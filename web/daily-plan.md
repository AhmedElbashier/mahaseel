# Mahaseel Web Build Plan — Admin + User Website

This is a comprehensive, day‑by‑day execution plan to build both the Admin web app and the end‑user Website (UI/UX parity with the mobile app). It includes product, design, engineering, DevOps, QA, security, analytics, and launch.

Assumptions (confirm on Day 1)
- Stack: Next.js 14 (App Router) + TypeScript, PNPM workspaces, Turborepo, Tailwind CSS + shadcn/ui, React Query, Zod, Zustand.
- CI/CD: GitHub Actions, Vercel (or similar) deployments per env: dev, staging, prod.
- Auth: NextAuth (or custom JWT) with RBAC (admin, staff, user).
- API: Existing Mahaseel backend (REST/GraphQL). Mock via MSW until endpoints stabilize.
- Analytics & Telemetry: GA4, Meta Pixel (if required), Sentry, LogRocket (optional), Vercel Analytics.
- Content: Optional CMS (Sanity/Contentful) for marketing pages and help/faq.
- Compliance: GDPR/CCPA, Cookie consent, Privacy/Terms pages.

Success Criteria
- Feature parity with core mobile flows for users on web: browse crops, search/filter, details, cart, checkout, account.
- Robust admin: crops/products, categories, inventory, orders, customers/users, settings, analytics.
- Performance: LCP ≤ 2.5s p75, TTI ≤ 3s p75 on mid‑tier mobile, CLS ≤ 0.1.
- Accessibility: WCAG 2.1 AA checks pass key flows; Lighthouse a11y ≥ 90.
- Quality: >80% critical path test coverage; green CI on main; zero P0 security issues.

Daily Plan (30 days)

Day 1 — Kickoff, Requirements, Scope Lock
- Align stakeholders on goals, KPIs, target devices/browsers, locales.
- Audit mobile app flows for parity and deltas needed on web (e.g., SEO).
- Define modules for Admin and User; prioritize MVP vs. phase 2.
- Confirm stack, envs, domains, hosting, and third‑party vendors.
- Produce a signed‑off Requirements & Acceptance Criteria doc.

Day 2 — UX Research, Personas, Journeys, IA
- Define user personas (end‑user, admin, staff) and top tasks.
- Map journeys: browse → filter → details → cart → checkout → orders; admin task flows.
- Information Architecture and navigation schema for both apps.
- Draft content strategy for marketing/help pages.

Day 3 — Wireframes (User Website)
- Low‑fi wires: Home, Catalog/List, Filters/Search, Crop Details, Cart, Checkout, Auth, Account (profile, orders, addresses).
- Error/empty/loading states, 404/500 pages, cookie banner, consent UX.
- Review and iterate with stakeholders.

Day 4 — Wireframes (Admin)
- Low‑fi wires: Sign‑in, Dashboard KPIs, Crops CRUD, Categories, Inventory, Orders (list/detail), Users (list/detail), Settings, Analytics.
- Bulk actions, import/export, role/permission prompts, audit log views.
- Review and iterate.

Day 5 — Design System Foundations
- Design tokens: color, typography, spacing, radius, shadows, breakpoints; dark mode if desired.
- Component library decision: shadcn/ui with Tailwind; charting (e.g., Recharts/ECharts).
- Figma components: buttons, inputs, selects, tables, modals, toasts, tabs, cards, forms.
- Accessibility specs per component (focus order, ARIA, contrast).

Day 6 — Monorepo & Tooling Setup
- PNPM workspace + Turborepo; root configs for TypeScript, ESLint, Prettier, lint‑staged, Husky, commitlint.
- Finalize skeletons under `web/apps/admin`, `web/apps/user`, `web/packages/shared`.
- tsconfig path aliases, absolute imports, `@shared/*` package wiring.
- GitHub Actions CI skeleton (typecheck, lint, unit tests). Vercel projects stubbed.

