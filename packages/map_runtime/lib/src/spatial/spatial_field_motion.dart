import 'dart:async';

import 'package:map_core/map_core.dart';

final class SpatialFieldMotion {
  FieldAbility? _ability;
  PlayerSpatialPosition? _from, _to;
  String? _modelInstanceId;
  double _modelDeltaX = 0, _modelDeltaZ = 0;
  double _duration = 0;
  double elapsedSeconds = 0;
  Completer<bool>? _completion;

  bool get isActive => _ability != null;
  double get progress =>
      isActive ? (elapsedSeconds / _duration).clamp(0, 1) : 0;
  CharacterAnimationState? get state => switch (_ability) {
    FieldAbility.strength => CharacterAnimationState.push,
    FieldAbility.waterfall ||
    FieldAbility.whirlpool => CharacterAnimationState.surf,
    _ => null,
  };

  PlayerSpatialPosition? get position => !isActive
      ? null
      : PlayerSpatialPosition(
          x: _from!.x + (_to!.x - _from!.x) * progress,
          z: _from!.z + (_to!.z - _from!.z) * progress,
        );

  ({double x, double z})? modelTranslation(String instanceId) =>
      !isActive || instanceId != _modelInstanceId
      ? null
      : (x: _modelDeltaX * progress, z: _modelDeltaZ * progress);

  Future<bool> play({
    required FieldAbility ability,
    required PlayerSpatialPosition from,
    required PlayerSpatialPosition to,
    required int durationMs,
    String? modelInstanceId,
    double modelDeltaX = 0,
    double modelDeltaZ = 0,
  }) {
    if (!const {
      FieldAbility.strength,
      FieldAbility.waterfall,
      FieldAbility.whirlpool,
    }.contains(ability)) {
      throw ArgumentError.value(ability, 'ability');
    }
    if (durationMs <= 0 ||
        from == to ||
        !modelDeltaX.isFinite ||
        !modelDeltaZ.isFinite ||
        modelInstanceId == '' ||
        modelInstanceId == null && (modelDeltaX != 0 || modelDeltaZ != 0) ||
        ability != FieldAbility.strength && modelInstanceId != null) {
      throw ArgumentError('Invalid field motion.');
    }
    if (isActive) return Future.value(false);
    _ability = ability;
    _from = from;
    _to = to;
    _modelInstanceId = modelInstanceId;
    _modelDeltaX = modelDeltaX;
    _modelDeltaZ = modelDeltaZ;
    _duration = durationMs / 1000;
    elapsedSeconds = 0;
    final completion = _completion = Completer<bool>();
    return completion.future;
  }

  void update(double dt, {bool paused = false}) {
    if (!isActive || paused || !dt.isFinite || dt <= 0 || _completion == null) {
      return;
    }
    elapsedSeconds += dt;
    if (elapsedSeconds + 1e-9 >= _duration) {
      elapsedSeconds = _duration;
      final completion = _completion!;
      _completion = null;
      completion.complete(true);
    }
  }

  void cancel() => release();

  void release() {
    final completion = _completion;
    _completion = null;
    _ability = null;
    _from = _to = null;
    _modelInstanceId = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete(false);
    }
  }
}
