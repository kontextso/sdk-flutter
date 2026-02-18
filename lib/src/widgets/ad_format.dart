import 'dart:async' show Timer, unawaited;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/models/ad_event.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/utils/browser_opener.dart';
import 'package:kontext_flutter_sdk/src/services/sk_overlay_service.dart';
import 'package:kontext_flutter_sdk/src/services/ad_attribution_kit.dart';
import 'package:kontext_flutter_sdk/src/services/sk_store_product_service.dart';
import 'package:kontext_flutter_sdk/src/utils/constants.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:kontext_flutter_sdk/src/utils/kontext_url_builder.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show OnEventCallback, Json, OpenIframeComponent;
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/select_bid.dart';
import 'package:kontext_flutter_sdk/src/widgets/interstitial_modal.dart';
import 'package:kontext_flutter_sdk/src/widgets/kontext_webview.dart';


class AdFormat extends HookWidget {
  const AdFormat({
    super.key,
    required this.code,
    required this.messageId,
    required this.onActiveChanged,
    @visibleForTesting this.webviewBuilder,
    @visibleForTesting this.showInterstitial,
    @visibleForTesting this.browserOpener = const BrowserOpener(),
  });

  static const Duration defaultTimeout = Duration(seconds: 5);

  final String code;
  final String messageId;
  final ValueChanged<bool> onActiveChanged;
  final KontextWebviewBuilder? webviewBuilder;
  final InterstitialModalShowFunc? showInterstitial;
  final BrowserOpener browserOpener;

