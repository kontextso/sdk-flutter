enum AdDisplayPosition { afterAssistantMessage, afterUserMessage }

class Bid {
  Bid({
    required this.id,
    required this.code,
    this.value,
    required this.position,
  });

  final String id;
  final String code;
  final int? value;
  final AdDisplayPosition position;

  bool get isAfterAssistantMessage => position == AdDisplayPosition.afterAssistantMessage;

  bool get isAfterUserMessage => position == AdDisplayPosition.afterUserMessage;

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['bidId'] as String,
      code: json['code'] as String,
      value: json['value'] as int?,
      position: AdDisplayPosition.values.firstWhere(
        (position) => position.name == '${json['adDisplayPosition']}',
        orElse: () => AdDisplayPosition.afterAssistantMessage,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Bid && id == other.id && code == other.code && value == other.value && position == other.position;
  }

  @override
  int get hashCode => Object.hash(id, code, value, position);

  @override
  String toString() {
    return 'Bid(id: $id, code: $code, value: $value, position: $position)';
  }
}
