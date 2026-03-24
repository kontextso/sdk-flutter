import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
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
  OmCreativeType? omCreativeType,
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
    OmCreativeType? omCreativeType,
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
                duration: const Duration(milliseconds: kInterstitialFadeDurationMs),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: (webviewBuilder ?? KontextWebview.new)(
                    uri: uri,
                    allowedOrigins: [adServerUrl],
                    omCreativeType: omCreativeType,
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
                        case 'ad-done-component-iframe':
                          if (omCreativeType != null) {
                            unawaited(controller.startOpenMeasurementSession());
                          }
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
                          if (omCreativeType != null) {
                            unawaited(() async {
                              await controller.logOpenMeasurementError(
                                errorType: data?['errorType'] as String?,
                                message: data?['message'] as String?,
                              );
                              closeAll();
                            }());
                            return;
                          }
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
    _initTimer = Timer(initTimeout + const Duration(milliseconds: 500), () => closeAll());
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
