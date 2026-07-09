# Changelog

## 2.2.4
* Activate SKAdNetwork (SKAN) install attribution for directly-served campaigns (iOS). The SDK now reports a version the ad server accepts for SKAN, receives signed `skan` payloads, and registers view-through (fidelity-0) impressions via `SKAdImpression`.
* Clicks on bids with fidelity-1 SKAN data now open the App Store product sheet (`SKStoreProductViewController`) with full attribution parameters, falling back to the browser if it fails to load.
* Support the `impressionTrigger` bid field (`immediate` — fire on ad done, `component` — fire on component open; defaults to `immediate`).
* Pass the complete signed SKAN payload to the native SKOverlay/SKStoreProduct layers (previously only a bare `appStoreId`, which could not carry attribution).
* Remove the message-driven `open-/close-skstoreproduct-iframe` component; StoreKit presentation is now SDK-driven from the click.
* SKOverlay now requires iOS 16.0+ and fidelity-1 SKAN data — attribution is mandatory, so on iOS 14–15 `present` returns `UNSUPPORTED_IOS` instead of showing an unattributable overlay (previous behavior).
* Harden the native `SKAdImpression` construction: resolve attribution fields upfront (top-level, else fidelity-0 entry), validate all required fields, and fail cleanly with `MISSING_ARGUMENTS` instead of building an empty impression.
* Declare the `StoreKit` framework in the podspec.
* Document the required host-app `SKAdNetworkItems` entry (`mp7rpxwdrx.skadnetwork`) in the README.

## 2.2.1
* Add `revenue` to `AdEvent.adViewed` events.

## 2.2.0
* Automatically retrieve IFA (ATT flow on iOS, Advertising ID on Android).
* Added SKOverlay support.
* Added SKStoreProductViewController support.
* Added SKAdNetwork (SKAN) support with full compatibility with DSP SKAN responses.
* Improved logging and expanded test coverage.

## 2.1.3
* Fix the issue on iOS that caused music interruption when the preload request is made.

## 2.1.2
* Limit the number of messages sent to the server.

## 2.1.1
* Allow specific srcdoc navigation in WebView
* Prevent ad notify events when `isDisabled` flips mid-preload

## 2.1.0
* Implement support for the transparency and consent framework.
* Use click-iframe to handle clicks instead of event-iframe.

## 2.0.2
* Rename `lowerPowerMode` to `lowPowerMode` in the preload API request body.

## 2.0.1
* Added tests for AdFormat, InterstitialAd, and InlineAd widgets.

## 2.0.0
### Breaking
`AdEvent` structure changed. The event now exposes normalized typed fields instead of loose payload maps. If you previously accessed dynamic payload values, you must update your code.

> `onEvent(AdEvent event)` callback stays the same - only the event model changed.

### Migration
Use the new typed fields + switch on `event.type`.

```dart
AdsProvider(
    ...
    onEvent: (AdEvent event) {
      switch (event.type) {
        case AdEventType.adClicked:
          break;
        case AdEventType.videoCompleted:
          break;
        // Handle other event types...
      }
    },
    ...
);
```

### Additional note
When `AdEventType.adNoFill` is returned, check `event.skipCode`.  
`skipCode` explains why the ad could not be rendered (reason of no-fill).

### Other changes
* Clicking on an ad now opens an in-app browser instead of external browser
* Added optional `userEmail` property to `AdsProvider`
* Added more tests
* Minor optimizations and internal clean-up

## 1.1.2
* Updated README.
* Updated `AdEvent` documentation.

## 1.1.1
* Stop logging `postMessage` events from `InAppWebView`.
* Updated Gradle and NDK versions for the example app.
* Send keyboard height to the server to determine whether an ad is visible.

## 1.1.0

* BREAKING CHANGE: Removed `onAdView`, `onAdClick` and `onAdDone` callbacks from `AdsProvider` widget. Use `onEvent` callback instead.
* BREAKING CHANGE: Removed `PublicAd` class. Use `AdEvent` class instead.

## 1.0.7

* Fixed `setState() called after dispose()` issue in `InlineAd` widget.
* Periodically report ad dimensions to the server.

## 1.0.6

* Enhanced InlineAd and AdFormat to manage active state and keep-alive behavior.
* Refactored ad preloading logic to prevent multiple concurrent requests.
* Updated README.

## 1.0.5

* Added support for interstitial ads.
* Added `Regulatory` object to `AdsProvider`.
* Added new parameters to preload API request body.
* Updated README.

## 1.0.4

* Removed assertions for `gdpr` and `coppa` parameters.

## 1.0.3

* Refactored `gppSid` parameter to use `List<int>` instead of `String` in `AdsProvider`.

## 1.0.2

* Added optional regulatory-related parameters to `AdsProvider`.
* Updated URLs and description in `pubspec.yaml`.

## 1.0.1

* Removed unnecessary comments.
* Added platform support for Android and iOS in pubspec.yaml.

## 1.0.0

* Initial public release of `kontext_flutter_sdk`.
* Full documentation available at [https://docs.kontext.so/sdk/flutter](https://docs.kontext.so/sdk/flutter).
