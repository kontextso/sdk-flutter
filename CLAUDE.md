# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kontext Flutter SDK — a Flutter plugin for integrating AI-powered contextual ads into iOS/Android chat apps. Published to pub.dev as `kontext_flutter_sdk`.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test ./test

# Full CI sequence
flutter pub get && flutter analyze && flutter test ./test
```

## Architecture

The SDK is a Flutter plugin with Dart logic and native iOS (Swift) / Android (Kotlin) platform channels.

### Public API (`lib/src/main.dart`)

**`AdsProvider`** — root `HookWidget` managing ads state for a conversation.

Required props:
- `publisherToken`, `userId`, `conversationId`, `messages`, `enabledPlacementCodes`

Optional props:
- `adServerUrl`, `userEmail`, `character`, `vendorId`, `variantId`, `advertisingId`, `logLevel`, `iosAppStoreId`, `regulatory`, `otherParams`, `onEvent`

**`InlineAd`** — widget for embedding an ad inline in a chat feed. Props: `code` (placement code), `messageId`

**Key public types**: `Message` (id, role, content, createdAt), `Character`, `AdEvent` / `AdEventType`, `Regulatory`, `Bid`, `LogLevel`

### Dart Layer (`lib/src/`)

- **`widgets/`** — `AdsProvider`, `InlineAd`, `AdFormat`, `InterstitialModal`, `KontextWebview`
- **`services/`** — `Api` (preload), `HttpClient`, `Logger`, `AdvertisingIdService`, `TrackingAuthorizationService`, `TransparencyConsentFrameworkService`, `SKAdNetworkService`, `SKOverlayService`, `SKStoreProductService`
- **`models/`** — `Message`, `AdEvent`, `Character`, `Regulatory`, `Bid`, etc.
- **`device_app_info/`** — collects OS, hardware, screen, audio, power, network info
- **`utils/`** — constants (`kSdkVersion`, `kSdkLabel`), URL builder, extensions

**`AdsProvider`** uses Flutter Hooks (`flutter_hooks`) for state management:
- Custom hooks `usePreloadAds()` and `useLastMessages()` drive the core logic
- Detects new user messages → calls `Api.preload()` → stores bids → `InlineAd` picks up matching bid

**`AdFormat`** renders ads via `flutter_inappwebview` (WKWebView/WebView). Communicates bidirectionally with the ad iframe via `postMessage`. Message types: `init-iframe`, `show-iframe`, `resize-iframe`, `click-iframe`, `open-component-iframe`, `close-component-iframe`, `error-iframe`, `ad-done-iframe`.

### Native Layer

**iOS** (`ios/Classes/` — Swift): `SKAdNetworkManager`, `SKOverlayManager`, `SKStoreProductManager`, `TrackingAuthorizationPlugin` (ATT), `AdvertisingIdPlugin` (IDFA/IDFV), `TransparencyConsentFrameworkPlugin` (TCF), plus device info plugins. Entry point: `KontextSdkPlugin.swift`.

**Android** (`android/` — Kotlin): `AdvertisingIdPlugin` (GAID), `TransparencyConsentFramework`, plus device info plugins. Entry point: `KontextSdkPlugin.kt`.

### Key Patterns

- `Api`, `HttpClient`, `Logger`, `DeviceAppInfo` are singletons
- `HttpClient` resets when `adServerUrl` changes
- Version string lives in `lib/src/utils/constants.dart` (`kSdkVersion`)
- Tests use `flutter_test` + `mocktail`
- Linting: `flutter_lints` extended in `analysis_options.yaml`

## Release Process

See [RELEASING.md](RELEASING.md).