  Rect _visibleWindowRect(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final top = mediaQuery.padding.top; // status bar / notch
    final left = mediaQuery.padding.left;
    final right = mediaQuery.padding.right;

    return Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top,
    );
  }

  Rect? _slotRectInWindow(GlobalKey key) {
    final currentContext = key.currentContext;
    if (currentContext == null) return null;

    final box = currentContext.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;

    final topLeft = box.localToGlobal(Offset.zero);
    final size = box.size;

    return Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height);
  }

  void _postDimensions({
    required BuildContext context,
    required GlobalKey key,
    InAppWebViewController? controller,
    required String adServerUrl,
    required bool Function() disposed,
    required bool isNullDimensions,
    required void Function(bool isNull) setIsNullDimensions,
  }) {
    if (disposed()) return;

    final slot = _slotRectInWindow(key);
    if (slot == null || controller == null) return;

    final viewport = _visibleWindowRect(context);
    final mq = MediaQueryData.fromView(View.of(context));
    final keyboardHeight = mq.viewInsets.bottom;

    final containerWidth = slot.width.nullIfNaN;
    final containerHeight = slot.height.nullIfNaN;
    final containerX = slot.left.nullIfNaN;
    final containerY = slot.top.nullIfNaN;

    final isAnyNullDimension =
        containerWidth == null || containerHeight == null || containerX == null || containerY == null;
    // If first time any dimension is null, we set the flag to avoid further posts
    setIsNullDimensions(isAnyNullDimension);

    if (isNullDimensions) return;

    final payload = {
      'type': 'update-dimensions-iframe',
      'data': {
        'windowWidth': viewport.width.nullIfNaN,
        'windowHeight': viewport.height.nullIfNaN,
        'containerWidth': slot.width.nullIfNaN,
        'containerHeight': slot.height.nullIfNaN,
        'containerX': slot.left.nullIfNaN,
        'containerY': slot.top.nullIfNaN,
        'keyboardHeight': keyboardHeight.nullIfNaN,
      },
    };

    _postMessageToWebView(adServerUrl, controller, payload);
  }

  void _postUpdateIframe(
    InAppWebViewController controller, {
    required String adServerUrl,
    required List<Message> messages,
    Map<String, dynamic>? otherParams,
  }) {
    final payload = {
      'type': 'update-iframe',
      'data': {
        'sdk': kSdkLabel,
        'code': code,
        'messageId': messageId,
        'messages': messages.map((m) => m.toJson()).toList(),
        if (otherParams != null) 'otherParams': otherParams,
      },
    };

    _postMessageToWebView(adServerUrl, controller, payload);
  }

  void _postMessageToWebView(
    String adServerUrl,
    InAppWebViewController controller,
    Json payload,
  ) {
    controller.evaluateJavascript(source: '''
      window.postMessage(${jsonEncode(payload)}, '$adServerUrl');
    ''');
  }

  void _handleWebViewCreated(
    BuildContext context, {
    required String adServerUrl,
    required InAppWebViewController controller,
    required String messageType,
    required GlobalKey key,
    Json? data,
    required bool Function() isDisposed,
    required Uri inlineUri,
    required String bidId,
    required ValueNotifier<bool> iframeLoaded,
    required ValueNotifier<bool> showIframe,
    required ValueNotifier<double> height,
    required VoidCallback resetIframe,
    required AdsProviderData adsProviderData,
  }) {
    switch (messageType) {
      case 'init-iframe':
        iframeLoaded.value = true;
        _handleAdAttributionKitInitialization(data);
        break;
      case 'show-iframe':
        showIframe.value = true;
        break;
      case 'hide-iframe':
        showIframe.value = false;
        break;
      case 'resize-iframe':
        final dataHeight = data?['height'];
        if (dataHeight is num) {
          height.value = dataHeight.toDouble();
        }
        break;
      case 'click-iframe':
        _handleClickIframe(adServerUrl: adServerUrl, controller: controller, data: data);
        break;
      case 'ad-done-iframe':
        final content = data?['cachedContent'] as String?;
        if (content != null) {
          adsProviderData.setCachedContent(bidId, content);
        }
        _handleAdAttributionKitBeginView(key);
        break;
      case 'open-component-iframe':
      case 'open-skoverlay-iframe':
      case 'open-skstoreproduct-iframe':
        final component = OpenIframeComponent.fromMessageType(messageType);
        if (component == null) {
          return;
        }

        _handleOpenComponentIframe(
          context,
          adServerUrl: adServerUrl,
          controller: controller,
          inlineUri: inlineUri,
          bidId: bidId,
          component: component,
          data: data,
          onEvent: adsProviderData.onEvent,
        );
        break;
      case 'close-component-iframe':
      case 'close-skoverlay-iframe':
      case 'close-skstoreproduct-iframe':
        final component = OpenIframeComponent.fromMessageType(messageType);
        if (component == null) {
          return;
        }

        _handleCloseComponentIframe(component, adServerUrl: adServerUrl, controller: controller);
        break;
      case 'error-iframe':
        resetIframe();
        break;
      default:
    }
  }

  Future<void> _handleClickIframe({
    required String adServerUrl,
    required InAppWebViewController controller,
    Json? data,
  }) async {
    try {
      final path = data?['url'];
      final appStoreId = data?['appStoreId'];

      final uri = (path is String) ? KontextUrlBuilder(baseUrl: adServerUrl, path: path).buildUri() : null;

      final navigationHandled = await AdAttributionKit.handleTap(uri);

      if (appStoreId == null) {
        if (uri != null && !navigationHandled) {
          browserOpener.open(uri);
        }
        return;
      }

      final storeProductOpened = await _presentSkStoreProduct(
        adServerUrl,
        controller,
        appStoreId,
      );

      if (!storeProductOpened && uri != null && !navigationHandled) {
        browserOpener.open(uri);
      }
    } catch (e, stack) {
      Logger.exception(e, stack);
      return;
    }
  }

  void _handleEventIframe({required String adServerUrl, OnEventCallback? onEvent, Json? data}) {
    if (data == null) {
      return;
    }

    try {
      final payload = data['payload'] as Json?;
      final path = payload?['url'] as String?;
      final uri = (path is String) ? KontextUrlBuilder(baseUrl: adServerUrl, path: path).buildUri() : null;

      final updatedData = {
        ...data,
        if (payload != null)
          'payload': {
            ...payload,
            if (uri != null) 'url': uri.toString(),
          }
      };

      final adEvent = AdEvent.fromJson(updatedData);
      onEvent?.call(adEvent);
    } catch (e, stack) {
      Logger.exception(e, stack);
      return;
    }
  }

  Future<bool> _presentSkOverlay(String adServerUrl, InAppWebViewController controller, Json data) async {
    final appStoreId = data['appStoreId'];
    if (appStoreId is! String || appStoreId.isEmpty) {
      Logger.error('App Store ID is required to open SKOverlay. Data: $data');
      return false;
    }

    final position = SKOverlayPosition.values.firstWhere(
      (e) => e.name == (data['position'] is String ? (data['position'] as String).toLowerCase() : null),
      orElse: () => SKOverlayPosition.bottom,
    );

    final dismissible = data['dismissible'];

    final success = await SKOverlayService.present(
      appStoreId: appStoreId,
      position: position,
      dismissible: dismissible is bool ? dismissible : true,
    );

    if (success) {
      _postMessageToWebView(adServerUrl, controller, {
        'type': 'update-skoverlay-iframe',
        'data': {'code': code, 'open': true},
      });
    }

    return success;
  }

  Future<bool> _dismissSkOverlay(String adServerUrl, InAppWebViewController? controller) async {
    final success = await SKOverlayService.dismiss();
    if (success && controller != null) {
      _postMessageToWebView(adServerUrl, controller, {
        'type': 'update-skoverlay-iframe',
        'data': {'code': code, 'open': false},
      });
    }
    return success;
  }

  Future<bool> _presentSkStoreProduct(
    String adServerUrl,
    InAppWebViewController controller,
    dynamic appStoreId,
  ) async {
    if (appStoreId is! String || appStoreId.isEmpty) {
      Logger.error('App Store ID is required to open SKStoreProduct. Data: $appStoreId');
      return false;
    }

    final success = await SKStoreProductService.present(appStoreId: appStoreId);
    if (success) {
      _postMessageToWebView(adServerUrl, controller, {
        'type': 'update-skstoreproduct-iframe',
        'data': {'code': code, 'open': true},
      });
    }
    return success;
  }

  // Ad Attribution Kit
  Future<void> _handleAdAttributionKitInitialization(Json? data) async {
    final attribution = data?['attribution'];
    if (attribution == null) return;
    if (attribution is! Json) {
      Logger.error('Ad attribution payload is invalid. Data: $data');
      return;
    }

    final framework = attribution['framework'];
    if (framework is! String || framework != 'adattributionkit') {
      Logger.error('Ad attribution framework is missing or not adattributionkit. Data: $data');
      return;
    }

    final jws = attribution['jws'];
    if (jws is! String || jws.isEmpty) {
      Logger.error('Ad attribution JWS is missing or invalid. Data: $data');
      return;
    }
    await AdAttributionKit.initImpression(jws);
  }

  Future<void> _handleAdAttributionKitBeginView(GlobalKey key) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final frameSet = await _setAdAttributionKitFrame(key);
      if (frameSet) {
        await AdAttributionKit.beginView();
      }
    });
  }

  Future<bool> _setAdAttributionKitFrame(GlobalKey key) async {
    final adContainer = _slotRectInWindow(key);
    if (adContainer == null) return false;
    return AdAttributionKit.setAttributionFrame(adContainer);
  }

  Future<void> _cleanupAdAttributionKitResources() async {
    await AdAttributionKit.endView();
    await AdAttributionKit.dispose();
  }

  Future<bool> _dismissSkStoreProduct(String adServerUrl, InAppWebViewController? controller) async {
    final success = await SKStoreProductService.dismiss();
    if (success && controller != null) {
      _postMessageToWebView(adServerUrl, controller, {
        'type': 'update-skstoreproduct-iframe',
        'data': {'code': code, 'open': false},
      });
    }
    return success;
  }

  Future<void> _handleOpenComponentIframe(
    BuildContext context, {
    required String adServerUrl,
    required InAppWebViewController controller,
    required Uri inlineUri,
    required String bidId,
    required OpenIframeComponent component,
    Json? data,
    OnEventCallback? onEvent,
  }) async {
    if (data == null) {
      Logger.error('Ad component data is missing. Component: $component');
      return;
    }

    final milliseconds = data['timeout'];
    final timeout =
        (milliseconds is int && milliseconds > 0) ? Duration(milliseconds: milliseconds) : AdFormat.defaultTimeout;

    switch (component) {
      case OpenIframeComponent.modal:
        final modalUri = inlineUri.replacePath('/api/${component.name}/$bidId');
        (showInterstitial ?? InterstitialModal.show)(
          context,
          adServerUrl: adServerUrl,
          uri: modalUri,
          initTimeout: timeout,
          onClickIframe: (data) => _handleClickIframe(
            adServerUrl: adServerUrl,
            controller: controller,
            data: data,
          ),
          onEventIframe: (controller, data) => _handleEventIframe(
            adServerUrl: adServerUrl,
            onEvent: onEvent,
            data: data,
          ),
          onOpenComponentIframe: (component, data) => _handleOpenComponentIframe(
            context,
            adServerUrl: adServerUrl,
            controller: controller,
            inlineUri: inlineUri,
            bidId: bidId,
            component: component,
            data: data,
            onEvent: onEvent,
          ),
          onCloseComponentIframe: (component) => _handleCloseComponentIframe(
            component,
            adServerUrl: adServerUrl,
            controller: controller,
          ),
        );
        break;
      case OpenIframeComponent.skoverlay:
        await _presentSkOverlay(adServerUrl, controller, data);
        break;
      case OpenIframeComponent.skstoreproduct:
        await _presentSkStoreProduct(adServerUrl, controller, data['appStoreId']);
        break;
    }
  }

  Future<void> _handleCloseComponentIframe(
    OpenIframeComponent component, {
    required String adServerUrl,
    required InAppWebViewController controller,
  }) async {
    switch (component) {
      case OpenIframeComponent.modal:
        break; // Do nothing, already handled by InterstitialModal
      case OpenIframeComponent.skoverlay:
        await _dismissSkOverlay(adServerUrl, controller);
        break;
      case OpenIframeComponent.skstoreproduct:
        await _dismissSkStoreProduct(adServerUrl, controller);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotKey = useMemoized(() => GlobalKey(), const []);

    final ticker = useRef<Timer?>(null);
    final delayedTicker = useRef<Timer?>(null);
    void cancelTimers() {
      delayedTicker.value?.cancel();
      delayedTicker.value = null;
      ticker.value?.cancel();
      ticker.value = null;
    }

    void setActive(bool active) => WidgetsBinding.instance.addPostFrameCallback((_) {
          onActiveChanged(active);
        });

    final adsProviderData = AdsProviderData.of(context);
    final disabled = adsProviderData == null || adsProviderData.isDisabled;

    final bidId = !disabled ? selectBid(adsProviderData, code: code, messageId: messageId)?.id : null;

    Uri? inlineUri;
    if (!disabled && bidId != null) {
      inlineUri = KontextUrlBuilder(
        baseUrl: adsProviderData.adServerUrl,
        path: '/api/frame/$bidId',
      )
          .addParam('code', code)
          .addParam('messageId', messageId)
          .addParam('sdk', kSdkLabel)
          .addParam('theme', adsProviderData.otherParams?['theme'])
          .addParam('cachedContent', adsProviderData.getCachedContent(bidId))
          .buildUri();
    }

    final isActive = !disabled && bidId != null && inlineUri != null;

    useEffect(() {
      setActive(isActive);
      return null;
    }, [isActive]);

    if (!isActive) return const SizedBox.shrink();

    final adServerUrl = adsProviderData.adServerUrl;
    final otherParams = adsProviderData.otherParams;

    final webviewController = useRef<InAppWebViewController?>(null);

    useEffect(() {
      return () {
        _dismissSkOverlay(adServerUrl, webviewController.value);
        _dismissSkStoreProduct(adServerUrl, webviewController.value);
      };
    }, const []);

    useEffect(() {
      return () => _cleanupAdAttributionKitResources();
    }, const []);

    useEffect(() {
      return () => setActive(false);
    }, const []);

    final disposed = useRef(false);
    useEffect(() {
      return () => disposed.value = true;
    }, const []);

    final iframeLoaded = useState(false);
    final showIframe = useState(false);
    final height = useState(.0);

    useEffect(() {
      // messageId can only become relevant if an ad was shown for that specific messageId
      if (showIframe.value && adsProviderData.lastAssistantMessageId == messageId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          adsProviderData.setRelevantAssistantMessageId(messageId);
        });
      }

      return null;
    }, [showIframe.value]);

    final isNullDimensions = useRef(false);
    useEffect(() {
      void postDimensions() => _postDimensions(
            context: context,
            controller: webviewController.value,
            key: slotKey,
            adServerUrl: adServerUrl,
            disposed: () => disposed.value,
            isNullDimensions: isNullDimensions.value,
            setIsNullDimensions: (isNull) => isNullDimensions.value = isNull,
          );
      final shouldRun = iframeLoaded.value && showIframe.value;
      if (shouldRun && ticker.value == null && delayedTicker.value == null) {
        // Start after a short delay to allow initial layout to settle
        delayedTicker.value = Timer(const Duration(milliseconds: 500), () {
          delayedTicker.value = null;
          if (!iframeLoaded.value || !showIframe.value || disposed.value) {
            return;
          }
          // First call immediately without waiting for the first tick
          postDimensions();
          ticker.value = Timer.periodic(
            const Duration(milliseconds: 300),
            (_) => postDimensions(),
          );
        });
      } else if (!shouldRun) {
        cancelTimers();
      }
      return null;
    }, [iframeLoaded.value, showIframe.value]);

    useEffect(() {
      return () => cancelTimers();
    }, const []);

    final otherParamsHash = otherParams?.deepHash;
    useEffect(() {
      if (!iframeLoaded.value || webviewController.value == null) {
        return null;
      }

      _postUpdateIframe(
        webviewController.value!,
        adServerUrl: adsProviderData.adServerUrl,
        messages: adsProviderData.messages.getLastMessages(),
        otherParams: otherParams,
      );

      return null;
    }, [iframeLoaded.value, webviewController.value, otherParamsHash]);

    void resetIframe() {
      unawaited(_cleanupAdAttributionKitResources());
      _dismissSkOverlay(adServerUrl, webviewController.value);
      _dismissSkStoreProduct(adServerUrl, webviewController.value);

      iframeLoaded.value = false;
      showIframe.value = false;
      height.value = 0.0;
      webviewController.value = null;
      adsProviderData.resetAll();
      setActive(false);
    }

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

    return Offstage(
      offstage: !iframeLoaded.value || !showIframe.value,
      child: Container(
        key: slotKey,
        height: height.value,
        width: double.infinity,
        color: Colors.transparent,
        child: buildWebview(
          key: ValueKey('ad-$messageId-$bidId'),
          uri: inlineUri,
          allowedOrigins: [adServerUrl],
          onEventIframe: (controller, data) => _handleEventIframe(
            adServerUrl: adServerUrl,
            onEvent: adsProviderData.onEvent,
            data: data,
          ),
          onMessageReceived: (controller, messageType, data) {
            webviewController.value = controller;
            _handleWebViewCreated(
              context,
              key: slotKey,
              adServerUrl: adServerUrl,
              controller: controller,
              messageType: messageType,
              isDisposed: () => disposed.value,
              data: data,
              inlineUri: inlineUri!,
              bidId: bidId,
              iframeLoaded: iframeLoaded,
              showIframe: showIframe,
              height: height,
              resetIframe: resetIframe,
              adsProviderData: adsProviderData,
            );
          },
        ),
      ),
    );
  }
}
