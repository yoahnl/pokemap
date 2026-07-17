final class PokemonSdkStudioProjectPayload {
  PokemonSdkStudioProjectPayload({
    required List<Map<String, dynamic>> moves,
    required List<Map<String, dynamic>> abilities,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> types,
    required List<Map<String, dynamic>> pokemon,
  })  : moves = _freezeJsonMaps(moves),
        abilities = _freezeJsonMaps(abilities),
        items = _freezeJsonMaps(items),
        types = _freezeJsonMaps(types),
        pokemon = _freezeJsonMaps(pokemon);

  final List<Map<String, dynamic>> moves;
  final List<Map<String, dynamic>> abilities;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> types;
  final List<Map<String, dynamic>> pokemon;
}

List<Map<String, dynamic>> _freezeJsonMaps(
  List<Map<String, dynamic>> entries,
) {
  return List<Map<String, dynamic>>.unmodifiable(
    entries.map(
      (entry) => Map<String, dynamic>.unmodifiable(_copyJsonMap(entry)),
    ),
  );
}

Map<String, dynamic> _copyJsonMap(Map<String, dynamic> source) {
  return source.map((key, value) => MapEntry(key, _copyJsonValue(value)));
}

Object? _copyJsonValue(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_copyJsonValue));
  }
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(
      value.cast<String, dynamic>().map(
            (key, nestedValue) => MapEntry(key, _copyJsonValue(nestedValue)),
          ),
    );
  }
  return value;
}
