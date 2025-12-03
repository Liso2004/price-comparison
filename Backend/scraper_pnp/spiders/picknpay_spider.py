import scrapy
import json
import pytz
from datetime import datetime
from scrapy_playwright.page import PageMethod
from urllib.parse import urljoin
import logging
import re

class JsonWriterPipeline:
    def open_spider(self, spider):
        self.file = open('data/products.json', 'w', encoding='utf-8')
        self.file.write('[\n')
        self.first_item = True

    def close_spider(self, spider):
        self.file.write('\n]')
        self.file.close()

    def process_item(self, item, spider):
        if not self.first_item:
            self.file.write(',\n')
        else:
            self.first_item = False
        
        line = json.dumps(dict(item), ensure_ascii=False, indent=2)
        self.file.write(line)
        return item

class PicknPaySpider(scrapy.Spider):
    name = 'picknpay'
    allowed_domains = ['pnp.co.za', 'cdn-prd-02.pnp.co.za']
    
    custom_settings = {
        'DOWNLOAD_DELAY': 10.0,
        'CONCURRENT_REQUESTS': 1,
        'ROBOTSTXT_OBEY': True,
    }
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.utc_tz = pytz.utc
        
        # List of REQUIRED products to look for
        self.required_products = [
            # Groceries
            {
                'name_keyword': 'Clover UHT Full Cream Long Life Milk 6 x 1L',
                'category': 'Groceries',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:milk-dairy-and-eggs-423144840',
                'sub_category': 'Milk Dairy and Eggs'
            },
            {
                'name_keyword': 'PnP Large Eggs 30 Pack',
                'category': 'Groceries',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:milk-dairy-and-eggs-423144840',
                'sub_category': 'Milk Dairy and Eggs'
            },
            
            # Health & Wellness
            {
                'name_keyword': 'Grand-pa Headache Powder Regular Stick Pack 38 Pack',
                'category': 'Health and Wellness',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:health-and-wellness-423144840',
                'sub_category': 'Health and Wellness'
            },
            {
                'name_keyword': 'Calpol Strawberry Flavoured Paediatric Syrup 100ml',
                'category': 'Health and Wellness',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:health-and-wellness-423144840',
                'sub_category': 'Health and Wellness'
            },
            
            # Household & Cleaning
            {
                'name_keyword': 'Sunlight Original Dishwashing Liquid 750ml',
                'category': 'Cleaning and Household',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:household-and-cleaning-423144840',
                'sub_category': 'Household and Cleaning'
            },
            {
                'name_keyword': 'Surf Stain Removal Hand Washing Powder Detergent 2kg',
                'category': 'Cleaning and Household',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:household-and-cleaning-423144840',
                'sub_category': 'Household and Cleaning'
            },
            
            # Electronics
            {
                'name_keyword': 'Energizer Max AAA 12 Pack',
                'category': 'Electronics',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:electronics-and-office-423144840',
                'sub_category': 'Electronics and Office'
            },
            {
                'name_keyword': 'Sandisk Cruizer Blade 32GB',
                'category': 'Electronics',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:electronics-and-office-423144840',
                'sub_category': 'Electronics and Office'
            },
            
            # Stationery
            {
                'name_keyword': 'Staedtler Colour Pencil Woodfree 24 Pack',
                'category': 'Stationery',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:stationery-423144840',
                'sub_category': 'Stationery'
            },
            {
                'name_keyword': 'PnP A4 Counter Book 96 Pages',
                'category': 'Stationery',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:stationery-423144840',
                'sub_category': 'Stationery'
            },
            
            # Personal Care
            {
                'name_keyword': 'Colgate Triple Action Multibenefit Toothpaste 100ml',
                'category': 'Personal Care',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:personal-care-and-hygiene-423144840',
                'sub_category': 'Personal Care and Hygiene'
            },
            {
                'name_keyword': 'Dettol Antiseptic Liquid 750ml',
                'category': 'Personal Care',
                'category_url': 'https://www.pnp.co.za/c/pnpbase?query=:relevance:allCategories:pnpbase:category:personal-care-and-hygiene-423144840',
                'sub_category': 'Personal Care and Hygiene'
            }
        ]
    
    def within_crawl_window(self):
        """Check if current time is within allowed crawling window"""
        utc_now = datetime.now(self.utc_tz)
        hour, minute = utc_now.hour, utc_now.minute
        
        if hour < 4 or hour > 8:
            return False
        if hour == 8 and minute > 45:
            return False
        return True
    
    def start_requests(self):
        if not self.within_crawl_window():
            self.logger.warning("❌ Outside allowed crawling time (04:00-08:45 UTC)")
            return
        
        self.logger.info("✅ Within crawling window, starting scrape...")
        self.logger.info(f"🎯 Looking for {len(self.required_products)} specific products")
        
        # Group products by category to minimize requests
        categories = {}
        for product in self.required_products:
            cat_url = product['category_url']
            if cat_url not in categories:
                categories[cat_url] = {
                    'main_category': product['category'],
                    'sub_category': product['sub_category'],
                    'products': []
                }
            categories[cat_url]['products'].append(product['name_keyword'])
        
        self.logger.info(f"📂 Processing {len(categories)} categories")
        
        for cat_url, cat_info in categories.items():
            self.logger.info(f"📦 Queueing: {cat_info['main_category']}")
            self.logger.info(f"   Looking for: {', '.join(cat_info['products'][:3])}{'...' if len(cat_info['products']) > 3 else ''}")
            
            yield scrapy.Request(
                url=cat_url,
                callback=self.parse_category,
                meta={
                    'playwright': True,
                    'playwright_page_methods': [
                        PageMethod('wait_for_selector', 'div.product-grid-item', timeout=40000),
                        PageMethod('wait_for_timeout', 8000),
                    ],
                    'download_delay': 10.0,
                    'main_category': cat_info['main_category'],
                    'sub_category': cat_info['sub_category'],
                    'target_products': cat_info['products']
                },
                errback=self.errback,
            )
    
    def parse_category(self, response):
        """Parse category page and look for specific products"""
        main_category = response.meta.get('main_category', 'Unknown')
        sub_category = response.meta.get('sub_category', 'Unknown')
        target_products = response.meta.get('target_products', [])
        
        self.logger.info(f"📁 Processing: {main_category} > {sub_category}")
        self.logger.info(f"🎯 Looking for: {target_products}")
        
        # Extract product elements
        products = response.css('div.product-grid-item')
        
        if not products:
            self.logger.warning("🔍 No products found with main selector, trying alternatives...")
            # Try alternative selectors
            products = response.css('[data-cnstrc-item-id]')
        
        self.logger.info(f"🔍 Found {len(products)} product elements")
        
        found_products = []
        
        # Look for each target product
        for target_name in target_products:
            target_lower = target_name.lower()
            found = False
            
            for product in products:
                # Try to get product name from data attribute
                name = product.attrib.get('data-cnstrc-item-name', '').strip()
                if not name:
                    # Try from CSS selector
                    name = product.css('a.product-grid-item__info-container__name span::text').get()
                    if name:
                        name = name.strip()
                
                if name and target_lower in name.lower():
                    # Found the product! Extract its data
                    item = self.extract_product_data(product, response, main_category, sub_category, name)
                    if item:
                        found_products.append(item)
                        self.logger.info(f"✅ FOUND: {name} - {item['price']}")
                        found = True
                        break
            
            if not found:
                self.logger.warning(f"⚠️ Not found: {target_name}")
        
        # If we didn't find all products, collect some other products from the category
        if len(found_products) < len(target_products):
            self.logger.info(f"🔍 Only found {len(found_products)}/{len(target_products)} required products")
            self.logger.info("🔍 Collecting additional products from category...")
            
            additional_count = 0
            for product in products:
                # Skip if we already have enough
                if len(found_products) >= len(target_products) + 3:  # Get up to 3 extras
                    break
                
                # Extract product name
                name = product.attrib.get('data-cnstrc-item-name', '').strip()
                if not name:
                    name = product.css('a.product-grid-item__info-container__name span::text').get()
                    if name:
                        name = name.strip()
                
                # Check if this is not already in our found products
                if name and not any(name.lower() == item['name'].lower() for item in found_products):
                    item = self.extract_product_data(product, response, main_category, sub_category, name)
                    if item:
                        found_products.append(item)
                        additional_count += 1
                        self.logger.info(f"➕ Additional product: {name} - {item['price']}")
        
        # Yield all found products
        for item in found_products:
            yield item
        
        self.logger.info(f"📊 Extracted {len(found_products)} products from {main_category}")
    
    def extract_product_data(self, product, response, main_category, sub_category, product_name):
        """Extract product data from product element"""
        
        # Get price from data attribute
        price_value = product.attrib.get('data-cnstrc-item-price', '').strip()
        
        # If not in data attribute, try to extract from visible price
        if not price_value:
            price_text = product.css('.price::text').get()
            if price_text:
                price_text = price_text.strip()
                numbers = re.findall(r'\d+\.?\d*', price_text)
                if numbers:
                    price_value = numbers[0]
        
        # Get product ID
        product_id = product.attrib.get('data-cnstrc-item-id', '').strip()
        
        # Get product URL
        product_url = product.css('a.product-action::attr(href)').get()
        if not product_url:
            product_url = product.css('a.product-grid-item__info-container__name::attr(href)').get()
        if not product_url:
            product_url = product.css('a[href*="/p/"]::attr(href)').get()
        
        if product_url:
            product_url = response.urljoin(product_url)
        
        # Get image URL
        image_url = product.css('img::attr(src)').get()
        
        # Get original price if on sale
        original_price = product.css('.old::text').get()
        if original_price:
            original_price = original_price.strip()
        
        # Format price
        price = f"R {price_value}" if price_value and price_value != "0.00" else ""
        
        # Build the complete item
        item = {
            'name': product_name,
            'price': price,
            'price_value': price_value,
            'original_price': original_price,
            'product_url': product_url,
            'image_url': image_url,
            'product_id': product_id,
            'main_category': main_category,
            'sub_category': sub_category,
            'category_url': response.url,
            'scraped_at': datetime.now(self.utc_tz).isoformat(),
            'data_attributes': {
                'item_id': product_id,
                'item_name': product.attrib.get('data-cnstrc-item-name', ''),
                'item_price': product.attrib.get('data-cnstrc-item-price', ''),
                'strategy_id': product.attrib.get('data-cnstrc-strategy-id', ''),
            }
        }
        
        return self.clean_item(item)
    
    def clean_item(self, item):
        """Clean and validate the item data"""
        for key, value in item.items():
            if isinstance(value, str):
                item[key] = self.clean_text(value)
            elif isinstance(value, dict):
                item[key] = {k: self.clean_text(v) if isinstance(v, str) else v 
                           for k, v in value.items()}
        return item
    
    def clean_text(self, text):
        """Clean text by removing extra whitespace"""
        if text:
            return ' '.join(text.strip().split())
        return None
    
    async def errback(self, failure):
        """Handle request errors"""
        self.logger.error(f"❌ Request failed: {failure.value}")