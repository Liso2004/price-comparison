from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

import crud, schemas
from database import get_db

router = APIRouter(prefix="", tags=["categories"])


@router.get("/categories", response_model=List[schemas.CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    """Return list of available categories."""
    try:
        cats = crud.get_categories(db)
        return [schemas.CategoryOut(id=c.id, name=c.name) for c in cats]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
