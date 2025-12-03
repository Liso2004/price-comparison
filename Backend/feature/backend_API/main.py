from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
import os
from dotenv import load_dotenv

# Load .env
load_dotenv()

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------------------------------------------------
# Load environment variables
# ------------------------------------------------------------

MONGO_URI = os.getenv("MONGO_URI")
DB_NAME = os.getenv("MONGO_DB_NAME")

# Collection names
COL_PRODUCT = os.getenv("PRODUCT_COLLECTION")

# ------------------------------------------------------------
# MongoDB (Motor = async)
# ------------------------------------------------------------

client = AsyncIOMotorClient(MONGO_URI)
db = client[DB_NAME]

collections = [
    db[COL_PRODUCT]
]

# ------------------------------------------------------------
# Pydantic Model
# ------------------------------------------------------------

class Product(BaseModel):
    id: str = Field(..., description="MongoDB ID")
    productName: str
    price: float
    category: str
    productURL: str
    productImageURL: str
    retailer: str

# ------------------------------------------------------------
# Helper to convert Mongo → Python
# ------------------------------------------------------------

def serialize_product(doc):
    if not doc:
        return None

    price_raw = doc.get("price", "0")

    try:
        price_clean = (
            float(price_raw.replace("R", "").replace(",", "").strip())
            if isinstance(price_raw, str)
            else float(price_raw)
        )
    except:
        price_clean = 0.0

    return {
        "id": str(doc.get("_id")),
        "productName": doc.get("productName", "Unknown"),
        "price": price_clean,
        "category": doc.get("category", "Unknown"),
        "productURL": doc.get("productURL", "Unknown"),
        "productImageURL": doc.get("productImageURL", "Unknown"),
        "retailer": doc.get("retailer", "Unknown")
    }

# ------------------------------------------------------------
# ROUTES
# ------------------------------------------------------------

@app.get("/products", response_model=List[Product])
async def get_products():
    try:
        products = []

        for collection in collections:
            cursor = collection.find()
            async for doc in cursor:
                products.append(serialize_product(doc))

        return products

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/products/category/{category}", response_model=List[Product])
async def get_products_by_category(category: str):
    try:
        products = []

        for collection in collections:
            cursor = collection.find({
                "category": {"$regex": category, "$options": "i"}
            })
            async for doc in cursor:
                products.append(serialize_product(doc))

        if not products:
            raise HTTPException(status_code=404, detail="No products found for this category")

        return products

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/products/search", response_model=List[Product])
async def search_products(query: str = Query(..., min_length=1)):
    try:
        results = []

        for collection in collections:
            cursor = collection.find({
                "productName": {"$regex": query, "$options": "i"}
            })

            async for doc in cursor:
                results.append(serialize_product(doc))

        if not results:
            raise HTTPException(status_code=404, detail="No matching products found")

        return results

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/products/sort", response_model=List[Product])
async def sort_products(
    by: str = Query("price", regex="^(price|productName)$"),
    order: str = Query("asc", regex="^(asc|desc)$")
):
    try:
        products = []

        for collection in collections:
            async for doc in collection.find():
                products.append(serialize_product(doc))

        if not products:
            raise HTTPException(status_code=404, detail="No products available to sort")

        reverse_order = order == "desc"
        products.sort(key=lambda x: x[by], reverse=reverse_order)

        return products

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ------------------------------------------------------------
# NEW: FILTER BY RETAILER
# ------------------------------------------------------------

@app.get("/products/retailer/{retailer}", response_model=List[Product])
async def get_products_by_retailer(retailer: str):
    try:
        products = []

        for collection in collections:
            cursor = collection.find({
                "retailer": {"$regex": retailer, "$options": "i"}
            })

            async for doc in cursor:
                products.append(serialize_product(doc))

        if not products:
            raise HTTPException(status_code=404, detail="No products found for this retailer")

        return products

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/")
async def home():
    return {"message": "FastAPI is running!"}
