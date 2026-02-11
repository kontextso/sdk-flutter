import 'dart:collection' show UnmodifiableListView;
import 'dart:async' show Timer;
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/extensions.dart' show UriExtension;
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;

// Prevent duplicate opens of the same store URL in a short window.
// This can happen during store URL resolution when creatives trigger multiple
// navigation methods.
// Some banners trigger the same store URL twice:
//  - `anchor`: click-through via an HTML link, e.g. `<a href="https://play.google.com/...">`
//  - `location`: JS navigation, e.g. `window.location`
final _storeOpenGate = _RecentStringGate(window: const Duration(milliseconds: 1200));
final _redirectOpenGate = _RecentStringGate(window: const Duration(milliseconds: 1200));
Timer? _pendingAndroidTrackerOpenTimer;
Uri? _pendingAndroidTrackerUri;

class _RecentStringGate {
  _RecentStringGate({required this.window});

  final Duration window;
  String? _lastValue;
  DateTime? _lastAt;

  bool allow(String value) {
    final now = DateTime.now();
    final lastAt = _lastAt;
    if (lastAt != null && _lastValue == value && now.difference(lastAt) < window) {
      return false;
    }
    _lastValue = value;
    _lastAt = now;
    return true;
  }
}

// In ad redirect chains, hasGesture can be true on an intermediate click tracker
// request and false on the final store URL request. Example:
// user tap: -> https://click.liftoff.io/... (hasGesture=true) -> https://play.google.com/... (hasGesture=false)
// Keep a short (2s) latch so the final request can still be treated as
// user-initiated.
DateTime? _lastUserGestureAt;
DateTime? _lastAndroidImagePopupAt;

void _resetWebViewClickContext() {
  _lastUserGestureAt = null;
  _lastAndroidImagePopupAt = null;
  _pendingAndroidTrackerOpenTimer?.cancel();
  _pendingAndroidTrackerOpenTimer = null;
  _pendingAndroidTrackerUri = null;
}

bool _hasRecentUserGesture() {
  final last = _lastUserGestureAt;
  if (last == null) {
    return false;
  }
  return DateTime.now().difference(last) < const Duration(seconds: 2);
}

bool _hasRecentAndroidImagePopup() {
  final last = _lastAndroidImagePopupAt;
  if (last == null) {
    return false;
  }
  return DateTime.now().difference(last) < const Duration(seconds: 2);
}

void _scheduleAndroidTrackerOpen(Uri target) {
  _pendingAndroidTrackerUri = target;
  _pendingAndroidTrackerOpenTimer?.cancel();
  _pendingAndroidTrackerOpenTimer = Timer(const Duration(milliseconds: 250), () async {
    final pending = _pendingAndroidTrackerUri;
    _pendingAndroidTrackerUri = null;
    _pendingAndroidTrackerOpenTimer = null;
    if (pending == null) {
      return;
    }

    final targetUrl = pending.toString();
    if (_redirectOpenGate.allow(targetUrl)) {
      await pending.openInAppBrowser();
    }
    _resetWebViewClickContext();
  });
}

final _earlyBridge = UserScript(
  source: '''
    (function() {
      if (window.__flutterSdkBridgeReady) return;
      window.__flutterSdkBridgeReady = true;
      
      // Messages buffered before the bridge is ready
      window.__kontextMsgQueue = [];
      
      function postToFlutter(data) {
        try {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('postMessage', data);
          } else {
            window.__kontextMsgQueue.push(data);
          }
        } catch (e) {
          console.error('Error posting message to Flutter: ', e);
        }
      }
      
      window.addEventListener('message', event => {
        postToFlutter(event.data);
      });
    })();
  ''',
  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  forMainFrameOnly: false,
);

final _flushMsgQueue = '''
  (function() {
    try {
      var queue = window.__kontextMsgQueue || [];
      if (queue.length === 0) return;
      window.__kontextMsgQueue = [];
      
      for (var i = 0; i < queue.length; i++) {
        var msg = queue[i];
        try {
          window.flutter_inappwebview.callHandler('postMessage', msg);
        } catch (e) {
          console.error('Error posting queued message to Flutter: ', e);
        }
      }
    } catch (e) {
      console.error('Error flushing message queue to Flutter: ', e);
    }
  })();
''';

