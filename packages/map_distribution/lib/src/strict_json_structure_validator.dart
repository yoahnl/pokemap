import 'dart:convert';

import 'game_package_format_exception.dart';

/// Rejects ambiguous or pathologically complex JSON before `jsonDecode`.
final class StrictJsonStructureValidator {
  const StrictJsonStructureValidator();

  void validate(
    String source, {
    required String path,
    required int maxDepth,
    required int maxNodes,
    String duplicateCode = 'executableContent',
  }) {
    try {
      _JsonStructureParser(
        source,
        maxDepth: maxDepth,
        maxNodes: maxNodes,
      ).parse();
    } on _DuplicateJsonKey {
      throw GamePackageFormatException(
        code: duplicateCode,
        path: path,
        message: 'JSON object contains a duplicate key.',
      );
    } on _JsonComplexityExceeded catch (error) {
      throw GamePackageFormatException(
        code: 'entryTooLarge',
        path: path,
        message: error.message,
      );
    } on FormatException {
      throw GamePackageFormatException(
        code: 'executableContent',
        path: path,
        message: 'Malformed JSON payload.',
      );
    }
  }
}

final class _JsonStructureParser {
  _JsonStructureParser(
    this.source, {
    required this.maxDepth,
    required this.maxNodes,
  });

  final String source;
  final int maxDepth;
  final int maxNodes;

  int _offset = 0;
  int _nodes = 0;

  void parse() {
    _skipWhitespace();
    _parseValue(0);
    _skipWhitespace();
    if (_offset != source.length) {
      throw const FormatException('Trailing JSON content.');
    }
  }

  void _parseValue(int depth) {
    _nodes++;
    if (_nodes > maxNodes) {
      throw const _JsonComplexityExceeded(
        'JSON node count exceeds policy.',
      );
    }
    if (_offset >= source.length) {
      throw const FormatException('Missing JSON value.');
    }
    switch (source.codeUnitAt(_offset)) {
      case 0x7b:
        _parseObject(depth + 1);
      case 0x5b:
        _parseArray(depth + 1);
      case 0x22:
        _parseString();
      case 0x74:
        _parseLiteral('true');
      case 0x66:
        _parseLiteral('false');
      case 0x6e:
        _parseLiteral('null');
      default:
        _parseNumber();
    }
  }

  void _parseObject(int depth) {
    _checkDepth(depth);
    _offset++;
    _skipWhitespace();
    if (_consume(0x7d)) return;
    final keys = <String>{};
    while (true) {
      if (_offset >= source.length || source.codeUnitAt(_offset) != 0x22) {
        throw const FormatException('JSON object key must be a string.');
      }
      final key = _parseString();
      if (!keys.add(key)) throw _DuplicateJsonKey(key);
      _skipWhitespace();
      _expect(0x3a);
      _skipWhitespace();
      _parseValue(depth);
      _skipWhitespace();
      if (_consume(0x7d)) return;
      _expect(0x2c);
      _skipWhitespace();
    }
  }

  void _parseArray(int depth) {
    _checkDepth(depth);
    _offset++;
    _skipWhitespace();
    if (_consume(0x5d)) return;
    while (true) {
      _parseValue(depth);
      _skipWhitespace();
      if (_consume(0x5d)) return;
      _expect(0x2c);
      _skipWhitespace();
    }
  }

  String _parseString() {
    final start = _offset;
    _offset++;
    while (_offset < source.length) {
      final codeUnit = source.codeUnitAt(_offset++);
      if (codeUnit == 0x22) {
        return jsonDecode(source.substring(start, _offset)) as String;
      }
      if (codeUnit < 0x20) {
        throw const FormatException('Control character in JSON string.');
      }
      if (codeUnit != 0x5c) continue;
      if (_offset >= source.length) {
        throw const FormatException('Incomplete JSON escape.');
      }
      final escape = source.codeUnitAt(_offset++);
      if (escape == 0x75) {
        if (_offset + 4 > source.length) {
          throw const FormatException('Incomplete Unicode escape.');
        }
        for (var index = 0; index < 4; index++) {
          if (!_isHex(source.codeUnitAt(_offset + index))) {
            throw const FormatException('Invalid Unicode escape.');
          }
        }
        _offset += 4;
      } else if (!_simpleEscapes.contains(escape)) {
        throw const FormatException('Invalid JSON escape.');
      }
    }
    throw const FormatException('Unterminated JSON string.');
  }

  void _parseLiteral(String literal) {
    if (!_startsWith(literal)) {
      throw const FormatException('Invalid JSON literal.');
    }
    _offset += literal.length;
  }

  void _parseNumber() {
    if (_consume(0x2d) && _offset >= source.length) {
      throw const FormatException('Invalid JSON number.');
    }
    if (_consume(0x30)) {
      if (_offset < source.length && _isDigit(source.codeUnitAt(_offset))) {
        throw const FormatException('Leading zero in JSON number.');
      }
    } else {
      _consumeDigits(requireOne: true);
    }
    if (_consume(0x2e)) {
      _consumeDigits(requireOne: true);
    }
    if (_offset < source.length) {
      final codeUnit = source.codeUnitAt(_offset);
      if (codeUnit == 0x65 || codeUnit == 0x45) {
        _offset++;
        if (_offset < source.length) {
          final sign = source.codeUnitAt(_offset);
          if (sign == 0x2b || sign == 0x2d) _offset++;
        }
        _consumeDigits(requireOne: true);
      }
    }
  }

  void _consumeDigits({required bool requireOne}) {
    final start = _offset;
    while (_offset < source.length && _isDigit(source.codeUnitAt(_offset))) {
      _offset++;
    }
    if (requireOne && _offset == start) {
      throw const FormatException('Missing JSON number digit.');
    }
  }

  void _checkDepth(int depth) {
    if (depth > maxDepth) {
      throw const _JsonComplexityExceeded(
        'JSON nesting depth exceeds policy.',
      );
    }
  }

  void _skipWhitespace() {
    while (_offset < source.length) {
      final codeUnit = source.codeUnitAt(_offset);
      if (codeUnit != 0x20 &&
          codeUnit != 0x09 &&
          codeUnit != 0x0a &&
          codeUnit != 0x0d) {
        return;
      }
      _offset++;
    }
  }

  void _expect(int codeUnit) {
    if (!_consume(codeUnit)) {
      throw const FormatException('Unexpected JSON token.');
    }
  }

  bool _consume(int codeUnit) {
    if (_offset >= source.length || source.codeUnitAt(_offset) != codeUnit) {
      return false;
    }
    _offset++;
    return true;
  }

  bool _startsWith(String value) =>
      _offset + value.length <= source.length &&
      source.startsWith(value, _offset);

  static bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

  static bool _isHex(int codeUnit) =>
      _isDigit(codeUnit) ||
      (codeUnit >= 0x41 && codeUnit <= 0x46) ||
      (codeUnit >= 0x61 && codeUnit <= 0x66);

  static const Set<int> _simpleEscapes = <int>{
    0x22,
    0x2f,
    0x5c,
    0x62,
    0x66,
    0x6e,
    0x72,
    0x74,
  };
}

final class _DuplicateJsonKey implements Exception {
  const _DuplicateJsonKey(this.key);

  final String key;
}

final class _JsonComplexityExceeded implements Exception {
  const _JsonComplexityExceeded(this.message);

  final String message;
}
