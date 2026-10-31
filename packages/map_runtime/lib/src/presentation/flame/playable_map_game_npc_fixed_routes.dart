part of 'playable_map_game.dart';

final class _NpcFixedRouteRuntimeEntry {
  _NpcFixedRouteRuntimeEntry({
    required this.scope,
    required this.controller,
    required this.variantId,
  });

  final MapInstanceRef scope;
  final NpcFixedRouteController controller;
  final String? variantId;
  NpcFixedRouteAttempt? pendingAttempt;
  ActorRouteMotionPlan? pendingMotion;
  bool playerContactActive = false;
}

extension _PlayableMapNpcFixedRoutes on PlayableMapGame {
  bool get _npcFixedRoutesPaused =>
      !_canResolveOverworldInteraction(allowSliding: true) ||
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
        final variantId = _npcFixedRouteVariant(entity.id)?.id;
        if (existing != null &&
            existing.scope == scope &&
            existing.variantId == variantId &&
            existing.controller.movement == movement) {
          continue;
        }
        if (existing != null) {
          _cancelNpcFixedRouteMotion(entity.id, existing);
          existing.controller.dispose();
        }
        _npcFixedRoutes[entity.id] = _NpcFixedRouteRuntimeEntry(
          scope: scope,
          variantId: variantId,
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
      final entry = _npcFixedRoutes.remove(id)!;
      _cancelNpcFixedRouteMotion(id, entry);
      entry.controller.dispose();
    }
  }

  void _disposeNpcFixedRoutes() {
    for (final item in _npcFixedRoutes.entries) {
      _cancelNpcFixedRouteMotion(item.key, item.value);
      item.value.controller.dispose();
    }
    _npcFixedRoutes.clear();
  }

  MapEntityPresentationVariant? _npcFixedRouteVariant(String entityId) {
    final map = (_runtimeBundleByMapId[_activeMapId] ?? _bundle).map;
    final entity = map.entities
        .where((value) => value.id == entityId)
        .firstOrNull;
    return entity == null
        ? null
        : resolveMapEntityPresentation(
            lookupRewardScenes: _lookupRewardScenes,
            project: _bundle.manifest,
            gameState: _scenePresentationGameState,
            map: map,
            entity: entity,
          );
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
      final loaded = _loadedMapsById[entry.scope.mapId];
      final map = _world.map.id == entry.scope.mapId
          ? _world.map
          : loaded?.bundle.map;
      final entity = map?.entities
          .where((candidate) => candidate.id == entityId)
          .firstOrNull;
      final actor = loaded?.npcActorByEntityId[entityId];
      if (entity != null && actor != null && loaded != null) {
        actor.configureGridPlacement(
          pos: entity.pos,
          footprint: entity.size,
          mapOrigin: _originPixelsOf(loaded),
        );
        actor.setMotion(
          entity.npc?.facing ?? actor.facing,
          CharacterAnimationState.idle,
        );
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
        _cancelNpcFixedRouteMotion(id, entry);
        entry.controller.dispose();
        _npcFixedRoutes.remove(id);
        continue;
      }
      final entity = _world.map.entities
          .where((candidate) => candidate.id == id)
          .firstOrNull;
      if (entity?.npc?.movement != entry.controller.movement ||
          _npcFixedRouteVariant(id)?.id != entry.variantId ||
          !_npcPresencePredicateFor(_bundle.manifest)(_activeMapId, entity!) ||
          _loadedMapsById[_activeMapId]?.npcActorByEntityId[id] == null) {
        entry.controller.dispose();
        _cancelNpcFixedRouteMotion(id, entry);
        _npcFixedRoutes.remove(id);
        continue;
      }
      if (entry.playerContactActive &&
          !npcFixedRouteTouchesPlayer(
            world: _world,
            entityId: id,
            direction: entity.npc!.facing,
          )) {
        entry.playerContactActive = false;
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
        if (plan.playerContact &&
            !entry.playerContactActive &&
            _npcFixedRouteVariant(id)?.startsOnNpcContact == true &&
            !_player.isStepping) {
          entry.playerContactActive = true;
          _runDetachedNarrativeTask(
            operation: 'npcRoute.entityBump',
            task: () =>
                _dispatchNpcFixedRouteContact(id, entry, attempt.direction),
          );
        }
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

  Future<void> _dispatchNpcFixedRouteContact(
    String entityId,
    _NpcFixedRouteRuntimeEntry entry,
    EntityFacing direction,
  ) async {
    final activation = _currentMapActivationId;
    final player = _world.player;
    final actor = _loadedMapsById[_activeMapId]?.npcActorByEntityId[entityId];
    final position = _world.map.entities
        .where((entity) => entity.id == entityId)
        .firstOrNull
        ?.pos;
    bool applicable() =>
        !_isRemoved &&
        !_player.isStepping &&
        activation == _currentMapActivationId &&
        _activeMapId == entry.scope.mapId &&
        _battleRuntimeGameState.mapInstanceWorldState.instanceRef(
              _activeMapId,
            ) ==
            entry.scope &&
        identical(_npcFixedRoutes[entityId], entry) &&
        identical(
          _loadedMapsById[_activeMapId]?.npcActorByEntityId[entityId],
          actor,
        ) &&
        actor != null &&
        !actor.isRemoved &&
        !actor.isStepping &&
        _npcFixedRouteVariant(entityId)?.id == entry.variantId &&
        _npcFixedRouteVariant(entityId)?.startsOnNpcContact == true &&
        _world.map.entities
                .where((entity) => entity.id == entityId)
                .firstOrNull
                ?.pos ==
            position &&
        _world.player.playerPositionPx == player.playerPositionPx &&
        npcFixedRouteTouchesPlayer(
          world: _world,
          entityId: entityId,
          direction: direction,
          dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
            ignoreEntityId: entityId,
          ),
          characterReservations: [
            for (final item
                in _scriptedNpcReservedOccupiedCellsByEntity.entries)
              if (item.key != entityId && item.value.contactRect != null)
                item.value.contactRect!,
          ],
        );
    if (!applicable()) return;
    await _dispatchSpatialOccurrence(
      occurrence: NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.entityBump(_activeMapId, entityId),
      ),
      legacyFallback: (_) async {},
      contactIsApplicable: applicable,
    );
  }

  void _stabilizeAutonomousNpcBump(MoveIntent intent) {
    for (final item in _npcFixedRoutes.entries.toList(growable: false)) {
      if (item.value.pendingMotion == null) continue;
      final contact = resolvePlayerEntityBumpContact(
        _world,
        intent.direction,
        attemptedPixelsPerStep: intent.pixelsPerStep,
        characterReservations: [
          for (final reservation
              in _scriptedNpcReservedOccupiedCellsByEntity.entries)
            if (reservation.key != item.key &&
                reservation.value.contactRect != null)
              reservation.value.contactRect!,
        ],
      );
      if (contact?.entityId == item.key) _interruptNpcFixedRoute(item.key);
    }
  }
}
