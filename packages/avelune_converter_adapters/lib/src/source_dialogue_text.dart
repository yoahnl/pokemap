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

({String text, int spans, int repairedClosingTags})? sourceDialoguePlainItalicPresentation(
    String source) {
  if (!source.contains('<i>')) return null;
  final text = StringBuffer();
  var index = 0, spans = 0, repaired = 0;
  var open = false;
  while (index < source.length) {
    if (source[index] == '>') return null;
    if (source[index] != '<') {
      text.write(source[index++]);
      continue;
    }
    if (source.startsWith('<i>', index)) {
      if (open) return null;
      open = true;
      index += 3;
    } else if (source.startsWith('</i>', index) || source.startsWith(r'<\i>', index)) {
      if (!open) return null;
      if (source.startsWith(r'<\i>', index)) repaired++;
      open = false;
      spans++;
      index += 4;
    } else {
      return null;
    }
  }
  return open || spans == 0 ? null :
      (text: text.toString(), spans: spans, repairedClosingTags: repaired);
}

final _variableControl = RegExp(r'\\v\[([0-9]+)\]', caseSensitive: false);
final _speedControl = RegExp(r'\\ts\[([0-9]*)\]', caseSensitive: false);
final _autoWaitControl =
    RegExp(r'\\wtnp\[\s*([0-9]+)\s*\]$', caseSensitive: false);
final _soundControl = RegExp(r'\\se\[([^\]]*)\]', caseSensitive: false);
final _unsupportedControl = RegExp(
    r'\\(sign\[|op|cl|wt\[|wtnp|se\[|g|cn|ch\[|me\[|1)',
    caseSensitive: false);

({String name, int volume, int pitch})? _soundParameters(String parameters) {
  final fields = parameters.split(':');
  if (fields.isEmpty || fields.length > 3) return null;
  final name = fields.first;
  if (name.isEmpty ||
      name.trim() != name ||
      name == '.' ||
      name == '..' ||
      RegExp(r'[\\/:<>\x00-\x1f]').hasMatch(name)) {
    return null;
  }
  int? number(int index, int fallback) => fields.length <= index
      ? fallback
      : RegExp(r'^\s*[0-9]+\s*$').hasMatch(fields[index])
          ? int.tryParse(fields[index].trim())
          : null;
  final volume = number(1, 100), pitch = number(2, 100);
  if (volume == null ||
      volume > 100 ||
      pitch == null ||
      pitch < 50 ||
      pitch > 150) {
    return null;
  }
  return (name: name, volume: volume, pitch: pitch);
}

