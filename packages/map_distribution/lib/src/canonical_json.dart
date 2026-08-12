import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

final class CanonicalJsonException extends FormatException {
  const CanonicalJsonException(super.message);
}

/// Canonical JSON encoder for PokeMap persisted contracts.
///
/// Numeric values use Dart's shortest deterministic JSON representation.
abstract final class CanonicalJson {
  static const int maxSafeInteger = 9007199254740991;

  static String encode(Object? value) {
    final output = StringBuffer();
    _write(value, output);
    return output.toString();
  }

  static Uint8List encodeUtf8(Object? value) =>
      Uint8List.fromList(utf8.encode(encode(value)));

  static String sha256Hex(Object? value) =>
      sha256.convert(encodeUtf8(value)).toString();

  static void _write(Object? value, StringBuffer output) {
    switch (value) {
      case null:
        output.write('null');
      case bool():
        output.write(value ? 'true' : 'false');
      case int():
        if (value < -maxSafeInteger || value > maxSafeInteger) {
          throw const CanonicalJsonException(
            'Integers must be exactly representable by an IEEE-754 double.',
          );
        }
        output.write(value);
      case double():
        if (!value.isFinite) {
          throw const CanonicalJsonException(
            'Non-finite numbers are not valid JSON.',
          );
        }
        if (value == 0) {
          output.write('0');
        } else if (value == value.truncateToDouble() &&
            value.abs() <= maxSafeInteger) {
          output.write(value.toInt());
        } else {
          output.write(jsonEncode(value));
        }
      case String():
        _validateUnicodeScalarSequence(value);
        output.write(jsonEncode(value));
      case List<Object?>():
        output.write('[');
        for (var index = 0; index < value.length; index++) {
          if (index > 0) output.write(',');
          _write(value[index], output);
        }
        output.write(']');
      case Map():
        final entries = <MapEntry<String, Object?>>[];
        for (final entry in value.entries) {
          final key = entry.key;
          if (key is! String) {
            throw const CanonicalJsonException(
              'Canonical JSON object keys must be strings.',
            );
          }
          _validateUnicodeScalarSequence(key);
          entries.add(MapEntry<String, Object?>(key, entry.value));
        }
        entries.sort(
          (left, right) => _compareUtf16(left.key, right.key),
        );
        output.write('{');
        for (var index = 0; index < entries.length; index++) {
          if (index > 0) output.write(',');
          output
            ..write(jsonEncode(entries[index].key))
            ..write(':');
          _write(entries[index].value, output);
        }
        output.write('}');
      default:
        throw CanonicalJsonException(
          'Unsupported canonical JSON value: ${value.runtimeType}.',
        );
    }
  }

  static int _compareUtf16(String left, String right) {
    final leftUnits = left.codeUnits;
    final rightUnits = right.codeUnits;
    final sharedLength = leftUnits.length < rightUnits.length
        ? leftUnits.length
        : rightUnits.length;
    for (var index = 0; index < sharedLength; index++) {
      final comparison = leftUnits[index].compareTo(rightUnits[index]);
      if (comparison != 0) return comparison;
    }
    return leftUnits.length.compareTo(rightUnits.length);
  }

  static void _validateUnicodeScalarSequence(String value) {
    final units = value.codeUnits;
    for (var index = 0; index < units.length; index++) {
      final unit = units[index];
      if (unit >= 0xd800 && unit <= 0xdbff) {
        if (index + 1 >= units.length ||
            units[index + 1] < 0xdc00 ||
            units[index + 1] > 0xdfff) {
          throw const CanonicalJsonException(
            'Strings must contain valid Unicode scalar values.',
          );
        }
        index++;
      } else if (unit >= 0xdc00 && unit <= 0xdfff) {
        throw const CanonicalJsonException(
          'Strings must contain valid Unicode scalar values.',
        );
      }
    }
  }
}
