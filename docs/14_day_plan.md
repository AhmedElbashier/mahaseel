## Project overview
###
Mahaseel’s FastAPI backend and Flutter mobile client are well-structured and already include helpful foundations such as JWT auth, rate‑limiting utilities, and secure token storage. A few hardening steps remain before releasing to millions of Sudanese users, especially around authentication flows, API robustness, and secure defaults.

#### 
Daily plan (next 14 days)
Day	Focus
#
```
1	Remove development OTP paths and wire real SMS provider; adjust mobile login flow.
2	Add per-user/IP rate limiting and OTP attempt lockouts on /auth/login and /auth/verify.
3	Rotate JWT secrets via environment variables, introduce refresh tokens, and enforce short access-token TTLs.
4	Restrict CORS to known domains and configure strict security headers.
5	Introduce /api/v1 versioning, update docs and clients, and standardize error responses.
6	Migrate media uploads to an object store (e.g., S3) with virus scanning and signed URLs.
7	Ensure the mobile client forces HTTPS, removes debug prints, and centralizes crash/telemetry reporting.
8	Add comprehensive API tests (happy path + failure cases) and begin fuzz testing.
9	Implement database indexes, caching, and pagination for large datasets.
10	Conduct load/stress tests and profile performance bottlenecks.
11	Perform security penetration testing and threat modeling review.
12	Finalize UI/UX polish, localization, and accessibility checks.
13	Release beta to limited audience, gather telemetry/feedback.
14	Address beta feedback and push production release with monitoring dashboards.
```
### Day 2 — Auth rate limits + OTP lockouts
- Backend: per-IP rate limit on `/auth/login` and `/auth/verify` via SlowAPI. Implemented in `backend/app/routes/auth.py` using `@limiter.limit("5/minute")`.
- Backend: OTP attempt lockout per phone (5 bad attempts → 15 min lock). Implemented in `backend/app/core/otp_store.py` and applied in `/auth/verify`.
- Migration: `backend/app/migrations/versions/d9b3a1e7c2ab_add_otp_lockout_fields.py` adds `failed_attempts` and `locked_until` to `otps`.
- Behavior: returns `429 otp_locked_try_later` when locked; resets on successful verify.

### Day 3 — JWT rotation + refresh tokens
- Secrets: `JWT_SECRET` from env (already). See `backend/app/core/config.py` and `docs/secret-rotation.md`.
- TTLs: set `JWT_ACCESS_MINUTES` to 15 in env for staging/prod; keep refresh at 7 days.
- Refresh: issue `refresh_token` at `/auth/verify` and add `/auth/refresh` to mint new access tokens. Implemented in `backend/app/routes/auth.py`; schema updated (`backend/app/schemas/auth.py`).
- Revocation: `token_service` supports JTI blacklist; call on logout as needed.

### Day 4 — CORS + security headers
- CORS: restricted to `settings.cors_origins` (already wired). Set env `CORS_ORIGINS` to known domains.
- Security headers: HSTS (non-dev), CSP, XFO, XCTO, Referrer-Policy, Permissions-Policy via `SecurityHeadersMiddleware` in `backend/app/main.py`.
- HTTPS: add `HTTPSRedirectMiddleware` in non-dev; `TrustedHostMiddleware` placeholder until domains finalized.

### Day 5 — API versioning + errors
- Versioning: routers mounted under `/api/v1` (implemented). Plan deprecation of unversioned routes and update clients/docs.
- Errors: standardized envelope in `backend/app/core/errors.py` (implemented). Audit error messages for safety/localization.

### Day 6 — Media to object store
- Uploads: S3 with presigned URLs/CDN + ClamAV scan in `backend/app/services/media_service.py` (implemented); used by `routes/media.py`.
- Ops: configure `S3_BUCKET`, optional `CDN_BASE_URL`, `CLAMD_HOST/PORT`.

