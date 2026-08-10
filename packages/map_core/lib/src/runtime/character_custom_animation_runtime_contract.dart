import '../models/enums.dart';

enum CharacterCustomAnimationPlaybackKind { once, repeatCount, forDuration }

enum CharacterCustomAnimationInterruptionPolicy { replaceActive, rejectIfBusy }

enum CharacterCustomAnimationFallbackPolicy { fail, restoreBaseAndComplete }

final class CharacterCustomAnimationPlayback {
  const CharacterCustomAnimationPlayback._once()
    : kind = CharacterCustomAnimationPlaybackKind.once,
      repeatCount = null,
      durationMs = null;

  const CharacterCustomAnimationPlayback._repeatCount(int count)
    : kind = CharacterCustomAnimationPlaybackKind.repeatCount,
      repeatCount = count,
      durationMs = null;

  const CharacterCustomAnimationPlayback._forDuration(int duration)
    : kind = CharacterCustomAnimationPlaybackKind.forDuration,
      repeatCount = null,
      durationMs = duration;

  factory CharacterCustomAnimationPlayback.once() =>
      const CharacterCustomAnimationPlayback._once();

  factory CharacterCustomAnimationPlayback.repeatCount(int count) {
    if (count <= 0) throw ArgumentError.value(count, 'count');
    return CharacterCustomAnimationPlayback._repeatCount(count);
  }

  factory CharacterCustomAnimationPlayback.forDuration(int duration) {
    if (duration <= 0) throw ArgumentError.value(duration, 'duration');
    return CharacterCustomAnimationPlayback._forDuration(duration);
  }

  factory CharacterCustomAnimationPlayback.fromJson(Map<String, dynamic> json) {
    final kind = CharacterCustomAnimationPlaybackKind.values.firstWhere(
      (value) => value.name == json['kind'],
      orElse: () => throw const FormatException('Invalid playback kind.'),
    );
    return switch (kind) {
      CharacterCustomAnimationPlaybackKind.once =>
        const CharacterCustomAnimationPlayback._once(),
      CharacterCustomAnimationPlaybackKind.repeatCount =>
        CharacterCustomAnimationPlayback.repeatCount(
          _positiveInt(json['repeatCount'], 'repeatCount'),
        ),
      CharacterCustomAnimationPlaybackKind.forDuration =>
        CharacterCustomAnimationPlayback.forDuration(
          _positiveInt(json['durationMs'], 'durationMs'),
        ),
    };
  }

  final CharacterCustomAnimationPlaybackKind kind;
  final int? repeatCount;
  final int? durationMs;

  int completionDurationMs({required int cycleDurationMs}) {
    if (cycleDurationMs <= 0) {
      throw ArgumentError.value(cycleDurationMs, 'cycleDurationMs');
    }
    return switch (kind) {
      CharacterCustomAnimationPlaybackKind.once => cycleDurationMs,
      CharacterCustomAnimationPlaybackKind.repeatCount =>
        cycleDurationMs * repeatCount!,
      CharacterCustomAnimationPlaybackKind.forDuration => durationMs!,
    };
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    if (repeatCount != null) 'repeatCount': repeatCount,
    if (durationMs != null) 'durationMs': durationMs,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterCustomAnimationPlayback &&
          other.kind == kind &&
          other.repeatCount == repeatCount &&
          other.durationMs == durationMs;

  @override
  int get hashCode => Object.hash(kind, repeatCount, durationMs);
}

final class CharacterCustomAnimationRuntimeCommand {
  CharacterCustomAnimationRuntimeCommand({
    required this.actorId,
    required this.definitionId,
    this.direction,
    CharacterCustomAnimationPlayback? playback,
    this.interruptionPolicy =
        CharacterCustomAnimationInterruptionPolicy.replaceActive,
    this.fallbackPolicy = CharacterCustomAnimationFallbackPolicy.fail,
  }) : playback = playback ?? const CharacterCustomAnimationPlayback._once() {
    if (actorId.trim().isEmpty) throw ArgumentError.value(actorId, 'actorId');
    if (definitionId.trim().isEmpty) {
      throw ArgumentError.value(definitionId, 'definitionId');
    }
  }

  factory CharacterCustomAnimationRuntimeCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    final actorId = _nonBlank(json['actorId'], 'actorId');
    final definitionId = _nonBlank(json['definitionId'], 'definitionId');
    final directionName = json['direction'];
    final playbackJson = json['playback'];
    if (playbackJson is! Map) {
      throw const FormatException('playback must be an object.');
    }
    return CharacterCustomAnimationRuntimeCommand(
      actorId: actorId,
      definitionId: definitionId,
      direction: directionName == null
          ? null
          : EntityFacing.values.firstWhere(
              (value) => value.name == directionName,
              orElse: () => throw const FormatException('Invalid direction.'),
            ),
      playback: CharacterCustomAnimationPlayback.fromJson(
        Map<String, dynamic>.from(playbackJson),
      ),
      interruptionPolicy: CharacterCustomAnimationInterruptionPolicy.values
          .firstWhere(
            (value) => value.name == json['interruptionPolicy'],
            orElse: () =>
                throw const FormatException('Invalid interruption policy.'),
          ),
      fallbackPolicy: CharacterCustomAnimationFallbackPolicy.values.firstWhere(
        (value) => value.name == json['fallbackPolicy'],
        orElse: () => throw const FormatException('Invalid fallback policy.'),
      ),
    );
  }

  final String actorId;
  final String definitionId;
  final EntityFacing? direction;
  final CharacterCustomAnimationPlayback playback;
  final CharacterCustomAnimationInterruptionPolicy interruptionPolicy;
  final CharacterCustomAnimationFallbackPolicy fallbackPolicy;

  Map<String, Object?> toJson() => <String, Object?>{
    'actorId': actorId,
    'definitionId': definitionId,
    if (direction != null) 'direction': direction!.name,
    'playback': playback.toJson(),
    'interruptionPolicy': interruptionPolicy.name,
    'fallbackPolicy': fallbackPolicy.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterCustomAnimationRuntimeCommand &&
          other.actorId == actorId &&
          other.definitionId == definitionId &&
          other.direction == direction &&
          other.playback == playback &&
          other.interruptionPolicy == interruptionPolicy &&
          other.fallbackPolicy == fallbackPolicy;

  @override
  int get hashCode => Object.hash(
    actorId,
    definitionId,
    direction,
    playback,
    interruptionPolicy,
    fallbackPolicy,
  );
}

int _positiveInt(Object? value, String name) {
  if (value is! int || value <= 0) {
    throw FormatException('$name must be a positive integer.');
  }
  return value;
}

String _nonBlank(Object? value, String name) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$name must be a non-empty string.');
  }
  return value.trim();
}
