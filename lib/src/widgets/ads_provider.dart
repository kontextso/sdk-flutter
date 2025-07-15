import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kontext_flutter_sdk/src/widgets/ads_provider_data.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/widgets/use_preload_ads.dart';

class AdsProvider extends HookWidget {
  const AdsProvider({
    super.key,
    required this.publisherToken,
    required this.userId,
    required this.conversationId,
    required this.messages,
    required this.child,
  });

  final String publisherToken;
  final String userId;
  final String conversationId;
  final List<Message> messages;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bids = usePreloadAds(
      context,
      publisherToken: publisherToken,
      messages: messages,
      userId: userId,
      conversationId: conversationId,
    );

    return AdsProviderData(
      messages: messages,
      bids: bids,
      child: child,
    );
  }
}
