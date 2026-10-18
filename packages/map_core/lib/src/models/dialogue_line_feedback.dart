enum DialogueLineAdvanceKind { confirm, autoAfterReveal }

final class DialogueLineAdvancePolicy {
  const DialogueLineAdvancePolicy.confirm()
    : kind = DialogueLineAdvanceKind.confirm,
      delayMicros = 0;

  DialogueLineAdvancePolicy.autoAfterReveal(this.delayMicros)
    : kind = DialogueLineAdvanceKind.autoAfterReveal {
    if (delayMicros < 0) throw ArgumentError.value(delayMicros, 'delayMicros');
  }

  final DialogueLineAdvanceKind kind;
  final int delayMicros;

  factory DialogueLineAdvancePolicy.fromJson(Map<String, dynamic> json) {
    switch (json['kind']) {
      case 'confirm':
        _fields(json, {'kind'}, {});
        return const DialogueLineAdvancePolicy.confirm();
      case 'autoAfterReveal':
        _fields(json, {'kind', 'delayMicros'}, {});
        return DialogueLineAdvancePolicy.autoAfterReveal(
          _nonnegative(json['delayMicros']),
        );
      default:
        throw const FormatException('Unknown dialogue advancement kind.');
    }
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    if (kind == DialogueLineAdvanceKind.autoAfterReveal)
      'delayMicros': delayMicros,
  };

  @override
  bool operator ==(Object other) =>
      other is DialogueLineAdvancePolicy &&
      kind == other.kind &&
      delayMicros == other.delayMicros;

  @override
  int get hashCode => Object.hash(kind, delayMicros);
}

final class DialogueSegmentStyle {
  DialogueSegmentStyle({this.colorArgb, this.shadowColorArgb}) {
    for (final value in [colorArgb, shadowColorArgb]) {
      if (value != null && (value < 0 || value > 0xffffffff)) {
        throw ArgumentError.value(value, 'colorArgb');
      }
    }
  }

  final int? colorArgb;
  final int? shadowColorArgb;

  factory DialogueSegmentStyle.fromJson(Map<String, dynamic> json) {
    _fields(json, {}, {'colorArgb', 'shadowColorArgb'});
    int? color(String key) {
      final value = json[key];
      if (value == null && !json.containsKey(key)) return null;
      if (value is! int || value < 0 || value > 0xffffffff) {
        throw const FormatException('Dialogue color must be an ARGB integer.');
      }
      return value;
    }

    return DialogueSegmentStyle(
      colorArgb: color('colorArgb'),
      shadowColorArgb: color('shadowColorArgb'),
    );
  }

  Map<String, Object?> toJson() => {
    if (colorArgb != null) 'colorArgb': colorArgb,
    if (shadowColorArgb != null) 'shadowColorArgb': shadowColorArgb,
  };

  @override
  bool operator ==(Object other) =>
      other is DialogueSegmentStyle &&
      colorArgb == other.colorArgb &&
      shadowColorArgb == other.shadowColorArgb;

  @override
  int get hashCode => Object.hash(colorArgb, shadowColorArgb);
}

sealed class DialogueLineSegment {
  const DialogueLineSegment();

  String get plainText;
  Map<String, Object?> toJson();

  factory DialogueLineSegment.fromJson(Map<String, dynamic> json) {
    switch (json['kind']) {
      case 'text':
        _fields(json, {'kind', 'text'}, {'style'});
        return DialogueTextSegment(
          _string(json['text']),
          style: json.containsKey('style')
              ? DialogueSegmentStyle.fromJson(_object(json['style']))
              : null,
        );
      case 'icon':
        _fields(json, {'kind', 'assetId', 'widthPx', 'heightPx'}, {});
        return DialogueIconSegment(
          assetId: _string(json['assetId']),
          widthPx: _positive(json['widthPx']),
          heightPx: _positive(json['heightPx']),
        );
      default:
        throw const FormatException('Unknown dialogue segment kind.');
    }
  }
}

final class DialogueTextSegment extends DialogueLineSegment {
  DialogueTextSegment(this.text, {this.style}) {
    if (text.isEmpty || text.contains('\uFFFC')) {
      throw ArgumentError.value(text, 'text');
    }
  }

  final String text;
  final DialogueSegmentStyle? style;

  @override
  String get plainText => text;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'text',
    'text': text,
    if (style != null) 'style': style!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is DialogueTextSegment &&
      text == other.text &&
      style == other.style;

  @override
  int get hashCode => Object.hash(text, style);
}

final class DialogueIconSegment extends DialogueLineSegment {
  DialogueIconSegment({
    required this.assetId,
    required this.widthPx,
    required this.heightPx,
  }) {
    _id(assetId);
    if (widthPx <= 0 || heightPx <= 0 || widthPx > 256 || heightPx > 256) {
      throw ArgumentError('Dialogue icon dimensions must be in 1..256.');
    }
  }

  final String assetId;
  final int widthPx;
  final int heightPx;

  @override
  String get plainText => '\uFFFC';

  @override
  Map<String, Object?> toJson() => {
    'kind': 'icon',
    'assetId': assetId,
    'widthPx': widthPx,
    'heightPx': heightPx,
  };

