import scrapy
from scrapy import Request
from datetime import datetime
import json
import re


class CheckersProductSpider(scrapy.Spider):
    name = "checkers_simple"
    
    start_urls = [
        "https://www.checkers.co.za/product/checkers-housebrand-full-cream-milk-6-x-1l-10156094PK1",
        "https://www.checkers.co.za/product/checkers-housebrand-large-eggs-30-pack-10417428EA",
        "https://www.checkers.co.za/product/grand-pa-headache-powder-38-pack-10750813EA",
        "https://www.checkers.co.za/product/calpol-strawberry-flavoured-paediatric-suspension-100ml-10144902EA",
        "https://www.checkers.co.za/product/sunlight-original-dishwashing-liquid-750ml-10126901EA",
        "https://www.checkers.co.za/product/surf-hand-washing-powder-2kg-10216662EA",
        "https://www.checkers.co.za/product/energizer-max-aaa-alkaline-batteries-12-pack-10689259EA",
        "https://www.checkers.co.za/product/sandisk-cruzer-glide-retractable-usb-a-30-flash-drive-32gb-10709366EA",
        "https://www.checkers.co.za/product/staedtler-wood-free-pencil-crayons-24-pack-10514798EA",
        "https://www.checkers.co.za/product/croxley-scholar-a5-feint-and-margin-hardcover-manuscript-book-96-pages-10116306EA",
        "https://www.checkers.co.za/product/colgate-triple-action-original-mint-fluoride-toothpaste-100ml-10130015EA",
        "https://www.checkers.co.za/product/dettol-antiseptic-liquid-750ml-10128732EA"
    ]
    
    custom_settings = {
        'USER_AGENT': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'ROBOTSTXT_OBEY': False,
        'DOWNLOAD_DELAY': 1,
        'FEED_FORMAT': 'json',
        'FEED_URI': 'checkers_output.json',
        'LOG_LEVEL': 'INFO',
    }

    def start_requests(self):
        for url in self.start_urls:
            yield Request(
                url,
                callback=self.parse_product,
                headers={
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
                    'Accept-Language': 'en-US,en;q=0.5',
                    'Accept-Encoding': 'gzip, deflate, br',
                    'Connection': 'keep-alive',
                    'Upgrade-Insecure-Requests': '1',
                    'Sec-Fetch-Dest': 'document',
                    'Sec-Fetch-Mode': 'navigate',
                    'Sec-Fetch-Site': 'none',
                    'Sec-Fetch-User': '?1',
                },
                errback=self.errback,
            )

    def parse_product(self, response):
        """Direct parsing without Playwright"""
        item = {
            'productURL': response.url,
            'productName': None,
            'price': None,
            'productImageURL': None,
            'category': None,
        }
        
        # 1. Try to extract from JSON-LD (most reliable)
        json_ld_data = self.extract_json_ld(response)
        if json_ld_data:
            item['productName'] = json_ld_data.get('name') or json_ld_data.get('title')
            item['price'] = json_ld_data.get('price')
            item['productImageURL'] = json_ld_data.get('image')
            item['category'] = json_ld_data.get('category') or item.get('category')
            if item['productImageURL']:
                low = item['productImageURL'].lower()
                # Ignore share-card and common tracking shortlinks
                if 'share-card' in low or 't.co' in low or 'twitter' in low or 'adsct' in low:
                    self.logger.debug(f"Ignoring JSON-LD image (share-card or tracker): {item['productImageURL']}")
                    item['productImageURL'] = None
        
        # 2. If JSON-LD didn't work, try HTML selectors
        if not item['productName']:
            # Product name selectors
            name_selectors = [
                'h1.product-detail__name::text',
                'h1.product__name::text',
                'h1.item-title::text',
                'h1::text',
                'title::text',
            ]
            
            for selector in name_selectors:
                name = response.css(selector).get()
                if name and name.strip():
                    item['productName'] = name.strip()
                    break
        
        if not item['price']:
            # Price selectors
            price_selectors = [
                'span.now::text',
                '.item-price::text',
                '.price::text',
                '.selling-price::text',
                '[class*="price"]::text',
            ]
            
            for selector in price_selectors:
                price = response.css(selector).get()
                if price and 'R' in price:
                    item['price'] = price.strip()
                    break
            
            # Regex fallback for price
            if not item['price']:
                price_match = re.search(r'R\s?\d+[.,]\d{2}', response.text)
                if price_match:
                    item['price'] = price_match.group(0)
        else:
            # If the price we found lacks cents, try to find a Rxx.xx price anywhere in the page
            try:
                if item['price'] and not re.search(r'[.,]\d{2}', item['price']):
                    price_match = re.search(r'R\s?\d+[.,]\d{2}', response.text)
                    if price_match:
                        item['price'] = price_match.group(0)
            except Exception:
                pass
        # After existing attempts, if price still lacks cents, search for decimals adjacent to the price token
        if item.get('price') and not re.search(r'[.,]\d{2}', item.get('price')):
            price_str = item.get('price')
            # Find where this string appears in the response text
            idx = response.text.find(price_str)
            decimal_match = None
            if idx >= 0:
                # search forward for a .99 or ,99 within the next 80 chars
                fragment = response.text[idx: idx+160]
                decimal_match = re.search(r'[\.,]\s?(\d{2})', fragment)
                if decimal_match:
                    cents = decimal_match.group(1)
                    if '.' in decimal_match.group(0) or ',' in decimal_match.group(0):
                        # Build new price
                        num_digits = re.search(r'\d+', price_str)
                        if num_digits:
                            base = price_str
                            # If base already contains decimals, skip
                            if not re.search(r'[.,]\d{2}', base):
                                base = base.rstrip()
                                if not base.startswith('R'):
                                    base = 'R' + base
                                item['price'] = re.sub(r'R\s?(\d+)', r'R\1.' + cents, base)
            if not decimal_match:
                # fallback: try to find any Rxx.xx on page and use first match
                m = re.search(r'R\s?\d+[\.,]\d{2}', response.text)
                if m:
                    item['price'] = m.group(0)
        # If price still lacks decimals, try to find it in Next.js __NEXT_DATA__ script (server-side data)
        if item['price'] and not re.search(r'[.,]\d{2}', item['price']):
            nd_script = response.css('script#__NEXT_DATA__::text').get()
            if nd_script:
                try:
                    nd = json.loads(nd_script)

                    def find_price(obj):
                        if isinstance(obj, dict):
                            for k, v in obj.items():
                                if isinstance(v, (int, float)) and v > 0:
                                    # If it looks like a price with decimals, return it
                                    if float(v) % 1 != 0:
                                        return v
                                if isinstance(v, str) and re.match(r'\d+[.,]\d{2}$', v):
                                    return v
                                res = find_price(v)
                                if res:
                                    return res
                        elif isinstance(obj, list):
                            for el in obj:
                                res = find_price(el)
                                if res:
                                    return res
                        return None

                    found_price = find_price(nd)
                    if found_price:
                        if isinstance(found_price, (int, float)):
                            item['price'] = f"R{float(found_price):.2f}"
                        else:
                            item['price'] = 'R' + found_price if not str(found_price).startswith('R') else str(found_price)
                except Exception:
                    pass
        
        # 3. **CRITICAL: Get actual product image**
        if not item['productImageURL']:
            item['productImageURL'] = self.extract_product_image(response)
        # 4. Derive category if not found yet
        if not item.get('category'):
            item['category'] = self.extract_category(response, json_ld_data, item.get('productName'))
        
        # Log results (use ProductURL)
        print(f"\n{'='*50}")
        print(f"productURL: {item['productURL']}")
        print(f"Product: {item['productName']}")
        print(f"Price: {item['price']}")
        print(f"Image: {item['productImageURL']}")
        print(f"Category: {item.get('category')}")
        print(f"{'='*50}\n")
        
        # Normalize final item keys and values (ensure ProductURL is normalized and image is https)
        if item.get('productURL'):
            item['productURL'] = item['productURL'].rstrip('/')
        if item.get('productImageURL'):
            # prefer https scheme
            if item['productImageURL'].startswith('http://'):
                item['productImageURL'] = item['productImageURL'].replace('http://', 'https://', 1)
        yield {
            'productURL': item.get('productURL'),
            'productName': item.get('productName'),
            'price': item.get('price'),
            'productImageURL': item.get('productImageURL'),
            'category': item.get('category'),
        }

    def extract_category(self, response, json_ld=None, product_name=None):
        """Extract a category from JSON-LD, breadcrumbs, or NEXT_DATA"""
        self.logger.debug(f"extract_category: starting for {response.url}")
        # 1) Try JSON-LD
        if json_ld and isinstance(json_ld, dict):
            if json_ld.get('category'):
                self.logger.debug(f"extract_category: found category in json_ld: {json_ld.get('category')}")
                return json_ld.get('category')
            # some schemas may use productCategory or categoryPath
            if json_ld.get('productCategory'):
                return json_ld.get('productCategory')
        # 2) Breadcrumbs
        breadcrumb_selectors = [
            'nav.breadcrumb a::text',
            'nav[aria-label="breadcrumb"] a::text',
            'ul.breadcrumb li a::text',
            '.breadcrumbs a::text',
            '.breadcrumb a::text',
            '.breadcrumbs li::text',
            '.breadcrumb li::text',
        ]
        crumbs = []
        # debug: find what breadcrumb selectors match
        for sel in breadcrumb_selectors:
            c = response.css(sel).getall()
            if c:
                self.logger.debug(f"extract_category: selector {sel} found breadcrumbs: {c}")
                # reuse existing logic
            else:
                self.logger.debug(f"extract_category: selector {sel} found nothing")
        for sel in breadcrumb_selectors:
            c = response.css(sel).getall()
            if c:
                crumbs = [t.strip() for t in c if t and t.strip()]
                if crumbs:
                    # remove 'Home' if present
                    crumbs = [x for x in crumbs if x.lower() not in ('home', 'products')]
                    if crumbs:
                        # If last crumb equals product name, prefer previous crumb as category
                        if product_name and crumbs[-1].strip().lower() == product_name.strip().lower() and len(crumbs) > 1:
                            return crumbs[-2]
                        return crumbs[-1]
        # 3) Try anchors linking to departments
        dept_anchors = response.css('a[href*="/department/"]::text').getall() or response.css('a[href*="/departments/"]::text').getall()
        if dept_anchors:
            dept_anchors = [t.strip() for t in dept_anchors if t and t.strip() and t.lower() not in ('home', 'shop', 'products')]
            self.logger.debug(f"extract_category: dept anchors: {dept_anchors}")
            if dept_anchors:
                # prefer the last anchor which is closest to the product context
                return dept_anchors[-1]

        # 4) Try __NEXT_DATA__ for department/category
        next_data_script = response.css('script#__NEXT_DATA__::text').get()
        if next_data_script:
            try:
                nd = json.loads(next_data_script)
                self.logger.debug(f"extract_category: found NEXT_DATA script with keys: {list(nd.keys())}")

                def find_category(obj):
                    if isinstance(obj, dict):
                        for k, v in obj.items():
                            if k and k.lower() in ('department', 'category', 'categories', 'categoryname', 'departmentname'):
                                if isinstance(v, str) and v.strip():
                                    return v.strip()
                                if isinstance(v, dict) and v.get('name'):
                                    return v.get('name')
                            res = find_category(v)
                            if res:
                                return res
                    elif isinstance(obj, list):
                        for el in obj:
                            res = find_category(el)
                            if res:
                                return res
                    return None

                # Build an id->name map by recursively searching structures containing 'id' and 'name' keys
                def build_id_name_map(obj, out=None):
                    if out is None:
                        out = {}
                    if isinstance(obj, dict):
                        if 'id' in obj and 'name' in obj and isinstance(obj.get('id'), (int, str)) and isinstance(obj.get('name'), str):
                            try:
                                out[str(obj.get('id'))] = obj.get('name')
                            except Exception:
                                pass
                        for k, v in obj.items():
                            build_id_name_map(v, out)
                    elif isinstance(obj, list):
                        for el in obj:
                            build_id_name_map(el, out)
                    return out

                def find_name_by_id(obj, target):
                    # Recursively search for an object where 'id' matches target and return its 'name' or 'displayName'
                    if isinstance(obj, dict):
                        # Compare as strings to be flexible
                        if 'id' in obj and str(obj.get('id')) == str(target):
                            if 'displayName' in obj and obj.get('displayName'):
                                return obj.get('displayName')
                            if 'name' in obj and obj.get('name'):
                                return obj.get('name')
                        for k, v in obj.items():
                            res = find_name_by_id(v, target)
                            if res:
                                return res
                    elif isinstance(obj, list):
                        for el in obj:
                            res = find_name_by_id(el, target)
                            if res:
                                return res
                    return None

                # First, try targeted paths where site usually keeps product data
                candidate_paths = [
                    ['props', 'pageProps', 'initialState'],
                    ['props', 'pageProps', 'initialProps'],
                    ['props', 'pageProps', 'product'],
                    ['props', 'pageProps', 'productData'],
                    ['props', 'pageProps', 'pageProps'],
                    ['props', 'pageProps'],
                    ['props'],
                ]
                # Build id->name map once from the entire NEXT_DATA structure
                id_map = build_id_name_map(nd)
                # debug: log a small snapshot of id_map
                try:
                    keys = list(id_map.keys())[:5]
                    sample = {k: id_map[k] for k in keys}
                    self.logger.debug(f"extract_category: built id_map sample keys: {sample}")
                except Exception:
                    pass
                for path in candidate_paths:
                    try:
                        obj = nd
                        for p in path:
                            obj = obj.get(p) if isinstance(obj, dict) else None
                        self.logger.debug(f"extract_category: NEXT_DATA path {path} keys: {list(obj.keys()) if isinstance(obj, dict) else type(obj)}")
                        if obj:
                            # quick checks for common shapes
                            if isinstance(obj, dict):
                                # displayCategories is often an array of category objects
                                if 'displayCategories' in obj and obj.get('displayCategories'):
                                    d = obj.get('displayCategories')
                                    # for debugging, log the displayCategories raw content
                                    try:
                                        from pprint import pformat
                                        self.logger.debug(f"extract_category: displayCategories raw: {pformat(d)[:200]}")
                                    except Exception:
                                        self.logger.debug("extract_category: displayCategories present but couldn't pretty print")
                                    d = obj.get('displayCategories')
                                    # try to extract display name(s)
                                    try:
                                        if isinstance(d, list):
                                            # try last non-empty name
                                            for el in reversed(d):
                                                if isinstance(el, dict) and el.get('name'):
                                                    self.logger.debug(f"extract_category: using displayCategories name: {el.get('name')}")
                                                    return el.get('name')
                                                elif isinstance(el, str) and el.strip():
                                                    return el.strip()
                                            # if content is plain integers or ids, just log them and continue
                                            # nothing else to do here
                                    except Exception:
                                        pass
                                if 'merchandiseCategory' in obj and obj.get('merchandiseCategory'):
                                    mc = obj.get('merchandiseCategory')
                                    try:
                                        mc_str = str(mc)
                                    except Exception:
                                        mc_str = None
                                    if mc_str and mc_str in id_map:
                                        mapped = id_map.get(mc_str)
                                        self.logger.debug(f"extract_category: merchandiseCategory {mc} mapped to name: {mapped}")
                                        return mapped
                                    # try to find it by recursing the ND with find_name_by_id
                                    mapped2 = find_name_by_id(nd, mc)
                                    if mapped2:
                                        self.logger.debug(f"extract_category: merchandiseCategory {mc} found via find_name_by_id: {mapped2}")
                                        return mapped2
                                    # fallback: if it's a string-like name already
                                    if isinstance(mc, str) and mc.strip() and not mc_str.isdigit():
                                        self.logger.debug(f"extract_category: using merchandiseCategory (string): {mc}")
                                        return mc.strip()
                            found = find_category(obj)
                            if found:
                                self.logger.debug(f"extract_category: found category in NEXT_DATA via path {path}: {found}")
                                return found
                    except Exception:
                        continue
                # Fallback to general find
                found = find_category(nd)
                if found:
                    self.logger.debug(f"extract_category: found category in NEXT_DATA: {found}")
                    return found
            except Exception:
                pass
        # 4) Try meta tags (keywords or article section)
        meta_kw = response.css('meta[name="keywords"]::attr(content)').get()
        if meta_kw:
            parts = [p.strip() for p in meta_kw.split(',') if p.strip()]
            # heuristically pick the shortest plausible category-like token
            for p in parts:
                if len(p.split()) <= 3 and len(p) > 2 and not any(bad in p.lower() for bad in ('checkers', 'south africa', 'online')):
                    self.logger.debug(f"extract_category: found meta keyword candidate: {p}")
                    return p
        meta_section = response.css('meta[property="article:section"]::attr(content)').get() or response.css('meta[name="article:section"]::attr(content)').get()
        if meta_section:
            self.logger.debug(f"extract_category: found article:section {meta_section}")
            return meta_section
        # 5) As a last resort, search for common category names in the visible page text and product name (heuristic)
        common_categories = ['Stationery', 'Toiletries', 'Personal Care', 'Health', 'Groceries', 'Bakery', 'Beverages', 'Electronics', 'Baby']
        # Additional keyword-to-category mapping to catch common items from product names
        keyword_category_map = {
            'Stationery': ['pencil', 'crayon', 'pen', 'stationery', 'notebook', 'book', 'paper', 'diary', 'counter book', 'office', 'stationery'],
            'Toiletries': ['toilet', 'toiletries', 'soap', 'bath', 'shower', 'toilet paper'],
            'Personal Care': ['toothpaste', 'toothbrush', 'deodorant', 'conditioner', 'shampoo', 'lotion', 'skincare', 'razor'],
            'Health': ['vitamin', 'paracetamol', 'aspirin', 'cold', 'syrup', 'medicine', 'capsule'],
            'Groceries': ['milk', 'bread', 'butter', 'cheese', 'grocery', 'rice', 'pasta', 'flour'],
            'Bakery': ['bakery', 'cake', 'bread', 'bake'],
            'Beverages': ['cola', 'drink', 'juice', 'tea', 'coffee', 'beverage'],
            'Electronics': ['charger', 'battery', 'headphone', 'earbud', 'electronic', 'camera'],
            'Baby': ['baby', 'nappy', 'diaper', 'milk formula'],
        }
        body_text = response.text or ''
        for cat in common_categories:
            if re.search(r'\b' + re.escape(cat) + r'\b', body_text, re.IGNORECASE):
                self.logger.debug(f"extract_category: found category by heuristic: {cat}")
                return cat
        # Also check product name and body text for keyword-category matches
        if product_name:
            pn = product_name.lower()
            for cat, keywords in keyword_category_map.items():
                for kw in keywords:
                    if kw in pn:
                        self.logger.debug(f"extract_category: matched product_name keyword '{kw}' to category '{cat}'")
                        return cat
        for cat, keywords in keyword_category_map.items():
            for kw in keywords:
                if kw in body_text.lower():
                    self.logger.debug(f"extract_category: matched body_text keyword '{kw}' to category '{cat}'")
                    return cat
        self.logger.debug("extract_category: no category found via heuristics")
        return None

    def extract_json_ld(self, response):
        """Extract product data from JSON-LD"""
        json_ld_scripts = response.css('script[type="application/ld+json"]::text').getall()
        
        for script in json_ld_scripts:
            try:
                data = json.loads(script)
                
                # Look for product schema
                if isinstance(data, dict):
                    schema_type = data.get('@type', '')
                    
                    if schema_type in ['Product', 'ProductModel']:
                        result = {}
                        
                        # Get name
                        result['name'] = data.get('name') or data.get('title')
                        
                        # Get price
                        if 'offers' in data:
                            offers = data['offers']
                            if isinstance(offers, dict):
                                result['price'] = offers.get('price')
                            elif isinstance(offers, list) and len(offers) > 0:
                                result['price'] = offers[0].get('price') if isinstance(offers[0], dict) else None
                        
                        # Get image
                        image_data = data.get('image')
                        if image_data:
                            if isinstance(image_data, str):
                                result['image'] = image_data
                            elif isinstance(image_data, list) and len(image_data) > 0:
                                # Get the first image
                                first_img = image_data[0]
                                if isinstance(first_img, str):
                                    result['image'] = first_img
                                elif isinstance(first_img, dict):
                                    result['image'] = first_img.get('url')
                        
                        if result.get('name') or result.get('price') or result.get('image') or result.get('category'):
                            return result
                
                # Check for list of schemas
                elif isinstance(data, list):
                    for item in data:
                        if isinstance(item, dict) and item.get('@type') in ['Product', 'ProductModel']:
                            result = {}
                            result['name'] = item.get('name') or item.get('title')
                            
                            if 'offers' in item:
                                offers = item['offers']
                                if isinstance(offers, dict):
                                    result['price'] = offers.get('price')
                            
                            image_data = item.get('image')
                            if image_data:
                                if isinstance(image_data, str):
                                    result['image'] = image_data
                                elif isinstance(image_data, list) and len(image_data) > 0:
                                    first_img = image_data[0]
                                    if isinstance(first_img, str):
                                        result['image'] = first_img
                            
                            if result.get('name') or result.get('price') or result.get('image') or result.get('category'):
                                return result
                                
            except json.JSONDecodeError:
                continue
        
        return None

    def extract_product_image(self, response):
        """Extract the actual product image (not share card)"""
        # Helper
        def parse_srcset(srcset):
            # returns list of (url, width) pairs
            pairs = []
            for part in (srcset or '').split(','):
                p = part.strip()
                if not p:
                    continue
                parts = p.split()
                url = parts[0]
                width = None
                if len(parts) > 1 and parts[1].endswith('w'):
                    try:
                        width = int(parts[1][:-1])
                    except Exception:
                        width = None
                pairs.append((url, width))
            return pairs

        def join_and_check(src):
            if not src:
                return None
            src = src.strip()
            if src.startswith('//'):
                src = 'https:' + src
            try:
                return response.urljoin(src)
            except Exception:
                return src

        # Helper to normalize internal catalog hosts to a public catalog domain
        def normalize_catalog_url(u):
            try:
                ulow = u.lower()
                if 'catalog-admin.prod-be.svc.cluster.local' in ulow:
                    return u.replace('http://catalog-admin.prod-be.svc.cluster.local:9420', 'https://catalog.sixty60.co.za')
                if 'catalog-admin' in ulow and 'svc.cluster.local' in ulow:
                    return re.sub(r'http[s]?://[^/]+', 'https://catalog.sixty60.co.za', u)
                return u
            except Exception:
                return u

        # Derive SKU from URL if present
        sku = None
        try:
            m = re.search(r"-([A-Z0-9]{6,})($|\.|-)", response.url)
            if m:
                sku = m.group(1)
        except Exception:
            sku = None

        # Candidate list (url, width if available)
        candidates = []

        # 1) Use JSON-LD or OG image if present via meta tags
        og = response.css('meta[property="og:image"]::attr(content)').get()
        if og:
            candidates.append((join_and_check(og), None))

        # 1b) Try to parse Next.js __NEXT_DATA__ JSON to find product images (server-side data)
        next_data_script = response.css('script#__NEXT_DATA__::text').get()
        if next_data_script:
            try:
                nd = json.loads(next_data_script)

                def find_image_strings(obj):
                    res = []
                    if isinstance(obj, dict):
                        for k, v in obj.items():
                            res += find_image_strings(v)
                    elif isinstance(obj, list):
                        for el in obj:
                            res += find_image_strings(el)
                    elif isinstance(obj, str):
                        if obj.startswith('http') and any(ext in obj.lower() for ext in ['.png', '.jpg', '.jpeg', '.gif', '/files/', 'catalog.six']):
                            res.append(obj)
                    return res

                nd_imgs = find_image_strings(nd)
                for ui in nd_imgs:
                    candidates.append((join_and_check(ui), None))
            except Exception:
                pass
        
        # Strategy 2: Look in product image containers
        product_containers = [
            'div.product-detail__main-image',
            '.product-image-container',
            '.product-gallery',
            '[data-qa="product-image"]',
            '.main-product-image',
        ]
        
        for container_sel in product_containers:
            container = response.css(container_sel)
            if container:
                imgs = container.css('img')
                for img in imgs:
                        src = img.css('::attr(src)').get() or img.css('::attr(data-src)').get()
                        srcset = img.css('::attr(srcset)').get() or img.css('::attr(data-srcset)').get()
                        # prefer srcset entries if available and parse the largest one
                        if srcset:
                            pairs = parse_srcset(srcset)
                            # choose largest width if specified
                            pairs = [(join_and_check(u), w) for u, w in pairs if u]
                            pairs = [p for p in pairs if p[0]]
                            if pairs:
                                # pick the highest width if available
                                pairs_sorted = sorted(pairs, key=lambda x: (x[1] or 0), reverse=True)
                                candidates.append(pairs_sorted[0])
                        if src:
                            candidates.append((join_and_check(src), None))
        
        # Strategy 3: Look for images that might be product images
        all_imgs = response.css('img')
        candidate_imgs = []
        
        for img in all_imgs:
            src = img.css('::attr(src)').get() or img.css('::attr(data-src)').get()
            srcset = img.css('::attr(srcset)').get() or img.css('::attr(data-srcset)').get()
            if not src or src.startswith('data:') or src.lower().endswith('.svg'):
                continue
            
            src_lower = src.lower()
            alt = img.css('::attr(alt)').get() or ''
            alt_lower = alt.lower()
            
            # Skip obviously wrong images
            if any(bad in src_lower for bad in ['share-card', 'logo', 'icon', 'banner', 'header', 'footer']):
                continue
            
            if any(bad in alt_lower for bad in ['logo', 'icon', 'banner']):
                continue
            
            # Check if it looks like a product image
            if any(good in src_lower for good in ['product', 'item', 'sku', 'image']):
                candidate_imgs.append(src)
            elif any(good in alt_lower for good in ['product', 'item', 'colgate', 'toothpaste']):
                candidate_imgs.append(src)
        
        # Add candidates discovered from candidate_imgs (parse alt emphasis)
        for c in candidate_imgs:
            candidates.append((join_and_check(c), None))

        # Also parse picture/source elements
        source_srcsets = response.css('picture source::attr(srcset), source::attr(srcset)').getall() or []
        for ss in source_srcsets:
            pairs = parse_srcset(ss)
            pairs = [(join_and_check(u), w) for u, w in pairs if u]
            if pairs:
                pairs_sorted = sorted(pairs, key=lambda x: (x[1] or 0), reverse=True)
                candidates.append(pairs_sorted[0])
        
        # Strategy 4: Get any non-share-card image
        all_img_srcs = response.css('img::attr(src), img::attr(data-src), img::attr(srcset), img::attr(data-srcset)').getall()
        for img_src in all_img_srcs:
            if not img_src:
                continue
            # If src contains multiple entries (srcset), parse them
            if ',' in img_src and ' ' in img_src:
                pairs = parse_srcset(img_src)
                for u, w in pairs:
                    candidates.append((join_and_check(u), w))
            else:
                candidates.append((join_and_check(img_src), None))
        
        # Filter candidates: remove None, duplicates, data:, svg, logos, share-card, trackers
        seen = set()
        filtered = []
        trackers = ['t.co', 'twitter', 'adsct', 'ads-twitter', 'tracking', 'doubleclick']
        bad_phrases = ['share-card', 'logo', 'icon', 'banner', 'header', 'footer']
        for src, w in candidates:
            if not src:
                continue
            low = src.lower()
            if src in seen:
                continue
            seen.add(src)
            if low.startswith('data:') or low.endswith('.svg'):
                continue
            if any(bad in low for bad in bad_phrases):
                continue
            if any(tr in low for tr in trackers):
                continue
            if not (low.startswith('http://') or low.startswith('https://')):
                continue
            filtered.append((src, w))

        if not filtered:
            # Debug: show candidates found before returning None
            # print/debug some of the candidates for inspection
            try:
                from pprint import pformat
                self.logger.debug(f"Image candidates before filter: {pformat(candidates[:10])}")
            except Exception:
                pass
            return None

        # Prefer site-hosted images (catalog, sixty60, checkers)
        site_preference = ['catalog', 'sixty60', 'checkers', '/files/']
        for src, w in filtered:
            low = src.lower()
            if any(pref in low for pref in site_preference):
                return normalize_catalog_url(src)

        # Otherwise choose the largest width if available
        filtered_sorted = sorted(filtered, key=lambda x: (x[1] or 0), reverse=True)
        chosen = filtered_sorted[0][0]
        # Normalize internal admin hosts to public catalog domain when encountered
        try:
            low = chosen.lower()
            if 'catalog-admin.prod-be.svc.cluster.local' in low:
                # Replace internal host with public catalog host
                chosen = chosen.replace('http://catalog-admin.prod-be.svc.cluster.local:9420', 'https://catalog.sixty60.co.za')
            elif 'catalog-admin' in low and 'svc.cluster.local' in low:
                chosen = re.sub(r'http[s]?://[^/]+', 'https://catalog.sixty60.co.za', chosen)
        except Exception:
            pass
        self.logger.debug(f"Image candidates filtered: {filtered_sorted[:6]}")
        self.logger.info(f"Selected product image: {chosen}")
        return chosen

    def errback(self, failure):
        """Simple error handling"""
        yield {
            'url': failure.request.url,
            'error': str(failure.value),
            'scraped_at': datetime.now().isoformat(),
        }


# Run with: scrapy crawl checkers_simple -o output.json