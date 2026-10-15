part of 'playable_map_game.dart';

final class _NpcFixedRouteRuntimeEntry {
  _NpcFixedRouteRuntimeEntry({required this.scope, required this.controller});

  final MapInstanceRef scope;
  final NpcFixedRouteController controller;
  NpcFixedRouteAttempt? pendingAttempt;
  ActorRouteMotionPlan? pendingMotion;
}

extension _PlayableMapNpcFixedRoutes on PlayableMapGame {
  bool get _npcFixedRoutesPaused =>
      !_canResolveOverworldInteraction() ||
      _dialogueOverlay != null ||
      _hasPendingDialogueLoad ||
      _pendingBattleRequest != null ||
      _sceneForcedRouteBarrierCount > 0 ||
      _sceneActorRouteTargets.isNotEmpty;

  void _resetNpcFixedRoutes() {
    final scope = _battleRuntimeGameState.mapInstanceWorldState.instanceRef(
      _activeMapId,
    );
    final active = <String>{};
    if (scope != null && _world.map.spatialScene == null) {
      final present = _npcPresencePredicateFor(_bundle.manifest);
      for (final entity in _world.map.entities) {
        final movement = entity.npc?.movement;
        if (entity.kind != MapEntityKind.npc ||
            movement?.mode != MapEntityNpcMovementMode.fixedRoute ||
            !present(_activeMapId, entity) ||
            _loadedMapsById[_activeMapId]?.npcActorByEntityId[entity.id] ==
                null) {
          continue;
        }
        active.add(entity.id);
        final existing = _npcFixedRoutes[entity.id];
        if (existing != null &&
            existing.scope == scope &&
            existing.controller.movement == movement) {
          _interruptNpcFixedRoute(entity.id);
          continue;
        }
        existing?.controller.dispose();
        _npcFixedRoutes[entity.id] = _NpcFixedRouteRuntimeEntry(
          scope: scope,
          controller: NpcFixedRouteController(
            target: SceneActorTarget.entity(
              mapId: _activeMapId,
              entityId: entity.id,
            ),
            movement: movement!,
            random: _npcRouteRandom,
            readInstanceBoolean: (key) => _battleRuntimeGameState
                .mapInstanceWorldState
                .eventBoolean(scope, entity.id, key),
          ),
        );
      }
    }
    for (final id in _npcFixedRoutes.keys.toList(growable: false)) {
      if (active.contains(id)) continue;
      _npcFixedRoutes.remove(id)!.controller.dispose();
    }
  }

  void _disposeNpcFixedRoutes() {
    for (final entry in _npcFixedRoutes.values) {
      entry.controller.dispose();
    }
    _npcFixedRoutes.clear();
  }

  void _interruptNpcFixedRoute(String entityId) {
    final entry = _npcFixedRoutes[entityId];
    if (entry == null) return;
    entry.controller.interrupt();
    _cancelNpcFixedRouteMotion(entityId, entry);
  }

  void _cancelNpcFixedRouteMotion(
    String entityId,
    _NpcFixedRouteRuntimeEntry entry,
  ) {
    if (entry.pendingMotion != null) {
      final entity = _world.map.entities
          .where((candidate) => candidate.id == entityId)
          .firstOrNull;
      final loaded = _loadedMapsById[_activeMapId];
      final actor = loaded?.npcActorByEntityId[entityId];
      if (entity != null && actor != null && loaded != null) {
        actor.configureGridPlacement(
          pos: entity.pos,
          footprint: entity.size,
          mapOrigin: _originPixelsOf(loaded),
        );
        actor.setMotion(entity.npc!.facing, CharacterAnimationState.idle);
      }
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
    }
    entry.pendingAttempt = null;
    entry.pendingMotion = null;
  }

  void _updateNpcFixedRoutes(double dt) {
    if (_isRemoved || !isLoaded || !dt.isFinite || dt < 0) return;
    final elapsed = Duration(microseconds: (dt * 1000000).round());
    final scope = _battleRuntimeGameState.mapInstanceWorldState.instanceRef(
      _activeMapId,
    );
    for (final item in _npcFixedRoutes.entries.toList(growable: false)) {
      final id = item.key;
      final entry = item.value;
      if (scope != entry.scope) {
        entry.controller.dispose();
        _npcFixedRoutes.remove(id);
        continue;
      }
      final entity = _world.map.entities
          .where((candidate) => candidate.id == id)
          .firstOrNull;
      if (entity?.npc?.movement != entry.controller.movement ||
          !_npcPresencePredicateFor(_bundle.manifest)(_activeMapId, entity!) ||
          _loadedMapsById[_activeMapId]?.npcActorByEntityId[id] == null) {
        entry.controller.dispose();
        _cancelNpcFixedRouteMotion(id, entry);
        _npcFixedRoutes.remove(id);
        continue;
      }
      final binding = entry.controller.movement.suspendWhenInstanceBoolean;
      if (binding != null &&
          _battleRuntimeGameState.mapInstanceWorldState.eventBoolean(
                scope!,
                id,
                binding.key,
              ) ==
              binding.value) {
        _interruptNpcFixedRoute(id);
        continue;
      }
      if (_npcFixedRoutesPaused) {
        if (entry.pendingAttempt != null) _interruptNpcFixedRoute(id);
        continue;
      }
      final pending = entry.pendingAttempt;
      if (pending != null) {
        if (_isScriptedNpcStepping(id)) continue;
        final motion = entry.pendingMotion;
        if (motion != null &&
            entry.controller.resolveStep(
              pending,
              NpcFixedRouteStepOutcome.completed,
            )) {
          _commitScriptedNpcPosition(id, motion.to);
          _scriptedEntityMovementController?.syncTrackedEntityPosition(
            id,
            motion.to,
          );
          entry.pendingAttempt = null;
          entry.pendingMotion = null;
          if (!_npcFixedRoutesPaused) _checkTrainerLineOfSight();
        } else {
          _cancelNpcFixedRouteMotion(id, entry);
        }
        continue;
      }
      final attempt = entry.controller.nextStep(
        elapsed,
        paused: _npcFixedRoutesPaused,
      );
      if (attempt == null) continue;
      final plan = planNpcFixedRouteStep(
        world: _world,
        attempt: attempt,
        dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
          ignoreEntityId: id,
        ),
        characterReservations: [
          for (final reservation
              in _scriptedNpcReservedOccupiedCellsByEntity.entries)
            if (reservation.key != id && reservation.value.contactRect != null)
              reservation.value.contactRect!,
        ],
      );
      _world = plan.world;
      _loadedMapsById[_activeMapId]!.npcActorByEntityId[id]!.setMotion(
        attempt.direction,
        CharacterAnimationState.idle,
      );
      final motion = plan.motion;
      if (motion == null) {
        entry.controller.resolveStep(
          attempt,
          plan.isBlocked
              ? NpcFixedRouteStepOutcome.blocked
              : NpcFixedRouteStepOutcome.completed,
        );
        _checkTrainerLineOfSight();
        continue;
      }
      if (_startScriptedNpcStep(
        entityId: id,
        from: motion.from,
        to: motion.to,
        facing: attempt.direction,
        durationSeconds: attempt.stepDurationMs / 1000,
      )) {
        entry.pendingAttempt = attempt;
        entry.pendingMotion = motion;
      } else {
        entry.controller.resolveStep(attempt, NpcFixedRouteStepOutcome.blocked);
      }
    }
  }
}
