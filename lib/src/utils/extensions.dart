import 'package:kontext_flutter_sdk/src/utils/helper_methods.dart';
import 'package:kontext_flutter_sdk/src/models/message.dart';

extension DeepHashExt on Object? {
  int get deepHash => deepHashObject(this);
}

extension ListExtension<E> on List<E> {
  E? firstWhereOrElse(bool Function(E element) test, {E Function()? orElse}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return orElse?.call();
  }

  E? lastWhereOrElse(bool Function(E element) test, {E Function()? orElse}) {
    for (int i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return orElse?.call();
  }
}

extension MessageListExtension on List<Message> {
  List<Message> getLastMessages({int count = 10}) {
    return length > count ? sublist(length - count) : this;
  }
}
