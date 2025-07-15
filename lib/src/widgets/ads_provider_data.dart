import 'package:flutter/material.dart';
import 'package:kontext_flutter_sdk/src/models/bid.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

class AdsProviderData extends InheritedWidget {
  const AdsProviderData({
    super.key,
    required this.messages,
    required this.bids,
    required super.child,
  });

  final List<Message> messages;
  final List<Bid> bids;

  static AdsProviderData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdsProviderData>();
  }

  @override
  bool updateShouldNotify(AdsProviderData oldWidget) {
    return oldWidget.messages.deepHash != messages.deepHash || oldWidget.bids.deepHash != bids.deepHash;
  }
}
