import pytest

from app.core.token_service import token_service


def test_refresh_token_and_revocation():
    refresh = token_service.create_refresh_token("user", "role")
    payload = token_service.decode(refresh)
    assert payload["typ"] == "refresh"

    token_service.revoke(refresh)
    with pytest.raises(RuntimeError):
        token_service.decode(refresh)
