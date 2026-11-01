import 'dart:convert';

Object? decodeBoundedBattleJson(
  List<int> bytes, {
  required int maxDepth,
  required String label,
}) {
  final text = utf8.decode(bytes);
  var depth = 0;
  var quoted = false;
  var escaped = false;
  for (final character in text.codeUnits) {
    if (quoted) {
      if (escaped) {
        escaped = false;
      } else if (character == 0x5c) {
        escaped = true;
      } else if (character == 0x22) {
        quoted = false;
      }
    } else if (character == 0x22) {
      quoted = true;
    } else if (character == 0x7b || character == 0x5b) {
      if (++depth > maxDepth) {
        throw FormatException('$label JSON too deep');
      }
    } else if (character == 0x7d || character == 0x5d) {
      depth--;
    }
  }
  return jsonDecode(text);
}
