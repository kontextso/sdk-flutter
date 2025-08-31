import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart' show Json;
import 'package:kontext_flutter_sdk/src/widgets/kontext_webview.dart';

class InterstitialModal {
  static OverlayEntry? _entry;
  static Timer? _initTimer;

  static void show(
    BuildContext context, {
    required String adServerUrl,
    required Uri uri,
    required void Function(Json? data) onAdClick,
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
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: KontextWebview(
                    uri: uri,
                    allowedOrigins: [adServerUrl],
                    onMessageReceived: (controller, messageType, data) {
                      switch (messageType) {
                        case 'init-component-iframe':
                          _initTimer?.cancel();
                          visible.value = true;
                          break;
                        case 'click-iframe':
                          onAdClick(data);
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
            );
          },
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _initTimer = Timer(initTimeout, () => close());
  }

  static void close() {
    _initTimer?.cancel();
    _initTimer = null;
    _entry?.remove();
    _entry = null;
  }
}
