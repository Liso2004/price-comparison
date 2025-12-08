from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import subprocess
import asyncio
import json
import os
from datetime import datetime
import pytz
import re
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# MongoDB setup
from pymongo import MongoClient

MONGO_URI = os.getenv("MONGO_URI")
DB_NAME = os.getenv("MONGO_DB", "priceapp_db")
COLLECTION_NAME = os.getenv("MONGO_COLLECTION", "product_storage")

client = MongoClient(MONGO_URI)
db = client[DB_NAME]
product_collection = db[COLLECTION_NAME]

# LOCAL IMPORT
try:
    from scraper_pnp.time_checker import within_crawl_window
except ImportError:
    # Fallback if time_checker is not available
    def within_crawl_window():
        return True, "Window check unavailable"

# ------------------------------------
#          FASTAPI APP SETUP
# ------------------------------------

app = FastAPI(
    title="Retailer Scraper & Product Search API",
    version="3.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------
#         RESPONSE MODELS (SCRAPER)
# ------------------------------------

class ScrapeResponse(BaseModel):
    status: str
    message: str
    task_id: Optional[str] = None
    timestamp: str

class ScrapeStatus(BaseModel):
    task_id: str
    status: str
    products_scraped: int
    start_time: str
    end_time: Optional[str] = None

scrape_jobs = {}

# ------------------------------------
#      STARTUP - SEED DATABASE
# ------------------------------------

def seed_products_from_cleaned_json():
    """Load cleaned JSON files from all retailers and insert into MongoDB."""
    import os
    
    base_path = os.path.dirname(__file__)
    cleaned_files = [
        ("scraper_pnp/cleaned/picknpay_cleaned_data.json", "Pick n Pay"),
        ("scraper_checkers/cleaned/checkers_scraped_data.json", "Checkers"),
        ("scraper_woolworths/cleaned/woolworths_cleaned.json", "Woolworths"),
        ("scraper_shoprite/cleaned/cleaned_grocery.json", "Shoprite"),
    ]
    
    seeded_count = 0
    
    for file_path, retailer_name in cleaned_files:
        full_path = os.path.join(base_path, file_path)
        
        if not os.path.exists(full_path):
            print(f"⚠️  Cleaned file not found: {full_path}")
            continue
        
        try:
            with open(full_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Handle different JSON structures (some are lists, some are nested)
            if isinstance(data, dict):
                # Handle nested structure like PnP ({"picknpay": [...]})
                products = []
                for key, value in data.items():
                    if isinstance(value, list):
                        products.extend(value)
            elif isinstance(data, list):
                products = data
            else:
                print(f"⚠️  Unexpected data structure in {file_path}")
                continue
            
            # Ensure retailer field is set
            for product in products:
                if 'retailer' not in product or not product['retailer']:
                    product['retailer'] = retailer_name
            
            # Insert into MongoDB
            if products:
                result = product_collection.insert_many(products, ordered=False)
                seeded_count += len(result.inserted_ids)
                print(f"✓ Seeded {len(result.inserted_ids)} products from {retailer_name}")
        
        except Exception as e:
            print(f"✗ Error seeding {retailer_name}: {str(e)}")
    
    return seeded_count

@app.on_event("startup")
async def startup_event():
    """Seed database with cleaned JSON files on app startup."""
    try:
        # Check if collection is empty
        count = product_collection.count_documents({})
        if count == 0:
            print("📦 Database is empty. Seeding with cleaned JSON files...")
            seeded = seed_products_from_cleaned_json()
            print(f"🎉 Seeding complete! Total products: {seeded}")
        else:
            print(f"✓ Database already contains {count} products. Skipping seed.")
    except Exception as e:
        print(f"✗ Error during startup: {str(e)}")

# ------------------------------------
#             ROOT
# ------------------------------------

@app.get("/")
async def root():
    return {
        "message": "Retailer Scraper & Product Search API is running!",
        "status": "active",
        "endpoints": {
            "product_endpoints": {
                "all_products": "GET /products",
                "search_products": "GET /products?search=<query>",
                "filter_by_retailer": "GET /products?retailer=<name>",
                "search_and_retailer": "GET /products?search=<query>&retailer=<name>",
                "products_by_retailer": "GET /products/retailer/{retailer_name}",
                "all_retailers": "GET /retailers",
                "all_categories": "GET /categories",
                "debug_reseed": "POST /debug/reseed"
            },
            "scraper_endpoints": {
                "status": "GET /scrape/status",
                "start_scraping": "POST /scrape/start",
                "get_results": "GET /scrape/results",
                "job_status": "GET /scrape/jobs/{task_id}"
            },
            "docs": "/docs"
        }
    }

@app.post("/debug/reseed")
async def debug_reseed():
    """Debug endpoint: Clear database and reseed from cleaned JSON files."""
    try:
        deleted = product_collection.delete_many({})
        print(f"🗑️  Deleted {deleted.deleted_count} products")
        
        seeded = seed_products_from_cleaned_json()
        total = product_collection.count_documents({})
        retailers = product_collection.distinct("retailer")
        
        # Check a sample document
        sample = product_collection.find_one({})
        
        return {
            "status": "success",
            "deleted": deleted.deleted_count,
            "seeded": seeded,
            "total_in_db": total,
            "retailers": retailers,
            "sample_document": sample
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/debug/fix-missing-retailers")
async def debug_fix_missing_retailers():
    """Debug endpoint: Add retailer field to documents missing it."""
    try:
        # Map category or other fields to retailer names
        retailer_mappings = {
            "Checkers": "Checkers",
            "Pick n Pay": "Pick n Pay", 
            "Woolworths": "Woolworths",
            "Shoprite": "Shoprite"
        }
        
        # Find documents without retailer field
        missing = list(product_collection.find({"retailer": {"$exists": False}}))
        print(f"Found {len(missing)} documents without retailer field")
        
        # Try to infer retailer from URL or set to "Unknown"
        updated_count = 0
        for doc in missing:
            url = doc.get('productURL', '').lower()
            retailer = "Unknown"
            
            if 'pnp.co.za' in url or 'picknpay' in url.lower():
                retailer = "Pick n Pay"
            elif 'checkers.co.za' in url:
                retailer = "Checkers"
            elif 'woolworths.co.za' in url:
                retailer = "Woolworths"
            elif 'shoprite.co.za' in url:
                retailer = "Shoprite"
            
            product_collection.update_one(
                {"_id": doc["_id"]},
                {"$set": {"retailer": retailer}}
            )
            updated_count += 1
        
        return {
            "status": "success",
            "missing_retailers_fixed": updated_count,
            "total_retailers_now": product_collection.distinct("retailer")
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ------------------------------------
#          SCRAPER ENDPOINTS
# ------------------------------------

@app.get("/scrape/status")
async def scrape_status():
    allowed, message = within_crawl_window()
    return {
        "scraping_allowed": allowed,
        "message": message,
        "window_utc": "04:00-08:45",
        "window_sast": "06:00-10:45",
        "current_utc": datetime.now(pytz.utc).strftime('%Y-%m-%d %H:%M:%S UTC'),
        "current_sast": datetime.now(pytz.timezone('Africa/Johannesburg')).strftime('%Y-%m-%d %H:%M:%S SAST')
    }

@app.post("/scrape/start", response_model=ScrapeResponse)
async def start_scrape(background_tasks: BackgroundTasks):
    allowed, message = within_crawl_window()

    if not allowed:
        raise HTTPException(status_code=423, detail=f"Scraping not allowed: {message}")

    task_id = datetime.now().strftime("%Y%m%d_%H%M%S")

    scrape_jobs[task_id] = {
        "status": "running",
        "start_time": datetime.now().isoformat(),
        "products_scraped": 0
    }

    background_tasks.add_task(run_scrapy_spider, task_id)

    return ScrapeResponse(
        status="started",
        message="Scraping initiated.",
        task_id=task_id,
        timestamp=datetime.now().isoformat()
    )

@app.get("/scrape/jobs/{task_id}")
async def get_job_status(task_id: str):
    if task_id not in scrape_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    return scrape_jobs[task_id]

@app.get("/scrape/results")
async def get_scrape_results():
    try:
        with open('data/products.json', 'r', encoding='utf-8') as f:
            products = json.load(f)
        return {"count": len(products), "products": products}
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="No results found. Run scraper first.")

async def run_scrapy_spider(task_id: str):
    try:
        process = await asyncio.create_subprocess_exec(
            'python', 'run_scraper.py',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        stdout, stderr = await process.communicate()

        if process.returncode == 0:
            scrape_jobs[task_id]["status"] = "completed"
            scrape_jobs[task_id]["end_time"] = datetime.now().isoformat()

            try:
                with open('data/products.json', 'r', encoding='utf-8') as f:
                    products = json.load(f)
                scrape_jobs[task_id]["products_scraped"] = len(products)
            except:
                scrape_jobs[task_id]["products_scraped"] = 0
        else:
            scrape_jobs[task_id]["status"] = "failed"
            scrape_jobs[task_id]["error"] = stderr.decode()

    except Exception as e:
        scrape_jobs[task_id]["status"] = "failed"
        scrape_jobs[task_id]["error"] = str(e)

# ------------------------------------
#    Utility – Parse price like "R39.99"
# ------------------------------------

def parse_price(price_str):
    if not price_str:
        return None
    cleaned = re.sub(r"[^\d.]", "", str(price_str))
    try:
        return float(cleaned)
    except:
        return None

# ------------------------------------
# 🚀 PRODUCTS ENDPOINTS
# ------------------------------------

@app.get("/categories")
async def get_categories():
    """Get list of unique categories from all products."""
    try:
        # Get distinct categories from products
        categories = product_collection.distinct("category")
        
        if not categories:
            # Return default categories if none found
            categories = ["Groceries", "Beverages", "Household", "Personal Care"]
        
        return [{"id": i, "name": cat} for i, cat in enumerate(categories)]

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ------------------------------------
# 🚀 GET RETAILERS
# ------------------------------------

@app.get("/retailers")
async def get_retailers():
    """Get list of unique retailers from all products."""
    try:
        # Get distinct retailers from products
        retailers = product_collection.distinct("retailer")
        
        if not retailers:
            # Return empty list if none found
            retailers = []
        
        return [{"id": i, "name": retailer} for i, retailer in enumerate(retailers)]

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ------------------------------------
# 🚀 GET PRODUCTS BY RETAILER
# ------------------------------------

@app.get("/products/retailer/{retailer_name}")
async def get_products_by_retailer(retailer_name: str):
    """Get all products from a specific retailer. Returns sorted by price ascending."""
    try:
        if not retailer_name:
            raise HTTPException(status_code=400, detail="Retailer name is required")

        # Find products by retailer (case-insensitive)
        regex = re.compile(f"^{re.escape(retailer_name)}$", re.IGNORECASE)
        results = list(product_collection.find({"retailer": regex}, {"_id": 0}))

        if not results:
            raise HTTPException(status_code=404, detail=f"No products found for retailer: {retailer_name}")

        # Parse prices and sort
        for item in results:
            item["numeric_price"] = parse_price(item.get("price"))

        # Sort by price ascending (None values go last)
        results = sorted(results, key=lambda x: (x["numeric_price"] is None, x["numeric_price"]))

        return results

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ------------------------------------
# 🚀 FILTER PRODUCTS BY RETAILER & SEARCH
# ------------------------------------

@app.get("/products")
async def get_all_products(search: Optional[str] = None, retailer: Optional[str] = None):
    """Get products with optional search query and/or retailer filter. Returns sorted by price ascending."""
    try:
        filters = {}
        
        # Add search filter
        if search:
            regex = re.compile(search, re.IGNORECASE)
            filters["productName"] = regex
        
        # Add retailer filter
        if retailer:
            retailer_regex = re.compile(f"^{re.escape(retailer)}$", re.IGNORECASE)
            filters["retailer"] = retailer_regex

        # Query MongoDB
        results = list(product_collection.find(filters, {"_id": 0}))

        if not results:
            raise HTTPException(status_code=404, detail="No products found")

        # Parse prices and sort
        for item in results:
            item["numeric_price"] = parse_price(item.get("price"))

        # Sort by price ascending (None values go last)
        results = sorted(results, key=lambda x: (x["numeric_price"] is None, x["numeric_price"]))

        return results

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ------------------------------------
#        MAIN ENTRY
# ------------------------------------

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=int(os.getenv("PORT", 8000)), reload=True)