### Day 7 — Mobile HTTPS + telemetry
- HTTPS: set release `.env` `API_BASE_URL` to https; Android cleartext allowed only for localhost (configured). iOS ATS defaults to HTTPS.
- Logs: `PiiSafeLogInterceptor` disables logs in release and redacts PII (implemented). Remove stray `debugPrint` calls.
- Crash/telemetry: enable Crashlytics/Sentry breadcrumbs in `logging_interceptor.dart` and set sampling.

### Day 8 — Tests + fuzzing
- Expand API tests for lockouts, pagination bounds, media limits.
- Add `hypothesis`-based fuzz tests for filters/search normalization.

### Day 9 — Indexes, caching, pagination
- Verify/search indexes on `crops` (state/type/created_at, text search). Add if missing.
- Consider response caching (fastapi-cache2) for hot listing endpoints (30–60s TTL).

### Day 10 — Load/stress + profiling
- k6/Locust scenarios: auth flow, list crops, media by crop, chat basics.
- Profile DB with slow query logs; iterate indexes/queries.

### Day 11 — Security testing + threat model
- Run OWASP ZAP against staging; review findings.
- STRIDE walkthrough for auth, media upload, chat/WS, admin paths.

### Day 12 — UX, i18n, accessibility
- Polish loading/empty/error states; RTL review for Arabic.
- Accessibility: contrast, touch targets, labels, large text.

### Progress — 2025-08-30
- Day 2 (Auth rate limits + OTP lockouts): done
  - SlowAPI per-IP rate limits on `/auth/login` and `/auth/verify` (`5/min`).
  - OTP lockout persisted per phone with `failed_attempts` + `locked_until` and handler in `/auth/verify`.
  - Alembic migration: `backend/app/migrations/versions/d9b3a1e7c2ab_add_otp_lockout_fields.py`.
- Day 3 (JWT rotation + refresh tokens): done
  - Issue `refresh_token` on `/auth/verify`; added `/auth/refresh` endpoint.
  - `TokenOut` extended; access token default TTL lowered to 15m via config (env-overridable).
- Day 4 (CORS + security headers): done
  - SecurityHeadersMiddleware (CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy).
  - HSTS + HTTPSRedirect in non-dev; keep TrustedHost placeholder; CORS via `settings.cors_origins`.
- Day 7 (Mobile HTTPS + telemetry): in progress
  - Enforce HTTPS base URL in release; centralized PII-safe network logging; iOS screenshot prevention (plugin), Android already secure.
  - Connectivity banner in Home Shell; centralized toast helper; started replacing SnackBars.
- Day 12 (UX/i18n/accessibility): in progress
  - Localization scaffolding (gen_l10n) with ARB for ar/en; initial keys (no-internet, tab labels, sort toasts, common labels).
  - EmptyState widget added and integrated into Favorites Home (no list), Chats List (no conversations), and Crops List (no results).
  - Localized crop sort toasts (newest/price asc/desc) and switched to toast helper.

Next (short-term)
- Finish localizing Home Shell (offline banner + bottom tabs) and App Drawer labels; swap remaining SnackBars for toasts across notifications/profile/support/map picker.
- Extend EmptyState into more lists as needed and move remaining hardcoded strings to ARB.



### What’s still left (priority)
```
! Home Shell
  Localize offline banner + bottom tabs.
! App Drawer
  Localize all labels; replace “coming soon” SnackBars with showToast.
! SnackBars → toasts
  Notifications, Profile, Map Picker (Support done).
! Crops list
  Finish the two remaining sort toasts (newest, asc/desc) where SnackBar is still used.
! EmptyState
  Add to any remaining “no data” lists you care about (we covered Crops, Chats, Favourites Home).
! ARB sweep
  Move remaining visible strings (drawer items, banners, sort labels, button tooltips) into ARB, then run: flutter pub get; flutter gen-l10n.


!!Nice-to-have (optional)

! Per-phone limiter key in backend (in addition to lockouts), if you want stricter rate limiting semantics.
! Verify Alembic migration applied in each env; set CORS_ORIGINS/JWT in staging/prod.
```