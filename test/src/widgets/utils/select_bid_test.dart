import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/widgets/utils/select_bid.dart';

void main() {
  Bid makeBid(String code, AdDisplayPosition position) => Bid.fromJson({
        'bidId': 'bid-$code',
        'code': code,
        'adDisplayPosition': position == AdDisplayPosition.afterAssistantMessage
            ? 'afterAssistantMessage'
            : 'afterUserMessage',
      });

  AdsProviderData makeData({
    required List<Bid> bids,
    List<String> placementCodes = const ['inlineAd'],
    String? lastAssistantMessageId,
    String? relevantAssistantMessageId,
    String? lastUserMessageId,
    bool readyForStreamingAssistant = true,
    bool readyForStreamingUser = true,
  }) {
    return AdsProviderData(
      adServerUrl: 'https://ads.example',
      messages: const <Message>[],
      bids: bids,
      isDisabled: false,
      enabledPlacementCodes: placementCodes,
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

  group('selectBid', () {
    test('returns null when placement code is not enabled', () {
      final data = makeData(
        bids: [makeBid('inlineAd', AdDisplayPosition.afterAssistantMessage)],
        placementCodes: const [],
      );
      expect(selectBid(data, code: 'inlineAd', messageId: 'm-1'), isNull);
    });

    test('returns null when no bid matches the code', () {
      final data = makeData(
        bids: [makeBid('boxAd', AdDisplayPosition.afterAssistantMessage)],
        placementCodes: const ['inlineAd'],
      );
      expect(selectBid(data, code: 'inlineAd', messageId: 'm-1'), isNull);
    });

    test('returns the matching bid when the afterAssistant conditions align', () {
      final bid = makeBid('inlineAd', AdDisplayPosition.afterAssistantMessage);
      final data = makeData(
        bids: [bid],
        lastAssistantMessageId: 'm-1',
        readyForStreamingAssistant: true,
      );
      expect(selectBid(data, code: 'inlineAd', messageId: 'm-1'), bid);
    });

    test('prefers relevantAssistantMessageId over lastAssistantMessageId', () {
      final bid = makeBid('inlineAd', AdDisplayPosition.afterAssistantMessage);
      final data = makeData(
        bids: [bid],
        lastAssistantMessageId: 'm-2',
        relevantAssistantMessageId: 'm-1',
        readyForStreamingAssistant: true,
      );
      // Only m-1 matches — m-2 should not because relevant overrides last.
      expect(selectBid(data, code: 'inlineAd', messageId: 'm-1'), bid);
      expect(selectBid(data, code: 'inlineAd', messageId: 'm-2'), isNull);
    });

    test('returns null when assistant streaming is not ready', () {
      final bid = makeBid('inlineAd', AdDisplayPosition.afterAssistantMessage);
      final data = makeData(
        bids: [bid],
        lastAssistantMessageId: 'm-1',
        readyForStreamingAssistant: false,
      );
      expect(selectBid(data, code: 'inlineAd', messageId: 'm-1'), isNull);
    });

    test('returns null for a mismatched assistant messageId', () {
      final bid = makeBid('inlineAd', AdDisplayPosition.afterAssistantMessage);
      final data = makeData(
        bids: [bid],
        lastAssistantMessageId: 'm-1',
        readyForStreamingAssistant: true,
      );
      expect(selectBid(data, code: 'inlineAd', messageId: 'other'), isNull);
    });

    test('afterUser bid requires lastUserMessageId + readyForStreamingUser', () {
      final bid = makeBid('inlineAd', AdDisplayPosition.afterUserMessage);
      final data = makeData(
        bids: [bid],
        lastUserMessageId: 'u-1',
        readyForStreamingUser: true,
      );
      expect(selectBid(data, code: 'inlineAd', messageId: 'u-1'), bid);
    });

    test('afterUser bid with readyForStreamingUser=false returns null', () {
      final bid = makeBid('inlineAd', AdDisplayPosition.afterUserMessage);
      final data = makeData(
        bids: [bid],
        lastUserMessageId: 'u-1',
        readyForStreamingUser: false,
      );
      expect(selectBid(data, code: 'inlineAd', messageId: 'u-1'), isNull);
    });

    test('afterUser bid with mismatched user messageId returns null', () {
      final bid = makeBid('inlineAd', AdDisplayPosition.afterUserMessage);
      final data = makeData(
        bids: [bid],
        lastUserMessageId: 'u-1',
        readyForStreamingUser: true,
      );
      expect(selectBid(data, code: 'inlineAd', messageId: 'u-2'), isNull);
    });

    test('picks the first bid for a code when multiple exist', () {
      final first = Bid.fromJson({
        'bidId': 'bid-1',
        'code': 'inlineAd',
        'adDisplayPosition': 'afterAssistantMessage',
      });
      final second = Bid.fromJson({
        'bidId': 'bid-2',
        'code': 'inlineAd',
        'adDisplayPosition': 'afterAssistantMessage',
      });
      final data = makeData(
        bids: [first, second],
        lastAssistantMessageId: 'm-1',
        readyForStreamingAssistant: true,
      );
      expect(selectBid(data, code: 'inlineAd', messageId: 'm-1'), first);
    });
  });
}
