class Bid {
  Bid({required this.id, required this.code});

  final String id;
  final String code;

  bool get isAfterAssistantMessage => true;

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['bidId'] as String,
      code: json['code'] as String
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Bid && id == other.id && code == other.code;
  }

  @override
  int get hashCode => Object.hash(id, code);

  @override
  String toString() {
    return 'Bid(id: $id, code: $code)';
  }
}
