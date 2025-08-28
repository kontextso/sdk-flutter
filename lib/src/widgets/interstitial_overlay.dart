import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' show URLRequest, WebUri;
import 'package:kontext_flutter_sdk/src/widgets/kontext_webview.dart';

class InterstitialOverlay {
  static OverlayEntry? _entry;
  static Timer? _initTimer;

  static void show(
    BuildContext context, {
    required String adServerUrl,
    required String component,
    required String bidId,
    required String code,
    required String messageId,
    Duration initTimeout = const Duration(seconds: 20),
  }) {
    close();

    final visible = ValueNotifier<bool>(false);

    _entry = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, isVisible, __) {
            return IgnorePointer(
              ignoring: !isVisible,
              child: AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SafeArea(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: double.infinity,
                    child: KontextWebview(
                      urlRequest: URLRequest(
                        url: WebUri('$adServerUrl/api/$component/$bidId?code=$code&messageId=$messageId'),
                      ),
                      allowedUrlSubstrings: [adServerUrl],
                      onMessageReceived: (controller, messageType, data) {
                        switch (messageType) {
                          case 'init-component-iframe':
                            _initTimer?.cancel();
                            visible.value = true;
                            break;
                          case 'close-component-iframe':
                          case 'error-component-iframe':
                            close();
                            break;
                          default:
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_entry!);
    _initTimer = Timer(initTimeout, () => close());
  }

  static void close() {
    _initTimer?.cancel();
    _initTimer = null;
    _entry?.remove();
    _entry = null;
  }
}