Set<int> sourceDialogueVariableIds(String source) {
  final ids = <int>{};
  for (var index = 0; index < source.length; index++) {
    if (source[index] != r'\') continue;
    if (source.startsWith(r'\\', index)) {
      index++;
      continue;
    }
    final sound = _soundControl.matchAsPrefix(source, index);
    if (sound != null) {
      index = sound.end - 1;
      continue;
    }
    final variable = _variableControl.matchAsPrefix(source, index);
    if (variable == null) continue;
    final id = int.tryParse(variable.group(1)!);
    if (id != null && id >= 1 && id <= 5000) ids.add(id);
    index = variable.end - 1;
  }
  return ids;
}

Iterable<String> sourceDialogueSoundNames(String source) sync* {
  for (var index = 0; index < source.length; index++) {
    if (source[index] != r'\') continue;
    if (source.startsWith(r'\\', index)) {
      index++;
      continue;
    }
    final control = _soundControl.matchAsPrefix(source, index);
    if (control == null) continue;
    final audio = _soundParameters(control.group(1)!);
    if (audio != null && audio.pitch == 100) yield audio.name;
    index = control.end - 1;
  }
}

DialogueLineFeedback? parseSourceDialogueText(
  String source, {
  bool allowPlayerName = true,
  bool allowTiming = true,
  bool allowLiteralEscapes = true,
  bool allowNativePlaceholders = false,
  String? Function(int sourceVariableId)? variablePlaceholder,
  DialogueAudioCue? Function(
          String name, int volume, int pitch, int revealOffset)?
      soundEffect,
  void Function(String reason)? onRefusal,
}) {
  DialogueLineFeedback? refuse(String reason) {
    onRefusal?.call(reason);
    return null;
  }

  if (source.length > 1048576 ||
      source.contains('\uFFFC') ||
      !allowNativePlaceholders && source.contains('{{') ||
      _formattingEntities.any(source.contains) ||
      _formattingTag.allMatches(source).any(
          (match) => _formattingTags.contains(match.group(1)!.toLowerCase()))) {
    return refuse('sourceTextControlUnsupported');
  }
  final segments = <DialogueLineSegment>[];
  var text = StringBuffer();
  DialogueSegmentStyle? style;
  int? cadence;
  var advance = const DialogueLineAdvancePolicy.confirm();
  DialogueAudioCue? audioCue;
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
    final sound = _soundControl.matchAsPrefix(source, index);
    if (sound != null) {
      if (audioCue != null) {
        return refuse('sourceTextAudioCueMultiplicityUnsupported');
      }
      final audio = _soundParameters(sound.group(1)!);
      if (audio == null) return refuse('sourceTextAudioControlMalformed');
      if (audio.pitch != 100) return refuse('sourceTextAudioPitchUnsupported');
      final offset = segments.fold<int>(
              0, (sum, segment) => sum + segment.plainText.runes.length) +
          text.toString().runes.length;
      audioCue =
          soundEffect?.call(audio.name, audio.volume, audio.pitch, offset);
      if (audioCue == null) return refuse('sourceTextAudioBindingMissing');
      if (audioCue.revealOffset != offset ||
          audioCue.role != DialogueAudioCueRole.effect ||
          audioCue.bgmInterruption != null) {
        return refuse('sourceTextAudioBindingInvalid');
      }
      index = sound.end;
      continue;
    }
    final variable = _variableControl.matchAsPrefix(source, index);
    if (variable != null) {
      final id = int.tryParse(variable.group(1)!);
      if (id == null || id < 1 || id > 5000) {
        return refuse('sourceTextVariableUnsupported');
      }
      final placeholder = variablePlaceholder?.call(id);
      if (placeholder == null) return refuse('sourceTextVariableUnsupported');
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
        return refuse('sourceTextCadencePositionUnsupported');
      }
      final value = speed.group(1)!.isEmpty ? 0 : int.tryParse(speed.group(1)!);
      if (value == null || value > 320) {
        return refuse('sourceTextControlMalformed');
      }
      cadence = value * 12500;
      index = speed.end;
      continue;
    }
    final wait = _autoWaitControl.matchAsPrefix(source, index);
    if (wait != null) {
      if (!allowTiming) return refuse('sourceTextTimingUnsupported');
      final frames = int.tryParse(wait.group(1)!);
      if (frames == null || frames > 1200) {
        return refuse('sourceTextControlMalformed');
      }
      advance = DialogueLineAdvancePolicy.autoAfterReveal(frames * 50000);
      index = wait.end;
      continue;
    }
    final unsupported = _unsupportedControl
        .matchAsPrefix(source, index)
        ?.group(1)
        ?.toLowerCase();
    final refusal = switch (unsupported) {
      'sign[' || 'op' || 'cl' => 'sourceTextWindowAnimationUnsupported',
      'wt[' => 'sourceTextMidRevealWaitUnsupported',
      'wtnp' || 'se[' => 'sourceTextControlMalformed',
      'g' => 'sourceTextGoldWindowUnsupported',
      'cn' => 'sourceTextCoinWindowUnsupported',
      'ch[' => 'sourceTextInlineChoiceUnsupported',
      'me[' => 'sourceTextMusicEffectUnsupported',
      '1' => 'sourceTextPauseControlUnsupported',
      _ => null,
    };
    if (refusal != null) return refuse(refusal);
    if (++index >= source.length) return refuse('sourceTextControlMalformed');
    switch (source[index++].toLowerCase()) {
      case 'n':
        if (index < source.length && source[index] == '[') {
          return refuse('sourceTextActorNameUnsupported');
        }
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
        return refuse('sourceTextControlUnsupported');
    }
  }
  flush();
  return DialogueLineFeedback(
      segments: segments,
      revealIntervalMicros: cadence,
      advance: advance,
      audioCue: audioCue);
}
