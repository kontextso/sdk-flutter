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