  @override
  bool operator ==(Object other) =>
      other is DialogueIconSegment &&
      assetId == other.assetId &&
      widthPx == other.widthPx &&
      heightPx == other.heightPx;

  @override
  int get hashCode => Object.hash(assetId, widthPx, heightPx);
}

enum DialogueAudioCueRole { effect, musicEffect }

final class DialogueBgmInterruption {
  DialogueBgmInterruption({required this.fadeOutMs, required this.fadeInMs}) {
    for (final entry in {
      'fadeOutMs': fadeOutMs,
      'fadeInMs': fadeInMs,
    }.entries) {
      if (entry.value < 0 || entry.value > 60000) {
        throw ArgumentError.value(entry.value, entry.key);
      }
    }
  }

  final int fadeOutMs;
  final int fadeInMs;

  factory DialogueBgmInterruption.fromJson(Map<String, dynamic> json) {
    _fields(json, {'fadeOutMs', 'fadeInMs'}, {});
    int duration(String field) {
      final value = json[field];
      if (value is! int || value < 0 || value > 60000) {
        throw FormatException('$field must be an integer in 0..60000.');
      }
      return value;
    }

    return DialogueBgmInterruption(
      fadeOutMs: duration('fadeOutMs'),
      fadeInMs: duration('fadeInMs'),
    );
  }

  Map<String, Object?> toJson() => {
    'fadeOutMs': fadeOutMs,
    'fadeInMs': fadeInMs,
  };

  @override
  bool operator ==(Object other) =>
      other is DialogueBgmInterruption &&
      fadeOutMs == other.fadeOutMs &&
      fadeInMs == other.fadeInMs;

  @override
  int get hashCode => Object.hash(fadeOutMs, fadeInMs);
}

final class DialogueAudioCue {
  DialogueAudioCue({
    required this.mediaAssetId,
    required this.cueId,
    this.volume = 1.0,
    this.role = DialogueAudioCueRole.effect,
    this.bgmInterruption,
  }) {
    _id(mediaAssetId);
    _id(cueId);
    if (!volume.isFinite || volume < 0 || volume > 1) {
      throw ArgumentError.value(volume, 'volume');
    }
    if (bgmInterruption != null && role != DialogueAudioCueRole.musicEffect) {
      throw ArgumentError('BGM interruption requires a music effect cue.');
    }
  }

  final String mediaAssetId;
  final String cueId;
  final double volume;
  final DialogueAudioCueRole role;
  final DialogueBgmInterruption? bgmInterruption;

