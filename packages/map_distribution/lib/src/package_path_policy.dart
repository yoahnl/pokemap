import 'dart:convert';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'game_package_format_exception.dart';
import 'unicode_case_folding.dart';

/// Shared lexical policy for paths stored in a `.avelunegame` package.
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
          _utf8Length(segment) > maxSegmentUtf8Bytes ||
          segment.endsWith('.') ||
          segment.endsWith(' ') ||
          _hasWindowsCharacter(segment) ||
          _isWindowsReserved(segment),
    );
    if (value != normalizeNfc(value) ||
        hasInvalidUnicode ||
        bytes.length > maxUtf8Bytes ||
        segments.length > maxDepth ||
        value.startsWith('/') ||
        value.contains('\\') ||
        value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f) ||
        !_hasAllowedRoot(value) ||
        hasInvalidSegment) {
      throw GamePackageFormatException(
        code: 'invalidPackagePath',
        path: errorPath,
        message: 'Invalid normalized package-relative path.',
      );
    }
  }

  /// Conservative cross-platform collision key.
  static String collisionKey(String value) => _isAscii(value)
      ? value.toLowerCase()
      : unorm.nfc(UnicodeCaseFolding.fold(unorm.nfc(value)));

  /// Returns the NFC representation required for package-relative paths.
  static String normalizeNfc(String value) =>
      _isAscii(value) ? value : unorm.nfc(value);

  static int compareUtf8(String left, String right) {
    final commonUnits =
        left.length < right.length ? left.length : right.length;
    var prefix = 0;
    while (prefix < commonUnits &&
        left.codeUnitAt(prefix) == right.codeUnitAt(prefix)) {
      prefix++;
    }
    if (prefix == 0 || !_isHighSurrogate(left.codeUnitAt(prefix - 1))) {
      if (prefix == commonUnits) return left.length.compareTo(right.length);
      final leftUnit = left.codeUnitAt(prefix);
      final rightUnit = right.codeUnitAt(prefix);
      if (!_isSurrogate(leftUnit) && !_isSurrogate(rightUnit)) {
        return leftUnit.compareTo(rightUnit);
      }
    }
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

  static bool _isAscii(String value) {
    for (var index = 0; index < value.length; index++) {
      if (value.codeUnitAt(index) > 0x7f) return false;
    }
    return true;
  }

  static bool _isWindowsReserved(String segment) {
    final dot = segment.indexOf('.');
    final base = (dot < 0 ? segment : segment.substring(0, dot)).toUpperCase();
    return _windowsReserved.contains(base);
  }

  static bool _hasWindowsCharacter(String segment) {
    for (var index = 0; index < segment.length; index++) {
      switch (segment.codeUnitAt(index)) {
        case 0x3c || 0x3e || 0x3a || 0x22 || 0x7c || 0x3f || 0x2a:
          return true;
      }
    }
    return false;
  }

  static bool _isSurrogate(int unit) => unit & 0xf800 == 0xd800;

  static bool _isHighSurrogate(int unit) => unit & 0xfc00 == 0xd800;

  static bool _hasAllowedRoot(String value) {
    final slash = value.indexOf('/');
    if (slash < 0 || slash == value.length - 1) return false;
    final root = value.substring(0, slash);
    if (root != 'project' && root != 'presentation' && root != 'legal') {
      return false;
    }
    for (var index = slash + 1; index < value.length; index++) {
      switch (value.codeUnitAt(index)) {
        case 0x0a || 0x0d || 0x2028 || 0x2029:
          return false;
      }
    }
    return true;
  }

  static int _utf8Length(String value) {
    var length = 0;
    for (var index = 0; index < value.length; index++) {
      final unit = value.codeUnitAt(index);
      if (unit < 0x80) {
        length += 1;
      } else if (unit < 0x800) {
        length += 2;
      } else if (unit >= 0xd800 &&
          unit <= 0xdbff &&
          index + 1 < value.length &&
          value.codeUnitAt(index + 1) & 0xfc00 == 0xdc00) {
        length += 4;
        index++;
      } else {
        length += 3;
      }
    }
    return length;
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

  static final Set<String> _windowsReserved = <String>{
    'CON',
    'PRN',
    'AUX',
    'NUL',
    for (var digit = 1; digit <= 9; digit++) ...['COM$digit', 'LPT$digit'],
  };
}
