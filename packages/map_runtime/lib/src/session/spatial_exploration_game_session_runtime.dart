import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_battle/map_battle.dart' show BattleOutcome;
import 'package:path/path.dart' as p;

import '../application/load_runtime_map_bundle.dart';
import '../application/narrative_runtime_activity_gate.dart';
import '../application/player_service_runtime_controller.dart';
import '../application/runtime_map_bundle.dart';
import '../application/battle_start_request.dart';
import '../application/map_activation.dart';
import '../application/narrative_event_runtime_snapshot.dart';
import '../application/scene_runtime/scene_battle_runtime_outcome_result.dart';
import '../application/scene_runtime/scene_consequence_runtime_writer.dart';
import '../application/scene_runtime/scene_interactive_command_runtime_executor.dart';
import '../application/scene_runtime/scene_runtime_host_callbacks.dart';
import '../application/scene_runtime/scene_wild_battle_request.dart';
import '../player/runtime_player_pause_data.dart';
import '../player/runtime_player_pause_data_builder.dart';
import '../player/runtime_player_host.dart';
import '../player/runtime_world_service_models.dart';
import '../application/runtime_overworld_interaction.dart';
import 'runtime_overworld_interaction_port.dart';
import 'package:map_gameplay/map_gameplay.dart';
import '../presentation/flame/runtime_input_authority.dart';
import '../presentation/flame/runtime_input_event.dart';
import '../spatial/spatial_exploration_session.dart';
import '../spatial/spatial_battle_runtime.dart';
import '../spatial/spatial_gameplay_events.dart';
import '../spatial/spatial_scene_callbacks.dart';
import '../presentation/flutter/dialogue_presentation_snapshot.dart';
import 'game_session_contract.dart';
import 'in_process_game_session_adapter.dart';
import 'playable_map_game_session_runtime.dart';
import 'runtime_session_strings.dart';

typedef SpatialExplorationSessionMount = Future<void> Function(
  SpatialExplorationGameSessionRuntime runtime,
);

