import 'package:meta/meta.dart' show immutable;

enum SceneWarpPresentationMode { fade, illustrated, caveEntrance, caveExit }

@immutable
final class SceneWarpPresentation {
  SceneWarpPresentation({
    required this.mode,
    this.illustrationElementId,
    this.fadeOutMs = 300,
    this.transferDelayMs = 400,
    this.revealMs = 300,
    int? illustrationHoldMs,
    int? illustrationFadeMs,
  }) : illustrationHoldMs = illustrationElementId == null
           ? null
           : illustrationHoldMs ?? 1000,
       illustrationFadeMs = illustrationElementId == null
           ? null
           : illustrationFadeMs ?? 1500 {
    final needsIllustration =
        mode == SceneWarpPresentationMode.illustrated ||
        mode == SceneWarpPresentationMode.caveEntrance;
    if (needsIllustration != (illustrationElementId != null) ||
        (illustrationElementId != null &&
            (illustrationElementId!.isEmpty ||
                illustrationElementId!.trim() != illustrationElementId)) ||
        (!needsIllustration &&
            (illustrationHoldMs != null || illustrationFadeMs != null))) {
      throw const FormatException(
        'Warp presentation has incompatible illustration options.',
      );
    }
    for (final value in [
      fadeOutMs,
      transferDelayMs,
      revealMs,
      this.illustrationHoldMs,
      this.illustrationFadeMs,
    ]) {
      if (value != null && (value < 0 || value > 10000)) {
        throw const FormatException(
          'Warp presentation durations must be bounded milliseconds.',
        );
      }
    }
    if (fadeOutMs == 0 ||
        revealMs == 0 ||
        transferDelayMs < fadeOutMs ||
        this.illustrationFadeMs == 0) {
      throw const FormatException('Warp presentation has an invalid timeline.');
    }
  }

  final SceneWarpPresentationMode mode;
  final String? illustrationElementId;
  final int fadeOutMs;
  final int transferDelayMs;
  final int revealMs;
  final int? illustrationHoldMs;
  final int? illustrationFadeMs;

  static const caveBandCount = 15;
  static const caveBandsMs = 400;
  static const caveFillMs = 400;
  static const cavePauseMs = 100;

  bool get hasCaveEffect =>
      mode == SceneWarpPresentationMode.caveEntrance ||
      mode == SceneWarpPresentationMode.caveExit;

  factory SceneWarpPresentation.fromJson(Map<String, dynamic> json) {
    const fields = {
      'mode',
      'illustrationElementId',
      'fadeOutMs',
      'transferDelayMs',
      'revealMs',
      'illustrationHoldMs',
      'illustrationFadeMs',
    };
    if (json.keys.any((key) => !fields.contains(key))) {
      throw const FormatException('Unknown warp presentation field.');
    }
    final mode = SceneWarpPresentationMode.values
        .where((candidate) => candidate.name == json['mode'])
        .firstOrNull;
    if (mode == null) {
      throw const FormatException('Unknown warp presentation mode.');
    }
    int duration(String key, int fallback) {
      if (!json.containsKey(key)) return fallback;
      final value = json[key];
      if (value is! int) {
        throw FormatException('$key must be integer milliseconds.');
      }
      return value;
    }

    int? optionalDuration(String key) {
      if (!json.containsKey(key)) return null;
      final value = json[key];
      if (value is! int) {
        throw FormatException('$key must be integer milliseconds.');
      }
      return value;
    }

    final elementId = json['illustrationElementId'];
    if (json.containsKey('illustrationElementId') && elementId is! String) {
      throw const FormatException(
        'Warp illustration must be an element identity.',
      );
    }
    return SceneWarpPresentation(
      mode: mode,
      illustrationElementId: elementId as String?,
      fadeOutMs: duration('fadeOutMs', 300),
      transferDelayMs: duration('transferDelayMs', 400),
      revealMs: duration('revealMs', 300),
      illustrationHoldMs: optionalDuration('illustrationHoldMs'),
      illustrationFadeMs: optionalDuration('illustrationFadeMs'),
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'fadeOutMs': fadeOutMs,
    'transferDelayMs': transferDelayMs,
    'revealMs': revealMs,
    if (illustrationElementId != null) ...{
      'illustrationElementId': illustrationElementId,
      'illustrationHoldMs': illustrationHoldMs,
      'illustrationFadeMs': illustrationFadeMs,
    },
  };

  @override
  bool operator ==(Object other) =>
      other is SceneWarpPresentation &&
      other.mode == mode &&
      other.illustrationElementId == illustrationElementId &&
      other.fadeOutMs == fadeOutMs &&
      other.transferDelayMs == transferDelayMs &&
      other.revealMs == revealMs &&
      other.illustrationHoldMs == illustrationHoldMs &&
      other.illustrationFadeMs == illustrationFadeMs;

  @override
  int get hashCode => Object.hash(
    mode,
    illustrationElementId,
    fadeOutMs,
    transferDelayMs,
    revealMs,
    illustrationHoldMs,
    illustrationFadeMs,
  );
}
