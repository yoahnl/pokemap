import 'package:meta/meta.dart' show immutable;

import 'enums.dart';

enum SceneActorTargetKind { player, entity }

enum SceneActorRouteStepKind { face, move, wait, through, sound }

@immutable
final class SceneActorTarget {
  SceneActorTarget.player({required String mapId})
    : kind = SceneActorTargetKind.player,
      mapId = _actorText(mapId, 'mapId'),
      entityId = null;

  SceneActorTarget.entity({required String mapId, required String entityId})
    : kind = SceneActorTargetKind.entity,
      mapId = _actorText(mapId, 'mapId'),
      entityId = _actorText(entityId, 'entityId');

  factory SceneActorTarget.fromJson(Map<String, dynamic> json) {
    final kind = _actorEnum(json, 'kind', SceneActorTargetKind.values);
    _actorFields(
      json,
      kind == SceneActorTargetKind.player
          ? const {'kind', 'mapId'}
          : const {'kind', 'mapId', 'entityId'},
    );
    return kind == SceneActorTargetKind.player
        ? SceneActorTarget.player(mapId: _actorJsonText(json, 'mapId'))
        : SceneActorTarget.entity(
            mapId: _actorJsonText(json, 'mapId'),
            entityId: _actorJsonText(json, 'entityId'),
          );
  }

  final SceneActorTargetKind kind;
  final String mapId;
  final String? entityId;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'mapId': mapId,
    if (entityId != null) 'entityId': entityId,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneActorTarget &&
      kind == other.kind &&
      mapId == other.mapId &&
      entityId == other.entityId;
  @override
  int get hashCode => Object.hash(kind, mapId, entityId);
}

@immutable
sealed class SceneActorRouteStep {
  const SceneActorRouteStep();

  factory SceneActorRouteStep.face({
    required EntityFacing direction,
    int durationMs,
  }) = SceneActorFaceStep;
  factory SceneActorRouteStep.move({
    required EntityFacing direction,
    required int durationMs,
  }) = SceneActorMoveStep;
  factory SceneActorRouteStep.wait({required int durationMs}) =
      SceneActorWaitStep;
  factory SceneActorRouteStep.through({required bool enabled}) =
      SceneActorThroughStep;
  factory SceneActorRouteStep.sound({
    required String mediaAssetId,
    required double gain,
  }) = SceneActorSoundStep;

  factory SceneActorRouteStep.fromJson(Map<String, dynamic> json) {
    final kind = _actorEnum(json, 'kind', SceneActorRouteStepKind.values);
    switch (kind) {
      case SceneActorRouteStepKind.face:
        _actorFields(
          json,
          const {'kind', 'direction'},
          optional: const {'durationMs'},
        );
        return SceneActorFaceStep(
          direction: _actorEnum(json, 'direction', EntityFacing.values),
          durationMs: json.containsKey('durationMs')
              ? _actorJsonDuration(json, minimum: 0)
              : 0,
        );
      case SceneActorRouteStepKind.move:
        _actorFields(json, const {'kind', 'direction', 'durationMs'});
        return SceneActorMoveStep(
          direction: _actorEnum(json, 'direction', EntityFacing.values),
          durationMs: _actorJsonDuration(json, minimum: 1),
        );
      case SceneActorRouteStepKind.wait:
        _actorFields(json, const {'kind', 'durationMs'});
        return SceneActorWaitStep(
          durationMs: _actorJsonDuration(json, minimum: 0),
        );
      case SceneActorRouteStepKind.through:
        _actorFields(json, const {'kind', 'enabled'});
        if (json['enabled'] is! bool) {
          throw const FormatException('enabled must be a boolean.');
        }
        return SceneActorThroughStep(enabled: json['enabled'] as bool);
      case SceneActorRouteStepKind.sound:
        _actorFields(json, const {'kind', 'mediaAssetId', 'gain'});
        final gain = json['gain'];
        if (gain is! num || !gain.isFinite || gain < 0 || gain > 1) {
          throw const FormatException('gain must be finite in [0, 1].');
        }
        return SceneActorSoundStep(
          mediaAssetId: _actorJsonText(json, 'mediaAssetId'),
          gain: gain.toDouble(),
        );
    }
  }

  SceneActorRouteStepKind get kind;
  Map<String, dynamic> toJson();
}

