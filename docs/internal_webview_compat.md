# Internal WebView Compat Reference

This document tracks the current internal webview compatibility layer.

Purpose:
- preserve the current `KontextWebview` call shape
- keep a one-file backend switch between custom and upstream-backed implementations
- use `flutter_inappwebview` as the behavioral reference
- keep ad rendering behavior unchanged while extending the custom backend over time

## Backend Switch

Switch point: [`lib/src/webview/in_app_webview.dart`](../lib/src/webview/in_app_webview.dart)

```dart
export 'compat_types.dart';

// export 'backends/upstream_in_app_webview.dart';
export 'backends/custom_in_app_webview.dart';
```

Use this file only to switch the active backend. `KontextWebview`, `AdFormat`, and modal code should not need call-site changes when comparing custom vs upstream behavior.

## Compatibility Contract

Primary call site: [`lib/src/widgets/kontext_webview.dart`](../lib/src/widgets/kontext_webview.dart)

```dart
return InAppWebView(
  initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
  initialUserScripts: UnmodifiableListView([_earlyBridge]),
  initialSettings: const InAppWebViewSettings(
    transparentBackground: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    sharedCookiesEnabled: true,
  ),
  shouldOverrideUrlLoading: ...,
  onWebViewCreated: ...,
  onConsoleMessage: ...,
  onReceivedError: ...,
  onReceivedHttpError: ...,
);
```

This is the contract to preserve when extending the compat layer.

## Current Compat Surface

Defined in [`lib/src/webview/compat_types.dart`](../lib/src/webview/compat_types.dart).

Implemented subset:
- `InAppWebView`
- `InAppWebViewController`
- `URLRequest`
- `WebUri`
- `UserScript`
- `UserScriptInjectionTime`
- `InAppWebViewSettings`
- `MixedContentMode`
- `NavigationAction`
- `NavigationActionPolicy`
- `ConsoleMessage`
- `ConsoleMessageLevel`
- `WebResourceRequest`
- `WebResourceError`
- `WebResourceResponse`

`NavigationAction` now includes `isForMainFrame`. This is metadata only; `KontextWebview` still decides navigation using the existing URL-based policy.

This is intentionally a narrow subset of upstream, not a full reimplementation.

## Backends

### Upstream Backend

File: [`lib/src/webview/backends/upstream_in_app_webview.dart`](../lib/src/webview/backends/upstream_in_app_webview.dart)

Role:
- adapts the compat types to `package:flutter_inappwebview/flutter_inappwebview.dart`
- serves as the reference path when comparing custom behavior against upstream

Use it when:
- validating whether an issue exists only in the custom backend
- checking how a future hook should behave before implementing it in the custom backend

### Custom Backend

Files:
- [`lib/src/webview/backends/custom_in_app_webview.dart`](../lib/src/webview/backends/custom_in_app_webview.dart)
- [`android/src/main/kotlin/so/kontext/sdk/flutter/KontextInAppWebView.kt`](../android/src/main/kotlin/so/kontext/sdk/flutter/KontextInAppWebView.kt)
- [`ios/Classes/KontextInAppWebViewPlugin.swift`](../ios/Classes/KontextInAppWebViewPlugin.swift)

Role:
- SDK-owned embedded webview implementation
- per-view method channel: `kontext_flutter_sdk/in_app_webview/<viewId>`
- preserves the same `InAppWebView(...)` constructor shape used by `KontextWebview`

Implemented controller methods:
- `evaluateJavascript`
- `addJavaScriptHandler`

## Android Lifecycle Rules

The Android custom backend has two important constraints.

### 1. Use `PlatformViewLink`, not plain `AndroidView`

