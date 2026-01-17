# Changelog

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
