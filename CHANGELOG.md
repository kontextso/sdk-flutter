# Changelog

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
