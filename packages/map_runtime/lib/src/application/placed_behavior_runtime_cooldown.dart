import 'package:map_core/map_core.dart';

class PlacedBehaviorRuntimeKey {
  const PlacedBehaviorRuntimeKey({
    required this.instanceId,
    required this.behaviorId,
    required this.trigger,
    required this.effectType,
  });

  final String instanceId;
  final String behaviorId;
  final MapPlacedElementTriggerType trigger;
  final MapPlacedElementEffectType effectType;

  @override
  bool operator ==(Object other) {
    return other is PlacedBehaviorRuntimeKey &&
        other.instanceId == instanceId &&
        other.behaviorId == behaviorId &&
        other.trigger == trigger &&
        other.effectType == effectType;
  }

  @override
  int get hashCode => Object.hash(
        instanceId,
        behaviorId,
        trigger,
        effectType,
      );
}

class PlacedBehaviorCooldownPolicy {
  const PlacedBehaviorCooldownPolicy({
    this.showMessage = const Duration(milliseconds: 650),
    this.openDialogue = const Duration(milliseconds: 900),
    this.playAnimationOnce = const Duration(milliseconds: 180),
    this.setAnimationEnabled = Duration.zero,
  });

  final Duration showMessage;
  final Duration openDialogue;
  final Duration playAnimationOnce;
  final Duration setAnimationEnabled;

  Duration durationFor(MapPlacedElementEffectType effectType) {
    return switch (effectType) {
      MapPlacedElementEffectType.showMessage => showMessage,
      MapPlacedElementEffectType.openDialogue => openDialogue,
      MapPlacedElementEffectType.playAnimationOnce => playAnimationOnce,
      MapPlacedElementEffectType.setAnimationEnabled => setAnimationEnabled,
    };
  }
}

class PlacedBehaviorCooldownGate {
  PlacedBehaviorCooldownGate({
    PlacedBehaviorCooldownPolicy policy = const PlacedBehaviorCooldownPolicy(),
  }) : _policy = policy;

  final PlacedBehaviorCooldownPolicy _policy;
  final Map<PlacedBehaviorRuntimeKey, double> _blockedUntilMs =
      <PlacedBehaviorRuntimeKey, double>{};

  bool canTrigger({
    required PlacedBehaviorRuntimeKey key,
    required double nowMs,
  }) {
    final blockedUntil = _blockedUntilMs[key];
    if (blockedUntil == null) {
      return true;
    }
    if (blockedUntil <= nowMs) {
      _blockedUntilMs.remove(key);
      return true;
    }
    return false;
  }

  double remainingMs({
    required PlacedBehaviorRuntimeKey key,
    required double nowMs,
  }) {
    final blockedUntil = _blockedUntilMs[key];
    if (blockedUntil == null) {
      return 0;
    }
    final remaining = blockedUntil - nowMs;
    if (remaining <= 0) {
      return 0;
    }
    return remaining;
  }

  void markTriggered({
    required PlacedBehaviorRuntimeKey key,
    required double nowMs,
  }) {
    final duration = _policy.durationFor(key.effectType);
    if (duration <= Duration.zero) {
      _blockedUntilMs.remove(key);
      return;
    }
    _blockedUntilMs[key] = nowMs + duration.inMilliseconds;
  }

  void prune({
    required double nowMs,
  }) {
    if (_blockedUntilMs.isEmpty) {
      return;
    }
    final toRemove = <PlacedBehaviorRuntimeKey>[];
    for (final entry in _blockedUntilMs.entries) {
      if (entry.value <= nowMs) {
        toRemove.add(entry.key);
      }
    }
    for (final key in toRemove) {
      _blockedUntilMs.remove(key);
    }
  }
}
