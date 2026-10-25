import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'spatial_cinematic_runtime_playback_sink.dart';

typedef SpatialNpcAutonomousTraversal = bool Function(
  MapEntity entity,
  double fromX,
  double fromZ,
  double toX,
  double toZ,
  Map<String, SpatialActorRuntimeState> reservations,
);

final class SpatialNpcFixedRouteRuntime {
  SpatialNpcFixedRouteRuntime({
    required this.readMap,
    required this.readActor,
    required this.isPresent,
    required this.canTraverse,
    required this.commitActor,
    required this.random,
    this.readVariantKey,
    this.readInstanceBoolean,
  });

  final MapData Function() readMap;
  final SpatialActorRuntimeState? Function(MapEntity entity) readActor;
  final bool Function(MapEntity entity) isPresent;
  final SpatialNpcAutonomousTraversal canTraverse;
  final void Function(String entityId, SpatialActorRuntimeState state)
  commitActor;
  final Random random;
  final String? Function(MapEntity entity)? readVariantKey;
  final bool Function(String entityId, String key)? readInstanceBoolean;
  final _entries = <String, _SpatialNpcRouteEntry>{};
  final _poses = <String, SpatialCinematicActorPose>{};
  String? _mapId;
  bool _disposed = false;

  SpatialCinematicActorPose? poseFor(String entityId) => _poses[entityId];

  void update(double dt, {bool paused = false}) {
    if (_disposed || !dt.isFinite || dt < 0) return;
    final map = readMap();
    if (_mapId != map.id) {
      reset();
      _mapId = map.id;
    }
    final active = <String, MapEntity>{};
    if (map.spatialScene != null) {
      for (final entity in map.entities) {
        if (entity.npc?.movement.mode == MapEntityNpcMovementMode.fixedRoute &&
            isPresent(entity)) {
          active[entity.id] = entity;
        }
      }
    }
    for (final id in _entries.keys.toList()) {
      final entity = active[id];
      final entry = _entries[id]!;
      if (entity == null ||
          entry.controller.movement != entity.npc!.movement ||
          entry.variantKey != readVariantKey?.call(entity)) {
        _flushEntry(id, entry);
        entry.controller.dispose();
        _entries.remove(id);
        _poses.remove(id);
      }
    }
    for (final entity in active.values) {
      final entry = _entries.putIfAbsent(
        entity.id,
        () => _SpatialNpcRouteEntry(
          controller: NpcFixedRouteController(
            target: SceneActorTarget.entity(mapId: map.id, entityId: entity.id),
            movement: entity.npc!.movement,
            random: random,
            readInstanceBoolean: (key) =>
                readInstanceBoolean?.call(entity.id, key) ?? false,
          ),
          variantKey: readVariantKey?.call(entity),
          entity: entity,
        ),
      );
      final binding = entity.npc!.movement.suspendWhenInstanceBoolean;
      final suspended =
          binding != null &&
          (readInstanceBoolean?.call(entity.id, binding.key) ?? false) ==
              binding.value;
      if (entry.attempt != null && !_stillOwned(entry)) {
        entry.controller.interrupt();
        entry.clearMotion();
        _poses.remove(entity.id);
      }
      if (paused || suspended) {
        _flushEntry(entity.id, entry);
        final pose = _poses[entity.id];
        if (pose != null) {
          _poses[entity.id] = pose.copyWith(
            motion: CharacterAnimationState.idle,
          );
        }
        continue;
      }
      if (entry.attempt != null) {
        _advance(entity, entry, dt);
        continue;
      }
      final attempt = entry.controller.nextStep(
        Duration(microseconds: (dt * 1000000).round()),
      );
      if (attempt == null) continue;
      final source =
          readActor(entity) ??
          SpatialActorRuntimeState(
            x: entity.pos.x + .5,
            z: entity.pos.y + .5,
            facing: entity.npc!.facing,
          );
      final faced = SpatialActorRuntimeState(
        x: source.x,
        z: source.z,
        facing: attempt.direction,
      );
      commitActor(entity.id, faced);
      entry.lastCommitted = faced;
      final moving =
          attempt.step is MapEntityNpcMoveStep ||
          attempt.step is MapEntityNpcRandomMoveStep;
      if (!moving) {
        entry.controller.resolveStep(
          attempt,
          NpcFixedRouteStepOutcome.completed,
        );
        continue;
      }
      final (dx, dz) = switch (attempt.direction) {
        EntityFacing.north => (0, -1),
        EntityFacing.south => (0, 1),
        EntityFacing.west => (-1, 0),
        EntityFacing.east => (1, 0),
      };
      final toX = source.x + dx, toZ = source.z + dz;
      if (!_inside(entity.npc!.movement.movementArea, toX, toZ) ||
          !_canTraverse(entity, source.x, source.z, toX, toZ)) {
        entry.controller.resolveStep(attempt, NpcFixedRouteStepOutcome.blocked);
        continue;
      }
      entry.attempt = attempt;
      entry.from = faced;
      entry.to = SpatialActorRuntimeState(
        x: toX,
        z: toZ,
        facing: attempt.direction,
      );
      _poses[entity.id] = SpatialCinematicActorPose(
        x: source.x,
        z: source.z,
        facing: attempt.direction,
        motion: CharacterAnimationState.walk,
      );
    }
  }

