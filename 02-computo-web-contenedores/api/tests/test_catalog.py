from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_catalog_contract():
    response = client.get("/api/products")
    assert response.status_code == 200
    payload = response.json()
    assert payload["currency"] == "PEN"
    assert len({item["id"] for item in payload["items"]}) == len(payload["items"])
    assert all(item["price"] > 0 for item in payload["items"])


def test_product_lookup_and_missing():
    assert client.get("/api/products/1").json()["name"] == "Mochila Andes"
    assert client.get("/api/products/999").status_code == 404
    assert client.get("/api/products/invalid").status_code == 422
