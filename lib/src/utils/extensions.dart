import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show ChromeSafariBrowser, WebUri, ChromeSafariBrowserSettings;
import 'package:kontext_flutter_sdk/src/services/logger.dart';
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

  List<E>? get nullIfEmpty {
    return isEmpty ? null : this;
  }
}

extension MapExtension<K, V> on Map<K, V> {
  V? getOrNull(K key) {
    if (containsKey(key)) {
      return this[key];
    }
    return null;
  }
}

extension StringExtension on String {
  String? get nullIfEmpty {
    final cleaned = trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}

extension UriExtension on Uri {
  Future<bool> openInAppBrowser() async {
    try {
      final webUri = WebUri.uri(this);
      final browser = ChromeSafariBrowser();
      browser.open(
        url: webUri,
        settings: ChromeSafariBrowserSettings(barCollapsingEnabled: true),
      );
      return true;
    } catch (e, stack) {
      Logger.exception(e, stack);
      return false;
    }
  }

  Uri replacePath(String newPath) {
    final params = queryParameters;
    return replace(path: newPath, queryParameters: params.isEmpty ? null : params);
  }
}

extension DoubleExtension on double {
  double? get nullIfNaN => isNaN ? null : this;
}
