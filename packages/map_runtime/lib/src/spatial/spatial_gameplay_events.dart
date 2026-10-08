import 'dart:async';
import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../application/battle_start_request.dart';
import '../application/encounter_to_battle_request.dart';
import '../application/global_story_chapter_runtime.dart';
import '../application/map_activation.dart';
import '../application/map_enter_production_dispatch_bridge.dart';
import '../application/map_entity_runtime_predicate_evaluator.dart';
import '../application/narrative_event_runtime_snapshot.dart';
import '../application/narrative_runtime_activity_gate.dart';
import '../application/narrative_runtime_activity_port.dart';
import '../application/narrative_scene_runtime_execution.dart';
import '../application/narrative_spatial_production_dispatch_bridge.dart';
import '../application/npc_runtime_presence.dart';
import '../application/scene_runtime/scene_consequence_runtime_writer.dart';
import '../application/scene_runtime/scene_runtime_host_callbacks.dart';
import '../application/step_studio_world_presence_runtime.dart';
import '../application/world_rules/runtime_world_rule_projection_hook.dart';

typedef SpatialSceneCallbackFactory = SceneRuntimeHostCallbacks Function(
  GameState Function() readSceneState,
  void Function(GameState state) commitSceneState,
);

typedef SpatialLegacyEventFallback = Future<GameState?> Function(
  NarrativeEventOccurrence occurrence,
  GameState state,
);

final Object _spatialHostEffectsZoneKey = Object();
final Object _spatialOperationZoneKey = Object();

typedef SpatialSceneConsequenceWriterFactory
    = Future<SceneConsequenceRuntimeWriter> Function(
  GameState state,
  String sceneId,
);

final class SpatialGameplayEvents {
  SpatialGameplayEvents._({
    required this.project,
    required this.mapsById,
    required NarrativeEventRuntimeSnapshot narrativeSnapshot,
    required GameState Function() readGameState,
    required void Function(GameState) commitGameState,
    required SpatialSceneCallbackFactory createSceneCallbacks,
    required Future<void> Function(MapEntity, DialogueRef) showEntityDialogue,
    required Future<void> Function(WildBattleStartRequest) startWildBattle,
    required this.activityGate,
    required bool Function() isActive,
    required bool Function() canProcessInput,
    required String Function(String prefix) runtimeIdFactory,
    required Random random,
    required DateTime Function() now,
    SpatialLegacyEventFallback? legacyFallback,
    SpatialSceneConsequenceWriterFactory? buildSceneConsequenceWriter,
    Future<void> Function(GameState)? afterStateCommitted,
  })  : _snapshot = narrativeSnapshot,
        _readGameState = readGameState,
        _commitGameState = commitGameState,
        _createSceneCallbacks = createSceneCallbacks,
        _showEntityDialogue = showEntityDialogue,
        _startWildBattle = startWildBattle,
        _isActive = isActive,
        _canProcessInput = canProcessInput,
        _runtimeIdFactory = runtimeIdFactory,
        _random = random,
        _now = now,
        _legacyFallback = legacyFallback,
        _buildSceneConsequenceWriter = buildSceneConsequenceWriter,
        _afterStateCommitted = afterStateCommitted,
        _transactions = NarrativeEventStateTransactions(readGameState()),
        _chapterIndex = buildGlobalStoryChapterStepIndex(project.scenarios),
        _battleContracts = buildBattlePublicContracts(project),
        _presenceRules =
            buildStepStudioWorldPresenceRuleList(project.scenarios) {
    final activity = NarrativeRuntimeActivityPort(activityGate);
    _mapEnter = MapEnterProductionDispatchBridge(
      stateTransactions: _transactions,
      currentGameState: _readGameState,
      onGameStateCommitted: _commit,
      prepareAuthority: (_, occurrence) async => _prepareAuthority(occurrence),
      executeScene: _executeScene,
      legacyFallback: (_, occurrence, state) => _fallback(occurrence, state),
      activityPort: activity,
      beforeSaveRestoreDispatch: (_) => _drainOutcomes(),
      isCurrentActivation: (id) =>
          _currentOperation && _activation?.activationId == id,
      executionIdFactory: () => _runtimeIdFactory('evx'),
      correlationIdFactory: () => _runtimeIdFactory('corr'),
      deliveryIdFactory: () => _runtimeIdFactory('outd'),
    );
    _spatial = NarrativeSpatialProductionDispatchBridge(
      stateTransactions: _transactions,
      currentGameState: _readGameState,
      onGameStateCommitted: _commit,
      prepareAuthority: (_, occurrence) async => _prepareAuthority(occurrence),
      executeScene: _executeScene,
      legacyFallback: (_, occurrence, state) => _fallback(occurrence, state),
      activityPort: activity,
      isCurrentOccurrence: (id) =>
          _currentOperation && _occurrences.contains(id),
      executionIdFactory: () => _runtimeIdFactory('evx'),
      correlationIdFactory: () => _runtimeIdFactory('corr'),
      deliveryIdFactory: () => _runtimeIdFactory('outd'),
    );
    _outbox = NarrativeOutcomeOutboxProcessor(
      stateTransactions: _transactions,
      dispatcher: _dispatchOutcome,
      activityPort: activity,
      deliveryIdFactory: () => _runtimeIdFactory('outd'),
    );
  }

