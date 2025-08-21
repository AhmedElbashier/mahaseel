import pytest

@pytest.mark.skip(reason="WhatsApp link generation not implemented yet")
def test_whatsapp_link(client):
    res = client.get("/contact/1/whatsapp")
    assert res.status_code == 200
