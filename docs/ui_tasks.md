# UI worklist aligned with the backend changes and a near-term polish pass.

### Auth UX

```
OTP input: masked phone, numeric keyboard, paste detection, resend timer, disabled “Verify” while waiting. Map lockouts (429) to a clear “Try again in X min” message. mobile/lib/features/auth/screens/otp_screen.dart:1
Refresh flow: store refresh_token, auto‑refresh access token on 401 once, then retry the original request; logout on refresh failure. mobile/lib/services/api_client.dart:1
Token storage: persist both jwt and refresh_jwt in secure storage; save both on verify. mobile/lib/features/auth/data/auth_repo.dart:1, mobile/lib/features/auth/state/auth_controller.dart:1
Dev OTP: show only in debug builds; never surface in release. mobile/lib/features/auth/data/auth_repo.dart:1
Error Handling

Central mapper: map API envelope {error:{code,type,message}} and common statuses (400, 404, 409, 429) to user messages; localize. Extend current 422 mapper. mobile/lib/core/http/fastapi_errors.dart:1
Global toasts: replace scattered SnackBars with a helper that applies consistent style + RTL. mobile/lib/core/theme/app_theme.dart:1
UX Polish

Empty/error states: add consistent, localized views for lists (crops, chats, favorites). mobile/lib/features/crops/screens/crop_list_screen.dart:1
Skeletons: reuse shimmer skeletons across lists and detail pages for visual consistency. mobile/lib/widgets/crop_skeleton.dart:1
Offline banner: show connectivity banner and queue retries using existing retry queue. mobile/lib/services/connectivity_service.dart:1, mobile/lib/services/retry_queue.dart:1
Image UX: cache and lazy‑load images with placeholders; show failure fallback.
Foundation

Localization: integrate flutter_localizations + intl with ARB (ar, en); move hardcoded Arabic strings to ARB to fix garbled text; set proper Arabic fonts. mobile/lib/main.dart:84
Accessibility: respect text scaling, add Semantics labels to tappables, ensure 44dp hit targets, verify color contrast.
Theme system: centralize color/spacing/typography tokens, add dark mode, and unify component styles. mobile/lib/core/theme/app_theme.dart:1
Navigation guards: ensure protected routes redirect to login when unauthenticated (and back after). mobile/lib/routing/app_router.dart:1
Privacy: disable screenshots on OTP screen (Android FLAG_SECURE, iOS equivalent) and redact PII in logs. mobile/lib/services/logging_interceptor.dart:1
