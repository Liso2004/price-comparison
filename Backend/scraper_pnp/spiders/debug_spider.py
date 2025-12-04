import scrapy
import json
import pytz
from datetime import datetime
from scrapy_playwright.page import PageMethod
import logging

class DebugSpider(scrapy.Spider):
    name = 'debug_picknpay'
    allowed_domains = ['pnp.co.za']
    
    custom_settings = {
        'DOWNLOAD_DELAY': 5.0,  # Reduced for testing
        'CONCURRENT_REQUESTS': 1,
        'ROBOTSTXT_OBEY': True,
    }
    
    def start_requests(self):
        self.logger.info("🚀 Starting debug spider...")
        
        # Test with just 3 categories first
        test_urls = [
            'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:food-cupboard-423144840',
            'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:chocolates-chips-and-snacks-423144840',
            'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:beverages-423144840',
        ]
        
        for i, url in enumerate(test_urls):
            self.logger.info(f"📦 Queueing request {i+1} for: {url}")
            yield scrapy.Request(
                url=url,
                callback=self.parse_category,
                meta={
                    'playwright': True,
                    'playwright_page_methods': [
                        PageMethod('wait_for_selector', 'div.product-grid-item', timeout=15000),
                    ],
                    'download_delay': 5.0,
                    'category_name': f'Test Category {i+1}',
                },
                errback=self.errback,
            )
    
    async def parse_category(self, response):
        self.logger.info(f"✅ Successfully loaded: {response.url}")
        self.logger.info(f"📄 Response status: {response.status}")
        
        products = response.css('div.product-grid-item')
        self.logger.info(f"🎯 Found {len(products)} products")
        
        # Extract just 2 products
        for i, product in enumerate(products[:2]):
            name = product.attrib.get('data-cnstrc-item-name', 'Unknown')
            price = product.attrib.get('data-cnstrc-item-price', 'Unknown')
            self.logger.info(f"📦 Product {i+1}: {name} - R{price}")
            
            yield {
                'name': name,
                'price': f"R{price}",
                'category': response.meta.get('category_name'),
                'url': response.url,
            }
        
        self.logger.info(f"🏁 Finished processing {response.url}")
    
    async def errback(self, failure):
        self.logger.error(f"❌ Request failed: {failure}")