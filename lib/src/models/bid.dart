import 'package:kontext_flutter_sdk/src/models/enums.dart';

class Bid {
  Bid({required this.id, required this.code, required this.position});

  final String id;
  final String code;
  final AdDisplayPosition position;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Bid && id == other.id && code == other.code && position == other.position;
  }

  @override
  int get hashCode => Object.hash(id, code, position);
}
