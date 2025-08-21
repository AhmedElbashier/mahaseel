# Mahaseel (محاصيل) 🌾

**An MVP mobile marketplace connecting Sudanese farmers directly with buyers.**

---

## 🚀 Vision
Empower farmers in Sudan by giving them a simple, accessible platform to list their crops, reach buyers, and close deals — without middlemen.

## 📱 Scope
- **Mobile App (Flutter):** For farmers and buyers.
- **Backend (FastAPI + PostgreSQL):** Secure API for listings, users, and orders.
- **Infra (Docker + Railway/Render):** Easy local dev + scalable cloud deployment.

## 🛠️ Tech Stack
- **Mobile:** Flutter (Dart 3.5)
- **Backend:** FastAPI (Python 3.11)
- **Database:** PostgreSQL 15 + SQLAlchemy + Alembic
- **Auth:** JWT-based (phone-first)
- **Maps:** Google Maps (location + filtering)
- **Chat:** WhatsApp deep links
- **Infra:** Docker, Docker Compose
- **CI/CD:** GitHub Actions

## 📂 Repo Layout
mahaseel/
backend/ # FastAPI app
mobile/ # Flutter app
infra/ # Docker, CI/CD, deployment configs
docs/ # Documentation

## ✅ Conventions
- GitHub Flow (feature branches → PR → main)
- Conventional Commits
- `.env` per service (never committed)
- Pre-commit hooks (lint, format, test)

## 📖 Documentation
See [docs/tech-decisions.md](docs/tech-decisions.md) for pinned versions and architectural decisions.

---

## 👩🏽‍🌾 Status
Day 1 — **Project Bootstrap** 🟢