final _sandboxIframeFix = UserScript(
  source: '''
    (function() {
      if (window.__kontextSandboxIframeFixInstalled) return;
      window.__kontextSandboxIframeFixInstalled = true;

      var token = 'allow-same-origin';

      // Ensure a sandboxed iframe includes allow-same-origin.
      function patchIframe(iframe) {
        var current = iframe.getAttribute('sandbox');
        if (!current) return;
        var parts = String(current).trim().split(/\\s+/).filter(Boolean);
        if (parts.indexOf(token) !== -1) return;
        parts.push(token);
        iframe.setAttribute('sandbox', parts.join(' '));
      }

      // Patch all currently existing sandboxed iframes.
      function patchAll() {
        try {
          var iframes = document.querySelectorAll('iframe[sandbox]');
          for (var i = 0; i < iframes.length; i++) patchIframe(iframes[i]);
        } catch (_) {}
      }

      // Prevent running patchAll() too many times
      var queued = false;
      function schedulePatch() {
        if (queued) return;
        queued = true;
        setTimeout(function() {
          queued = false;
          patchAll();
        }, 0);
      }

      patchAll();

      try {
        var observer = new MutationObserver(schedulePatch);
        observer.observe(document.documentElement || document, {
          childList: true,
          subtree: true,
          attributes: true,
          attributeFilter: ['sandbox']
        });
      } catch (_) {}
    })();
  ''',
  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  forMainFrameOnly: false,
);

typedef OnMessageReceived = void Function(InAppWebViewController controller, String messageType, Json? data);
typedef KontextWebviewBuilder = Widget Function({
  Key? key,
  required Uri uri,
  required List<String> allowedOrigins,
  required void Function(Json? data) onEventIframe,
  required OnMessageReceived onMessageReceived,
});

class KontextWebview extends StatelessWidget {
  const KontextWebview({
    super.key,
    required this.uri,
    required this.allowedOrigins,
    required this.onEventIframe,
    required this.onMessageReceived,
  });

