import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

VoidCallback useUpdate() {
  final attempt = useState(0);
  return () => attempt.value++;
}