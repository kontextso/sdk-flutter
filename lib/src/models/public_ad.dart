class PublicAd {
  PublicAd({
    this.id,
    this.code,
    this.messageId,
    this.content,
  });

  final String? id;
  final String? code;
  final String? messageId;
  final String? content;

  factory PublicAd.fromJson(Map<String, dynamic> json) {
    return PublicAd(
      id: json['id'] as String?,
      code: json['code'] as String?,
      messageId: json['messageId'] as String?,
      content: json['content'] as String?,
    );
  }

  @override
  String toString() {
    return 'PublicAd(id: $id, code: $code, messageId: $messageId, content: $content)';
  }
}
