import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';

void main() {
  Bid bid(String id) => Bid.fromJson({
        'bidId': id,
        'code': 'inlineAd',
        'adDisplayPosition': 'afterAssistantMessage',
      });

  Message msg(String id, {MessageRole role = MessageRole.user}) =>
      Message(id: id, role: role, content: 'c', createdAt: DateTime.utc(2025));

  AdsProviderData build({
    String adServerUrl = 'https://a.test',
    List<Message>? messages,
    List<Bid>? bids,
    bool isDisabled = false,
    List<String>? placements,
    Map<String, dynamic>? otherParams,
    bool readyForStreamingAssistant = false,
    bool readyForStreamingUser = false,
    String? lastAssistantMessageId,
    String? lastUserMessageId,
    String? relevantAssistantMessageId,
  }) {
    return AdsProviderData(
      adServerUrl: adServerUrl,
      messages: messages ?? const [],
      bids: bids ?? const [],
      isDisabled: isDisabled,
      enabledPlacementCodes: placements ?? const ['inlineAd'],
      otherParams: otherParams,
      readyForStreamingAssistant: readyForStreamingAssistant,
      readyForStreamingUser: readyForStreamingUser,
      lastAssistantMessageId: lastAssistantMessageId,
      lastUserMessageId: lastUserMessageId,
      relevantAssistantMessageId: relevantAssistantMessageId,
      setRelevantAssistantMessageId: (_) {},
      getCachedContent: (_) => null,
      setCachedContent: (_, __) {},
      resetAll: () {},
      onEvent: null,
      child: const SizedBox.shrink(),
    );
  }

  group('AdsProviderData.of', () {
    testWidgets('returns the nearest ancestor instance', (tester) async {
      AdsProviderData? captured;
      final data = build();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AdsProviderData(
            adServerUrl: data.adServerUrl,
            messages: data.messages,
            bids: data.bids,
            isDisabled: data.isDisabled,
            enabledPlacementCodes: data.enabledPlacementCodes,
            otherParams: data.otherParams,
            readyForStreamingAssistant: data.readyForStreamingAssistant,
            readyForStreamingUser: data.readyForStreamingUser,
            lastAssistantMessageId: data.lastAssistantMessageId,
            lastUserMessageId: data.lastUserMessageId,
            relevantAssistantMessageId: data.relevantAssistantMessageId,
            setRelevantAssistantMessageId: data.setRelevantAssistantMessageId,
            getCachedContent: data.getCachedContent,
            setCachedContent: data.setCachedContent,
            resetAll: data.resetAll,
            onEvent: data.onEvent,
            child: Builder(builder: (context) {
              captured = AdsProviderData.of(context);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.adServerUrl, 'https://a.test');
    });

    testWidgets('returns null when no AdsProviderData ancestor exists', (tester) async {
      AdsProviderData? captured;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              captured = AdsProviderData.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured, isNull);
    });
  });

  group('updateShouldNotify', () {
    test('no-op when all fields equal', () {
      final a = build();
      final b = build();
      expect(a.updateShouldNotify(b), isFalse);
    });

    test('changes to adServerUrl, isDisabled, lastUserMessageId and each flag retrigger', () {
      final base = build();
      expect(base.updateShouldNotify(build(adServerUrl: 'https://other')), isTrue);
      expect(base.updateShouldNotify(build(isDisabled: true)), isTrue);
      expect(base.updateShouldNotify(build(readyForStreamingAssistant: true)), isTrue);
      expect(base.updateShouldNotify(build(readyForStreamingUser: true)), isTrue);
      expect(base.updateShouldNotify(build(lastAssistantMessageId: 'a-1')), isTrue);
      expect(base.updateShouldNotify(build(relevantAssistantMessageId: 'r-1')), isTrue);
      expect(base.updateShouldNotify(build(lastUserMessageId: 'u-1')), isTrue);
    });

    test('messages list change retriggers', () {
      final base = build();
      final withMessage = build(messages: [msg('m-1')]);
      expect(base.updateShouldNotify(withMessage), isTrue);
    });

    test('bids list change retriggers', () {
      final base = build();
      final withBid = build(bids: [bid('b-1')]);
      expect(base.updateShouldNotify(withBid), isTrue);
    });

    test('placementCodes list change retriggers', () {
      final base = build();
      final other = build(placements: ['boxAd']);
      expect(base.updateShouldNotify(other), isTrue);
    });

    test('otherParams change retriggers', () {
      final base = build(otherParams: const {'theme': 'dark'});
      final changed = build(otherParams: const {'theme': 'light'});
      expect(base.updateShouldNotify(changed), isTrue);
    });

    test('deep-equal otherParams does NOT retrigger', () {
      final a = build(otherParams: const {'theme': 'dark'});
      final b = build(otherParams: const {'theme': 'dark'});
      expect(a.updateShouldNotify(b), isFalse);
    });

    test('deep-equal messages list does NOT retrigger', () {
      final a = build(messages: [msg('m-1')]);
      final b = build(messages: [msg('m-1')]);
      expect(a.updateShouldNotify(b), isFalse);
    });
  });
}