  static Future<SpatialGameplayEvents> create({
    required ProjectManifest project,
    required Map<String, MapData> mapsById,
    required GameState Function() readGameState,
    required void Function(GameState) commitGameState,
    required SpatialSceneCallbackFactory createSceneCallbacks,
    required Future<void> Function(MapEntity, DialogueRef) showEntityDialogue,
    required Future<void> Function(WildBattleStartRequest) startWildBattle,
    required NarrativeRuntimeActivityGate activityGate,
    required bool Function() isActive,
    required bool Function() canProcessInput,
    required String Function(String prefix) runtimeIdFactory,
    SpatialLegacyEventFallback? legacyFallback,
    SpatialSceneConsequenceWriterFactory? buildSceneConsequenceWriter,
    Future<void> Function(GameState)? afterStateCommitted,
    NarrativeEventRuntimeSnapshot? narrativeSnapshot,
    Random? random,
    DateTime Function()? now,
  }) async {
    if (project.settings.dimension != ProjectDimension.threeD) {
      throw ArgumentError('Spatial gameplay requires a 3D project.');
    }
    final maps = Map<String, MapData>.unmodifiable(mapsById);
    for (final entry in project.maps) {
      final map = maps[entry.id];
      if (map == null || map.id != entry.id || map.spatialScene == null) {
        throw StateError('Spatial gameplay map "${entry.id}" is unavailable.');
      }
    }
    final snapshot = narrativeSnapshot ??
        await NarrativeEventRuntimeSnapshot.build(
          project: project,
          loadMap: (id) async => (project: project, map: maps[id]!),
        );
    if (!snapshot.matchesProject(project)) {
      throw StateError(
          'Spatial narrative snapshot belongs to another project.');
    }
    return SpatialGameplayEvents._(
      project: project,
      mapsById: maps,
      narrativeSnapshot: snapshot,
      readGameState: readGameState,
      commitGameState: commitGameState,
      createSceneCallbacks: createSceneCallbacks,
      showEntityDialogue: showEntityDialogue,
      startWildBattle: startWildBattle,
      activityGate: activityGate,
      isActive: isActive,
      canProcessInput: canProcessInput,
      runtimeIdFactory: runtimeIdFactory,
      legacyFallback: legacyFallback,
      buildSceneConsequenceWriter: buildSceneConsequenceWriter,
      afterStateCommitted: afterStateCommitted,
      random: random ?? Random(),
      now: now ?? DateTime.now,
    );
  }

