# JWT Secret Rotation

Mahaseel relies on the `JWT_SECRET` environment variable for signing
JSON Web Tokens. For security, rotate this secret periodically.

## Generate a new secret

```bash
python - <<'PY'
import secrets
print(secrets.token_urlsafe(32))
PY
```

## Rotation steps

1. Deploy the new value as `JWT_SECRET` alongside the old one.
2. Restart the application with the new secret.
3. Revoke existing refresh tokens via the revocation list in
   `app/core/token_service.py` to force users to re‑authenticate.

Old tokens signed with the previous secret will become invalid once the
application restarts with the new secret.
