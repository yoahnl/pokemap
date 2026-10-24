import 'dart:convert';

bool sourceEngineGameIniIsLocal(List<int> bytes) {
  if (bytes.isEmpty || bytes.length > 4096 || bytes.contains(0)) return false;
  final lines = const LineSplitter().convert(latin1.decode(bytes));
  final values = <String, String>{};
  var gameSection = false;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line == '[Game]') {
      if (gameSection || values.isNotEmpty) return false;
      gameSection = true;
      continue;
    }
    final equals = line.indexOf('=');
    if (!gameSection || equals < 1) return false;
    final key = line.substring(0, equals).trim();
    final value = line.substring(equals + 1).trim();
    if (!const {'Library', 'Scripts', 'Title', 'RTP1', 'RTP2', 'RTP3'}
            .contains(key) ||
        values.containsKey(key)) {
      return false;
    }
    values[key] = value;
  }
  final title = values['Title'];
  return values.length == 6 && values['Library'] == 'RGSS104E.dll' &&
      values['Scripts']?.replaceAll(r'\', '/') == 'Data/Scripts.rxdata' &&
      title != null && title.isNotEmpty && title.length <= 256 &&
      !title.codeUnits.any((unit) => unit < 32 || unit == 127) &&
      const ['RTP1', 'RTP2', 'RTP3'].every((key) => values[key] == '');
}
