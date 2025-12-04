# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


# useful for handling different item types with a single interface
# pipelines.py

from itemadapter import ItemAdapter
import re

# You must also enable this in settings.py:
# ITEM_PIPELINES = {
#     "checkers_scraper.pipelines.PriceCleaningPipeline": 300,
# }

class PriceCleaningPipeline:
    def process_item(self, item, spider):
        adapter = ItemAdapter(item)
        
        # List of price fields to clean
        price_fields = ['Final_Price', 'Regular_Price', 'Discounted_Price']
        
        for field_name in price_fields:
            value = adapter.get(field_name)
            
            if value and value != 'N/A':
                # 1. Remove currency symbols (R) and excess spaces
                cleaned_value = re.sub(r'R\s*', '', value)
                # 2. Remove commas (if used as thousands separator)
                cleaned_value = cleaned_value.replace(',', '')
                
                try:
                    # 3. Convert to float for numerical comparison/storage
                    adapter[field_name] = float(cleaned_value)
                except ValueError:
                    # If conversion fails, keep the original text and log a warning
                    spider.logger.warning(f"Failed to convert price '{value}' to float for {field_name} in {adapter.get('URL')}")
                    adapter[field_name] = value 
                    
        return item
