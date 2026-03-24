import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kontext_flutter_sdk/src/webview/compat_types.dart';

const _viewType = 'kontext_flutter_sdk/in_app_webview';

class InAppWebView extends StatefulWidget {
  const InAppWebView({
    super.key,
    this.initialUrlRequest,
    this.initialUserScripts,
    this.initialSettings = const InAppWebViewSettings(),
    this.shouldOverrideUrlLoading,
    this.onWebViewCreated,
    this.onConsoleMessage,
    this.onReceivedError,
    this.onReceivedHttpError,
  });

  final URLRequest? initialUrlRequest;
  final UnmodifiableListView<UserScript>? initialUserScripts;
  final InAppWebViewSettings initialSettings;
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
  State<InAppWebView> createState() => _InAppWebViewState();
}

class _InAppWebViewState extends State<InAppWebView> {
  _CustomInAppWebViewController? _controller;

  Map<String, dynamic> _creationParams() => {
        'initialUrlRequest': widget.initialUrlRequest?.toMap(),
        'initialUserScripts': widget.initialUserScripts?.map((script) => script.toMap()).toList(),
        'initialSettings': widget.initialSettings.toMap(),
      };

  void _attachCallbacks() {
    _controller?.callbacks = _CustomInAppWebViewCallbacks(
      shouldOverrideUrlLoading: widget.shouldOverrideUrlLoading,
      onConsoleMessage: widget.onConsoleMessage,
      onReceivedError: widget.onReceivedError,
      onReceivedHttpError: widget.onReceivedHttpError,
    );
  }

  void _onPlatformViewCreated(int id) {
    final controller = _CustomInAppWebViewController(id);
    _controller = controller;
    _attachCallbacks();
    widget.onWebViewCreated?.call(controller);
  }

  @override
  void didUpdateWidget(covariant InAppWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _attachCallbacks();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return UiKitView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: _creationParams(),
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return AndroidView(
      viewType: _viewType,
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParams: _creationParams(),
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class _CustomInAppWebViewCallbacks {
  _CustomInAppWebViewCallbacks({
    this.shouldOverrideUrlLoading,
    this.onConsoleMessage,
    this.onReceivedError,
    this.onReceivedHttpError,
  });

  final Future<NavigationActionPolicy?> Function(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  )? shouldOverrideUrlLoading;
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
}

class _CustomInAppWebViewController extends InAppWebViewController {
  _CustomInAppWebViewController(int id) : _channel = MethodChannel('kontext_flutter_sdk/in_app_webview/$id') {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  final Map<String, JavaScriptHandlerCallback> _javaScriptHandlers = <String, JavaScriptHandlerCallback>{};
  final Map<String, List<List<dynamic>>> _pendingJavaScriptCalls = <String, List<List<dynamic>>>{};

  _CustomInAppWebViewCallbacks callbacks = _CustomInAppWebViewCallbacks();

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {
    _javaScriptHandlers[handlerName] = callback;

    final pendingCalls = _pendingJavaScriptCalls.remove(handlerName);
    if (pendingCalls == null) {
      return;
    }

    for (final arguments in pendingCalls) {
      callback(arguments);
    }
  }

  @override
  Future<dynamic> evaluateJavascript({required String source}) {
    return _channel.invokeMethod<dynamic>('evaluateJavascript', {
      'source': source,
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    final arguments = call.arguments;
    switch (call.method) {
      case 'onJavaScriptHandler':
        final payload = (arguments as Map<dynamic, dynamic>?) ?? const {};
        final handlerName = payload['handlerName'] as String?;
        if (handlerName == null) {
          return null;
        }
        final args = _decodeJavaScriptHandlerArguments(payload['args']);
        final handler = _javaScriptHandlers[handlerName];
        if (handler == null) {
          _pendingJavaScriptCalls.putIfAbsent(handlerName, () => <List<dynamic>>[]).add(args);
          return null;
        }
        return handler(args);
      case 'shouldOverrideUrlLoading':
        final callback = callbacks.shouldOverrideUrlLoading;
        if (callback == null) {
          return NavigationActionPolicy.ALLOW.name;
        }
        final action = NavigationAction.fromMap((arguments as Map<dynamic, dynamic>?) ?? const {});
        final result = await callback(this, action);
        return (result ?? NavigationActionPolicy.CANCEL).name;
      case 'onConsoleMessage':
        final callback = callbacks.onConsoleMessage;
        if (callback != null) {
          callback(this, ConsoleMessage.fromMap((arguments as Map<dynamic, dynamic>?) ?? const {}));
        }
        return null;
      case 'onReceivedError':
        final payload = (arguments as Map<dynamic, dynamic>?) ?? const {};
        final callback = callbacks.onReceivedError;
        if (callback != null) {
          callback(
            this,
            WebResourceRequest.fromMap((payload['request'] as Map<dynamic, dynamic>?) ?? const {}),
            WebResourceError.fromMap((payload['error'] as Map<dynamic, dynamic>?) ?? const {}),
          );
        }
        return null;
      case 'onReceivedHttpError':
        final payload = (arguments as Map<dynamic, dynamic>?) ?? const {};
        final callback = callbacks.onReceivedHttpError;
        if (callback != null) {
          callback(
            this,
            WebResourceRequest.fromMap((payload['request'] as Map<dynamic, dynamic>?) ?? const {}),
            WebResourceResponse.fromMap((payload['errorResponse'] as Map<dynamic, dynamic>?) ?? const {}),
          );
        }
        return null;
      default:
        throw MissingPluginException('Unknown webview callback: ${call.method}');
    }
  }
}

List<dynamic> _decodeJavaScriptHandlerArguments(dynamic rawArgs) {
  if (rawArgs is String) {
    try {
      final decoded = jsonDecode(rawArgs);
      if (decoded is List) {
        return _normalizeValue(decoded).cast<dynamic>();
      }
    } catch (_) {
      return const <dynamic>[];
    }
  }

  if (rawArgs is List) {
    return _normalizeValue(rawArgs).cast<dynamic>();
  }

  return const <dynamic>[];
}

dynamic _normalizeValue(dynamic value) {
  if (value is Map) {
    return value.map<String, dynamic>((key, mapValue) => MapEntry(key.toString(), _normalizeValue(mapValue)));
  }

  if (value is List) {
    return value.map<dynamic>(_normalizeValue).toList(growable: false);
  }

  return value;
}
