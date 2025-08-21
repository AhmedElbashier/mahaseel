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
    assert len(data_all) == 2

    filtered = client.get("/crops", params={"state": "State1"})
    assert filtered.status_code == 200
    data_filtered = filtered.json()
    assert len(data_filtered) == 1
    assert data_filtered[0]["location"]["state"] == "State1"