  final ProjectManifest project;
  final Map<String, MapData> mapsById;
  final NarrativeRuntimeActivityGate activityGate;
  final NarrativeEventRuntimeSnapshot _snapshot;
  final GameState Function() _readGameState;
  final void Function(GameState) _commitGameState;
  final SpatialSceneCallbackFactory _createSceneCallbacks;
  final Future<void> Function(MapEntity, DialogueRef) _showEntityDialogue;
  final Future<void> Function(WildBattleStartRequest) _startWildBattle;
  final bool Function() _isActive;
  final bool Function() _canProcessInput;
  final String Function(String) _runtimeIdFactory;
  final Random _random;
  final DateTime Function() _now;
  final SpatialLegacyEventFallback? _legacyFallback;
  final SpatialSceneConsequenceWriterFactory? _buildSceneConsequenceWriter;
  final Future<void> Function(GameState)? _afterStateCommitted;
  final NarrativeEventStateTransactions _transactions;
  final GlobalStoryChapterStepIndex _chapterIndex;
  final List<BattlePublicContract> _battleContracts;
  final List<StepStudioWorldPresenceRule> _presenceRules;
  late final MapEnterProductionDispatchBridge _mapEnter;
  late final NarrativeSpatialProductionDispatchBridge _spatial;
  late final NarrativeOutcomeOutboxProcessor _outbox;
  Future<void> _tail = Future<void>.value();
  MapActivation? _activation;
  GridPos? _lastCell;
  Iterable<String>? _occupiedTriggers;
  final Set<String> _occurrences = {};
  int _generation = 0;
  int? _operationGeneration;
  int _pendingOperations = 0;
  bool _disposed = false;
  bool _hostEffectsPending = false;
  final Set<String> _publishedBattleAttemptIds = {};
  Map<String, NarrativeOutcomeRef>? _sceneBattleAttempts;
  List<NarrativeOutcomeRef>? _sceneBattleOutcomes;

  bool get isBusy => _pendingOperations > 0;
  bool get _available => !_disposed && _isActive();
  bool get _currentOperation =>
      _available && _operationGeneration == _generation;
  bool get _inputAllowed =>
      _available &&
      !isBusy &&
      _canProcessInput() &&
      !activityGate.checkpointInProgress &&
      activityGate.activity == NarrativeRuntimeActivity.idle;

  MapData get _map {
    final state = _readGameState();
    final map = mapsById[state.currentMapId];
    if (map == null) {
      throw StateError('Active spatial gameplay map is unavailable.');
    }
    return map;
  }

  Future<void> activateMap(MapActivation activation) async {
    if (!_available) return;
    if (_activation == activation) return;
    if (activation.mapId != _readGameState().currentMapId) {
      throw StateError(
          'Map activation does not match the authoritative state.');
    }
    _activation = activation;
    _generation++;
    _occurrences.clear();
    _lastCell = _readGameState().playerPosition;
    _occupiedTriggers = resolveNarrativeTriggerEnterFronts(
      map: _map,
      currentPosition: _lastCell!,
      previousOccupiedTriggerIds: null,
    ).currentOccupiedTriggerIds;
    await _run<void>(() async {
      final result = await _mapEnter.dispatchCompletedActivation(activation);
      if (!_currentOperation) return;
      if (result is MapEnterProductionDispatchFailed) {
        throw StateError('Map enter failed: ${result.failure}');
      }
      if (result is MapEnterProductionDispatchAuthorityBlocked) {
        throw StateError(
            'Map enter authority blocked: ${result.authority.reason.name}: ${result.authority.diagnostics.join('; ')}');
      }
      await _settle();
    });
  }

  MapEntity? get interactionTarget {
    if (!_inputAllowed) return null;
    final state = _readGameState();
    final position = state.playerSpatialPosition;
    if (position == null) return null;
    final map = _map;
    return findSpatialEntityInteraction(
      scene: map.spatialScene!,
      entities: map.entities.where((entity) => entityIsPresent(map.id, entity)),
      actorStateProvider: (id) =>
          state.spatialWorldState.actorState(map.id, id),
      x: position.x,
      z: position.z,
      facing: state.playerFacing,
    );
  }

