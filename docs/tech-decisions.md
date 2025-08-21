# Tech Decisions — Mahaseel (محاصيل)

This document records the key technical choices and pinned versions used in the Mahaseel project.  
It ensures consistency across the team and reproducibility for builds.

---

## 🐍 Backend — Python

- **Language:** Python `3.11`
  - Rationale: Long-term support, stable, widely compatible with FastAPI ecosystem.
- **Framework:** FastAPI `0.111+`
- **Package Manager:** `pip` + `uv` (optional for speed).
- **Dependency Management:** `requirements.txt` (simple, CI/CD friendly).
- **Migrations:** Alembic (bundled with SQLAlchemy).
- **Lint/Format:** `ruff`, `black`.

---

## 📱 Mobile — Flutter

- **SDK Version:** Flutter `3.24.x` (stable channel, Dart `3.5.x`)
  - Rationale: Latest stable with LTS support, good for production apps.
- **State Management:** Riverpod (preferred) or Bloc.
- **Minimum Android SDK:** 21 (Android 5.0).
- **Minimum iOS:** 12.0.

---

## 🐳 Infrastructure — Docker

- **Docker Engine:** `25.x`
- **Docker Compose:** `v2.29.x`
- **Orchestration:** Compose for local/staging, Railway/Render for cloud deployment.
- **Base Images:**
  - Backend: `python:3.11-slim`
  - Database: `postgres:15-alpine`
- **Networking:** Bridge network with healthchecks.
- **Secrets:** `.env` per service, never committed.

---

## 🔐 Conventions

- GitHub Flow (feature branches → PR → main).
- Conventional Commits for history & changelogs.
- Pre-commit hooks for lint/format.
- CI/CD: GitHub Actions (backend + mobile).

---

_Last updated: 2025-08-21_
