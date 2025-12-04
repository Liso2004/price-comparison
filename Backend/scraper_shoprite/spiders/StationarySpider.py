import scrapy
from scrapy_playwright.page import PageMethod
from urllib.parse import urljoin

class StationarySpider(scrapy.Spider):
    name = 'stationaryspider'
    allowed_domains = ['shoprite.co.za']
    
    # Performance optimization settings
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
            "https://www.shoprite.co.za/c-1110/All-Departments/Household/Stationery-and-Newsagent/Cutting-and-Sticking?q=%3Arelevance%3AbrowseAllStoresFacet%3AbrowseAllStoresFacet%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=0",
            "https://www.shoprite.co.za/c-1110/All-Departments/Household/Stationery-and-Newsagent/Cutting-and-Sticking?q=%3Arelevance%3AbrowseAllStoresFacet%3AbrowseAllStoresFacet%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=1",
            "https://www.shoprite.co.za/c-1110/All-Departments/Household/Stationery-and-Newsagent/Cutting-and-Sticking"
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
                        PageMethod("wait_for_selector", ".item-product", timeout=45000),
                    ],
                    "playwright_page_goto_kwargs": {
                        "wait_until": "domcontentloaded",
                        "timeout": 60000,
                    },
                },
                callback=self.parse
            )
    
    async def parse(self, response):
        # Product container detection
        products = response.css('.item-product')
        self.logger.info(f"Found {len(products)} products on {response.url}")
        
        # Fallback selectors if primary fails
        if not products:
            alternative_selectors = [
                '.js-product-container',
                '[data-product-code]',
                '.product-item',
                '.product-frame'
            ]
            
            for selector in alternative_selectors:
                alt_products = response.css(selector)
                if alt_products:
                    products = alt_products
                    break
            
            if not products:
                self.logger.error("No products found with any selector")
                return
        
        # Product data extraction
        for product in products:
            try:
                product_data = {
                    'name': product.css('h3.item-product__name a::text').get(),
                    'price': ''.join(product.css('.special-price .now ::text').getall()).strip(),
                    'original_price': product.css('.special-price__price .before::text').get(),
                    'savings': product.css('.special-price__extra__title::text').get(),
                    'image_url': product.css('.item-product__image img::attr(src)').get(),
                    'category': 'Stationery',
                    'product_id': product.css('::attr(data-product-code)').get(),
                    'product_url': product.css('h3.item-product__name a::attr(href)').get(),
                    'valid_until': product.css('.item-product__valid::text').get(),
                    'page_url': response.url,
                }
                
                # Data cleaning and normalization
                if product_data['name']:
                    product_data['name'] = product_data['name'].strip()
                
                if product_data['product_url'] and not product_data['product_url'].startswith('http'):
                    product_data['product_url'] = urljoin('https://www.shoprite.co.za', product_data['product_url'])
                
                # Fallback ID extraction from GA data
                if not product_data['product_id']:
                    ga_data = product.css('::attr(data-product-ga)').get()
                    if ga_data and '"id":"' in ga_data:
                        import re
                        match = re.search(r'"id":"([^"]+)"', ga_data)
                        if match:
                            product_data['product_id'] = match.group(1)
                
                yield product_data
                
            except Exception as e:
                self.logger.error(f"Error processing product: {e}")
                continue
        
        # Pagination handling
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
                    break
        
        if next_page:
            if not next_page.startswith('http'):
                next_page = urljoin('https://www.shoprite.co.za', next_page)
            
            yield scrapy.Request(
                url=next_page,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                },
                meta={
                    "playwright": True,
                    "playwright_include_page": True,
                    "playwright_page_methods": [
                        PageMethod("wait_for_selector", ".item-product", timeout=45000),
                    ],
                    "playwright_page_goto_kwargs": {
                        "wait_until": "domcontentloaded",
                        "timeout": 60000,
                    },
                },
                callback=self.parse
            )