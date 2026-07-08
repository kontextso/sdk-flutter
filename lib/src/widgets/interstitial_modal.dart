import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json, OpenIframeComponent;
import 'package:kontext_flutter_sdk/src/widgets/kontext_webview.dart';

typedef InterstitialModalShowFunc = void Function(
  BuildContext context, {
  required String adServerUrl,
  required Uri uri,
  required Duration initTimeout,
  required void Function(Json? data) onClickIframe,
  required OnEventIframe onEventIframe,
  required void Function(OpenIframeComponent component, Json? data) onOpenComponentIframe,
  required void Function(OpenIframeComponent component) onCloseComponentIframe,
});

class InterstitialModal {
  static OverlayEntry? _entry;
  static Timer? _initTimer;

  static bool _orientationLocked = false;
  static List<DeviceOrientation>? _restoreOrientations;

  static void show(
    BuildContext context, {
    required String adServerUrl,
    required Uri uri,
    required Duration initTimeout,
    required void Function(Json? data) onClickIframe,
    required OnEventIframe onEventIframe,
    required void Function(OpenIframeComponent component, Json? data) onOpenComponentIframe,
    required void Function(OpenIframeComponent component) onCloseComponentIframe,
    @visibleForTesting Key? animatedOpacityKey,
    @visibleForTesting KontextWebviewBuilder? webviewBuilder,
  }) {
    closeSKOverlay() => onCloseComponentIframe(OpenIframeComponent.skoverlay);
    closeAll() {
      closeSKOverlay();
      closeModal();
    }

    closeModal();

    final visible = ValueNotifier<bool>(false);

    final buildWebview = webviewBuilder ??
        ({
          Key? key,
          required Uri uri,
          required List<String> allowedOrigins,
          required OnEventIframe onEventIframe,
          required OnMessageReceived onMessageReceived,
        }) =>
            KontextWebview(
              key: key,
              uri: uri,
              allowedOrigins: allowedOrigins,
              onEventIframe: onEventIframe,
              onMessageReceived: onMessageReceived,
            );

    _entry = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, isVisible, __) {
            return IgnorePointer(
              ignoring: !isVisible,
              child: AnimatedOpacity(
                key: animatedOpacityKey,
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: buildWebview(
                    uri: uri,
                    allowedOrigins: [adServerUrl],
                    onEventIframe: onEventIframe,
                    onMessageReceived: (controller, messageType, data) {
                      switch (messageType) {
                        case 'init-component-iframe':
                          if (!_orientationLocked) {
                            _restoreOrientations ??= DeviceOrientation.values;
                            _orientationLocked = true;
                            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                          }

                          _initTimer?.cancel();
                          visible.value = true;
                          break;
                        case 'open-component-iframe':
                        case 'open-skoverlay-iframe':
                          final component = OpenIframeComponent.fromMessageType(messageType);
                          if (component == null) {
                            return;
                          }
                          onOpenComponentIframe(component, data);
                          break;
                        case 'close-component-iframe':
                          closeModal();
                          break;
                        case 'close-skoverlay-iframe':
                          closeSKOverlay();
                          break;
                        case 'error-component-iframe':
                          closeAll();
                          break;
                        case 'click-iframe':
                          onClickIframe(data);
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
    _initTimer = Timer(initTimeout, () => closeAll());
  }

  static void closeModal() {
    _initTimer?.cancel();
    _initTimer = null;
    _entry?.remove();
    _entry = null;

    if (_orientationLocked) {
      final toRestore = _restoreOrientations ?? DeviceOrientation.values;
      SystemChrome.setPreferredOrientations(toRestore).whenComplete(() {
        _orientationLocked = false;
        _restoreOrientations = null;
      });
    }
  }
}
