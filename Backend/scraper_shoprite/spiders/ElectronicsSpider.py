import scrapy
from scrapy_playwright.page import PageMethod
from urllib.parse import urljoin

class ElectronicsSpider(scrapy.Spider):
    name = 'electronicspider'
    allowed_domains = ['shoprite.co.za']
    
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
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=0",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=1",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=2",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=3",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=4",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=5",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=6",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=7",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=8",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=9",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=10",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=11",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=12",
            "https://www.shoprite.co.za/c-2256/All-Departments?q=%3Arelevance%3AallCategories%3Aelectronics%3AallCategories%3Aappliances%3AbrowseAllStoresFacetOff%3AbrowseAllStoresFacetOff&page=13",
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
        products = response.css('.item-product')
        self.logger.info(f"Found {len(products)} products on {response.url}")
        
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
        
        for product in products:
            try:
                product_data = {
                    'name': product.css('h3.item-product__name a::text').get(),
                    'price': ''.join(product.css('.special-price .now ::text').getall()).strip(),
                    'unit_price': ''.join(product.css('.special-price .now ::text').getall()).strip(),
                    'image_url': product.css('.item-product__image img::attr(src)').get(),
                    'category': 'Electronics',
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