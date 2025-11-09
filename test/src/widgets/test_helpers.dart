import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show Json;
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
  bool isDisabled = false,
  List<Bid>? bids,
  VoidCallback? resetAll,
  required Widget child,
}) {
  return AdsProviderData(
    adServerUrl: 'https://example.com/ad',
    messages: const [],
    bids: bids ?? [Bid(id: '1', code: 'test_code', position: AdDisplayPosition.afterAssistantMessage)],
    enabledPlacementCodes: ['test_code'],
    isDisabled: isDisabled,
    readyForStreamingAssistant: true,
    readyForStreamingUser: false,
    lastAssistantMessageId: 'msg_1',
    lastUserMessageId: null,
    relevantAssistantMessageId: null,
    setRelevantAssistantMessageId: (_) {},
    resetAll: resetAll ?? () {},
    onEvent: (_) {},
    child: child,
  );
}
