part of 'playable_map_game.dart';

final class _ParallelCycleCancelled implements Exception {
  const _ParallelCycleCancelled();
}

extension _PlayableMapGameParallelEvents on PlayableMapGame {
  bool get _parallelSuspended =>
      _isRemoved ||
      !isLoaded ||
      _parallelLifecycleSuspended ||
      isPaused ||
      _onLoadInProgress ||
      !_canResolveOverworldInteraction() ||
      _hasCheckpointUnsafeRuntimeWorkForSave ||
      _dialogueOverlay != null ||
      _activeNarrativeSceneWorkingSession != null;

  void _prepareParallelPrograms() {
    final project = _bundle.manifest;
    if (identical(_parallelProgramProject, project)) {
      return;
    }
    _parallelProgramProject = project;
    _parallelDefinitionsByMap.clear();
    _parallelPrograms.clear();
    _parallelFaultedOwners.clear();
    _parallelScheduler.clear();
    if (project.settings.dimension != ProjectDimension.twoD) {
      return;
    }
    for (final record
        in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
      final definition = record.definitionOrNull;
      if (definition == null || definition.parallelPolicy == null) {
        continue;
      }
      final mapId = definition.source.toJson()['mapId'] as String?;
      if (mapId == null) {
        continue;
      }
      final scenes = project.scenes
          .where((scene) => scene.id == definition.sceneId)
          .toList();
      if (scenes.length != 1) {
        continue;
      }
      try {
        _parallelPrograms[definition.id] = NarrativeParallelProgram.compile(
          scenes.single,
          ownerMapId: mapId,
        );
        _parallelDefinitionsByMap.putIfAbsent(mapId, () => []).add(definition);
      } on Object catch (error) {
        debugPrint(
          '[event_v2] parallel rejected event=${definition.id}: $error',
        );
      }
    }
  }

  NarrativeParallelOwner? _parallelOwner(
    NarrativeEventDefinition definition,
    GameState state,
  ) {
    final activationId = _currentMapActivationId;
    if (activationId == null ||
        definition.source.toJson()['mapId'] != _activeMapId) {
      return null;
    }
    final policy = definition.parallelPolicy!;
    String? variantId;
    if (definition.source.kind == NarrativeEventSourceKind.entityAutorun) {
      final entityId = definition.source.toJson()['entityId'];
      final entities = _bundle.map.entities
          .where((entity) => entity.id == entityId)
          .toList();
      if (entities.length != 1) {
        return null;
      }
      final entity = entities.single;
      if (!_mapEntityPresencePredicateFor(
        _bundle.manifest,
        gameStateOverride: state,
      )(_activeMapId, entity)) {
        return null;
      }
      if (entity.presentation != null) {
        variantId = resolveMapEntityPresentation(
          project: _bundle.manifest,
          gameState: state,
          map: _bundle.map,
          entity: entity,
          maps:
              _cachedNarrativeRuntimeSnapshot?.mapsById.values.toList() ??
              const [],
        )?.id;
        if (variantId == null) {
          return null;
        }
      }
      if (policy.ownerVariantId != null && policy.ownerVariantId != variantId) {
        return null;
      }
    }
    return NarrativeParallelOwner(
      mapActivationId: activationId,
      mapInstanceId: state.mapInstanceWorldState
          .instanceRef(_activeMapId)
          ?.instanceId,
      eventId: definition.id,
      variantId: variantId,
      policy: policy,
    );
  }

  void _updateParallelEvents(double dt) {
    if (_isRemoved || !isLoaded) {
      return;
    }
    _prepareParallelPrograms();
    final definitions =
        _parallelDefinitionsByMap[_activeMapId] ??
        const <NarrativeEventDefinition>[];
    if (definitions.isEmpty) {
      _parallelFaultedOwners.clear();
      _parallelScheduler.clear();
      return;
    }
    final state = gameStateSnapshot;
    final owners = [
      for (final definition in definitions) ?_parallelOwner(definition, state),
    ];
    final currentOwners = owners.toSet();
    _parallelFaultedOwners.removeWhere(
      (owner) => !currentOwners.contains(owner),
    );
    _parallelScheduler.reconcile(
      owners.where((owner) => !_parallelFaultedOwners.contains(owner)),
    );
    final due = _parallelScheduler.advance(
      dt,
      suspended: _parallelSuspended || _parallelDrainFuture != null,
    );
    if (due.isEmpty || _parallelDrainFuture != null) {
      return;
    }
    final future = _drainParallelEvents(due);
    _parallelDrainFuture = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_parallelDrainFuture, future)) {
          _parallelDrainFuture = null;
        }
      }),
    );
  }

  Future<void> _drainParallelEvents(List<NarrativeParallelOwner> owners) async {
    for (final owner in owners) {
      try {
        await _narrativeStateTransactions.transact<void>((queuedState) {
          if (_parallelSuspended ||
              owner.mapActivationId != _currentMapActivationId) {
            return NarrativeEventStateTransaction.rollback(null);
          }
          final definitions =
              _parallelDefinitionsByMap[_activeMapId] ??
              const <NarrativeEventDefinition>[];
          final matching = definitions
              .where((definition) => definition.id == owner.eventId)
              .toList();
          if (matching.length != 1) {
            return NarrativeEventStateTransaction.rollback(null);
          }
          final definition = matching.single;
          final state = _captureGameStateFromWorld(baseState: queuedState);
          if (_parallelOwner(definition, state) != owner) {
            return NarrativeEventStateTransaction.rollback(null);
          }
          final authority = _readInteractionAuthority(
            NarrativeEventOccurrence(source: definition.source),
          );
          if (authority is! NarrativeEventDispatchAuthorityReady ||
              authority.plan(gameState: state, parallelEventId: definition.id)
                  is! NarrativeEventDispatchHandled) {
            return NarrativeEventStateTransaction.rollback(null);
          }
          final snapshot = _cachedNarrativeRuntimeSnapshot;
          final program = _parallelPrograms[definition.id];
          if (snapshot == null ||
              program == null ||
              !snapshot.matchesProject(_bundle.manifest)) {
            return NarrativeEventStateTransaction.rollback(null);
          }
          final next = executeNarrativeParallelProgram(
            scene: program.scene,
            program: program,
            gameState: state,
            writer: SceneConsequenceRuntimeWriter(
              project: _bundle.manifest,
              mapsById: snapshot.mapsById,
              itemCatalog: _itemCatalogSnapshot,
              mapInstanceScopes: {
                _activeMapId: ?state.mapInstanceWorldState.instanceRef(
                  _activeMapId,
                ),
              },
            ),
          );
          if (_parallelSuspended ||
              _parallelOwner(definition, state) != owner ||
              next == state) {
            return NarrativeEventStateTransaction.rollback(null);
          }
          _narrativeStateTransactions.deferAfterCurrentCommit((committed) {
            if (_parallelSuspended ||
                owner.mapActivationId != _currentMapActivationId) {
              throw const _ParallelCycleCancelled();
            }
            _applyNarrativeGameState(committed);
          });
          return NarrativeEventStateTransaction.commit(next, null);
        });
      } on _ParallelCycleCancelled {
        continue;
      } on Object catch (error, stackTrace) {
        if (_parallelFaultedOwners.add(owner)) {
          debugPrint(
            '[event_v2] parallel cycle failed event=${owner.eventId}: $error\n$stackTrace',
          );
        }
      }
    }
  }
}
