import scrapy
from scrapy_playwright.page import PageMethod
from urllib.parse import urljoin

class GroceriesSpider(scrapy.Spider):
    name = 'groceriesspider'
    allowed_domains = ['shoprite.co.za']
    
    # Configure Playwright settings for performance and resource blocking
    custom_settings = {
        'PLAYWRIGHT_DEFAULT_NAVIGATION_TIMEOUT': 60000,
        'PLAYWRIGHT_ABORT_REQUEST': lambda req: (
            req.resource_type in {"image", "stylesheet", "font"} 
            or any(domain in req.url for domain in [
                "google-analytics.com", 
                "doubleclick.net",
                "facebook.com",
                "googletagmanager.com",
                "creativecdn.com",
                "useinsider.com",
                "hotjar.com",
                "crazyegg.com"
            ])
        ),
    }
    
    def start_requests(self):
        urls = [
         
            "https://www.shoprite.co.za/search/all?q=cruzer",
           
        ]
        
        custom_headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        }
        
        for url in urls:
            yield scrapy.Request(
                url=url,
                headers=custom_headers,
                meta={
                    "playwright": True,
                    "playwright_include_page": True,
                    "playwright_page_methods": [
                    PageMethod("wait_for_timeout", 10000),
                    ],
                    "playwright_page_goto_kwargs": {
                        "wait_until": "networkidle",
                        "timeout": 60000,
                    },
                },
                callback=self.parse
            )
    
    async def parse(self, response):
        self.logger.info(f"Successfully reached page: {response.url}")
        
        products = response.css('.item-product')
        
        self.logger.info(f"Found {len(products)} products")
        
        if not products:
            self.logger.warning("No products found - trying alternative selectors")
            
            alternative_selectors = [
                '.js-product-container',
                '.item-product',
                '[data-product-code]',
                '.product-item'
            ]
            
            for selector in alternative_selectors:
                alt_products = response.css(selector)
                if alt_products:
                    self.logger.info(f"Found {len(alt_products)} products with selector: {selector}")
                    products = alt_products
                    break
            
            if not products:
                self.logger.error("No products found with any selector")
                with open('debug_page.html', 'w', encoding='utf-8') as f:
                    f.write(response.text)
                with open('debug_selectors.txt', 'w', encoding='utf-8') as f:
                    f.write("Available product-related classes:\n")
                    for cls in response.css('[class]::attr(class)').getall():
                        if 'product' in cls.lower() or 'item' in cls.lower():
                            f.write(f"{cls}\n")
                return
        
        for product in products:
            try:
                # Extract product information from each product item
                # Extract product information from each product item
                product_data = {
                    'name': product.css('h3.item-product__name a::text').get(),
                    # FIXED PRICE SELECTOR - gets full price including superscript
                    'price': ''.join(product.css('.special-price .now ::text').getall()).strip(),
                    'unit_price': ''.join(product.css('.special-price .now ::text').getall()).strip(),
                    'image_url': product.css('.item-product__image img::attr(src)').get(),
                    'category': 'Food',
                    'product_id': product.css('::attr(data-product-code)').get(),
                    'brand': product.css('::attr(data-brand)').get(),
                    'valid_until': product.css('.item-product__valid::text').get(),
                    'product_url': product.css('h3.item-product__name a::attr(href)').get(),
                    'page_url': response.url,
                }
                
                if product_data['name']:
                    product_data['name'] = product_data['name'].strip()
                
                if product_data['product_url'] and not product_data['product_url'].startswith('http'):
                    product_data['product_url'] = urljoin('https://www.shoprite.co.za', product_data['product_url'])
                
                if not product_data['product_id']:
                    ga_data = product.css('::attr(data-product-ga)').get()
                    if ga_data and '"id":"' in ga_data:
                        import re
                        match = re.search(r'"id":"([^"]+)"', ga_data)
                        if match:
                            product_data['product_id'] = match.group(1)
                
                if not product_data['brand']:
                    ga_data = product.css('::attr(data-product-ga)').get()
                    if ga_data and '"brand":"' in ga_data:
                        import re
                        match = re.search(r'"brand":"([^"]+)"', ga_data)
                        if match:
                            product_data['brand'] = match.group(1)
                
                yield product_data
                
            except Exception as e:
                self.logger.error(f"Error processing product: {e}")
                continue
        
        # Follow pagination links to next page
        next_page = response.css('a.next::attr(href)').get()
        if not next_page:
            next_page_selectors = [
                'a[rel="next"]::attr(href)',
                '.pagination__next a::attr(href)',
                '.next-page::attr(href)',
                'li.pagination__item--next a::attr(href)',
                'a.pagination__next::attr(href)'
            ]
            
            for selector in next_page_selectors:
                next_page = response.css(selector).get()
                if next_page:
                    self.logger.info(f"Found next page with selector: {selector}")
                    break
        
        if next_page:
            if not next_page.startswith('http'):
                next_page = urljoin('https://www.shoprite.co.za', next_page)
            
            self.logger.info(f"Following next page: {next_page}")
            
            yield scrapy.Request(
                url=next_page,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                },
                meta={
                    "playwright": True,
                    "playwright_include_page": True,
                    "playwright_page_methods": [
                      PageMethod("wait_for_timeout", 10000),
                    ],
                    "playwright_page_goto_kwargs": {
                        "wait_until": "networkidle",
                        "timeout": 60000,
                    },
                },
                callback=self.parse
            )
        else:
            self.logger.info("No more pages to follow")