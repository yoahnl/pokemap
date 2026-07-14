import 'dart:convert';

import 'package:crypto/crypto.dart';

/// RFC 8785 JSON Canonicalization Scheme for I-JSON-compatible Dart values.
String canonicalizeNarrativeEventJson(Object? value) {
  final buffer = StringBuffer();
  _writeCanonicalJson(value, buffer, path: r'$');
  return buffer.toString();
}

/// Decodes a raw JSON source after rejecting duplicate object member names.
///
/// The returned value is also validated against the same I-JSON boundary used
/// by [canonicalizeNarrativeEventJson].
Object? decodeNarrativeEventJsonStrict(String source) {
  final duplicates = findDuplicateNarrativeEventJsonKeys(source);
  if (duplicates.isNotEmpty) {
    throw FormatException(
      'Duplicate JSON key${duplicates.length == 1 ? '' : 's'} at '
      '${duplicates.join(', ')}.',
    );
  }
  final decoded = jsonDecode(source);
  canonicalizeNarrativeEventJson(decoded);
  return decoded;
}

String canonicalizeNarrativeEventJsonText(String source) =>
    canonicalizeNarrativeEventJson(decodeNarrativeEventJsonStrict(source));

List<String> findDuplicateNarrativeEventJsonKeys(String source) =>
    _JsonDuplicateKeyScanner(source).scan();

List<int> canonicalizeNarrativeEventJsonUtf8(Object? value) {
  return utf8.encode(canonicalizeNarrativeEventJson(value));
}

String narrativeEventCanonicalSha256(Object? value) {
  return sha256.convert(canonicalizeNarrativeEventJsonUtf8(value)).toString();
}

String narrativeEventBytesFingerprint(List<int> bytes) {
  return 'sha256:${sha256.convert(bytes)}';
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
  final doubleValue = value.toDouble();
  if (!doubleValue.isFinite) {
    throw FormatException('$path: JCS numbers must be finite IEEE-754 values.');
  }
  if (value is int && doubleValue.toInt() != value) {
    throw FormatException(
      '$path: JSON integer cannot be represented exactly as IEEE-754 binary64.',
    );
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
    var codePoint = unit;
    if (unit >= 0xd800 && unit <= 0xdbff) {
      if (index + 1 >= units.length) {
        throw FormatException('$path: Unpaired high surrogate.');
      }
      final next = units[++index];
      if (next < 0xdc00 || next > 0xdfff) {
        throw FormatException('$path: Unpaired high surrogate.');
      }
      codePoint = 0x10000 + ((unit - 0xd800) << 10) + (next - 0xdc00);
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      throw FormatException('$path: Unpaired low surrogate.');
    }
    if ((codePoint >= 0xfdd0 && codePoint <= 0xfdef) ||
        (codePoint & 0xffff) == 0xfffe ||
        (codePoint & 0xffff) == 0xffff) {
      throw FormatException(
        '$path: Unicode noncharacter U+'
        '${codePoint.toRadixString(16).toUpperCase()}.',
      );
    }
  }
}

final class _JsonDuplicateKeyScanner {
  _JsonDuplicateKeyScanner(this.source);

  final String source;
  final List<String> _duplicates = <String>[];
  int _index = 0;

  List<String> scan() {
    _skipWhitespace();
    _parseValue(r'$');
    _skipWhitespace();
    if (_index != source.length) {
      throw FormatException('Unexpected JSON content at offset $_index.');
    }
    return List<String>.unmodifiable(_duplicates);
  }

  void _parseValue(String path) {
    _skipWhitespace();
    if (_index >= source.length) {
      throw const FormatException('Unexpected end of JSON input.');
    }
    switch (source.codeUnitAt(_index)) {
      case 0x7b:
        _parseObject(path);
      case 0x5b:
        _parseArray(path);
      case 0x22:
        _parseString();
      default:
        _parsePrimitive();
    }
  }

  void _parseObject(String path) {
    _expect(0x7b);
    _skipWhitespace();
    if (_consumeIf(0x7d)) return;
    final keys = <String>{};
    while (true) {
      _skipWhitespace();
      final key = _parseString();
      final keyPath = '$path.$key';
      if (!keys.add(key)) _duplicates.add(keyPath);
      _skipWhitespace();
      _expect(0x3a);
      _parseValue(keyPath);
      _skipWhitespace();
      if (_consumeIf(0x7d)) return;
      _expect(0x2c);
    }
  }

  void _parseArray(String path) {
    _expect(0x5b);
    _skipWhitespace();
    if (_consumeIf(0x5d)) return;
    var itemIndex = 0;
    while (true) {
      _parseValue('$path[$itemIndex]');
      itemIndex++;
      _skipWhitespace();
      if (_consumeIf(0x5d)) return;
      _expect(0x2c);
    }
  }

  String _parseString() {
    _skipWhitespace();
    final start = _index;
    _expect(0x22);
    var escaped = false;
    while (_index < source.length) {
      final unit = source.codeUnitAt(_index++);
      if (escaped) {
        escaped = false;
        continue;
      }
      if (unit == 0x5c) {
        escaped = true;
      } else if (unit == 0x22) {
        final token = source.substring(start, _index);
        final decoded = jsonDecode(token);
        if (decoded is! String) {
          throw FormatException('Invalid JSON string at offset $start.');
        }
        return decoded;
      }
    }
    throw FormatException('Unterminated JSON string at offset $start.');
  }

  void _parsePrimitive() {
    final start = _index;
    while (_index < source.length) {
      final unit = source.codeUnitAt(_index);
      if (unit == 0x2c || unit == 0x7d || unit == 0x5d || _isWhitespace(unit)) {
        break;
      }
      _index++;
    }
    if (_index == start) {
      throw FormatException('Invalid JSON value at offset $start.');
    }
  }

  void _skipWhitespace() {
    while (_index < source.length && _isWhitespace(source.codeUnitAt(_index))) {
      _index++;
    }
  }

  bool _consumeIf(int unit) {
    if (_index < source.length && source.codeUnitAt(_index) == unit) {
      _index++;
      return true;
    }
    return false;
  }

  void _expect(int unit) {
    if (!_consumeIf(unit)) {
      throw FormatException(
        'Expected ${String.fromCharCode(unit)} at offset $_index.',
      );
    }
  }

  bool _isWhitespace(int unit) =>
      unit == 0x20 || unit == 0x09 || unit == 0x0a || unit == 0x0d;
}
