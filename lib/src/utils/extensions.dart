import 'package:kontext_flutter_sdk/src/utils/helper_methods.dart';

extension DeepHashExt on Object? {
  int get deepHash => deepHashObject(this);
}
