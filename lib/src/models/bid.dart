enum AdDisplayPosition { afterAssistantMessage, afterUserMessage }

class Bid {
  Bid({required this.id, required this.code, required this.position});

  final String id;
  final String code;
  final AdDisplayPosition position;

  bool get isAfterAssistantMessage => position == AdDisplayPosition.afterAssistantMessage;

  bool get isAfterUserMessage => position == AdDisplayPosition.afterUserMessage;

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['bidId'] as String,
      code: json['code'] as String,
      position: AdDisplayPosition.values.firstWhere(
        (position) => position.name == '${json['adDisplayPosition']}',
        orElse: () => AdDisplayPosition.afterAssistantMessage,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Bid && id == other.id && code == other.code && position == other.position;
  }

  @override
  int get hashCode => Object.hash(id, code, position);

  @override
  String toString() {
    return 'Bid(id: $id, code: $code, position: $position)';
  }
}
