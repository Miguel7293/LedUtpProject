import os
from fastapi import FastAPI, HTTPException

app = FastAPI(title="LEAD UTP · Catálogo", version="1.0.0")
PRODUCTS = [
    {"id": 1, "name": "Mochila Andes", "category": "Accesorios", "price": 89.90},
    {"id": 2, "name": "Termo Lima", "category": "Accesorios", "price": 45.00},
    {"id": 3, "name": "Cuaderno UTP", "category": "Papelería", "price": 18.50},
]


@app.get("/health")
def health():
    return {"status": "ok", "service": "catalog-api"}


@app.get("/api/products")
def products():
    return {"items": PRODUCTS, "currency": "PEN", "source": "demo", "environment": os.getenv("APP_ENV", "local")}


@app.get("/api/products/{product_id}")
def product(product_id: int):
    for item in PRODUCTS:
        if item["id"] == product_id:
            return item
    raise HTTPException(status_code=404, detail="Producto no encontrado")