  bool entityIsPresent(String mapId, MapEntity entity) {
    final map = mapsById[mapId];
    if (map == null) return false;
    final state = _readGameState();
    final present = isNpcRuntimePresentOnMap(
      gameState: state,
      manifest: project,
      stepStudioWorldRules: _presenceRules,
      mapId: mapId,
      entity: entity,
      chapterIndex: _chapterIndex,
    );
    return const RuntimeWorldRuleProjectionHook()
        .resolve(
          project: project,
          gameState: state,
          map: map,
        )
        .isMapEntityVisible(entity, defaultVisible: present);
  }

  SpatialModelInstance? get modelInteractionTarget {
    if (!_inputAllowed) return null;
    final state = _readGameState();
    final position = state.playerSpatialPosition;
    if (position == null) return null;
    final map = _map;
    final ids = <String>{};
    for (final record
        in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
      if (record.enabledOrNull != true) continue;
      final id = record.definitionOrNull?.source.when<String?>(
        modelInteract: (mapId, instanceId) =>
            mapId == map.id ? instanceId : null,
        entityInteract: (mapId, entityId) => null,
        triggerEnter: (mapId, triggerId) => null,
        mapEnter: (mapId) => null,
        outcomeReceived: (outcome) => null,
      );
      if (id != null) ids.add(id);
    }
    return findSpatialModelInteraction(
        scene: map.spatialScene!,
        models: project.models3d,
        instances: map.spatialScene!.instances
            .where((instance) => ids.contains(instance.id)),
        x: position.x,
        z: position.z,
        facing: state.playerFacing);
  }

  Future<NarrativeSpatialProductionDispatchResult?> interact() {
    final entity = interactionTarget;
    final model = entity == null ? modelInteractionTarget : null;
    if (entity == null && model == null) return Future.value();
    final mapId = _map.id;
    return _run(() async {
      final result = await _dispatchSpatial(NarrativeEventOccurrence(
        source: entity != null
            ? NarrativeEventSourceRef.entityInteract(mapId, entity.id)
            : NarrativeEventSourceRef.modelInteract(mapId, model!.id),
      ));
      await _settle();
      return result;
    });
  }

