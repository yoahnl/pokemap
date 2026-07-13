List<T> deduplicateNarrativeEventReadValues<T>({
  required Iterable<T> values,
  required String Function(T value) keyOf,
  required Comparator<T> compare,
}) {
  final byKey = <String, T>{};
  for (final value in values) {
    byKey.putIfAbsent(keyOf(value), () => value);
  }
  final result = byKey.values.toList()..sort(compare);
  return List.unmodifiable(result);
}
