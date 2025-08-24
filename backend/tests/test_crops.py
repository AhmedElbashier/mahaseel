from fastapi.testclient import TestClient

def _sample_crop(state="State1"):
    return {
        "name": "Tomatoes",
        "type": "veg",
        "qty": 100,
        "price": 50,
        "unit": "kg",
        "location": {
            "lat": 1.0,
            "lng": 2.0,
            "state": state,
            "locality": "Loc",
            "address": "Addr",
        },
        "notes": "Fresh",
    }

def test_crop_create_list_filter(client: TestClient, auth_headers):
    r1 = client.post("/crops", json=_sample_crop("State1"), headers=auth_headers)
    assert r1.status_code == 201
    r2 = client.post("/crops", json=_sample_crop("State2"), headers=auth_headers)
    assert r2.status_code == 201

    list_all = client.get("/crops")
    assert list_all.status_code == 200
    data_all = list_all.json()
    assert len(data_all["items"]) == 2

    filtered = client.get("/crops", params={"state": "State1"})
    assert filtered.status_code == 200
    data_filtered = filtered.json()
    assert len(data_filtered["items"]) == 1
    assert data_filtered["items"][0]["location"]["state"] == "State1"


def test_crop_get(client: TestClient, auth_headers):
    missing = client.get("/crops/999")
    assert missing.status_code == 404

    create = client.post("/crops", json=_sample_crop(), headers=auth_headers)
    assert create.status_code == 201
    crop_id = create.json()["id"]

    fetched = client.get(f"/crops/{crop_id}")
    assert fetched.status_code == 200
    data = fetched.json()
    assert data["id"] == crop_id
    assert data["name"] == "Tomatoes"


def test_crop_create_requires_role(
    client: TestClient, buyer_headers, admin_headers
):
    forbidden = client.post("/crops", json=_sample_crop(), headers=buyer_headers)
    assert forbidden.status_code == 403

    allowed = client.post("/crops", json=_sample_crop(), headers=admin_headers)
    assert allowed.status_code == 201