  factory DialogueAudioCue.fromJson(Map<String, dynamic> json) {
    _fields(
      json,
      {'mediaAssetId', 'cueId'},
      {'volume', 'role', 'bgmInterruption'},
    );
    final volume = json.containsKey('volume') ? json['volume'] : 1.0;
    if (volume is! num || !volume.isFinite || volume < 0 || volume > 1) {
      throw const FormatException(
        'Dialogue cue volume must be finite in 0..1.',
      );
    }
    final role = json.containsKey('role')
        ? switch (json['role']) {
            'effect' => DialogueAudioCueRole.effect,
            'musicEffect' => DialogueAudioCueRole.musicEffect,
            _ => throw const FormatException(
              'Unknown dialogue audio cue role.',
            ),
          }
        : DialogueAudioCueRole.effect;
    try {
      return DialogueAudioCue(
        mediaAssetId: _string(json['mediaAssetId']),
        cueId: _string(json['cueId']),
        volume: volume.toDouble(),
        role: role,
        bgmInterruption: json.containsKey('bgmInterruption')
            ? DialogueBgmInterruption.fromJson(_object(json['bgmInterruption']))
            : null,
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  Map<String, Object?> toJson() => {
    'mediaAssetId': mediaAssetId,
    'cueId': cueId,
    if (volume != 1.0) 'volume': volume,
    if (role != DialogueAudioCueRole.effect) 'role': role.name,
    if (bgmInterruption != null) 'bgmInterruption': bgmInterruption!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is DialogueAudioCue &&
      mediaAssetId == other.mediaAssetId &&
      cueId == other.cueId &&
      volume == other.volume &&
      role == other.role &&
      bgmInterruption == other.bgmInterruption;

  @override
  int get hashCode =>
      Object.hash(mediaAssetId, cueId, volume, role, bgmInterruption);
}

final class DialogueLineFeedback {
  DialogueLineFeedback({
    List<DialogueLineSegment> segments = const [],
    this.revealIntervalMicros,
    this.advance = const DialogueLineAdvancePolicy.confirm(),
    this.audioCue,
  }) : segments = List.unmodifiable(segments) {
    if (revealIntervalMicros != null && revealIntervalMicros! < 0) {
      throw ArgumentError.value(revealIntervalMicros, 'revealIntervalMicros');
    }
  }

  final List<DialogueLineSegment> segments;
  final int? revealIntervalMicros;
  final DialogueLineAdvancePolicy advance;
  final DialogueAudioCue? audioCue;

  String get plainText => segments.map((segment) => segment.plainText).join();

  void validateText(String text) {
    if (segments.isNotEmpty && plainText != text) {
      throw const FormatException(
        'Dialogue segments must reproduce the line text exactly.',
      );
    }
  }

  DialogueLineFeedback mapText(String Function(String) transform) =>
      DialogueLineFeedback(
        segments: segments
            .expand<DialogueLineSegment>((segment) {
              if (segment is DialogueIconSegment) return [segment];
              final text = segment as DialogueTextSegment;
              final mapped = transform(text.text);
              return mapped.isEmpty ? const [] : [DialogueTextSegment(mapped, style: text.style)];
            })
            .toList(growable: false),
        revealIntervalMicros: revealIntervalMicros,
        advance: advance,
        audioCue: audioCue,
      );

  factory DialogueLineFeedback.fromJson(Map<String, dynamic> json) {
    _fields(
      json,
      {'segments', 'advance'},
      {'revealIntervalMicros', 'audioCue'},
    );
    final segments = json['segments'];
    if (segments is! List) {
      throw const FormatException('Dialogue segments must be a list.');
    }
    try {
      return DialogueLineFeedback(
        segments: segments
            .map((value) => DialogueLineSegment.fromJson(_object(value)))
            .toList(growable: false),
        revealIntervalMicros: json.containsKey('revealIntervalMicros')
            ? _nonnegative(json['revealIntervalMicros'])
            : null,
        advance: DialogueLineAdvancePolicy.fromJson(_object(json['advance'])),
        audioCue: json.containsKey('audioCue')
            ? DialogueAudioCue.fromJson(_object(json['audioCue']))
            : null,
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  Map<String, Object?> toJson() => {
    'segments': segments
        .map((segment) => segment.toJson())
        .toList(growable: false),
    if (revealIntervalMicros != null)
      'revealIntervalMicros': revealIntervalMicros,
    'advance': advance.toJson(),
    if (audioCue != null) 'audioCue': audioCue!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is DialogueLineFeedback &&
      _listEquals(segments, other.segments) &&
      revealIntervalMicros == other.revealIntervalMicros &&
      advance == other.advance &&
      audioCue == other.audioCue;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(segments),
    revealIntervalMicros,
    advance,
    audioCue,
  );
}

final class SceneDialogueLinePolicy {
  SceneDialogueLinePolicy({
    required this.nodeName,
    required this.lineIndex,
    required this.feedback,
  }) {
    _id(nodeName);
    if (lineIndex < 0) throw ArgumentError.value(lineIndex, 'lineIndex');
  }

  final String nodeName;
  final int lineIndex;
  final DialogueLineFeedback feedback;

  factory SceneDialogueLinePolicy.fromJson(Map<String, dynamic> json) {
    _fields(json, {'nodeName', 'lineIndex', 'feedback'}, {});
    try {
      return SceneDialogueLinePolicy(
        nodeName: _string(json['nodeName']),
        lineIndex: _nonnegative(json['lineIndex']),
        feedback: DialogueLineFeedback.fromJson(_object(json['feedback'])),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  Map<String, Object?> toJson() => {
    'nodeName': nodeName,
    'lineIndex': lineIndex,
    'feedback': feedback.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is SceneDialogueLinePolicy &&
      nodeName == other.nodeName &&
      lineIndex == other.lineIndex &&
      feedback == other.feedback;

  @override
  int get hashCode => Object.hash(nodeName, lineIndex, feedback);
}

void _id(String value) {
  if (value.isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, 'reference');
  }
}

void _fields(
  Map<String, dynamic> json,
  Set<String> required,
  Set<String> optional,
) {
  if (!json.keys.toSet().containsAll(required) ||
      json.keys.any(
        (key) => !required.contains(key) && !optional.contains(key),
      )) {
    throw const FormatException('Invalid dialogue feedback fields.');
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected feedback object.');
  }
  return Map<String, dynamic>.from(value);
}

String _string(Object? value) {
  if (value is! String) {
    throw const FormatException('Expected feedback string.');
  }
  return value;
}

int _nonnegative(Object? value) {
  if (value is! int || value < 0) {
    throw const FormatException('Expected nonnegative feedback integer.');
  }
  return value;
}

int _positive(Object? value) {
  final result = _nonnegative(value);
  if (result == 0) {
    throw const FormatException('Expected positive feedback integer.');
  }
  return result;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

List<DialogueLineSegment> visibleDialogueLineSegments(
  List<DialogueLineSegment> segments,
  int runeCount,
) {
  if (runeCount < 0) throw ArgumentError.value(runeCount, 'runeCount');
  final result = <DialogueLineSegment>[];
  var remaining = runeCount;
  for (final segment in segments) {
    if (remaining == 0) break;
    final length = segment.plainText.runes.length;
    if (length <= remaining) {
      result.add(segment);
      remaining -= length;
    } else if (segment is DialogueTextSegment) {
      result.add(
        DialogueTextSegment(
          String.fromCharCodes(segment.text.runes.take(remaining)),
          style: segment.style,
        ),
      );
      break;
    }
  }
  return List.unmodifiable(result);
}
