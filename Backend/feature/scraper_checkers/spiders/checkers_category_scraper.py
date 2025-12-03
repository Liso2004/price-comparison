import scrapy
from scrapy import Request
from scrapy.http import Response


class JSTableSpider(scrapy.Spider):
    name = "js_table"

    # Start URL
    start_urls = [
        "https://checkers.co.za/department/toiletries-1-67075d99ff987811364006cf"
    ]

    custom_settings = {
        "DOWNLOAD_HANDLERS": {
            "http": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler",
            "https": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler",
        },
        "TWISTED_REACTOR": "twisted.internet.asyncioreactor.AsyncioSelectorReactor",
        "PLAYWRIGHT_BROWSER_TYPE": "chromium",
        
        # More realistic settings
        "CONCURRENT_REQUESTS": 1,  # Be more gentle
        "DOWNLOAD_DELAY": 2,  # Add delay between requests
        "AUTOTHROTTLE_ENABLED": True,
        
        "PLAYWRIGHT_LAUNCH_OPTIONS": {
            "headless": True,  # Set to True for production
            "args": [
                "--disable-blink-features=AutomationControlled",
                "--disable-dev-shm-usage",
                "--no-sandbox",
                "--disable-web-security",
                "--disable-features=VizDisplayCompositor"
            ]
        },

        # Enhanced headers
        "DEFAULT_REQUEST_HEADERS": {
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120.0.0.0 Safari/537.36"
            ),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
        },

        # Enhanced retry settings
        "RETRY_ENABLED": True,
        "RETRY_TIMES": 3,
        "RETRY_HTTP_CODES": [403, 429, 500, 502, 503, 504],
        
        # Export settings
        "FEEDS": {
            "products.json": {
                "format": "json",
                "encoding": "utf8",
                "indent": 4,
            }
        },
    }

    def start_requests(self):
        """Generate initial requests with Playwright"""
        for url in self.start_urls:
            yield Request(
                url,
                meta={
                    "playwright": True,
                    "playwright_include_page": True,
                    "playwright_context": "persistent"
                },
                callback=self.parse,
                errback=self.errback
            )

    async def parse(self, response: Response):
        """Parse product listings page"""
        
        # Check response status
        if response.status != 200:
            self.logger.warning(f"Non-200 response: {response.status} for {response.url}")
            return
        
        page = response.meta["playwright_page"]
        
        try:
            # Wait for products to load with error handling
            try:
                await page.wait_for_selector("div.product-card_card__DsB3_", timeout=15000)
            except Exception as e:
                self.logger.error(f"Timeout waiting for products: {e}")
                return

            # Extract product blocks
            products = response.css("div.product-card_card__DsB3_")
            category = response.url.split("/department/")[-1].split("-1-")[0]
            
            if not products:
                self.logger.warning("No products found on page")
                return
                
            self.logger.info(f"Found {len(products)} products on page")

            for product in products:
                # Defensive data extraction with cleaning
                product_name = product.css("p.product-card_product-name__8wxGT::text").get()
                current_price = product.css("span.price-display_full__ngphI::text").get()
                current_price_cents = product.css("span.price-display_half__1YePZ::text").get()
                image_url = product.css("picture img::attr(src)").get()
                
                # Clean and validate data
                cleaned_data = {
                    "product_name": product_name.strip() if product_name else None,
                    "current_price": current_price.strip() + current_price_cents.strip() if current_price else None,
                    "unit_price": None,  # Placeholder for future extraction
                    "image_url": response.urljoin(image_url) if image_url else None,
                    "category": category,
                }
                
                # Only yield if we have at least a product name
                if cleaned_data["product_name"]:
                    yield cleaned_data
                else:
                    self.logger.warning("Skipping product with no name")

            # Pagination - More robust handling
            next_page = response.css("a.pagination_next__OvGJM::attr(href)").get()
            if next_page:
                next_url = response.urljoin(next_page)
                self.logger.info(f"Found next page: {next_url}")
                
                yield Request(
                    next_url,
                    meta={
                        "playwright": True,
                        "playwright_include_page": True,
                        "playwright_context": "persistent"
                    },
                    callback=self.parse,
                    errback=self.errback
                )
            else:
                self.logger.info("No more pages found")

        except Exception as e:
            self.logger.error(f"Error parsing page {response.url}: {e}")
        finally:
            # Always close the page to prevent memory leaks
            if page and not page.is_closed():
                await page.close()

    async def errback(self, failure):
        """Handle request errors"""
        page = failure.request.meta.get('playwright_page')
        if page and not page.is_closed():
            await page.close()
        
        self.logger.error(f"Request failed: {failure.value}")

    def closed(self, reason):
        """Called when spider closes"""
        self.logger.info(f"Spider closed: {reason}")


# Optional: Scrapy Item for better data validation
from scrapy.item import Item, Field

class ProductItem(Item):
    product_name = Field()
    current_price = Field()
    image_url = Field()
    url = Field()
    scraped_at = Field()


# Alternative version using Items in the parse method:
"""
async def parse(self, response: Response):
    # ... same setup code ...
    
    for product in products:
        item = ProductItem()
        item['product_name'] = product_name.strip() if product_name else None
        item['current_price'] = current_price.strip() if current_price else None
        item['image_url'] = response.urljoin(image_url) if image_url else None
        item['url'] = response.url
        item['scraped_at'] = datetime.now().isoformat()
        
        if item['product_name']:
            yield item
"""