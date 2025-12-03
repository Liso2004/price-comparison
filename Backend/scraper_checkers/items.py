# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html
# items.py

import scrapy


class CheckersScraperItem(scrapy.Item):
    # Define fields to match the keys yielded in your spider
    Name = scrapy.Field()
    Final_Price = scrapy.Field()
    Regular_Price = scrapy.Field()
    Discounted_Price = scrapy.Field()
    Description = scrapy.Field()
    Image_URL = scrapy.Field()
    URL = scrapy.Field()
    Scrape_Date = scrapy.Field()
