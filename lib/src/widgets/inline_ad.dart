import 'package:flutter/material.dart';
import 'package:kontext_flutter_sdk/src/widgets/ad_format.dart';

class InlineAd extends StatefulWidget {
  const InlineAd({
    super.key,
    required this.code,
    required this.messageId,
    this.otherParams,
  });

  /// The ad format code that identifies the ad to be displayed.
  final String code;

  /// A unique identifier for the message associated with this ad.
  final String messageId;

  /// Additional parameters associated with the ad.
  final Map<String, dynamic>? otherParams;

  @override
  InlineAdState createState() => InlineAdState();
}

class InlineAdState extends State<InlineAd> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AdFormat(
      code: widget.code,
      messageId: widget.messageId,
      otherParams: widget.otherParams,
    );
  }
}