  Future<GameplayEncounterCheckResult?> playerEnteredCell({
    required GridPos previousPosition,
    required GridPos currentPosition,
    EncounterKind encounterKind = EncounterKind.walk,
  }) {
    if (!_inputAllowed ||
        _activation == null ||
        previousPosition == currentPosition ||
        _lastCell == currentPosition) {
      return Future.value();
    }
    final state = _readGameState();
    if (_lastCell != previousPosition ||
        currentPosition != state.playerPosition ||
        _activation!.mapId != state.currentMapId) {
      throw StateError('Cell entry does not match spatial navigation.');
    }
    state.playerSpatialPosition?.validateGridPosition(currentPosition);
    _lastCell = currentPosition;
    final fronts = resolveNarrativeTriggerEnterFronts(
      map: _map,
      currentPosition: currentPosition,
      previousOccupiedTriggerIds: _occupiedTriggers,
    );
    _occupiedTriggers = fronts.currentOccupiedTriggerIds;
    final mapId = _map.id;
    return _run<GameplayEncounterCheckResult?>(() async {
      for (final triggerId in fronts.enteredTriggerIds) {
        await _dispatchSpatial(NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.triggerEnter(mapId, triggerId),
        ));
        await _settle();
        _ensureCurrent();
      }
      if (!_canProcessInput() ||
          _readGameState().currentMapId != mapId ||
          _readGameState().playerPosition != currentPosition) {
        return null;
      }
      final world = projectWorld();
      final check = checkEncounterAtPlayerPosition(
        world: world,
        project: project,
        encounterKind: encounterKind,
        gameState: _readGameState(),
        random: _random,
      );
      final encounter = check.encounter;
      if (check.triggered && encounter != null) {
        await _startWildBattle(buildBattleStartRequestFromEncounter(
          encounter: encounter,
          world: world,
          createdAtEpochMs: _now().millisecondsSinceEpoch,
        ));
        _ensureCurrent();
      }
      return check;
    });
  }

  GameplayWorldState projectWorld() {
    final state = _readGameState();
    final position = state.playerSpatialPosition;
    if (position == null) {
      throw StateError('Spatial gameplay requires a continuous position.');
    }
    position.validateGridPosition(state.playerPosition);
    final map = _map;
    final settings = project.settings;
    const width = PlayerCollisionConventionsV1.defaultSpriteWidthPx;
    const height = PlayerCollisionConventionsV1.defaultSpriteHeightPx;
    final player = GameplayPlayerState(
      pos: state.playerPosition,
      facing: state.playerFacing.asDirection,
      playerPositionPx: PixelPosition(
        leftPx: (position.x * settings.tileWidth).floor() - width ~/ 2,
        topPx: (position.z * settings.tileHeight).floor() - height + 1,
      ),
    );
    return GameplayWorldState.initial(
      map: map,
      project: project,
      playerPos: state.playerPosition,
      playerFacing: player.facing,
      tileWidth: settings.tileWidth,
      tileHeight: settings.tileHeight,
      mapEntityPresencePredicate: entityIsPresent,
    ).withPlayer(player);
  }

  Future<void> drainPendingOutcomes() async {
    if (!_available || isBusy) return;
    await _run<void>(() async {
      await _transactions.transact<void>(
          (_) => NarrativeEventStateTransaction.commit(_readGameState(), null));
      await _settle();
    });
  }

  Future<bool> publishBattleOutcome({
    required BattleStartRequest request,
    required String outcomeId,
  }) async {
    if (!_available) return false;
    if (request.requestId.isEmpty ||
        request.requestId.trim() != request.requestId) {
      throw ArgumentError(
          'Narrative battle publication requires an exact attempt id.');
    }
    final trainerId = switch (request) {
      TrainerBattleStartRequest(:final trainerId) => trainerId,
      StaticBattleStartRequest(:final opponentProfileId) => opponentProfileId,
      WildBattleStartRequest() => null,
    };
    if (trainerId == null) return false;
    final kind = request.kind == RuntimeBattleKind.staticEncounter
        ? BattlePublicContractKind.staticEncounter
        : BattlePublicContractKind.trainer;
    final contracts = _battleContracts
        .where((contract) =>
            contract.trainerId == trainerId && contract.battleKind == kind)
        .toList(growable: false);
    if (contracts.length != 1 ||
        contracts.single.status != LinkedAssetContractStatus.available ||
        !contracts.single.possibleOutcomes
            .any((outcome) => outcome.id == outcomeId)) {
      return false;
    }
    if (_publishedBattleAttemptIds.contains(request.requestId)) return false;
    final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: contracts.single.battleRefId,
        outcomeId: outcomeId);
    final sceneAttempts = _sceneBattleAttempts;
    if (sceneAttempts != null) {
      _ensureCurrent();
      final previous = sceneAttempts[request.requestId];
      if (previous != null) {
        if (previous != outcome) {
          throw StateError(
              'One battle attempt cannot produce two narrative results.');
        }
        return false;
      }
      sceneAttempts[request.requestId] = outcome;
      _sceneBattleOutcomes!.add(outcome);
      return true;
    }
    Future<bool> publish() async {
      _ensureCurrent();
      if (_publishedBattleAttemptIds.contains(request.requestId)) return false;
      final updated = await _transactions.transact<GameState>((_) {
        final state = _readGameState();
        final progress = state.narrativeEventProgress;
        final next = state.copyWith(
            narrativeEventProgress: progress.copyWith(
          pendingNarrativeOutcomeDeliveries: [
            ...progress.pendingNarrativeOutcomeDeliveries,
            NarrativeOutcomeDelivery(
                deliveryId: _runtimeIdFactory('outd'),
                outcome: outcome,
                causationExecutionId: _runtimeIdFactory('evx'),
                rootCorrelationId: _runtimeIdFactory('corr'),
                depth: 0,
                attemptCount: 0),
          ],
        ));
        return NarrativeEventStateTransaction.commit(next, next);
      });
      _ensureCurrent();
      _publishedBattleAttemptIds.add(request.requestId);
      _commit(updated);
      await _settle();
      return true;
    }

    if (_currentOperation &&
        identical(Zone.current[_spatialOperationZoneKey], this)) {
      return publish();
    }
    if (isBusy) {
      throw StateError(
          'A narrative operation already owns battle publication.');
    }
    return await _run<bool>(publish) ?? false;
  }

  void invalidate() {
    _generation++;
    _activation = null;
    _occurrences.clear();
    _lastCell = null;
    _occupiedTriggers = null;
  }

  void dispose() {
    _disposed = true;
    invalidate();
  }

  Future<T?> _run<T>(Future<T> Function() action) {
    final generation = _generation;
    final lease = activityGate.enter(NarrativeRuntimeActivity.dispatching);
    _pendingOperations++;
    final completer = Completer<T?>();
    Future<void> execute() async {
      final previousGeneration = _operationGeneration;
      _operationGeneration = generation;
      try {
        _ensureCurrent();
        final value = await runZoned(action,
            zoneValues: {_spatialOperationZoneKey: this});
        completer.complete(_currentOperation ? value : null);
      } on _SpatialGameplayCancelled {
        completer.complete();
      } catch (error, stack) {
        completer.completeError(error, stack);
      } finally {
        _operationGeneration = previousGeneration;
        _pendingOperations--;
        lease.close();
      }
    }

    if (identical(Zone.current[_spatialHostEffectsZoneKey], this)) {
      unawaited(execute());
    } else {
      _tail = _tail.then((_) => execute());
    }
    return completer.future;
  }

  void _ensureCurrent() {
    if (!_currentOperation) throw const _SpatialGameplayCancelled();
  }

  void _commit(GameState state) {
    if (!_currentOperation) return;
    _commitGameState(state);
    _hostEffectsPending = true;
  }

  NarrativeEventDispatchAuthorityPreparation _prepareAuthority(
          NarrativeEventOccurrence occurrence) =>
      NarrativeEventDispatchAuthority.prepare(
        registryResult: _snapshot.registryResult,
        occurrence: occurrence,
        factResolver: _snapshot.factResolver,
        legacyClaimIndex: _snapshot.legacyClaimIndex,
        projectCatalog: _snapshot.projectCatalog,
        project: project,
        maps: mapsById.values.toList(growable: false),
      );

  Future<NarrativeSpatialProductionDispatchResult> _dispatchSpatial(
      NarrativeEventOccurrence occurrence) async {
    _ensureCurrent();
    final id = _runtimeIdFactory('spocc');
    _occurrences.add(id);
    try {
      final result =
          await _spatial.dispatch(occurrenceId: id, occurrence: occurrence);
      _ensureCurrent();
      if (result is NarrativeSpatialProductionDispatchFailed) {
        throw StateError('Spatial event failed: ${result.failure}');
      }
      if (result is NarrativeSpatialProductionDispatchAuthorityBlocked) {
        throw StateError(
            'Spatial event authority blocked: ${result.authority.reason.name}: ${result.authority.diagnostics.join('; ')}');
      }
      return result;
    } finally {
      _occurrences.remove(id);
    }
  }

  Future<NarrativeSceneExecutionResult> _executeScene(
      NarrativeSceneExecutionRequest request) async {
    final generation = _operationGeneration;
    var workingState = request.gameState;
    bool current() => _currentOperation && _operationGeneration == generation;
    final writer = await _buildSceneConsequenceWriter?.call(
            workingState, request.sceneId) ??
        SceneConsequenceRuntimeWriter(project: project, mapsById: mapsById);
    if (!current()) {
      return NarrativeSceneExecutionResult.cancelled(
          'Spatial activation changed while preparing scene.');
    }
    if (_sceneBattleAttempts != null) {
      return NarrativeSceneExecutionResult.failed(
          StateError('A spatial scene already owns battle returns.'));
    }
    final attempts = _sceneBattleAttempts = <String, NarrativeOutcomeRef>{};
    final outcomes = _sceneBattleOutcomes = <NarrativeOutcomeRef>[];
    try {
      final callbacks = _createSceneCallbacks(
        () => workingState,
        (state) {
          if (current()) workingState = state;
        },
      );
      SceneRuntimeIntentCallback guard(SceneRuntimeIntentCallback callback) =>
          (intent) async {
            if (!current()) throw const _SpatialGameplayCancelled();
            final result = await callback(intent);
            if (!current()) throw const _SpatialGameplayCancelled();
            return result;
          };
      final result = await executeNarrativeEventScene(
        request: request,
        project: project,
        mapsById: mapsById,
        currentGameState: () => workingState,
        consequenceWriter: writer,
        hostedBattleOutcomes: outcomes,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: guard(callbacks.evaluateCondition),
          showDialogue: guard(callbacks.showDialogue),
          startBattle: guard(callbacks.startBattle),
          playCinematic: guard(callbacks.playCinematic),
          playPresentationCinematic: callbacks.playPresentationCinematic == null
              ? null
              : guard(callbacks.playPresentationCinematic!),
          executeInteractiveCommand: callbacks.executeInteractiveCommand == null
              ? null
              : guard(callbacks.executeInteractiveCommand!),
          requestStructuredInteraction:
              callbacks.requestStructuredInteraction == null
                  ? null
                  : guard(callbacks.requestStructuredInteraction!),
        ),
      );
      if (!current()) {
        return NarrativeSceneExecutionResult.cancelled(
            'Spatial activation changed during scene.');
      }
      if (result is NarrativeSceneExecutionCompleted && attempts.isNotEmpty) {
        final deferred = _transactions.deferAfterCurrentCommit((_) {
          if (current()) _publishedBattleAttemptIds.addAll(attempts.keys);
        });
        if (!deferred) {
          return NarrativeSceneExecutionResult.failed(StateError(
              'Scene battle publication requires the scene transaction.'));
        }
      }
      return result;
    } finally {
      if (identical(_sceneBattleAttempts, attempts)) {
        _sceneBattleAttempts = null;
        _sceneBattleOutcomes = null;
      }
    }
  }

  Future<void> _fallback(
      NarrativeEventOccurrence occurrence, GameState state) async {
    _ensureCurrent();
    final fallback = _legacyFallback;
    if (fallback != null) {
      final updated = await fallback(occurrence, state);
      _ensureCurrent();
      if (updated != null) {
        await _transactions.transact<void>(
            (_) => NarrativeEventStateTransaction.commit(updated, null));
        _ensureCurrent();
        _commit(updated);
      }
      return;
    }
    final source = occurrence.source.when(
      modelInteract: (mapId, instanceId) => null,
      entityInteract: (mapId, entityId) => (mapId: mapId, entityId: entityId),
      triggerEnter: (_, __) => null,
      mapEnter: (_) => null,
      outcomeReceived: (_) => null,
    );
    if (source == null) return;
    final map = mapsById[source.mapId]!;
    final entity =
        map.entities.where((entity) => entity.id == source.entityId).single;
    final projection = const RuntimeWorldRuleProjectionHook()
        .resolve(project: project, gameState: state, map: map);
    final override = projection.dialogueOverrideForEntity(entity.id);
    final dialogue = override == null
        ? entity.npc == null
            ? entity.sign?.dialogue
            : MapEntityRuntimePredicateEvaluator(
                    gameState: state, chapterIndex: _chapterIndex)
                .resolveNpcDialogue(entity.npc!)
        : DialogueRef(dialogueId: override);
    if (dialogue != null) {
      await _showEntityDialogue(entity, dialogue);
      _ensureCurrent();
    }
  }

  Future<void> _settle() async {
    _ensureCurrent();
    await _flushHostEffects();
    await _drainOutcomes();
    _ensureCurrent();
    await _flushHostEffects();
  }

  Future<void> _flushHostEffects() async {
    if (_hostEffectsPending) {
      _hostEffectsPending = false;
      await runZoned(
        () async => _afterStateCommitted?.call(_readGameState()),
        zoneValues: {_spatialHostEffectsZoneKey: this},
      );
      _ensureCurrent();
      await _transactions.transact<void>(
        (_) => NarrativeEventStateTransaction.commit(_readGameState(), null),
      );
      _ensureCurrent();
    }
  }

  Future<void> _drainOutcomes() async {
    while (_currentOperation) {
      final result = await _outbox.processNext();
      _ensureCurrent();
      switch (result) {
        case NarrativeOutcomeOutboxEmpty():
          return;
        case NarrativeOutcomeOutboxBusy():
          throw StateError('Spatial narrative outbox is already processing.');
        case NarrativeOutcomeOutboxRetryScheduled(
            :final updatedGameState,
            :final failure
          ):
          _commit(updatedGameState);
          throw StateError(
              'Spatial narrative outcome remains pending: $failure');
        case NarrativeOutcomeOutboxDelivered(:final updatedGameState) ||
              NarrativeOutcomeOutboxTerminalized(:final updatedGameState) ||
              NarrativeOutcomeOutboxDataInconsistency(:final updatedGameState):
          _commit(updatedGameState);
      }
    }
  }

  Future<NarrativeOutcomeDispatchResult> _dispatchOutcome(
      NarrativeOutcomeDispatchRequest request) async {
    if (!_currentOperation) {
      return NarrativeOutcomeDispatchResult.infrastructureFailureBeforePlanning(
          const _SpatialGameplayCancelled());
    }
    final preparation = _prepareAuthority(request.occurrence);
    if (preparation is NarrativeEventDispatchAuthorityBlocked) {
      return NarrativeOutcomeDispatchResult.infrastructureFailureBeforePlanning(
          preparation);
    }
    final authority = preparation as NarrativeEventDispatchAuthorityReady;
    final execution = await NarrativeEventExecutionCoordinator(
      stateTransactions: _transactions,
      planner: NarrativeEventDispatchPlanner(),
      executeScene: _executeScene,
      activityPort: NarrativeRuntimeActivityPort(activityGate),
      executionIdFactory: () => _runtimeIdFactory('evx'),
      correlationIdFactory: () => _runtimeIdFactory('corr'),
      deliveryIdFactory: () => _runtimeIdFactory('outd'),
      beforePlan: (state) => authority.applyOutcomeReset(
          gameState: state,
          deliveryId: request.delivery.deliveryId,
          outcome: request.delivery.outcome),
    ).execute(authority: authority);
    if (!_currentOperation) {
      return NarrativeOutcomeDispatchResult.infrastructureFailureBeforePlanning(
          const _SpatialGameplayCancelled());
    }
    if (execution is NarrativeEventExecutionSucceeded) {
      return NarrativeOutcomeDispatchResult.delivered(
          updatedGameState: execution.updatedGameState,
          causationExecutionId: execution.executionId);
    }
    if (execution is NarrativeEventExecutionFailed) {
      return NarrativeOutcomeDispatchResult.terminalFailure(execution.failure);
    }
    if (execution is NarrativeEventExecutionCancelled) {
      return NarrativeOutcomeDispatchResult.terminalFailure(
          execution.reason ?? 'Spatial outcome scene was cancelled.');
    }
    return NarrativeOutcomeDispatchResult.delivered(
        updatedGameState: await _transactions.read());
  }
}

final class _SpatialGameplayCancelled implements Exception {
  const _SpatialGameplayCancelled();
}