final class SceneActorFaceStep extends SceneActorRouteStep {
  SceneActorFaceStep({required this.direction, int durationMs = 0})
    : durationMs = _actorDuration(durationMs, minimum: 0);
  final EntityFacing direction;
  final int durationMs;
  @override
  SceneActorRouteStepKind get kind => SceneActorRouteStepKind.face;
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'direction': direction.name,
    'durationMs': durationMs,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneActorFaceStep &&
      direction == other.direction &&
      durationMs == other.durationMs;
  @override
  int get hashCode => Object.hash(kind, direction, durationMs);
}

final class SceneActorMoveStep extends SceneActorRouteStep {
  SceneActorMoveStep({required this.direction, required int durationMs})
    : durationMs = _actorDuration(durationMs, minimum: 1);
  final EntityFacing direction;
  final int durationMs;
  @override
  SceneActorRouteStepKind get kind => SceneActorRouteStepKind.move;
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'direction': direction.name,
    'durationMs': durationMs,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneActorMoveStep &&
      direction == other.direction &&
      durationMs == other.durationMs;
  @override
  int get hashCode => Object.hash(kind, direction, durationMs);
}

final class SceneActorWaitStep extends SceneActorRouteStep {
  SceneActorWaitStep({required int durationMs})
    : durationMs = _actorDuration(durationMs, minimum: 0);
  final int durationMs;
  @override
  SceneActorRouteStepKind get kind => SceneActorRouteStepKind.wait;
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'durationMs': durationMs,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneActorWaitStep && durationMs == other.durationMs;
  @override
  int get hashCode => Object.hash(kind, durationMs);
}

final class SceneActorThroughStep extends SceneActorRouteStep {
  const SceneActorThroughStep({required this.enabled});
  final bool enabled;
  @override
  SceneActorRouteStepKind get kind => SceneActorRouteStepKind.through;
  @override
  Map<String, dynamic> toJson() => {'kind': kind.name, 'enabled': enabled};
  @override
  bool operator ==(Object other) =>
      other is SceneActorThroughStep && enabled == other.enabled;
  @override
  int get hashCode => Object.hash(kind, enabled);
}

final class SceneActorSoundStep extends SceneActorRouteStep {
  SceneActorSoundStep({required String mediaAssetId, required double gain})
    : mediaAssetId = _actorText(mediaAssetId, 'mediaAssetId'),
      gain = _actorGain(gain);
  final String mediaAssetId;
  final double gain;
  @override
  SceneActorRouteStepKind get kind => SceneActorRouteStepKind.sound;
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'mediaAssetId': mediaAssetId,
    'gain': gain,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneActorSoundStep &&
      mediaAssetId == other.mediaAssetId &&
      gain == other.gain;
  @override
  int get hashCode => Object.hash(kind, mediaAssetId, gain);
}

void _actorFields(
  Map<String, dynamic> json,
  Set<String> required, {
  Set<String> optional = const {},
}) {
  final keys = json.keys.toSet();
  if (required.difference(keys).isNotEmpty ||
      keys.difference({...required, ...optional}).isNotEmpty) {
    throw const FormatException(
      'Actor route fields do not match the contract.',
    );
  }
}

String _actorText(String value, String field) {
  final text = value.trim();
  if (text.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty.');
  }
  return text;
}

String _actorJsonText(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a nonempty string.');
  }
  return value.trim();
}

T _actorEnum<T extends Enum>(
  Map<String, dynamic> json,
  String field,
  List<T> values,
) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a string.');
  return values.firstWhere(
    (candidate) => candidate.name == value,
    orElse: () => throw FormatException('Unknown $field: $value.'),
  );
}

int _actorDuration(int value, {required int minimum}) {
  if (value < minimum || value > 0x7fffffff) {
    throw ArgumentError.value(
      value,
      'durationMs',
      'Must be int32 >= $minimum.',
    );
  }
  return value;
}

int _actorJsonDuration(Map<String, dynamic> json, {required int minimum}) {
  final value = json['durationMs'];
  if (value is! int || value < minimum || value > 0x7fffffff) {
    throw FormatException('durationMs must be int32 >= $minimum.');
  }
  return value;
}

double _actorGain(double value) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw ArgumentError.value(value, 'gain', 'Must be finite in [0, 1].');
  }
  return value;
}
