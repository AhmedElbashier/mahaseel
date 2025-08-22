import io
from fastapi.testclient import TestClient
from PIL import Image
from app.routes import media as media_module


def create_image_bytes(color=(255, 0, 0)):
    img = Image.new("RGB", (10, 10), color=color)
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


def test_media_upload_and_main_image(client: TestClient, auth_headers, tmp_path, monkeypatch):
    monkeypatch.setattr(media_module, "UPLOAD_DIR", str(tmp_path))

    crop_payload = {
        "name": "Apples",
        "type": "fruit",
        "qty": 10,
        "price": 5,
        "unit": "kg",
        "location": {"lat": 0, "lng": 0, "state": "State1", "locality": "Loc", "address": "Addr"},
    }
    crop_resp = client.post("/crops", json=crop_payload, headers=auth_headers)
    crop_id = crop_resp.json()["id"]

    img1 = create_image_bytes(color=(255, 0, 0))
    files1 = {"file": ("img1.jpg", img1, "image/jpeg")}
    m1_resp = client.post(
        "/media/upload",
        params={"crop_id": crop_id, "is_main": "true"},
        files=files1,
        headers=auth_headers,
    )
    assert m1_resp.status_code == 200
    m1 = m1_resp.json()
    assert m1["is_main"] is True

    img2 = create_image_bytes(color=(0, 255, 0))
    files2 = {"file": ("img2.jpg", img2, "image/jpeg")}
    m2_resp = client.post(
        "/media/upload",
        params={"crop_id": crop_id, "is_main": "true"},
        files=files2,
        headers=auth_headers,
    )
    assert m2_resp.status_code == 200
    m2 = m2_resp.json()
    assert m2["is_main"] is True

    list_resp = client.get(f"/media/by-crop/{crop_id}")
    data = list_resp.json()
    assert len(data) == 2
    mains = [m for m in data if m["is_main"]]
    assert len(mains) == 1 and mains[0]["id"] == m2["id"]

    crop_detail = client.get(f"/crops/{crop_id}").json()
    assert crop_detail["image_url"] == m2["url"]
