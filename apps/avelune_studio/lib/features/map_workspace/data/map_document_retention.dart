import 'dart:convert';

import 'package:map_core/map_core.dart';

void requireMapDocumentRetention(List<int> bytes, MapData map) {
  final source = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
  final encoded = jsonDecode(jsonEncode(map.toJson()));
  _requireRetained(source, encoded);
}

void _requireRetained(Object? source, Object? encoded) {
  if (source is Map && encoded is Map) {
    for (final key in source.keys) {
      if (!encoded.containsKey(key)) throw const FormatException();
      _requireRetained(source[key], encoded[key]);
    }
  } else if (source is List && encoded is List) {
    if (source.length != encoded.length) throw const FormatException();
    for (var index = 0; index < source.length; index++) {
      _requireRetained(source[index], encoded[index]);
    }
  } else if (source != encoded) {
    throw const FormatException();
  }
}
