import 'dart:convert';

Object? decodeBoundedBattleJson(
  List<int> bytes, {
  required int maxDepth,
  required String label,
  int? integerNumbersOnlyForSchemaVersion,
}) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xef &&
      bytes[1] == 0xbb &&
      bytes[2] == 0xbf) {
    throw FormatException('$label JSON has a byte order mark');
  }
  final text = utf8.decode(bytes);
  final objects = <Set<String>?>[];
  var expectsKey = false;
  var hasNonIntegerNumber = false;
  for (var index = 0; index < text.length; index++) {
    final character = text.codeUnitAt(index);
    if (character == 0x22) {
      final start = index;
      var escaped = false;
      while (++index < text.length) {
        final next = text.codeUnitAt(index);
        if (escaped) {
          escaped = false;
        } else if (next == 0x5c) {
          escaped = true;
        } else if (next == 0x22) {
          break;
        }
      }
      if (index >= text.length) {
        throw FormatException('$label JSON has an unterminated string');
      }
      if (objects.isNotEmpty && objects.last != null && expectsKey) {
        final key = jsonDecode(text.substring(start, index + 1)) as String;
        if (!objects.last!.add(key)) {
          throw FormatException('$label JSON has duplicate keys');
        }
        expectsKey = false;
      }
    } else if (character == 0x7b || character == 0x5b) {
      objects.add(character == 0x7b ? <String>{} : null);
      if (objects.length > maxDepth) {
        throw FormatException('$label JSON too deep');
      }
      expectsKey = character == 0x7b;
    } else if (character == 0x7d || character == 0x5d) {
      if (objects.isNotEmpty) objects.removeLast();
      expectsKey = false;
    } else if (character == 0x2c && objects.isNotEmpty) {
      expectsKey = objects.last != null;
    } else if (integerNumbersOnlyForSchemaVersion != null &&
        (character == 0x2d || (character >= 0x30 && character <= 0x39))) {
      var end = index + 1;
      while (end < text.length) {
        final next = text.codeUnitAt(end);
        if (next == 0x20 ||
            next == 0x09 ||
            next == 0x0a ||
            next == 0x0d ||
            next == 0x2c ||
            next == 0x5d ||
            next == 0x7d) {
          break;
        }
        if (next == 0x2e || next == 0x65 || next == 0x45) {
          hasNonIntegerNumber = true;
        }
        end++;
      }
      index = end - 1;
    }
  }
  final value = jsonDecode(text);
  if (integerNumbersOnlyForSchemaVersion != null &&
      value is Map &&
      value['schemaVersion'] == integerNumbersOnlyForSchemaVersion &&
      hasNonIntegerNumber) {
    throw FormatException('$label JSON requires integer number tokens');
  }
  return value;
}
