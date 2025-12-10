import os
import json
import glob
import re
import asyncio
import subprocess
from datetime import datetime
from typing import List, Optional, Any
from urllib.parse import quote, unquote
import base64
import httpx

import pytz
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, BackgroundTasks, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field, BeforeValidator, AnyUrl
from typing_extensions import Annotated
from pymongo import MongoClient, ASCENDING

# ---------------------------------------------------------------------------
# 1. CONFIGURATION & DATABASE SETUP
# ---------------------------------------------------------------------------

# Load environment variables
load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
DB_NAME = os.getenv("MONGO_DB")
COLLECTION_NAME = os.getenv("MONGO_COLLECTION")

# Connect to MongoDB
try:
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    products_collection = db[COLLECTION_NAME]
    # Create indexes for faster searching
    products_collection.create_index([("name", ASCENDING)])
    products_collection.create_index([("retailer", ASCENDING)])
    products_collection.create_index([("category", ASCENDING)])
    print(f"✅ Connected to MongoDB: {DB_NAME} / {COLLECTION_NAME}")
except Exception as e:
    print(f"❌ Could not connect to MongoDB: {e}")

# ---------------------------------------------------------------------------
# 2. PYDANTIC SCHEMAS (DATA MODELS)
# ---------------------------------------------------------------------------

# Helper to automatically convert MongoDB's _id (ObjectId) to string
PyObjectId = Annotated[str, BeforeValidator(str)]

class ProductBase(BaseModel):
    productName: str
    price: Optional[str] = None
    productImageURL: Optional[str] = None
    productURL: Optional[str] = None
    category: Optional[str] = "Uncategorized"
    retailer: Optional[str] = "Unknown"

class ProductOut(ProductBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)

    class Config:
        populate_by_name = True
        json_encoders = {
            # Handle ObjectId serialization if needed
        }

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

# ---------------------------------------------------------------------------
# 3. UTILITY FUNCTIONS
# ---------------------------------------------------------------------------

# Scraper Job Storage (In-memory)
scrape_jobs = {}

# Try to import time_checker, fallback if missing
try:
    from scraper_pnp.time_checker import within_crawl_window
except ImportError:
    def within_crawl_window():
        return True, "Window check unavailable (Dev Mode)"

def parse_price(value: Any) -> Optional[float]:
    """Cleans a price string (e.g., 'R 39.99') into a float (39.99)."""
    if value is None:
        return None
    try:
        # Remove any character that isn't a digit or a decimal point
        cleaned = re.sub(r"[^0-9.]", "", str(value))
        return float(cleaned) if cleaned else None
    except Exception:
        return None

async def fetch_image_from_url(url: str) -> Optional[bytes]:
    """Fetch image bytes from external URL using httpx."""
    if not url:
        return None
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url, follow_redirects=True)
            if response.status_code == 200:
                return response.content
    except Exception as e:
        print(f"⚠️ Failed to fetch image from {url}: {e}")
    return None

def add_image_proxy_url(product: dict, base_url: str = "http://127.0.0.1:8000") -> dict:
    """Replace productImageURL with proxy URL if image exists."""
    if product.get("productImageURL"):
        encoded_url = quote(product["productImageURL"], safe="")
        product["productImageURL"] = f"{base_url}/image?url={encoded_url}"
    return product

# ---------------------------------------------------------------------------
# 4. FASTAPI APP INIT
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# 5. DATABASE SEEDING LOGIC
# ---------------------------------------------------------------------------

