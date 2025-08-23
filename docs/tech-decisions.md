# Tech Decisions — Mahaseel (محاصيل)

This living document records technical choices, pinned versions, and ops policies for reproducible builds and safe releases.

_Last updated: 2025-08-23_

---

## 🐍 Backend — Python

- **Language:** Python `3.11.x`
- **Framework:** FastAPI `>=0.115`
- **ASGI:** Uvicorn (behind reverse proxy)
- **Core libs:**
  - Starlette `>=0.47.2` (security-fix line)
  - Pydantic v2
  - SQLAlchemy 2.x + Alembic
  - `python-multipart==0.0.18`
  - `python-jose[cryptography]==3.4.0` (avoids `ecdsa`)
  - `cryptography>=42`
- **Config:** `pydantic-settings` + `.env`
- **Packaging:** `requirements.txt` pinned via `pip freeze`
- **Lint/Format/Test:** `ruff`, `black`, `pytest`
- **Logging:** JSON logs + correlation IDs
- **AuthZ:** JWT (short-lived access), roles: `seller`, `buyer`, `admin`

### Backend Security
- `pip-audit` in CI (fail on high/critical)
- CORS restricted to app/staging origins
- Upload validation (MIME/size), path traversal guards
- Basic rate limiting (`slowapi`)
- Secrets never committed; `.env.example` maintained

---

## 📱 Mobile — Flutter

- **Flutter:** `3.24.x` (stable), Dart `3.5.x`
- **Arch:** Feature-first + Riverpod
- **Routing:** `go_router`
- **Networking:** `dio` + interceptors
- **Storage:** `flutter_secure_storage` for tokens
- **Location/Maps:** `geolocator`, `google_maps_flutter`
- **Media:** `image_picker` (runtime perms)
- **Crash/Analytics:** Crashlytics `^5.0.0`, Analytics `^12.0.0`
- **Env:** `flutter_dotenv ^6.0.0`
- **Min SDKs:** Android 21+, iOS 12+

### Mobile Security
- No secrets in bundle; runtime config only
- HTTPS only; reject bad certs (default)
- Token storage via secure storage
- Proguard/R8 enabled for release

---

## 🐳 Infrastructure — Docker & Environments

- **Engine:** Docker `25.x`, Compose `v2.29.x`
- **Images:** `python:3.11-slim` (backend), `postgres:15-alpine` (DB)
- **Local:** `docker-compose.yml` with healthchecks
- **Staging/Prod:** Railway/Render managed Postgres
- **Backups:** Daily `pg_dump` (script + GH Action), 7‑day retention
- **Health:** `/healthz` endpoint for checks

---

## 🔐 Secrets & Config

- `.env` per environment; never commit real secrets
- `.env.example` with placeholders
- Secret rotation quarterly or post-incident
- Host platform secret manager (Railway/Render) for deployment

---

## 🚦 CI/CD

- **GitHub Actions**
  - Backend: lint → test → build image → push (GHCR)
  - Mobile: format → analyze → build debug/release artifacts
  - Security: `pip-audit` + monthly `flutter pub outdated` report
  - Backups: nightly Postgres dump (artifact, 7‑day retention)

---

## 🧯 DR & Backups

- Nightly automated `pg_dump` with 7‑day retention
- Monthly restore drill in staging
- Runbook: `docs/runbooks/dr.md` (RTO/RPO, restore steps)

---

## 📝 Conventions

- GitHub Flow (feature → PR → main)
- Conventional Commits
- Pre-commit hooks (lint/format)
- Code review: at least 1 approval for backend/mobile