  final Uri uri;
  final List<String> allowedOrigins;
  final void Function(Json? data) onEventIframe;
  final OnMessageReceived onMessageReceived;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
      initialUserScripts: Platform.isIOS
          ? UnmodifiableListView([_earlyBridge, _sandboxIframeFix])
          : UnmodifiableListView([_earlyBridge]),
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
        sharedCookiesEnabled: true,
        supportMultipleWindows: true,
        javaScriptCanOpenWindowsAutomatically: true,
      ),
      onCreateWindow: (controller, request) async {
        if (request.hasGesture == true) {
          _lastUserGestureAt = DateTime.now();
        }

        final uri = request.request.url?.uriValue;
        if (uri == null) {
          return false;
        }

        if (uri.isHttp && !uri.isStore && Platform.isIOS) {
          // On iOS, keep HTTP(S) redirect chains inside WebView until they
          // resolve to a definitive store URL.
          return false;
        }

        if (uri.isHttp && uri.isImageAsset && Platform.isAndroid) {
          // Some banners on Android call window.open(image-url) before firing
          // the actual click tracker. Ignore the asset popup and wait for the
          // tracker/store navigation in request interception.
          if (request.hasGesture == true) {
            _lastAndroidImagePopupAt = DateTime.now();
          }
          return false;
        }

        return uri.openInAppBrowser();
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final uri = navigationAction.request.url?.uriValue;
        if (uri == null) {
          return NavigationActionPolicy.CANCEL;
        }

        final url = uri.toString();

        if (uri.isStore) {
          if (_storeOpenGate.allow(url)) {
            await uri.openInAppBrowser();
          }
          return NavigationActionPolicy.CANCEL;
        }

        if (url == 'about:srcdoc' || url == 'about:blank') {
          return NavigationActionPolicy.ALLOW;
        }

        final isAllowed = uri.matchesAllowedOrigins(allowedOrigins);
        if (isAllowed) {
          return NavigationActionPolicy.ALLOW;
        }

        if (Platform.isIOS && uri.isHttp) {
          final isTopLevel = navigationAction.isForMainFrame == true || navigationAction.targetFrame == null;
          if (isTopLevel) {
            // Keep top-level external HTTP(S) hops out of the ad WebView
            // (trackers/redirectors) to avoid reload loops and "Double render".
            await uri.openInAppBrowser();
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        }

        final isUserGesture = navigationAction.hasGesture == true;
        if (uri.isHttp && isUserGesture) {
          await uri.openInAppBrowser();
          return NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },
      shouldInterceptRequest: (controller, request) async {
        if (!Platform.isAndroid) {
          return null;
        }

        final uri = request.url.uriValue;
        final hasGesture = request.hasGesture == true;

        if (hasGesture) {
          _lastUserGestureAt = DateTime.now();
        }

        final emptyResponse = WebResourceResponse(
          contentType: 'text/plain',
          data: Uint8List(0),
          headers: const {'Content-Type': 'text/plain'},
          statusCode: 204,
          reasonPhrase: 'No Content',
        );

        if (uri.isStore) {
          final isUserGesture = hasGesture || _hasRecentUserGesture();
          if (isUserGesture) {
            await uri.openInAppBrowser();
            // Reset the last user gesture timestamp to prevent subsequent non-gesture requests from being treated as gestures.
            _resetWebViewClickContext();
          }

          // Return an empty response so the iframe doesn't render a WebView error page.
          return emptyResponse;
        }

        final hasRecentClickContext = hasGesture || _hasRecentUserGesture() || _hasRecentAndroidImagePopup();
        if (hasRecentClickContext && uri.isAtomexTrackerClick) {
          final destination = uri.urlQueryParamAsUri;
          if (destination != null && (destination.isHttp || destination.isStore)) {
            final destinationUrl = destination.toString();
            if (_redirectOpenGate.allow(destinationUrl)) {
              await destination.openInAppBrowser();
            }
            _resetWebViewClickContext();
          }
          return null;
        }

        final isExternalGestureClick = hasRecentClickContext &&
            uri.isHttp &&
            !uri.isStore &&
            !uri.isImageAsset &&
            !uri.matchesAllowedOrigins(allowedOrigins);
        if (isExternalGestureClick) {
          // Multiple tracker URLs may arrive within a single click burst.
          // Debounce and open only the latest candidate.
          _scheduleAndroidTrackerOpen(uri);
          return null;
        }

        return null;
      },
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'postMessage',
          callback: (args) {
            final postMessage = args.firstOrNull;
            if (postMessage == null || postMessage is! Json) {
              return;
            }

            final messageType = postMessage['type'];
            final data = postMessage['data'];

            if (messageType is String && (data == null || data is Json)) {
              if (messageType == 'event-iframe') {
                onEventIframe(data);
              }
              onMessageReceived(controller, messageType, data as Json?);
            }
          },
        );

        controller.evaluateJavascript(source: _flushMsgQueue);
      },
      onConsoleMessage: (controller, consoleMessage) {
        final message = consoleMessage.message;
        final level = consoleMessage.messageLevel;

        if (level == ConsoleMessageLevel.ERROR) {
          Logger.error('WebView Console $level: $message');
        } else if (level == ConsoleMessageLevel.WARNING) {
          Logger.warn('WebView Console $level: $message');
        } else {
          Logger.info('WebView Console: $message');
        }
      },
      onReceivedError: (controller, request, error) {
        Logger.error('Error received in InAppWebView: $error, request: $request');
      },
      onReceivedHttpError: (controller, request, error) {
        // Ignore favicon 404 errors as they're not critical
        if (request.url.toString().endsWith('/favicon.ico')) {
          return;
        }

        Logger.error('HTTP error received in InAppWebView: $error, request: $request');
      },
    );
  }
}