Day 7 — App Scaffolding & Base UI
- Next.js 14 setup for both apps; App Router; global layouts, metadata.
- Tailwind config with tokens; shadcn/ui install and initial components.
- Global styles, CSS variables, font loading strategy.
- Header/Footer, responsive grid, container and spacing utilities.

Day 8 — Auth & RBAC Foundation
- NextAuth (or JWT) integration (email/password, OAuth if needed).
- Roles/permissions model; server components guards; client guards.
- Session provider, protected routes, auth pages: sign‑in, register, reset.
- Secure storage of secrets; environment variable strategy per env.

Day 9 — API Client & Data Layer
- API client (Axios/Fetch) with interceptors, retry, and error normalization.
- React Query setup: cache keys, hydration, suspense, error boundaries.
- Validation with Zod; form handling with React Hook Form.
- Mock Service Worker (MSW) for dev and tests.

Day 10 — Shared Package & Design System
- Build tokens, primitives, and base components in `packages/shared`.
- Cross‑app components: Button, Input, Select, Modal, Toast, Tabs, Card, Table, Pagination, Breadcrumbs.
- Utility libs: date/number helpers, fetch wrappers, feature flags, analytics wrapper.

Day 11 — User: Shell, Home, SEO
- Home page layout, hero, featured categories, promos.
- SEO: metadata, OpenGraph/Twitter, sitemap, robots, canonical.
- Responsive nav and search; skeleton loaders.
- Analytics events (page_view, search_opened, featured_click).

Day 12 — User: Catalog, Filters, Search
- Catalog grid/list with server components and pagination/infinite scroll.
- Filters: category, price, availability; accessible filter UI.
- Search box with debounced suggestions; empty state.
- Persisted query params; shareable URLs.

Day 13 — User: Crop Details
- Details page: images gallery (zoom), price, variants/options, description.
- Related/recommended items; recently viewed.
- SEO structured data (Product schema), breadcrumbs.

Day 14 — User: Cart
- Cart slice (Zustand) + localStorage persistence; mini‑cart in header.
- Cart page: update qty, remove, promo codes; shipping estimator.
- Edge cases: out‑of‑stock, price changes, validation on checkout.

Day 15 — User: Checkout
- Address book (add/edit/delete), shipping methods, delivery times.
- Payment gateway integration (Stripe or provider placeholder); PCI considerations.
- Order confirmation page and transactional email templates.
- Guest checkout vs. account; fraud and error handling.

Day 16 — User: Account Area
- Profile (name/email/phone), password change, 2FA option.
- Orders list/detail (invoices, status tracking), reorder.
- Addresses management, notifications preferences.
- Returns/refunds request flow (phase 2 if needed).

Day 17 — User: Content & Support
- Static pages: About, Contact, Privacy, Terms, FAQ.
- Optional CMS wiring for editable content.
- Contact form with spam protection (hCaptcha/ReCAPTCHA).
- Live chat or Intercom/Zendesk widget (optional).

Day 18 — Admin: Dashboard & Tables
- Dashboard KPIs, charts (daily orders, revenue, top products, inventory alerts).
- Data table primitives: sorting, filtering, column chooser, export CSV.
- Date range selectors, saved views.

Day 19 — Admin: Crops/Products
- CRUD with rich text, images upload (S3 or storage provider), categories.
- Variants/options, inventory tracking, pricing tiers.
- Bulk import/export (CSV/XLSX), validation and error reporting.

Day 20 — Admin: Orders
- Orders list/detail, status transitions (pending → shipped → delivered), refunds.
- Shipment/fulfillment integration (webhooks if applicable); invoice PDF.
- Notes, activity log, email triggers.

Day 21 — Admin: Users/Customers
- Customers list/detail, order history, segmentation tags.
- Admin/staff users and role management; impersonation capability.
- Audit logging: who changed what, when.

