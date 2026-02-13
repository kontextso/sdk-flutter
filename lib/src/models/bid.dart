enum AdDisplayPosition { afterAssistantMessage, afterUserMessage }

class Bid {
  Bid({
    required this.id,
    required this.code,
    this.revenue,
    required this.position,
  });

  final String id;
  final String code;
  final double? revenue;
  final AdDisplayPosition position;

  bool get isAfterAssistantMessage => position == AdDisplayPosition.afterAssistantMessage;

  bool get isAfterUserMessage => position == AdDisplayPosition.afterUserMessage;

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['bidId'] as String,
      code: json['code'] as String,
      revenue: _parseRevenue(json['revenue']),
      position: AdDisplayPosition.values.firstWhere(
        (position) => position.name == '${json['adDisplayPosition']}',
        orElse: () => AdDisplayPosition.afterAssistantMessage,
      ),
    );
  }

  static double? _parseRevenue(Object? value) {
    if (value == null) return null;

    if (value is num) {
      if (!value.isFinite) return null;
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed == null || !parsed.isFinite) return null;
      return parsed;
    }

    return null;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Bid && id == other.id && code == other.code && revenue == other.revenue && position == other.position;
  }

  @override
  int get hashCode => Object.hash(id, code, revenue, position);

  @override
  String toString() {
    return 'Bid(id: $id, code: $code, revenue: $revenue, position: $position)';
  }
}
