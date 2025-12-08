from sqlalchemy.orm import Session
import models
from typing import List, Optional
import os
import json
import glob
import re


def get_product(db: Session, product_id: int) -> Optional[models.Product]:
    return db.query(models.Product).filter(models.Product.id == product_id).first()


def get_products(db: Session, skip: int = 0, limit: int = 100) -> List[models.Product]:
    return db.query(models.Product).offset(skip).limit(limit).all()


def search_products(db: Session, query: str) -> List[models.Product]:
    q = f"%{query}%"
    return db.query(models.Product).filter(models.Product.name.ilike(q)).all()


def get_categories(db: Session) -> List[models.Category]:
    return db.query(models.Category).all()


def _parse_price(value):
    if value is None:
        return None
    try:
        # remove currency symbols and spaces
        cleaned = re.sub(r"[^0-9.]", "", str(value))
        return float(cleaned) if cleaned else None
    except Exception:
        return None


def seed_data(db: Session):
    """Seed the database from any cleaned JSON files found under scraper_*/*/cleaned.

    This function is idempotent: it will not duplicate categories or products if they already exist.
    """
    # if products exist, skip seeding
    existing = db.query(models.Product).first()
    if existing:
        return

    base = os.path.dirname(__file__)
    pattern = os.path.join(base, "scraper_*", "cleaned", "*.json")
    files = glob.glob(pattern)

    for filepath in files:
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue

        if not isinstance(data, list):
            # maybe the file has an object with list under a key
            if isinstance(data, dict):
                # attempt to find a list value
                for v in data.values():
                    if isinstance(v, list):
                        data = v
                        break

        for item in data:
            name = item.get("name") or item.get("productName") or item.get("title")
            if not name:
                continue
            price = _parse_price(item.get("price") or item.get("price_str"))
            image = item.get("image") or item.get("image_url") or item.get("img")
            buy = item.get("buy_url") or item.get("url") or item.get("product_url")
            category_name = item.get("category") or item.get("department") or "Uncategorized"

            # ensure category exists
            category = db.query(models.Category).filter(models.Category.name == category_name).first()
            if not category:
                category = models.Category(name=category_name)
                db.add(category)
                db.commit()
                db.refresh(category)

            # avoid duplicates by name + buy_url
            q = db.query(models.Product).filter(models.Product.name == name)
            if buy:
                q = q.filter(models.Product.buy_url == buy)
            exists = q.first()
            if exists:
                continue

            prod = models.Product(
                name=name,
                price=price,
                image_url=image,
                buy_url=buy,
                category_id=category.id,
            )
            db.add(prod)
        # commit after processing file
        db.commit()
