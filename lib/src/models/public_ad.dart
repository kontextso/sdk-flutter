class PublicAd {
  PublicAd({
    required this.id,
    required this.code,
    this.messageId,
    this.content,
  });

  /// A unique identifier for the ad.
  final String id;

  /// The ad format code that identifies the displayed ad.
  final String code;

  /// A unique identifier for the message associated with this ad.
  final String? messageId;

  /// The content of the message.
  final String? content;

  factory PublicAd.fromJson(Map<String, dynamic> json) {
    return PublicAd(
      id: json['id'] as String,
      code: json['code'] as String,
      messageId: json['messageId'] as String?,
      content: json['content'] as String?,
    );
  }

  @override
  String toString() {
    return 'PublicAd(id: $id, code: $code, messageId: $messageId, content: $content)';
  }
}
