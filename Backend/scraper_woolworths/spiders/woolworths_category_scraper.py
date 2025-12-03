import scrapy
from scrapy.crawler import CrawlerProcess
from scrapy_playwright.page import PageMethod
from urllib.parse import urlencode, parse_qs, urlparse
import hashlib
import os
import re
import html
import json

class ProductSpider(scrapy.Spider):
    name = 'product_spider'
    # Provide a list of category URLs to iterate through. Update this list to add more targets.
    # Optionally supply a comma-separated environment variable START_URLS to override
    env_urls = os.getenv('START_URLS')
    if env_urls:
        start_urls = [u.strip() for u in env_urls.split(',') if u.strip()]
    else:
        start_urls = [
            "https://www.woolworths.co.za/cat/Food/Toiletries-Health/Oral-Care/_/N-1sqrc3m"  
        ]
    # Optional max pages per category (safety cap)
    # Allow overriding via env var
    try:
        # Default to a higher page cap to avoid prematurely hitting a low cap (changeable via env)
        max_pages = int(os.getenv('MAX_PAGES', '200'))
    except Exception:
        max_pages = 200
    scraped_products = set()  # Track scraped products to prevent duplicates
    enqueued_products = set()  # Track product_ids enqueued for detail page requests
    # track consecutive pages with high duplicate count so we only stop if it's stable
    consecutive_duplicate_pages = 0
    consecutive_duplicate_threshold = 3
    consecutive_empty_pages = 0
    consecutive_empty_threshold = 5
    # Allow auto-expansion of max_pages when page reports a total product count
    auto_expand_pages = os.getenv('AUTO_MAX_PAGES', '1') not in ('0', 'false', 'False')

    def start_requests(self):
        for url in self.start_urls:
            yield scrapy.Request(
                url=url,
                callback=self.parse,
            meta={
                'playwright': True,
                    # Per-request page counter
                    'current_page': 1,
                'playwright_page_methods': [
                    PageMethod('wait_for_selector', 'div.product-list__item', timeout=15000),
                    PageMethod('wait_for_load_state', 'domcontentloaded'),
                    # Stronger lazy-load triggering: incremental scroll passes
                        PageMethod('evaluate', r'() => window.scrollTo(0, 0)'),
                    PageMethod('wait_for_timeout', 250),
                    PageMethod('evaluate', '() => window.scrollBy(0, window.innerHeight)'),
                    PageMethod('wait_for_timeout', 300),
                    PageMethod('evaluate', '() => window.scrollBy(0, window.innerHeight)'),
                    PageMethod('wait_for_timeout', 300),
                    PageMethod('evaluate', '() => window.scrollTo(0, document.body.scrollHeight)'),
                    PageMethod('wait_for_timeout', 600),
                    # Simulate mouseover/mousemove so lazyload triggers on initial page
                    PageMethod('evaluate', r"""
                        () => {
                            document.querySelectorAll('div.product-list__item, div[class*="product"]').forEach(card => {
                                const evt = new MouseEvent('mouseover', { bubbles: true });
                                card.dispatchEvent(evt);
                                const evt2 = new MouseEvent('mousemove', { bubbles: true });
                                card.dispatchEvent(evt2);
                            });
                        }
                    """),
                    PageMethod('wait_for_load_state', 'networkidle'),
                    # Scroll each product into view (in case images are loaded by IntersectionObserver on a container)
                    PageMethod('evaluate', r"""
                        async () => {
                            const cards = Array.from(document.querySelectorAll('div.product-list__item, div[class*="product"]'));
                            for (let i = 0; i < cards.length; i++) {
                                try {
                                    const el = cards[i];
                                    el.scrollIntoView({block: 'center'});
                                    await new Promise(r => setTimeout(r, 120));
                                    el.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
                                    await new Promise(r => setTimeout(r, 80));
                                } catch (e) {
                                    // ignore
                                }
                            }
                        }
                    """),
                    # Attach computed image src into product container 'data-scraped-image' attribute
                        PageMethod('evaluate', r"""
                        () => {
                            document.querySelectorAll('div.product-list__item, div[class*="product"]').forEach(item => {
                                try {
                                    let img = item.querySelector('img');
                                    let src = null;
                                    if (img) {
                                        src = img.src || img.getAttribute('data-src') || img.getAttribute('data-original') || img.getAttribute('data-lazy-src');
                                        if (!src && img.getAttribute('srcset')) {
                                            const ss = img.getAttribute('srcset').split(',').map(s => s.trim());
                                            const last = ss[ss.length-1];
                                            src = last.split(' ')[0];
                                        }
                                    }
                                    if (!src) {
                                        let pictureSource = item.querySelector('picture source[srcset], source[srcset]');
                                        if (pictureSource && pictureSource.getAttribute('srcset')) {
                                            const ss = pictureSource.getAttribute('srcset').split(',').map(s => s.trim());
                                            const last = ss[ss.length-1];
                                            src = last.split(' ')[0];
                                        }
                                    }
                                    if (!src) {
                                        let bg = item.querySelector('[style*="background-image"]');
                                        if (bg) {
                                            const m = bg.getAttribute('style').match(/url\(['\"]?(.*?)['\"]?\)/);
                                            if (m) src = m[1];
                                        }
                                    }
                                    if (src) {
                                        item.setAttribute('data-scraped-image', src);
                                    }
                                } catch (e) {
                                    // Ignore per-item failures
                                }
                            });
                        }
                    """),
                    # Hydrate <img> and <source> attributes from data-* so Scrapy can read them
                        PageMethod('evaluate', r"""
                        () => {
                            // Promote data-src/srcset to src/srcset so server-side parse can see them
                            document.querySelectorAll('img[data-src]').forEach(img => {
                                if (!img.getAttribute('src')) img.setAttribute('src', img.getAttribute('data-src'));
                            });
                            document.querySelectorAll('img[data-srcset]').forEach(img => {
                                if (!img.getAttribute('srcset')) img.setAttribute('srcset', img.getAttribute('data-srcset'));
                            });
                            document.querySelectorAll('source[data-srcset]').forEach(s => {
                                if (!s.getAttribute('srcset')) s.setAttribute('srcset', s.getAttribute('data-srcset'));
                            });
                        }
                    """),
                    # Wait for any real image sources to be present
                    PageMethod('wait_for_selector', 'img[src]:not([src^="data:"]) , picture source[srcset], div[class*="product--image"][style*="background-image"], div[class*="product-image"][style*="background-image"]', timeout=10000),
                ],
            }
        )

    def parse(self, response):
        # per-request pagination counter
        current_page = response.meta.get('current_page', 1)
        # Prefer explicit product list item selectors. Avoid broad 'div[class*="product"]' which
        # matches many non-product nodes in the DOM and can inflate the computed page_size.
        products = response.css('div.product-list__item, article.product-card, div.product-card')
        # Keep a stable page_size across the category's pagination so offsets are computed consistently
        # Compute page_size conservatively from our discrete product selector
        page_size = response.meta.get('page_size') or (len(products) if products is not None else None)
        self.logger.debug(f"📐 Computed page_size={page_size} (node count={len(products) if products is not None else 0})")
        # If this is the first page and we computed a page_size, store it in meta for subsequent pages
        if current_page == 1 and page_size:
            response.meta['page_size'] = page_size

        new_products_count = 0
        duplicate_count = 0
        missing_images = 0

        for product in products:
            # skip any nodes that aren't product items (some pages have placeholder nodes)
            if not (product.attrib.get('data-cnstrc-item-id') or product.attrib.get('data-cnstrc-item-name') or product.css('a.product--view::attr(href)').get()):
                # Not a real product card; skip
                continue
            name = product.css('h3::text, [class*="title"]::text, [class*="name"]::text').get()
            clean_name = name.strip() if name else None

            price_parts = product.css('[class*="price"] ::text').getall()
            raw_price = ''.join(price_parts).strip() if price_parts else None
            cleaned_price = self.clean_price(raw_price) if raw_price else None

            # Use robust helper to find image url
            img = self.get_image_url(product, response)
            # If Playwright computed data attribute contains image, prefer that
            scraped_attr = product.attrib.get('data-scraped-image')
            if not img and scraped_attr:
                img = scraped_attr
                if img and not img.startswith('http'):
                    try:
                        img = response.urljoin(img)
                    except Exception:
                        pass

            # Debug log for image detection
            item_id = product.attrib.get('data-cnstrc-item-id') or product.attrib.get('data-cnstrc-item-sku')
            if img:
                self.logger.debug(f"🖼️ Found image for {item_id or clean_name}: {img}")
            else:
                self.logger.debug(f"⚠️ No image found for {item_id or clean_name}")
                # Save the first few product HTML debug snapshots for offline inspection
                if missing_images < 5:
                    debug_html = product.get()
                    try:
                        with open(f"missing_image_debug_{missing_images+1}.html", "w", encoding="utf-8") as f:
                            f.write(debug_html)
                    except Exception as e:
                        self.logger.debug(f"Failed to write missing image debug file: {e}")
                    imgs_local = product.css('img')
                    for i, im_sel in enumerate(imgs_local[:6]):
                        attrs = {k: im_sel.attrib.get(k) for k in ['src', 'data-src', 'srcset', 'data-srcset', 'class', 'alt']}
                        self.logger.debug(f"🔎 Missing image - img #{i+1} attrs for product {item_id or clean_name}: {attrs}")

            # Extra fallbacks retained from your original approach
            if not img:
                img = product.css('div[class*="product--image"] div.lazyload-wrapper img::attr(src), div[class*="product-image"] div.lazyload-wrapper img::attr(src)').get()
            if not img:
                srcset = product.css('div[class*="product--image"] div.lazyload-wrapper img::attr(srcset), div[class*="product-image"] div.lazyload-wrapper img::attr(srcset)').get()
                if srcset:
                    try:
                        url_parts = [u.strip().split(' ')[0] for u in srcset.split(',') if u.strip()]
                        img = url_parts[-1]
                    except Exception:
                        img = url_parts[0] if url_parts else None
            if not img:
                data_srcset = product.css('div[class*="product--image"] div.lazyload-wrapper img::attr(data-srcset), div[class*="product-image"] div.lazyload-wrapper img::attr(data-srcset)').get()
                if data_srcset:
                    try:
                        url_parts = [u.strip().split(' ')[0] for u in data_srcset.split(',') if u.strip()]
                        img = url_parts[-1]
                    except Exception:
                        img = url_parts[0] if url_parts else None

            if img and not img.startswith('http'):
                try:
                    img = response.urljoin(img)
                except Exception:
                    pass

            if name and cleaned_price:
                clean_name = name.strip()
                clean_price = cleaned_price

                if raw_price and clean_price and raw_price != clean_price:
                    self.logger.debug(f"💬 Price normalized: '{raw_price}' -> '{clean_price}' for product '{clean_name}'")

                # Prefer SKU-based ids (more stable). Fall back to normalized name if no sku present.
                sku_id = product.attrib.get('data-cnstrc-item-id') or product.attrib.get('data-cnstrc-item-sku')
                product_id = self.create_product_id(sku_id) if sku_id else self.create_product_id(clean_name)

                # Only follow/emit when we haven't already scraped or enqueued this product
                if product_id not in self.scraped_products and product_id not in self.enqueued_products:
                    # If no image in listing, try to follow product detail page to fetch it
                    if not img:
                        detail_url = product.css('a.product--view::attr(href), a.product-view::attr(href)').get()
                        # If detail link exists, follow it and parse image from detail page
                        if detail_url:
                            full_url = response.urljoin(detail_url)
                            # Mark as enqueued to avoid duplicates being enqueued later
                            self.enqueued_products.add(product_id)
                            new_products_count += 1
                            # Build partial item and forward to detail page
                            partial = {
                                'name': clean_name,
                                'price': clean_price,
                                'image_url': None,
                                'product_id': product_id,
                                'productURL': full_url,
                            }
                            yield response.follow(
                                full_url,
                                callback=self.parse_product_detail,
                                meta={
                                    'playwright': True,
                                    'partial_item': partial,
                                    'page_size': page_size,
                                    'playwright_page_methods': [
                                        PageMethod('wait_for_selector', 'div.product-card, div.product--detail, img'),
                                        PageMethod('wait_for_load_state', 'domcontentloaded'),
                                        PageMethod('evaluate', '() => window.scrollTo(0, 0)'),
                                        PageMethod('wait_for_timeout', 250),
                                        PageMethod('evaluate', '() => window.scrollTo(0, document.body.scrollHeight)'),
                                        PageMethod('wait_for_timeout', 400),
                                        PageMethod('evaluate', r"""
                                            () => {
                                                document.querySelectorAll('img[data-src], img[data-srcset], img[data-lazy-src], img[data-original]').forEach(img => {
                                                    if (!img.getAttribute('src')) img.setAttribute('src', img.getAttribute('data-src') || img.getAttribute('data-original') || img.getAttribute('data-lazy-src'));
                                                    if (!img.getAttribute('srcset')) img.setAttribute('srcset', img.getAttribute('data-srcset') || img.getAttribute('data-ll-src'));
                                                });
                                                document.querySelectorAll('source[data-srcset]').forEach(s => {
                                                    if (!s.getAttribute('srcset')) s.setAttribute('srcset', s.getAttribute('data-srcset'));
                                                });
                                            }
                                        """),
                                        PageMethod('wait_for_load_state', 'networkidle'),
                                    ],
                                },
                            )
                        else:
                            # No detail link; yield item with image None
                            # If we're yielding directly (no detail page), mark as scraped
                            self.scraped_products.add(product_id)
                            new_products_count += 1
                            yield {
                                'name': clean_name,
                                'price': clean_price,
                                'image_url': img,
                                'product_id': product_id,
                                'productURL': None,
                            }
                else:
                    duplicate_count += 1
                    self.logger.debug(f"🔄 Skipped duplicate: {clean_name}")

            if not img:
                missing_images += 1

        self.logger.info(f"📊 Page {current_page}: {new_products_count} new products, {duplicate_count} duplicates skipped, {missing_images} missing images")

        # If AUTO_MAX_PAGES enabled, detect total product count from any page and compute expected pages
        if self.auto_expand_pages:
            try:
                # Ensure page_size is a sensible integer. If page_size is None/0, fall back to a reasonable default
                # (many Woolworths categories show 24 items per page, but some use 12). Use 24 as a pragmatic default.
                page_size = int(page_size or (len(products) if products else 24))
                total_count = self.extract_total_products(response)
                if total_count:
                    # persist detection for subsequent pages
                    response.meta['total_count'] = total_count
                    self.logger.debug(f"📊 Detected total_count={total_count} from page {current_page}")
                if total_count and page_size:
                    computed_pages = int((int(total_count) + page_size - 1) // page_size)
                    if computed_pages != self.max_pages:
                        self.logger.info(f"📈 Adjusting max_pages from {self.max_pages} to {computed_pages} based on total product count {total_count}")
                        self.max_pages = computed_pages
                else:
                    self.logger.debug("💡 Could not determine total count or page size; not auto-expanding max_pages")
                    # Save first page HTML for offline inspection if not already saved
                    try:
                        dump_path = 'category_firstpage_debug.html'
                        with open(dump_path, 'w', encoding='utf-8') as fh:
                            fh.write(response.text)
                        self.logger.debug(f"🐞 First page HTML saved to {dump_path} for debugging total count detection")
                    except Exception as e:
                        self.logger.debug(f"Failed to write debug file: {e}")
            except Exception as e:
                self.logger.debug(f"Failed to auto-detect total products: {e}")

        # If we are getting too many duplicates on this page, increment a consecutive counter
        # and only stop when multiple pages in a row are highly-duplicated. This avoids stopping
        # early due to a single noisy page (e.g., heavily filtered/sponsored items on a single page).
        dup_ratio = (duplicate_count / len(products)) if products and len(products) else 0
        if dup_ratio > 0.8:  # If 80% are duplicates on this page
            self.consecutive_duplicate_pages += 1
            self.logger.info(f"⚠️ High duplicate ratio on page {current_page} ({dup_ratio:.2%}). consec={self.consecutive_duplicate_pages}")
            if self.consecutive_duplicate_pages >= self.consecutive_duplicate_threshold:
                self.logger.info("🛑 Stopping pagination - high duplicate ratio persists across pages")
                return
        else:
            # Reset consecutive counter when a healthy page is encountered
            if self.consecutive_duplicate_pages:
                self.logger.debug(f"✅ Reset consecutive duplicate counter (was {self.consecutive_duplicate_pages})")
            self.consecutive_duplicate_pages = 0

        # If the page has no real products (empty/placeholder), increment empty counter and stop if repeated
        if not products or len(products) == 0:
            self.consecutive_empty_pages += 1
            self.logger.info(f"⚠️ Empty page detected (no products). consec_empty={self.consecutive_empty_pages}")
            # If total_count is known, compute expected pages and only stop when we've reached/exceeded it
            total_count = response.meta.get('total_count') or self.extract_total_products(response)
            if total_count and page_size:
                try:
                    computed_pages = int((int(total_count) + int(page_size) - 1) // int(page_size))
                except Exception:
                    computed_pages = None
                # If we've reached or passed the computed last page, stop
                if computed_pages and current_page >= computed_pages:
                    self.logger.info("🛑 Reached final computed page (empty page). Stopping pagination")
                    return
            # If we don't have total_count, fall back to consecutive empty pages threshold but only
            # after we've scanned a reasonable number of pages (avoid early stop due to transient empties)
            if not total_count:
                min_safe_pages = int(os.getenv('MIN_SAFE_PAGES', '8'))
                if self.consecutive_empty_pages >= self.consecutive_empty_threshold and current_page > min_safe_pages:
                    self.logger.info("🛑 Stopping pagination - consecutive empty pages detected (no total_count available)")
                    return
                # Attempt a one-time rehydration of this page, to recover product nodes
                # if they are loaded differently or more slowly on deeper pages.
                retried = response.meta.get('rehydrated')
                if not retried and current_page < self.max_pages:
                    self.logger.info(f"🔁 Retrying current page ({current_page}) with extended hydration to recover product nodes")
                    yield response.follow(
                        response.url,
                        callback=self.parse,
                        meta={
                            'playwright': True,
                            'current_page': current_page,
                            'page_size': page_size,
                            'rehydrated': True,
                            'playwright_page_methods': [
                                PageMethod('wait_for_selector', 'div.product-list__item, article.product-card, div.product-card', timeout=20000),
                                PageMethod('wait_for_load_state', 'domcontentloaded'),
                                PageMethod('evaluate', '() => window.scrollTo(0, 0)'),
                                PageMethod('wait_for_timeout', 1000),
                                PageMethod('evaluate', '() => window.scrollBy(0, window.innerHeight)'),
                                PageMethod('wait_for_timeout', 600),
                                PageMethod('evaluate', '() => window.scrollBy(0, window.innerHeight)'),
                                PageMethod('wait_for_timeout', 600),
                                PageMethod('evaluate', '() => window.scrollTo(0, document.body.scrollHeight)'),
                                PageMethod('wait_for_timeout', 1000),
                                PageMethod('evaluate', '() => { window.dispatchEvent(new Event("resize")); }'),
                                PageMethod('wait_for_timeout', 300),
                                PageMethod('wait_for_load_state', 'networkidle')
                            ],
                        },
                    )
        else:
            if self.consecutive_empty_pages:
                self.logger.debug(f"✅ Reset consecutive empty page counter (was {self.consecutive_empty_pages})")
            self.consecutive_empty_pages = 0

        # 🔄 PAGINATION: Try multiple strategies
        next_page_url = self.find_next_page(response, page_size=page_size)

        # Limit pages per category via per-request meta 'current_page' and spider.max_pages
        if next_page_url and current_page < self.max_pages:
            next_page_num = current_page + 1
            self.logger.info(f"🎯 Moving to page {next_page_num} for {response.url}: {next_page_url}")
            # Prevent following the same URL repeatedly (rare cases where next link resolves to the same page)
            if response.url.rstrip('/') == next_page_url.rstrip('/'):
                self.logger.warning(f"⛔ Next page URL equals current URL ({response.url}). Not following to avoid loop.")
                return

            yield response.follow(
                next_page_url,
                callback=self.parse,
                meta={
                    'playwright': True,
                    # carry forward the incremented page counter
                    'current_page': next_page_num,
                    'page_size': page_size,
                    'playwright_page_methods': [
                        PageMethod('wait_for_selector', 'div.product-list__item', timeout=15000),
                        PageMethod('wait_for_load_state', 'domcontentloaded'),
                        # Repeat the same hydration + scroll sequence for each page
                        PageMethod('evaluate', '() => window.scrollTo(0, 0)'),
                        PageMethod('wait_for_timeout', 250),
                        PageMethod('evaluate', '() => window.scrollBy(0, window.innerHeight)'),
                        PageMethod('wait_for_timeout', 300),
                        PageMethod('evaluate', '() => window.scrollBy(0, window.innerHeight)'),
                        PageMethod('wait_for_timeout', 300),
                        PageMethod('evaluate', '() => window.scrollTo(0, document.body.scrollHeight)'),
                        PageMethod('wait_for_timeout', 600),
                                        PageMethod('evaluate', r"""
                            async () => {
                                const cards = Array.from(document.querySelectorAll('div.product-list__item, div[class*="product"]'));
                                for (let i = 0; i < cards.length; i++) {
                                    try {
                                        const el = cards[i];
                                        el.scrollIntoView({block: 'center'});
                                        await new Promise(r => setTimeout(r, 120));
                                        el.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
                                        await new Promise(r => setTimeout(r, 80));
                                    } catch (e) {
                                        // ignore
                                    }
                                }
                            }
                        """),
                        # Simulate mouseover/mousemove on each product card so lazyload triggers
                        PageMethod('evaluate', r"""
                            () => {
                                document.querySelectorAll('div.product-list__item, div[class*="product"]').forEach(card => {
                                    const evt = new MouseEvent('mouseover', { bubbles: true });
                                    card.dispatchEvent(evt);
                                    const evt2 = new MouseEvent('mousemove', { bubbles: true });
                                    card.dispatchEvent(evt2);
                                });
                            }
                        """),
                        # Attach computed image src into product container 'data-scraped-image' attribute
                        PageMethod('evaluate', r"""
                            () => {
                                document.querySelectorAll('div.product-list__item, div[class*="product"]').forEach(item => {
                                    try {
                                        let img = item.querySelector('img');
                                        let src = null;
                                        if (img) {
                                            src = img.src || img.getAttribute('data-src') || img.getAttribute('data-original') || img.getAttribute('data-lazy-src');
                                            if (!src && img.getAttribute('srcset')) {
                                                const ss = img.getAttribute('srcset').split(',').map(s => s.trim());
                                                const last = ss[ss.length-1];
                                                src = last.split(' ')[0];
                                            }
                                        }
                                        if (!src) {
                                            let pictureSource = item.querySelector('picture source[srcset], source[srcset]');
                                            if (pictureSource && pictureSource.getAttribute('srcset')) {
                                                const ss = pictureSource.getAttribute('srcset').split(',').map(s => s.trim());
                                                const last = ss[ss.length-1];
                                                src = last.split(' ')[0];
                                            }
                                        }
                                        if (!src) {
                                            let bg = item.querySelector('[style*="background-image"]');
                                            if (bg) {
                                                const m = bg.getAttribute('style').match(/url\(['\"]?(.*?)['\"]?\)/);
                                                if (m) src = m[1];
                                            }
                                        }
                                        if (src) {
                                            item.setAttribute('data-scraped-image', src);
                                        }
                                    } catch (e) {
                                        // Ignore per-item failures
                                    }
                                });
                            }
                        """),
                        PageMethod('wait_for_timeout', 200),
                        PageMethod('wait_for_load_state', 'networkidle'),
                        PageMethod('evaluate', r"""
                            () => {
                                // Promote image attributes so server-side parse can read them
                                document.querySelectorAll('img[data-src]').forEach(img => {
                                    if (!img.getAttribute('src')) img.setAttribute('src', img.getAttribute('data-src'));
                                });
                                document.querySelectorAll('img[data-srcset]').forEach(img => {
                                    if (!img.getAttribute('srcset')) img.setAttribute('srcset', img.getAttribute('data-srcset'));
                                });
                                document.querySelectorAll('source[data-srcset]').forEach(s => {
                                    if (!s.getAttribute('srcset')) s.setAttribute('srcset', s.getAttribute('data-srcset'));
                                });
                                // Additional popular lazy attributes
                                document.querySelectorAll('img[data-original]').forEach(img => {
                                    if (!img.getAttribute('src')) img.setAttribute('src', img.getAttribute('data-original'));
                                });
                                document.querySelectorAll('img[data-lazy-src]').forEach(img => {
                                    if (!img.getAttribute('src')) img.setAttribute('src', img.getAttribute('data-lazy-src'));
                                });
                                document.querySelectorAll('img[data-ll-src]').forEach(img => {
                                    if (!img.getAttribute('src')) img.setAttribute('src', img.getAttribute('data-ll-src'));
                                });
                                document.querySelectorAll('img[data-src], img[src]').forEach(img => {
                                    // If src exists but is a data: URI placeholder, swap in data-src
                                    const src = img.getAttribute('src');
                                    if (src && src.startsWith('data:')) {
                                        const ds = img.getAttribute('data-src') || img.getAttribute('data-original') || img.getAttribute('data-lazy-src');
                                        if (ds) img.setAttribute('src', ds);
                                    }
                                });
                            }
                        """),
                        # Wait for real images to be present (exclude data: placeholders when possible)
                        PageMethod('wait_for_selector', 'img[src]:not([src^="data:"]) , picture source[srcset], div[class*="product--image"][style*="background-image"], div[class*="product-image"][style*="background-image"]', timeout=10000),
                    ],
                }
            )
        else:
            self.logger.info(f"🏁 Finished scraping after {current_page} pages for {response.url}")
            self.logger.info(f"📈 Total unique products scraped: {len(self.scraped_products)}")

    def create_product_id(self, name):
        """Create a unique identifier for the product to detect duplicates"""
        normalized_name = name.lower().strip()
        normalized_name = ' '.join(normalized_name.split())
        return hashlib.md5(normalized_name.encode()).hexdigest()

    def get_image_url(self, product, response):
        """Return the best image URL for a product element.

        Tries <img> src/data-src/srcset/data-srcset, <picture><source srcset>, noscript images,
        CSS background-image, and finally any img::attr(src). Prefer highest-res from srcset.
        Returns absolute URL.
        """
        def pick_from_srcset(value):
            parts = [p.strip() for p in value.split(',') if p.strip()]
            if not parts:
                return None
            parsed = []
            for p in parts:
                vals = p.split(' ')
                url = vals[0]
                descriptor = vals[1] if len(vals) > 1 else ''
                num = 0
                if descriptor.endswith('w'):
                    try:
                        num = int(descriptor[:-1])
                    except Exception:
                        num = 0
                elif descriptor.endswith('x'):
                    try:
                        num = int(float(descriptor[:-1]) * 1000)
                    except Exception:
                        num = 0
                parsed.append((num, url))
            parsed.sort(key=lambda x: x[0] if isinstance(x[0], int) else 0)
            return parsed[-1][1] if parsed else parts[-1].split(' ')[0]

        # 1) <img> attributes (prefer data-*, then srcset, then src)
        candidate_attrs = ['data-src', 'data-original', 'data-lazy-src', 'data-ll-src', 'src']
        imgs = product.css('img')
        for img_sel in imgs:
            # direct single-value attrs
            for attr in candidate_attrs:
                val = img_sel.attrib.get(attr)
                if val:
                    val = val.strip()
                    # Skip obvious placeholders
                    if val.startswith('data:') or val.startswith('blob:') or 'placeholder' in val or val.strip() == '':
                        continue
                    if val and not val.startswith('http'):
                        try:
                            val = response.urljoin(val)
                        except Exception:
                            pass
                        # Unescape any HTML entities
                        val = html.unescape(val)
                    # Log low-frequency debug for product image attributes
                    # (We can't log the entire product in heavy runs)
                    return val
            # srcset-family
            for attr in ['data-srcset', 'srcset']:
                v = img_sel.attrib.get(attr)
                if v:
                    picked = pick_from_srcset(v)
                    if picked:
                        if not picked.startswith('http'):
                            try:
                                picked = response.urljoin(picked)
                            except Exception:
                                pass
                        picked = html.unescape(picked)
                        return picked

        # 2) <picture><source srcset> (common for responsive product cards)
        srcsets = product.css('picture source::attr(srcset), source::attr(srcset)').getall()
        if srcsets:
            # choose last/highest-res
            try:
                last = srcsets[-1].strip()
                picked = pick_from_srcset(last) if ',' in last else last.split(' ')[0]
            except Exception:
                picked = srcsets[0].strip().split(' ')[0]
            if picked:
                if not picked.startswith('http'):
                    try:
                        picked = response.urljoin(picked)
                    except Exception:
                        pass
                picked = html.unescape(picked)
                return picked

        # 3) noscript img fallback
        val = product.css('noscript img::attr(src)').get()
        if val:
            val = val.strip()
            if val and not val.startswith('http'):
                try:
                    val = response.urljoin(val)
                except Exception:
                    pass
            val = html.unescape(val)
            return val

        # 4) CSS background-image on common wrappers
        style_val = product.css(
            'div.product--image::attr(style), div.lazyload-wrapper::attr(style), div.product-image::attr(style)'
        ).get()
        if style_val:
            m = re.search(r"url\(['\"]?(.*?)['\"]?\)", style_val)
            if m:
                val = m.group(1)
                if val and not val.startswith('http'):
                    try:
                        val = response.urljoin(val)
                    except Exception:
                        pass
                return val

        # 5) last resort: any img src, ignoring data: placeholders where possible
        val = None
        for v in product.css('img::attr(src)').getall():
            if v and v.strip() and not v.startswith('data:'):
                val = v.strip()
                break
        if val:
            val = val.strip()
            if val and not val.startswith('http'):
                try:
                    val = response.urljoin(val)
                except Exception:
                    pass
            return val

        # 6) product-card specific fallbacks
        # Check within anchors and common 'product-card_img' class names
        for attr in ['data-src', 'src']:
            s = product.css('a.product--view img::attr(%s), img.product-card_img::attr(%s), img[class*="product-card_img"]::attr(%s)' % (attr, attr, attr)).get()
            if s and not s.startswith('data:'):
                s = s.strip()
                if not s.startswith('http'):
                    try:
                        s = response.urljoin(s)
                    except Exception:
                        pass
                    s = html.unescape(s)
                return s

        return None

    def clean_price(self, raw_price):
        """Extract all 'R' currency values from the raw price string, convert them to floats,
        choose the lowest, and return a consistently formatted string like 'R 62.99'.
        If no price is found, return the original trimmed string.
        """
        if not raw_price:
            return None

        amounts = re.findall(r"R\s*\d+[.,]?\d*", raw_price)
        if not amounts:
            # Try to find just numbers as a fallback
            nums = re.findall(r"\d+[.,]\d+", raw_price)
            if not nums:
                return ' '.join(raw_price.split())
            amounts = [f"R {n}" for n in nums]

        parsed = []
        for a in amounts:
            num_text = a.replace('R', '').strip()
            num_text = num_text.replace(',', '.')
            try:
                parsed.append(float(num_text))
            except ValueError:
                continue

        if not parsed:
            return ' '.join(raw_price.split())

        best = min(parsed)
        return f"R {best:.2f}"

    def find_next_page(self, response, page_size=None):
        """Try multiple strategies to find the next page URL"""
        # current_page is stored in request meta; default to 1
        current_page = response.meta.get('current_page', 1)

        # Strategy 1: link[rel=next] - canonical next link
        next_page = response.css('link[rel="next"]::attr(href)').get()
        if next_page:
            full_url = response.urljoin(next_page)
            self.logger.info(f"🔍 Found next page via rel=next: {full_url}")
            return full_url

        # Strategy 2: Direct XPath for Next button (fallback if rel=next not present)
        next_page = response.xpath('//span[contains(text(), "Next")]/ancestor::a/@href').get()
        if next_page:
            full_url = response.urljoin(next_page)
            self.logger.info(f"🔍 Found next page via Strategy 1: {full_url}")
            return full_url

        # Strategy 3: Look for pagination_nav with Next
        pagination_navs = response.css('div.pagination_nav')
        for nav in pagination_navs:
            nav_text = ' '.join(nav.css('::text').getall())
            if 'Next' in nav_text:
                next_link = nav.css('a::attr(href)').get()
                if next_link:
                    full_url = response.urljoin(next_link)
                    self.logger.info(f"🔍 Found next page via Strategy 2: {full_url}")
                    return full_url

        # Strategy 4: Look for active page and get next one
        active_page = response.css('a.pagination__nav--active')
        if active_page:
            next_link = active_page.xpath('./following-sibling::a[1]/@href').get()
            if next_link:
                full_url = response.urljoin(next_link)
                self.logger.info(f"🔍 Found next page via Strategy 3: {full_url}")
                return full_url

        # Strategy 5: URL pattern - if current URL has page parameter, increment it
        parsed_url = urlparse(response.url)
        query_params = parse_qs(parsed_url.query)

        for param in ['page', 'No', 'offset', 'start']:
            if param in query_params:
                try:
                    current_param_value = query_params[param][0]
                    # Some sites use No as an offset (e.g., No=24 indicates start index), while others use 'page'
                    current_page_num = int(current_param_value)
                    # If the pagination parameter is 'page', increment by 1; for offsets (No/start/offset), increment by page_size
                    if param == 'page':
                        next_page_num = current_page_num + 1
                    else:
                        # Fallback to sensible defaults if page_size missing
                        inc = int(page_size or 24)
                        # If current_page_num looks like an offset (>= page size), increment by page_size
                        next_page_num = current_page_num + inc
                    # Avoid loops or extreme jumps: ensure next value truly advances and is reasonable
                    try:
                        cur_int = int(current_param_value)
                        if next_page_num <= cur_int:
                            self.logger.debug(f"⛔ Computed next offset {next_page_num} is not greater than current [{cur_int}], ignoring")
                            return None
                        if page_size and next_page_num - cur_int > (int(page_size) * 8):
                            # A jump greater than 8 pages is suspicious — ignore computed offset to avoid overshooting
                            self.logger.debug(f"⛔ Computed next offset jump too large ({next_page_num - cur_int}) - ignoring")
                            return None
                    except Exception:
                        pass
                    # Guard: if a total_count is available, don't compute offsets beyond the total index
                    try:
                        total_count = response.meta.get('total_count') or self.extract_total_products(response)
                        if total_count and next_page_num >= int(total_count):
                            self.logger.info(f"❌ Not following next page (computed offset {next_page_num} >= total_count {total_count})")
                            return None
                    except Exception:
                        pass
                    query_params[param] = [str(next_page_num)]
                    new_query = urlencode(query_params, doseq=True)
                    next_url = f"{parsed_url.scheme}://{parsed_url.netloc}{parsed_url.path}?{new_query}"
                    self.logger.info(f"🔍 Found next page via Strategy 4: {next_url}")
                    return next_url
                except (ValueError, IndexError):
                    continue

        # Strategy 6: If no page parameter, add one
        # If no pagination parameter is present, add one using page_size when known
        if 'page' not in query_params and 'No' not in query_params and 'offset' not in query_params and 'start' not in query_params:
            inc = int(page_size or 24)
            # If the first page has no pagination param, the next offset is current_page * page_size
            next_offset = current_page * inc
            if '?' in response.url:
                separator = '&' if response.url.split('?')[1] else '?'
                next_url = f"{response.url}{separator}No={next_offset}"
            else:
                next_url = f"{response.url}?No={next_offset}"
            self.logger.info(f"🔍 Found next page via Strategy 5: {next_url}")
            return next_url

        # Extra fallback: try ARIA or rel-next anchors or 'a[aria-label*="Next"]'
        aria_href = response.css('a[aria-label*="Next"]::attr(href), a[aria-label*="next"]::attr(href), a[rel="next"]::attr(href)').get()
        if aria_href:
            full_url = response.urljoin(aria_href)
            self.logger.info(f"🔍 Found next page via aria/rel-next fallback: {full_url}")
            return full_url

        self.logger.info("❌ No next page found")
        return None

    def extract_total_products(self, response):
        """Try multiple strategies to find the total number of products for the category page.

        Returns integer total or None.
        """
        # Strategy 1: search for human-readable indicators in page text (e.g. "of 309 results")
        full_text = ' '.join(response.css('body *::text').getall() or [])
        # look for several variations with/without 'of'
        m = re.search(r"(?:of\s+)?([0-9,]+)\s*(?:results|results found|products|items|products found)?", full_text, flags=re.I)
        if m:
            try:
                return int(m.group(1).replace(',', ''))
            except Exception:
                pass

        # Strategy 2: look for meta descriptions or other banner counts
        meta_desc = response.css('meta[name=description]::attr(content)').get()
        if meta_desc:
            m = re.search(r"([0-9,]+)\s*(?:results|products|items)", meta_desc, flags=re.I)
            if m:
                try:
                    return int(m.group(1).replace(',', ''))
                except Exception:
                    pass

        # Strategy 3: named page elements common on e-commerce sites
        candidate_selectors = [
            'div.search-results__count::text',
            'div.results-count::text',
            'span.total-results::text',
            'span.results::text',
            'span.search-result-count::text',
            'p.results-count::text',
            'div.results-count__value::text'
        ]
        for sel in candidate_selectors:
            t = response.css(sel).get()
            if t:
                m = re.search(r'([0-9,]+)', t)
                if m:
                    try:
                        return int(m.group(1).replace(',', ''))
                    except Exception:
                        continue

        # Strategy 4a: check for a site-specific data attribute used by CNSTRC (commonly present in Woolworths listings)
        try:
            num_results_attr = response.css('div.product-list__list::attr(data-cnstrc-num-results), [data-cnstrc-num-results]::attr(data-cnstrc-num-results)').get()
            if num_results_attr:
                try:
                    return int(num_results_attr)
                except Exception:
                    pass
        except Exception:
            pass

        # Strategy 4b: check for pagination page count 'of X' and compute total as page_count * page_size if page_size is available
        try:
            page_nums = response.css('nav.pagination .page-num-mobile strong::text').getall()
            if page_nums and len(page_nums) >= 2:
                # page_nums like ['1', '13'] -> second is total pages
                page_count = int(page_nums[1].strip())
                # get page size from DOM if available
                page_size = None
                # prefer product-list__list data attribute if present
                try:
                    page_size_attr = response.css('div.product-list__list::attr(data-cnstrc-page-size)').get()
                    if page_size_attr:
                        page_size = int(page_size_attr)
                except Exception:
                    page_size = None
                # fallback to counting product nodes
                if not page_size:
                    try:
                        page_size = len(response.css('div.product-list__item'))
                    except Exception:
                        page_size = None
                if page_size and page_count:
                    return int(page_count) * int(page_size)
        except Exception:
            pass

        # Strategy 5: inspect inline JSON on page, check for common keys like totalResults/totalProducts/total
        # Strategy 4: inspect inline JSON on page, check for common keys like totalResults/totalProducts/total
        scripts = response.css('script::text').getall()
        # look for common variants in the JSON payloads
        json_keys = ['totalResults', 'totalProducts', 'total', 'productCount', 'totalItems', 'total_products', 'totalRecords']
        for s in scripts:
            if not s:
                continue
            for key in json_keys:
                # look for "total":123 and '"total": 123' styles
                m = re.search(r'"%s"\s*[:=]\s*([0-9]+)' % re.escape(key), s)
                if m:
                    try:
                        return int(m.group(1))
                    except Exception:
                        continue

        return None

    def parse_product_detail(self, response):
        """Parse the product detail page to attempt to extract images or other missing info.

        Expects a 'partial_item' dict in meta with keys 'name', 'price', 'image_url', and 'product_id'.
        Updates the image_url if found and yields the final item.
        """
        partial = response.meta.get('partial_item') or {}
        # Try to extract primary image from detail page (the response object itself can be used)
        img = None
        try:
            # Use get_image_url to attempt to find any inline <img> specifics
            img = self.get_image_url(response, response)
        except Exception:
            img = None

        # As a fallback, check some typical detail page structures and meta tags
        if not img:
            # Check open graph / twitter meta image tags first and prefer these
            meta_og = response.css('meta[property="og:image"]::attr(content)').get()
            meta_twitter = response.css('meta[name="twitter:image"]::attr(content)').get()
            meta_itemprop = response.css('meta[itemprop="image"]::attr(content)').get()
            meta_img = meta_og or meta_twitter or meta_itemprop
            if meta_img:
                # Unescape HTML entities if necessary and sanitize
                meta_img = html.unescape(meta_img).strip()
                if meta_img and not meta_img.startswith('http'):
                    try:
                        meta_img = response.urljoin(meta_img)
                    except Exception:
                        pass
                img = meta_img
                if img:
                    self.logger.debug(f"🔗 Used meta image for detail page: {img}")
            else:
                # If no meta found, look for inline images (including data-src)
                img = response.css('img[class*="product-card_img"]::attr(src), img[class*="product-main-image"]::attr(src), img::attr(data-src)').get()
                if img and not img.startswith('http'):
                    try:
                        img = response.urljoin(img)
                    except Exception:
                        pass

        # Additional fallback: parse JSON-LD product structured data if present
        if not img:
            try:
                json_ld_elems = response.css('script[type="application/ld+json"]::text').getall()
                for j in json_ld_elems:
                    try:
                        parsed = json.loads(j)
                        # sometimes it's a list; find product objects
                        candidates = parsed if isinstance(parsed, list) else [parsed]
                        for c in candidates:
                            if isinstance(c, dict) and c.get('@type') and 'product' in c.get('@type', '').lower():
                                img_prop = c.get('image') or c.get('images')
                                if img_prop:
                                    if isinstance(img_prop, list):
                                        img = img_prop[0]
                                    else:
                                        img = img_prop
                                    if img and not img.startswith('http'):
                                        img = response.urljoin(img)
                                    self.logger.debug(f"🔎 JSON-LD product image found: {img}")
                                    raise StopIteration
                    except StopIteration:
                        break
                    except Exception:
                        continue
            except Exception:
                pass

        # If it's still a data: placeholder, try data-src
        if img and img.startswith('data:'):
            ds = response.css('img[class*="product-card_img"]::attr(data-src), img::attr(data-src), img::attr(data-original)').get()
            if ds:
                img = ds
                if not img.startswith('http'):
                    try:
                        img = response.urljoin(img)
                    except Exception:
                        pass

        final = partial.copy()
        final['image_url'] = img
        # Ensure product_id is present and not double-yielded
        product_id = final.get('product_id')
        # Ensure productURL is present (fall back to PDP response URL if missing)
        if 'productURL' not in final or not final.get('productURL'):
            try:
                final['productURL'] = response.url
            except Exception:
                final['productURL'] = None
        if product_id:
            # Move from enqueued to scraped set after successfully obtaining final item
            try:
                if product_id in self.enqueued_products:
                    self.enqueued_products.remove(product_id)
            except Exception:
                pass
            self.scraped_products.add(product_id)
        yield final

    def closed(self, reason):
        """Called when spider closes"""
        self.logger.info(f"🔚 Spider closed: {reason}")
        self.logger.info(f"📊 Final statistics: {len(self.scraped_products)} unique products scraped")


# Optional standalone runner (unchanged)
if __name__ == "__main__":
    process = CrawlerProcess(settings={
        "FEEDS": {"products.json": {"format": "json"}},
        "PLAYWRIGHT_BROWSER_TYPE": "chromium",
        "PLAYWRIGHT_DEFAULT_NAVIGATION_TIMEOUT": 30000,
        "LOG_LEVEL": "INFO",
    })
    process.crawl(ProductSpider)
    process.start()
