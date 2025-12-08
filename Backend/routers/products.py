from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional

import crud, schemas
from database import get_db

router = APIRouter(prefix="", tags=["products"])


@router.get("/products", response_model=List[schemas.ProductOut])
def list_products(search: Optional[str] = Query(None, description="Search query for product name"), db: Session = Depends(get_db)):
    """Return list of products. If `search` is provided, return matching products.

    Example:
    GET /products
    GET /products?search=milk
    """
    try:
        if search:
            results = crud.search_products(db, search)
        else:
            results = crud.get_products(db)

        # map category name into response
        out = []
        for p in results:
            out.append(schemas.ProductOut(
                id=p.id,
                name=p.name,
                price=p.price,
                category=p.category.name if p.category else None,
                image_url=p.image_url,
                buy_url=p.buy_url,
            ))
        return out
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/product/{product_id}", response_model=schemas.ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    """Return a single product by id.

    Returns 404 if not found.
    """
    try:
        p = crud.get_product(db, product_id)
        if not p:
            raise HTTPException(status_code=404, detail="Product not found")
        return schemas.ProductOut(
            id=p.id,
            name=p.name,
            price=p.price,
            category=p.category.name if p.category else None,
            image_url=p.image_url,
            buy_url=p.buy_url,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
