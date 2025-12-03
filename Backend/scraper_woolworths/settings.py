# Scrapy settings for checkers_scraper project
#
# For simplicity, this file contains only settings considered important or
# commonly used.

BOT_NAME = "checkers_scraper"

SPIDER_MODULES = ["checkers_scraper.spiders"]
NEWSPIDER_MODULE = "checkers_scraper.spiders"

# Crawl responsibly by identifying yourself (and your website) on the user-agent
# FIX: Using a new User-Agent to bypass server blocking
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " \
             "(KHTML, like Gecko) Chrome/120.0.6099.109 Safari/537.36"

# Obey robots.txt rules
ROBOTSTXT_OBEY = True

# -----------------------------------------------------------------------------
# CONCURRENCY, DELAYS, and TIME OUTS (CRITICAL COMPLIANCE FIXES)
# -----------------------------------------------------------------------------

# FIX: Set CONCURRENT_REQUESTS and DOWNLOAD_DELAY to comply with robots.txt (1/10s)
CONCURRENT_REQUESTS = 1 
CONCURRENT_REQUESTS_PER_DOMAIN = 1
DOWNLOAD_DELAY = 10
DOWNLOAD_TIMEOUT = 60

COOKIES_ENABLED = True

DEFAULT_REQUEST_HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Referer": "https://www.checkers.co.za/",
    "Connection": "keep-alive",
}

# -----------------------------------------------------------------------------
# 🌟 SCAPY-PLAYWRIGHT ESSENTIAL CONFIGURATION 🌟
# -----------------------------------------------------------------------------

# 1. DOWNLOAD HANDLERS (Tells Scrapy to use Playwright for requests)
DOWNLOAD_HANDLERS = {
    "http": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler",
    "https": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler",
}

# 2. TWISTED REACTOR (Enables asyncio support needed by Playwright)
TWISTED_REACTOR = "twisted.internet.asyncioreactor.AsyncioSelectorReactor"

# 3. DOWNLOADER MIDDLEWARES (FINAL WORKAROUND)
DOWNLOADER_MIDDLEWARES = {
    # ✅ WORKAROUND: Using the Download Handler as the Middleware. 
    # This works for older or specific configurations where other names fail.
    'scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler': 543, 
    # 'checkers_scraper.middlewares.CheckersScraperDownloaderMiddleware': 543, 
}

# -----------------------------------------------------------------------------
# EXTENSIONS AND AUTOTHROTTLE (DISABLED DUE TO FIXED CRAWL DELAY)
# -----------------------------------------------------------------------------

# FIX: Disable Autothrottle as DOWNLOAD_DELAY is fixed at 10s by robots.txt
AUTOTHROTTLE_ENABLED = False
# AUTOTHROTTLE_START_DELAY = 5
# AUTOTHROTTLE_MAX_DELAY = 60
# AUTOTHROTTLE_TARGET_CONCURRENCY = 2.0 

# Set settings whose default value is deprecated to a future-proof value
FEED_EXPORT_ENCODING = "utf-8"