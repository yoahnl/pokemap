import 'dart:convert';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'game_package_format_exception.dart';
import 'unicode_case_folding.dart';

/// Shared lexical policy for paths stored in a `.pokemapgame` package.
abstract final class PackagePathPolicy {
  static const int maxUtf8Bytes = 512;
  static const int maxSegmentUtf8Bytes = 255;
  static const int maxDepth = 32;

  static void validate(String value, {required String errorPath}) {
    final bytes = utf8.encode(value);
    final segments = value.split('/');
    final hasInvalidUnicode = _hasInvalidUnicodeScalar(value);
    final hasInvalidSegment = segments.any(
      (segment) =>
          segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          utf8.encode(segment).length > maxSegmentUtf8Bytes ||
          segment.endsWith('.') ||
          segment.endsWith(' ') ||
          _windowsCharacters.hasMatch(segment) ||
          _isWindowsReserved(segment),
    );
    if (value != unorm.nfc(value) ||
        hasInvalidUnicode ||
        bytes.length > maxUtf8Bytes ||
        segments.length > maxDepth ||
        value.startsWith('/') ||
        value.contains('\\') ||
        value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f) ||
        !_allowedRoot.hasMatch(value) ||
        hasInvalidSegment) {
      throw GamePackageFormatException(
        code: 'invalidPackagePath',
        path: errorPath,
        message: 'Invalid normalized package-relative path.',
      );
    }
  }

  /// Conservative cross-platform collision key.
  static String collisionKey(String value) =>
      unorm.nfc(UnicodeCaseFolding.fold(unorm.nfc(value)));

  static int compareUtf8(String left, String right) {
    final leftBytes = utf8.encode(left);
    final rightBytes = utf8.encode(right);
    final shared = leftBytes.length < rightBytes.length
        ? leftBytes.length
        : rightBytes.length;
    for (var index = 0; index < shared; index++) {
      final comparison = leftBytes[index].compareTo(rightBytes[index]);
      if (comparison != 0) return comparison;
    }
    return leftBytes.length.compareTo(rightBytes.length);
  }

  static bool _isWindowsReserved(String segment) {
    final base = segment.split('.').first.toUpperCase();
    return _windowsReserved.hasMatch(base);
  }

  static bool _hasInvalidUnicodeScalar(String value) {
    final units = value.codeUnits;
    for (var index = 0; index < units.length; index++) {
      final unit = units[index];
      if (unit >= 0xd800 && unit <= 0xdbff) {
        if (index + 1 >= units.length ||
            units[index + 1] < 0xdc00 ||
            units[index + 1] > 0xdfff) {
          return true;
        }
        index++;
      } else if (unit >= 0xdc00 && unit <= 0xdfff) {
        return true;
      }
    }
    return false;
  }

  static final RegExp _allowedRoot =
      RegExp(r'^(?:project|presentation|legal)/.+$');
  static final RegExp _windowsCharacters = RegExp(r'''[<>:"|?*]''');
  static final RegExp _windowsReserved =
      RegExp(r'^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$');
}