def seed_database_from_json():
    """Reads cleaned JSON files from scraper folders and inserts into MongoDB."""
    base_path = os.path.dirname(__file__)
    # Look for files like: scraper_pnp/cleaned/picknpay_cleaned_data.json
    pattern = os.path.join(base_path, "scraper_*", "cleaned", "*.json")
    files = glob.glob(pattern)

    seeded_count = 0
    
    for filepath in files:
        # Infer retailer from filename or folder
        retailer_name = "Unknown"
        lower_path = filepath.lower()
        if "picknpay" in lower_path or "pnp" in lower_path: retailer_name = "Pick n Pay"
        elif "checkers" in lower_path: retailer_name = "Checkers"
        elif "woolworths" in lower_path: retailer_name = "Woolworths"
        elif "shoprite" in lower_path: retailer_name = "Shoprite"

        try:
            with open(filepath, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            print(f"⚠️ Error reading {filepath}: {e}")
            continue

        # Normalize data (handle list vs dict structures)
        products_list = []
        if isinstance(data, list):
            products_list = data
        elif isinstance(data, dict):
            # Some scrapers might wrap list in a key
            for v in data.values():
                if isinstance(v, list):
                    products_list.extend(v)

        # Process and Upsert
        for item in products_list:
            name = item.get("name") or item.get("productName") or item.get("title")
            if not name:
                continue

            # Standardize fields
            price_val = parse_price(item.get("price") or item.get("price_str"))
            buy_url = item.get("buy_url") or item.get("url") or item.get("productURL")
            
            doc = {
                "productName": name,
                "price": price_val,
                "productImageURL": item.get("image") or item.get("productImageURL") or item.get("img"),
                "productURL": buy_url,
                "category": item.get("category") or item.get("department") or "Uncategorized",
                "retailer": item.get("retailer") or retailer_name,
                "updated_at": datetime.utcnow()
            }

            # Avoid duplicates: Update if exists, Insert if new
            # Using 'buy_url' as unique key if present, otherwise 'name'
            filter_query = {"productURL": buy_url} if buy_url else {"productName": name}
            
            result = products_collection.update_one(filter_query, {"$set": doc}, upsert=True)
            if result.upserted_id:
                seeded_count += 1

    return seeded_count

@app.on_event("startup")
async def startup_event():
    """Run seeding on startup if DB is empty."""
    try:
        count = products_collection.count_documents({})
        if count == 0:
            print("📦 Database is empty. Seeding from JSON files...")
            new_items = seed_database_from_json()
            print(f"🎉 Seeding complete! Added {new_items} new products.")
        else:
            print(f"✓ Database ready with {count} products.")
    except Exception as e:
        print(f"✗ Startup Error: {e}")

# ---------------------------------------------------------------------------
# 6. SCRAPER BACKGROUND TASK
# ---------------------------------------------------------------------------

async def run_scrapy_spider(task_id: str):
    """Executes the external scraping script."""
    try:
        # Assumes 'run_scraper.py' exists in the root
        process = await asyncio.create_subprocess_exec(
            'python', 'run_scraper.py',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await process.communicate()

        if process.returncode == 0:
            scrape_jobs[task_id]["status"] = "completed"
            scrape_jobs[task_id]["end_time"] = datetime.now().isoformat()
            # Try to count results if possible
            scrape_jobs[task_id]["products_scraped"] = products_collection.count_documents({})
        else:
            scrape_jobs[task_id]["status"] = "failed"
            scrape_jobs[task_id]["error"] = stderr.decode()

    except Exception as e:
        scrape_jobs[task_id]["status"] = "failed"
        scrape_jobs[task_id]["error"] = str(e)

# ---------------------------------------------------------------------------
# 7. API ENDPOINTS
# ---------------------------------------------------------------------------

@app.get("/")
async def root():
    return {
        "message": "Retailer Scraper & Product Search API is active",
        "database": "MongoDB",
        "endpoints": {
            "docs": "/docs",
            "products": "/products",
            "retailers": "/retailers",
            "categories": "/categories",
            "image": "/image?url=<encoded_url>"
        }
    }

@app.get("/image")
async def serve_image(url: str):
    """
    Proxy endpoint to fetch and serve product images.
    Usage: GET /image?url=<URL-encoded-image-URL>
    """
    if not url:
        raise HTTPException(status_code=400, detail="url parameter is required")
    
    image_bytes = await fetch_image_from_url(url)
    if not image_bytes:
        raise HTTPException(status_code=404, detail="Could not fetch image from URL")
    
    # Return image as binary stream with appropriate content-type
    return StreamingResponse(
        iter([image_bytes]),
        media_type="image/jpeg",  # Adjust based on actual image type if needed
        headers={"Cache-Control": "public, max-age=86400"}  # Cache for 24 hours
    )

@app.get("/products", response_model=List[ProductOut])
async def get_products(
    search: Optional[str] = None,
    retailer: Optional[str] = None,
    category: Optional[str] = None,
    skip: int = 0,
    limit: int = 100
):
    """
    Search and filter products.
    """
    query = {}

    # Case-insensitive Search across name fields and category
    if search:
        escaped = re.escape(search)
        regex_expr = {"$regex": escaped, "$options": "i"}
        # Match product name/title fields OR category so users can search by category name
        query["$or"] = [
            {"productName": regex_expr},
            {"name": regex_expr},
            {"title": regex_expr},
            {"category": regex_expr},
            {"retailer": regex_expr}
        ]

    # Filter by Retailer
    if retailer:
        query["retailer"] = {"$regex": f"^{re.escape(retailer)}$", "$options": "i"}
    
    # Filter by Category
    if category:
        query["category"] = {"$regex": f"^{re.escape(category)}$", "$options": "i"}

    # Fetch Data
    cursor = products_collection.find(query).skip(skip).limit(limit)
    
    # Sort in Python to handle None values safely (put None price at end)
    products = list(cursor)
    products.sort(key=lambda x: (x.get("price") is None, x.get("price")))

    # Add image proxy URLs to each product
    for product in products:
        add_image_proxy_url(product)

    return products

@app.get("/products/category/{category_name}", response_model=List[ProductOut])
async def get_products_by_category_path(category_name: str):
    """Shortcut endpoint for categories."""
    return await get_products(category=category_name)

@app.get("/products/retailer/{retailer_name}", response_model=List[ProductOut])
async def get_products_by_retailer_path(retailer_name: str):
    """Shortcut endpoint for retailers."""
    return await get_products(retailer=retailer_name)


@app.get("/products/search", response_model=List[ProductOut])
async def search_product_and_retailer(
    product: Optional[str] = None,
    retailer: Optional[str] = None,
    skip: int = 0,
    limit: int = 100
):
    """Search products by product name (or part of it) and retailer.

    Usage examples:
    - `/products/search?product=milk&retailer=Shoprite`
    - `/products/search?product=tomato`
    - `/products/search?retailer=Pick%20n%20Pay`
    """
    if not product and not retailer:
        raise HTTPException(status_code=400, detail="Provide at least `product` or `retailer` parameter")

    # Delegate to the main get_products function which handles search/filters
    return await get_products(search=product, retailer=retailer, skip=skip, limit=limit)

@app.get("/categories", response_model=List[dict])
async def get_categories():
    """Return all unique categories found in DB."""
    cats = products_collection.distinct("category")
    cats = [c for c in cats if c] # filter empty
    cats.sort()
    return [{"id": i, "name": c} for i, c in enumerate(cats)]

@app.get("/retailers", response_model=List[dict])
async def get_retailers():
    """Return all unique retailers found in DB."""
    rets = products_collection.distinct("retailer")
    rets = [r for r in rets if r]
    rets.sort()
    return [{"id": i, "name": r} for i, r in enumerate(rets)]

# --- Scraper Endpoints ---

@app.get("/scrape/status")
async def scrape_status():
    allowed, message = within_crawl_window()
    return {
        "scraping_allowed": allowed,
        "message": message,
        "server_time": datetime.now(pytz.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
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
        message="Scraping initiated in background.",
        task_id=task_id,
        timestamp=datetime.now().isoformat()
    )

@app.get("/scrape/jobs/{task_id}")
async def get_job_status(task_id: str):
    if task_id not in scrape_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    return scrape_jobs[task_id]

# --- Debug Endpoints ---

@app.post("/debug/reseed")
async def debug_reseed():
    """Clears DB and re-runs seeding from JSON files."""
    try:
        deleted = products_collection.delete_many({})
        seeded = seed_database_from_json()
        return {
            "status": "success", 
            "deleted_count": deleted.deleted_count, 
            "seeded_count": seeded
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=int(os.getenv("PORT", 8000)), reload=True)