import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json, OnEventCallback;
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/widgets/kontext_webview.dart' show OnMessageReceived;
import 'package:mocktail/mocktail.dart';

typedef IsDisabledAndBids = ({bool isDisabled, List<Bid> bids});

class FakeWebview extends StatelessWidget {
  const FakeWebview({
    super.key,
    required this.onEventIframe,
    required this.onMessageReceived,
  });

  final void Function(Json? data) onEventIframe;
  final OnMessageReceived onMessageReceived;

  @override
  Widget build(BuildContext context) {
    return Container(key: const Key('fake_webview'));
  }
}

class MockInAppWebViewController extends Mock implements InAppWebViewController {}

void onActiveChanged(bool _) {}

AdsProviderData createDefaultProvider({
  String? adServerUrl,
  bool? isDisabled,
  List<Bid>? bids,
  bool? readyForStreamingAssistant,
  bool? readyForStreamingUser,
  String? lastAssistantMessageId,
  String? lastUserMessageId,
  String? relevantAssistantMessageId,
  VoidCallback? resetAll,
  OnEventCallback? onEvent,
  required Widget child,
}) {
  return AdsProviderData(
    adServerUrl: adServerUrl ?? 'https://example.com/ad',
    messages: const [],
    bids: bids ?? [Bid(id: '1', code: 'test_code', position: AdDisplayPosition.afterAssistantMessage),],
    enabledPlacementCodes: ['test_code'],
    isDisabled: isDisabled ?? false,
    readyForStreamingAssistant: readyForStreamingAssistant ?? true,
    readyForStreamingUser: readyForStreamingUser ?? false,
    lastAssistantMessageId: lastAssistantMessageId ?? 'msg_1',
    lastUserMessageId: lastUserMessageId,
    relevantAssistantMessageId: relevantAssistantMessageId,
    setRelevantAssistantMessageId: (_) {},
    resetAll: resetAll ?? () {},
    onEvent: onEvent ?? (_) {},
    child: child,
  );
}
