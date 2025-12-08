from pydantic import BaseModel, AnyUrl
from typing import Optional


class CategoryBase(BaseModel):
    name: str


class CategoryOut(CategoryBase):
    id: int

    class Config:
        from_attributes = True


class ProductBase(BaseModel):
    name: str
    price: Optional[float]
    category: Optional[str]
    image_url: Optional[AnyUrl]
    buy_url: Optional[AnyUrl]


class ProductOut(ProductBase):
    id: int

    class Config:
        from_attributes = True