final class SpatialExplorationGameSessionRuntime
    implements
        InProcessGameSessionRuntime,
        GameSessionInputLockPort,
        RuntimePlayerPauseDataPort,
        RuntimePlayerCompanionMenuPort,
        RuntimePlayerPreferencesPort,
        RuntimePlayerPauseCommandPort,
        RuntimeWorldServicePort,
        RuntimeOverworldInteractionPort {
  SpatialExplorationGameSessionRuntime({
    required this.descriptor,
    required SessionProjectFilePathLoader projectFilePath,
    required SpatialExplorationSessionMount mountSession,
    required SpatialExplorationSessionMount unmountSession,
    SessionInitialSaveLoader? initialSave,
    SessionPreloadedInitialMapLoader? preloadedInitialMap,
    GameSessionCheckpointCommitter? commitCheckpoint,
    PlayerServiceRecoveryCapsLoader? recoveryCapsLoader,
    DateTime Function()? now,
  })  : _projectFilePath = projectFilePath,
        _mountSession = mountSession,
        _unmountSession = unmountSession,
        _initialSave = initialSave,
        _preloadedInitialMap = preloadedInitialMap,
        _commitCheckpoint = commitCheckpoint,
        _recoveryCapsLoader = recoveryCapsLoader,
        _now = now ?? DateTime.now;

  final GameSessionDescriptor descriptor;
  final SessionProjectFilePathLoader _projectFilePath;
  final SpatialExplorationSessionMount _mountSession, _unmountSession;
  final SessionPreloadedInitialMapLoader? _preloadedInitialMap;
  final SessionInitialSaveLoader? _initialSave;
  final GameSessionCheckpointCommitter? _commitCheckpoint;
  final PlayerServiceRecoveryCapsLoader? _recoveryCapsLoader;
  final _activityGate = NarrativeRuntimeActivityGate();
  PlayerServiceRuntimeController? _playerServices;
  StreamSubscription<RuntimeWorldServiceSnapshot?>? _playerServiceSnapshots;
  final _worldServiceSnapshots =
      StreamController<RuntimeWorldServiceSnapshot?>.broadcast();
  RuntimeWorldServiceSnapshot? _worldServiceSnapshot;
  bool _pauseCommandInFlight = false;
  GameState Function()? _sceneStateReader;
  void Function(GameState)? _sceneStateWriter;
  SpatialGameplayEvents? _gameplay;
  SpatialBattleRuntime? _battle;
  SpatialBattleRuntime? get battle => _battle;
  final _runtimeIds = NarrativeEventIdGenerator();
  Map<String, MapData> _mapsById = const {};
  int _gameplayOperations = 0;
  bool _materializingState = false;
  int _transferPauseEpoch = 0;
  Completer<void>? _materializationResumed;
  GridPos? _lastCell;
  Future<void> gameplayReady = Future.value();
  String? _sceneBattleOutcome;
  final DateTime Function() _now;
  final _playWatch = Stopwatch();
  GameState? _gameState;
  DateTime? _createdAt;
  int _basePlayTimeSeconds = 0;
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();
  final _locks = <RuntimeExternalInputLock>{};
  final _pressed = <RuntimeInputControl>{};
  final inputAuthority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
    context: RuntimeInputContext.blocked,
  ));
  SpatialExplorationSession? _session;
  PlayerPreferencesSnapshot? _preferences;
  late final overworldInteractions = ValueNotifier(
      RuntimeOverworldInteractionSnapshot(
          sessionId: descriptor.sessionId,
          mapActivationId: _mapActivationId,
          mapId: 'loading'));
  final _interactionEvents =
      StreamController<RuntimeOverworldInteractionSnapshot?>.broadcast();
  @override
  RuntimeOverworldInteractionSnapshot? get overworldInteractionSnapshot =>
      _session == null ? null : overworldInteractions.value;
  @override
  Stream<RuntimeOverworldInteractionSnapshot?>
      get overworldInteractionSnapshots => _interactionEvents.stream;
  @override
  void applyPlayerPreferences(PlayerPreferencesSnapshot preferences) {
    _preferences = preferences;
    _session?.setTextSpeed(preferences.dialogueTextSpeed);
  }

  String get _mapActivationId =>
      '${descriptor.sessionId}:spatial:${(_session?.mapRevision.value ?? 0) + 1}';
  void _publishInteractions() {
    if (_disposed) return;
    final session = _session;
    if (session == null) return;
    final npc = !inputAuthority.value.acceptsOverworldInput
        ? null
        : _gameplay != null
            ? _gameplay!.interactionTarget
            : findSpatialNpcInteraction(
                scene: session.bundle.map.spatialScene!,
                entities: session.bundle.map.entities,
                x: session.movement.x,
                z: session.movement.z,
                facing: session.movement.facing);
    final snapshot = RuntimeOverworldInteractionSnapshot(
        sessionId: descriptor.sessionId,
        mapActivationId: _mapActivationId,
        mapId: session.bundle.map.id,
        primaryAction: npc == null ||
                (_gameplay == null && npc.npc?.dialogue == null)
            ? null
            : RuntimeOverworldInteractionAction(
                request: RuntimeOverworldInteractionRequest(
                    sessionId: descriptor.sessionId,
                    mapActivationId: _mapActivationId,
                    mapId: session.bundle.map.id,
                    targetKind: RuntimeOverworldInteractionTargetKind.entity,
                    targetId: npc.id,
                    actionId: 'talk'),
                verb: switch (npc.kind) {
                  MapEntityKind.npc => RuntimeOverworldInteractionVerb.talk,
                  MapEntityKind.sign => RuntimeOverworldInteractionVerb.read,
                  MapEntityKind.item => RuntimeOverworldInteractionVerb.collect,
                  _ => RuntimeOverworldInteractionVerb.interact,
                },
                targetCell: npc.pos,
                targetBounds: PixelRect(
                    leftPx:
                        npc.pos.x * session.bundle.manifest.settings.tileWidth,
                    topPx:
                        npc.pos.y * session.bundle.manifest.settings.tileHeight,
                    widthPx: session.bundle.manifest.settings.tileWidth,
                    heightPx: session.bundle.manifest.settings.tileHeight)));
    if (snapshot != overworldInteractions.value) {
      overworldInteractions.value = snapshot;
      _interactionEvents.add(snapshot);
    }
  }

  @override
  bool dispatchOverworldInteraction(
      RuntimeOverworldInteractionRequest request) {
    if (_disposed ||
        _gameplayOperations > 0 ||
        _materializingState ||
        (_gameplay?.isBusy ?? false) ||
        !inputAuthority.value.acceptsOverworldInput) {
      return false;
    }
    _publishInteractions();
    if (request != overworldInteractions.value.primaryAction?.request) {
      return false;
    }
    final gameplay = _gameplay;
    if (gameplay == null) {
      unawaited(_session!.interact());
    } else {
      unawaited(_runGameplay(() async {
        await gameplay.interact();
      }));
    }
    return true;
  }

  bool _mounted = false, _paused = false, _stopped = false, _disposed = false;
  bool _loadingStarted = false;
  int _loadGeneration = 0;
  Future<void>? _mountFuture;

  SpatialExplorationSession? get session => _session;
  GameState get gameStateSnapshot {
    _ensureOpen();
    _syncGameState();
    return _gameState ??
        (throw StateError('The spatial runtime is not loaded.'));
  }

  void _syncGameState() {
    if (_sceneStateReader != null ||
        _materializingState ||
        _gameplayOperations > 0) {
      return;
    }
    final session = _session;
    final state = _gameState;
    if (session == null || state == null) return;
    final movement = session.movement;
    final position = PlayerSpatialPosition(x: movement.x, z: movement.z);
    if (state.currentMapId == session.bundle.map.id &&
        state.playerSpatialPosition == position &&
        state.playerFacing == movement.facing) {
      return;
    }
    _gameState = state.copyWith(
        currentMapId: session.bundle.map.id,
        playerPosition: GridPos(x: position.x.floor(), y: position.z.floor()),
        playerSpatialPosition: position,
        playerFacing: movement.facing);
  }

  void _publishFrame() {
    if (_disposed) return;
    _syncGameState();
    final gameplay = _gameplay;
    final cell = _gameState?.playerPosition;
    if (gameplay != null &&
        cell != null &&
        _lastCell != cell &&
        inputAuthority.value.acceptsOverworldInput) {
      final previous = _lastCell;
      _lastCell = cell;
      final map = _session!.bundle.map;
      if (previous != null &&
          (map.triggers.isNotEmpty || map.gameplayZones.isNotEmpty)) {
        unawaited(_runGameplay(() => gameplay.playerEnteredCell(
            previousPosition: previous, currentPosition: cell)));
      }
    }
    _publishInteractions();
  }

  ValueListenable<DialoguePresentationSnapshot?>
      get dialoguePresentationListenable => _session!.dialoguePresentation;
  void dispatchDialoguePresentationCommand(
      DialoguePresentationCommand command) {
    if (inputAuthority.value.context == RuntimeInputContext.dialogue &&
        inputAuthority.value.acceptsRuntimeInput) {
      _session?.dispatchDialogueCommand(command);
    }
  }

  Future<void> _initializeSpatialGameplay(RuntimeMapBundle bundle, String path,
      {required int generation,
      NarrativeEventRuntimeSnapshot? narrativeSnapshot}) async {
    final project = bundle.manifest;
    final maps = <String, MapData>{bundle.map.id: bundle.map};
    for (final entry in project.maps) {
      if (!maps.containsKey(entry.id)) {
        final loaded = await loadMapDataFromFile(
            p.join(bundle.projectRootDirectory, entry.relativePath),
            projectDialogueContext: project);
        _ensureLoadActive(generation);
        maps[entry.id] = loaded;
      }
    }
    if (!SpatialGameplayCapabilities.requiresGameplay(project,
        maps: maps.values)) {
      return;
    }
    _mapsById = Map.unmodifiable(maps);
    _battle = SpatialBattleRuntime(
        readGameState: _readMutableState,
        commitGameState: (expected, next) {
          if (_disposed || _stopped || _readMutableState() != expected) {
            return false;
          }
          if (_sceneStateWriter case final commit?) {
            commit(next);
          } else {
            _gameState = next;
          }
          return true;
        },
        onCompleted: _battleCompleted,
        onError: (error) {
          if (!_disposed) _session?.interactionError.value = error;
        })
      ..addListener(_syncMovement);
    _gameplay = await SpatialGameplayEvents.create(
        project: project,
        mapsById: _mapsById,
        readGameState: () => _gameState!,
        commitGameState: (state) {
          _ensureGameplayActive();
          _gameState = state;
        },
        createSceneCallbacks: _createSceneCallbacks,
        showEntityDialogue: (entity, ref) async {
          final result = await _session!.showDialogue(ref, entity: entity);
          if (!result.success) throw StateError(result.message!);
        },
        startWildBattle: (request) async {
          await _startBattle(request);
        },
        activityGate: _activityGate,
        isActive: () => !_disposed && !_stopped,
        canProcessInput: () =>
            !_paused &&
            _locks.isEmpty &&
            !(_session?.transitioning.value ?? false) &&
            !(_session?.interactionActive.value ?? false) &&
            !(_battle?.isActive ?? false),
        runtimeIdFactory: (prefix) =>
            '$prefix${_runtimeIds.generate(existingRecords: const []).substring(3)}',
        narrativeSnapshot: narrativeSnapshot,
        afterStateCommitted: _materializeState,
        buildSceneConsequenceWriter: (state, sceneId) async {
          final scene =
              project.scenes.firstWhere((scene) => scene.id == sceneId);
          final needsHealing = scene.graph.nodes.any((node) =>
              node.payload is SceneActionPayload &&
              (node.payload as SceneActionPayload).consequence?.kind ==
                  SceneConsequenceKind.healParty);
          final caps = needsHealing
              ? await (_recoveryCapsLoader?.call(state) ??
                  loadRuntimePlayerServiceRecoveryCaps(
                      gameState: state,
                      projectRootDirectory: bundle.projectRootDirectory,
                      pokemonConfig: project.pokemon))
              : const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {});
          _ensureGameplayActive();
          return SceneConsequenceRuntimeWriter(
              project: project,
              mapsById: _mapsById,
              maxHpByPartyIndex: caps.maxHpByPartyIndex,
              maxPpByPartyIndex: caps.maxPpByPartyIndex);
        });
  }

  GameState _readMutableState() =>
      _sceneStateReader?.call() ?? gameStateSnapshot;

  Future<T> _withSceneState<T>(GameState Function() read,
      void Function(GameState) commit, Future<T> Function() operation) async {
    if (_sceneStateReader != null) {
      throw StateError('A Scene callback is already active.');
    }
    _sceneStateReader = read;
    _sceneStateWriter = commit;
    try {
      return await operation();
    } finally {
      _sceneStateReader = null;
      _sceneStateWriter = null;
    }
  }

  SceneRuntimeHostCallbacks _createSceneCallbacks(
          GameState Function() read, void Function(GameState) commit) =>
      SpatialSceneCallbacks(
        project: _session!.bundle.manifest,
        runtimeSourceId: _mapActivationId,
        readGameState: read,
        show: (request) => _withSceneState(
            read,
            commit,
            () => _session!.showDialogue(DialogueRef(
                dialogueId: request.dialogueId,
                startNode: request.yarnNodeName))),
        battle: (request) => _withSceneState(read, commit, () async {
          final state = read();
          final context = OverworldReturnContext(
              mapId: state.currentMapId,
              playerPos: state.playerPosition,
              playerFacing: state.playerFacing.asDirection);
          final battleRequest = switch (request.battleKind) {
            'wild' => buildSceneWildBattleRequest(
                request: request,
                manifest: _session!.bundle.manifest,
                returnContext: context),
            'trainer' => TrainerBattleStartRequest(
                requestId: request.requestId,
                createdAtEpochMs: request.createdAtEpochMs,
                returnContext: context,
                trainerId: request.trainerId,
                npcEntityId: request.npcEntityId,
                mapId: state.currentMapId,
                playerPos: state.playerPosition),
            'static' => StaticBattleStartRequest(
                requestId: request.requestId,
                createdAtEpochMs: request.createdAtEpochMs,
                returnContext: context,
                battleId: request.battleTemplateId ?? request.trainerId,
                opponentProfileId: request.trainerId,
                entityId: request.npcEntityId,
                mapId: state.currentMapId,
                playerPos: state.playerPosition),
            _ => throw UnsupportedError('Unsupported spatial battle kind.'),
          };
          final outcome = await _startBattle(battleRequest);
          return SceneBattleRuntimeOutcomeResult.completed(
              port: SceneBattleRuntimeOutcomePort.values.byName(outcome));
        }),
        interactive: (intent) => _withSceneState(
            read,
            commit,
            () => SceneInteractiveCommandRuntimeExecutor(warp: (command) async {
                  if (command is! SceneWarpInteractiveCommand) return 'blocked';
                  final destination = _mapsById[command.destinationMapId];
                  final warp = destination?.warps
                      .where((warp) => warp.id == command.warpId)
                      .firstOrNull;
                  if (warp == null) return 'blocked';
                  commit(const GameStateMutations().warpPlayer(
                      read(), destination!.id, warp.pos.x, warp.pos.y));
                  return 'completed';
                }, openWorldService: (request) async {
                  final result = await switch (request) {
                    OpenHealService() => openHealCenter(request: request),
                    OpenPcService() => openPc(request: request),
                    OpenShopService(:final shopId) => openShop(
                        _session!.bundle.manifest.shops
                            .firstWhere((shop) => shop.id == shopId),
                        request: request),
                  };
                  if (result.status == PlayerServiceRuntimeStatus.failed) {
                    throw StateError(
                        'The spatial world service failed: ${result.error}');
                  }
                  return result.status == PlayerServiceRuntimeStatus.completed
                      ? 'completed'
                      : 'cancelled';
                }).execute(intent)),
      ).build();

  Future<String> _startBattle(BattleStartRequest request) async {
    _ensureGameplayActive();
    _sceneBattleOutcome = null;
    final completed =
        await _battle!.start(bundle: _session!.bundle, request: request);
    _ensureGameplayActive();
    if (!completed || _sceneBattleOutcome == null) {
      throw StateError('The spatial battle did not complete.');
    }
    final outcome = _sceneBattleOutcome!;
    await _gameplay!.publishBattleOutcome(request: request, outcomeId: outcome);
    return outcome;
  }

  void _battleCompleted(BattleOutcome outcome) {
    _ensureGameplayActive();
    _sceneBattleOutcome = outcome.type.name;
  }

  Future<void> _runGameplay(Future<void> Function() action) async {
    if (_disposed || _stopped) return;
    _gameplayOperations++;
    _syncMovement();
    try {
      await action();
      if (!_disposed && !_stopped) await _materializeState(_gameState!);
    } catch (error) {
      if (!_disposed && !_stopped) _session?.interactionError.value = error;
    } finally {
      _gameplayOperations--;
      if (!_disposed) _syncMovement();
    }
  }

  Future<void> _materializeState(GameState state) async {
    _ensureGameplayActive();
    final session = _session!;
    final changedMap = session.bundle.map.id != state.currentMapId;
    final position = state.playerSpatialPosition ??
        PlayerSpatialPosition(
            x: state.playerPosition.x + .5, z: state.playerPosition.y + .5);
    if (!changedMap &&
        session.movement.spatialPosition == position &&
        session.movement.facing == state.playerFacing) {
      _gameState = state;
      _lastCell = state.playerPosition;
      return;
    }
    _materializingState = true;
    try {
      while (true) {
        await _waitForWorldAvailability();
        final pauseEpoch = _transferPauseEpoch;
        try {
          await session.restoreGameState(state);
          break;
        } catch (_) {
          _ensureGameplayActive();
          if (!_paused && _locks.isEmpty && pauseEpoch == _transferPauseEpoch) {
            rethrow;
          }
        }
      }
      _ensureGameplayActive();
      _gameState = state.copyWith(
          playerPosition: GridPos(
              x: session.movement.x.floor(), y: session.movement.z.floor()),
          playerSpatialPosition: session.movement.spatialPosition,
          playerFacing: session.movement.facing);
      _lastCell = _gameState!.playerPosition;
    } finally {
      _materializingState = false;
    }
    if (changedMap) {
      await _gameplay?.activateMap(MapActivation(
          activationId: _mapActivationId,
          mapId: state.currentMapId,
          reason: MapActivationReason.warp));
    }
  }

  Future<void> _waitForWorldAvailability() async {
    while (_paused || _locks.isNotEmpty) {
      _ensureGameplayActive();
      await (_materializationResumed ??= Completer<void>()).future;
    }
    _ensureGameplayActive();
  }

  void _onMapActivated() {
    if (_disposed || _stopped || _materializingState) return;
    _syncGameState();
    _lastCell = _gameState!.playerPosition;
    final gameplay = _gameplay;
    if (gameplay != null) {
      unawaited(_runGameplay(() => gameplay.activateMap(MapActivation(
          activationId: _mapActivationId,
          mapId: _session!.bundle.map.id,
          reason: _session!.connectionEntry == null
              ? MapActivationReason.warp
              : MapActivationReason.connection))));
    }
  }

  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;

  @override
  Future<void> load(GameSessionProgressReporter reportProgress) async {
    _ensureOpen();
    if (_loadingStarted || _stopped) {
      throw StateError('Exploration is single-use.');
    }
    if (!descriptor.grantedCapabilities.contains('map3d@1')) {
      throw StateError('Spatial exploration requires map3d@1.');
    }
    _loadingStarted = true;
    final generation = ++_loadGeneration;
    reportProgress(const GameSessionLoadingProgress(
        stage: 'project', current: 0, total: 3));
    final path = await _projectFilePath();
    _ensureLoadActive(generation);
    final save = await _initialSave?.call();
    _ensureLoadActive(generation);
    _validateInitialSave(save);
    final preload = await _preloadedInitialMap?.call(
        projectFilePath: path, descriptor: descriptor, initialSave: save);
    try {
      _ensureLoadActive(generation);
      final manifest =
          preload?.bundle.manifest ?? await loadProjectManifestFromFile(path);
      _ensureLoadActive(generation);
      if (manifest.settings.dimension != ProjectDimension.threeD ||
          manifest.maps.isEmpty) {
        throw StateError('A spatial project with an initial map is required.');
      }
      late final GameState state;
      if (descriptor.launchMode == GameSessionLaunchMode.newGame) {
        final initial = descriptor.initialGameState;
        if (!manifest.newGame.enabled ||
            initial == null ||
            initial.currentMapId.trim() != manifest.newGame.startMapId.trim()) {
          throw StateError(
              'A committed authored spatial New Game is required.');
        }
        state = normalizeLoadedGameState(initial);
        _createdAt = _now().toUtc();
      } else {
        state = const GameStateSaveEnvelopeMapper().restore(save!);
        _createdAt = save.createdAt;
        _basePlayTimeSeconds = save.playTimeSeconds;
      }
      final mapId = state.currentMapId.trim();
      final position = state.playerSpatialPosition;
      if (mapId.isEmpty ||
          position == null ||
          !manifest.maps.any((map) => map.id == mapId)) {
        throw StateError(
            'The spatial state does not reference a valid map and position.');
      }
      final bundle = preload?.bundle ??
          await loadRuntimeMapBundle(
              projectFilePath: path, mapId: mapId, preloadedManifest: manifest);
      _ensureLoadActive(generation);
      if (bundle.map.id != mapId) {
        throw StateError('The preloaded map does not match the spatial state.');
      }
      reportProgress(const GameSessionLoadingProgress(
          stage: 'resources', current: 1, total: 3));
      _gameState = state;
      await _initializeSpatialGameplay(bundle, path,
          generation: generation,
          narrativeSnapshot: preload?.narrativeSnapshot);
      _ensureLoadActive(generation);
      final loaded = await SpatialExplorationSession.load(bundle,
          spatialArrival: position,
          facing: state.playerFacing,
          entityIsPresent: (mapId, entity) =>
              _gameplay?.entityIsPresent(mapId, entity) ?? true,
          characterId: state.trainerProfile.avatarCharacterId);
      if (_disposed || _stopped || generation != _loadGeneration) {
        loaded.dispose();
        throw StateError('Exploration closed while loading.');
      }
      _session = loaded;
      _initializePlayerServices(bundle);
      loaded.interactionActive.addListener(_syncMovement);
      loaded.transitioning.addListener(_syncMovement);
      loaded.mapRevision.addListener(_onMapActivated);
      loaded.onFrame = _publishFrame;
      if (_preferences case final preferences?) {
        loaded.setTextSpeed(preferences.dialogueTextSpeed);
      }
      _syncMovement();
      _mounted = true;
      _mountFuture = Future<void>.sync(() => _mountSession(this));
      await _mountFuture;
      _ensureLoadActive(generation);
      if (!_paused) _playWatch.start();
      reportProgress(const GameSessionLoadingProgress(
          stage: 'ready', current: 3, total: 3));
      final gameplay = _gameplay;
      _lastCell = gameStateSnapshot.playerPosition;
      if (gameplay != null) {
        gameplayReady = _runGameplay(() => gameplay.activateMap(MapActivation(
            activationId: _mapActivationId,
            mapId: loaded.bundle.map.id,
            reason: descriptor.launchMode == GameSessionLaunchMode.continueGame
                ? MapActivationReason.saveRestore
                : MapActivationReason.initialBoot)));
        unawaited(gameplayReady);
        if (loaded.bundle.manifest.eventRegistry?.records.isEmpty ?? true) {
          await gameplayReady;
          _ensureLoadActive(generation);
        }
      }
    } finally {
      preload?.dispose();
    }
  }

  @override
  bool handleInput(RuntimeInputEvent event) {
    if (_disposed || _session == null) return false;
    if (event.isRelease) _pressed.remove(event.control);
    if (!inputAuthority.value.acceptsRuntimeInput) return true;
    if (inputAuthority.value.context == RuntimeInputContext.battle) {
      return _battle?.handleInput(event) ?? true;
    }
    if (inputAuthority.value.context == RuntimeInputContext.dialogue) {
      if (event.isPress && !event.isRepeat) {
        if (event.control == RuntimeInputControl.secondary) {
          _session!.closeDialogue();
        }
        if (event.control == RuntimeInputControl.primary) {
          _session!.confirmDialogue();
        }
        if (event.control == RuntimeInputControl.up ||
            event.control == RuntimeInputControl.down) {
          _session!.moveDialogueCursor(
              event.control == RuntimeInputControl.up ? -1 : 1);
        }
      }
      return true;
    }
    if (!inputAuthority.value.acceptsOverworldInput) return true;
    if (event.control == RuntimeInputControl.primary) {
      if (event.isPress && !event.isRepeat) {
        _publishInteractions();
        final request = overworldInteractions.value.primaryAction?.request;
        if (request != null) dispatchOverworldInteraction(request);
      }
      return true;
    }
    if (!{
      RuntimeInputControl.up,
      RuntimeInputControl.down,
      RuntimeInputControl.left,
      RuntimeInputControl.right,
      RuntimeInputControl.sprint
    }.contains(event.control)) {
      return false;
    }
    if (event.isRelease) {
      _pressed.remove(event.control);
    } else if (!event.isRepeat || _pressed.contains(event.control)) {
      _pressed.add(event.control);
    }
    _session!.movement.setInput(
      x: (_pressed.contains(RuntimeInputControl.right) ? 1 : 0) -
          (_pressed.contains(RuntimeInputControl.left) ? 1 : 0),
      z: (_pressed.contains(RuntimeInputControl.down) ? 1 : 0) -
          (_pressed.contains(RuntimeInputControl.up) ? 1 : 0),
      run: _pressed.contains(RuntimeInputControl.sprint),
    );
    return true;
  }

  @override
  Future<void> setInputLock(RuntimeExternalInputLock owner,
      {required bool locked}) async {
    _ensureOpen();
    if (locked) {
      _transferPauseEpoch++;
      _locks.add(owner);
      if (_session?.transitioning.value ?? false) {
        _session!.cancelPendingTransition();
      }
    } else {
      _locks.remove(owner);
    }
    _syncMovement();
  }

  void _syncMovement() {
    final paused = _paused ||
        _stopped ||
        _locks.isNotEmpty ||
        _session == null ||
        (_session?.transitioning.value ?? false);
    final talking = _session?.interactionActive.value ?? false;
    final battling = _battle?.isActive ?? false;
    if (paused || talking || battling) _pressed.clear();
    final busy = _gameplayOperations > 0 || (_gameplay?.isBusy ?? false);
    if (!paused || _stopped) {
      _materializationResumed?.complete();
      _materializationResumed = null;
    }
    _session?.dialoguePaused = paused;
    _session?.movement.setPaused(paused || talking || battling || busy);
    if (!paused && !talking && !battling && !busy) {
      _session?.movement.setInput(
          x: (_pressed.contains(RuntimeInputControl.right) ? 1 : 0) -
              (_pressed.contains(RuntimeInputControl.left) ? 1 : 0),
          z: (_pressed.contains(RuntimeInputControl.down) ? 1 : 0) -
              (_pressed.contains(RuntimeInputControl.up) ? 1 : 0),
          run: _pressed.contains(RuntimeInputControl.sprint));
    }
    if (paused) {
      _battle?.pause(owner: this);
    } else {
      _battle?.resume(owner: this);
    }
    inputAuthority.value = RuntimeInputAuthoritySnapshot(
        context: paused
            ? RuntimeInputContext.blocked
            : battling
                ? RuntimeInputContext.battle
                : talking
                    ? RuntimeInputContext.dialogue
                    : RuntimeInputContext.overworld,
        externalLocks: Set.unmodifiable(_locks),
        sprintAllowed: !paused && !talking && !battling);
    _publishInteractions();
  }

  @override
  Future<void> pause() async {
    _ensureOpen();
    _transferPauseEpoch++;
    _paused = true;
    _playWatch.stop();
    if (_session?.transitioning.value ?? false) {
      _session!.cancelPendingTransition();
    }
    _syncMovement();
  }

  @override
  Future<void> resume() async {
    _ensureOpen();
    _paused = false;
    if (!_stopped && _session != null) _playWatch.start();
    _syncMovement();
  }

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async {
    if (_session?.transitioning.value ?? false) {
      throw StateError('A spatial map transfer is still in progress.');
    }
    if (_playerServices?.isActive ?? false) {
      throw StateError('A player service is still in progress.');
    }
    if ((_battle?.isActive ?? false) || _gameplayOperations > 0) {
      throw StateError('A spatial gameplay action is still in progress.');
    }
    return _activityGate.runCheckpoint(NarrativeRuntimeCheckpointOperation.save,
        () async => _checkpointFromState(gameStateSnapshot));
  }

  GameSessionCheckpoint _checkpointFromState(GameState state) {
    return GameSessionCheckpoint(
        saveId: state.saveId,
        createdAt: _createdAt!,
        updatedAt: _now().toUtc(),
        playTimeSeconds: _basePlayTimeSeconds + _playWatch.elapsed.inSeconds,
        state: strictGameStateSaveJson(state));
  }

  void _initializePlayerServices(RuntimeMapBundle bundle) {
    final services = PlayerServiceRuntimeController.contextual(
        currentGameState: () => _sceneStateReader?.call() ?? gameStateSnapshot,
        commitAndSave: _commitPlayerServiceState,
        setInputLocked: (locked) {
          if (_disposed) return;
          if (locked) {
            _transferPauseEpoch++;
            _locks.add(RuntimeExternalInputLock.playerService);
            _session?.cancelPendingTransition();
          } else {
            _locks.remove(RuntimeExternalInputLock.playerService);
          }
          _syncMovement();
        },
        loadRecoveryCaps: _recoveryCapsLoader ??
            (state) => loadRuntimePlayerServiceRecoveryCaps(
                gameState: state,
                projectRootDirectory: bundle.projectRootDirectory,
                pokemonConfig: bundle.manifest.pokemon),
        conditionContext: ScriptEvaluationContext(
            narrativeFactResolver:
                NarrativeFactRuntimeResolver.fromFacts(bundle.manifest.facts)),
        grantedCapabilities: descriptor.grantedCapabilities,
        projectRootDirectory: bundle.projectRootDirectory,
        pokemonConfig: bundle.manifest.pokemon,
        locale: descriptor.locale);
    services.setPauseMutationGuard(() =>
        _activityGate.activity == NarrativeRuntimeActivity.idle &&
                !_stopped &&
                _gameplayOperations == 0 &&
                !_materializingState &&
                !(_gameplay?.isBusy ?? false)
            ? null
            : 'Une action est déjà en cours.');
    _playerServices = services;
    _playerServiceSnapshots =
        services.worldServiceSnapshots.listen(_publishWorldService);
  }

  Future<void> _commitPlayerServiceState(GameState state) async {
    _ensureGameplayActive();
    final normalized = normalizeLoadedGameState(state);
    if (_sceneStateWriter case final commit?) {
      commit(normalized);
      return;
    }
    final previous = gameStateSnapshot;
    if (normalized.saveId != previous.saveId ||
        normalized.currentMapId != previous.currentMapId ||
        normalized.playerSpatialPosition != previous.playerSpatialPosition) {
      throw StateError('A player service cannot relocate its spatial session.');
    }
    _gameState = normalized;
    try {
      if (!_pauseCommandInFlight) {
        final commit = _commitCheckpoint;
        if (commit == null) {
          throw StateError('The host does not provide checkpoint persistence.');
        }
        await _activityGate.runCheckpoint(
            NarrativeRuntimeCheckpointOperation.save,
            () => commit(GameSessionCheckpointCommit(
                descriptor: descriptor.publicContext,
                checkpoint: _checkpointFromState(normalized),
                status: SaveStatus.active,
                trigger: GameSessionCheckpointTrigger.pauseMutation)));
      }
    } catch (_) {
      if (identical(_gameState, normalized)) _gameState = previous;
      rethrow;
    }
  }

  @override
  RuntimeWorldServiceSnapshot? get worldServiceSnapshot =>
      _worldServiceSnapshot;

  @override
  Stream<RuntimeWorldServiceSnapshot?> get worldServiceSnapshots =>
      _worldServiceSnapshots.stream;

  void _publishWorldService(RuntimeWorldServiceSnapshot? snapshot) {
    _worldServiceSnapshot = snapshot;
    if (!_worldServiceSnapshots.isClosed) _worldServiceSnapshots.add(snapshot);
  }

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
      RuntimeWorldServiceCommand command) {
    final services = _playerServices;
    if (_disposed || _stopped || services == null) {
      return Future.value(RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
          safeMessage: RuntimeSessionStrings.forLocale(descriptor.locale)
              .noWorldService));
    }
    return services.dispatchWorldService(command);
  }

  @override
  Future<RuntimePlayerPauseCommandResult> dispatchPauseCommand(
      RuntimePlayerPauseCommand command) async {
    final services = _playerServices;
    if (_disposed ||
        _stopped ||
        !_paused ||
        _pauseCommandInFlight ||
        services == null) {
      return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: RuntimeSessionStrings.forLocale(descriptor.locale)
              .bagUnavailable);
    }
    _pauseCommandInFlight = true;
    try {
      return await switch (command.kind) {
        RuntimePlayerPauseCommandKind.reorderPartyMember ||
        RuntimePlayerPauseCommandKind.setPartyLead =>
          services.reorderPartyOutsideBattle(command),
        _ => services.useBagItemOutsideBattle(command),
      };
    } finally {
      _pauseCommandInFlight = false;
    }
  }

  Future<PlayerServiceRuntimeResult> openHealCenter(
      {OpenHealService? request}) {
    _ensureGameplayActive();
    return _playerServices!.openHealCenter(request: request);
  }

  Future<PlayerServiceRuntimeResult> openShop(ShopDefinition shop,
      {OpenShopService? request}) {
    _ensureGameplayActive();
    return _playerServices!.openShop(shop, request: request);
  }

  Future<PlayerServiceRuntimeResult> openPc({OpenPcService? request}) {
    _ensureGameplayActive();
    return _playerServices!.openPc(request: request);
  }

  @override
  Future<void> lockGameplayForCompletion() =>
      setInputLock(RuntimeExternalInputLock.gameCompletion, locked: true);

  @override
  Future<void> acknowledgeCompletion({required bool accepted}) async {}

  @override
  Future<void> stop(GameSessionExitReason reason) async {
    if (_disposed) return;
    _stopped = true;
    _loadGeneration++;
    _playWatch.stop();
    _gameplay?.invalidate();
    _battle?.cancel();
    _session?.cancelPendingTransition();
    _session?.closeDialogue();
    _syncMovement();
  }

  @override
  Future<PlayerPauseMenuState> loadPauseMenuState() async =>
      gameStateSnapshot.pauseMenuState;

  @override
  Future<Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>
      loadPauseDetails() async => (await readCompanionMenuData()).pauseDetails;

  @override
  Future<RuntimePlayerCompanionMenuData> readCompanionMenuData() async {
    final state = gameStateSnapshot;
    final session = _session!;
    final mapRevision = session.mapRevision.value;
    final manifest = session.bundle.manifest;
    final details = await const RuntimePlayerPauseDataBuilder().build(
        gameState: state,
        projectRootDirectory: session.bundle.projectRootDirectory,
        pokemonConfig: manifest.pokemon,
        locale: descriptor.locale,
        uiLocale: _preferences?.locale,
        mapEnabled: descriptor.grantedCapabilities.contains('map3d@1'),
        projectMaps: manifest.maps,
        regionalMap: manifest.regionalMap,
        projectBadges: manifest.badges,
        projectCharacters: manifest.characters,
        playtimeSeconds: _basePlayTimeSeconds + _playWatch.elapsed.inSeconds);
    _ensureOpen();
    if (!identical(session, _session) ||
        session.mapRevision.value != mapRevision) {
      throw StateError('Session changed.');
    }
    return RuntimePlayerCompanionMenuData(
        pauseMenuState: state.pauseMenuState, pauseDetails: details);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stopped = true;
    _loadGeneration++;
    _playWatch.stop();
    _materializationResumed?.complete();
    _materializationResumed = null;
    _gameplay?.dispose();
    _battle?.removeListener(_syncMovement);
    _battle?.dispose();
    _session?.closeDialogue();
    _syncMovement();
    try {
      await _playerServiceSnapshots?.cancel();
      _playerServiceSnapshots = null;
      final services = _playerServices;
      _playerServices = null;
      await services?.dispose();
      _publishWorldService(null);
      await _mountFuture?.catchError((Object _) {});
      if (_mounted) await _unmountSession(this);
    } finally {
      _mounted = false;
      _session?.interactionActive.removeListener(_syncMovement);
      _session?.transitioning.removeListener(_syncMovement);
      _session?.mapRevision.removeListener(_onMapActivated);
      _session?.dispose();
      _session = null;
      overworldInteractions.dispose();
      await _interactionEvents.close();
      await _worldServiceSnapshots.close();
      inputAuthority.dispose();
      await _events.close();
    }
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Spatial exploration is disposed.');
  }

  void _ensureGameplayActive() {
    _ensureOpen();
    if (_stopped || _session == null) {
      throw StateError('The spatial gameplay session is not active.');
    }
  }

  void _ensureLoadActive(int generation) {
    _ensureOpen();
    if (_stopped || generation != _loadGeneration) {
      throw StateError('Spatial exploration stopped while loading.');
    }
  }

  void _validateInitialSave(SaveEnvelope? save) {
    if (descriptor.launchMode == GameSessionLaunchMode.newGame) {
      if (save != null || descriptor.saveReadHandle != null) {
        throw StateError('New Game cannot consume an existing save.');
      }
      return;
    }
    if (save == null ||
        descriptor.initialGameState != null ||
        descriptor.saveReadHandle == null ||
        save.gameId != descriptor.identity.gameId ||
        save.profileId != descriptor.profileId ||
        save.slotId != descriptor.slotId ||
        save.projectFormat != descriptor.identity.projectFormat ||
        save.saveFormat != descriptor.identity.saveFormat ||
        save.compatibilityId != descriptor.identity.compatibilityId) {
      throw StateError('The selected save does not match the spatial session.');
    }
  }
}
