// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

typedef JavaScriptHandlerCallback = dynamic Function(List<dynamic> args);

enum UserScriptInjectionTime {
  AT_DOCUMENT_START,
  AT_DOCUMENT_END,
}

enum MixedContentMode {
  MIXED_CONTENT_NEVER_ALLOW,
  MIXED_CONTENT_COMPATIBILITY_MODE,
  MIXED_CONTENT_ALWAYS_ALLOW,
}

enum NavigationActionPolicy {
  CANCEL,
  ALLOW,
}

enum ConsoleMessageLevel {
  TIP,
  LOG,
  WARNING,
  ERROR,
  DEBUG,
}

@immutable
class WebUri {
  const WebUri(this.uri);

  final Uri uri;

  factory WebUri.uri(Uri uri) => WebUri(uri);

  @override
  String toString() => uri.toString();
}

@immutable
class URLRequest {
  const URLRequest({this.url});

  final WebUri? url;

  Map<String, dynamic> toMap() => {
        'url': url?.uri.toString(),
      };

  factory URLRequest.fromMap(Map<dynamic, dynamic> map) {
    final rawUrl = map['url'];
    return URLRequest(
      url: rawUrl is String ? WebUri.uri(Uri.parse(rawUrl)) : null,
    );
  }

  @override
  String toString() => 'URLRequest{url: $url}';
}

@immutable
class UserScript {
  const UserScript({
    required this.source,
    required this.injectionTime,
    this.forMainFrameOnly = true,
  });

  final String source;
  final UserScriptInjectionTime injectionTime;
  final bool forMainFrameOnly;

  Map<String, dynamic> toMap() => {
        'source': source,
        'injectionTime': injectionTime.name,
        'forMainFrameOnly': forMainFrameOnly,
      };
}

@immutable
class InAppWebViewSettings {
  const InAppWebViewSettings({
    this.transparentBackground = false,
    this.mixedContentMode,
    this.useShouldOverrideUrlLoading = false,
    this.mediaPlaybackRequiresUserGesture = true,
    this.allowsInlineMediaPlayback = false,
    this.verticalScrollBarEnabled = true,
    this.horizontalScrollBarEnabled = true,
    this.sharedCookiesEnabled = false,
  });

  final bool transparentBackground;
  final MixedContentMode? mixedContentMode;
  final bool useShouldOverrideUrlLoading;
  final bool mediaPlaybackRequiresUserGesture;
  final bool allowsInlineMediaPlayback;
  final bool verticalScrollBarEnabled;
  final bool horizontalScrollBarEnabled;
  final bool sharedCookiesEnabled;

  Map<String, dynamic> toMap() => {
        'transparentBackground': transparentBackground,
        'mixedContentMode': mixedContentMode?.name,
        'useShouldOverrideUrlLoading': useShouldOverrideUrlLoading,
        'mediaPlaybackRequiresUserGesture': mediaPlaybackRequiresUserGesture,
        'allowsInlineMediaPlayback': allowsInlineMediaPlayback,
        'verticalScrollBarEnabled': verticalScrollBarEnabled,
        'horizontalScrollBarEnabled': horizontalScrollBarEnabled,
        'sharedCookiesEnabled': sharedCookiesEnabled,
      };
}

@immutable
class NavigationAction {
  const NavigationAction({
    required this.request,
    required this.isForMainFrame,
  });

  final URLRequest request;
  final bool isForMainFrame;

  factory NavigationAction.fromMap(Map<dynamic, dynamic> map) {
    return NavigationAction(
      request: URLRequest.fromMap((map['request'] as Map<dynamic, dynamic>?) ?? const {}),
      isForMainFrame: map['isForMainFrame'] as bool? ?? true,
    );
  }
}

@immutable
class WebResourceRequest {
  const WebResourceRequest({this.url});

  final WebUri? url;

  factory WebResourceRequest.fromMap(Map<dynamic, dynamic> map) {
    final rawUrl = map['url'];
    return WebResourceRequest(
      url: rawUrl is String ? WebUri.uri(Uri.parse(rawUrl)) : null,
    );
  }

  @override
  String toString() => 'WebResourceRequest{url: $url}';
}

@immutable
class WebResourceError {
  const WebResourceError({
    this.type,
    this.description,
  });

  final int? type;
  final String? description;

  factory WebResourceError.fromMap(Map<dynamic, dynamic> map) {
    final rawType = map['type'];
    return WebResourceError(
      type: rawType is int ? rawType : (rawType is num ? rawType.toInt() : null),
      description: map['description'] as String?,
    );
  }

  @override
  String toString() => 'WebResourceError{type: $type, description: $description}';
}

@immutable
class WebResourceResponse {
  const WebResourceResponse({
    this.statusCode,
    this.reasonPhrase,
  });

  final int? statusCode;
  final String? reasonPhrase;

  factory WebResourceResponse.fromMap(Map<dynamic, dynamic> map) {
    final rawStatusCode = map['statusCode'];
    return WebResourceResponse(
      statusCode: rawStatusCode is int ? rawStatusCode : (rawStatusCode is num ? rawStatusCode.toInt() : null),
      reasonPhrase: map['reasonPhrase'] as String?,
    );
  }

  @override
  String toString() => 'WebResourceResponse{statusCode: $statusCode, reasonPhrase: $reasonPhrase}';
}

@immutable
class ConsoleMessage {
  const ConsoleMessage({
    required this.message,
    required this.messageLevel,
  });

  final String message;
  final ConsoleMessageLevel messageLevel;

  factory ConsoleMessage.fromMap(Map<dynamic, dynamic> map) {
    final rawLevel = map['messageLevel'] as String?;
    final level = ConsoleMessageLevel.values.firstWhere(
      (value) => value.name == rawLevel,
      orElse: () => ConsoleMessageLevel.LOG,
    );
    return ConsoleMessage(
      message: map['message'] as String? ?? '',
      messageLevel: level,
    );
  }
}

abstract class InAppWebViewController {
  Future<dynamic> evaluateJavascript({required String source});

  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  });
}