Relevant code: [`lib/src/webview/backends/custom_in_app_webview.dart:118`](../lib/src/webview/backends/custom_in_app_webview.dart#L118)

```dart
return PlatformViewLink(
  viewType: _viewType,
  surfaceFactory: (context, controller) {
    return AndroidViewSurface(
      controller: controller as AndroidViewController,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    );
  },
  onCreatePlatformView: (params) {
    final controller = PlatformViewsService.initExpensiveAndroidView(...);
```

This matches upstream Android embedding more closely and avoids the lifecycle problems seen with the earlier plain `AndroidView` path.

### 2. Defer initial load until the JS handler is registered

Relevant code: [`lib/src/webview/backends/custom_in_app_webview.dart:83`](../lib/src/webview/backends/custom_in_app_webview.dart#L83)

```dart
void _deliverOnWebViewCreated(_CustomInAppWebViewController controller) {
  if (_hasDeliveredOnWebViewCreated) {
    return;
  }

  _hasDeliveredOnWebViewCreated = true;
  widget.onWebViewCreated?.call(controller);
  unawaited(controller.startInitialLoad());
}
```

Reason:
- `KontextWebview` registers `addJavaScriptHandler('postMessage', ...)` inside `onWebViewCreated`
- if the page starts loading before that, the first `init-iframe` can be lost

### 3. Do not call the native per-view channel before the platform view is ready

Relevant code: [`lib/src/webview/backends/custom_in_app_webview.dart:182`](../lib/src/webview/backends/custom_in_app_webview.dart#L182)

```dart
final Completer<void> _platformReadyCompleter = Completer<void>();

void markPlatformReady() {
  if (_platformReadyCompleter.isCompleted) {
    return;
  }
  _platformReadyCompleter.complete();
}

Future<T?> _invokeMethodWhenReady<T>(String method, [Map<String, dynamic>? arguments]) async {
  await _platformReadyCompleter.future;
  return _channel.invokeMethod<T>(method, arguments);
}
```

Reason:
- Android may call `onWebViewCreated` before the native per-view `MethodChannel` is usable
- without this gate, `loadInitialUrl` can fail with `MissingPluginException`

## JS Bridge Contract

The Dart-side early bridge lives in [`lib/src/widgets/kontext_webview.dart:10`](../lib/src/widgets/kontext_webview.dart#L10)

```dart
if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
  window.flutter_inappwebview.callHandler('postMessage', data);
} else {
  window.__kontextMsgQueue.push(data);
}
```

And the queued messages are flushed in [`lib/src/widgets/kontext_webview.dart:151`](../lib/src/widgets/kontext_webview.dart#L151)

```dart
controller.addJavaScriptHandler(
  handlerName: 'postMessage',
  callback: (args) { ... },
);

controller.evaluateJavascript(source: _flushMsgQueue);
```

Important rule:
- JS handler arguments must arrive in Dart as normalized `Map<String, dynamic>` / `List<dynamic>` values
- if they arrive as incompatible platform maps, `KontextWebview` ignores them and the ad never becomes visible

Relevant code: [`lib/src/webview/backends/custom_in_app_webview.dart:230`](../lib/src/webview/backends/custom_in_app_webview.dart#L230)

```dart
case 'onJavaScriptHandler':
  final handlerName = payload['handlerName'] as String?;
  final args = _decodeJavaScriptHandlerArguments(payload['args']);
  final handler = _javaScriptHandlers[handlerName];
  if (handler == null) {
    _pendingJavaScriptCalls.putIfAbsent(handlerName, () => <List<dynamic>>[]).add(args);
    return null;
  }
  return handler(args);
```

## Native Bridge Shape

The custom backend intentionally follows the upstream bridge shape closely.

### Android

Relevant code: [`android/src/main/kotlin/so/kontext/sdk/flutter/KontextInAppWebView.kt`](../android/src/main/kotlin/so/kontext/sdk/flutter/KontextInAppWebView.kt)

```kotlin
private const val JAVASCRIPT_BRIDGE_NAME = "flutter_inappwebview"
```

```kotlin
window.$JAVASCRIPT_BRIDGE_NAME.callHandler = function() {
  var _callHandlerID = setTimeout(function(){});
  window.$JAVASCRIPT_BRIDGE_NAME._callHandler(
    arguments[0],
    _callHandlerID,
    JSON.stringify(Array.prototype.slice.call(arguments, 1))
  );
  return new Promise(function(resolve, reject) {
    window.$JAVASCRIPT_BRIDGE_NAME[_callHandlerID] = {resolve: resolve, reject: reject};
  });
};
```

Android custom still only surfaces main-frame `shouldOverrideUrlLoading` callbacks because the native guard returns early for non-main-frame requests before invoking the method channel.

### iOS

Relevant code: [`ios/Classes/KontextInAppWebViewPlugin.swift`](../ios/Classes/KontextInAppWebViewPlugin.swift)

```swift
window.flutter_inappwebview.callHandler = function(handlerName) {
  var _callHandlerID = setTimeout(function(){});
  var args = Array.prototype.slice.call(arguments, 1);
  window.webkit.messageHandlers.\(kontextNativeBridgeName).postMessage({
    handlerName: handlerName,
    _callHandlerID: String(_callHandlerID),
    args: JSON.stringify(args)
  });
  return new Promise(function(resolve, reject) {
    window.flutter_inappwebview[_callHandlerID] = {resolve: resolve, reject: reject};
  });
};
```

Do not rename this bridge shape casually. The current Flutter-side bridge code assumes `window.flutter_inappwebview.callHandler(...)`.

## Ad Visibility Constraint

Relevant code: [`lib/src/widgets/ad_format.dart`](../lib/src/widgets/ad_format.dart)

```dart
return Offstage(
  offstage: !iframeLoaded.value || !showIframe.value,
  child: Container(
```

Implication:
- if `init-iframe` or `show-iframe` stop arriving, the webview subtree stays hidden
- a visible platform view alone does not prove the ad flow works

When debugging rendering issues, verify:
1. the JS bridge reaches Dart
2. `init-iframe` is received
3. `show-iframe` is received

## Native Notes

Android:
- document-start script cleanup does not call `ScriptHandler.remove()` anymore
- destroying the `WebView` is the cleanup path used in practice
- this avoids the `IncompatibleClassChangeError` seen with the earlier cleanup approach

iOS:
- initial URL loading is also deferred behind `loadInitialUrl()` to match the custom backend lifecycle shape across platforms
- `sharedCookiesEnabled` performs initial cookie seeding from `HTTPCookieStorage.shared` into `WKHTTPCookieStore`
- the first `loadInitialUrl()` waits for that cookie seeding to finish so the initial request can observe the seeded cookies
- that seeding is not a continuous sync after the `WKWebView` is created

## Adding Future Hooks

When adding another upstream-style hook:
1. add the type or callback to the compat subset only if the SDK actually needs it
2. implement it in the custom backend first
3. mirror it in the upstream adapter if backend comparison is still useful
4. keep `KontextWebview` call shape stable unless the SDK truly needs a new surface

The design goal is still a focused SDK-owned subset, not full `flutter_inappwebview` parity.
