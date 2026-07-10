import 'dart:convert';

import 'package:crypto/crypto.dart';

/// RFC 8785 JSON Canonicalization Scheme for I-JSON-compatible Dart values.
String canonicalizeNarrativeEventJson(Object? value) {
  final buffer = StringBuffer();
  _writeCanonicalJson(value, buffer, path: r'$');
  return buffer.toString();
}

List<int> canonicalizeNarrativeEventJsonUtf8(Object? value) {
  return utf8.encode(canonicalizeNarrativeEventJson(value));
}

String narrativeEventCanonicalSha256(Object? value) {
  return sha256.convert(canonicalizeNarrativeEventJsonUtf8(value)).toString();
}

int compareNarrativeEventUtf16(String left, String right) {
  final leftUnits = left.codeUnits;
  final rightUnits = right.codeUnits;
  final commonLength = leftUnits.length < rightUnits.length
      ? leftUnits.length
      : rightUnits.length;
  for (var index = 0; index < commonLength; index++) {
    final comparison = leftUnits[index].compareTo(rightUnits[index]);
    if (comparison != 0) return comparison;
  }
  return leftUnits.length.compareTo(rightUnits.length);
}

void _writeCanonicalJson(
  Object? value,
  StringBuffer buffer, {
  required String path,
}) {
  switch (value) {
    case null:
      buffer.write('null');
    case bool value:
      buffer.write(value ? 'true' : 'false');
    case String value:
      _validateUnicodeScalarSequence(value, path: path);
      buffer.write(jsonEncode(value));
    case num value:
      buffer.write(_canonicalNumber(value, path: path));
    case List value:
      buffer.write('[');
      for (var index = 0; index < value.length; index++) {
        if (index != 0) buffer.write(',');
        _writeCanonicalJson(value[index], buffer, path: '$path[$index]');
      }
      buffer.write(']');
    case Map value:
      final entries = <MapEntry<String, Object?>>[];
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw FormatException('$path: JSON object keys must be strings.');
        }
        _validateUnicodeScalarSequence(key, path: '$path.<key>');
        entries.add(MapEntry(key, entry.value));
      }
      entries.sort(
        (left, right) => compareNarrativeEventUtf16(left.key, right.key),
      );
      buffer.write('{');
      for (var index = 0; index < entries.length; index++) {
        if (index != 0) buffer.write(',');
        final entry = entries[index];
        buffer
          ..write(jsonEncode(entry.key))
          ..write(':');
        _writeCanonicalJson(
          entry.value,
          buffer,
          path: '$path.${entry.key}',
        );
      }
      buffer.write('}');
    default:
      throw FormatException(
        '$path: Unsupported JSON value type ${value.runtimeType}.',
      );
  }
}

String _canonicalNumber(num value, {required String path}) {
  if (value is int && (value < -9007199254740991 || value > 9007199254740991)) {
    throw FormatException(
      '$path: JCS integers must stay within the I-JSON safe range.',
    );
  }
  final doubleValue = value.toDouble();
  if (!doubleValue.isFinite) {
    throw FormatException('$path: JCS numbers must be finite IEEE-754 values.');
  }
  if (doubleValue == 0) return '0';

  final encoded = jsonEncode(doubleValue);
  if (encoded.endsWith('.0')) {
    return encoded.substring(0, encoded.length - 2);
  }
  return encoded;
}

void _validateUnicodeScalarSequence(String value, {required String path}) {
  final units = value.codeUnits;
  for (var index = 0; index < units.length; index++) {
    final unit = units[index];
    if (unit >= 0xd800 && unit <= 0xdbff) {
      if (index + 1 >= units.length) {
        throw FormatException('$path: Unpaired high surrogate.');
      }
      final next = units[++index];
      if (next < 0xdc00 || next > 0xdfff) {
        throw FormatException('$path: Unpaired high surrogate.');
      }
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      throw FormatException('$path: Unpaired low surrogate.');
    }
  }
}