Day 22 — Admin: Settings
- Store settings (branding, locales/currency, tax/regions), payment/shipping configs.
- Feature flags & experiments; environment toggles.
- Webhooks management, API keys, integrations marketplace (optional).

Day 23 — Admin: Analytics & Reporting
- Cohorts, funnels, retention, top categories, AOV, conversion rates.
- Exportable reports, scheduled email reports.
- Time zone handling and data consistency.

Day 24 — Cross‑App Integrations
- Media storage (S3), Email provider (SendGrid/SES), SMS (Twilio) if needed.
- Image CDN and optimization pipeline; responsive images with blur placeholders.
- Maps for addresses (Mapbox/Google) and address autocomplete.

Day 25 — Accessibility & Performance
- A11y audit (axe), keyboard traps, focus management; screen reader checks.
- Performance budgets: prefetch/preload, code‑splitting, route‑level caching, ISR/SSR.
- Optimize fonts (subset, swap), images (AVIF/WebP), reduce bundle size.

Day 26 — Internationalization & Localization
- i18n routing, locale switcher, translated metadata.
- Currency/units formatting, RTL support if required.
- Translation pipeline (JSON, CMS), fallback strategy.

Day 27 — Testing Deep Dive
- Unit/component tests coverage for critical components; Mock Service Worker.
- E2E flows with Playwright/Cypress: browse → checkout; admin CRUD; permissions.
- Visual regression tests for key pages.

Day 28 — Security & Compliance
- Security headers (CSP, HSTS, XFO, COOP/COEP), CSRF, SSRF protections.
- Dependency and secret scanning, SAST/DAST; renovate/dependabot.
- Cookie consent, DPA updates, PII redaction, data retention policy.

Day 29 — Observability, Ops, Docs
- Sentry errors + performance; uptime monitoring; health checks.
- Logging strategy, dashboards, alerts/on‑call plan.
- Developer docs: README, ADRs, runbooks, troubleshooting, release process.

Day 30 — UAT, Launch, Post‑Launch Plan
- Full regression pass, bug bash; UAT sign‑off checklist.
- Finalize DNS, SSL, caching/CDN, warm ISR; release notes.
- Launch to production; post‑launch monitoring; hotfix process.

Feature Checklists (condensed)

User Website
- Home, Catalog/List, Filters/Search, Crop Details, Cart, Checkout
- Auth (register/login/reset), Account (profile, orders, addresses)
- SEO (sitemap/robots/OG), Accessibility, Performance budgets
- Content pages, CMS integration (optional), Contact/Support
- Analytics events, cookie consent, error/empty/loading states

Admin App
- Auth + RBAC, Dashboard KPIs, Tables toolkit
- Crops/Products CRUD, Categories, Inventory
- Orders (statuses, refunds, invoices), Users/Customers, Audit log
- Settings (store, payments, shipping, tax, webhooks, feature flags)
- Analytics & Reporting, Scheduled exports

Engineering & DevOps
- Monorepo (pnpm/turbo), shared package, code quality gates
- CI (typecheck/lint/test), Preview deployments, env management
- Security headers, dependency scanning, secrets management
- Observability, alerts, runbooks; rollback strategy

Definition of Done (per feature)
- UX spec implemented incl. empty/loading/error states, a11y passes
- Tests: unit/integration; E2E coverage for critical paths
- Performance within budget; analytics events instrumented
- Documentation updated; code reviewed; CI green; feature flagged if needed

RACI (lightweight)
- Product: requirements, acceptance, UAT
- Design: IA, wires, UI kit, a11y review
- Engineering: build, tests, infra, security
- QA: test plans, regression, E2E
- Ops: deployment, monitoring, incident

Notes
- Keep user website experience fast, responsive, and SEO‑friendly. Treat it as first‑class, not a mobile afterthought.
- Maintain parity with mobile flows but optimize layout and navigation for desktop/tablet.
- Use Feature Flags for risky/iterative features to ship safely.
