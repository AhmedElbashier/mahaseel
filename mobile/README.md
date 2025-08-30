# mahaseel

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## API configuration

The app reads its API endpoint from a runtime environment variable using
[`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv).
Create a `.env` file in the `mobile/` directory:

```
API_BASE_URL=https://staging.mahaseel.com
```

- `API_BASE_URL` – Base URL for HTTP requests. In release builds the app
  refuses to run if this value is not HTTPS.
