import '../player/real_weather_service.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_battle/map_battle.dart' show BattleOutcome, BattleOutcomeType;
import 'package:path/path.dart' as p;

import '../application/load_runtime_map_bundle.dart';
import '../application/runtime_project_catalog.dart';
import '../application/runtime_item_catalog_loader.dart';
import '../application/runtime_bag_capacity.dart';
import '../application/narrative_runtime_activity_gate.dart';
import '../application/player_service_runtime_controller.dart';
import '../application/runtime_map_bundle.dart';
import '../application/battle_start_request.dart';
import '../application/map_activation.dart';
import '../application/narrative_event_runtime_snapshot.dart';
import '../application/scene_runtime/scene_battle_runtime_outcome_result.dart';
import '../application/scene_runtime/scene_consequence_runtime_writer.dart';
import '../application/scene_runtime/runtime_scene_pokemon_catalog.dart';
import '../application/scene_runtime/runtime_scene_party_condition_context.dart';
import '../application/scene_runtime/scene_interactive_command_runtime_executor.dart';
import '../application/scene_runtime/scene_runtime_host_callbacks.dart';
import '../application/scene_runtime/scene_wild_battle_request.dart';
import '../player/runtime_player_pause_data.dart';
import '../player/runtime_player_pause_data_builder.dart';
import '../player/runtime_player_host.dart';
import '../player/runtime_music_service.dart';
import '../player/runtime_scene_music_controller.dart';
import '../player/runtime_audio_mixer.dart';
import '../presentation/flame/battle_music_resolver.dart';
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
import '../spatial/spatial_story_playback.dart';
import '../spatial/spatial_trainer_spot_cinematic.dart';
import '../spatial/spatial_scene_audio_runtime.dart';
import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import '../player/contact_device_pause.dart';
import '../application/dialogue_portrait_resolver.dart';
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
    RealWeatherService? realWeatherService,
    DateTime Function()? now,
    RuntimeAudioMixer? audioMixer,
    @visibleForTesting FlameCinematicAudioDriver Function()? sceneAudioDriverFactory,
    @visibleForTesting RuntimeMusicService Function(RuntimeAudioMixer)? musicServiceFactory,
  })  : _projectFilePath = projectFilePath,
        _mountSession = mountSession,
        _unmountSession = unmountSession,
        _initialSave = initialSave,
        _preloadedInitialMap = preloadedInitialMap,
        _commitCheckpoint = commitCheckpoint,
        _recoveryCapsLoader = recoveryCapsLoader,
        _now = now ?? DateTime.now,
        _realWeather = realWeatherService ?? RealWeatherService.shared,
        _audioMixer = audioMixer ?? RuntimeAudioMixer(),
        _ownsAudioMixer = audioMixer == null,
        _sceneAudioDriverFactory = sceneAudioDriverFactory {
    _music = musicServiceFactory?.call(_audioMixer) ?? RuntimeMusicService(mixer: _audioMixer);
  }

  final GameSessionDescriptor descriptor;
  final RuntimeAudioMixer _audioMixer;
  RuntimeAudioMixer get audioMixer => _audioMixer;
  final bool _ownsAudioMixer;
  late final RuntimeMusicService _music;
  final FlameCinematicAudioDriver Function()? _sceneAudioDriverFactory;
  SpatialSceneAudioRuntime? _sceneAudio;
  RuntimeSceneMusicSelection? _battleMusic;
  RuntimeSceneMusicSelection? _trainerEncounterMusic;
  BattleMusicSelection? _battleAudioSelection;
  String? _audioMapId;
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
  bool _pauseCommandInFlight = false;
  String? _pendingContactId;
  GameState Function()? _sceneStateReader;
  void Function(GameState)? _sceneStateWriter;
  SpatialGameplayEvents? _gameplay;
  SpatialBattleRuntime? _battle;
  SpatialBattleRuntime? get battle => _battle;
  final _runtimeIds = NarrativeEventIdGenerator();
  Map<String, MapData> _mapsById = const {};
  int _gameplayOperations = 0;
  bool _materializingState = false;
  MapActivation? _pendingSceneMapActivation;
  bool _hasUncommittedSceneWarp = false;
  int _transferPauseEpoch = 0;
  Completer<void>? _materializationResumed;
  GridPos? _lastCell;
  Future<void> gameplayReady = Future.value();
  String? _sceneBattleOutcome;
  final DateTime Function() _now;
  final _playWatch = Stopwatch();
  GameState? _gameState;
  WorldEnvironmentClock? _environmentClock;
  final RealWeatherService _realWeather;
  Timer? _weatherTimer;
  bool _realWeatherDeclared = false;
  (RealWeatherPreferences, bool, bool)? _weatherConfiguration;
  void _configureRealWeather() {
    final session = _session;
    if (session == null || _disposed || _stopped) return;
    final preferences = _preferences?.realWeather ?? const RealWeatherPreferences();
    final requested = _realWeatherDeclared || session.bundle.visualProfile.requiresRealWeather;
    final configuration = (preferences, requested, session.presentationPaused);
    if (_weatherConfiguration == configuration) return;
    _weatherConfiguration = configuration;
    _weatherTimer?.cancel();
    session.realWeatherAllowed = preferences.enabled && requested;
    if (!preferences.enabled) { unawaited(_realWeather.refresh(preferences)); return; }
    if (!requested || session.presentationPaused) return;
    unawaited(_realWeather.refresh(preferences));
    _weatherTimer = Timer.periodic(const Duration(minutes: 20), (_) => unawaited(_realWeather.refresh(preferences)));
  }

  DateTime? _createdAt;
  int _basePlayTimeSeconds = 0;
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();
  final _locks = <RuntimeExternalInputLock>{};
  final _pressed = <RuntimeInputControl>{};
  final inputAuthority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
    context: RuntimeInputContext.blocked,
  ));
  SpatialExplorationSession? _session;
  RuntimeProjectCatalog? _projectCatalog;
  SpatialStoryPlayback? _story;
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
    if (_ownsAudioMixer) _observeMusic(_audioMixer.transitionTo(preferences.audioMix));
    _session?.setTextSpeed(preferences.dialogueTextSpeed);
    _configureRealWeather();
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
    final model = npc == null && inputAuthority.value.acceptsOverworldInput
        ? _gameplay?.modelInteractionTarget
        : null;
    if (model != null) {
      final cell =
          GridPos(x: model.position.x.floor(), y: model.position.z.floor());
      final snapshot = RuntimeOverworldInteractionSnapshot(
        sessionId: descriptor.sessionId,
        mapActivationId: _mapActivationId,
        mapId: session.bundle.map.id,
        movementContinuityId:
            '${descriptor.sessionId}:${session.movement.inputEpoch}',
        primaryAction: RuntimeOverworldInteractionAction(
            request: RuntimeOverworldInteractionRequest(
                sessionId: descriptor.sessionId,
                mapActivationId: _mapActivationId,
                mapId: session.bundle.map.id,
                targetKind: RuntimeOverworldInteractionTargetKind.modelInstance,
                targetId: model.id,
                actionId: 'interact'),
            verb: RuntimeOverworldInteractionVerb.interact,
            targetCell: cell,
            targetBounds: PixelRect(
                leftPx: cell.x * session.bundle.manifest.settings.tileWidth,
                topPx: cell.y * session.bundle.manifest.settings.tileHeight,
                widthPx: session.bundle.manifest.settings.tileWidth,
                heightPx: session.bundle.manifest.settings.tileHeight)),
      );
      if (snapshot != overworldInteractions.value) {
        overworldInteractions.value = snapshot;
        _interactionEvents.add(snapshot);
      }
      return;
    }
    final npcPose = npc == null ? null : session.actorRuntimeState(npc);
    final npcCell = npcPose == null
        ? npc?.pos
        : GridPos(x: npcPose.x.floor(), y: npcPose.z.floor());
    final snapshot = RuntimeOverworldInteractionSnapshot(
        sessionId: descriptor.sessionId,
        mapActivationId: _mapActivationId,
        mapId: session.bundle.map.id,
        movementContinuityId:
            '${descriptor.sessionId}:${session.movement.inputEpoch}',
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
                targetCell: npcCell!,
                targetBounds: PixelRect(
                    leftPx:
                        npcCell.x * session.bundle.manifest.settings.tileWidth,
                    topPx:
                        npcCell.y * session.bundle.manifest.settings.tileHeight,
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
      final entity = gameplay.interactionTarget;
      unawaited(_runGameplay(() async {
        await _session!.withEntityInteraction(entity, () => gameplay.interact());
      }));
    }
    return true;
  }

  bool _mounted = false, _paused = false, _stopped = false, _disposed = false;
  bool _loadingStarted = false;
  ItemCatalogSnapshot _bagItemCatalog = ItemCatalogSnapshot.empty();
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
    if (_stopped ||
        _disposed ||
        _sceneStateReader != null ||
        _materializingState ||
        _gameplayOperations > 0) {
      return;
    }
    final session = _session;
    final state = _gameState;
    if (session == null || state == null) return;
    if (session.nativeDoorTraversalActive) return;
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
        !(_session?.movement.isJumping ?? true) &&
        _lastCell != cell &&
        inputAuthority.value.acceptsOverworldInput) {
      final previous = _lastCell;
      _lastCell = cell;
      final map = _session!.bundle.map;
      if (previous != null &&
          (map.triggers.isNotEmpty ||
              map.gameplayZones.isNotEmpty ||
              map.layers.whereType<SmartTileLayer>().any(
                  (layer) => layer.isVisible && layer.encounterBehavior != null))) {
        unawaited(_runGameplay(() => gameplay.playerEnteredCell(
            previousPosition: previous, currentPosition: cell)));
      }
    }
    _publishInteractions();
    _trySpotTrainer();
  }

  String? _trainerSpotLatch;

  void _trySpotTrainer() {
    final session = _session, gameplay = _gameplay, story = _story;
    if (session == null || gameplay == null || story == null ||
        !descriptor.grantedCapabilities.contains(SpatialGameplayCapabilities.trainerSpottingCapabilityId) ||
        _gameplayOperations > 0 || _materializingState || gameplay.isBusy ||
        !inputAuthority.value.acceptsOverworldInput || session.presentationPaused ||
        session.transitioning.value || session.nativeDoorTraversalActive ||
        session.movement.isJumping || session.storyActive.value) {
      return;
    }
    final spot = findSpatialTrainerSpot(entities: session.bundle.map.entities,
      playerX: session.movement.x, playerZ: session.movement.z,
      eligible: gameplay.canSpotTrainer, actorState: session.actorRuntimeState,
      canTraverse: (entity, x, z, nextX, nextZ) => session.movement.canTraverseActor(
        x, z, nextX, nextZ, ignoredEntityId: entity.id, collideWithPlayer: true));
    if (spot == null) {
      _trainerSpotLatch = null;
      return;
    }
    final identity = '${session.bundle.map.id}:${spot.entity.id}';
    if (_trainerSpotLatch == identity) {
      return;
    }
    _trainerSpotLatch = identity;
    unawaited(_runGameplay(() async {
      final encounterPath = const BattleMusicResolver().resolveEncounterMusicAbsolutePath(
        bundle: session.bundle, playerPos: GridPos(x: session.movement.x.floor(), y: session.movement.z.floor()));
      if (encounterPath != null) {
        _trainerEncounterMusic = (route: RuntimeAudioRoute.overworld, path: encounterPath, volume: .8);
      }
      try {
        await _applyMusicSelection();
        story.autonomousNpcs.flush();
        final completed = await story.playTransient(spatialTrainerSpotCinematic(session.bundle.map.id, spot));
        if (!completed || _disposed || _stopped || !identical(session, _session)) return;
        await _materializeState(_gameState!);
        if (!gameplay.canSpotTrainer(spot.entity) || gameplay.interactionTarget?.id != spot.entity.id) return;
        await session.withEntityInteraction(spot.entity, () => gameplay.interact());
      } finally {
        _trainerEncounterMusic = null;
        await _applyMusicSelection();
      }
    }));
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
    final entries = project.maps
        .where((entry) => !maps.containsKey(entry.id))
        .toList(growable: false);
    final loadedMaps = await loadMapDataFiles(
      [
        for (final entry in entries)
          p.join(bundle.projectRootDirectory, entry.relativePath),
      ],
      projectDialogueContext: bundle.projectCatalog == null ? project : null,
    );
    _ensureLoadActive(generation);
    for (var index = 0; index < entries.length; index++) {
      maps[entries[index].id] = loadedMaps[index];
    }
    final savedWorld = gameStateSnapshot.spatialWorldState;
    if (bundle.projectCatalog case final catalog?) {
      for (final id in {...savedWorld.modelsByMap.keys,
          ...savedWorld.actorsByMap.keys}) {
        final map = maps[id];
        if (map == null) throw StateError('Saved spatial map is missing: $id');
        final view = await catalog.manifestForMap(map);
        validateSpatialWorldState(
            state: SpatialWorldState(
              modelsByMap: {if (savedWorld.modelsByMap[id] case final value?) id: value},
              actorsByMap: {if (savedWorld.actorsByMap[id] case final value?) id: value},
            ), project: view, maps: [map]);
      }
    } else {
      validateSpatialWorldState(state: savedWorld, project: project, maps: maps.values);
    }
    _mapsById = Map.unmodifiable(maps);
    if (!SpatialGameplayCapabilities.requiresGameplay(project,
        maps: maps.values)) {
      return;
    }
    _battle = SpatialBattleRuntime(
        audioMixer: _audioMixer,
        onOutcomePresented: _battleOutcomePresented,
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
        currentWorldProject: () => _session?.bundle.manifest ?? project,
        now: _now,
        interactionPositionBlocked: (x, z, ignoredEntityId) => _session == null || !_session!.movement.canTraverseActor(x, z, x, z, ignoredEntityId: ignoredEntityId),
        currentModelDefinitions: () =>
            _session?.bundle.manifest.models3d ?? project.models3d,
        mapsById: _mapsById,
        readGameState: () => _gameState!,
        commitGameState: (state) {
          _ensureGameplayActive();
          _gameState = state;
        },
        createSceneCallbacks: _createSceneCallbacks,
        itemCatalog: _bagItemCatalog,
        persistItemPickup: _persistNativeItemPickup,
        presentItemPickup: _presentNativeItemPickup,
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
        onSceneTerminated: (owner) async {
          _story?.releaseScene(owner);
          await _sceneAudio?.releaseScene(owner);
        },
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
          final pokemonCatalog = await loadRuntimeScenePokemonCatalog(
            scene: scene,
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: project.pokemon,
          );
          final partyConditionContext = await loadRuntimeScenePartyConditionContext(
            scene: scene,
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: project.pokemon,
          );
          _ensureGameplayActive();
          return SceneConsequenceRuntimeWriter(
              project: project,
              itemCatalog: _bagItemCatalog,
              pokemonCatalog: pokemonCatalog,
              partyConditionContext: partyConditionContext,
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
    presentPlayerAvatar: (id) async {
      _ensureGameplayActive();
      await _session!.presentPlayerAvatar(id);
      _ensureGameplayActive();
    },
    presentTextInput: (request) async {
      final services = _playerServices;
      if (services == null) throw StateError('The spatial numeric presenter is unavailable.');
      return services.openSceneTextInteraction(request: request);
    },
    presentPokemonGift: (request) async {
      final services = _playerServices;
      if (services == null) {
        throw StateError('The spatial Pokemon gift presenter is unavailable.');
      }
      return services.openPokemonGiftInteraction(request: request);
    },
        project: _session!.bundle.manifest,
        runtimeSourceId: _mapActivationId,
        readGameState: read,
        playCinematic: (intent) => _withSceneState(read, commit,
            () => _story!.playCinematic(intent, _mapActivationId, sceneOwner: read)),
        show: (request) => _withSceneState(
            read,
            commit,
            () => _session!.showDialogue(DialogueRef(
                dialogueId: request.dialogueId,
                startNode: request.yarnNodeName),
                entity: _session!.interactionEntity,
                choicePolicies: request.choicePolicies,
                linePolicies: request.linePolicies)),
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
          final outcome = await _startBattle(battleRequest,
              defeatRecovery: request.defeatRecovery);
          return SceneBattleRuntimeOutcomeResult.completed(
              port: SceneBattleRuntimeOutcomePort.values.byName(outcome));
        }),
        interactive: (intent) => _withSceneState(
            read,
            commit,
            () => SceneInteractiveCommandRuntimeExecutor(
                sceneMusic: (command) => _sceneAudio!.execute(command, sceneOwner: read),
                worldPresentation: (command) => _story!.playVisual(command, owner: read),
                playModelAnimation: (command) => _story!.playModel(command),
                playSoundEffect: (command) => _sceneAudio!.execute(command, sceneOwner: read),
                playMusicEffect: (command) => _sceneAudio!.execute(command, sceneOwner: read),
                stopSoundEffects: (command) => _sceneAudio!.execute(command, sceneOwner: read),
                warp: (command) =>
                    _executeSceneWarp(command, read: read, commit: commit),
                openWorldService: (request) async {
                  final result = await switch (request) {
                    OpenPokemonGiftInteractionService() => throw StateError('Pokemon gifts require the Scene presenter.'),
                    OpenTextInputService() || OpenSceneTextInteractionService() =>
                      Future<PlayerServiceRuntimeResult>.value(
                        const PlayerServiceRuntimeResult.unavailable(
                          'La saisie de texte en scène n’est pas disponible en 3D.',
                        ),
                      ),
                    OpenHealService() => openHealCenter(request: request),
                    OpenPcService() => openPc(request: request),
            OpenPartyTradeService() => Future<PlayerServiceRuntimeResult>.value(
              const PlayerServiceRuntimeResult.unavailable(
                'Ce service nécessite une carte 2D.',
              ),
            ),
                    OpenRegionalMapService() => Future<PlayerServiceRuntimeResult>.value(
                        const PlayerServiceRuntimeResult.unavailable('La carte régionale en scène n’est pas disponible en 3D.')),
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

  Future<String> _executeSceneWarp(SceneInteractiveCommand command,
      {required GameState Function() read,
      required void Function(GameState) commit}) async {
    if (command is! SceneWarpInteractiveCommand) return 'blocked';
    final destination = _mapsById[command.destinationMapId];
    final warp = destination?.warps
        .where((warp) => warp.id == command.warpId)
        .firstOrNull;
    if (warp == null) return 'blocked';
    _story?.autonomousNpcs.flush();
    final source = read();
    final pendingActivation = _pendingSceneMapActivation;
    final pendingWarp = _hasUncommittedSceneWarp;
    final next = const GameStateMutations().warpPlayer(
        source, destination!.id, warp.pos.x, warp.pos.y,
        facing: command.arrivalFacing);
    try {
      _hasUncommittedSceneWarp = true;
      final restored = await switch (command.transition) {
        SceneWarpTransition.mapDefault || SceneWarpTransition.none =>
          _restoreSpatialState(next, restoreAvatar: false),
      };
      if (!_session!.movement.isPositionTraversable) {
        throw StateError('The spatial warp arrival is blocked.');
      }
      if (source.currentMapId != restored.currentMapId) {
        _pendingSceneMapActivation = MapActivation(
            activationId: _mapActivationId,
            mapId: restored.currentMapId,
            reason: MapActivationReason.warp);
      }
      commit(restored);
      return 'completed';
    } on Object {
      _pendingSceneMapActivation = pendingActivation;
      _hasUncommittedSceneWarp = pendingWarp;
      if (!_disposed && !_stopped) {
        await _restoreSpatialState(source, restoreAvatar: false);
      }
      return 'blocked';
    }
  }

  Future<String> _startBattle(BattleStartRequest request,
      {SceneBattleDefeatRecovery defeatRecovery =
          SceneBattleDefeatRecovery.returnToRecoveryPoint}) async {
    _ensureGameplayActive();
    _sceneBattleOutcome = null;
    final bundle = _session!.bundle;
    _trainerEncounterMusic = null;
    _battleAudioSelection = const BattleMusicResolver().resolve(request: request, bundle: bundle);
    _battleMusic = (route: RuntimeAudioRoute.battle,
      path: _battleAudioSelection!.battleMusicAbsolutePath,
      volume: .8);
    try {
      await _applyMusicSelection();
      _ensureGameplayActive();
      final completed = await _battle!.start(
          bundle: bundle, request: request, defeatRecovery: defeatRecovery);
      _ensureGameplayActive();
      if (!completed || _sceneBattleOutcome == null) {
        throw StateError('The spatial battle did not complete.');
      }
      final outcome = _sceneBattleOutcome!;
      await _gameplay!.publishBattleOutcome(request: request, outcomeId: outcome);
      return outcome;
    } finally {
      _battleMusic = null;
      _battleAudioSelection = null;
      await _applyMusicSelection();
    }
  }

  void _battleOutcomePresented(BattleOutcome outcome) {
    if (_disposed || _stopped || _battleMusic == null ||
        (outcome.type != BattleOutcomeType.victory && outcome.type != BattleOutcomeType.captured)) return;
    _battleMusic = (route: RuntimeAudioRoute.battle,
      path: _battleAudioSelection?.victoryMusicAbsolutePath, volume: .8);
    _observeMusic(_applyMusicSelection());
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
      if (!_disposed && !_stopped) {
        await _rollbackPendingSceneWarp();
        final cancelled = _story?.wasCancelled == true;
        _story?.synchronize(_gameState!.spatialWorldState);
        _session?.interactionError.value = cancelled ? null : error;
      }
    } finally {
      _gameplayOperations--;
      if (!_disposed) _syncMovement();
    }
  }

  Future<void> _materializeState(GameState state) async {
    final changedMap = _session!.bundle.map.id != state.currentMapId;
    _gameState = await _restoreSpatialState(state);
    _hasUncommittedSceneWarp = false;
    _lastCell = _gameState!.playerPosition;
    if (changedMap) {
      _pendingSceneMapActivation = MapActivation(
          activationId: _mapActivationId,
          mapId: state.currentMapId,
          reason: MapActivationReason.warp);
    }
    if (_gameplay?.isBusy ?? false) return;
    while (_pendingSceneMapActivation != null) {
      final activation = _pendingSceneMapActivation!;
      _pendingSceneMapActivation = null;
      if (activation.mapId == _gameState!.currentMapId) {
        await _gameplay?.activateMap(activation);
      }
    }
  }

  Future<GameState> _restoreSpatialState(GameState state, {bool restoreAvatar = true}) async {
    _ensureGameplayActive();
    final session = _session!;
    if (restoreAvatar) await session.presentPlayerAvatar(state.trainerProfile.avatarCharacterId);
    _story?.synchronize(state.spatialWorldState);
    final changedMap = session.bundle.map.id != state.currentMapId;
    final position = state.playerSpatialPosition ??
        PlayerSpatialPosition(
            x: state.playerPosition.x + .5, z: state.playerPosition.y + .5);
    if (!changedMap &&
        session.movement.spatialPosition == position &&
        session.movement.facing == state.playerFacing) {
      return state.copyWith(playerSpatialPosition: position);
    }
    _materializingState = true;
    try {
      while (true) {
        await _waitForWorldAvailability();
        final pauseEpoch = _transferPauseEpoch;
        try {
          await session.restoreGameState(state, restorePlayerAvatar: false);
          break;
        } catch (_) {
          _ensureGameplayActive();
          if (!_paused && _locks.isEmpty && pauseEpoch == _transferPauseEpoch) {
            rethrow;
          }
        }
      }
      _ensureGameplayActive();
      if (session.bundle.map.id != state.currentMapId ||
          session.movement.spatialPosition != position ||
          session.movement.facing != state.playerFacing) {
        throw StateError('The spatial relocation did not reach its arrival.');
      }
      return state.copyWith(
          playerPosition: GridPos(
              x: session.movement.x.floor(), y: session.movement.z.floor()),
          playerSpatialPosition: session.movement.spatialPosition,
          playerFacing: session.movement.facing);
    } finally {
      _materializingState = false;
    }
  }

  Future<void> _rollbackPendingSceneWarp() async {
    if (!_hasUncommittedSceneWarp || _session == null) return;
    _hasUncommittedSceneWarp = false;
    _pendingSceneMapActivation = null;
    _materializingState = true;
    try {
      _story?.synchronize(_gameState!.spatialWorldState);
      await _session!.restoreGameState(_gameState!, compensatePendingScene: true);
      _lastCell = _gameState!.playerPosition;
    } finally {
      _materializingState = false;
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
    if (_disposed || _stopped) return;
    _configureRealWeather();
    if (_audioMapId != _session?.bundle.map.id) {
      _audioMapId = _session?.bundle.map.id;
      unawaited(_sceneAudio?.reset());
    }
    _syncMapMusic();
    if (_materializingState) return;
    if (_session?.nativeDoorTraversalActive ?? false) return;
    _syncGameState();
    _lastCell = _gameState!.playerPosition;
    final gameplay = _gameplay;
    if (gameplay != null) {
      final activation = MapActivation(
          activationId: _mapActivationId,
          mapId: _session!.bundle.map.id,
          reason: _session!.connectionEntry == null
              ? MapActivationReason.warp
              : MapActivationReason.connection);
      if (gameplay.tryActivateConnectedMap(activation)) {
        _publishInteractions();
        return;
      }
      unawaited(_runGameplay(() => gameplay.activateMap(activation)));
    }
  }

  void _observeMusic(Future<void> operation) {
    unawaited(operation.catchError((Object error) {
      _music.lastFailure = error;
    }));
  }

  RuntimeSceneMusicSelection _mapMusicSelection() {
    final bundle = _session!.bundle;
    return (route: RuntimeAudioRoute.overworld,
      path: const BattleMusicResolver().resolveMapMusicAbsolutePath(bundle: bundle),
      volume: bundle.map.mapMetadata.musicVolume ?? .8);
  }

  Future<void> _applyMusicSelection() async {
    if (_disposed || _stopped || _session == null) return;
    final selected = _battleMusic ?? _trainerEncounterMusic ?? _sceneAudio?.musicSelection ?? _mapMusicSelection();
    await _music.update(route: selected.route, path: selected.path, volume: selected.volume);
    if (_music.lastFailure case final failure?) throw failure;
  }

  void _syncMapMusic() => _observeMusic(_applyMusicSelection());

  void _syncMusicSuspension() {
    if (_disposed || _stopped) return;
    _observeMusic(_music.setSuspended(_locks.contains(RuntimeExternalInputLock.lifecycle) ||
        (_session?.lifecyclePaused ?? false)));
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
      final catalog = preload?.takeProjectCatalog() ??
          (preload == null ? await RuntimeProjectCatalog.open(path) : null);
      if (_disposed || _stopped || generation != _loadGeneration) {
        catalog?.dispose();
        _ensureLoadActive(generation);
      }
      _projectCatalog = catalog;
      final manifest = preload?.bundle.manifest ?? catalog!.projectMetadata;
      _ensureLoadActive(generation);
      for (final requirement in {
        if (manifest.contactDevice != null) ProjectContactDeviceConfig.capabilityId,
        if (SpatialGameplayCapabilities.requiresSceneMusic(manifest)) SpatialGameplayCapabilities.sceneMusicCapabilityId,
        if (SpatialGameplayCapabilities.requiresAudio(manifest)) SpatialGameplayCapabilities.audioCapabilityId,
        if (SpatialGameplayCapabilities.requiresCinematicFade(manifest)) SpatialGameplayCapabilities.cinematicFadeCapabilityId,
      }) {
        if (!descriptor.grantedCapabilities.contains(requirement)) throw StateError('The project requires $requirement.');
      }
      if (manifest.partyCompanion.enabled &&
          !descriptor.grantedCapabilities.contains(SpatialGameplayCapabilities.companionCapabilityId)) {
        throw StateError('A party companion requires ${SpatialGameplayCapabilities.companionCapabilityId}.');
      }
      if (manifest.settings.dimension != ProjectDimension.threeD ||
          manifest.maps.isEmpty) {
        throw StateError('A spatial project with an initial map is required.');
      }
      if (SpatialGameplayCapabilities.requiresStory(manifest) &&
          !descriptor.grantedCapabilities
              .contains(SpatialGameplayCapabilities.storyCapabilityId)) {
        throw StateError(
            'Spatial story playback requires ${SpatialGameplayCapabilities.storyCapabilityId}.');
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
              projectFilePath: path, mapId: mapId, preloadedManifest: manifest,
              projectCatalog: catalog,
              additionalCharacterIds: {
                if (state.trainerProfile.avatarCharacterId case final String id
                    when id.isNotEmpty) id,
              });
      _ensureLoadActive(generation);
      if (bundle.map.id != mapId) {
        throw StateError('The preloaded map does not match the spatial state.');
      }
      _bagItemCatalog = await const RuntimeItemCatalogLoader().loadSnapshot(
        projectRootDirectory: bundle.projectRootDirectory,
        pokemonConfig: manifest.pokemon,
      );
      _ensureLoadActive(generation);
      ensureRuntimeBagCapacity(
        state: state,
        capacity: manifest.bagCapacity,
        itemCatalog: _bagItemCatalog,
      );
      reportProgress(const GameSessionLoadingProgress(
          stage: 'resources', current: 1, total: 3));
      _gameState = state;
      _environmentClock = WorldEnvironmentClock(now: _now, initialState: state.environmentState);
      _environmentClock!.resolve(bundle.visualProfile);
      if (bundle.map.spatialScene?.camera.projection == SpatialCameraProjection.orthographic && !descriptor.grantedCapabilities.contains(SpatialCameraProfile.orthographicCapabilityId)) throw StateError('The map requires ${SpatialCameraProfile.orthographicCapabilityId}.');
      if (SpatialActorOcclusionCapabilities.requiresCapability(manifest, maps: [bundle.map]) &&
          !descriptor.grantedCapabilities.contains(SpatialActorOcclusionCapabilities.capabilityId)) {
        throw StateError('The map requires ${SpatialActorOcclusionCapabilities.capabilityId}.');
      }
      _audioMapId = bundle.map.id;
      _sceneAudio = SpatialSceneAudioRuntime(
        mediaAssets: manifest.cinematicMediaAssets,
        resolvePath: (asset) => p.join(bundle.projectRootDirectory, asset.relativePath),
        mixer: _audioMixer, music: _music, driverFactory: _sceneAudioDriverFactory,
        captureMusicBaseline: _mapMusicSelection,
        onMusicChanged: _applyMusicSelection,
      );
      await _initializeSpatialGameplay(bundle, path,
          generation: generation,
          narrativeSnapshot: preload?.narrativeSnapshot);
      _ensureLoadActive(generation);
      final loaded = await SpatialExplorationSession.load(bundle,
          allowNpcOverlapRecovery: descriptor.launchMode == GameSessionLaunchMode.continueGame,
          knownMaps: _mapsById.values,
          worldStateProvider: () =>
              _sceneStateReader?.call().spatialWorldState ??
              _gameState!.spatialWorldState,
          spatialArrival: position,
          facing: state.playerFacing,
          entityProjection: (mapId, entity) => _gameplay?.projectEntity(mapId, entity,
            gameStateOverride: _stopped || _disposed ? _gameState :
              _gameplay?.projectedSceneGameState ?? _sceneStateReader?.call()),
          presentationStateProvider: () => _gameplay?.projectedSceneGameState ??
            _sceneStateReader?.call() ?? _gameState!,
          entityIsPresent: (mapId, entity) =>
              _gameplay?.entityIsPresent(mapId, entity,
                  gameStateOverride: _stopped || _disposed
                      ? _gameState
                      : _gameplay?.projectedSceneGameState ??
                          _sceneStateReader?.call()) ?? true,
          characterId: state.trainerProfile.avatarCharacterId);
      if (_disposed || _stopped || generation != _loadGeneration) {
        loaded.dispose();
        throw StateError('Exploration closed while loading.');
      }
      loaded.environmentClock = _environmentClock!;
      loaded.realWeather = _realWeather;
      _realWeatherDeclared = WorldEnvironmentCapabilities.requiresRealProject(bundle.manifest);
      _session = loaded;
      if (loaded.movement.spatialPosition != position) {
        _gameState = state.copyWith(playerPosition: GridPos(
            x: loaded.movement.x.floor(), y: loaded.movement.z.floor()),
            playerSpatialPosition: loaded.movement.spatialPosition);
      }
      _story = SpatialStoryPlayback(
        session: loaded,
        readGameState: _readMutableState,
        writeGameState: (state) {
          final writer = _sceneStateWriter;
          if (writer != null) {
            writer(state);
          } else {
            _gameState = state;
          }
        },
      );
      _initializePlayerServices(bundle);
      loaded.interactionActive.addListener(_syncMovement);
      loaded.transitioning.addListener(_syncMovement);
      loaded.mapRevision.addListener(_onMapActivated);
      loaded.onFrame = _publishFrame;
      loaded.onLifecyclePausedChanged = (_) { _syncMusicSuspension(); _configureRealWeather(); };
      if (_preferences case final preferences?) {
        loaded.setTextSpeed(preferences.dialogueTextSpeed);
      }
      _syncMovement();
      _mounted = true;
      _mountFuture = Future<void>.sync(() => _mountSession(this));
      await _mountFuture;
      _ensureLoadActive(generation);
      _syncMapMusic();
      _syncMusicSuspension();
      _configureRealWeather();
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
    if (!_paused && _locks.isEmpty && _session!.nativeDoorTraversalActive &&
        event.isPress && !event.isRepeat &&
        event.control == RuntimeInputControl.secondary) {
      _session!.cancelPendingTransition();
      _syncMovement();
      return true;
    }
    if (!_paused &&
        _locks.isEmpty &&
        _session?.storyActive.value == true &&
        event.isPress &&
        !event.isRepeat) {
      if (event.control == RuntimeInputControl.secondary) {
        _story?.cancel();
        unawaited(_sceneAudio?.reset());
      } else if (event.control == RuntimeInputControl.primary) {
        _story?.skip();
      }
      return true;
    }
    if (!inputAuthority.value.acceptsRuntimeInput) return true;
    if (inputAuthority.value.context == RuntimeInputContext.battle) {
      return _battle?.handleInput(event) ?? true;
    }
    if (inputAuthority.value.context == RuntimeInputContext.dialogue) {
      if (event.isPress && !event.isRepeat) {
        if (event.control == RuntimeInputControl.secondary) {
          _session!.cancelDialogue();
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
    _configureRealWeather();
    if (owner == RuntimeExternalInputLock.lifecycle) _syncMusicSuspension();
    _startPendingContact();
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
    if (!_disposed && !_stopped && (paused || talking || battling || busy)) {
      _story?.autonomousNpcs.update(0, paused: true);
    }
    if (!paused || _stopped) {
      _materializationResumed?.complete();
      _materializationResumed = null;
    }
    _session?.dialoguePaused = _paused || _stopped || _locks.isNotEmpty;
    _session?.movement.setPaused(paused || talking || battling || busy,
        preserveInput: !paused && !talking && !battling);
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
    _story?.autonomousNpcs.update(0, paused: true);
    _playWatch.stop();
    if ((_session?.transitioning.value ?? false) &&
        !(_session?.nativeDoorTraversalActive ?? false)) {
      _session!.cancelPendingTransition();
    }
    _syncMovement();
    _configureRealWeather();
  }

  @override
  Future<void> resume() async {
    _ensureOpen();
    _paused = false;
    if (!_stopped && _session != null) _playWatch.start();
    _syncMovement();
    _configureRealWeather();
    _startPendingContact();
  }

  void _startPendingContact() {
    if (_disposed || _stopped || _paused || _locks.isNotEmpty) return;
    final contactId = _pendingContactId;
    _pendingContactId = null;
    if (contactId != null) {
      unawaited(_runGameplay(() async {
        final called = await _gameplay?.callContact(contactId) ?? false;
        if (!called && !_disposed && !_stopped) throw StateError('The contact conversation is unavailable.');
      }));
    }
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
    if (_session != null && !_session!.movement.isPositionTraversable) {
      throw StateError('The spatial checkpoint position is blocked.');
    }
    return _activityGate.runCheckpoint(NarrativeRuntimeCheckpointOperation.save,
        () async {
      _story?.autonomousNpcs.flush();
      return _checkpointFromState(gameStateSnapshot);
    });
  }

  GameSessionCheckpoint _checkpointFromState(GameState state) {
    ensureRuntimeBagCapacity(
      state: state,
      capacity: _session!.bundle.manifest.bagCapacity,
      itemCatalog: _bagItemCatalog,
    );
    return GameSessionCheckpoint(
        saveId: state.saveId,
        createdAt: _createdAt!,
        updatedAt: _now().toUtc(),
        playTimeSeconds: _basePlayTimeSeconds + _playWatch.elapsed.inSeconds,
        state: strictGameStateSaveJson(state.copyWith(environmentState: _environmentClock?.checkpoint ?? state.environmentState)));
  }

  void _initializePlayerServices(RuntimeMapBundle bundle) {
    final services = PlayerServiceRuntimeController.contextual(
        currentGameState: () {
          _story?.autonomousNpcs.flush();
          return _sceneStateReader?.call() ?? gameStateSnapshot;
        },
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
        bagCapacity: bundle.manifest.bagCapacity,
        itemCatalog: _bagItemCatalog,
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

  Future<void> _persistNativeItemPickup(GameState state) async {
    _ensureGameplayActive();
    if (!(_gameplay?.isBusy ?? false) ||
        _activityGate.activity != NarrativeRuntimeActivity.dispatching ||
        _activityGate.checkpointInProgress) {
      throw StateError('The native item pickup does not own a stable spatial operation.');
    }
    ensureRuntimeBagCapacity(state: state, capacity: _session!.bundle.manifest.bagCapacity,
        itemCatalog: _bagItemCatalog);
    final commit = _commitCheckpoint;
    if (commit == null) throw StateError('The host does not provide item pickup persistence.');
    await commit(GameSessionCheckpointCommit(descriptor: descriptor.publicContext,
        checkpoint: _checkpointFromState(state), status: SaveStatus.active,
        trigger: GameSessionCheckpointTrigger.pauseMutation));
    _ensureGameplayActive();
  }

  Future<void> _presentNativeItemPickup(MapEntity entity, SpatialItemPickupResult result, String itemLabel) async {
    final services = _playerServices;
    if (services == null) throw StateError('The native item presenter is unavailable.');
    final full = result.outcome == SpatialItemPickupOutcome.bagFull;
    final id = 'item-${_runtimeIds.generate(existingRecords: const []).substring(3)}';
    await services.openSceneTextInteraction(request: OpenSceneTextInteractionService(
      interactionId: id,
      interaction: SceneMessageInteractionRequest(requestId: id, revision: 0,
        prompt: SceneInteractionPrompt(localizationKey: full ? 'overworld.item.bagFull' : 'overworld.item.received',
          fallbackText: full ? 'Le Sac est plein...' : 'Obtenu : $itemLabel × ${entity.item!.quantity} !'))));
  }

  Future<void> _commitPlayerServiceState(GameState state) async {
    _ensureGameplayActive();
    ensureRuntimeBagCapacity(
      state: state,
      capacity: _session!.bundle.manifest.bagCapacity,
      itemCatalog: _bagItemCatalog,
    );
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
      _playerServices?.worldServiceSnapshot;

  @override
  Stream<RuntimeWorldServiceSnapshot?> get worldServiceSnapshots =>
      _worldServiceSnapshots.stream;

  void _publishWorldService(RuntimeWorldServiceSnapshot? snapshot) {
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
      if (command.kind == RuntimePlayerPauseCommandKind.callContact) {
        final contactId = command.contactId;
        try {
          if (contactId == null || _pendingContactId != null || _gameplay == null) throw StateError('Contact unavailable.');
          ContactDeviceAccess.resolve(project: _session!.bundle.manifest, state: gameStateSnapshot).sceneForContact(contactId);
          _pendingContactId = contactId;
          return const RuntimePlayerPauseCommandResult(status: RuntimePlayerPauseCommandStatus.accepted, safeMessage: '', resumeGameplay: true);
        } on StateError {
          return const RuntimePlayerPauseCommandResult(status: RuntimePlayerPauseCommandStatus.unavailable, safeMessage: 'Contact indisponible.');
        }
      }
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
    _pendingContactId = null;
    _story?.autonomousNpcs.flush();
    _story?.cancel();
    if (_disposed) return;
    _stopped = true;
    _weatherTimer?.cancel();
    final sceneAudioStopped = _sceneAudio?.dispose();
    final musicStopped = _music.dispose();
    _loadGeneration++;
    _playWatch.stop();
    _gameplay?.invalidate();
    _battle?.cancel();
    _session?.cancelPendingTransition();
    _session?.closeDialogue();
    _syncMovement();
    await _rollbackPendingSceneWarp();
    await sceneAudioStopped;
    await musicStopped;
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
    final contactPortraits = DialoguePortraitResolver(manifest: manifest, projectRootDirectory: session.bundle.projectRootDirectory);
    if (manifest.contactDevice != null) {
      await contactPortraits.ensureCatalogLoaded(characterIds: manifest.contactDevice!.contacts.map((c) => c.characterId).whereType<String>());
    }
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
        pauseMenuState: state.pauseMenuState, pauseDetails: {
          ...details,
          if (buildContactDevicePauseDetail(project: manifest, state: state, portraitLookup: contactPortraits.resolve) case final contactDetail?)
            RuntimePlayerPauseSection.contacts: contactDetail,
        });
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _pendingContactId = null;
    _story?.autonomousNpcs.flush();
    _story?.cancel();
    _disposed = true;
    final sceneAudioStopped = _sceneAudio?.dispose();
    final musicStopped = _music.dispose();
    _projectCatalog?.dispose();
    _projectCatalog = null;
    _stopped = true;
    _weatherTimer?.cancel();
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
      await _rollbackPendingSceneWarp();
    } finally {
      try {
        await _playerServiceSnapshots?.cancel();
        _playerServiceSnapshots = null;
        final services = _playerServices;
        _playerServices = null;
        await services?.dispose();
        _publishWorldService(null);
        await _mountFuture?.catchError((Object _) {});
      } finally {
        try {
          if (_mounted) await _unmountSession(this);
        } finally {
          _mounted = false;
          _story?.dispose();
          _story = null;
          _session?.interactionActive.removeListener(_syncMovement);
          _session?.transitioning.removeListener(_syncMovement);
          _session?.mapRevision.removeListener(_onMapActivated);
          if (_session case final session?) session.onLifecyclePausedChanged = null;
          _weatherTimer?.cancel();
          _session?.dispose();
          _session = null;
          overworldInteractions.dispose();
          await _interactionEvents.close();
          await _worldServiceSnapshots.close();
          inputAuthority.dispose();
          await _events.close();
          await sceneAudioStopped;
    await musicStopped;
        }
      }
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
