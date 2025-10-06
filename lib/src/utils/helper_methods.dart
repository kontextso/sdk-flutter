import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:kontext_flutter_sdk/src/utils/types.dart' show OpenIframeComponent;

int deepHashObject(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    return Object.hashAll(
      entries.map((e) => Object.hash(deepHashObject(e.key), deepHashObject(e.value))),
    );
  }
  if (value is Iterable) {
    return Object.hashAll(value.map(deepHashObject));
  }
  return value.hashCode;
}

OpenIframeComponent? toOpenIframeComponent(dynamic value) {
  final component = OpenIframeComponent.values.firstWhereOrElse(
    (e) => e.name == (value is String ? value.toLowerCase() : null),
  );

  if (component == null) {
    Logger.error('Iframe component "$value" is not supported.');
    return null;
  }

  return component;
}