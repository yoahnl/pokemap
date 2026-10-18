import 'package:map_core/map_core.dart';

final _formattingTag =
    RegExp(r'</?([a-z0-9]+)(?:\s*=\s*[^>]*)?>', caseSensitive: false);
const _formattingTags = {
  'b',
  'i',
  'u',
  's',
  'al',
  'r',
  'ar',
  'ac',
  'br',
  'c',
  'c2',
  'c3',
  'o',
  'outln',
  'outln2',
  'fn',
  'fs',
  'icon',
  'img',
  'pg',
  'pog'
};
const _formattingEntities = {
  '&lt;',
  '&gt;',
  '&apos;',
  '&quot;',
  '&amp;',
  '&m;',
  '&f;'
};
final _variableControl = RegExp(r'\\v\[([0-9]+)\]', caseSensitive: false);
final _speedControl = RegExp(r'\\ts\[([0-9]*)\]', caseSensitive: false);
final _autoWaitControl =
    RegExp(r'\\wtnp\[\s*([0-9]+)\s*\]$', caseSensitive: false);

Set<int> sourceDialogueVariableIds(String source) {
  final ids = <int>{};
  parseSourceDialogueText(source, variablePlaceholder: (id) {
    ids.add(id);
    return '{{ variable$id }}';
  });
  return ids;
}

DialogueLineFeedback? parseSourceDialogueText(
  String source, {
  bool allowPlayerName = true,
  bool allowTiming = true,
  bool allowLiteralEscapes = true,
  bool allowNativePlaceholders = false,
  String? Function(int sourceVariableId)? variablePlaceholder,
}) {
  if (source.length > 1048576 ||
      source.contains('\uFFFC') ||
      !allowNativePlaceholders && source.contains('{{') ||
      _formattingEntities.any(source.contains) ||
      _formattingTag.allMatches(source).any(
          (match) => _formattingTags.contains(match.group(1)!.toLowerCase()))) {
    return null;
  }
  final segments = <DialogueLineSegment>[];
  var text = StringBuffer();
  DialogueSegmentStyle? style;
  int? cadence;
  var advance = const DialogueLineAdvancePolicy.confirm();
  void flush() {
    if (text.isEmpty) return;
    segments.add(DialogueTextSegment(text.toString(), style: style));
    text = StringBuffer();
  }

  for (var index = 0; index < source.length;) {
    if (source[index] != r'\') {
      text.write(source[index++]);
      continue;
    }
    if (allowLiteralEscapes && source.startsWith(r'\\', index)) {
      text.write(r'\');
      index += 2;
      continue;
    }
    if (allowPlayerName &&
        index + 3 <= source.length &&
        source.substring(index, index + 3).toLowerCase() == r'\pn') {
      text.write('{{ player_name }}');
      index += 3;
      continue;
    }
    final variable = _variableControl.matchAsPrefix(source, index);
    if (variable != null) {
      final id = int.tryParse(variable.group(1)!);
      if (id == null || id < 1 || id > 5000) return null;
      final placeholder = variablePlaceholder?.call(id);
      if (placeholder == null) return null;
      text.write(placeholder);
      index = variable.end;
      continue;
    }
    final speed = _speedControl.matchAsPrefix(source, index);
    if (speed != null) {
      if (!allowTiming ||
          text.isNotEmpty ||
          segments.isNotEmpty ||
          cadence != null) {
        return null;
      }
      final value = speed.group(1)!.isEmpty ? 0 : int.tryParse(speed.group(1)!);
      if (value == null || value > 320) return null;
      cadence = value * 12500;
      index = speed.end;
      continue;
    }
    final wait = _autoWaitControl.matchAsPrefix(source, index);
    if (wait != null) {
      if (!allowTiming) return null;
      final frames = int.tryParse(wait.group(1)!);
      if (frames == null || frames > 1200) return null;
      advance = DialogueLineAdvancePolicy.autoAfterReveal(frames * 50000);
      index = wait.end;
      continue;
    }
    if (++index >= source.length) return null;
    switch (source[index++].toLowerCase()) {
      case 'n':
        if (index < source.length && source[index] == '[') return null;
        text.write('\n');
      case 'b':
      case 'r':
        flush();
        style = DialogueSegmentStyle(
            colorArgb: source[index - 1].toLowerCase() == 'b'
                ? 0xff3050c8
                : 0xffe00808,
            shadowColorArgb: 0xffd0d0c8);
      default:
        return null;
    }
  }
  flush();
  return DialogueLineFeedback(
      segments: segments, revealIntervalMicros: cadence, advance: advance);
}