  void _advance(MapEntity entity, _SpatialNpcRouteEntry entry, double dt) {
    final from = entry.from!, to = entry.to!, attempt = entry.attempt!;
    final elapsed = entry.elapsed + dt;
    final progress = (elapsed * 1000 / attempt.stepDurationMs).clamp(
      0.0,
      1.0,
    );
    final previous = _poses[entity.id]!;
    final x = from.x + (to.x - from.x) * progress;
    final z = from.z + (to.z - from.z) * progress;
    if (!_canTraverse(entity, previous.x, previous.z, x, z)) {
      _flushEntry(entity.id, entry);
      if (entry.elapsed == 0) {
        entry.controller.resolveStep(attempt, NpcFixedRouteStepOutcome.blocked);
        entry.clearMotion();
        _poses.remove(entity.id);
      } else {
        _poses[entity.id] = previous.copyWith(
          motion: CharacterAnimationState.idle,
        );
      }
      return;
    }
    entry.elapsed = elapsed;
    if (progress >= 1) {
      commitActor(entity.id, to);
      entry.lastCommitted = to;
      entry.controller.resolveStep(attempt, NpcFixedRouteStepOutcome.completed);
      entry.clearMotion();
      _poses.remove(entity.id);
    } else {
      _poses[entity.id] = SpatialCinematicActorPose(
        x: x,
        z: z,
        facing: to.facing,
        motion: CharacterAnimationState.walk,
        animationSeconds: entry.elapsed,
      );
    }
  }

  Map<String, SpatialActorRuntimeState> _reservations(String ignoredId) => {
    for (final entry in _entries.entries)
      if (entry.key != ignoredId && entry.value.to != null)
        entry.key: entry.value.to!,
  };

  bool _canTraverse(
    MapEntity entity,
    double x,
    double z,
    double toX,
    double toZ,
  ) =>
      canTraverse(entity, x, z, toX, toZ, _reservations(entity.id)) &&
      canTraverse(entity, x, z, toX, toZ, {
        for (final entry in _poses.entries)
          if (entry.key != entity.id)
            entry.key: SpatialActorRuntimeState(
              x: entry.value.x,
              z: entry.value.z,
              facing: entry.value.facing,
            ),
      });

  bool _stillOwned(_SpatialNpcRouteEntry entry) {
    final current = readActor(entry.entity), expected = entry.lastCommitted;
    return current != null &&
        expected != null &&
        current.x == expected.x &&
        current.z == expected.z;
  }

  void _flushEntry(String id, _SpatialNpcRouteEntry entry) {
    final pose = _poses[id];
    if (pose == null || !_stillOwned(entry)) return;
    final current = readActor(entry.entity)!;
    final value = SpatialActorRuntimeState(
      x: pose.x,
      z: pose.z,
      facing: current.facing,
    );
    if (current != value) commitActor(id, value);
    entry.lastCommitted = value;
  }

  void flush() {
    if (_disposed) return;
    for (final entry in _entries.entries) {
      _flushEntry(entry.key, entry.value);
    }
  }

  bool _inside(MapRect? area, double x, double z) =>
      area == null ||
      x >= area.pos.x + .5 &&
          z >= area.pos.y + .5 &&
          x <= area.pos.x + area.size.width - .5 &&
          z <= area.pos.y + area.size.height - .5;

  void reset() {
    for (final entry in _entries.values) {
      entry.controller.dispose();
    }
    _entries.clear();
    _poses.clear();
    _mapId = null;
  }

  void dispose() {
    reset();
    _disposed = true;
  }
}

final class _SpatialNpcRouteEntry {
  _SpatialNpcRouteEntry({
    required this.controller,
    required this.variantKey,
    required this.entity,
  });
  final NpcFixedRouteController controller;
  final String? variantKey;
  final MapEntity entity;
  NpcFixedRouteAttempt? attempt;
  SpatialActorRuntimeState? from, to, lastCommitted;
  double elapsed = 0;
  void clearMotion() {
    attempt = null;
    from = null;
    to = null;
    elapsed = 0;
  }
}
