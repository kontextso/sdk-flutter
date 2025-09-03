import 'package:flutter/material.dart';
import 'package:kontext_flutter_sdk/src/widgets/ad_format.dart';

/// A widget that displays an inline ad using a specific ad format.
class InlineAd extends StatefulWidget {
  const InlineAd({
    super.key,
    required this.code,
    required this.messageId,
  });

  /// The ad format code that identifies the ad to be displayed.
  final String code;

  /// A unique identifier for the message associated with this ad.
  final String messageId;

  @override
  InlineAdState createState() => InlineAdState();
}

class InlineAdState extends State<InlineAd> with AutomaticKeepAliveClientMixin {
  bool _keepAlive = false;

  @override
  bool get wantKeepAlive => _keepAlive;

  void _setKeepAlive(bool value) {
    if (!mounted || _keepAlive == value) return;
    setState(() => _keepAlive = value);
    updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AdFormat(
      code: widget.code,
      messageId: widget.messageId,
      onActiveChanged: _setKeepAlive,
    );
  }
}
