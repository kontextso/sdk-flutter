import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as upstream;
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/webview/compat_types.dart';

class InAppWebView extends StatelessWidget {
  const InAppWebView({
    super.key,
    this.initialUrlRequest,
    this.initialUserScripts,
    this.initialSettings = const InAppWebViewSettings(),
    this.initialOmCreativeType,
    this.shouldOverrideUrlLoading,
    this.onWebViewCreated,
    this.onConsoleMessage,
    this.onReceivedError,
    this.onReceivedHttpError,
  });

  final URLRequest? initialUrlRequest;
  final UnmodifiableListView<UserScript>? initialUserScripts;
  final InAppWebViewSettings initialSettings;
  final OmCreativeType? initialOmCreativeType;
  final Future<NavigationActionPolicy?> Function(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  )? shouldOverrideUrlLoading;
  final void Function(InAppWebViewController controller)? onWebViewCreated;
  final void Function(InAppWebViewController controller, ConsoleMessage consoleMessage)? onConsoleMessage;
  final void Function(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceError error,
  )? onReceivedError;
  final void Function(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceResponse errorResponse,
  )? onReceivedHttpError;

  @override
  Widget build(BuildContext context) {
    return upstream.InAppWebView(
      initialUrlRequest: initialUrlRequest == null
          ? null
          : upstream.URLRequest(
              url: upstream.WebUri.uri(initialUrlRequest!.url!.uri),
            ),
      initialUserScripts: initialUserScripts == null
          ? null
          : UnmodifiableListView(
              initialUserScripts!.map(
                (script) => upstream.UserScript(
                  source: script.source,
                  injectionTime: _toUpstreamInjectionTime(script.injectionTime),
                  forMainFrameOnly: script.forMainFrameOnly,
                ),
              ),
            ),
      initialSettings: upstream.InAppWebViewSettings(
        transparentBackground: initialSettings.transparentBackground,
        mixedContentMode: _toUpstreamMixedContentMode(initialSettings.mixedContentMode),
        useShouldOverrideUrlLoading: initialSettings.useShouldOverrideUrlLoading,
        mediaPlaybackRequiresUserGesture: initialSettings.mediaPlaybackRequiresUserGesture,
        allowsInlineMediaPlayback: initialSettings.allowsInlineMediaPlayback,
        verticalScrollBarEnabled: initialSettings.verticalScrollBarEnabled,
        horizontalScrollBarEnabled: initialSettings.horizontalScrollBarEnabled,
        sharedCookiesEnabled: initialSettings.sharedCookiesEnabled,
      ),
      shouldOverrideUrlLoading: shouldOverrideUrlLoading == null
          ? null
          : (controller, navigationAction) async {
              final adapter = _UpstreamInAppWebViewController(controller);
              final action = NavigationAction(
                request: URLRequest(
                  url: navigationAction.request.url == null
                      ? null
                      : WebUri.uri(navigationAction.request.url!.uriValue),
                ),
                isForMainFrame: navigationAction.isForMainFrame,
              );
              final result = await shouldOverrideUrlLoading!(adapter, action);
              return _toUpstreamNavigationActionPolicy(result ?? NavigationActionPolicy.CANCEL);
            },
      onWebViewCreated: onWebViewCreated == null
          ? null
          : (controller) => onWebViewCreated!(_UpstreamInAppWebViewController(controller)),
      onConsoleMessage: onConsoleMessage == null
          ? null
          : (controller, consoleMessage) {
              onConsoleMessage!(
                _UpstreamInAppWebViewController(controller),
                ConsoleMessage(
                  message: consoleMessage.message,
                  messageLevel: _fromUpstreamConsoleMessageLevel(consoleMessage.messageLevel),
                ),
              );
            },
      onReceivedError: onReceivedError == null
          ? null
          : (controller, request, error) {
              onReceivedError!(
                _UpstreamInAppWebViewController(controller),
                WebResourceRequest(
                  url: WebUri.uri(request.url.uriValue),
                ),
                WebResourceError(
                  type: error.type.toNativeValue(),
                  description: error.description,
                ),
              );
            },
      onReceivedHttpError: onReceivedHttpError == null
          ? null
          : (controller, request, errorResponse) {
              onReceivedHttpError!(
                _UpstreamInAppWebViewController(controller),
                WebResourceRequest(
                  url: WebUri.uri(request.url.uriValue),
                ),
                WebResourceResponse(
                  statusCode: errorResponse.statusCode,
                  reasonPhrase: errorResponse.reasonPhrase,
                ),
              );
            },
    );
  }
}

class _UpstreamInAppWebViewController extends InAppWebViewController {
  _UpstreamInAppWebViewController(this._delegate);

  final upstream.InAppWebViewController _delegate;

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {
    _delegate.addJavaScriptHandler(
      handlerName: handlerName,
      callback: callback,
    );
  }

  @override
  Future<dynamic> evaluateJavascript({required String source}) {
    return _delegate.evaluateJavascript(source: source);
  }

  @override
  Future<void> configureOpenMeasurement(OmCreativeType creativeType) async {}

  @override
  Future<void> startOpenMeasurementSession() async {}

  @override
  Future<void> logOpenMeasurementError({
    String? errorType,
    String? message,
  }) async {}

  @override
  Future<void> finishOpenMeasurementSession() async {}
}

upstream.UserScriptInjectionTime _toUpstreamInjectionTime(UserScriptInjectionTime value) {
  switch (value) {
    case UserScriptInjectionTime.AT_DOCUMENT_START:
      return upstream.UserScriptInjectionTime.AT_DOCUMENT_START;
    case UserScriptInjectionTime.AT_DOCUMENT_END:
      return upstream.UserScriptInjectionTime.AT_DOCUMENT_END;
  }
}

upstream.MixedContentMode? _toUpstreamMixedContentMode(MixedContentMode? value) {
  switch (value) {
    case MixedContentMode.MIXED_CONTENT_NEVER_ALLOW:
      return upstream.MixedContentMode.MIXED_CONTENT_NEVER_ALLOW;
    case MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE:
      return upstream.MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE;
    case MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW:
      return upstream.MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW;
    case null:
      return null;
  }
}

upstream.NavigationActionPolicy _toUpstreamNavigationActionPolicy(NavigationActionPolicy value) {
  switch (value) {
    case NavigationActionPolicy.CANCEL:
      return upstream.NavigationActionPolicy.CANCEL;
    case NavigationActionPolicy.ALLOW:
      return upstream.NavigationActionPolicy.ALLOW;
  }
}

ConsoleMessageLevel _fromUpstreamConsoleMessageLevel(upstream.ConsoleMessageLevel value) {
  if (value == upstream.ConsoleMessageLevel.TIP) {
    return ConsoleMessageLevel.TIP;
  }
  if (value == upstream.ConsoleMessageLevel.WARNING) {
    return ConsoleMessageLevel.WARNING;
  }
  if (value == upstream.ConsoleMessageLevel.ERROR) {
    return ConsoleMessageLevel.ERROR;
  }
  if (value == upstream.ConsoleMessageLevel.DEBUG) {
    return ConsoleMessageLevel.DEBUG;
  }
  return ConsoleMessageLevel.LOG;
}
