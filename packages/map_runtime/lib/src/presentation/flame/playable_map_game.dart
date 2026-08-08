import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import '../../../domain/repositories/game_save_repository.dart';
import '../../../src/application/load_game_use_case.dart';
import '../../../src/application/save_game_use_case.dart';
import '../../../src/infrastructure/file_game_save_repository.dart';
import '../../application/battle_start_request.dart';
import '../../application/cutscene_runtime_models.dart';
import '../../application/cutscene_runtime_runner.dart';
import '../../application/dialogue_runtime_models.dart';
import '../../application/dialogue_variable_interpolation.dart';
import '../../application/encounter_to_battle_request.dart';
import '../../application/field_move_dialogue.dart';
import '../../application/global_story_chapter_runtime.dart';
import '../../application/load_dialogue_content.dart';
import '../../application/load_runtime_map_bundle.dart';
import '../../application/map_activation.dart';
import '../../application/map_entity_runtime_predicate_evaluator.dart';
import '../../application/map_enter_production_dispatch_bridge.dart';
import '../../application/movement_feedback.dart';
import '../../application/narrative_event_runtime_snapshot.dart';
import '../../application/narrative_runtime_activity_gate.dart';
import '../../application/narrative_runtime_activity_port.dart';
import '../../application/narrative_scene_runtime_execution.dart';
import '../../application/narrative_spatial_production_dispatch_bridge.dart';
import '../../application/npc_overworld_movement_defaults.dart';
import '../../application/npc_runtime_presence.dart';
import '../../application/placed_behavior_runtime_cooldown.dart';
import '../../application/player_service_runtime_controller.dart';
import '../../player/runtime_input_lock_manager.dart';
import '../../player/runtime_audio_mixer.dart';
import '../../player/runtime_world_service_models.dart';
import '../../application/resolve_dialogue.dart';
import '../../application/runtime_battle_setup_mapper.dart';
import '../../application/runtime_battle_outcome_apply.dart';
import '../../application/runtime_battle_reward_resolver.dart';
import '../../application/runtime_battle_bag_hp_heal_item_apply.dart';
import '../../application/runtime_battle_combatant_seed_builder.dart';
import '../../application/runtime_character_refs.dart';
import '../../application/runtime_map_bundle.dart';
import '../../application/runtime_move_catalog_loader.dart';
import '../../application/runtime_player_pokemon_progression_hydrator.dart';
import '../../application/runtime_pokemon_learnset_loader.dart';
import '../../application/runtime_pokemon_evolution_loader.dart';
import '../../application/runtime_pokemon_species_loader.dart';
import '../../application/runtime_post_battle_decision_coordinator.dart';
import '../../application/runtime_psdk_battle_session_adapter.dart';
import '../../application/runtime_psdk_battle_setup_mapper.dart';
import '../../application/runtime_story_branching.dart';
import '../../application/runtime_trainer_lifecycle_policy.dart';
import '../../application/scene_runtime/scene_battle_runtime_outcome_adapter.dart';
import '../../application/scene_runtime/scene_battle_runtime_outcome_result.dart';
import '../../application/scene_runtime/cinematic_runtime_playback_controller.dart';
import '../../application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart';
import '../../application/scene_runtime/scene_consequence_runtime_writer.dart';
import '../../application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart';
import '../../application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart';
import '../../application/scene_runtime/scene_event_runtime_hook.dart';
import '../../application/scene_runtime/scene_fact_condition_runtime_resolver.dart';
import '../../application/scene_runtime/scene_interactive_command_runtime_executor.dart';
import '../../application/scene_runtime/scene_npc_state_metadata.dart';
import '../../application/scene_runtime/narrative_game_completion_runtime_coordinator.dart';
import '../../application/scene_runtime/scene_runtime_host_callbacks.dart';
import '../../application/scene_runtime/scene_runtime_hook_result.dart';
import '../../application/scenario_runtime/scenario_runtime_executor.dart';
import '../../application/scenario_runtime/scenario_runtime_models.dart';
import '../../application/scenario_runtime/scenario_battle_outcome_flags.dart';
import '../../application/scenario_runtime_completion_gate.dart';
import '../../application/script_runtime_controller.dart';
import '../../application/script_runtime_state.dart';
import '../../application/scripted_entity_movement_controller.dart';
import '../../application/scripted_entity_movement_models.dart';
import '../../application/scripted_npc_anchor_passability.dart';
import '../../application/step_studio_completion_runtime.dart';
import '../../application/step_studio_world_presence_runtime.dart';
import '../../application/story_flags_manager.dart';
import '../../application/trainer_battle_request.dart';
import '../../application/world_rules/runtime_world_rule_projection_hook.dart';
import '../../border/border_runtime_asset_cache.dart';
import '../../border/border_runtime_readiness.dart';
import '../../infrastructure/runtime_tileset_image.dart';
import '../../infrastructure/tile_image_loader.dart';
import '../../shadow/runtime_actor_contact_shadow_collection.dart';
import '../../shadow/runtime_projected_building_shadow_collection.dart';
import '../../shadow/runtime_shadow_collection_merge.dart';
import '../../shadow/runtime_static_placed_element_shadow_sources.dart';
import '../../shadow/shadow_runtime_collection_provider.dart';
import '../../shadow/shadow_runtime_instruction_collection.dart';
import 'battle_bag_menu_model.dart';
import 'battle_bag_item_icon_resolver.dart';
import 'battle_fx_bundle_cache.dart';
import 'battle_overlay_component.dart';
import 'battle_background_resolver.dart';
import 'battle_medicine_target_menu_model.dart';
import 'battle_pokemon_sprite_resolver.dart';
import '../flutter/battle_command_overlay_snapshot.dart';
import '../flutter/dialogue_presentation_snapshot.dart';
import '../flutter/post_battle_presentation_snapshot.dart';
import '../flutter/runtime_notification_snapshot.dart';
import 'battle_visual_asset_cache.dart';
import 'runtime_input_event.dart';
import 'runtime_input_authority.dart';
import 'runtime_input_key_bindings.dart';
import 'battle_transition_overlay_component.dart';
import 'dialogue_overlay_component.dart';
import 'dialogue_text_speed.dart';
import 'flame_cinematic_fx_playback_adapter.dart';
import 'flame_cinematic_media_playback_adapter.dart';
import 'flame_cinematic_runtime_playback_sink.dart';
import 'map_layers_component.dart';
import 'overworld_actor_component.dart';
import 'player_component.dart';
import 'placed_element_occlusion_patch_component.dart';
import 'post_battle_progression_overlay_component.dart';
import 'runtime_battle_gender_overrides.dart';
import 'runtime_trainer_battle_overrides.dart';
import 'static_placed_element_occlusion_patch_resolution.dart';
import 'warp_transition_overlay_component.dart';

const double _kViewportTilesX = 15.0;
const double _kViewportTilesY = 11.0;
const double _kWaterRequiresSurfMessageCooldownMs = 900;
const bool _kVerboseEncounterLogs = false;

enum _RuntimeFlowPhase {
  overworld,
  blockingInteraction,
  dialogue,
  mapTransition,
  battleTransition,
  battle,
}

RuntimeInputLockOwner _inputOwnerForExternalLock(
  RuntimeExternalInputLock lock,
) =>
    switch (lock) {
      RuntimeExternalInputLock.pauseMenu => RuntimeInputLockOwner.pauseMenu,
      RuntimeExternalInputLock.lifecycle => RuntimeInputLockOwner.lifecycle,
      RuntimeExternalInputLock.playerService =>
        RuntimeInputLockOwner.playerService,
      RuntimeExternalInputLock.gameCompletion =>
        RuntimeInputLockOwner.gameCompletion,
    };

RuntimeInputSurface _inputSurfaceForExternalLock(
  RuntimeExternalInputLock lock,
) =>
    switch (lock) {
      RuntimeExternalInputLock.pauseMenu => RuntimeInputSurface.pause,
      RuntimeExternalInputLock.lifecycle => RuntimeInputSurface.background,
      RuntimeExternalInputLock.playerService =>
        RuntimeInputSurface.playerService,
      RuntimeExternalInputLock.gameCompletion => RuntimeInputSurface.completion,
    };

final class _NarrativeOutcomeRetryPendingException implements Exception {
  const _NarrativeOutcomeRetryPendingException({
    required this.deliveryId,
    required this.failure,
  });

  final String deliveryId;
  final Object failure;

  @override
  String toString() {
    return 'Narrative outcome delivery "$deliveryId" is pending a future '
        'retry: $failure';
  }
}

typedef RuntimeMapBundleLoader = Future<RuntimeMapBundle> Function({
  required String projectFilePath,
  required String mapId,
});

typedef RuntimeTilesetImageLoader = Future<Map<String, RuntimeTilesetImage>>
    Function(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId,
});
typedef RuntimeDialogueSessionLoader = Future<DialogueSession?> Function(
  ResolvedDialogue resolved,
);
typedef RuntimePostBattleOverlayMounter = Future<void> Function(
  PostBattleProgressionOverlayComponent overlay,
);
typedef DefeatRecoveryCheckpointEmitter = Future<void> Function();

class PlayableMapGame extends FlameGame with KeyboardEvents {
  PlayableMapGame({
    required RuntimeMapBundle bundle,
    required this.projectFilePath,
    SaveData? saveData,
    GameSaveRepository? saveRepository,
    this.bundleTransformer,
    this.runtimeCutscenes = const <RuntimeCutsceneAsset>[],
    RuntimeDialogueSessionLoader? dialogueSessionLoader,
    RuntimeMapBundleLoader? runtimeMapBundleLoader,
    RuntimeTilesetImageLoader? runtimeTilesetImageLoader,
    RuntimePlayerPokemonProgressionCatalogLoader?
        runtimePlayerPokemonProgressionCatalogLoader,
    @visibleForTesting math.Random? encounterRandom,
    RuntimePostBattleDecisionCoordinator? postBattleDecisionCoordinator,
    @visibleForTesting this.postBattleOverlayMounter,
    @visibleForTesting this.beforePostBattleStateCommit,
    this.initialMapActivationReason = MapActivationReason.initialBoot,
    NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
    @visibleForTesting this.beforeNarrativeAuthorityPreparation,
    @visibleForTesting this.afterNarrativeAuthorityPreparation,
    @visibleForTesting this.beforeBattleHandoffPreparation,
    @visibleForTesting this.beforeLoadCommitCompletion,
    @visibleForTesting this.afterInitialTilesetImagesLoaded,
    GameCompletionRequestEmitter? gameCompletionEmitter,
    this.defeatRecoveryCheckpointEmitter,
    @visibleForTesting this.defeatRecoveryCapsLoader,
    this.runtimeLocale = 'fr-FR',
    String? initialPlayerName,
    String? initialPlayerAvatarCharacterId,
    PlayerPronounSet? initialPlayerPronounSet,
    this.shadowCollectionProvider,
    this.enableActorContactShadows = true,
    this.enableStaticPlacedElementShadows = true,
    RuntimeAudioMixer? audioMixer,
  })  : _bundle = bundle,
        _gameState = normalizeLoadedGameState(
          saveData == null
              ? const GameState(saveId: 'default')
              : gameStateFromSaveData(saveData),
        ),
        _dialogueSessionLoader = dialogueSessionLoader ?? loadDialogueContent,
        _runtimeMapBundleLoader =
            runtimeMapBundleLoader ?? loadRuntimeMapBundle,
        _runtimeTilesetImageLoader =
            runtimeTilesetImageLoader ?? loadTilesetImagesById,
        _runtimePlayerPokemonProgressionCatalogLoader =
            runtimePlayerPokemonProgressionCatalogLoader ??
                loadRuntimePlayerPokemonProgressionCatalogs,
        _encounterRandom = encounterRandom ?? math.Random() {
    if (bundleTransformer != null) {
      _bundle = bundleTransformer!(_bundle);
    }
    _gameCompletionCoordinator = gameCompletionEmitter == null
        ? null
        : NarrativeGameCompletionRuntimeCoordinator(
            project: _bundle.manifest,
            locale: runtimeLocale,
            emitCompletion: gameCompletionEmitter,
          );
    _isProjectNewGameBoot =
        saveData == null && _bundle.manifest.newGame.enabled;
    if (_isProjectNewGameBoot) {
      _gameState = createNewGameStateFromProject(
        project: _bundle.manifest,
        startMap: _bundle.map,
        saveId: 'new_game',
        playerName: initialPlayerName,
        playerAvatarCharacterId: initialPlayerAvatarCharacterId,
        playerPronounSet: initialPlayerPronounSet,
        locale: runtimeLocale,
        tileWidthPx: _bundle.manifest.settings.tileWidth,
        tileHeightPx: _bundle.manifest.settings.tileHeight,
      );
    }
    _gameState = applyPlayerIdentityDialogueVariables(
      _gameState,
      locale: runtimeLocale,
    );
    _narrativeActivityGate =
        narrativeRuntimeActivityGate ?? NarrativeRuntimeActivityGate();
    _saveRepo = saveRepository ??
        FileGameSaveRepository(activityGate: _narrativeActivityGate);
    _narrativeStateTransactions = NarrativeEventStateTransactions(_gameState);
    _mapEnterDispatchBridge = MapEnterProductionDispatchBridge(
      stateTransactions: _narrativeStateTransactions,
      currentGameState: () => _gameState,
      onGameStateCommitted: _applyNarrativeGameState,
      prepareAuthority: (_, occurrence) =>
          _prepareNarrativeDispatchAuthority(occurrence),
      executeScene: _executeNarrativeScene,
      legacyFallback: _dispatchLegacyMapEnterFallback,
      activityPort: NarrativeRuntimeActivityPort(_narrativeActivityGate),
      beforeSaveRestoreDispatch: _drainRestoredNarrativeOutcomeOutbox,
      isCurrentActivation: (activationId) =>
          activationId == _currentMapActivationId,
      executionIdFactory: () => _nextNarrativeRuntimeId('evx'),
      correlationIdFactory: () => _nextNarrativeRuntimeId('corr'),
      deliveryIdFactory: () => _nextNarrativeRuntimeId('outd'),
    );
    _spatialDispatchBridge = NarrativeSpatialProductionDispatchBridge(
      stateTransactions: _narrativeStateTransactions,
      currentGameState: () => _gameState,
      onGameStateCommitted: _applyNarrativeGameState,
      prepareAuthority: (_, occurrence) =>
          _prepareNarrativeDispatchAuthority(occurrence),
      executeScene: _executeNarrativeScene,
      legacyFallback: _dispatchLegacySpatialFallback,
      activityPort: NarrativeRuntimeActivityPort(_narrativeActivityGate),
      isCurrentOccurrence: _isCurrentSpatialOccurrence,
      executionIdFactory: () => _nextNarrativeRuntimeId('evx'),
      correlationIdFactory: () => _nextNarrativeRuntimeId('corr'),
      deliveryIdFactory: () => _nextNarrativeRuntimeId('outd'),
    );
    _narrativeOutcomeOutboxProcessor = NarrativeOutcomeOutboxProcessor(
      stateTransactions: _narrativeStateTransactions,
      dispatcher: _dispatchNarrativeOutcome,
      activityPort: NarrativeRuntimeActivityPort(_narrativeActivityGate),
      deliveryIdFactory: () => _nextNarrativeRuntimeId('outd'),
    );
    _saveGameUseCase = SaveGameUseCase(_saveRepo);
    _loadGameUseCase = LoadGameUseCase(_saveRepo);
    _battleSpriteResolver = BattlePokemonSpriteResolver(
      manifest: _bundle.manifest,
      projectRootDirectory: _bundle.projectRootDirectory,
    );
    _battleBagItemIconResolver = BattleBagItemIconResolver(
      manifest: _bundle.manifest,
      projectRootDirectory: _bundle.projectRootDirectory,
    );
    final evolutionLoader = RuntimePokemonEvolutionLoader(
      speciesLoader: _battleSpeciesLoader,
    );
    _postBattleDecisionCoordinator = postBattleDecisionCoordinator ??
        RuntimePostBattleDecisionCoordinator(
          rewardResolver: RuntimeBattleRewardResolver(
            loadSpecies: _battleSpeciesLoader.loadById,
            loadMoveLearningCandidates:
                _battleLearnsetLoader.loadLevelUpCandidates,
            loadEvolutionCandidates: evolutionLoader.loadLevelUpCandidates,
          ),
        );
    _cinematicRuntimeHost = _PlayableMapCinematicRuntimeHost(this);
    final cinematicFxPlayback = FlameCinematicFxPlaybackAdapter(
      host: _cinematicRuntimeHost,
    );
    final cinematicMediaPlayback = FlameCinematicMediaPlaybackAdapter(
      mediaAssets: _bundle.manifest.cinematicMediaAssets,
      resolvePath: (asset) => p.normalize(
        p.join(_bundle.projectRootDirectory, asset.relativePath),
      ),
      fx: cinematicFxPlayback,
      audioMixer: audioMixer,
    );
    _cinematicRuntimeSink = FlameCinematicRuntimePlaybackSink(
      host: _cinematicRuntimeHost,
      mediaPlaybackPort: cinematicMediaPlayback,
      dialogues: _bundle.manifest.dialogues,
      mediaAssets: _bundle.manifest.cinematicMediaAssets,
    );
    _cinematicRuntimeController = CinematicRuntimePlaybackController(
      sink: _cinematicRuntimeSink,
    );
    _tilesetImageCache = RuntimeTilesetImageSingleFlightCache(
      loader: _runtimeTilesetImageLoader,
    );
  }

  final String projectFilePath;
  final RuntimeMapBundle Function(RuntimeMapBundle bundle)? bundleTransformer;
  final List<RuntimeCutsceneAsset> runtimeCutscenes;
  final MapActivationReason initialMapActivationReason;
  final String runtimeLocale;

  /// Deterministic async instrumentation for activation-dispatch race tests.
  ///
  /// Production callers must leave this unset. The callback runs before the
  /// production authority snapshot is prepared and must not mutate runtime
  /// state.
  @visibleForTesting
  final Future<void> Function(NarrativeEventOccurrence occurrence)?
      beforeNarrativeAuthorityPreparation;
  @visibleForTesting
  final Future<void> Function(
    NarrativeEventOccurrence occurrence,
    NarrativeEventDispatchAuthorityPreparation preparation,
  )? afterNarrativeAuthorityPreparation;
  @visibleForTesting
  final Future<void> Function()? beforeBattleHandoffPreparation;
  @visibleForTesting
  final Future<void> Function()? beforeLoadCommitCompletion;
  @visibleForTesting
  final Future<void> Function()? afterInitialTilesetImagesLoaded;
  @visibleForTesting
  final RuntimePostBattleOverlayMounter? postBattleOverlayMounter;
  @visibleForTesting
  final VoidCallback? beforePostBattleStateCommit;
  final DefeatRecoveryCheckpointEmitter? defeatRecoveryCheckpointEmitter;
  @visibleForTesting
  final PlayerServiceRecoveryCapsLoader? defeatRecoveryCapsLoader;
  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
  final bool enableActorContactShadows;
  final bool enableStaticPlacedElementShadows;
  RuntimeMapBundle _bundle;
  GameState _gameState;
  late final bool _isProjectNewGameBoot;
  late GameplayWorldState _world;
  late PlayerComponent _player;
  bool _actorContactShadowRuntimeReady = false;
  String _activeMapId = '';
  String? _previousMapId;
  _RuntimeFlowPhase _flowPhase = _RuntimeFlowPhase.overworld;
  final RuntimeInputLockManager _inputLocks = RuntimeInputLockManager();
  RuntimeInputLockToken? _flowInputLock;
  RuntimeInputLockToken? _cinematicInputLock;
  final Map<RuntimeInputLockOwner, RuntimeInputLockToken> _derivedInputLocks =
      <RuntimeInputLockOwner, RuntimeInputLockToken>{};
  final Map<RuntimeExternalInputLock, RuntimeInputLockToken>
      _externalInputLocks = <RuntimeExternalInputLock, RuntimeInputLockToken>{};
  final Set<RuntimeInputControl> _pressedMovementControls =
      <RuntimeInputControl>{};
  RuntimeInputControl? _lastMovementControl;
  TriggeredWarp? _pendingWarp;
  TriggeredConnection? _pendingConnection;
  BattleStartRequest? _pendingBattleRequest;
  Completer<SceneBattleRuntimeOutcomeResult>?
      _pendingSceneBattleOutcomeCompleter;
  String? _pendingSceneBattleRequestId;
  _NarrativeSceneWorkingSession? _activeNarrativeSceneWorkingSession;
  PlayerServiceRuntimeController? _playerServiceRuntimeController;
  Completer<SceneDialogueRuntimeAwaitableResult>?
      _pendingSceneDialogueCompleter;
  String? _pendingSceneDialogueRequestId;
  PlacedElementInteracted? _pendingPlacedElementBehavior;
  DialogueOverlayComponent? _dialogueOverlay;
  RuntimeDialogueTextSpeed _dialogueTextSpeed =
      RuntimeDialogueTextSpeed.instant;
  final ValueNotifier<DialoguePresentationSnapshot?>
      _dialoguePresentationNotifier =
      ValueNotifier<DialoguePresentationSnapshot?>(null);
  final ValueNotifier<RuntimeInputAuthoritySnapshot> _inputAuthorityNotifier =
      ValueNotifier<RuntimeInputAuthoritySnapshot>(
    const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld,
    ),
  );
  DialoguePresentationSnapshot? _pendingDialoguePresentationSnapshot;
  bool _dialoguePresentationPostFrameFlushScheduled = false;
  bool _preferDialogueFlutterOverlay = false;
  BattleTransitionOverlayComponent? _battleTransitionOverlay;
  BattleOverlayComponent? _battleOverlay;
  PostBattleProgressionOverlayComponent? _postBattleProgressionOverlay;
  final ValueNotifier<PostBattlePresentationSnapshot?>
      _postBattlePresentationNotifier =
      ValueNotifier<PostBattlePresentationSnapshot?>(null);
  PostBattlePresentationSnapshot? _pendingPostBattlePresentationSnapshot;
  bool _postBattlePresentationPostFrameFlushScheduled = false;
  bool _preferPostBattleFlutterOverlay = false;
  WarpTransitionOverlayComponent? _warpTransitionOverlay;
  TextComponent? _notification;
  final ValueNotifier<RuntimeNotificationSnapshot?>
      _runtimeNotificationNotifier =
      ValueNotifier<RuntimeNotificationSnapshot?>(null);
  RuntimeNotificationSnapshot? _pendingRuntimeNotificationSnapshot;
  bool _runtimeNotificationPostFrameFlushScheduled = false;
  bool _preferFlutterNotifications = false;
  int _runtimeNotificationRevision = 0;
  final List<OverworldActorComponent> _npcActors = [];
  final ShadowRuntimeCollectionController _actorShadowCollectionController =
      ShadowRuntimeCollectionController();
  List<RuntimeActorContactShadowSource>? _lastActorShadowSources;
  final Map<String, ShadowRuntimeInstructionCollection>
      _projectedBuildingShadowCollectionByMapId =
      <String, ShadowRuntimeInstructionCollection>{};
  final Map<String, ShadowRuntimeInstructionCollection>
      _staticShadowCollectionByMapId =
      <String, ShadowRuntimeInstructionCollection>{};
  final Map<String, _MergedShadowCollectionCache>
      _mergedShadowCollectionCacheByMapId =
      <String, _MergedShadowCollectionCache>{};
  final Map<String, _LoadedPlayableMap> _loadedMapsById = {};
  final Map<String, Future<_LoadedPlayableMap?>> _loadMapFutureById = {};
  final RuntimeDialogueSessionLoader _dialogueSessionLoader;
  final RuntimeMapBundleLoader _runtimeMapBundleLoader;
  final RuntimeTilesetImageLoader _runtimeTilesetImageLoader;
  late final RuntimeTilesetImageSingleFlightCache _tilesetImageCache;
  bool _isRemoved = false;
  bool _onLoadInProgress = false;
  final RuntimePlayerPokemonProgressionCatalogLoader
      _runtimePlayerPokemonProgressionCatalogLoader;
  final Map<String, RuntimeMapBundle> _runtimeBundleByMapId =
      <String, RuntimeMapBundle>{};
  final Map<String, Future<RuntimeMapBundle>> _runtimeBundleFutureByMapId =
      <String, Future<RuntimeMapBundle>>{};
  final Map<String, Future<void>> _prewarmedWarpTargetFutureByMapId =
      <String, Future<void>>{};
  final Map<String, Future<void>> _prewarmedBattleDataFutureByKey =
      <String, Future<void>>{};
  final BorderRuntimeAssetCache _borderRuntimeAssetCache =
      BorderRuntimeAssetCache();

  /// Injected only by deterministic acceptance tests. Production retains a
  /// fresh random source and the encounter engine remains the sole consumer.
  final math.Random _encounterRandom;
  final GridPathfinder _followPathfinder = const GridPathfinder();
  final RuntimeMoveCatalogLoader _battleMoveCatalogLoader =
      RuntimeMoveCatalogLoader();
  final RuntimePokemonSpeciesLoader _battleSpeciesLoader =
      RuntimePokemonSpeciesLoader();
  late final RuntimePokemonLearnsetLoader _battleLearnsetLoader =
      RuntimePokemonLearnsetLoader(
    moveCatalogLoader: _battleMoveCatalogLoader,
  );
  late final BattlePokemonSpriteResolver _battleSpriteResolver;
  late final BattleBagItemIconResolver _battleBagItemIconResolver;
  late final RuntimePostBattleDecisionCoordinator
      _postBattleDecisionCoordinator;
  late final _PlayableMapCinematicRuntimeHost _cinematicRuntimeHost;
  late final FlameCinematicRuntimePlaybackSink _cinematicRuntimeSink;
  late final CinematicRuntimePlaybackController _cinematicRuntimeController;
  final BattleVisualAssetCache _battleVisualAssetCache =
      BattleVisualAssetCache();

  /// Cache FX au scope jeu : construit par combat auparavant, chaque combat
  /// re-décodait les mêmes PNG et orphelinait les images du combat précédent.
  final BattleFxBundleCache _battleFxBundleCache = BattleFxBundleCache();
  late final RuntimeBattleSetupMapper _battleSetupMapper =
      RuntimeBattleSetupMapper(
    moveCatalogLoader: _battleMoveCatalogLoader,
    combatantSeedBuilder: RuntimeBattleCombatantSeedBuilder(
      speciesLoader: _battleSpeciesLoader,
      learnsetLoader: _battleLearnsetLoader,
    ),
  );
  late final RuntimePsdkBattleSetupMapper _psdkBattleSetupMapper =
      RuntimePsdkBattleSetupMapper(
    moveCatalogLoader: _battleMoveCatalogLoader,
    combatantSeedBuilder: RuntimeBattleCombatantSeedBuilder(
      speciesLoader: _battleSpeciesLoader,
      learnsetLoader: _battleLearnsetLoader,
    ),
  );
  final BattleBackgroundResolver _battleBackgroundResolver =
      const BattleBackgroundResolver();
  final PlacedBehaviorCooldownGate _placedBehaviorCooldownGate =
      PlacedBehaviorCooldownGate();
  final StoryFlagsManager _storyFlags = const StoryFlagsManager();
  final RuntimeStoryBranching _storyBranching = const RuntimeStoryBranching();
  final ScenarioRuntimeExecutor _scenarioRuntime =
      const ScenarioRuntimeExecutor();
  ProjectManifest? _cachedNarrativeFactResolverManifest;
  NarrativeFactRuntimeResolver? _cachedNarrativeFactResolver;

  NarrativeFactRuntimeResolver get _narrativeFactResolver {
    final manifest = _bundle.manifest;
    if (!identical(_cachedNarrativeFactResolverManifest, manifest)) {
      _cachedNarrativeFactResolverManifest = manifest;
      _cachedNarrativeFactResolver =
          NarrativeFactRuntimeResolver.fromFacts(manifest.facts);
    }
    return _cachedNarrativeFactResolver!;
  }

  MapActivation _createMapActivation({
    required String mapId,
    required MapActivationReason reason,
  }) {
    final activation = MapActivation(
      activationId:
          'mapact_${DateTime.now().microsecondsSinceEpoch}_${++_nextMapActivationSerial}',
      mapId: mapId,
      reason: reason,
    );
    return activation;
  }

  void _installMapActivation(MapActivation activation) {
    _currentMapActivationId = activation.activationId;
  }

  bool get _blocksOverworldForMapActivationWork =>
      _flowPhase == _RuntimeFlowPhase.overworld &&
      (_isLoadActivationWorkInFlight ||
          _inFlightMapActivationDispatchIds.isNotEmpty);

  bool get _blocksOverworldForNarrativeDispatch =>
      _flowPhase == _RuntimeFlowPhase.overworld &&
      (_inFlightSpatialDispatchCount > 0 ||
          _narrativeOutcomeDrainFuture != null ||
          _inFlightRootOutcomePublicationCount > 0);

  bool get _hasCheckpointUnsafeRuntimeWork =>
      _flowPhase == _RuntimeFlowPhase.mapTransition ||
      _flowPhase == _RuntimeFlowPhase.battleTransition ||
      _flowPhase == _RuntimeFlowPhase.battle ||
      _pendingBattleRequest != null ||
      _isLoadActivationWorkInFlight ||
      _inFlightMapActivationDispatchIds.isNotEmpty ||
      _inFlightSpatialDispatchCount > 0 ||
      _narrativeOutcomeDrainFuture != null ||
      _inFlightRootOutcomePublicationCount > 0 ||
      _narrativeActivityGate.activity != NarrativeRuntimeActivity.idle ||
      _narrativeActivityGate.checkpointInProgress ||
      isCutsceneRunning ||
      _cinematicRuntimeController.isPlaying;

  bool get _hasCheckpointUnsafeRuntimeWorkForSave =>
      _hasCheckpointUnsafeRuntimeWork ||
      _pendingWarp != null ||
      _pendingConnection != null ||
      _pendingConnectionEntryAnimation != null ||
      _pendingPlacedElementBehavior != null ||
      _pendingNarrativeTriggerEntries.isNotEmpty ||
      _isNarrativeTriggerQueueDraining;

  void _logCheckpointInterlock(String operation) {
    debugPrint(
      '[$operation] ignored: transient runtime work is not checkpoint-safe '
      'flow=${_flowPhase.name} '
      'loadActivationWork=$_isLoadActivationWorkInFlight '
      'activationDispatches=${_inFlightMapActivationDispatchIds.join(',')} '
      'spatialDispatches=$_inFlightSpatialDispatchCount '
      'rootPublications=$_inFlightRootOutcomePublicationCount '
      'outboxDrain=${_narrativeOutcomeDrainFuture != null} '
      'activity=${_narrativeActivityGate.activity.name} '
      'checkpoint=${_narrativeActivityGate.checkpointInProgress} '
      'cutscene=$isCutsceneRunning '
      'pendingWarp=${_pendingWarp != null} '
      'pendingConnection=${_pendingConnection != null} '
      'pendingConnectionAnimation=${_pendingConnectionEntryAnimation != null} '
      'pendingBattle=${_pendingBattleRequest != null} '
      'pendingPlacedBehavior=${_pendingPlacedElementBehavior != null} '
      'pendingTriggerEntries=${_pendingNarrativeTriggerEntries.length} '
      'triggerQueueDraining=$_isNarrativeTriggerQueueDraining',
    );
  }

  String _nextNarrativeRuntimeId(String prefix) {
    final serial = ++_nextNarrativeRuntimeIdSerial;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final timeHex =
        (timestamp & 0xffffffffffff).toRadixString(16).padLeft(12, '0');
    final version =
        (0x7000 | (serial & 0x0fff)).toRadixString(16).padLeft(4, '0');
    final variant =
        (0x8000 | ((serial >> 12) & 0x3fff)).toRadixString(16).padLeft(4, '0');
    final tail = ((timestamp * 0x9e3779b1 + serial) & 0xffffffffffff)
        .toRadixString(16)
        .padLeft(12, '0');
    return '${prefix}_${timeHex.substring(0, 8)}-'
        '${timeHex.substring(8)}-$version-$variant-$tail';
  }

  Future<NarrativeEventDispatchAuthorityPreparation>
      _prepareNarrativeDispatchAuthority(
    NarrativeEventOccurrence occurrence,
  ) async {
    await beforeNarrativeAuthorityPreparation?.call(occurrence);
    final project = _bundle.manifest;
    final registry = project.eventRegistry;
    late final NarrativeEventDispatchAuthorityPreparation preparation;
    if (registry == null || registry.mode == EventSystemMode.legacyOnly) {
      preparation = NarrativeEventDispatchAuthority.prepare(
        registryResult: registry == null
            ? EventRegistryDecodeResult.absent()
            : EventRegistryDecodeResult.decoded(registry),
        occurrence: occurrence,
        factResolver: NarrativeFactRuntimeResolver.fromFacts(project.facts),
      );
    } else {
      final snapshot = await _narrativeRuntimeSnapshotFor(project);
      preparation = NarrativeEventDispatchAuthority.prepare(
        registryResult: snapshot.registryResult,
        occurrence: occurrence,
        factResolver: snapshot.factResolver,
        legacyClaimIndex: snapshot.legacyClaimIndex,
        projectCatalog: snapshot.projectCatalog,
        project: snapshot.project,
        maps: snapshot.mapsById.values.toList(growable: false),
      );
    }
    await afterNarrativeAuthorityPreparation?.call(occurrence, preparation);
    return preparation;
  }

  void _runDetachedNarrativeTask({
    required String operation,
    required Future<void> Function() task,
  }) {
    unawaited(() async {
      try {
        await task();
      } on _NarrativeOutcomeRetryPendingException catch (error, stackTrace) {
        // ADR-EV2-014 keeps this delivery durable for an explicit later drain
        // (notably save/reload). Do not hot-loop the same infrastructure
        // failure from a detached producer.
        debugPrint(
          '[event_v2] detached $operation left retry pending '
          'delivery=${error.deliveryId} failure=${error.failure}\n$stackTrace',
        );
        _showNotification('Résultat narratif en attente.');
      } catch (error, stackTrace) {
        debugPrint(
          '[event_v2] detached $operation failed: $error\n$stackTrace',
        );
        _showNotification('Évènement impossible.');
      }
    }());
  }

  bool _isCurrentSpatialOccurrence(String occurrenceId) {
    return _currentSpatialOccurrenceIds.contains(occurrenceId) &&
        _spatialOccurrenceActivationIds[occurrenceId] ==
            _currentMapActivationId;
  }

  Future<void> _dispatchLegacySpatialFallback(
    String occurrenceId,
    NarrativeEventOccurrence _,
    GameState gameState,
  ) async {
    final fallback = _legacySpatialFallbacks[occurrenceId];
    if (fallback == null) {
      throw StateError(
        'Spatial occurrence "$occurrenceId" has no legacy fallback.',
      );
    }
    _applyNarrativeGameState(gameState);
    final outcomes = <NarrativeOutcomeRef>[];
    final barrierCountBeforeFallback = _narrativeContinuationBarriers.length;
    if (_activeLegacyScenarioOutcomeCollector != null) {
      throw StateError(
          'A legacy Scenario outcome collector is already active.');
    }
    _activeLegacyScenarioOutcomeCollector = outcomes;
    try {
      await fallback(gameState);
      await _narrativeStateTransactions.transact<void>((_) {
        return NarrativeEventStateTransaction.commit(_gameState, null);
      });
    } finally {
      _activeLegacyScenarioOutcomeCollector = null;
    }
    final continuation =
        _narrativeContinuationBarriers.length > barrierCountBeforeFallback
            ? _narrativeContinuationBarriers.last.continuation
            : null;
    await _publishRootNarrativeOutcomes(
      outcomes,
      continuation: continuation,
    );
  }

  Future<NarrativeSpatialProductionDispatchResult> _dispatchSpatialOccurrence({
    required NarrativeEventOccurrence occurrence,
    required Future<void> Function(GameState gameState) legacyFallback,
  }) async {
    final occurrenceId = _nextNarrativeRuntimeId('spocc');
    _currentSpatialOccurrenceIds.add(occurrenceId);
    _spatialOccurrenceActivationIds[occurrenceId] = _currentMapActivationId;
    _legacySpatialFallbacks[occurrenceId] = legacyFallback;
    _inFlightSpatialDispatchCount++;
    _clearPressedMovementControls();
    NarrativeRuntimeActivityLease? dispatchLease;
    try {
      try {
        dispatchLease = _narrativeActivityGate.enter(
          NarrativeRuntimeActivity.dispatching,
        );
      } on NarrativeRuntimeActivityBlockedException catch (error, stackTrace) {
        return NarrativeSpatialProductionDispatchFailed(
          occurrenceId,
          occurrence,
          error,
          stackTrace,
        );
      }
      final result = await _spatialDispatchBridge.dispatch(
        occurrenceId: occurrenceId,
        occurrence: occurrence,
      );
      final transientCheckpointBlock =
          result is NarrativeSpatialProductionDispatchFailed &&
              result.failure is NarrativeRuntimeActivityBlockedException;
      if ((result is NarrativeSpatialProductionDispatchFailed &&
              !transientCheckpointBlock) ||
          result is NarrativeSpatialProductionDispatchAuthorityBlocked) {
        _showNotification('Évènement impossible.');
      }
      if (result is NarrativeSpatialProductionDispatchV2Handled) {
        await _drainLiveNarrativeOutcomeOutbox();
      }
      return result;
    } finally {
      dispatchLease?.close();
      _legacySpatialFallbacks.remove(occurrenceId);
      _spatialOccurrenceActivationIds.remove(occurrenceId);
      _currentSpatialOccurrenceIds.remove(occurrenceId);
      _inFlightSpatialDispatchCount--;
    }
  }

  Future<NarrativeEventRuntimeSnapshot> _narrativeRuntimeSnapshotFor(
    ProjectManifest project,
  ) async {
    final cached = _cachedNarrativeRuntimeSnapshot;
    if (cached != null && _cachedNarrativeRuntimeSnapshotProject == project) {
      return cached;
    }
    final snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: project,
      loadMap: (mapId) async {
        final bundle = await _loadRuntimeMapBundleCached(mapId);
        return (project: bundle.manifest, map: bundle.map);
      },
    );
    _cachedNarrativeRuntimeSnapshotProject = project;
    _cachedNarrativeRuntimeSnapshot = snapshot;
    return snapshot;
  }

  Future<GameState> _hydrateOwnedPlayerPokemonProgression(
    GameState gameState, {
    RuntimeMapBundle? bundle,
  }) async {
    final catalogueBundle = bundle ?? _bundle;
    final catalogs = await _runtimePlayerPokemonProgressionCatalogLoader(
      gameState: gameState,
      projectRootDirectory: catalogueBundle.projectRootDirectory,
      pokemonConfig: catalogueBundle.manifest.pokemon,
    );
    return hydrateRuntimePlayerPokemonProgression(
      gameState: gameState,
      catalogs: catalogs,
    );
  }

  Future<NarrativeSceneExecutionResult> _executeNarrativeScene(
    NarrativeSceneExecutionRequest request,
  ) async {
    if (_activeNarrativeSceneWorkingSession != null) {
      return NarrativeSceneExecutionResult.failed(
        StateError('A narrative Scene working session is already active.'),
      );
    }
    final snapshot = await _narrativeRuntimeSnapshotFor(_bundle.manifest);
    final session = _NarrativeSceneWorkingSession(request.gameState);
    final hostedBattleOutcomes = <NarrativeOutcomeRef>[];
    final consequenceWriter = await _buildSceneConsequenceRuntimeWriter(
      project: snapshot.project,
      mapsById: snapshot.mapsById,
      sceneId: request.sceneId,
      gameState: request.gameState,
    );
    _activeNarrativeSceneWorkingSession = session;
    try {
      final result = await executeNarrativeEventScene(
        request: request,
        project: snapshot.project,
        mapsById: snapshot.mapsById,
        currentGameState: () => session.gameState,
        hostedBattleOutcomes: hostedBattleOutcomes,
        consequenceWriter: consequenceWriter,
        callbacks: _buildSceneRuntimeHostCallbacks(
          runtimeSourceId: 'event-v2:${request.eventId}:${request.executionId}',
          defaultNpcEntityId: _narrativeSceneBattleAnchor(
            snapshot,
            request.eventId,
          ),
          currentGameState: () => session.gameState,
          onQualifiedBattleOutcome: hostedBattleOutcomes.add,
        ),
      );
      if (result is NarrativeSceneExecutionCompleted) {
        try {
          final hydratedGameState = await _hydrateOwnedPlayerPokemonProgression(
            result.updatedGameState,
          );
          final gameCompletion = result.gameCompletion;
          if (gameCompletion != null) {
            final coordinator = _gameCompletionCoordinator;
            if (coordinator == null) {
              return NarrativeSceneExecutionResult.failed(
                StateError(
                  'Finish Game requires an active session completion port.',
                ),
              );
            }
            coordinator.queue(gameCompletion);
          }
          session.gameState = hydratedGameState;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: hydratedGameState,
            qualifiedOutcomes: result.qualifiedOutcomes,
            gameCompletion: gameCompletion,
          );
        } catch (error) {
          return NarrativeSceneExecutionResult.failed(error);
        }
      }
      return result;
    } finally {
      _activeNarrativeSceneWorkingSession = null;
    }
  }

  String _narrativeSceneBattleAnchor(
    NarrativeEventRuntimeSnapshot snapshot,
    String eventId,
  ) {
    final registry = snapshot.project.eventRegistry;
    if (registry != null) {
      for (final record in registry.records) {
        if (record.id != eventId) continue;
        final source = record.definitionOrNull?.source;
        if (source == null) break;
        return source.when(
          entityInteract: (_, entityId) => entityId,
          triggerEnter: (_, triggerId) => triggerId,
          mapEnter: (mapId) => mapId,
          outcomeReceived: (_) => eventId,
        );
      }
    }
    return eventId;
  }

  void _applyNarrativeGameState(GameState gameState) {
    _gameState = gameState;
    if (isLoaded) {
      _refreshWorldNpcPresence();
    }
    final completionCoordinator = _gameCompletionCoordinator;
    if (completionCoordinator != null) {
      unawaited(
        completionCoordinator.onGameStateCommitted(gameState).catchError(
          (Object error, StackTrace stackTrace) {
            debugPrint(
              '[game_completion] emission failed: $error\n$stackTrace',
            );
            _showNotification('Fin de partie impossible.');
          },
        ),
      );
    }
  }

  Future<void> _dispatchLegacyMapEnterFallback(
    MapActivation activation,
    NarrativeEventOccurrence _,
    GameState gameState,
  ) async {
    // The restore outbox may have committed a newer snapshot than the Flame
    // facade currently holds. Legacy Scenario must see that exact state.
    _applyNarrativeGameState(gameState);
    final outcomes = <NarrativeOutcomeRef>[];
    final result = _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.mapEnter(mapId: activation.mapId),
      deferredOutcomes: outcomes,
    );
    final continuation = _narrativeContinuationBarrierFor(
      _scenarioContinuationRuntimeSourceId(result) ?? '',
    )?.continuation;
    await _narrativeStateTransactions.transact<void>((_) {
      return NarrativeEventStateTransaction.commit(_gameState, null);
    });
    await _publishRootNarrativeOutcomes(
      outcomes,
      continuation: continuation,
    );
  }

  Future<MapEnterProductionDispatchResult> _dispatchCompletedMapActivation(
    MapActivation activation,
  ) async {
    if (!_inFlightMapActivationDispatchIds.add(activation.activationId)) {
      return MapEnterProductionDispatchDuplicate(activation);
    }
    if (_flowPhase == _RuntimeFlowPhase.overworld) {
      _clearPressedMovementControls();
    }
    NarrativeRuntimeActivityLease? dispatchLease;
    try {
      try {
        dispatchLease = _narrativeActivityGate.enter(
          NarrativeRuntimeActivity.dispatching,
        );
      } on NarrativeRuntimeActivityBlockedException catch (error, stackTrace) {
        return MapEnterProductionDispatchFailed(
          activation,
          error,
          stackTrace,
        );
      }
      final result =
          await _mapEnterDispatchBridge.dispatchCompletedActivation(activation);
      final activationCompleted =
          result is MapEnterProductionDispatchLegacyFallback ||
              result is MapEnterProductionDispatchV2Handled ||
              result is MapEnterProductionDispatchClaimedIneligible ||
              result is MapEnterProductionDispatchNoFallback;
      if (activationCompleted) {
        _completedMapActivationDispatchCount++;
        _lastCompletedMapActivation = activation;
        // Every terminal activation, including a legacy/no-match one, must
        // hand the active activation ID back to an owning outcome drain. An
        // outcome adapter may emit a child and then transition maps; limiting
        // this handoff to V2Handled would leave that child pending as soon as
        // the outer drain notices that its previous activation became stale.
        await _drainLiveNarrativeOutcomeOutbox(
          expectedActivationId: activation.activationId,
        );
      } else if ((result is MapEnterProductionDispatchAuthorityBlocked ||
              result is MapEnterProductionDispatchFailed) &&
          _narrativeOutcomeDrainFuture != null &&
          _narrativeOutcomeDispatchDepth > 0) {
        // The physical transition already installed this activation even
        // though its mapEnter source failed closed. Resume the owning drain
        // on the current activation so child outcomes emitted before that
        // transition can retry or terminalize instead of being orphaned.
        _rememberDeferredNarrativeOutcomeDrainActivation(
          activation.activationId,
        );
      }
      debugPrint(
        '[event_v2] mapEnter activation=${activation.activationId} '
        'map=${activation.mapId} reason=${activation.reason.name} '
        'result=${result.runtimeType}',
      );
      if (result is MapEnterProductionDispatchFailed) {
        debugPrint(
          '[event_v2] mapEnter failure=${result.failure}'
          '${result.stackTrace == null ? '' : '\n${result.stackTrace}'}',
        );
      }
      return result;
    } finally {
      dispatchLease?.close();
      _inFlightMapActivationDispatchIds.remove(activation.activationId);
    }
  }

  Future<void> _drainRestoredNarrativeOutcomeOutbox(
    MapActivation activation,
  ) async {
    while (_currentMapActivationId == activation.activationId) {
      await _drainLiveNarrativeOutcomeOutbox(
        expectedActivationId: activation.activationId,
      );
      if (_currentMapActivationId != activation.activationId) {
        return;
      }
      final barrier = _narrativeContinuationBarriers.isEmpty
          ? null
          : _narrativeContinuationBarriers.last;
      if (barrier == null) {
        return;
      }
      _restoredOutcomeContinuationActivationId = activation.activationId;
      try {
        await barrier.closedFuture;
      } finally {
        if (_restoredOutcomeContinuationActivationId ==
            activation.activationId) {
          _restoredOutcomeContinuationActivationId = null;
        }
      }
    }
  }

  bool _restoreFenceOwnsSource(String? runtimeSourceId) {
    if (runtimeSourceId == null ||
        _restoredOutcomeContinuationActivationId == null ||
        _narrativeContinuationBarriers.isEmpty) {
      return false;
    }
    return _narrativeContinuationBarriers.last.runtimeSourceId ==
        runtimeSourceId;
  }

  void _rememberDeferredNarrativeOutcomeDrainActivation(
    String? expectedActivationId,
  ) {
    final requests = _deferredNarrativeOutcomeDrainActivationIds;
    if (requests.isEmpty || requests.last != expectedActivationId) {
      requests.add(expectedActivationId);
    }
  }

  Future<void> _drainLiveNarrativeOutcomeOutbox({
    String? expectedActivationId,
  }) {
    final existing = _narrativeOutcomeDrainFuture;
    if (existing != null) {
      if (_narrativeOutcomeDispatchDepth > 0) {
        // An outcome may transition to a map whose mapEnter Scene publishes
        // another outcome. Awaiting the owning drain here would make the
        // dispatcher wait on itself, so record the new activation and let the
        // outer loop resume it after the current delivery is committed.
        _rememberDeferredNarrativeOutcomeDrainActivation(
          expectedActivationId,
        );
        return Future<void>.value();
      }
      return existing;
    }
    final completer = Completer<void>();
    _narrativeOutcomeDrainFuture = completer.future;
    unawaited(() async {
      var activeExpectedActivationId = expectedActivationId;
      try {
        while (true) {
          final continuationBarrier = _narrativeContinuationBarriers.isEmpty
              ? null
              : _narrativeContinuationBarriers.last;
          if (continuationBarrier != null && !continuationBarrier.advancing) {
            // processNext commits the current raw delivery before control
            // returns here. Stop before the next FIFO head and release the
            // drain so dialogue/script/move/battle/warp can progress.
            break;
          }
          if (activeExpectedActivationId != null &&
              _currentMapActivationId != activeExpectedActivationId) {
            if (_deferredNarrativeOutcomeDrainActivationIds.isEmpty) {
              break;
            }
            activeExpectedActivationId =
                _deferredNarrativeOutcomeDrainActivationIds.removeAt(0);
            continue;
          }
          final result = await _narrativeOutcomeOutboxProcessor.processNext();
          if (result is NarrativeOutcomeOutboxEmpty) {
            _applyNarrativeGameState(await _narrativeStateTransactions.read());
            if (_deferredNarrativeOutcomeDrainActivationIds.isEmpty) {
              break;
            }
            activeExpectedActivationId =
                _deferredNarrativeOutcomeDrainActivationIds.removeAt(0);
            continue;
          }
          if (result is NarrativeOutcomeOutboxBusy) {
            throw StateError('Narrative outcome outbox is already busy.');
          }
          if (result is NarrativeOutcomeOutboxRetryScheduled) {
            _applyNarrativeGameState(result.updatedGameState);
            throw _NarrativeOutcomeRetryPendingException(
              deliveryId: result.delivery.deliveryId,
              failure: result.failure,
            );
          }
          if (result is NarrativeOutcomeOutboxDelivered) {
            _applyNarrativeGameState(result.updatedGameState);
            _startNarrativePostCommitEffectIfReady();
            continue;
          }
          if (result is NarrativeOutcomeOutboxTerminalized) {
            _applyNarrativeGameState(result.updatedGameState);
            continue;
          }
          final inconsistency =
              result as NarrativeOutcomeOutboxDataInconsistency;
          _applyNarrativeGameState(inconsistency.updatedGameState);
        }
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _deferredNarrativeOutcomeDrainActivationIds.clear();
        _narrativeOutcomeDrainFuture = null;
      }
    }());
    return completer.future;
  }

  Future<void> _publishRootNarrativeOutcomes(
    List<NarrativeOutcomeRef> outcomes, {
    _NarrativeOutcomeContinuationContext? continuation,
  }) {
    final metadata = continuation ??
        _NarrativeOutcomeContinuationContext(
          causationId: _nextNarrativeRuntimeId('evx'),
          correlationId: _nextNarrativeRuntimeId('corr'),
          depth: 0,
        );
    return _publishNarrativeOutcomes(
      outcomes,
      causationId: metadata.causationId,
      correlationId: metadata.correlationId,
      depth: metadata.depth,
    );
  }

  Future<void> _publishNarrativeOutcomes(
    List<NarrativeOutcomeRef> outcomes, {
    required String causationId,
    required String correlationId,
    required int depth,
  }) async {
    if (outcomes.isEmpty) {
      return;
    }
    _inFlightRootOutcomePublicationCount++;
    _clearPressedMovementControls();
    NarrativeRuntimeActivityLease? publicationLease;
    try {
      publicationLease = _narrativeActivityGate.enter(
        NarrativeRuntimeActivity.outboxProcessing,
      );
      await _enqueueNarrativeOutcomes(
        outcomes,
        causationId: causationId,
        correlationId: correlationId,
        depth: depth,
      );
      await _drainLiveNarrativeOutcomeOutbox();
    } finally {
      publicationLease?.close();
      _inFlightRootOutcomePublicationCount--;
    }
  }

  Future<void> _enqueueNarrativeOutcomes(
    List<NarrativeOutcomeRef> outcomes, {
    required String causationId,
    required String correlationId,
    required int depth,
  }) async {
    if (outcomes.isEmpty) {
      return;
    }
    final updated = await _narrativeStateTransactions
        .transact<GameState>((transactionState) {
      // Scenario callbacks update the live facade before they publish. Keep
      // those gameplay mutations, but always append to the transaction's
      // canonical outbox snapshot so two fire-and-forget producers cannot
      // overwrite each other's pending or delivered entries.
      final state = _gameState;
      final progress = transactionState.narrativeEventProgress;
      final nextState = state.copyWith(
        narrativeEventProgress: progress.copyWith(
          pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
            ...progress.pendingNarrativeOutcomeDeliveries,
            for (final outcome in outcomes)
              NarrativeOutcomeDelivery(
                deliveryId: _nextNarrativeRuntimeId('outd'),
                outcome: outcome,
                causationExecutionId: causationId,
                rootCorrelationId: correlationId,
                depth: depth,
                attemptCount: 0,
              ),
          ],
        ),
      );
      return NarrativeEventStateTransaction.commit(nextState, nextState);
    });
    _applyNarrativeGameState(updated);
  }

  Future<NarrativeOutcomeDispatchResult> _dispatchNarrativeOutcome(
    NarrativeOutcomeDispatchRequest request,
  ) async {
    _narrativeOutcomeDispatchDepth++;
    try {
      return await _dispatchNarrativeOutcomeGuarded(request);
    } finally {
      _narrativeOutcomeDispatchDepth--;
    }
  }

  Future<NarrativeOutcomeDispatchResult> _dispatchNarrativeOutcomeGuarded(
    NarrativeOutcomeDispatchRequest request,
  ) async {
    NarrativeEventDispatchAuthorityPreparation preparation;
    try {
      preparation =
          await _prepareNarrativeDispatchAuthority(request.occurrence);
    } catch (error) {
      return NarrativeOutcomeDispatchResult.infrastructureFailureBeforePlanning(
          error);
    }
    if (preparation is NarrativeEventDispatchAuthorityBlocked) {
      return NarrativeOutcomeDispatchResult.infrastructureFailureBeforePlanning(
        StateError(
          'Outcome authority blocked: ${preparation.reason.name}.',
        ),
      );
    }

    final authority = preparation as NarrativeEventDispatchAuthorityReady;

    final coordinator = NarrativeEventExecutionCoordinator(
      stateTransactions: _narrativeStateTransactions,
      planner: NarrativeEventDispatchPlanner(),
      executeScene: _executeNarrativeScene,
      activityPort: NarrativeRuntimeActivityPort(_narrativeActivityGate),
      executionIdFactory: () => _nextNarrativeRuntimeId('evx'),
      correlationIdFactory: () => _nextNarrativeRuntimeId('corr'),
      deliveryIdFactory: () => _nextNarrativeRuntimeId('outd'),
      beforePlan: (gameState) => authority.applyOutcomeReset(
        gameState: gameState,
        deliveryId: request.delivery.deliveryId,
        outcome: request.delivery.outcome,
      ),
    );
    final execution = await coordinator.execute(authority: authority);
    if (execution is NarrativeEventExecutionSucceeded) {
      return NarrativeOutcomeDispatchResult.delivered(
        updatedGameState: execution.updatedGameState,
        causationExecutionId: execution.executionId,
      );
    }
    if (execution is NarrativeEventExecutionClaimedButIneligible) {
      final resetGameState = await _narrativeStateTransactions.read();
      return NarrativeOutcomeDispatchResult.delivered(
        updatedGameState: resetGameState,
      );
    }
    if (execution is NarrativeEventExecutionNoMatch) {
      final resetGameState = await _narrativeStateTransactions.read();
      final legacyFallbackAllowed = execution.legacyFallbackAllowed &&
          request.delivery.outcome.producerKind ==
              NarrativeOutcomeProducerKind.legacyScenario;
      debugPrint(
        '[event_v2] outcome noMatch producer='
        '${request.delivery.outcome.producerKind.name}:'
        '${request.delivery.outcome.producerId} '
        'outcome=${request.delivery.outcome.outcomeId} '
        'legacyFallbackAllowed=$legacyFallbackAllowed',
      );
      if (!legacyFallbackAllowed) {
        return NarrativeOutcomeDispatchResult.delivered(
          updatedGameState: resetGameState,
        );
      }
      _applyNarrativeGameState(resetGameState);
      final legacyChildOutcomes = <NarrativeOutcomeRef>[];
      final pendingTransitionBeforeDispatch =
          _pendingScenarioTransitionMapRequest;
      final legacyResult = _dispatchScenarioRuntimeSource(
        ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: request.delivery.outcome.outcomeId,
        ),
        deferredOutcomes: legacyChildOutcomes,
      );
      debugPrint(
        '[event_v2] legacy outcome adapter status=${legacyResult.status.name} '
        'scenario=${legacyResult.scenarioId ?? '-'} '
        'outcome=${request.delivery.outcome.outcomeId}',
      );
      final continuation = _NarrativeOutcomeContinuationContext(
        causationId: request.delivery.causationExecutionId ??
            _nextNarrativeRuntimeId('evx'),
        correlationId: request.delivery.rootCorrelationId,
        depth: request.delivery.depth + 1,
      );
      _attachNarrativeOutcomeContinuationToBarrier(
        legacyResult,
        continuation,
      );
      final pendingLegacyOutcomeTransition =
          _pendingScenarioTransitionMapRequest;
      if (pendingLegacyOutcomeTransition != null &&
          !identical(
            pendingLegacyOutcomeTransition,
            pendingTransitionBeforeDispatch,
          ) &&
          _scenarioContinuationRuntimeSourceId(legacyResult) == null &&
          identical(
            _pendingScenarioTransitionMapRequest,
            pendingLegacyOutcomeTransition,
          )) {
        _pendingScenarioTransitionMapRequest = null;
        _openNarrativeContinuationBarrier(
          runtimeSourceId: 'scenario-transition:${request.delivery.deliveryId}',
          continuation: continuation,
          resumesScenario: false,
          postCommitEffect: () => _executeScenarioTransitionMapRequest(
            pendingLegacyOutcomeTransition,
            allowMapActivationWork: true,
            skipVisualTransition: !isLoaded,
          ),
        );
      }
      await _narrativeStateTransactions.transact<void>((_) {
        return NarrativeEventStateTransaction.commit(_gameState, null);
      });
      return NarrativeOutcomeDispatchResult.delivered(
        updatedGameState: _gameState,
        qualifiedChildOutcomes: legacyChildOutcomes,
        causationExecutionId: continuation.causationId,
      );
    }
    if (execution is NarrativeEventExecutionFailed) {
      return NarrativeOutcomeDispatchResult.terminalFailure(
        execution.failure,
      );
    }
    return NarrativeOutcomeDispatchResult.terminalFailure(
      (execution as NarrativeEventExecutionCancelled).reason ??
          StateError('Restore outcome Scene was cancelled.'),
    );
  }

  /// Cache de l’index Step Studio ↔ cutscenes locales (invalidé quand [_bundle] change).
  StepCompletionCutsceneIndex? _cachedStepCompletionIndex;
  RuntimeMapBundle? _cachedStepCompletionBundleForIndex;

  /// Cache des `worldChanges` parsés (une entrée par ligne JSON) pour le manifeste courant.
  List<StepStudioWorldPresenceRule> _cachedStepStudioWorldRules =
      const <StepStudioWorldPresenceRule>[];
  ProjectManifest? _cachedStepStudioWorldRulesManifest;

  void _ensureStepStudioWorldRulesForManifest(ProjectManifest manifest) {
    if (identical(_cachedStepStudioWorldRulesManifest, manifest)) {
      return;
    }
    _cachedStepStudioWorldRulesManifest = manifest;
    _cachedStepStudioWorldRules =
        buildStepStudioWorldPresenceRuleList(manifest.scenarios);
  }

  /// Cache de l'index chapitres globalStory (même politique que les règles
  /// Step Studio) : le construire re-parse le JSON authoring de chaque
  /// scénario, et il était reconstruit pour chaque PNJ à chaque refresh de
  /// présence ainsi qu'à chaque résolution de dialogue.
  GlobalStoryChapterStepIndex? _cachedGlobalStoryChapterIndex;
  ProjectManifest? _cachedGlobalStoryChapterIndexManifest;

  GlobalStoryChapterStepIndex _globalStoryChapterIndexFor(
    ProjectManifest manifest,
  ) {
    if (!identical(_cachedGlobalStoryChapterIndexManifest, manifest) ||
        _cachedGlobalStoryChapterIndex == null) {
      _cachedGlobalStoryChapterIndexManifest = manifest;
      _cachedGlobalStoryChapterIndex =
          buildGlobalStoryChapterStepIndex(manifest.scenarios);
    }
    return _cachedGlobalStoryChapterIndex!;
  }

  late final CutsceneRuntimeRunner _cutsceneRunner =
      _buildCutsceneRuntimeRunner();
  CutsceneChoiceRequest? _pendingCutsceneChoiceRequest;
  NarrativeRuntimeActivityLease? _cutsceneActivityLease;
  ScriptedEntityMovementController? _scriptedEntityMovementController;
  final Map<String, GridPos> _runtimeNpcPositions = <String, GridPos>{};
  final Map<String, Completer<String>> _pendingSceneNpcMovesByEntity =
      <String, Completer<String>>{};
  // Réservations temporaires d'occupation pour PNJ scriptés en cours de pas.
  //
  // Frontière intentionnelle:
  // - `GameplayWorldState` reste la source canonique des positions *commitées*.
  // - pendant une interpolation visuelle d'un pas PNJ, on réserve aussi les
  //   cellules de destination pour éviter les traversées joueur<->PNJ / PNJ<->PNJ.
  final Map<String, Set<GridPos>> _scriptedNpcReservedOccupiedCellsByEntity =
      <String, Set<GridPos>>{};
  double _runtimeClockMs = 0;
  int _debugEncounterCheckCount = 0;
  _EncounterCheckMarker? _lastEncounterCheckMarker;
  double _lastWaterRequiresSurfMessageAtMs = -1000000000;
  void Function()? _pendingPostDialogueAction;

  /// Propriétaire atomique du handoff Battle lancé par Scenario.
  ///
  /// Le requestId lie causalement la continuation au combat effectivement
  /// consommé. Ne jamais conserver ou modifier ces trois valeurs séparément.
  _PendingScenarioBattleHandoff? _pendingScenarioBattleHandoff;
  bool _awaitingSurfConfirmation = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showBehaviorDebugOverlay = false;
  bool _showFpsOverlay = false;
  bool _preferBattleFlutterCommandOverlay = false;
  TextComponent? _behaviorDebugOverlay;
  TextComponent? _fpsOverlay;
  double _fpsAccumulatorSeconds = 0.0;
  int _fpsFrameCount = 0;
  double _currentFps = 0.0;
  String _lastBehaviorDebugLine = 'Aucun behavior déclenché';
  int _nextBlockingInteractionSerial = 0;
  int? _activeBlockingInteractionSerial;
  String? _activeBlockingInteractionSourceId;
  bool _hasPendingDialogueLoad = false;
  String? _activeScriptRuntimeSourceId;
  _PendingScenarioWarpHandoff? _pendingScenarioWarpHandoff;
  _PendingScenarioLeaderWarpHandoff? _pendingScenarioLeaderWarpHandoff;
  int _lastFollowPathNodeCount = 0;
  GridPos? _lastFollowPathDestination;
  GridPos? _debugTileMarkerPos;
  String? _debugTileMarkerLabel;
  RectangleComponent? _debugTileMarkerFill;
  RectangleComponent? _debugTileMarkerBorder;
  TextComponent? _debugTileMarkerText;
  final Map<String, _NpcCollisionDebugVisual> _npcCollisionDebugByEntityId =
      <String, _NpcCollisionDebugVisual>{};

  ScriptRuntimeController? _activeScriptController;
  Set<String> _activeScenarioTriggerIds = <String>{};
  _PendingScenarioFollowRequest? _pendingScenarioFollowRequest;
  _PendingScenarioTransitionMapRequest? _pendingScenarioTransitionMapRequest;
  final Map<String, _PendingScenarioNpcWarpEntry>
      _pendingScenarioNpcWarpEntries = <String, _PendingScenarioNpcWarpEntry>{};
  final Map<String, _PendingScenarioMoveContinuation>
      _pendingScenarioMoveContinuationsByEntity =
      <String, _PendingScenarioMoveContinuation>{};
  // File d'attente des scénarios ayant atteint `end` mais dont la complétion
  // doit attendre la fin réelle des effets runtime visibles.
  final List<_PendingScenarioReachedEnd> _pendingScenarioReachedEndQueue =
      <_PendingScenarioReachedEnd>[];
  String? _lastScenarioCompletionBlockReason;

  // Save/Load system
  late final GameSaveRepository _saveRepo;
  late SaveGameUseCase _saveGameUseCase;
  late LoadGameUseCase _loadGameUseCase;

  // Event V2 F1 production composition. The default file repository and the
  // narrative coordinator share this gate so checkpoints cannot overlap a
  // dispatch, Scene execution or restore-outbox drain.
  late final NarrativeRuntimeActivityGate _narrativeActivityGate;
  late final NarrativeGameCompletionRuntimeCoordinator?
      _gameCompletionCoordinator;
  late final NarrativeEventStateTransactions _narrativeStateTransactions;
  late final MapEnterProductionDispatchBridge _mapEnterDispatchBridge;
  late final NarrativeSpatialProductionDispatchBridge _spatialDispatchBridge;
  late final NarrativeOutcomeOutboxProcessor _narrativeOutcomeOutboxProcessor;
  Future<void>? _narrativeOutcomeDrainFuture;
  final List<String?> _deferredNarrativeOutcomeDrainActivationIds = <String?>[];
  int _narrativeOutcomeDispatchDepth = 0;
  int _inFlightRootOutcomePublicationCount = 0;
  final List<_NarrativeContinuationBarrier> _narrativeContinuationBarriers =
      <_NarrativeContinuationBarrier>[];
  final Set<String> _reservedNarrativeContinuationRuntimeSourceIds = <String>{};
  final Set<String> _deferredNarrativeContinuationAdvanceSourceIds = <String>{};
  final Set<String> _deferredNarrativeContinuationCancelSourceIds = <String>{};
  String? _restoredOutcomeContinuationActivationId;
  NarrativeEventRuntimeSnapshot? _cachedNarrativeRuntimeSnapshot;
  ProjectManifest? _cachedNarrativeRuntimeSnapshotProject;
  int _nextMapActivationSerial = 0;
  int _nextNarrativeRuntimeIdSerial = 0;
  String? _currentMapActivationId;
  final Set<String> _inFlightMapActivationDispatchIds = <String>{};
  bool _isLoadActivationWorkInFlight = false;
  int _completedMapActivationDispatchCount = 0;
  MapActivation? _lastCompletedMapActivation;
  final Set<String> _currentSpatialOccurrenceIds = <String>{};
  final Map<String, String?> _spatialOccurrenceActivationIds =
      <String, String?>{};
  final Map<String, Future<void> Function(GameState gameState)>
      _legacySpatialFallbacks =
      <String, Future<void> Function(GameState gameState)>{};
  int _inFlightSpatialDispatchCount = 0;
  List<String> _activeNarrativeTriggerIds = const <String>[];
  final List<_PendingNarrativeTriggerEntry> _pendingNarrativeTriggerEntries =
      <_PendingNarrativeTriggerEntry>[];
  bool _isNarrativeTriggerQueueDraining = false;
  List<NarrativeOutcomeRef>? _activeLegacyScenarioOutcomeCollector;

  // Battle system (map_battle integration)
  BattleSession? _battleSession;
  RuntimePsdkBattleSessionAdapter? _psdkBattleSession;
  RuntimeActiveBattleContext? _activeBattleContext;
  RuntimeBattleCaptureAttemptReceipt? _captureAttemptReceipt;
  final ValueNotifier<BattleCommandOverlaySnapshot?>
      _battleCommandOverlayNotifier =
      ValueNotifier<BattleCommandOverlaySnapshot?>(null);
  BattleCommandOverlaySnapshot? _pendingBattleCommandOverlaySnapshot;
  bool _battleCommandOverlayPostFrameFlushScheduled = false;
  _PendingConnectionEntryAnimation? _pendingConnectionEntryAnimation;

  // Battle flow hardening
  bool _isBattleResolving =
      false; // Lock pour empêcher spam clavier pendant résolution
  bool _isPostBattleFlowRunning = false;
  bool _isPostBattleCommitCompleted = false;
  Future<void> _defeatRecoveryFuture = Future<void>.value();
  int _postBattleFlowGeneration = 0;
  Completer<void>? _postBattleFlowCompleter;
  Future<void> _postBattleCompletionFuture = Future<void>.value();
  RuntimeInputLockToken? _postBattleInputLock;

  // Line of Sight (LoS) trainer detection
  final Set<String> _triggeredTrainerBattles = {}; // Anti-retrigger lock

  bool get showCollisionOverlay => _showCollisionOverlay;

  void setCollisionOverlayVisible(bool visible) {
    _showCollisionOverlay = visible;
    for (final loaded in _loadedMapsById.values) {
      loaded.backgroundLayers.showCollisionOverlay = visible;
    }
  }

  bool get showNpcCollisionDebugOverlay => _showNpcCollisionDebugOverlay;

  void setNpcCollisionDebugOverlayVisible(bool visible) {
    _showNpcCollisionDebugOverlay = visible;
    if (!isLoaded) {
      return;
    }
    _syncNpcCollisionDebugOverlay();
  }

  bool get showBehaviorDebugOverlay => _showBehaviorDebugOverlay;
  bool get showFpsOverlay => _showFpsOverlay;
  double get currentFps => _currentFps;

  /// Active/désactive l'affichage du compteur FPS dans le viewport runtime.
  ///
  /// Ce toggle est utilisé par l'example host pour un contrôle manuel.
  /// Le compteur est volontairement optionnel pour éviter toute pollution
  /// visuelle par défaut.
  void setFpsOverlayVisible(bool visible) {
    _showFpsOverlay = visible;
    if (!_showFpsOverlay) {
      _fpsOverlay?.removeFromParent();
      _fpsOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureFpsOverlay();
  }

  /// Le host mobile peut préférer sortir le panneau de commandes battle en
  /// vrai widget Flutter quand aucune manette n'est active.
  ///
  /// Frontière volontaire :
  /// - le runtime ne détecte pas le hardware tout seul ;
  /// - le host pousse seulement une préférence d'interaction ;
  /// - l'overlay battle reste la seule surface concernée.
  void setBattleFlutterCommandOverlayPreferred(bool preferred) {
    _preferBattleFlutterCommandOverlay = preferred;
    _battleOverlay?.setUseFlutterCommandOverlay(preferred);
  }

  /// Applies a real reveal cadence to current and future dialogue overlays.
  ///
  /// The runtime default remains instant for backwards compatibility; the
  /// player host opts into its persisted preference when creating the game.
  void setDialogueTextSpeed(RuntimeDialogueTextSpeed speed) {
    _dialogueTextSpeed = speed;
    _dialogueOverlay?.setTextSpeed(speed);
  }

  RuntimeDialogueTextSpeed get dialogueTextSpeed => _dialogueTextSpeed;

  /// Confie la boîte de dialogue au shell Flutter sans déplacer la machine
  /// d'état Yarn hors du runtime.
  void setDialogueFlutterOverlayPreferred(bool preferred) {
    _preferDialogueFlutterOverlay = preferred;
    _dialogueOverlay?.setRenderInFlame(!preferred);
  }

  ValueListenable<DialoguePresentationSnapshot?>
      get dialoguePresentationListenable => _dialoguePresentationNotifier;

  ValueListenable<RuntimeInputAuthoritySnapshot> get inputAuthorityListenable =>
      _inputAuthorityNotifier;

  void setFlutterNotificationsPreferred(bool preferred) {
    _preferFlutterNotifications = preferred;
    final component = _notification;
    if (preferred && component != null) {
      component.removeFromParent();
      _notification = null;
    }
  }

  ValueListenable<RuntimeNotificationSnapshot?>
      get runtimeNotificationListenable => _runtimeNotificationNotifier;

  void setPostBattleFlutterOverlayPreferred(bool preferred) {
    _preferPostBattleFlutterOverlay = preferred;
    _postBattleProgressionOverlay?.setRenderInFlame(!preferred);
  }

  ValueListenable<PostBattlePresentationSnapshot?>
      get postBattlePresentationListenable => _postBattlePresentationNotifier;

  bool dispatchPostBattlePresentationCommand(
    PostBattlePresentationCommand command,
  ) {
    final snapshot = _postBattlePresentationNotifier.value;
    final overlay = _postBattleProgressionOverlay;
    if (snapshot == null ||
        overlay == null ||
        !validatePostBattlePresentationCommand(snapshot, command).accepted) {
      return false;
    }
    switch (command) {
      case PostBattleAdvanceCommand():
        return overlay.validateSelectedChoice();
      case PostBattleSelectDecisionCommand(:final decisionIndex):
        return overlay.selectDecision(decisionIndex) &&
            overlay.validateSelectedChoice();
    }
  }

  bool dispatchDialoguePresentationCommand(
    DialoguePresentationCommand command,
  ) {
    final snapshot = _dialoguePresentationNotifier.value;
    final overlay = _dialogueOverlay;
    if (snapshot == null ||
        overlay == null ||
        !validateDialoguePresentationCommand(snapshot, command).accepted) {
      return false;
    }
    switch (command) {
      case DialogueAdvanceCommand():
        _advanceDialogue();
      case DialogueSelectChoiceCommand(:final choiceIndex):
        final state = overlay.currentSession.state;
        if (state is! DialogueWaitingForChoice) {
          return false;
        }
        overlay.moveCursor(choiceIndex - state.selectedIndex);
        _confirmDialogueChoice();
    }
    return true;
  }

  void _setDialoguePresentationSnapshot(
    DialoguePresentationSnapshot? snapshot,
  ) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (!shouldDefer) {
      _pendingDialoguePresentationSnapshot = null;
      _dialoguePresentationNotifier.value = snapshot;
      return;
    }
    _pendingDialoguePresentationSnapshot = snapshot;
    if (_dialoguePresentationPostFrameFlushScheduled) {
      return;
    }
    _dialoguePresentationPostFrameFlushScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _dialoguePresentationPostFrameFlushScheduled = false;
      final pending = _pendingDialoguePresentationSnapshot;
      _pendingDialoguePresentationSnapshot = null;
      _dialoguePresentationNotifier.value = pending;
    });
  }

  void _publishRuntimeNotification(
    String text, {
    RuntimeNotificationTone tone = RuntimeNotificationTone.info,
  }) {
    _setRuntimeNotificationSnapshot(
      RuntimeNotificationSnapshot(
        revision: ++_runtimeNotificationRevision,
        text: text,
        tone: tone,
      ),
    );
  }

  void _setRuntimeNotificationSnapshot(
    RuntimeNotificationSnapshot? snapshot,
  ) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (!shouldDefer) {
      _pendingRuntimeNotificationSnapshot = null;
      _runtimeNotificationNotifier.value = snapshot;
      return;
    }
    _pendingRuntimeNotificationSnapshot = snapshot;
    if (_runtimeNotificationPostFrameFlushScheduled) {
      return;
    }
    _runtimeNotificationPostFrameFlushScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _runtimeNotificationPostFrameFlushScheduled = false;
      final pending = _pendingRuntimeNotificationSnapshot;
      _pendingRuntimeNotificationSnapshot = null;
      _runtimeNotificationNotifier.value = pending;
    });
  }

  void _setPostBattlePresentationSnapshot(
    PostBattlePresentationSnapshot? snapshot,
  ) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (!shouldDefer) {
      _pendingPostBattlePresentationSnapshot = null;
      _postBattlePresentationNotifier.value = snapshot;
      return;
    }
    _pendingPostBattlePresentationSnapshot = snapshot;
    if (_postBattlePresentationPostFrameFlushScheduled) {
      return;
    }
    _postBattlePresentationPostFrameFlushScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _postBattlePresentationPostFrameFlushScheduled = false;
      final pending = _pendingPostBattlePresentationSnapshot;
      _pendingPostBattlePresentationSnapshot = null;
      _postBattlePresentationNotifier.value = pending;
    });
  }

  /// Compat historique : l'ancien seam mobile pilotait un faux scroll tactile
  /// directement dans le panneau Flame. Le lot mobile Flutter redirige ce
  /// toggle vers la nouvelle surcouche widget sans casser les appels existants.
  void setBattleTouchListDragScrollPreferred(bool preferred) {
    setBattleFlutterCommandOverlayPreferred(preferred);
  }

  ValueListenable<BattleCommandOverlaySnapshot?>
      get battleCommandOverlayListenable => _battleCommandOverlayNotifier;

  void _setBattleCommandOverlaySnapshot(
    BattleCommandOverlaySnapshot? snapshot,
  ) {
    final binding = SchedulerBinding.instance;
    final phase = binding.schedulerPhase;
    final shouldDeferUntilPostFrame =
        phase == SchedulerPhase.persistentCallbacks ||
            phase == SchedulerPhase.midFrameMicrotasks;
    if (!shouldDeferUntilPostFrame) {
      _pendingBattleCommandOverlaySnapshot = null;
      _flushBattleCommandOverlaySnapshot(snapshot);
      return;
    }
    _pendingBattleCommandOverlaySnapshot = snapshot;
    if (_battleCommandOverlayPostFrameFlushScheduled) {
      return;
    }
    _battleCommandOverlayPostFrameFlushScheduled = true;
    binding.addPostFrameCallback((_) {
      _battleCommandOverlayPostFrameFlushScheduled = false;
      final pendingSnapshot = _pendingBattleCommandOverlaySnapshot;
      _pendingBattleCommandOverlaySnapshot = null;
      _flushBattleCommandOverlaySnapshot(pendingSnapshot);
    });
  }

  void _flushBattleCommandOverlaySnapshot(
    BattleCommandOverlaySnapshot? snapshot,
  ) {
    if (_battleCommandOverlayNotifier.value == snapshot) {
      return;
    }
    _battleCommandOverlayNotifier.value = snapshot;
  }

  /// Point d'entrée unique des commandes de la présentation battle Flutter.
  ///
  /// Les anciennes méthodes ciblées restent publiques pour le host développeur,
  /// mais le shell joueur passe par ce contrat afin de refuser les taps issus
  /// d'un snapshot obsolète.
  bool dispatchBattlePresentationCommand(
    BattlePresentationCommand command,
  ) {
    final snapshot = _battleCommandOverlayNotifier.value;
    if (snapshot == null ||
        !validateBattlePresentationCommand(snapshot, command).accepted) {
      return false;
    }
    return switch (command) {
      BattleBackCommand() => backFromBattleOverlay(),
      BattleSelectEntryCommand(:final entryIndex) => switch (snapshot.mode) {
          BattleCommandOverlayMode.root => selectBattleRootEntry(entryIndex),
          BattleCommandOverlayMode.fight ||
          BattleCommandOverlayMode.continueOnly =>
            selectBattleChoiceEntry(entryIndex),
          BattleCommandOverlayMode.bag => selectBattleBagEntry(entryIndex),
          BattleCommandOverlayMode.pokemon =>
            selectBattlePartyEntry(entryIndex),
          BattleCommandOverlayMode.bagMedicineTarget =>
            selectBattleMedicineTargetEntry(entryIndex),
        },
    };
  }

  bool selectBattleRootEntry(int index) {
    return _battleOverlay?.selectRootEntry(index) ?? false;
  }

  bool selectBattleChoiceEntry(int index) {
    return _battleOverlay?.selectChoiceEntry(index) ?? false;
  }

  bool selectBattleBagEntry(int index) {
    return _battleOverlay?.selectBagEntry(index) ?? false;
  }

  bool selectBattlePartyEntry(int index) {
    return _battleOverlay?.selectPartyEntry(index) ?? false;
  }

  bool selectBattleMedicineTargetEntry(int index) {
    return _battleOverlay?.selectMedicineTargetEntry(index) ?? false;
  }

  bool backFromBattleOverlay() {
    return _battleOverlay?.handleEscape() ?? false;
  }

  MovementMode get playerMovementMode {
    if (isLoaded) {
      return _world.player.movementMode;
    }
    return _gameState.playerMovementMode;
  }

  bool get isSurfing => playerMovementMode == MovementMode.surf;

  bool get isBattleUiActive =>
      _flowPhase == _RuntimeFlowPhase.battle ||
      _flowPhase == _RuntimeFlowPhase.battleTransition;

  ({String mapId, int playerX, int playerY, String facing, String movementMode})
      get saveLoadInfo {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return (
      mapId: _gameState.currentMapId,
      playerX: _gameState.playerPosition.x,
      playerY: _gameState.playerPosition.y,
      facing: _gameState.playerFacing.name,
      movementMode: _gameState.playerMovementMode.name,
    );
  }

  GameState get gameStateSnapshot {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return _gameState;
  }

  /// Snapshot used by a Shop/PC route opened from an executing Scene.
  ///
  /// Consequences already applied inside the Scene live in its working
  /// session until the Scene transaction completes, so the overlay must not
  /// fall back to the older Flame snapshot.
  GameState get playerServiceGameStateSnapshot =>
      _activeNarrativeSceneWorkingSession?.gameState ?? gameStateSnapshot;

  /// Installs the host-owned Shop/PC coordinator after the Flame game exists.
  ///
  /// The host needs the game instance to provide state, save and input-lock
  /// callbacks, which makes post-construction attachment explicit and avoids a
  /// circular constructor dependency.
  void setPlayerServiceRuntimeController(
    PlayerServiceRuntimeController controller,
  ) {
    _playerServiceRuntimeController = controller;
  }

  /// Opens the production Shop overlay for typed interactive evaluation.
  ///
  /// This stays on the real player-service controller: pricing, conditions,
  /// commits, saves and input locks are not duplicated in the evaluator.
  @visibleForTesting
  Future<void> debugOpenPlayerServiceShop(String shopId) async {
    final shop = _bundle.manifest.shops
        .where((candidate) => candidate.id == shopId)
        .firstOrNull;
    if (shop == null) {
      throw StateError('Unknown player-service Shop "$shopId".');
    }
    final controller = _playerServiceRuntimeController;
    if (controller == null) {
      throw StateError('The player-service controller is unavailable.');
    }
    final result = await controller.openShop(shop);
    if (result.status != PlayerServiceRuntimeStatus.completed) {
      throw StateError(
        'The player-service Shop ended with ${result.status.name}.',
      );
    }
  }

  /// Commits a player-service mutation to the live narrative state and save.
  ///
  /// A failed save restores the previous in-memory transaction snapshot so a
  /// closed Shop, PC or healing overlay never leaves a half-committed session.
  Future<void> commitAndSavePlayerServiceState(GameState nextState) async {
    final activeScene = _activeNarrativeSceneWorkingSession;
    if (activeScene != null) {
      // The Scene owns the current atomic state transaction. Persisting here
      // would checkpoint a transient sceneActive state and is intentionally
      // rejected by the save interlock. The completed Scene publishes this
      // working state; the player shell can then checkpoint it safely.
      activeScene.gameState = nextState;
      return;
    }
    final previousState = await _narrativeStateTransactions.read();
    try {
      final committedState =
          await _narrativeStateTransactions.transact<GameState>((_) {
        return NarrativeEventStateTransaction.commit(nextState, nextState);
      });
      _applyNarrativeGameState(committedState);
      final saved = await saveGame();
      if (!saved) {
        throw StateError('Player service state could not be saved.');
      }
    } catch (error) {
      await _narrativeStateTransactions.transact<void>((_) {
        return NarrativeEventStateTransaction.commit(previousState, null);
      });
      _applyNarrativeGameState(previousState);
      rethrow;
    }
  }

  /// The single player-input authority exposed to Flutter hosts and tests.
  RuntimeInputAuthoritySnapshot get inputAuthoritySnapshot {
    _syncDerivedInputLocks();
    final lockSnapshot = _inputLocks.snapshot;
    final externalTokens = _externalInputLocks.values.toSet();
    final internalTokens = lockSnapshot.activeTokens
        .where((token) => !externalTokens.contains(token))
        .toList(growable: false);
    final internalSurface = internalTokens.isEmpty
        ? RuntimeInputSurface.world
        : internalTokens.last.surface;
    final context = switch (internalSurface) {
      RuntimeInputSurface.world => RuntimeInputContext.overworld,
      RuntimeInputSurface.dialogue => RuntimeInputContext.dialogue,
      RuntimeInputSurface.cinematic => RuntimeInputContext.cinematic,
      RuntimeInputSurface.battle ||
      RuntimeInputSurface.progression =>
        RuntimeInputContext.battle,
      RuntimeInputSurface.transition => RuntimeInputContext.transition,
      RuntimeInputSurface.pause ||
      RuntimeInputSurface.playerService ||
      RuntimeInputSurface.blocked ||
      RuntimeInputSurface.background ||
      RuntimeInputSurface.completion =>
        RuntimeInputContext.blocked,
    };
    return RuntimeInputAuthoritySnapshot(
      context: context,
      externalLocks:
          Set<RuntimeExternalInputLock>.unmodifiable(_externalInputLocks.keys),
    );
  }

  void _publishInputAuthoritySnapshot() {
    final next = inputAuthoritySnapshot;
    if (_inputAuthorityNotifier.value != next) {
      _inputAuthorityNotifier.value = next;
    }
  }

  void _setFlowPhase(_RuntimeFlowPhase phase) {
    final previousToken = _flowInputLock;
    _flowInputLock = null;
    if (previousToken != null) {
      _inputLocks.release(
        owner: previousToken.owner,
        token: previousToken,
      );
    }
    _flowPhase = phase;
    switch (phase) {
      case _RuntimeFlowPhase.overworld:
        break;
      case _RuntimeFlowPhase.blockingInteraction:
        _flowInputLock = _inputLocks.acquire(
          owner: RuntimeInputLockOwner.blockingInteraction,
          surface: RuntimeInputSurface.blocked,
        );
      case _RuntimeFlowPhase.dialogue:
        _flowInputLock = _inputLocks.acquire(
          owner: RuntimeInputLockOwner.dialogue,
          surface: RuntimeInputSurface.dialogue,
        );
      case _RuntimeFlowPhase.mapTransition:
      case _RuntimeFlowPhase.battleTransition:
        _flowInputLock = _inputLocks.acquire(
          owner: RuntimeInputLockOwner.transition,
          surface: RuntimeInputSurface.transition,
        );
      case _RuntimeFlowPhase.battle:
        _flowInputLock = _inputLocks.acquire(
          owner: RuntimeInputLockOwner.battle,
          surface: RuntimeInputSurface.battle,
        );
    }
    _publishInputAuthoritySnapshot();
  }

  void _setCinematicInputLocked(bool locked) {
    if (locked) {
      _cinematicInputLock ??= _inputLocks.acquire(
        owner: RuntimeInputLockOwner.cinematic,
        surface: RuntimeInputSurface.cinematic,
      );
      if (isLoaded) {
        _clearPressedMovementControls();
      }
      _publishInputAuthoritySnapshot();
      return;
    }
    final token = _cinematicInputLock;
    _cinematicInputLock = null;
    if (token != null) {
      _inputLocks.release(
        owner: RuntimeInputLockOwner.cinematic,
        token: token,
      );
    }
    _publishInputAuthoritySnapshot();
  }

  void _syncDerivedInputLocks() {
    _setDerivedInputLock(
      RuntimeInputLockOwner.blockingInteraction,
      RuntimeInputSurface.blocked,
      _activeBlockingInteractionSerial != null,
    );
    _setDerivedInputLock(
      RuntimeInputLockOwner.mapActivation,
      RuntimeInputSurface.blocked,
      _blocksOverworldForMapActivationWork,
    );
    _setDerivedInputLock(
      RuntimeInputLockOwner.narrativeDispatch,
      RuntimeInputSurface.blocked,
      _blocksOverworldForNarrativeDispatch,
    );
    _setDerivedInputLock(
      RuntimeInputLockOwner.checkpoint,
      RuntimeInputSurface.blocked,
      _narrativeActivityGate.checkpointInProgress,
    );
    _setDerivedInputLock(
      RuntimeInputLockOwner.scriptedMovement,
      RuntimeInputSurface.blocked,
      _suppressOverworldInputForScriptedPlayerMovement(),
    );
    _setDerivedInputLock(
      RuntimeInputLockOwner.cutscene,
      RuntimeInputSurface.blocked,
      isCutsceneRunning,
    );
  }

  void _setDerivedInputLock(
    RuntimeInputLockOwner owner,
    RuntimeInputSurface surface,
    bool locked,
  ) {
    if (locked) {
      _derivedInputLocks.putIfAbsent(
        owner,
        () => _inputLocks.acquire(owner: owner, surface: surface),
      );
      return;
    }
    final token = _derivedInputLocks.remove(owner);
    if (token != null) {
      _inputLocks.release(owner: owner, token: token);
    }
  }

  /// Acquires or releases a lock owned by a Flutter player surface.
  ///
  /// Acquiring a lock also clears held directions. This prevents a key or
  /// gamepad axis pressed just before opening the menu from resuming movement
  /// when the route closes.
  void setExternalInputLock(
    RuntimeExternalInputLock owner, {
    required bool locked,
  }) {
    if (locked) {
      _externalInputLocks.putIfAbsent(
        owner,
        () => _inputLocks.acquire(
          owner: _inputOwnerForExternalLock(owner),
          surface: _inputSurfaceForExternalLock(owner),
        ),
      );
      if (isLoaded) {
        _clearPressedMovementControls();
      }
      _publishInputAuthoritySnapshot();
      return;
    }
    final token = _externalInputLocks.remove(owner);
    if (token != null) {
      _inputLocks.release(
        owner: _inputOwnerForExternalLock(owner),
        token: token,
      );
    }
    _publishInputAuthoritySnapshot();
  }

  void _releasePostBattleInputLock() {
    final token = _postBattleInputLock;
    _postBattleInputLock = null;
    if (token != null) {
      _inputLocks.release(
        owner: RuntimeInputLockOwner.postBattleProgression,
        token: token,
      );
    }
  }

  @visibleForTesting
  RuntimeInputLockSnapshot get debugInputLockSnapshot {
    _syncDerivedInputLocks();
    return _inputLocks.snapshot;
  }

  @visibleForTesting
  String get debugFlowPhaseName => _flowPhase.name;

  @visibleForTesting
  bool get debugIsMapActivationDispatchInFlight =>
      _inFlightMapActivationDispatchIds.isNotEmpty;

  @visibleForTesting
  bool get debugIsNarrativeSpatialDispatchInFlight =>
      _inFlightSpatialDispatchCount > 0;

  @visibleForTesting
  int get debugPendingNarrativeTriggerEntryCount =>
      _pendingNarrativeTriggerEntries.length;

  @visibleForTesting
  bool get debugIsNarrativeOutcomeWorkInFlight =>
      _narrativeOutcomeDrainFuture != null ||
      _inFlightRootOutcomePublicationCount > 0;

  @visibleForTesting
  bool get debugHasPendingSceneBattle =>
      _pendingSceneBattleOutcomeCompleter != null;

  @visibleForTesting
  bool get debugHasPendingScenarioBattle =>
      _pendingScenarioBattleHandoff != null;

  @visibleForTesting
  BattleStartRequest? get debugPendingBattleRequest => _pendingBattleRequest;

  @visibleForTesting
  bool debugTryEnqueueBattleRequestForTest(BattleStartRequest request) {
    return _tryEnqueueBattleRequest(request);
  }

  @visibleForTesting
  bool get debugHasPendingScenarioTransitionMap =>
      _pendingScenarioTransitionMapRequest != null;

  @visibleForTesting
  String? get debugPendingScenarioTransitionTargetMapId =>
      _pendingScenarioTransitionMapRequest?.mapId;

  @visibleForTesting
  Future<NarrativeSceneExecutionResult> debugExecuteNarrativeSceneForTest(
    NarrativeSceneExecutionRequest request,
  ) {
    return _executeNarrativeScene(request);
  }

  @visibleForTesting
  bool get debugIsLoadActivationWorkInFlight => _isLoadActivationWorkInFlight;

  @visibleForTesting
  int get debugCompletedMapActivationDispatchCount =>
      _completedMapActivationDispatchCount;

  @visibleForTesting
  MapActivation? get debugLastCompletedMapActivation =>
      _lastCompletedMapActivation;

  @visibleForTesting
  bool get debugHasPendingDialogueLoad => _hasPendingDialogueLoad;

  @visibleForTesting
  bool get debugIsGameplayInputLocked =>
      inputAuthoritySnapshot.isGameplayLocked;

  @visibleForTesting
  bool get debugIsCinematicPlaying => _cinematicRuntimeController.isPlaying;

  @visibleForTesting
  String? get debugCinematicDialogueLine => _cinematicRuntimeHost.dialogueLine;

  @visibleForTesting
  double? get debugCinematicFadeOpacity => _cinematicRuntimeHost.fadeOpacity;

  @visibleForTesting
  GridPos get debugPlayerGridPosition => _world.player.pos;

  @visibleForTesting
  bool get debugHasActiveScenarioFollow =>
      _pendingScenarioFollowRequest != null;

  @visibleForTesting
  String? get debugScenarioFollowLeaderId =>
      _pendingScenarioFollowRequest?.leaderEntityId;

  @visibleForTesting
  int get debugScenarioFollowConsecutiveBlockedSteps =>
      _pendingScenarioFollowRequest?.consecutiveBlockedSteps ?? 0;

  @visibleForTesting
  int get debugLastFollowPathNodeCount => _lastFollowPathNodeCount;

  @visibleForTesting
  GridPos? get debugScenarioFollowDestination => _lastFollowPathDestination;

  @visibleForTesting
  bool get debugHasPendingLeaderWarpHandoff =>
      _pendingScenarioLeaderWarpHandoff != null;

  @visibleForTesting
  int get debugPendingScenarioNpcWarpEntryCount =>
      _pendingScenarioNpcWarpEntries.length;

  @visibleForTesting
  GridPos? debugNpcGridPosition(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final movement = scriptedNpcMovementStatus(normalized);
    if (movement.entityId == normalized &&
        movement.state != ScriptedEntityMovementState.failed) {
      return movement.currentPos;
    }
    return _resolveScenarioEntityPosition(normalized);
  }

  @visibleForTesting
  String? get debugNotificationText => _notification?.text;

  @visibleForTesting
  bool get debugIsPlayerStepping => _player.isStepping;

  @visibleForTesting
  bool get debugHasPendingMapTransition =>
      _pendingWarp != null || _pendingConnection != null;

  @visibleForTesting
  GridPos? get debugRenderedPlayerFootCell =>
      isLoaded ? _renderedPlayerFootGridCell() : null;

  @visibleForTesting
  Vector2 get debugPlayerWorldTopLeft => _player.position.clone();

  @visibleForTesting
  Vector2 get debugPlayerScreenTopLeft {
    return debugPlayerWorldTopLeft - debugCameraWorldTopLeft;
  }

  @visibleForTesting
  Vector2 get debugPlayerScreenFootPoint {
    return _player.footPoint - debugCameraWorldTopLeft;
  }

  @visibleForTesting
  ShadowRuntimeInstructionCollectionProvider?
      debugShadowCollectionProviderForMap(
    String mapId,
  ) =>
          _shadowCollectionProviderForMap(mapId);

  @visibleForTesting
  Vector2 get debugMapOriginWorldTopLeft => _player.mapOrigin;

  @visibleForTesting
  Vector2 debugMapCellWorldTopLeft(GridPos cell) {
    return Vector2(
      _player.mapOrigin.x + cell.x * _cellWidth,
      _player.mapOrigin.y + cell.y * _cellHeight,
    );
  }

  @visibleForTesting
  Vector2 debugWorldToScreen(Vector2 worldPoint) {
    return worldPoint - debugCameraWorldTopLeft;
  }

  @visibleForTesting
  Vector2 get debugCameraWorldTopLeft {
    final visibleSize = camera.viewfinder.visibleGameSize;
    final viewportSize =
        visibleSize ?? Vector2(camera.viewport.size.x, camera.viewport.size.y);
    final center = camera.viewfinder.position;
    return Vector2(
      center.x - viewportSize.x / 2,
      center.y - viewportSize.y / 2,
    );
  }

  @visibleForTesting
  Vector2? get debugPlayerActorLocalPosition => _player.debugActorLocalPosition;

  @visibleForTesting
  bool debugIsMapLoaded(String mapId) => _loadedMapsById.containsKey(mapId);

  @visibleForTesting
  Future<RuntimeMapBundle> debugLoadRuntimeMapBundleCachedForTest(
    String mapId,
  ) =>
      _loadRuntimeMapBundleCached(mapId);

  @visibleForTesting
  void debugUnmountLoadedMapForTest(String mapId) {
    _unmountLoadedMap(mapId);
  }

  @visibleForTesting
  void debugRepositionLoadedMapForTest({
    required String mapId,
    required int originCellX,
    required int originCellY,
  }) {
    final loaded = _loadedMapsById[mapId];
    if (loaded == null) {
      return;
    }
    _repositionLoadedMap(
      loaded,
      originCellX: originCellX,
      originCellY: originCellY,
    );
  }

  @visibleForTesting
  Vector2 debugWorldTopLeftForSpawnCell(GridPos cell) {
    return _worldTopLeftForPlayerSpawnCell(
      bundle: _bundle,
      mapOrigin: _player.mapOrigin,
      cell: cell,
      playerState: _world.player,
    );
  }

  @visibleForTesting
  Vector2 get debugExpectedPlayerWorldTopLeft {
    final tileWidth = _bundle.manifest.settings.tileWidth;
    final tileHeight = _bundle.manifest.settings.tileHeight;
    final scaleX = _cellWidth / (tileWidth > 0 ? tileWidth : 1);
    final scaleY = _cellHeight / (tileHeight > 0 ? tileHeight : 1);
    final origin = _player.mapOrigin;
    final topLeft = _world.player.playerPositionPx;
    return Vector2(
      (origin.x + topLeft.leftPx * scaleX).roundToDouble(),
      (origin.y + topLeft.topPx * scaleY).roundToDouble(),
    );
  }

  @visibleForTesting
  int get debugBattleMoveCatalogReadCount =>
      _battleMoveCatalogLoader.debugActualReadCount;

  @visibleForTesting
  int get debugEncounterCheckCount => _debugEncounterCheckCount;

  @visibleForTesting
  int get debugBattleSpeciesReadCount =>
      _battleSpeciesLoader.debugActualReadCount;

  @visibleForTesting
  int get debugBattleLearnsetReadCount =>
      _battleLearnsetLoader.debugActualReadCount;

  @visibleForTesting
  int get debugBattleSpriteMediaReadCount =>
      _battleSpriteResolver.debugActualMediaReadCount;

  @visibleForTesting
  int get debugBattleVisualImageLoadCount =>
      _battleVisualAssetCache.debugActualImageLoadCount;

  @visibleForTesting
  int get debugBattleVisualOpaqueRectComputeCount =>
      _battleVisualAssetCache.debugActualOpaqueRectComputeCount;

  @visibleForTesting
  bool get debugBattleOverlayMounted => _battleOverlay != null;

  @visibleForTesting
  bool get debugPostBattleOverlayMounted =>
      _postBattleProgressionOverlay != null;

  @visibleForTesting
  bool get debugIsBattleResolving => _isBattleResolving;

  @visibleForTesting
  List<String> get debugPostBattleDecisionLabels =>
      _postBattleProgressionOverlay?.decisionLabels ?? const <String>[];

  @visibleForTesting
  bool debugValidatePostBattleChoice() =>
      _postBattleProgressionOverlay?.validateSelectedChoice() ?? false;

  @visibleForTesting
  BattleOverlayComponent? get debugBattleOverlayComponent => _battleOverlay;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _battleOverlay?.onGameResize(camera.viewport.size.clone());
    _postBattleProgressionOverlay?.onGameResize(camera.viewport.size.clone());
    _cinematicRuntimeHost.onViewportResize(camera.viewport.size.clone());
  }

  @visibleForTesting
  BattleSession? get debugBattleSessionSnapshot => _battleSession;

  @visibleForTesting
  bool get debugPsdkBattleSessionActive => _psdkBattleSession != null;

  @visibleForTesting
  Future<void> debugOpenBattleForTest(BattleStartRequest request) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      throw StateError('Battle test seam requires overworld flow.');
    }
    _setFlowPhase(_RuntimeFlowPhase.battleTransition);
    await _openBattleOverlay(request);
  }

  @visibleForTesting
  Future<void> debugWaitForBattleOverlaySync() async {
    await (_battleOverlay?.waitForPendingVisualSync() ?? Future<void>.value());
  }

  @visibleForTesting
  void debugPublishBattleCommandOverlaySnapshotForTest(
    BattleCommandOverlaySnapshot? snapshot,
  ) {
    _setBattleCommandOverlaySnapshot(snapshot);
  }

  @visibleForTesting
  void debugResetBattleForTest() {
    _cinematicRuntimeController.cancel(
      message: 'Cinematic playback was cancelled by debug battle reset.',
    );
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _postBattleProgressionOverlay?.removeFromParent();
    _postBattleProgressionOverlay = null;
    _setPostBattlePresentationSnapshot(null);
    _setBattleCommandOverlaySnapshot(null);
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _psdkBattleSession = null;
    _activeBattleContext = null;
    _captureAttemptReceipt = null;
    _isBattleResolving = false;
    _isPostBattleFlowRunning = false;
    _isPostBattleCommitCompleted = false;
    _releasePostBattleInputLock();
    _postBattleFlowGeneration += 1;
    final postBattleCompleter = _postBattleFlowCompleter;
    if (postBattleCompleter != null && !postBattleCompleter.isCompleted) {
      postBattleCompleter.complete();
    }
    _pendingBattleRequest = null;
    _pendingSceneBattleOutcomeCompleter = null;
    _pendingSceneBattleRequestId = null;
    _completePendingSceneDialogue(
      const SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
        message: 'Scene dialogue was cancelled by debug battle reset.',
      ),
    );
    _setFlowPhase(_RuntimeFlowPhase.overworld);
    _clearPressedMovementControls();
  }

  @visibleForTesting
  Future<void> debugStartPostBattleForTest({
    required RuntimeActiveBattleContext context,
    required BattleOutcome outcome,
    RuntimeBattleCaptureAttemptReceipt? captureAttemptReceipt,
  }) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      throw StateError('Post-battle test seam requires overworld flow.');
    }
    _activeBattleContext = context;
    _captureAttemptReceipt = captureAttemptReceipt;
    _setFlowPhase(_RuntimeFlowPhase.battle);
    _isBattleResolving = true;
    await _beginPostBattleFlow(outcome);
  }

  @visibleForTesting
  Future<void> debugWaitForPostBattleCompletion() =>
      _postBattleCompletionFuture;

  @visibleForTesting
  Future<void> debugWaitForDefeatRecovery() => _defeatRecoveryFuture;

  @visibleForTesting
  void debugApplyBattleOutcomeForTest({
    required RuntimeActiveBattleContext context,
    required BattleOutcome outcome,
    RuntimeBattleCaptureAttemptReceipt? captureAttemptReceipt,
  }) {
    // Seam de test volontairement fin :
    // - on ne contourne pas la logique réelle de fin de combat ;
    // - on évite en revanche de devoir piloter tout l'overlay Flame au clavier
    //   pour prouver les garanties lot 15 ;
    // - le runtime garde donc un point d'entrée stable pour tester le write-back
    //   + la reprise overworld sans créer d'API produit parallèle.
    _pendingBattleRequest = null;
    _activeBattleContext = context;
    _captureAttemptReceipt = captureAttemptReceipt;
    _setFlowPhase(_RuntimeFlowPhase.battle);
    _onBattleFinished(outcome);
  }

  @visibleForTesting
  void debugSetPlayerStateForTest({
    required GridPos position,
    required Direction facing,
    MovementMode movementMode = MovementMode.walk,
  }) {
    _world = _world.withPlayer(
      _gridAlignedPlayerState(
        position: position,
        facing: facing,
        movementMode: movementMode,
      ),
    );
    _player.syncState(_world.player, snapToGrid: true);
    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    _syncCameraToPlayer();
  }

  @visibleForTesting
  bool debugStartScenarioFollow(String leaderEntityId) {
    return _runScenarioFollowCharacter(leaderEntityId: leaderEntityId);
  }

  @visibleForTesting
  bool debugRunScenarioMoveCharacterToWarp({
    required String entityId,
    required String warpId,
  }) {
    return _runScenarioMoveCharacter(
      entityId: entityId,
      targetKind: 'warp',
      targetId: warpId,
      waitForCompletion: false,
      runtimeSourceId: 'debug_follow_warp',
    );
  }

  void _syncGameStateFromWorld({String? mapIdOverride}) {
    final mapId = mapIdOverride ?? _activeMapId;
    _gameState = _gameState.copyWith(
      currentMapId: mapId,
      playerPosition: _world.player.pos,
      playerFacing: _world.player.facing.asFacing,
      playerMovementMode: _world.player.movementMode,
    );
  }

  /// Filtre spatial PNJ : d’abord [MapEntityNpcData.visibilityRule], puis
  /// les `worldChanges` Step Studio (même [mapId] / [entity.id] que l’authoring).
  ///
  /// Les règles Step Studio sont relues via [_ensureStepStudioWorldRulesForManifest]
  /// **à chaque évaluation** pour éviter une liste [worldRules] capturée une fois
  /// et obsolète si le cache manifeste est invalidé.
  NpcMapPresencePredicate _npcPresencePredicateFor(
    ProjectManifest manifest, {
    GameState? gameStateOverride,
    MapData? mapOverride,
  }) {
    return (String mapId, MapEntity npcEntity) {
      final gameState = gameStateOverride ?? _gameState;
      final explicitPresence = sceneNpcPresenceOverride(
        gameState,
        mapId: mapId,
        entityId: npcEntity.id,
      );
      if (explicitPresence != null) {
        return explicitPresence;
      }
      _ensureStepStudioWorldRulesForManifest(manifest);
      final baseVisible = isNpcRuntimePresentOnMap(
        gameState: gameState,
        manifest: manifest,
        stepStudioWorldRules: _cachedStepStudioWorldRules,
        mapId: mapId,
        entity: npcEntity,
        chapterIndex: _globalStoryChapterIndexFor(manifest),
      );
      final projection = _resolveWorldRuleProjectionForMap(
        mapId,
        manifest,
        gameStateOverride: gameState,
        mapOverride: mapOverride,
      );
      if (projection == null) {
        return baseVisible;
      }
      return projection.isMapEntityVisible(
        npcEntity,
        defaultVisible: baseVisible,
      );
    };
  }

  MapEntityPresencePredicate _mapEntityPresencePredicateFor(
    ProjectManifest manifest, {
    GameState? gameStateOverride,
    MapData? mapOverride,
  }) {
    return (String mapId, MapEntity entity) {
      final projection = _resolveWorldRuleProjectionForMap(
        mapId,
        manifest,
        gameStateOverride: gameStateOverride,
        mapOverride: mapOverride,
      );
      return projection?.isMapEntityVisible(entity) ?? true;
    };
  }

  /// Dialogue effectif : variantes ordonnées puis dialogue par défaut du PNJ.
  DialogueRef? _resolveNpcDialogueRef(MapEntity entity) {
    final npc = entity.npc;
    if (npc == null) {
      return null;
    }
    final projection = _resolveWorldRuleProjectionForMap(
      _world.map.id,
      _bundle.manifest,
    );
    final overrideDialogueId = projection?.dialogueOverrideForEntity(entity.id);
    if (overrideDialogueId != null) {
      return DialogueRef(dialogueId: overrideDialogueId);
    }
    return MapEntityRuntimePredicateEvaluator(
      gameState: _gameState,
      chapterIndex: _globalStoryChapterIndexFor(_bundle.manifest),
    ).resolveNpcDialogue(npc);
  }

  final Map<String, _WorldRuleProjectionCache> _worldRuleProjectionCacheByMapId =
      <String, _WorldRuleProjectionCache>{};

  RuntimeWorldRuleProjectionState? _resolveWorldRuleProjectionForMap(
    String mapId,
    ProjectManifest manifest, {
    GameState? gameStateOverride,
    MapData? mapOverride,
  }) {
    final map = (mapOverride?.id == mapId ? mapOverride : null) ??
        _runtimeBundleByMapId[mapId]?.map ??
        _loadedMapsById[mapId]?.bundle.map ??
        (mapId == _bundle.map.id ? _bundle.map : null);
    if (map == null) {
      return null;
    }
    // La projection était recalculée (résolution complète des effets + 9
    // copies de collections) pour chaque PNJ dans la closure de présence.
    // Ses entrées sont immuables et remplacées par identité : un refresh de
    // présence la calcule une fois par carte, pas une fois par entité.
    final gameState = gameStateOverride ?? _gameState;
    final cached = _worldRuleProjectionCacheByMapId[mapId];
    if (cached != null &&
        identical(cached.manifest, manifest) &&
        identical(cached.gameState, gameState) &&
        identical(cached.map, map)) {
      return cached.projection;
    }
    final projection = const RuntimeWorldRuleProjectionHook().resolve(
      project: manifest,
      gameState: gameState,
      map: map,
    );
    _worldRuleProjectionCacheByMapId[mapId] = _WorldRuleProjectionCache(
      manifest: manifest,
      gameState: gameState,
      map: map,
      projection: projection,
    );
    return projection;
  }

  void _refreshWorldNpcPresence() {
    if (!isLoaded) {
      return;
    }
    _world = _world.withNpcMapPresencePredicate(
      _npcPresencePredicateFor(_bundle.manifest),
    );
    _world = _world.withMapEntityPresencePredicate(
      _mapEntityPresencePredicateFor(_bundle.manifest),
    );
    _mountNewlyPresentNpcActorsOnLoadedMaps();
    // Retirer les acteurs Flame des PNJ désormais absents (évite toute dérive
    // visuelle / hit test si un composant repasse « visible » par défaut).
    _detachAbsentNpcActorsFromAllLoadedMaps();
    _syncNpcRenderVisibility();
    _syncNpcCollisionDebugOverlay();
    // Patrouilles / réservations / LoS trainer : mêmes règles que le gameplay
    // (un PNJ « absent » ne doit plus consommer ces systèmes parallèles).
    _stopGameplaySideEffectsForAbsentNpcs();
  }

  /// Retire les [OverworldActorComponent] pour tout PNJ avec personnage dont le
  /// prédicat de présence est faux (cartes chargées / voisines incluses).
  void _detachAbsentNpcActorsFromAllLoadedMaps() {
    for (final loaded in _loadedMapsById.values) {
      final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
      final mapId = loaded.bundle.map.id;
      final toRemove = <String>[];
      for (final entity in loaded.bundle.map.entities) {
        if (entity.kind != MapEntityKind.npc) {
          continue;
        }
        final charId = resolveNpcCharacterId(entity, loaded.bundle.manifest);
        if (charId == null || charId.isEmpty) {
          continue;
        }
        if (npcPred(mapId, entity)) {
          continue;
        }
        if (loaded.npcActorByEntityId.containsKey(entity.id)) {
          toRemove.add(entity.id);
        }
      }
      for (final rawId in toRemove) {
        final id = rawId.trim();
        if (id.isEmpty) {
          continue;
        }
        _scriptedEntityMovementController?.stopPatrol(id);
        _scriptedEntityMovementController?.untrackEntity(id);
        _scriptedNpcReservedOccupiedCellsByEntity.remove(id);
        _runtimeNpcPositions.remove(id);
        _triggeredTrainerBattles.remove(id);
        if (_pendingScenarioFollowRequest?.leaderEntityId == id) {
          _pendingScenarioFollowRequest = null;
        }
        _pendingScenarioNpcWarpEntries.remove(id);
        final pendingMove =
            _pendingScenarioMoveContinuationsByEntity.remove(id);
        if (pendingMove != null) {
          _cancelNarrativeContinuationBarrier(pendingMove.runtimeSourceId);
        }
        _purgeMountedNpcActorForEntity(entityId: id, loaded: loaded);
      }
    }
  }

  void _mountNewlyPresentNpcActorsOnLoadedMaps() {
    for (final loaded in _loadedMapsById.values) {
      final charById = {
        for (final character in loaded.bundle.manifest.characters)
          character.id: character,
      };
      final mapOrigin = _originPixels(
        originCellX: loaded.originCellX,
        originCellY: loaded.originCellY,
      );
      for (final entity in loaded.bundle.map.entities) {
        if (entity.kind != MapEntityKind.npc ||
            sceneNpcPresenceOverride(
                  _gameState,
                  mapId: loaded.bundle.map.id,
                  entityId: entity.id,
                ) !=
                true ||
            loaded.npcActorByEntityId.containsKey(entity.id)) {
          continue;
        }
        final characterId =
            resolveNpcCharacterId(entity, loaded.bundle.manifest);
        final character = characterId == null ? null : charById[characterId];
        if (character == null) continue;
        final actor = OverworldActorComponent(
          character: character,
          tileImages: loaded.tileImagesById,
          tileWidth: loaded.bundle.manifest.settings.tileWidth,
          tileHeight: loaded.bundle.manifest.settings.tileHeight,
          cellWidth: loaded.bundle.cellWidth,
          cellHeight: loaded.bundle.cellHeight,
          facing: entity.npc?.facing ?? EntityFacing.south,
        );
        actor.configureGridPlacement(
          pos: entity.pos,
          footprint: entity.size,
          mapOrigin: mapOrigin,
          snapToGrid: true,
        );
        loaded.npcActors.add(actor);
        loaded.npcActorByEntityId[entity.id] = actor;
        _npcActors.add(actor);
        world.add(actor);
        if (loaded.bundle.map.id == _activeMapId) {
          _runtimeNpcPositions[entity.id] = entity.pos;
          _scriptedEntityMovementController?.trackEntity(
            entity.id,
            entity.pos,
          );
        }
      }
    }
  }

  void _purgeMountedNpcActorForEntity({
    required String entityId,
    required _LoadedPlayableMap loaded,
  }) {
    final actor = loaded.npcActorByEntityId.remove(entityId);
    if (actor != null) {
      loaded.npcActors.remove(actor);
      _npcActors.remove(actor);
      actor.removeFromParent();
    }
    final visual = _npcCollisionDebugByEntityId.remove(entityId);
    visual?.spriteRect.removeFromParent();
    visual?.collisionRect.removeFromParent();
    visual?.anchorMarker.removeFromParent();
  }

  /// Arrête tout effet runtime **hors** [GameplayWorldState] qui pourrait encore
  /// cibler un PNJ filtré par [NpcMapPresencePredicate] (patrouille, réservation
  /// de cases, lock trainer).
  void _stopGameplaySideEffectsForAbsentNpcs() {
    final controller = _scriptedEntityMovementController;
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (pred(mapId, entity)) {
        continue;
      }
      controller?.stopPatrol(entity.id);
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entity.id);
      _runtimeNpcPositions.remove(entity.id);
      _triggeredTrainerBattles.remove(entity.id);
    }
    _applyNpcOverworldDefaultMovement();
  }

  void _syncNpcRenderVisibility() {
    for (final loaded in _loadedMapsById.values) {
      _applyNpcVisibilityToLoadedMap(loaded);
    }
  }

  void _applyNpcVisibilityToLoadedMap(_LoadedPlayableMap loaded) {
    final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
    final entityPred = _mapEntityPresencePredicateFor(loaded.bundle.manifest);
    loaded.backgroundLayers.npcMapPresencePredicate = npcPred;
    loaded.foregroundLayers.npcMapPresencePredicate = npcPred;
    loaded.backgroundLayers.mapEntityPresencePredicate = entityPred;
    loaded.foregroundLayers.mapEntityPresencePredicate = entityPred;
    for (final entity in loaded.bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final present = npcPred(loaded.bundle.map.id, entity);
      // Trace "source de vérité -> rendu" :
      // on journalise la décision finale de présence pour chaque PNJ afin de
      // diagnostiquer rapidement un cas "la règle existe mais l'acteur reste visible".
      debugPrint(
        '[step_studio_trace] npc_presence_applied map=${loaded.bundle.map.id} entity=${entity.id} present=$present',
      );
      loaded.npcActorByEntityId[entity.id]?.setGameplayVisible(present);
    }
  }

  RuntimeMapBundle _resolveRuntimeBundle(RuntimeMapBundle bundle) {
    final transform = bundleTransformer;
    if (transform == null) {
      return bundle;
    }
    return transform(bundle);
  }

  Future<RuntimeMapBundle> _loadRuntimeMapBundleCached(String mapId) async {
    final cached = _runtimeBundleByMapId[mapId];
    if (cached != null) {
      final prepared = await prepareBorderRuntimeBundle(cached);
      _runtimeBundleByMapId[mapId] = prepared;
      return prepared;
    }
    final inFlight = _runtimeBundleFutureByMapId[mapId];
    if (inFlight != null) {
      return await inFlight;
    }
    final future = () async {
      final loaded = await _runtimeMapBundleLoader(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      final resolved = _resolveRuntimeBundle(loaded);
      final prepared = await prepareBorderRuntimeBundle(resolved);
      _runtimeBundleByMapId[mapId] = prepared;
      return prepared;
    }();
    _runtimeBundleFutureByMapId[mapId] = future;
    try {
      return await future;
    } finally {
      final current = _runtimeBundleFutureByMapId[mapId];
      if (identical(current, future)) {
        _runtimeBundleFutureByMapId.remove(mapId);
      }
    }
  }

  Future<Map<String, RuntimeTilesetImage>> _loadTilesetImagesCached(
    Map<String, String> absolutePathByTilesetId, {
    ProjectManifest? manifest,
  }) async {
    if (absolutePathByTilesetId.isEmpty) {
      debugPrint('[runtime_game] tileset cache skipped: no tilesets');
      return const <String, RuntimeTilesetImage>{};
    }
    debugPrint(
      '[runtime_game] tileset cache resolve requested=${absolutePathByTilesetId.length}',
    );
    final transparentColors = _transparentColorByTilesetId(
      manifest ?? _bundle.manifest,
    );
    final result = await _tilesetImageCache.loadById(
      absolutePathByTilesetId,
      transparentColorByTilesetId: transparentColors,
    );
    for (final entry in absolutePathByTilesetId.entries) {
      if (!result.containsKey(entry.key)) {
        debugPrint(
          '[runtime_game] tileset image loader returned no image id=${entry.key} path=${entry.value}',
        );
      }
    }
    debugPrint(
        '[runtime_game] tileset cache resolve ok result=${result.length}');
    return result;
  }

  Future<BorderRuntimeAssetBundle> _loadBorderRuntimeAssets(
    RuntimeMapBundle bundle,
  ) {
    final preparation = bundle.borderRuntimePreparation;
    if (preparation == null) {
      throw StateError(
        'Border runtime bundle must be prepared before visual loading: '
        '${bundle.map.id}',
      );
    }
    return _borderRuntimeAssetCache.loadCollection(
      projectRoot: bundle.projectRootDirectory,
      collection: preparation.assetCollection,
    );
  }

  Map<String, TilesetTransparentColor> _transparentColorByTilesetId(
    ProjectManifest manifest,
  ) {
    return <String, TilesetTransparentColor>{
      for (final tileset in manifest.tilesets)
        if (tileset.transparentColor != null)
          tileset.id: tileset.transparentColor!,
    };
  }

  Future<T> _traceAsync<T>(
    String domain,
    String label,
    Future<T> Function() action,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stopwatch.stop();
      debugPrint('[perf][$domain] $label=${stopwatch.elapsedMilliseconds}ms');
    }
  }

  T _traceSync<T>(
    String domain,
    String label,
    T Function() action,
  ) {
    final stopwatch = Stopwatch()..start();
    try {
      return action();
    } finally {
      stopwatch.stop();
      debugPrint('[perf][$domain] $label=${stopwatch.elapsedMilliseconds}ms');
    }
  }

  _GridCellPos _connectionEntryStartCell({
    required GridPos targetPos,
    required MapConnectionDirection direction,
  }) {
    return switch (direction) {
      MapConnectionDirection.east =>
        _GridCellPos(x: targetPos.x - 1, y: targetPos.y),
      MapConnectionDirection.west =>
        _GridCellPos(x: targetPos.x + 1, y: targetPos.y),
      MapConnectionDirection.north =>
        _GridCellPos(x: targetPos.x, y: targetPos.y + 1),
      MapConnectionDirection.south =>
        _GridCellPos(x: targetPos.x, y: targetPos.y - 1),
    };
  }

  Vector2 _worldTopLeftForPlayerSpawnCell({
    required RuntimeMapBundle bundle,
    required Vector2 mapOrigin,
    required GridPos cell,
    required GameplayPlayerState playerState,
  }) {
    final topLeft =
        PlayerCollisionConventionsV1.playerSpriteTopLeftFromSpawnCell(
      cellX: cell.x,
      cellY: cell.y,
      tileWidthPx: bundle.manifest.settings.tileWidth,
      tileHeightPx: bundle.manifest.settings.tileHeight,
      spriteWidthPx: playerState.playerSpriteWidthPx,
      spriteHeightPx: playerState.playerSpriteHeightPx,
    );
    final scaleX =
        bundle.cellWidth / math.max(1, bundle.manifest.settings.tileWidth);
    final scaleY =
        bundle.cellHeight / math.max(1, bundle.manifest.settings.tileHeight);
    return Vector2(
      mapOrigin.x + topLeft.leftPx * scaleX,
      mapOrigin.y + topLeft.topPx * scaleY,
    );
  }

  void setPlayerMovementMode(MovementMode movementMode) {
    if (!isLoaded) {
      return;
    }
    if (_world.player.movementMode == movementMode) {
      return;
    }
    _world = _world.withPlayer(
      _world.player.copyWith(movementMode: movementMode),
    );
    _syncGameStateFromWorld();
    _player.syncState(_world.player);
  }

  void setSurfingEnabled(bool enabled) {
    setPlayerMovementMode(enabled ? MovementMode.surf : MovementMode.walk);
  }

  /// Lance un déplacement scripté ponctuel pour un PNJ.
  ///
  /// API runtime publique pensée pour une future orchestration cutscene:
  /// - start movement
  /// - poll status
  /// - wait until completed/failed
  ScriptedEntityMovementStatus startScriptedNpcMove({
    required String entityId,
    required GridPos destination,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        targetPos: destination,
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    final result = controller.moveEntityTo(
      entityId: entityId,
      destination: destination,
    );
    if (result.state != ScriptedEntityMovementState.failed) {
      _cancelScenarioMoveOwnerForAcceptedReplacement(entityId);
    }
    return result;
  }

  void _cancelScenarioMoveOwnerForAcceptedReplacement(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return;
    }
    final replacedContinuation =
        _pendingScenarioMoveContinuationsByEntity.remove(normalized);
    if (replacedContinuation != null) {
      _cancelNarrativeContinuationBarrier(
        replacedContinuation.runtimeSourceId,
      );
      debugPrint(
        '[scenario_runtime] moveCharacter replaced continuation '
        'entity=$normalized source=${replacedContinuation.runtimeSourceId}',
      );
    }
    _pendingScenarioNpcWarpEntries.remove(normalized);
  }

  /// Active une patrouille simple (waypoints) pour un PNJ.
  ScriptedEntityMovementStatus startScriptedNpcPatrol({
    required String entityId,
    required List<GridPos> waypoints,
    bool loop = true,
    int pauseDurationMs = 0,
    int stepDurationMs = 200,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.startPatrol(
      ScriptedEntityPatrolRoute(
        entityId: entityId,
        waypoints: waypoints,
        loop: loop,
        pauseDurationMs: pauseDurationMs,
        stepDurationMs: stepDurationMs,
      ),
    );
  }

  void stopScriptedNpcPatrol(String entityId) {
    _scriptedEntityMovementController?.stopPatrol(entityId);
  }

  ScriptedEntityMovementStatus scriptedNpcMovementStatus(String entityId) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.statusOf(entityId);
  }

  /// true si une cutscene runtime est en cours d'exécution.
  bool get isCutsceneRunning => _cutsceneRunner.isRunning;

  /// Identifiant de la cutscene active, `null` si aucune.
  String? get activeCutsceneId => _cutsceneRunner.activeCutsceneId;

  /// Snapshot détaillé du runner cutscene.
  CutsceneRuntimeStatus get cutsceneStatus => _cutsceneRunner.status;

  /// Requête de choix en attente (si la cutscene attend une décision joueur).
  CutsceneChoiceRequest? get pendingCutsceneChoiceRequest =>
      _pendingCutsceneChoiceRequest;

  bool get hasPendingCutsceneChoice => _pendingCutsceneChoiceRequest != null;

  /// Dernier choix résolu pendant la cutscene active.
  CutsceneChoiceResult? get lastCutsceneChoiceResult =>
      _cutsceneRunner.lastChoiceResult;

  /// Démarre une cutscene fournie explicitement.
  ///
  /// Cette API est utile pour des déclenchements runtime directs (tests,
  /// scripts d'initialisation, futur bridge Step -> Cutscene).
  bool startCutscene(RuntimeCutsceneAsset cutscene) {
    return _tryStartCutscene(cutscene);
  }

  /// Démarre une cutscene depuis le registre runtime injecté au game host.
  ///
  /// Retourne `false` si l'ID est introuvable ou si une cutscene est déjà active.
  bool startCutsceneById(String cutsceneId) {
    if (!isLoaded) {
      return false;
    }
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final cutscene = _findRuntimeCutsceneById(normalized);
    if (cutscene == null) {
      return false;
    }
    return _tryStartCutscene(cutscene);
  }

  bool _tryStartCutscene(RuntimeCutsceneAsset cutscene) {
    if (!isLoaded ||
        _flowPhase != _RuntimeFlowPhase.overworld ||
        _cutsceneRunner.isRunning ||
        _hasCheckpointUnsafeRuntimeWorkForSave) {
      return false;
    }
    late final NarrativeRuntimeActivityLease lease;
    try {
      lease = _narrativeActivityGate.enter(
        NarrativeRuntimeActivity.sceneSuspended,
      );
    } on NarrativeRuntimeActivityBlockedException {
      return false;
    }
    _cutsceneActivityLease = lease;
    _pendingCutsceneChoiceRequest = null;
    try {
      final started = _cutsceneRunner.start(cutscene);
      _syncCutsceneLifecycle();
      return started;
    } catch (_) {
      _releaseCutsceneActivityLease();
      rethrow;
    }
  }

  /// Cancels the active runtime Cutscene and releases checkpoint authority.
  bool cancelCutscene() {
    final cancelled = _cutsceneRunner.cancel();
    _syncCutsceneLifecycle();
    return cancelled;
  }

  void _cancelCutsceneForLoad() {
    _cutsceneRunner.cancel(
      reason: 'Cutscene cancelled by checkpoint load.',
    );
    _syncCutsceneLifecycle();
  }

  void _syncCutsceneLifecycle() {
    _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    if (!_cutsceneRunner.isRunning) {
      _releaseCutsceneActivityLease();
    }
  }

  void _releaseCutsceneActivityLease() {
    _cutsceneActivityLease?.close();
    _cutsceneActivityLease = null;
  }

  bool resolvePendingCutsceneChoiceByIndex(int selectedIndex) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByIndex(selectedIndex);
    if (resolved) {
      _syncCutsceneLifecycle();
    }
    return resolved;
  }

  bool resolvePendingCutsceneChoiceByValue(String selectedValue) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByValue(selectedValue);
    if (resolved) {
      _syncCutsceneLifecycle();
    }
    return resolved;
  }

  void setBehaviorDebugOverlayVisible(bool visible) {
    _showBehaviorDebugOverlay = visible;
    if (!visible) {
      _behaviorDebugOverlay?.removeFromParent();
      _behaviorDebugOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureBehaviorDebugOverlay();
  }

  void setDebugTileMarker({
    required GridPos? position,
    String? label,
  }) {
    _debugTileMarkerPos = position;
    _debugTileMarkerLabel = label;
    if (!isLoaded) {
      return;
    }
    _applyDebugTileMarker();
  }

  @override
  void onRemove() {
    _isRemoved = true;
    if (!_onLoadInProgress) {
      _tilesetImageCache.dispose();
      _battleVisualAssetCache.dispose();
      _battleFxBundleCache.dispose();
    }
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    _onLoadInProgress = true;
    try {
      if (_isRemoved) return;
      if (initialMapActivationReason == MapActivationReason.saveRestore) {
        final restoredMapId = _gameState.currentMapId.trim();
        if (restoredMapId.isEmpty) {
          throw StateError(
            'An explicit saveRestore boot requires a non-empty saved map id.',
          );
        }
        if (restoredMapId != _bundle.map.id) {
          _bundle = await _loadRuntimeMapBundleCached(restoredMapId);
          if (_isRemoved) return;
        }
      }
      _bundle = await prepareBorderRuntimeBundle(_bundle);
      if (_isRemoved) return;
      _runtimeBundleByMapId[_bundle.map.id] = _bundle;
      final hydratedGameState =
          _hydrateOwnedPlayerPokemonProgression(_gameState);
      final rootBorderAssets = _loadBorderRuntimeAssets(_bundle);
      debugPrint(
          '[runtime_game] tileset image load start map=${_bundle.map.id}');
      final tilesetImages =
          _loadTilesetImagesCached(_bundle.tilesetAbsolutePathsById);
      final bootResources = await Future.wait<Object?>(
        <Future<Object?>>[
          hydratedGameState,
          rootBorderAssets,
          tilesetImages,
        ],
        eagerError: false,
      );
      _gameState = bootResources[0]! as GameState;
      final loadedRootBorderAssets =
          bootResources[1]! as BorderRuntimeAssetBundle;
      final images = bootResources[2]! as Map<String, RuntimeTilesetImage>;
      await afterInitialTilesetImagesLoaded?.call();
      if (_isRemoved) return;
      // The coordinator was constructed before asynchronous catalogue loading.
      // Publish the hydrated snapshot before any map-enter dispatch can observe
      // the game as playable.
      await _narrativeStateTransactions.transact<void>((_) {
        return NarrativeEventStateTransaction.commit(_gameState, null);
      });
      if (_isRemoved) return;
      final activation = _createMapActivation(
        mapId: _bundle.map.id,
        reason: initialMapActivationReason,
      );
      debugPrint(
        '[runtime_game] onLoad start map=${_bundle.map.id} projectFilePath=$projectFilePath tilesets=${_bundle.tilesetAbsolutePathsById.length}',
      );
      if (initialMapActivationReason == MapActivationReason.saveRestore) {
        if (!_isWithinMapBounds(_bundle.map, _gameState.playerPosition)) {
          throw StateError(
            'Saved player position is outside map "${_bundle.map.id}".',
          );
        }
        _world = GameplayWorldState.initial(
          map: _bundle.map,
          playerPos: _gameState.playerPosition,
          playerFacing: _gameState.playerFacing.asDirection,
          playerMovementMode: _gameState.playerMovementMode,
          project: _bundle.manifest,
          tileWidth: _bundle.manifest.settings.tileWidth,
          tileHeight: _bundle.manifest.settings.tileHeight,
          npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
          mapEntityPresencePredicate:
              _mapEntityPresencePredicateFor(_bundle.manifest),
        );
        debugPrint(
          '[runtime] Save restored on map ${_bundle.map.id} at '
          '(${_world.player.pos.x}, ${_world.player.pos.y})',
        );
      } else if (_isProjectNewGameBoot) {
        _world = GameplayWorldState.initial(
          map: _bundle.map,
          playerPos: _gameState.playerPosition,
          playerFacing: _gameState.playerFacing.asDirection,
          playerMovementMode: _gameState.playerMovementMode,
          project: _bundle.manifest,
          tileWidth: _bundle.manifest.settings.tileWidth,
          tileHeight: _bundle.manifest.settings.tileHeight,
          npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
          mapEntityPresencePredicate:
              _mapEntityPresencePredicateFor(_bundle.manifest),
        );
        debugPrint(
          '[runtime] New game created from project contract on '
          '${_bundle.map.id} at '
          '(${_world.player.pos.x}, ${_world.player.pos.y})',
        );
      } else {
        try {
          debugPrint('[runtime_game] world build start map=${_bundle.map.id}');
          _world = GameplayWorldState.fromMap(
            _bundle.map,
            project: _bundle.manifest,
            tileWidth: _bundle.manifest.settings.tileWidth,
            tileHeight: _bundle.manifest.settings.tileHeight,
            npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
            mapEntityPresencePredicate:
                _mapEntityPresencePredicateFor(_bundle.manifest),
          );
          debugPrint(
            '[runtime] Map loaded: ${_bundle.map.id}, spawn at (${_world.player.pos.x}, ${_world.player.pos.y})',
          );
        } on GameplaySpawnResolutionException catch (e) {
          debugPrint(
              '[runtime] Spawn resolution failed ($e), falling back to (0,0)');
          _world = GameplayWorldState.initial(
            map: _bundle.map,
            playerPos: const GridPos(x: 0, y: 0),
            project: _bundle.manifest,
            tileWidth: _bundle.manifest.settings.tileWidth,
            tileHeight: _bundle.manifest.settings.tileHeight,
            npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
            mapEntityPresencePredicate:
                _mapEntityPresencePredicateFor(_bundle.manifest),
          );
        }
      }
      debugPrint(
        '[runtime_game] tileset image load ok count=${images.length} map=${_bundle.map.id}',
      );
      _activeMapId = _bundle.map.id;
      debugPrint('[runtime_game] mount root map start map=$_activeMapId');
      final rootMap = await _mountLoadedMap(
        bundle: _bundle,
        tileImagesById: images,
        borderAssets: loadedRootBorderAssets,
        originCellX: 0,
        originCellY: 0,
      );
      if (_isRemoved) return;
      debugPrint('[runtime_game] mount root map ok map=$_activeMapId');
      final playerChar = _resolvePlayerCharacter(_bundle);
      _player = PlayerComponent(
        bundle: _bundle,
        state: _world.player,
        characterEntry: playerChar,
        tileImages: images,
        mapOrigin: _originPixelsOf(rootMap),
      );
      await world.add(_player);
      if (_isRemoved) return;
      _actorContactShadowRuntimeReady = true;
      _refreshActorContactShadowCollection();
      _syncGameStateFromWorld();
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _prewarmActiveMapWarpTargets();
      _prewarmActiveMapBattleData();
      _ensureBehaviorDebugOverlay();
      _ensureFpsOverlay();
      _applyDebugTileMarker();
      _resetScriptedNpcMovementController();
      _resetTriggerEnterOccupancy();
      _setFlowPhase(_RuntimeFlowPhase.overworld);
      _installMapActivation(activation);
      await super.onLoad();
      if (_isRemoved) return;
      _runDetachedNarrativeTask(
        operation: 'mapEnter.initialBoot',
        task: () async {
          await _dispatchCompletedMapActivation(activation);
        },
      );
      debugPrint('[runtime_game] onLoad completed activeMapId=$_activeMapId');
    } finally {
      _onLoadInProgress = false;
      if (_isRemoved) {
        _tilesetImageCache.dispose();
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final runtimeEvent = runtimeInputEventFromKeyEvent(event);
    if (runtimeEvent == null) {
      return KeyEventResult.ignored;
    }
    return handleRuntimeInputEvent(runtimeEvent)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  /// Point d'entrée public pour injecter des commandes runtime depuis une autre
  /// source que le clavier: boutons tactiles Flutter, bridge plateforme,
  /// remapping host, etc.
  ///
  /// Le contrat reste volontairement borné aux commandes réellement supportées
  /// par le runtime actuel. On ne transforme pas `PlayableMapGame` en système
  /// générique d'input; on donne juste un seam honnête pour ne plus dépendre
  /// directement des `LogicalKeyboardKey`.
  bool handleRuntimeInputEvent(RuntimeInputEvent event) {
    final control = event.control;

    // Menu/Start belongs to the shared player shell. A bare GameWidget (the
    // developer host) leaves it unhandled instead of opening product UI from
    // inside Flame.
    if (control == RuntimeInputControl.menu) {
      return false;
    }

    // Flutter overlays such as the pause menu sit outside Flame and therefore
    // cannot rely on focus alone: gamepad events are delivered directly by the
    // host. Consume every runtime command while one of those owners is active.
    if (_externalInputLocks.isNotEmpty) {
      if (_isMovementControl(control)) {
        _releaseMovementControl(control);
      }
      return true;
    }

    if (!isLoaded) {
      return false;
    }
    final inputAuthority = inputAuthoritySnapshot;

    if (inputAuthority.context == RuntimeInputContext.cinematic) {
      if (_isMovementControl(control)) {
        _releaseMovementControl(control);
      }
      if (event.isPress &&
          !event.isRepeat &&
          control == RuntimeInputControl.primary &&
          _cinematicRuntimeSink.signalDialogueLineComplete()) {
        _cinematicRuntimeController.update(Duration.zero);
      }
      return true;
    }

    if (inputAuthority.context == RuntimeInputContext.battle) {
      final postBattleOverlay = _postBattleProgressionOverlay;
      if (postBattleOverlay != null) {
        if (event.isPress && control == RuntimeInputControl.up) {
          postBattleOverlay.moveSelectionUp();
          return true;
        }
        if (event.isPress && control == RuntimeInputControl.down) {
          postBattleOverlay.moveSelectionDown();
          return true;
        }
        if (event.isPress && control == RuntimeInputControl.left) {
          postBattleOverlay.moveSelectionLeft();
          return true;
        }
        if (event.isPress && control == RuntimeInputControl.right) {
          postBattleOverlay.moveSelectionRight();
          return true;
        }
        if (event.isPress &&
            !event.isRepeat &&
            control == RuntimeInputControl.primary) {
          postBattleOverlay.validateSelectedChoice();
          return true;
        }
        // Le flux post-combat est modal : retour/annulation et relâchements
        // restent consommés jusqu'au commit ou à l'acquittement d'une erreur.
        return true;
      }
      if (_isPostBattleFlowRunning) {
        return true;
      }
      final overlay = _battleOverlay;
      if (overlay == null) {
        debugPrint('[battle] Runtime input but overlay is null!');
        return true;
      }
      if (event.isPress && control == RuntimeInputControl.up) {
        final changed = overlay.moveSelectionUp();
        debugPrint('[battle] Up pressed, selection changed=$changed');
        return true;
      }
      if (event.isPress && control == RuntimeInputControl.down) {
        final changed = overlay.moveSelectionDown();
        debugPrint('[battle] Down pressed, selection changed=$changed');
        return true;
      }
      if (event.isPress && control == RuntimeInputControl.left) {
        final changed = overlay.moveSelectionLeft();
        debugPrint('[battle] Left pressed, selection changed=$changed');
        return true;
      }
      if (event.isPress && control == RuntimeInputControl.right) {
        final changed = overlay.moveSelectionRight();
        debugPrint('[battle] Right pressed, selection changed=$changed');
        return true;
      }
      if (event.isPress &&
          !event.isRepeat &&
          control == RuntimeInputControl.primary) {
        if (_flowPhase != _RuntimeFlowPhase.battle || _battleOverlay == null) {
          debugPrint(
            '[battle] Validate input pressed but phase changed to $_flowPhase, IGNORING',
          );
          return true;
        }
        final selectedChoice = overlay.getSelectedChoice();
        debugPrint(
          '[battle] Validate input pressed, selectedChoice=$selectedChoice',
        );
        final validated = overlay.validateSelectedChoice();
        debugPrint('[battle] validateSelectedChoice returned=$validated');
        return true;
      }
      if (event.isPress &&
          !event.isRepeat &&
          control == RuntimeInputControl.secondary) {
        final handled = overlay.handleEscape();
        debugPrint('[battle] Secondary input pressed, handled=$handled');
        return true;
      }
      return true;
    }

    if (inputAuthority.context == RuntimeInputContext.blocked ||
        inputAuthority.context == RuntimeInputContext.transition) {
      if (_isMovementControl(control)) {
        _releaseMovementControl(control);
      }
      if (inputAuthority.context == RuntimeInputContext.blocked &&
          event.isPress &&
          _activeBlockingInteractionSerial != null) {
        debugPrint(
          '[scenario_lock] input blocked while pending source=${_activeBlockingInteractionSourceId ?? '-'}',
        );
      }
      return true;
    }

    if (_isMovementControl(control)) {
      if (inputAuthority.context == RuntimeInputContext.dialogue) {
        _releaseMovementControl(control);
        if ((_dialogueOverlay?.isShowingChoices ?? false) && event.isPress) {
          if (control == RuntimeInputControl.up) {
            _moveChoiceCursor(-1);
          } else if (control == RuntimeInputControl.down) {
            _moveChoiceCursor(1);
          }
        }
        return true;
      }
      if (inputAuthority.context != RuntimeInputContext.overworld) {
        _releaseMovementControl(control);
        return true;
      }
      if (event.isPress) {
        _pressMovementControl(control);
      } else if (event.isRelease) {
        _releaseMovementControl(control);
      }
      return true;
    }

    if (inputAuthority.context == RuntimeInputContext.dialogue) {
      final overlay = _dialogueOverlay;
      if (overlay == null || !event.isPress || event.isRepeat) {
        return true;
      }
      if (overlay.isShowingChoices) {
        if (control == RuntimeInputControl.primary) {
          _confirmDialogueChoice();
          return true;
        }
      } else {
        if (control == RuntimeInputControl.primary) {
          _advanceDialogue();
          return true;
        }
      }
      return true;
    }

    if (inputAuthority.context != RuntimeInputContext.overworld) {
      return true;
    }
    if (!event.isPress || event.isRepeat) {
      return false;
    }

    if (control == RuntimeInputControl.primary) {
      _handleInteract();
      return true;
    }

    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateFps(dt);
    _runtimeClockMs += dt * 1000;
    _placedBehaviorCooldownGate.prune(nowMs: _runtimeClockMs);
    _updateActorDepthOrdering();
    _refreshActorContactShadowCollection();
    final pendingConnectionEntryAnimation = _pendingConnectionEntryAnimation;
    if (pendingConnectionEntryAnimation != null &&
        pendingConnectionEntryAnimation.holdInitialCameraFrame) {
      _setCameraWorldTopLeft(
        pendingConnectionEntryAnimation.initialCameraWorldTopLeft,
      );
      pendingConnectionEntryAnimation.holdInitialCameraFrame = false;
    } else if (!_cinematicRuntimeController.isPlaying) {
      _syncCameraToPlayer();
    }
    if (_cinematicRuntimeController.isPlaying) {
      _cinematicRuntimeController.update(
        Duration(
          microseconds: math.max(
            0,
            (dt * Duration.microsecondsPerSecond).round(),
          ),
        ),
      );
    }
    _syncViewportCullingRects();
    _syncNpcCollisionDebugOverlay();

    if (_cinematicRuntimeController.isPlaying) {
      _clearPressedMovementControls();
      return;
    }

    if (_flowPhase == _RuntimeFlowPhase.mapTransition) {
      if (_narrativeActivityGate.checkpointInProgress) {
        return;
      }
      if (pendingConnectionEntryAnimation != null && !_player.isStepping) {
        _pendingConnectionEntryAnimation = null;
        _setFlowPhase(_RuntimeFlowPhase.overworld);
        _resetTriggerEnterOccupancy();
        debugPrint(
          '[connection] transition complete -> map=${pendingConnectionEntryAnimation.mapId} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
        );
        _installMapActivation(pendingConnectionEntryAnimation.activation);
        _runDetachedNarrativeTask(
          operation: 'mapEnter.connection',
          task: () async {
            await _dispatchCompletedMapActivation(
              pendingConnectionEntryAnimation.activation,
            );
          },
        );
      }
      return;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }

    final mapActivationWorkLocked = _blocksOverworldForMapActivationWork;
    final narrativeDispatchLocked = _blocksOverworldForNarrativeDispatch;
    final checkpointLocked = _narrativeActivityGate.checkpointInProgress;
    final blocksNewOverworldLaunch =
        mapActivationWorkLocked || narrativeDispatchLocked || checkpointLocked;
    if (!blocksNewOverworldLaunch && _startNarrativeTriggerQueueDrain()) {
      _clearPressedMovementControls();
      return;
    }
    final pendingWarp = _pendingWarp;
    final pendingWarpOwner = _pendingScenarioWarpHandoff;
    final restoreFenceOwnsPendingWarp = pendingWarpOwner != null &&
        pendingWarpOwner.matches(pendingWarp) &&
        !checkpointLocked &&
        _restoreFenceOwnsSource(pendingWarpOwner.runtimeSourceId);
    if ((!blocksNewOverworldLaunch || restoreFenceOwnsPendingWarp) &&
        pendingWarp != null &&
        !_player.isStepping) {
      _pendingWarp = null;
      final scenarioOwner = _pendingScenarioWarpHandoff;
      final matchingOwner =
          scenarioOwner?.matches(pendingWarp) == true ? scenarioOwner : null;
      if (scenarioOwner != null && matchingOwner == null) {
        _pendingScenarioWarpHandoff = null;
        _cancelNarrativeContinuationBarrier(
          scenarioOwner.runtimeSourceId,
        );
      }
      final warp = _handleWarp(
        pendingWarp,
        allowMapActivationWork:
            _restoreFenceOwnsSource(matchingOwner?.runtimeSourceId),
      );
      if (matchingOwner == null) {
        _runDetachedNarrativeTask(
          operation: 'mapEnter.physicalWarp',
          task: () => warp,
        );
      } else {
        unawaited(
          () async {
            try {
              await warp;
            } catch (error, stackTrace) {
              debugPrint(
                '[scenario_runtime] owned warp handoff failed '
                'source=${matchingOwner.runtimeSourceId} '
                'error=$error\n$stackTrace',
              );
              if (identical(_pendingScenarioWarpHandoff, matchingOwner)) {
                _pendingScenarioWarpHandoff = null;
              }
              _syncGameStateFromWorld(mapIdOverride: _activeMapId);
              _cancelOwnedScenarioWarpContinuation(matchingOwner);
              return;
            }
            if (identical(_pendingScenarioWarpHandoff, matchingOwner)) {
              _pendingScenarioWarpHandoff = null;
            }
            final completed = _activeMapId == pendingWarp.targetMapId &&
                _world.player.pos == pendingWarp.targetPos;
            if (completed) {
              _completeOwnedScenarioWarpContinuation(matchingOwner);
            } else {
              debugPrint(
                '[scenario_runtime] owned warp handoff canceled '
                'source=${matchingOwner.runtimeSourceId} '
                'expectedMap=${pendingWarp.targetMapId} '
                'actualMap=$_activeMapId '
                'expectedPos=(${pendingWarp.targetPos.x},${pendingWarp.targetPos.y}) '
                'actualPos=(${_world.player.pos.x},${_world.player.pos.y})',
              );
              _syncGameStateFromWorld(mapIdOverride: _activeMapId);
              _cancelOwnedScenarioWarpContinuation(matchingOwner);
            }
          }(),
        );
      }
      return;
    }

    if (!blocksNewOverworldLaunch) {
      final pendingConnection = _pendingConnection;
      if (pendingConnection != null && !_player.isStepping) {
        _pendingConnection = null;
        _handleConnection(pendingConnection);
        return;
      }
    }

    final pendingBattleRequest = _pendingBattleRequest;
    final pendingBattleOwner = _pendingScenarioBattleHandoff;
    final restoreFenceOwnsPendingBattle = pendingBattleOwner != null &&
        pendingBattleOwner.requestId == pendingBattleRequest?.requestId &&
        !checkpointLocked &&
        _restoreFenceOwnsSource(pendingBattleOwner.runtimeSourceId);
    if ((!blocksNewOverworldLaunch || restoreFenceOwnsPendingBattle) &&
        pendingBattleRequest != null &&
        !_player.isStepping) {
      _pendingBattleRequest = null;
      _startBattleHandoff(pendingBattleRequest);
      return;
    }

    if (!blocksNewOverworldLaunch) {
      final pendingPlacedElementBehavior = _pendingPlacedElementBehavior;
      if (pendingPlacedElementBehavior != null && !_player.isStepping) {
        _pendingPlacedElementBehavior = null;
        _executePlacedElementBehavior(
          element: pendingPlacedElementBehavior.element,
          behavior: pendingPlacedElementBehavior.behavior,
          trigger: pendingPlacedElementBehavior.trigger,
        );
        return;
      }
    }

    // Tick du système de déplacement scripté PNJ.
    //
    // Ce tick reste dans le flux overworld pour ce MVP:
    // - pas d'exécution pendant dialogue/battle transition;
    // - base propre pour un futur "wait movement" en cutscene.
    if (!blocksNewOverworldLaunch) {
      _scriptedEntityMovementController?.update(dt);
      _processPendingSceneNpcMoves();
      _processPendingScenarioNpcWarpEntries();
      _processPendingScenarioMoveContinuations();
      _processPendingScenarioFollowRequest();
      _processPendingScenarioTransitionMapRequest();
      _processPendingScenarioReachedEndCompletions();
    } else {
      _PendingScenarioMoveContinuation? restoreOwnedMove;
      for (final pending in _pendingScenarioMoveContinuationsByEntity.values) {
        if (_restoreFenceOwnsSource(pending.runtimeSourceId)) {
          restoreOwnedMove = pending;
          break;
        }
      }
      if (restoreOwnedMove != null) {
        _scriptedEntityMovementController?.updateOwnedMove(
          dt,
          restoreOwnedMove.entityId,
        );
        _processPendingScenarioNpcWarpEntries(
          onlyEntityId: restoreOwnedMove.entityId,
        );
        _processPendingScenarioMoveContinuations(
          onlyEntityId: restoreOwnedMove.entityId,
        );
      }
    }

    // Tick runner cutscene MVP (séquentiel).
    if (!blocksNewOverworldLaunch) {
      _cutsceneRunner.update(dt);
    }
    _syncCutsceneLifecycle();
    if (isCutsceneRunning) {
      // Tant que la cutscene n'est pas terminée, on ne laisse pas la boucle
      // input joueur déplacer le player.
      return;
    }

    if (!inputAuthoritySnapshot.acceptsOverworldInput) {
      _clearPressedMovementControls();
      return;
    }

    _driveMovement();
  }

  void _updateActorDepthOrdering() {
    _player.priority = 1000 + _player.footPoint.y.round();
    for (final actor in _npcActors) {
      actor.priority = 1000 + actor.depthSortY.round();
    }
  }

  ShadowRuntimeInstructionCollectionProvider? _shadowCollectionProviderForMap(
    String mapId,
  ) {
    final externalProvider = shadowCollectionProvider;
    if (externalProvider != null) {
      return externalProvider;
    }
    if (!enableActorContactShadows && !enableStaticPlacedElementShadows) {
      return null;
    }
    return () => _provideShadowCollectionForMap(mapId);
  }

  ShadowRuntimeInstructionCollection? _provideShadowCollectionForMap(
    String mapId,
  ) {
    // Appelé depuis render() à chaque frame : la fusion (plusieurs copies de
    // listes) ne doit se refaire que quand une des collections sources change.
    // Les trois sources sont immuables et remplacées par identité, donc un
    // simple test d'identité suffit à valider le cache — y compris après un
    // changement de carte active (l'entrée actor devient null/non-null).
    ShadowRuntimeInstructionCollection? projected;
    ShadowRuntimeInstructionCollection? staticCollection;
    if (enableStaticPlacedElementShadows) {
      projected = _projectedBuildingShadowCollectionByMapId[mapId];
      staticCollection = _staticShadowCollectionByMapId[mapId];
    }
    ShadowRuntimeInstructionCollection? actorCollection;
    if (enableActorContactShadows && mapId == _activeMapId) {
      actorCollection = _actorShadowCollectionController.provide();
    }
    final cached = _mergedShadowCollectionCacheByMapId[mapId];
    if (cached != null &&
        identical(cached.projected, projected) &&
        identical(cached.staticCollection, staticCollection) &&
        identical(cached.actorCollection, actorCollection)) {
      return cached.merged;
    }
    final collections = <ShadowRuntimeInstructionCollection>[
      if (projected != null && projected.isNotEmpty) projected,
      if (staticCollection != null && staticCollection.isNotEmpty)
        staticCollection,
      if (actorCollection != null && actorCollection.isNotEmpty)
        actorCollection,
    ];
    final merged = switch (collections.length) {
      0 => null,
      1 => collections.first,
      _ => mergeShadowRuntimeInstructionCollections(collections),
    };
    _mergedShadowCollectionCacheByMapId[mapId] = _MergedShadowCollectionCache(
      projected: projected,
      staticCollection: staticCollection,
      actorCollection: actorCollection,
      merged: merged,
    );
    return merged;
  }

  void _refreshActorContactShadowCollection() {
    if (shadowCollectionProvider != null ||
        !enableActorContactShadows ||
        !_actorContactShadowRuntimeReady) {
      _actorShadowCollectionController.clear();
      _lastActorShadowSources = null;
      return;
    }
    final sources = _actorContactShadowSources();
    // Skip rebuild si les sources n'ont pas changé.
    final prev = _lastActorShadowSources;
    if (prev != null && _shadowSourcesEqual(prev, sources)) {
      return;
    }
    _lastActorShadowSources = sources;
    _actorShadowCollectionController.replace(
      buildRuntimeActorContactShadowCollection(sources: sources),
    );
  }

  static bool _shadowSourcesEqual(
    List<RuntimeActorContactShadowSource> a,
    List<RuntimeActorContactShadowSource> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _refreshProjectedBuildingShadowCollection(RuntimeMapBundle bundle) {
    if (shadowCollectionProvider != null || !enableStaticPlacedElementShadows) {
      _projectedBuildingShadowCollectionByMapId.remove(bundle.map.id);
      return;
    }
    final collection = buildRuntimeProjectedBuildingShadowCollection(
      manifest: bundle.manifest,
      mapData: bundle.map,
    );
    if (collection.isEmpty) {
      _projectedBuildingShadowCollectionByMapId.remove(bundle.map.id);
      return;
    }
    _projectedBuildingShadowCollectionByMapId[bundle.map.id] = collection;
  }

  void _refreshStaticPlacedElementShadowCollection(RuntimeMapBundle bundle) {
    if (shadowCollectionProvider != null || !enableStaticPlacedElementShadows) {
      _staticShadowCollectionByMapId.remove(bundle.map.id);
      return;
    }
    final collection = buildRuntimeStaticPlacedElementShadowCollectionForBundle(
      bundle: bundle,
    );
    if (collection.isEmpty) {
      _staticShadowCollectionByMapId.remove(bundle.map.id);
      return;
    }
    _staticShadowCollectionByMapId[bundle.map.id] = collection;
  }

  List<RuntimeActorContactShadowSource> _actorContactShadowSources() {
    final activeMap = _loadedMapsById[_activeMapId];
    final activeMapOrigin =
        activeMap == null ? Vector2.zero() : _originPixelsOf(activeMap);
    final sources = <RuntimeActorContactShadowSource>[
      RuntimeActorContactShadowSource(
        id: 'player',
        footWorldX: _player.footPoint.x - activeMapOrigin.x,
        footWorldY: _player.footPoint.y - activeMapOrigin.y,
        visualWidth: _player.visualSize.x,
        visualHeight: _player.visualSize.y,
        isVisible: _player.parent != null,
      ),
    ];
    if (activeMap != null) {
      for (final actor in activeMap.npcActors) {
        sources.add(
          RuntimeActorContactShadowSource(
            id: actor.character.id,
            footWorldX: actor.position.x + actor.size.x / 2 - activeMapOrigin.x,
            footWorldY: actor.depthSortY - activeMapOrigin.y,
            visualWidth: actor.size.x,
            visualHeight: actor.size.y,
            isVisible: actor.parent != null && actor.isGameplayPresent,
          ),
        );
      }
    }
    return sources;
  }

  bool _isMovementControl(RuntimeInputControl control) {
    return control == RuntimeInputControl.up ||
        control == RuntimeInputControl.down ||
        control == RuntimeInputControl.left ||
        control == RuntimeInputControl.right;
  }

  Direction? _directionForControl(RuntimeInputControl control) {
    switch (control) {
      case RuntimeInputControl.up:
        return Direction.north;
      case RuntimeInputControl.down:
        return Direction.south;
      case RuntimeInputControl.left:
        return Direction.west;
      case RuntimeInputControl.right:
        return Direction.east;
      case RuntimeInputControl.primary:
      case RuntimeInputControl.secondary:
      case RuntimeInputControl.menu:
        return null;
    }
  }

  void _pressMovementControl(RuntimeInputControl control) {
    if (!_isMovementControl(control)) {
      return;
    }
    _pressedMovementControls.add(control);
    _lastMovementControl = control;
  }

  void _releaseMovementControl(RuntimeInputControl control) {
    if (!_isMovementControl(control)) {
      return;
    }
    _pressedMovementControls.remove(control);
    if (_lastMovementControl == control) {
      _lastMovementControl = null;
    }
  }

  GameplayIntent? _intentFromPressedMovementControls() {
    final preferred = _lastMovementControl;
    if (preferred != null && _pressedMovementControls.contains(preferred)) {
      final direction = _directionForControl(preferred);
      if (direction != null) {
        return MoveIntent(
          direction,
          pixelsPerStep: _playerStepPixels(direction),
        );
      }
    }

    for (final control in _pressedMovementControls) {
      final direction = _directionForControl(control);
      if (direction != null) {
        return MoveIntent(
          direction,
          pixelsPerStep: _playerStepPixels(direction),
        );
      }
    }
    return null;
  }

  int _playerStepPixels(Direction direction) {
    final raw = switch (direction) {
      Direction.east || Direction.west => _world.tileWidthPx,
      Direction.north || Direction.south => _world.tileHeightPx,
    };
    return math.max(1, raw);
  }

  MoveIntent _fullTileMoveIntent(Direction direction) {
    return MoveIntent(
      direction,
      pixelsPerStep: _playerStepPixels(direction),
    );
  }

  void _driveMovement() {
    if (_suppressOverworldInputForScriptedPlayerMovement()) {
      _clearPressedMovementControls();
      return;
    }
    if (_player.isStepping) {
      return;
    }

    final intent = _intentFromPressedMovementControls();
    if (intent == null) {
      _player.syncState(_world.player);
      return;
    }
    final attemptedDirection = intent is MoveIntent ? intent.direction : null;
    final attemptedX = attemptedDirection == null
        ? null
        : _world.player.pos.x + attemptedDirection.dx;
    final attemptedY = attemptedDirection == null
        ? null
        : _world.player.pos.y + attemptedDirection.dy;
    final attemptedOutOfBounds = attemptedX != null &&
        attemptedY != null &&
        (attemptedX < 0 ||
            attemptedY < 0 ||
            attemptedX >= _world.map.size.width ||
            attemptedY >= _world.map.size.height);

    // Collision runtime stricte contre les destinations PNJ réservées.
    //
    // Sans ce garde-fou, un joueur peut entrer dans la case cible d'un PNJ en
    // interpolation (avant commit canonique), créant un effet de traversée.
    if (attemptedDirection != null &&
        attemptedX != null &&
        attemptedY != null &&
        _isCellReservedByScriptedNpc(
          GridPos(x: attemptedX, y: attemptedY),
        )) {
      _world =
          _world.withPlayer(_world.player.copyWith(facing: attemptedDirection));
      _player.syncState(_world.player);
      return;
    }

    final previousPlayerPos = _world.player.pos;
    final result = stepGameplayWorld(_world, intent);
    _world = result.world;
    _syncGameStateFromWorld();

    if (result is Blocked) {
      if (result.reason == GameplayMovementBlockReason.waterRequiresSurf) {
        _handleWaterBlocked();
      }
      if (attemptedOutOfBounds && attemptedDirection != null) {
        final direction = switch (attemptedDirection) {
          Direction.north => MapConnectionDirection.north,
          Direction.south => MapConnectionDirection.south,
          Direction.east => MapConnectionDirection.east,
          Direction.west => MapConnectionDirection.west,
        };
        debugPrint(
          '[connection] no connection for direction=${direction.name} map=${_bundle.map.id}',
        );
      }
      _player.syncState(_world.player);
      return;
    }

    if (result is Moved) {
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _checkStepEncounter();
      _checkTrainerLineOfSight(); // Check LoS only when player position changes
      _dispatchScenarioTriggerEnterFromMovement(
        previousPos: previousPlayerPos,
        currentPos: _world.player.pos,
      );
      return;
    }

    if (result is WarpTriggered) {
      _dispatchScenarioTriggerEnterFromMovement(
        previousPos: previousPlayerPos,
        currentPos: _world.player.pos,
      );
      if (result.warp.triggerMode == MapWarpTriggerMode.onEnter) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player, snapToGrid: true);
      }
      if (!_tryEnqueueWarp(result.warp)) {
        debugPrint(
          '[warp] physical warp rejected because another owned warp handoff '
          'is pending: ${result.warp.warpId}',
        );
        return;
      }
      debugPrint(
        '[warp] Triggered warp ${result.warp.warpId} mode=${result.warp.triggerMode.name} -> map=${result.warp.targetMapId} pos=(${result.warp.targetPos.x}, ${result.warp.targetPos.y})',
      );
      return;
    }

    if (result is ConnectionTriggered) {
      _player.syncState(_world.player);
      _pendingConnection = result.connection;
      debugPrint(
        '[connection] exit detected map=${_bundle.map.id} direction=${result.connection.direction.name} target=${result.connection.targetMapId} offset=${result.connection.offset} source=(${result.connection.sourcePos.x}, ${result.connection.sourcePos.y})',
      );
      return;
    }

    if (result is PlacedElementInteracted) {
      if (_world.player.pos != previousPlayerPos) {
        _dispatchScenarioTriggerEnterFromMovement(
          previousPos: previousPlayerPos,
          currentPos: _world.player.pos,
        );
      }
      final isMovementTrigger =
          result.trigger == MapPlacedElementTriggerType.onEnter ||
              result.trigger == MapPlacedElementTriggerType.onExit ||
              result.trigger == MapPlacedElementTriggerType.onNear;
      if (isMovementTrigger) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player);
      }
      _pendingPlacedElementBehavior = result;
      final behaviorId = result.behavior.id.trim().isEmpty
          ? 'legacy'
          : result.behavior.id.trim();
      debugPrint(
        '[placed_behavior] queued trigger=${result.trigger.name} scope=${result.behavior.triggerScope.name} instance=${result.element.id} behavior=$behaviorId effect=${result.behavior.effect.type.name}',
      );
      _updateBehaviorDebugLine(
        'Queued ${result.trigger.name}/${result.behavior.triggerScope.name} · ${result.behavior.effect.type.name} · ${result.element.id}#$behaviorId',
      );
      return;
    }
  }

  void _checkStepEncounter() {
    final encounterKind = _world.player.movementMode == MovementMode.surf
        ? EncounterKind.surf
        : EncounterKind.walk;
    final pos = _world.player.pos;
    final marker = _EncounterCheckMarker(
      mapId: _activeMapId,
      pos: pos,
      kind: encounterKind,
    );
    if (_lastEncounterCheckMarker == marker) {
      return;
    }
    _lastEncounterCheckMarker = marker;
    _debugEncounterCheckCount += 1;
    if (_kVerboseEncounterLogs) {
      debugPrint(
        '[encounter] checking at x=${pos.x} y=${pos.y} kind=${encounterKind.name}',
      );
    }
    final check = checkEncounterAtPlayerPosition(
      world: _world,
      project: _bundle.manifest,
      encounterKind: encounterKind,
      gameState: _gameState,
      random: _encounterRandom,
    );
    _logEncounterCheck(check);
    if (!check.triggered) {
      return;
    }
    final encounter = check.encounter;
    if (encounter == null) {
      return;
    }
    final request = buildBattleStartRequestFromEncounter(
      encounter: encounter,
      world: _world,
    );
    if (!_tryEnqueueBattleRequest(request)) {
      debugPrint(
        '[battle] wild request rejected: another Battle handoff is pending',
      );
      return;
    }
    debugPrint(
      '[battle] battle request created kind=${request.kind.name} source=${request.source.name} requestId=${request.requestId}',
    );
    debugPrint(
      '[battle] wild payload species=${encounter.speciesId} level=${encounter.level} map=${encounter.mapId} zone=${encounter.zoneId}',
    );
  }

  /// Détecte les entrées dans des triggers de map pour alimenter les sources
  /// scénario `sourceTriggerEnter`.
  ///
  /// Le calcul est local et déterministe:
  /// - on lit les triggers couvrant l'ancienne position,
  /// - on lit les triggers couvrant la nouvelle position,
  /// - on déclenche uniquement les IDs présents dans "nouvelle - ancienne".
  void _resetTriggerEnterOccupancy() {
    _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: _world.player.pos,
    );
    _activeNarrativeTriggerIds = resolveNarrativeTriggerEnterFronts(
      map: _bundle.map,
      currentPosition: _world.player.pos,
      previousOccupiedTriggerIds: null,
    ).currentOccupiedTriggerIds;
    _pendingNarrativeTriggerEntries.clear();
  }

  void _dispatchScenarioTriggerEnterFromMovement({
    required GridPos previousPos,
    required GridPos currentPos,
  }) {
    // On privilégie l'état mémorisé pour éviter de recalculer l'ancienne
    // couverture à chaque tick. Un fallback de sécurité reste possible.
    final previousIds = _activeScenarioTriggerIds.isEmpty
        ? _scenarioRuntime.triggerIdsAtPosition(
            map: _bundle.map,
            pos: previousPos,
          )
        : _activeScenarioTriggerIds;
    final currentIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: currentPos,
    );
    _activeScenarioTriggerIds = currentIds;
    final enteredIds =
        currentIds.difference(previousIds).toList(growable: false)..sort();
    for (final triggerId in enteredIds) {
      MapTrigger? trigger;
      for (final candidate in _bundle.map.triggers) {
        if (candidate.id == triggerId) {
          trigger = candidate;
          break;
        }
      }
      if (trigger != null &&
          (trigger.type == TriggerType.event ||
              trigger.type == TriggerType.custom)) {
        continue;
      }
      _dispatchScenarioRuntimeSource(
        ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: _activeMapId,
          triggerId: triggerId,
        ),
      );
    }

    final narrativeFronts = resolveNarrativeTriggerEnterFronts(
      map: _bundle.map,
      currentPosition: currentPos,
      previousOccupiedTriggerIds: _activeNarrativeTriggerIds,
    );
    _activeNarrativeTriggerIds = narrativeFronts.currentOccupiedTriggerIds;
    for (final triggerId in narrativeFronts.enteredTriggerIds) {
      _pendingNarrativeTriggerEntries.add(
        _PendingNarrativeTriggerEntry(
          activationId: _currentMapActivationId,
          mapId: _activeMapId,
          triggerId: triggerId,
        ),
      );
    }
  }

  bool _startNarrativeTriggerQueueDrain() {
    if (_isNarrativeTriggerQueueDraining ||
        _inFlightSpatialDispatchCount > 0 ||
        _narrativeActivityGate.checkpointInProgress ||
        _pendingNarrativeTriggerEntries.isEmpty) {
      return false;
    }
    _isNarrativeTriggerQueueDraining = true;
    _runDetachedNarrativeTask(
      operation: 'triggerEnter.queue',
      task: _drainNarrativeTriggerQueue,
    );
    return true;
  }

  Future<void> _drainNarrativeTriggerQueue() async {
    try {
      while (_pendingNarrativeTriggerEntries.isNotEmpty &&
          _flowPhase == _RuntimeFlowPhase.overworld) {
        final entry = _pendingNarrativeTriggerEntries.removeAt(0);
        if (entry.activationId != _currentMapActivationId ||
            entry.mapId != _activeMapId) {
          continue;
        }
        final result = await _dispatchSpatialOccurrence(
          occurrence: NarrativeEventOccurrence(
            source: NarrativeEventSourceRef.triggerEnter(
              entry.mapId,
              entry.triggerId,
            ),
          ),
          legacyFallback: (_) async {
            _dispatchScenarioRuntimeSource(
              ScenarioRuntimeSourceEvent.triggerEnter(
                mapId: entry.mapId,
                triggerId: entry.triggerId,
              ),
            );
          },
        );
        if (result is NarrativeSpatialProductionDispatchFailed &&
            result.failure is NarrativeRuntimeActivityBlockedException) {
          if (entry.activationId == _currentMapActivationId &&
              entry.mapId == _activeMapId) {
            _pendingNarrativeTriggerEntries.insert(0, entry);
          }
          break;
        }
      }
    } finally {
      _isNarrativeTriggerQueueDraining = false;
    }
  }

  /// Point d'entrée unique pour les déclenchements runtime du Scenario Graph.
  ///
  /// Cette méthode centralise:
  /// - le guard de phase (overworld/script actif),
  /// - l'appel à l'exécuteur scénario,
  /// - le branchement vers les effets runtime (dialogue/script/message),
  /// - la synchronisation de GameState lorsque le flow mutera des flags.
  ScenarioRuntimeExecutionResult _dispatchScenarioRuntimeSource(
    ScenarioRuntimeSourceEvent sourceEvent, {
    List<NarrativeOutcomeRef>? deferredOutcomes,
  }) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: flow is not in overworld phase.',
      );
    }
    final activeScript = _activeScriptController;
    if (activeScript != null && !activeScript.isTerminated) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: a script is already running.',
      );
    }
    final scenarios = _bundle.manifest.scenarios;
    if (scenarios.isEmpty) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'No scenario available in current manifest.',
      );
    }

    late final NarrativeRuntimeActivityLease sceneLease;
    try {
      // Acquire before building the callback context: every legacy Scenario
      // callback may mutate the live facade and therefore belongs inside the
      // same checkpoint exclusion boundary as a V2 Scene execution.
      sceneLease =
          _narrativeActivityGate.enter(NarrativeRuntimeActivity.sceneActive);
    } on NarrativeRuntimeActivityBlockedException {
      debugPrint(
        '[scenario_runtime] blocked by checkpoint '
        'source=${sourceEvent.type.name}',
      );
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.blocked,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Blocked: a checkpoint is in progress.',
      );
    }

    try {
      final activeCollector = _activeLegacyScenarioOutcomeCollector;
      final outcomes =
          deferredOutcomes ?? activeCollector ?? <NarrativeOutcomeRef>[];
      final publishesOwnOutcomes =
          deferredOutcomes == null && activeCollector == null;
      final result = _scenarioRuntime.dispatch(
        scenarios: scenarios,
        sourceEvent: sourceEvent,
        context: _buildScenarioRuntimeExecutionContext(outcomes),
      );

      // Step Studio : on ne complète pas sur "flow reached end" uniquement.
      // La completion est validée quand les effets runtime visibles sont terminés.
      _handleScenarioRuntimeCompletionResult(
        result,
        origin: 'dispatch:${sourceEvent.type.name}',
      );

      // On maintient une trace explicite en logs pour faciliter le debug.
      if (result.status == ScenarioRuntimeExecutionStatus.noMatchingSource) {
        return result;
      }
      debugPrint(
        '[scenario_runtime] source=${sourceEvent.type.name} map=${sourceEvent.mapId} trigger=${sourceEvent.triggerId ?? '-'} entity=${sourceEvent.entityId ?? '-'} status=${result.status.name} scenario=${result.scenarioId ?? '-'} sourceNode=${result.sourceNodeId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
      );

      // [SEL-B2] Si l'effet est un combat, on lance le battle handoff et on
      // suspend le graphe. La reprise viendra de _onBattleFinished.
      final battleHandoffReady =
          result.effect.type != ScenarioRuntimeEffectType.battle ||
              _handleScenarioBattleEffect(result);
      final continuationBarrier = battleHandoffReady
          ? _registerNarrativeContinuationBarrier(result)
          : null;

      if (publishesOwnOutcomes && outcomes.isNotEmpty) {
        _scheduleNarrativeOutcomesPublication(
          outcomes,
          continuation: continuationBarrier?.continuation,
        );
      }

      return result;
    } finally {
      sceneLease.close();
    }
  }

  /// Contexte partagé dispatch / continuation : inclut le filtre Step Studio
  /// pour ne pas relancer une cutscene locale dont la step est déjà complétée.
  ScenarioRuntimeExecutionContext _buildScenarioRuntimeExecutionContext(
    List<NarrativeOutcomeRef> deferredOutcomes,
  ) {
    return ScenarioRuntimeExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      shouldSkipScenario: _shouldSkipLocalScenarioForCompletedStep,
      deferOutcomeDispatch: true,
      onOutcomeEmitted: ({required scenarioId, required outcomeId}) {
        deferredOutcomes.add(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.legacyScenario,
            producerId: scenarioId,
            outcomeId: outcomeId,
          ),
        );
      },
      openDialogue: _openScenarioDialogueById,
      runScript: _runScenarioScriptById,
      showMessage: (message) => _showNotification(message),
      moveCharacter: ({
        required entityId,
        required targetKind,
        required targetId,
        required waitForCompletion,
        runtimeSourceId,
      }) {
        return _runScenarioMoveCharacter(
          entityId: entityId,
          targetKind: targetKind,
          targetId: targetId,
          waitForCompletion: waitForCompletion,
          runtimeSourceId: runtimeSourceId,
        );
      },
      followCharacter: ({
        required leaderEntityId,
      }) {
        return _runScenarioFollowCharacter(leaderEntityId: leaderEntityId);
      },
      faceCharacter: ({
        required entityId,
        required direction,
      }) {
        return _runScenarioFaceCharacter(
          entityId: entityId,
          direction: direction,
        );
      },
      transitionMap: ({
        required mapId,
        required warpId,
      }) {
        return _runScenarioTransitionMap(
          mapId: mapId,
          warpId: warpId,
        );
      },
    );
  }

  /// Index Step Studio mis en cache tant que le bundle courant est inchangé
  /// (évite de re-parser le JSON à chaque déclencheur).
  StepCompletionCutsceneIndex _stepCompletionIndexForCurrentBundle() {
    if (!identical(_cachedStepCompletionBundleForIndex, _bundle)) {
      _cachedStepCompletionBundleForIndex = _bundle;
      _cachedStepCompletionIndex =
          buildStepCompletionCutsceneIndex(_bundle.manifest.scenarios);
    }
    return _cachedStepCompletionIndex!;
  }

  /// Si la cutscene [scenarioId] est la condition de fin d’une step déjà
  /// enregistrée dans [PlayerProgression.completedStepIds], on ignore ce
  /// scénario pour permettre à un autre candidat de matcher (ou aucun).
  bool _shouldSkipLocalScenarioForCompletedStep(String scenarioId) {
    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId == null) {
      return false;
    }
    return _gameState.progression.completedStepIds.contains(stepId);
  }

  /// Capture un résultat scénario et décide si la completion doit être :
  /// - appliquée immédiatement;
  /// - ou différée jusqu'à la fin réelle des effets runtime visibles.
  void _handleScenarioRuntimeCompletionResult(
    ScenarioRuntimeExecutionResult result, {
    required String origin,
  }) {
    if (result.status != ScenarioRuntimeExecutionStatus.reachedEnd) {
      return;
    }
    final scenarioId = result.scenarioId?.trim();
    if (scenarioId == null || scenarioId.isEmpty) {
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason == null) {
      _applyScenarioReachedEndCompletion(
          scenarioId: scenarioId, origin: origin);
      return;
    }
    for (final pending in _pendingScenarioReachedEndQueue) {
      if (pending.scenarioId == scenarioId) {
        debugPrint(
          '[step_studio_trace] completion_deferred_duplicate scenario=$scenarioId origin=$origin reason="$blockingReason"',
        );
        return;
      }
    }
    _pendingScenarioReachedEndQueue.add(
      _PendingScenarioReachedEnd(
        scenarioId: scenarioId,
        origin: origin,
        queuedAtMs: _runtimeClockMs,
      ),
    );
    debugPrint(
      '[step_studio_trace] completion_deferred scenario=$scenarioId origin=$origin reason="$blockingReason"',
    );
  }

  /// Applique réellement la completion progression pour un scénario qui a
  /// atteint `end` ET dont la mise en scène runtime est terminée.
  void _applyScenarioReachedEndCompletion({
    required String scenarioId,
    required String origin,
  }) {
    var progression = _gameState.progression;
    var changed = false;

    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId != null) {
      debugPrint(
        '[step_studio_trace] runtime_mark_step_completed_candidate scenario=$scenarioId step=$stepId before=${progression.completedStepIds}',
      );
      final nextSteps = appendCompletedStepIdIfAbsent(
        progression.completedStepIds,
        stepId,
      );
      if (!identical(nextSteps, progression.completedStepIds)) {
        progression = progression.copyWith(completedStepIds: nextSteps);
        changed = true;
        debugPrint(
          '[step_studio] step "$stepId" completed (cutscene "$scenarioId" reached end).',
        );
        debugPrint(
          '[step_studio_trace] runtime_completed_steps_updated scenario=$scenarioId step=$stepId after=${progression.completedStepIds}',
        );
      }
    }

    ScenarioAsset? scenarioAsset;
    for (final s in _bundle.manifest.scenarios) {
      if (s.id == scenarioId) {
        scenarioAsset = s;
        break;
      }
    }
    if (scenarioAsset != null &&
        scenarioAsset.scope == ScenarioScope.localEventFlow) {
      final nextCut = appendCompletedCutsceneIdIfAbsent(
        progression.completedCutsceneIds,
        scenarioId,
      );
      if (!identical(nextCut, progression.completedCutsceneIds)) {
        progression = progression.copyWith(completedCutsceneIds: nextCut);
        changed = true;
        debugPrint(
          '[runtime] local scenario "$scenarioId" marked completed (predicate cutsceneCompleted).',
        );
      }
    }

    if (changed) {
      _gameState = _gameState.copyWith(progression: progression);
      _refreshWorldNpcPresence();
    }
    debugPrint(
      '[step_studio_trace] completion_applied scenario=$scenarioId origin=$origin completedSteps=${_gameState.progression.completedStepIds} completedCutscenes=${_gameState.progression.completedCutsceneIds}',
    );
  }

  /// Retourne la raison bloquante empêchant de finaliser la cutscene.
  ///
  /// Tant qu'une raison existe, on ne matérialise pas les effects de progression
  /// (`completedStepIds`, `completedCutsceneIds`).
  String? _scenarioCompletionBlockingReason() {
    return scenarioRuntimeCompletionBlockingReason(
      isOverworldFlow: _flowPhase == _RuntimeFlowPhase.overworld,
      flowPhaseName: _flowPhase.name,
      isDialogueOpen: _dialogueOverlay != null,
      isCutsceneRunnerActive: isCutsceneRunning,
      hasPendingFollowCharacter: _pendingScenarioFollowRequest != null,
      hasPendingMoveContinuations:
          _pendingScenarioMoveContinuationsByEntity.isNotEmpty,
      hasPendingNpcWarpEntries: _pendingScenarioNpcWarpEntries.isNotEmpty,
      hasPendingTransitionMapRequest:
          _pendingScenarioTransitionMapRequest != null ||
              _narrativeContinuationBarriers.any(
                (barrier) => barrier.ownedTransitionMapRequest != null,
              ),
      hasPendingRuntimeWarp: _pendingWarp != null,
      hasPendingRuntimeConnection: _pendingConnection != null,
      isPlayerStepInProgress: _player.isStepping,
    );
  }

  /// Dès que les effets visibles sont terminés, on applique les complétions
  /// différées dans l'ordre d'arrivée.
  void _processPendingScenarioReachedEndCompletions() {
    if (_pendingScenarioReachedEndQueue.isEmpty) {
      _lastScenarioCompletionBlockReason = null;
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason != null) {
      if (_lastScenarioCompletionBlockReason != blockingReason) {
        debugPrint(
          '[step_studio_trace] completion_gate_blocked reason="$blockingReason" queue=${_pendingScenarioReachedEndQueue.length}',
        );
        _lastScenarioCompletionBlockReason = blockingReason;
      }
      return;
    }
    if (_lastScenarioCompletionBlockReason != null) {
      debugPrint(
        '[step_studio_trace] completion_gate_unblocked queue=${_pendingScenarioReachedEndQueue.length}',
      );
      _lastScenarioCompletionBlockReason = null;
    }
    final pendingItems =
        List<_PendingScenarioReachedEnd>.from(_pendingScenarioReachedEndQueue);
    _pendingScenarioReachedEndQueue.clear();
    for (final pending in pendingItems) {
      final waitMs = (_runtimeClockMs - pending.queuedAtMs).round();
      debugPrint(
        '[step_studio_trace] completion_deferred_flush scenario=${pending.scenarioId} waitedMs=$waitMs origin=${pending.origin}',
      );
      _applyScenarioReachedEndCompletion(
        scenarioId: pending.scenarioId,
        origin: 'deferred:${pending.origin}',
      );
    }
  }

  /// Ouvre un dialogue projet à partir d'un `dialogueId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _openScenarioDialogueById(
    String dialogueId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedDialogueId = dialogueId.trim();
    if (normalizedDialogueId.isEmpty) {
      return false;
    }
    final source = runtimeSourceId ?? 'scenario';
    _reserveNarrativeContinuationRuntimeSource(source);
    final opened = _tryOpenDialogue(
      source,
      DialogueRef(
        dialogueId: normalizedDialogueId,
        startNode: startNode,
      ),
      'Dialogue introuvable: $normalizedDialogueId',
    );
    if (!opened) {
      _discardNarrativeContinuationRuntimeSourceReservation(source);
    }
    if (opened && runtimeSourceId != null && runtimeSourceId.isNotEmpty) {
      _scheduleScenarioContinuationAfterDialogue(runtimeSourceId);
    }
    return opened;
  }

  void _scheduleScenarioContinuationAfterDialogue(String runtimeSourceId) {
    if (!runtimeSourceId.startsWith('scenario:')) {
      return;
    }
    final previous = _pendingPostDialogueAction;
    _pendingPostDialogueAction = () {
      previous?.call();
      _scheduleNarrativeContinuationAdvance(runtimeSourceId);
    };
  }

  _ScenarioContinuationResumeResult _resumeScenarioAfterRuntimeSource(
    String runtimeSourceId,
  ) {
    final parts = runtimeSourceId.split(':');
    if (parts.length != 4) {
      return const _ScenarioContinuationResumeResult.invalid();
    }
    final scenarioId = parts[1].trim();
    final sourceNodeId = parts[2].trim();
    final resumeAfterNodeId = parts[3].trim();
    if (scenarioId.isEmpty ||
        sourceNodeId.isEmpty ||
        resumeAfterNodeId.isEmpty) {
      return const _ScenarioContinuationResumeResult.invalid();
    }
    final outcomes = <NarrativeOutcomeRef>[];
    final pendingTransitionBeforeResume = _pendingScenarioTransitionMapRequest;
    final result = _scenarioRuntime.dispatchContinuation(
      scenarios: _bundle.manifest.scenarios,
      scenarioId: scenarioId,
      sourceNodeId: sourceNodeId,
      resumeAfterNodeId: resumeAfterNodeId,
      context: _buildScenarioRuntimeExecutionContext(outcomes),
    );
    _handleScenarioRuntimeCompletionResult(
      result,
      origin: 'continuation:$runtimeSourceId',
    );
    debugPrint(
      '[scenario_runtime] continuation source=$runtimeSourceId status=${result.status.name} scenario=${result.scenarioId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
    final battleHandoffReady =
        result.effect.type != ScenarioRuntimeEffectType.battle ||
            _handleScenarioBattleEffect(result);
    final pendingTransitionAfterResume = _pendingScenarioTransitionMapRequest;
    _PendingScenarioTransitionMapRequest? ownedTransitionMapRequest;
    if (pendingTransitionAfterResume != null &&
        !identical(
          pendingTransitionAfterResume,
          pendingTransitionBeforeResume,
        ) &&
        identical(
          _pendingScenarioTransitionMapRequest,
          pendingTransitionAfterResume,
        )) {
      // A continuation may synchronously schedule transitionMap before it
      // reaches End. Move only that newly-created request under the same
      // continuation owner; a pre-existing/global transition is unrelated
      // work and must never be adopted by this barrier.
      _pendingScenarioTransitionMapRequest = null;
      ownedTransitionMapRequest = pendingTransitionAfterResume;
    }
    return _ScenarioContinuationResumeResult(
      outcomes: outcomes,
      nextRuntimeSourceId: battleHandoffReady
          ? _scenarioContinuationRuntimeSourceId(result)
          : null,
      ownedTransitionMapRequest: ownedTransitionMapRequest,
    );
  }

  void _scheduleNarrativeContinuationAdvance(
    String runtimeSourceId, {
    List<NarrativeOutcomeRef> effectOutcomes = const <NarrativeOutcomeRef>[],
  }) {
    final barrier = _narrativeContinuationBarrierFor(runtimeSourceId);
    if (barrier == null || barrier.advancing) {
      if (_reservedNarrativeContinuationRuntimeSourceIds
          .contains(runtimeSourceId)) {
        // A valid Scenario cycle can synchronously start and complete the same
        // runtime source while its owning barrier is still advancing. Keep the
        // completion latched until the source reservation is claimed after the
        // barrier transfer; otherwise the one completion signal is lost.
        _deferredNarrativeContinuationAdvanceSourceIds.add(runtimeSourceId);
      }
      return;
    }
    unawaited(
      _advanceNarrativeContinuationBarrier(
        runtimeSourceId,
        effectOutcomes: effectOutcomes,
      ),
    );
  }

  void _startNarrativePostCommitEffectIfReady() {
    if (_narrativeContinuationBarriers.isEmpty) {
      return;
    }
    final barrier = _narrativeContinuationBarriers.last;
    final effect = barrier.postCommitEffect;
    if (effect == null || barrier.postCommitEffectStarted || barrier.closed) {
      return;
    }
    barrier.postCommitEffectStarted = true;
    unawaited(
      () async {
        try {
          await effect();
        } catch (error, stackTrace) {
          debugPrint(
            '[event_v2] post-commit effect failed '
            'source=${barrier.runtimeSourceId} error=$error\n$stackTrace',
          );
          _showNotification('Transition impossible.');
        } finally {
          await _advanceNarrativeContinuationBarrier(
            barrier.runtimeSourceId,
          );
        }
      }(),
    );
  }

  Future<void> _advanceNarrativeContinuationBarrier(
    String runtimeSourceId, {
    List<NarrativeOutcomeRef> effectOutcomes = const <NarrativeOutcomeRef>[],
  }) async {
    final barrier = _narrativeContinuationBarrierFor(runtimeSourceId);
    if (barrier == null || barrier.closed || barrier.advancing) {
      return;
    }
    while (_narrativeContinuationBarriers.isNotEmpty &&
        !identical(_narrativeContinuationBarriers.last, barrier)) {
      await _narrativeContinuationBarriers.last.closedFuture;
      if (barrier.closed) {
        return;
      }
    }
    barrier.advancing = true;
    try {
      if (effectOutcomes.isNotEmpty) {
        await _enqueueNarrativeOutcomes(
          effectOutcomes,
          causationId: barrier.continuation.causationId,
          correlationId: barrier.continuation.correlationId,
          depth: barrier.continuation.depth,
        );
      }

      // Drain every FIFO item that precedes or belongs to this continuation.
      // A newly suspended Scenario pushes a child barrier; wait for that child
      // to close, then continue the same bounded owner progression.
      await _drainNarrativeOutcomesOwnedBy(barrier);

      if (!barrier.resumesScenario || barrier.cancelled) {
        _closeNarrativeContinuationBarrier(barrier);
        return;
      }

      final resumed = _resumeScenarioAfterRuntimeSource(runtimeSourceId);
      final resumedTransition = resumed.ownedTransitionMapRequest;
      if (resumedTransition != null) {
        if (barrier.ownedTransitionMapRequest != null) {
          throw StateError(
            'A narrative continuation cannot own two map transitions.',
          );
        }
        // Transfer ownership before the first await after resume so no update
        // tick can observe the transition as globally detached and unowned.
        barrier.ownedTransitionMapRequest = resumedTransition;
      }
      await _narrativeStateTransactions.transact<void>((_) {
        return NarrativeEventStateTransaction.commit(_gameState, null);
      });
      if (resumed.outcomes.isNotEmpty) {
        await _enqueueNarrativeOutcomes(
          resumed.outcomes,
          causationId: barrier.continuation.causationId,
          correlationId: barrier.continuation.correlationId,
          depth: barrier.continuation.depth,
        );
      }

      final nextRuntimeSourceId = resumed.nextRuntimeSourceId;
      if (nextRuntimeSourceId != null) {
        barrier.runtimeSourceId = nextRuntimeSourceId;
        barrier.advancing = false;
        _claimNarrativeContinuationRuntimeSource(
          barrier,
          nextRuntimeSourceId,
        );
        debugPrint(
          '[event_v2] continuation barrier transferred '
          'source=$nextRuntimeSourceId',
        );
        return;
      }

      await _drainNarrativeOutcomesOwnedBy(barrier);
      final ownedTransition = barrier.ownedTransitionMapRequest;
      if (ownedTransition != null) {
        await _executeScenarioTransitionMapRequest(
          ownedTransition,
          allowMapActivationWork: true,
          skipVisualTransition: !isLoaded,
        );
        barrier.ownedTransitionMapRequest = null;
        // The target mapEnter may itself suspend a Scenario. Preserve strict
        // LIFO ownership and wait for that child before closing this restored
        // parent barrier.
        await _drainNarrativeOutcomesOwnedBy(barrier);
      }
      _closeNarrativeContinuationBarrier(barrier);
    } catch (error, stackTrace) {
      debugPrint(
        '[event_v2] continuation barrier failed '
        'source=$runtimeSourceId error=$error\n$stackTrace',
      );
      _showNotification('Résultat narratif impossible.');
      _closeNarrativeContinuationBarrier(barrier);
    }
  }

  Future<void> _drainNarrativeOutcomesOwnedBy(
    _NarrativeContinuationBarrier owner,
  ) async {
    while (!owner.closed) {
      while (_narrativeContinuationBarriers.isNotEmpty &&
          !identical(_narrativeContinuationBarriers.last, owner)) {
        await _narrativeContinuationBarriers.last.closedFuture;
      }
      if (owner.closed) {
        return;
      }
      await _drainLiveNarrativeOutcomeOutbox();
      if (_narrativeContinuationBarriers.isNotEmpty &&
          !identical(_narrativeContinuationBarriers.last, owner)) {
        continue;
      }
      final state = await _narrativeStateTransactions.read();
      if (state
          .narrativeEventProgress.pendingNarrativeOutcomeDeliveries.isEmpty) {
        _applyNarrativeGameState(state);
        return;
      }
    }
  }

  void _closeNarrativeContinuationBarrier(
    _NarrativeContinuationBarrier barrier,
  ) {
    if (barrier.closed) {
      return;
    }
    if (_narrativeContinuationBarriers.isEmpty ||
        !identical(_narrativeContinuationBarriers.last, barrier)) {
      throw StateError('Narrative continuation barriers must close LIFO.');
    }
    _narrativeContinuationBarriers.removeLast();
    barrier.closed = true;
    barrier.lease.close();
    barrier.closedCompleter.complete();
    debugPrint(
      '[event_v2] continuation barrier closed '
      'source=${barrier.runtimeSourceId} '
      'depth=${_narrativeContinuationBarriers.length}',
    );
  }

  void _cancelNarrativeContinuationBarrier(String runtimeSourceId) {
    final barrier = _narrativeContinuationBarrierFor(runtimeSourceId);
    if (barrier == null || barrier.closed) {
      if (_reservedNarrativeContinuationRuntimeSourceIds
          .contains(runtimeSourceId)) {
        _deferredNarrativeContinuationCancelSourceIds.add(runtimeSourceId);
      }
      return;
    }
    barrier.cancelled = true;
    _scheduleNarrativeContinuationAdvance(runtimeSourceId);
  }

  void _attachNarrativeOutcomeContinuationToBarrier(
    ScenarioRuntimeExecutionResult result,
    _NarrativeOutcomeContinuationContext continuation,
  ) {
    final runtimeSourceId = _scenarioContinuationRuntimeSourceId(result);
    if (runtimeSourceId == null) {
      return;
    }
    final barrier = _narrativeContinuationBarrierFor(runtimeSourceId);
    if (barrier != null) {
      barrier.continuation = continuation;
    }
  }

  String? _scenarioContinuationRuntimeSourceId(
    ScenarioRuntimeExecutionResult result,
  ) {
    if (result.status != ScenarioRuntimeExecutionStatus.executedEffect) {
      return null;
    }
    switch (result.effect.type) {
      case ScenarioRuntimeEffectType.dialogue:
      case ScenarioRuntimeEffectType.script:
      case ScenarioRuntimeEffectType.battle:
      case ScenarioRuntimeEffectType.none:
        break;
      case ScenarioRuntimeEffectType.message:
        return null;
    }
    final scenarioId = result.scenarioId?.trim() ?? '';
    final sourceNodeId = result.sourceNodeId?.trim() ?? '';
    final stopNodeId = result.stopNodeId?.trim() ?? '';
    if (scenarioId.isEmpty || sourceNodeId.isEmpty || stopNodeId.isEmpty) {
      return null;
    }
    return 'scenario:$scenarioId:$sourceNodeId:$stopNodeId';
  }

  _NarrativeContinuationBarrier? _registerNarrativeContinuationBarrier(
    ScenarioRuntimeExecutionResult result,
  ) {
    final runtimeSourceId = _scenarioContinuationRuntimeSourceId(result);
    if (runtimeSourceId == null) {
      return null;
    }
    return _openNarrativeContinuationBarrier(
      runtimeSourceId: runtimeSourceId,
      continuation: _NarrativeOutcomeContinuationContext(
        causationId: _nextNarrativeRuntimeId('evx'),
        correlationId: _nextNarrativeRuntimeId('corr'),
        depth: 0,
      ),
    );
  }

  _NarrativeContinuationBarrier _openNarrativeContinuationBarrier({
    required String runtimeSourceId,
    required _NarrativeOutcomeContinuationContext continuation,
    bool resumesScenario = true,
    Future<void> Function()? postCommitEffect,
  }) {
    final barrier = _NarrativeContinuationBarrier(
      runtimeSourceId: runtimeSourceId,
      continuation: continuation,
      lease: _narrativeActivityGate.enter(
        NarrativeRuntimeActivity.sceneSuspended,
      ),
      resumesScenario: resumesScenario,
      postCommitEffect: postCommitEffect,
    );
    _narrativeContinuationBarriers.add(barrier);
    _claimNarrativeContinuationRuntimeSource(barrier, runtimeSourceId);
    debugPrint(
      '[event_v2] continuation barrier opened source=$runtimeSourceId '
      'depth=${_narrativeContinuationBarriers.length}',
    );
    return barrier;
  }

  void _reserveNarrativeContinuationRuntimeSource(String runtimeSourceId) {
    if (runtimeSourceId.startsWith('scenario:')) {
      _reservedNarrativeContinuationRuntimeSourceIds.add(runtimeSourceId);
    }
  }

  void _discardNarrativeContinuationRuntimeSourceReservation(
    String runtimeSourceId,
  ) {
    _reservedNarrativeContinuationRuntimeSourceIds.remove(runtimeSourceId);
    _deferredNarrativeContinuationAdvanceSourceIds.remove(runtimeSourceId);
    _deferredNarrativeContinuationCancelSourceIds.remove(runtimeSourceId);
  }

  void _claimNarrativeContinuationRuntimeSource(
    _NarrativeContinuationBarrier barrier,
    String runtimeSourceId,
  ) {
    _reservedNarrativeContinuationRuntimeSourceIds.remove(runtimeSourceId);
    final shouldCancel =
        _deferredNarrativeContinuationCancelSourceIds.remove(runtimeSourceId);
    final shouldAdvance =
        _deferredNarrativeContinuationAdvanceSourceIds.remove(runtimeSourceId);
    if (shouldCancel) {
      barrier.cancelled = true;
    }
    if (shouldCancel || shouldAdvance) {
      scheduleMicrotask(
        () => _scheduleNarrativeContinuationAdvance(runtimeSourceId),
      );
    }
  }

  _NarrativeContinuationBarrier? _narrativeContinuationBarrierFor(
    String runtimeSourceId,
  ) {
    for (final barrier in _narrativeContinuationBarriers.reversed) {
      if (!barrier.closed && barrier.runtimeSourceId == runtimeSourceId) {
        return barrier;
      }
    }
    return null;
  }

  /// [SEL-B2] Gère un effet `ScenarioRuntimeEffectType.battle` retourné par
  /// l'exécuteur de graphe scénario.
  ///
  /// Réutilise le pattern `_pendingBattleRequest` existant : le combat sera
  /// lancé par `update()` au prochain tick, exactement comme un combat LoS ou
  /// wild. La continuation scénario est stockée dans
  /// `_pendingScenarioBattleHandoff` et sera consommée uniquement par le
  /// résultat portant le même requestId dans `_onBattleFinished`.
  bool _handleScenarioBattleEffect(ScenarioRuntimeExecutionResult result) {
    final effect = result.effect;
    final trainerId = effect.trainerId ?? '';
    final npcEntityId = effect.npcEntityId ?? '';
    final battleId = effect.battleId ?? trainerId;
    if (trainerId.isEmpty || npcEntityId.isEmpty) {
      debugPrint(
        '[scenario_runtime] battle effect incomplete: trainerId=$trainerId npcEntityId=$npcEntityId',
      );
      return false;
    }

    // Construire le runtimeSourceId pour la continuation post-combat.
    // Format attendu : 'scenario:<scenarioId>:<sourceNodeId>:<stopNodeId>'
    // Si l'un des composants est null, on ne peut pas construire le sourceId
    // et donc pas programmer de continuation → abort proprement.
    final scenarioId = result.scenarioId;
    final sourceNodeId = result.sourceNodeId;
    final stopNodeId = result.stopNodeId;
    if (scenarioId == null || sourceNodeId == null || stopNodeId == null) {
      debugPrint(
        '[scenario_runtime] battle effect: cannot build runtimeSourceId '
        '(scenarioId=$scenarioId sourceNodeId=$sourceNodeId stopNodeId=$stopNodeId)',
      );
      return false;
    }
    final runtimeSourceId = 'scenario:$scenarioId:$sourceNodeId:$stopNodeId';

    // Chercher l'entité NPC sur la map courante.
    final entity = _world.map.entities
        .cast<MapEntity?>()
        .firstWhere((e) => e?.id == npcEntityId, orElse: () => null);
    if (entity == null) {
      debugPrint(
        '[scenario_runtime] battle effect: npc entity "$npcEntityId" not found on current map',
      );
      return false;
    }

    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request == null) {
      debugPrint(
        '[scenario_runtime] battle effect: could not build TrainerBattleStartRequest for trainerId=$trainerId npcEntityId=$npcEntityId',
      );
      return false;
    }

    final owner = _PendingScenarioBattleHandoff(
      requestId: request.requestId,
      runtimeSourceId: runtimeSourceId,
      battleId: battleId,
    );
    if (!_tryEnqueueBattleRequest(request, scenarioOwner: owner)) {
      debugPrint(
        '[scenario_runtime] battle handoff rejected: another Battle handoff '
        'already owns the queue',
      );
      return false;
    }

    _triggeredTrainerBattles.add(entity.id);

    debugPrint(
      '[scenario_runtime] battle handoff enqueued: battleId=$battleId trainerId=$trainerId npcEntityId=$npcEntityId runtimeSourceId=$runtimeSourceId',
    );
    return true;
  }

  bool _tryEnqueueBattleRequest(
    BattleStartRequest request, {
    _PendingScenarioBattleHandoff? scenarioOwner,
  }) {
    if (_hasClaimedBattleHandoff) {
      return false;
    }
    _pendingBattleRequest = request;
    _pendingScenarioBattleHandoff = scenarioOwner;
    return true;
  }

  bool get _hasClaimedBattleHandoff =>
      _pendingBattleRequest != null ||
      _pendingScenarioBattleHandoff != null ||
      _pendingSceneBattleOutcomeCompleter != null;

  bool _runScenarioMoveCharacter({
    required String entityId,
    required String targetKind,
    required String targetId,
    required bool waitForCompletion,
    String? runtimeSourceId,
  }) {
    final trimmedEntity = entityId.trim();
    if (trimmedEntity == 'player') {
      _scriptedEntityMovementController?.syncTrackedEntityPosition(
        trimmedEntity,
        _world.player.pos,
      );
    }
    final destination = _resolveScenarioMoveTarget(
      targetKind: targetKind,
      targetId: targetId,
    );
    if (destination == null) {
      debugPrint(
        '[scenario_runtime] moveCharacter target unresolved kind=$targetKind targetId=$targetId',
      );
      return false;
    }
    var resolvedDestination = destination;
    var entityApproachCandidates = const <GridPos>[];
    if (targetKind == 'entity') {
      entityApproachCandidates = _resolveScenarioEntityApproachCandidates(
        moverEntityId: entityId,
        targetEntityId: targetId,
        primaryDestination: destination,
      );
      if (entityApproachCandidates.isEmpty) {
        debugPrint(
          '[scenario_runtime] moveCharacter entity target has no reachable adjacent cell entity=$entityId target=$targetId',
        );
        return false;
      }
      resolvedDestination = entityApproachCandidates.first;
    }
    var started = startScriptedNpcMove(
      entityId: entityId,
      destination: resolvedDestination,
    );
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        final fallbackCandidates = _resolveScenarioWarpApproachCandidates(
          entityId: entityId,
          warp: warp,
          primaryDestination: destination,
        );
        for (final candidate in fallbackCandidates) {
          final fallbackStarted = startScriptedNpcMove(
            entityId: entityId,
            destination: candidate,
          );
          if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
            resolvedDestination = candidate;
            started = fallbackStarted;
            debugPrint(
              '[scenario_runtime] moveCharacter warp fallback entity=$entityId warp=${warp.id} destination=(${candidate.x},${candidate.y})',
            );
            break;
          }
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'entity') {
      final fallbackCandidates = entityApproachCandidates.isNotEmpty
          ? entityApproachCandidates.skip(1)
          : _resolveScenarioEntityApproachCandidates(
              moverEntityId: entityId,
              targetEntityId: targetId,
              primaryDestination: destination,
            );
      for (final candidate in fallbackCandidates) {
        final fallbackStarted = startScriptedNpcMove(
          entityId: entityId,
          destination: candidate,
        );
        if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
          resolvedDestination = candidate;
          started = fallbackStarted;
          debugPrint(
            '[scenario_runtime] moveCharacter entity fallback entity=$entityId target=$targetId destination=(${candidate.x},${candidate.y})',
          );
          break;
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed) {
      debugPrint(
        '[scenario_runtime] moveCharacter failed entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y})',
      );
      return false;
    }
    if (targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        _pendingScenarioNpcWarpEntries[entityId] = _PendingScenarioNpcWarpEntry(
          entityId: entityId,
          warpId: warp.id,
          warpPos: warp.pos,
          approachPos: resolvedDestination,
        );
      }
    } else {
      _pendingScenarioNpcWarpEntries.remove(entityId);
    }
    if (waitForCompletion) {
      final runtimeSource = runtimeSourceId?.trim() ?? '';
      if (runtimeSource.startsWith('scenario:') && trimmedEntity.isNotEmpty) {
        _pendingScenarioMoveContinuationsByEntity[trimmedEntity] =
            _PendingScenarioMoveContinuation(
          entityId: trimmedEntity,
          runtimeSourceId: runtimeSource,
          targetKind: targetKind,
        );
      }
      debugPrint(
        '[scenario_runtime] moveCharacter started entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y}) waitForCompletion=true',
      );
    }
    return true;
  }

  bool _runScenarioTransitionMap({
    required String mapId,
    required String warpId,
  }) {
    final normalizedMapId = mapId.trim();
    final normalizedWarpId = warpId.trim();
    if (normalizedMapId.isEmpty || normalizedWarpId.isEmpty) {
      debugPrint(
        '[scenario_runtime] transitionMap invalid mapId="$mapId" warpId="$warpId"',
      );
      return false;
    }
    if (_pendingScenarioTransitionMapRequest != null) {
      debugPrint(
        '[scenario_runtime] transitionMap rejected: another transition owns '
        'the queue',
      );
      return false;
    }
    _pendingScenarioTransitionMapRequest = _PendingScenarioTransitionMapRequest(
      mapId: normalizedMapId,
      warpId: normalizedWarpId,
    );
    debugPrint(
      '[scenario_runtime] transitionMap scheduled map=$normalizedMapId warp=$normalizedWarpId',
    );
    return true;
  }

  void _processPendingScenarioTransitionMapRequest() {
    final pending = _pendingScenarioTransitionMapRequest;
    if (pending == null) {
      return;
    }

    // On attend la fin du suivi (followCharacter) pour ne pas couper la scène.
    if (_pendingScenarioFollowRequest != null) {
      return;
    }
    if (_player.isStepping) {
      return;
    }

    _pendingScenarioTransitionMapRequest = null;
    unawaited(_executeScenarioTransitionMapRequest(pending));
  }

  Future<void> _executeScenarioTransitionMapRequest(
    _PendingScenarioTransitionMapRequest request, {
    bool allowMapActivationWork = false,
    bool skipVisualTransition = false,
  }) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint(
        '[scenario_runtime] transitionMap ignored: flow=${_flowPhase.name}',
      );
      return;
    }
    try {
      final targetBundle = await _loadRuntimeMapBundleCached(request.mapId);
      MapWarp? targetWarp;
      for (final candidate in targetBundle.map.warps) {
        if (candidate.id == request.warpId) {
          targetWarp = candidate;
          break;
        }
      }
      if (targetWarp == null) {
        debugPrint(
          '[scenario_runtime] transitionMap failed: warp "${request.warpId}" not found on map "${request.mapId}"',
        );
        _showNotification('Transition impossible (warp introuvable)');
        return;
      }

      final transition = TriggeredWarp(
        warpId: 'scenario:${request.warpId}',
        targetMapId: targetBundle.map.id,
        targetPos: targetWarp.pos,
        triggerMode: MapWarpTriggerMode.onEnter,
      );
      debugPrint(
        '[scenario_runtime] transitionMap start map=${transition.targetMapId} warp=${request.warpId} pos=(${transition.targetPos.x},${transition.targetPos.y})',
      );
      await _handleWarp(
        transition,
        allowMapActivationWork: allowMapActivationWork,
        skipVisualTransition: skipVisualTransition,
      );
    } catch (e, st) {
      debugPrint(
        '[scenario_runtime] transitionMap failed map=${request.mapId} warp=${request.warpId}: $e\n$st',
      );
      _showNotification('Transition impossible');
    }
  }

  MapWarp? _findMapWarpById(String warpId) {
    final normalized = warpId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final warp in _world.map.warps) {
      if (warp.id == normalized) {
        return warp;
      }
    }
    return null;
  }

  List<GridPos> _resolveScenarioWarpApproachCandidates({
    required String entityId,
    required MapWarp warp,
    required GridPos primaryDestination,
  }) {
    final currentPos = _resolveScenarioEntityPosition(entityId) ?? warp.pos;
    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};

    // Anneaux autour du warp: on essaie de rester proche de la porte tout en
    // respectant le footprint collision réel du PNJ (souvent 2x2).
    const maxRadius = 4;
    for (var radius = 1; radius <= maxRadius; radius++) {
      for (var dx = -radius; dx <= radius; dx++) {
        final top = GridPos(x: warp.pos.x + dx, y: warp.pos.y - radius);
        if (_addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: top,
          entityId: entityId,
        )) {
          // no-op
        }
        final bottom = GridPos(x: warp.pos.x + dx, y: warp.pos.y + radius);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: bottom,
          entityId: entityId,
        );
      }
      for (var dy = -radius + 1; dy <= radius - 1; dy++) {
        final left = GridPos(x: warp.pos.x - radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: left,
          entityId: entityId,
        );
        final right = GridPos(x: warp.pos.x + radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: right,
          entityId: entityId,
        );
      }
    }

    candidates.sort((a, b) {
      final aDoor = (a.x - warp.pos.x).abs() + (a.y - warp.pos.y).abs();
      final bDoor = (b.x - warp.pos.x).abs() + (b.y - warp.pos.y).abs();
      if (aDoor != bDoor) {
        return aDoor.compareTo(bDoor);
      }
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      return aCurrent.compareTo(bCurrent);
    });
    return candidates;
  }

  List<GridPos> _resolveScenarioEntityApproachCandidates({
    required String moverEntityId,
    required String targetEntityId,
    required GridPos primaryDestination,
  }) {
    final currentPos =
        _resolveScenarioEntityPosition(moverEntityId) ?? primaryDestination;

    MapRect targetRect;
    if (targetEntityId == 'player') {
      targetRect = MapRect(
        pos: _world.player.pos,
        size: const GridSize(width: 1, height: 1),
      );
    } else {
      MapEntity? targetEntity;
      for (final entry in _world.map.entities) {
        if (entry.id == targetEntityId) {
          targetEntity = entry;
          break;
        }
      }
      if (targetEntity == null) {
        return const <GridPos>[];
      }
      targetRect = resolveEntityCollisionFootprint(targetEntity);
    }

    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};
    for (final cell in _adjacentCellsAroundRect(targetRect)) {
      if (!seen.add(cell)) {
        continue;
      }
      if (!_isWithinMapBounds(_world.map, cell)) {
        continue;
      }
      if (!_isScenarioNpcAnchorPassable(
          entityId: moverEntityId, anchor: cell)) {
        continue;
      }
      candidates.add(cell);
    }

    candidates.sort((a, b) {
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      if (aCurrent != bCurrent) {
        return aCurrent.compareTo(bCurrent);
      }
      final aTarget =
          (a.x - targetRect.pos.x).abs() + (a.y - targetRect.pos.y).abs();
      final bTarget =
          (b.x - targetRect.pos.x).abs() + (b.y - targetRect.pos.y).abs();
      return aTarget.compareTo(bTarget);
    });
    return candidates;
  }

  bool _addWarpApproachCandidate({
    required Set<GridPos> seen,
    required List<GridPos> out,
    required GridPos candidate,
    required String entityId,
  }) {
    if (!seen.add(candidate)) {
      return false;
    }
    if (!_isWithinMapBounds(_world.map, candidate)) {
      return false;
    }
    if (!_isScenarioNpcAnchorPassable(entityId: entityId, anchor: candidate)) {
      return false;
    }
    out.add(candidate);
    return true;
  }

  bool _isScenarioNpcAnchorPassable({
    required String entityId,
    required GridPos anchor,
  }) {
    if (entityId.trim() == 'player') {
      return _isPlayerScriptedMoveAnchorPassable(anchor);
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: anchor,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    return probe.passable;
  }

  bool _isPlayerScriptedMoveAnchorPassable(GridPos anchor) {
    final mode = _world.player.movementMode;
    if (_world.movementBlockReasonAt(
          x: anchor.x,
          y: anchor.y,
          movementMode: mode,
        ) !=
        null) {
      return false;
    }
    for (final cell
        in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
      if (cell.x == anchor.x && cell.y == anchor.y) {
        return false;
      }
    }
    return true;
  }

  GridPos? _resolveScenarioEntityPosition(String entityId) {
    if (entityId == 'player') {
      return _world.player.pos;
    }
    final runtimePos = _runtimeNpcPositions[entityId];
    if (runtimePos != null) {
      return runtimePos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == entityId) {
        return entity.pos;
      }
    }
    return null;
  }

  GridPos? _resolveScenarioMoveTarget({
    required String targetKind,
    required String targetId,
  }) {
    final map = _world.map;
    switch (targetKind) {
      case 'warp':
        for (final warp in map.warps) {
          if (warp.id == targetId) {
            return warp.pos;
          }
        }
        return null;
      case 'spawn':
        for (final entity in map.entities) {
          if (entity.kind == MapEntityKind.spawn && entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      case 'entity':
        if (targetId == 'player') {
          return _world.player.pos;
        }
        for (final entity in map.entities) {
          if (entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      default:
        return null;
    }
  }

  bool _suppressOverworldInputForScriptedPlayerMovement() {
    final status = scriptedNpcMovementStatus('player');
    return status.state == ScriptedEntityMovementState.moving;
  }

  void _clearPressedMovementControls() {
    _pressedMovementControls.clear();
    _lastMovementControl = null;
  }

  int _beginBlockingInteraction({
    required String source,
    bool pendingDialogueLoad = false,
  }) {
    _clearPressedMovementControls();
    final serial = ++_nextBlockingInteractionSerial;
    _activeBlockingInteractionSerial = serial;
    _activeBlockingInteractionSourceId = source;
    _hasPendingDialogueLoad = pendingDialogueLoad;
    _setFlowPhase(_RuntimeFlowPhase.blockingInteraction);
    debugPrint(
      '[scenario_lock] accepted source=$source phase=${pendingDialogueLoad ? 'dialogueLoading' : 'blockingInteraction'} serial=$serial',
    );
    return serial;
  }

  bool _isBlockingInteractionActive(int serial) {
    return _activeBlockingInteractionSerial == serial;
  }

  void _markBlockingInteractionPendingDialogue() {
    if (_activeBlockingInteractionSerial == null) {
      return;
    }
    _hasPendingDialogueLoad = true;
  }

  void _clearBlockingInteractionState() {
    _activeBlockingInteractionSerial = null;
    _activeBlockingInteractionSourceId = null;
    _hasPendingDialogueLoad = false;
  }

  void _releaseBlockingInteraction({
    required int serial,
    required String source,
    required String reason,
  }) {
    if (!_isBlockingInteractionActive(serial)) {
      return;
    }
    _clearBlockingInteractionState();
    if (_flowPhase == _RuntimeFlowPhase.blockingInteraction) {
      _setFlowPhase(_RuntimeFlowPhase.overworld);
    }
    debugPrint(
      '[scenario_lock] released source=$source reason=$reason serial=$serial',
    );
  }

  void _clearBlockingInteractionWithoutUnlock({required String reason}) {
    final source = _activeBlockingInteractionSourceId;
    final serial = _activeBlockingInteractionSerial;
    if (serial == null) {
      return;
    }
    _clearBlockingInteractionState();
    debugPrint(
      '[scenario_lock] cleared source=${source ?? '-'} reason=$reason serial=$serial',
    );
  }

  void _abortActiveScriptAfterDialogueFailure({
    required int serial,
    required String source,
    required String fallbackLabel,
  }) {
    _abortActiveScriptExecution(
      source: source,
      reason: 'dialogueLoadFailed',
      fallbackLabel: fallbackLabel,
      expectedBlockingSerial: serial,
    );
  }

  void _abortActiveScriptExecution({
    required String source,
    required String reason,
    required String fallbackLabel,
    int? expectedBlockingSerial,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _activeScriptController = null;
    _activeScriptRuntimeSourceId = null;
    final serial = _activeBlockingInteractionSerial;
    if (serial != null &&
        (expectedBlockingSerial == null || serial == expectedBlockingSerial)) {
      _releaseBlockingInteraction(
        serial: serial,
        source: source,
        reason: reason,
      );
    }
    _pendingPostDialogueAction = null;
    final warpOwner = _pendingScenarioWarpHandoff;
    if (warpOwner != null &&
        warpOwner.kind == _ScenarioWarpHandoffKind.script &&
        warpOwner.runtimeSourceId == source) {
      if (warpOwner.matches(_pendingWarp)) {
        _pendingWarp = null;
      }
      _pendingScenarioWarpHandoff = null;
    }
    _cancelNarrativeContinuationBarrier(source);
    debugPrint(
      '[script] aborted source=$source reason=$reason '
      'error=${error ?? '-'}${stackTrace == null ? '' : '\n$stackTrace'}',
    );
    _showNotification(fallbackLabel);
  }

  void _resumeActiveScriptAfterDialogue(String runtimeSourceId) {
    final controller = _activeScriptController;
    if (controller == null) {
      _activeScriptRuntimeSourceId = null;
      return;
    }
    _activeScriptRuntimeSourceId = runtimeSourceId;
    controller.resume();
    _beginBlockingInteraction(source: runtimeSourceId);
    _runScriptStep();
  }

  void _processPendingScenarioNpcWarpEntries({String? onlyEntityId}) {
    if (_pendingScenarioNpcWarpEntries.isEmpty) {
      return;
    }
    final entityIds = onlyEntityId == null
        ? (_pendingScenarioNpcWarpEntries.keys.toList(growable: false)..sort())
        : <String>[onlyEntityId];
    for (final entityId in entityIds) {
      final pending = _pendingScenarioNpcWarpEntries[entityId];
      if (pending == null) {
        continue;
      }
      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        debugPrint(
          '[scenario_runtime] npc warp canceled entity=$entityId warp=${pending.warpId} reason="${status.failureReason ?? 'move failed'}"',
        );
        _pendingScenarioNpcWarpEntries.remove(entityId);
        continue;
      }
      if (status.state != ScriptedEntityMovementState.completed) {
        final stillPresent = _resolveScenarioEntityPosition(entityId) != null;
        if (!stillPresent) {
          _pendingScenarioNpcWarpEntries.remove(entityId);
        }
        continue;
      }
      _pendingScenarioNpcWarpEntries.remove(entityId);
      _completeScenarioNpcWarpEntry(pending);
    }
  }

  void _processPendingScenarioMoveContinuations({String? onlyEntityId}) {
    if (_pendingScenarioMoveContinuationsByEntity.isEmpty) {
      return;
    }
    final entityIds = onlyEntityId == null
        ? (_pendingScenarioMoveContinuationsByEntity.keys
            .toList(growable: false)
          ..sort())
        : <String>[onlyEntityId];
    for (final entityId in entityIds) {
      final pending = _pendingScenarioMoveContinuationsByEntity[entityId];
      if (pending == null) {
        continue;
      }

      if (pending.targetKind == 'warp' &&
          pending.entityId == 'player' &&
          _pendingScenarioWarpHandoff?.runtimeSourceId ==
              pending.runtimeSourceId) {
        // Le déplacement est "fini" uniquement après consommation effective du
        // warp joueur et retour en overworld.
        continue;
      }

      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        _cancelNarrativeContinuationBarrier(pending.runtimeSourceId);
        continue;
      }
      if (status.state == ScriptedEntityMovementState.completed ||
          status.state == ScriptedEntityMovementState.idle) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        _scheduleNarrativeContinuationAdvance(pending.runtimeSourceId);
      }
    }
  }

  void _completeScenarioNpcWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    if (pending.entityId.trim() == 'player') {
      _completeScenarioPlayerWarpEntry(pending);
      return;
    }
    final moveContinuation =
        _pendingScenarioMoveContinuationsByEntity[pending.entityId];
    final activeFollow = _pendingScenarioFollowRequest;
    final keepFollowActive = activeFollow?.leaderEntityId == pending.entityId;
    var continuationOwnedByLeaderWarp = false;
    if (keepFollowActive) {
      final warp = _findMapWarpById(pending.warpId);
      if (warp == null) {
        if (moveContinuation != null) {
          _pendingScenarioMoveContinuationsByEntity.remove(pending.entityId);
          _cancelNarrativeContinuationBarrier(
            moveContinuation.runtimeSourceId,
          );
        }
        _pendingScenarioFollowRequest = null;
        debugPrint(
          '[scenario_runtime] followCharacter leaderWarp canceled '
          'leader=${pending.entityId} warp=${pending.warpId} reason=missing_warp',
        );
        return;
      }
      final triggeredWarp = TriggeredWarp(
        warpId: warp.id,
        targetMapId: warp.targetMapId,
        targetPos: warp.targetPos,
        triggerMode: warp.triggerMode,
      );
      final owner = moveContinuation == null
          ? null
          : _PendingScenarioWarpHandoff(
              runtimeSourceId: moveContinuation.runtimeSourceId,
              expectedWarp: triggeredWarp,
              kind: _ScenarioWarpHandoffKind.leaderMove,
              entityId: pending.entityId,
            );
      if (!_tryEnqueueWarp(triggeredWarp, scenarioOwner: owner)) {
        if (moveContinuation != null) {
          _pendingScenarioMoveContinuationsByEntity.remove(pending.entityId);
          _cancelNarrativeContinuationBarrier(
            moveContinuation.runtimeSourceId,
          );
        }
        _pendingScenarioFollowRequest = null;
        _despawnNpcFromActiveMap(pending.entityId);
        debugPrint(
          '[scenario_runtime] followCharacter leaderWarp canceled '
          'leader=${pending.entityId} warp=${warp.id} reason=queue_owned',
        );
        return;
      }
      continuationOwnedByLeaderWarp = owner != null;
      _pendingScenarioLeaderWarpHandoff = _PendingScenarioLeaderWarpHandoff(
        leaderEntityId: pending.entityId,
        warpId: warp.id,
        targetMapId: warp.targetMapId,
        targetPos: warp.targetPos,
        triggerMode: warp.triggerMode,
        runtimeSourceId: owner?.runtimeSourceId,
      );
      debugPrint(
        '[scenario_runtime] followCharacter leaderWarp leader=${pending.entityId} '
        'warp=${warp.id} targetMap=${warp.targetMapId} '
        'source=${owner?.runtimeSourceId ?? 'non_awaited'}',
      );
    }
    final removed = _despawnNpcFromActiveMap(
      pending.entityId,
      keepActiveFollow: keepFollowActive,
    );
    if (!removed) {
      debugPrint(
        '[scenario_runtime] npc warp failed to remove entity=${pending.entityId} warp=${pending.warpId}',
      );
      if (moveContinuation != null) {
        final owner = _pendingScenarioWarpHandoff;
        if (owner != null &&
            owner.kind == _ScenarioWarpHandoffKind.leaderMove &&
            owner.entityId == pending.entityId) {
          if (owner.matches(_pendingWarp)) {
            _pendingWarp = null;
          }
          _pendingScenarioWarpHandoff = null;
        }
        _pendingScenarioLeaderWarpHandoff = null;
        _pendingScenarioFollowRequest = null;
        _cancelNarrativeContinuationBarrier(
          moveContinuation.runtimeSourceId,
        );
      }
      return;
    }
    if (moveContinuation != null && !continuationOwnedByLeaderWarp) {
      _scheduleNarrativeContinuationAdvance(moveContinuation.runtimeSourceId);
    }
    debugPrint(
      '[scenario_runtime] npc entered warp entity=${pending.entityId} warp=${pending.warpId} approach=(${pending.approachPos.x},${pending.approachPos.y})',
    );
  }

  void _completeScenarioPlayerWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    final warp = _findMapWarpById(pending.warpId);
    if (warp == null) {
      debugPrint(
        '[scenario_runtime] player warp failed: warp "${pending.warpId}" not found on map "${_bundle.map.id}"',
      );
      final moveContinuation =
          _pendingScenarioMoveContinuationsByEntity.remove(pending.entityId);
      if (moveContinuation != null) {
        _cancelNarrativeContinuationBarrier(
          moveContinuation.runtimeSourceId,
        );
      }
      return;
    }
    final moveContinuation =
        _pendingScenarioMoveContinuationsByEntity[pending.entityId];
    final triggeredWarp = TriggeredWarp(
      warpId: warp.id,
      targetMapId: warp.targetMapId,
      targetPos: warp.targetPos,
      triggerMode: warp.triggerMode,
    );
    final owner = moveContinuation == null
        ? null
        : _PendingScenarioWarpHandoff(
            runtimeSourceId: moveContinuation.runtimeSourceId,
            expectedWarp: triggeredWarp,
            kind: _ScenarioWarpHandoffKind.playerMove,
            entityId: pending.entityId,
          );
    if (!_tryEnqueueWarp(triggeredWarp, scenarioOwner: owner)) {
      debugPrint(
        '[scenario_runtime] player warp handoff rejected: another warp owns '
        'the queue',
      );
      if (moveContinuation != null) {
        _pendingScenarioMoveContinuationsByEntity.remove(pending.entityId);
        _cancelNarrativeContinuationBarrier(
          moveContinuation.runtimeSourceId,
        );
      }
      return;
    }
    debugPrint(
      '[scenario_runtime] player reached warp=${warp.id} -> map=${warp.targetMapId} target=(${warp.targetPos.x},${warp.targetPos.y})',
    );
  }

  bool _tryEnqueueWarp(
    TriggeredWarp warp, {
    _PendingScenarioWarpHandoff? scenarioOwner,
  }) {
    if (_pendingWarp != null || _pendingScenarioWarpHandoff != null) {
      return false;
    }
    _pendingWarp = warp;
    _pendingScenarioWarpHandoff = scenarioOwner;
    return true;
  }

  void _completeOwnedScenarioWarpContinuation(
    _PendingScenarioWarpHandoff owner,
  ) {
    if (owner.kind == _ScenarioWarpHandoffKind.playerMove ||
        owner.kind == _ScenarioWarpHandoffKind.leaderMove) {
      final entityId = owner.entityId;
      final pending = entityId == null
          ? null
          : _pendingScenarioMoveContinuationsByEntity[entityId];
      if (pending?.runtimeSourceId == owner.runtimeSourceId) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
      }
    }
    if (owner.runtimeSourceId.startsWith('scenario:')) {
      _scheduleNarrativeContinuationAdvance(owner.runtimeSourceId);
    }
  }

  void _cancelOwnedScenarioWarpContinuation(
    _PendingScenarioWarpHandoff owner,
  ) {
    if (owner.kind == _ScenarioWarpHandoffKind.playerMove ||
        owner.kind == _ScenarioWarpHandoffKind.leaderMove) {
      final entityId = owner.entityId;
      final pending = entityId == null
          ? null
          : _pendingScenarioMoveContinuationsByEntity[entityId];
      if (pending?.runtimeSourceId == owner.runtimeSourceId) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
      }
    }
    if (owner.runtimeSourceId.startsWith('scenario:')) {
      _cancelNarrativeContinuationBarrier(owner.runtimeSourceId);
    }
  }

  bool _despawnNpcFromActiveMap(
    String entityId, {
    bool keepActiveFollow = false,
  }) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == normalized);
    if (index < 0) {
      return false;
    }

    final updatedEntities = List<MapEntity>.from(entities)..removeAt(index);
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      mapEntityPresencePredicate:
          _mapEntityPresencePredicateFor(_bundle.manifest),
    );
    _bundle = _bundle.copyWith(
      map: updatedMap,
    );

    final loaded = _loadedMapsById[_activeMapId];
    if (loaded != null) {
      _purgeMountedNpcActorForEntity(entityId: normalized, loaded: loaded);
    }

    _scriptedNpcReservedOccupiedCellsByEntity.remove(normalized);
    _runtimeNpcPositions.remove(normalized);
    _triggeredTrainerBattles.remove(normalized);
    if (!keepActiveFollow &&
        _pendingScenarioFollowRequest?.leaderEntityId == normalized) {
      _pendingScenarioFollowRequest = null;
    }
    _pendingScenarioNpcWarpEntries.remove(normalized);
    _pendingScenarioMoveContinuationsByEntity.remove(normalized);
    _scriptedEntityMovementController?.untrackEntity(normalized);
    _syncGameStateFromWorld();
    return true;
  }

  bool _runScenarioFollowCharacter({
    required String leaderEntityId,
  }) {
    _pendingScenarioFollowRequest = _PendingScenarioFollowRequest(
      leaderEntityId: leaderEntityId,
      requestedAtMs: _runtimeClockMs,
    );
    debugPrint(
      '[scenario_runtime] followCharacter activated leader=$leaderEntityId',
    );
    // On traite la première itération immédiatement pour éviter un frame de latence.
    _processPendingScenarioFollowRequest();
    return true;
  }

  void _processPendingScenarioFollowRequest() {
    final pending = _pendingScenarioFollowRequest;
    if (pending == null) {
      return;
    }
    final leaderPos = _resolveScenarioLeaderPosition(pending.leaderEntityId);
    if (leaderPos == null) {
      final pendingWarpHandoff = _pendingScenarioLeaderWarpHandoff;
      if (pendingWarpHandoff != null &&
          pendingWarpHandoff.leaderEntityId == pending.leaderEntityId) {
        return;
      }
      debugPrint(
        '[scenario_runtime] followCharacter canceled leader unresolved=${pending.leaderEntityId}',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: pending.leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final leaderMovement = scriptedNpcMovementStatus(pending.leaderEntityId);
    final leaderTravelDirection = _resolveLeaderTravelDirection(
      pending: pending,
      leaderPos: leaderPos,
      movementStatus: leaderMovement,
    );
    final preferredTrailingSide = leaderTravelDirection == null
        ? null
        : _oppositeDirection(leaderTravelDirection);
    final playerPos = _world.player.pos;
    final playerAdjacentToLeader = _isPosAdjacentToRect(playerPos, leaderRect);

    // Condition de fin:
    // - leader immobile
    // - joueur déjà adjacent au footprint réel du leader.
    if (leaderMovement.state != ScriptedEntityMovementState.moving &&
        playerAdjacentToLeader) {
      debugPrint(
        '[scenario_runtime] followCharacter completed leader=${pending.leaderEntityId} player=(${playerPos.x},${playerPos.y})',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }

    // Si le joueur est déjà en interpolation, on attend le prochain tick.
    if (_player.isStepping) {
      return;
    }

    final canReuseCachedPath = pending.cachedPath != null &&
        pending.cachedPathDestination != null &&
        pending.cachedPathLeaderPos != null &&
        pending.cachedPathLeaderPos!.x == leaderPos.x &&
        pending.cachedPathLeaderPos!.y == leaderPos.y;
    if (canReuseCachedPath) {
      final nextPos = _nextFollowPathStep(
        path: pending.cachedPath!,
        currentPos: playerPos,
      );
      if (nextPos != null) {
        final stepped = _stepPlayerAlongFollowPath(
          leaderEntityId: pending.leaderEntityId,
          leaderPos: leaderPos,
          destination: pending.cachedPathDestination!,
          nextPos: nextPos,
          preferredTrailingSide: preferredTrailingSide,
        );
        if (stepped) {
          pending.consecutiveBlockedSteps = 0;
          return;
        }
        pending.consecutiveBlockedSteps += 1;
        _clearPendingFollowPathCache(pending);
        if (leaderMovement.state != ScriptedEntityMovementState.moving &&
            pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
        return;
      }
      _clearPendingFollowPathCache(pending);
    }

    final followPlan = _resolveFollowPathPlanNearLeader(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      preferredSide: preferredTrailingSide,
      strictPreferredSide:
          leaderMovement.state == ScriptedEntityMovementState.moving,
    );
    if (followPlan == null) {
      if (leaderMovement.state != ScriptedEntityMovementState.moving) {
        pending.consecutiveBlockedSteps += 1;
        if (pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled no reachable trailing path leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
      }
      return;
    }
    pending.consecutiveBlockedSteps = 0;

    // Si on est déjà au meilleur point, on attend la prochaine évolution leader.
    if (followPlan.path.length <= 1 ||
        (followPlan.destination.x == playerPos.x &&
            followPlan.destination.y == playerPos.y)) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    pending.cachedPath = followPlan.path;
    pending.cachedPathDestination = followPlan.destination;
    pending.cachedPathLeaderPos = leaderPos;
    final nextPos = _nextFollowPathStep(
      path: followPlan.path,
      currentPos: playerPos,
    );
    if (nextPos == null) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    final stepped = _stepPlayerAlongFollowPath(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      destination: followPlan.destination,
      nextPos: nextPos,
      preferredTrailingSide: preferredTrailingSide,
    );
    if (!stepped) {
      pending.consecutiveBlockedSteps += 1;
      _clearPendingFollowPathCache(pending);
      if (leaderMovement.state != ScriptedEntityMovementState.moving &&
          pending.consecutiveBlockedSteps >= 10) {
        debugPrint(
          '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
        );
        _pendingScenarioFollowRequest = null;
      }
    }
  }

  bool _stepPlayerAlongFollowPath({
    required String leaderEntityId,
    required GridPos leaderPos,
    required GridPos destination,
    required GridPos nextPos,
    required Direction? preferredTrailingSide,
  }) {
    final currentPos = _world.player.pos;
    final direction = _directionBetweenAdjacent(
      from: currentPos,
      to: nextPos,
    );
    if (direction == null) {
      debugPrint(
        '[scenario_runtime] followCharacter invalid non-adjacent path step leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }

    final followWorld = _buildFollowPlanningWorldIgnoringLeader(
      leaderEntityId: leaderEntityId,
      leaderPos: leaderPos,
    );
    final result = stepGameplayWorld(
      followWorld,
      _fullTileMoveIntent(direction),
    );
    if (result is! Moved) {
      debugPrint(
        '[scenario_runtime] followCharacter path step blocked leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }
    _world = _world.withPlayer(result.world.player);
    _syncGameStateFromWorld();
    _player.startStep(
      _world.player,
      durationSeconds: PlayerComponent.kDefaultStepSeconds,
    );
    _dispatchScenarioTriggerEnterFromMovement(
      previousPos: currentPos,
      currentPos: _world.player.pos,
    );
    debugPrint(
      '[scenario_runtime] followCharacter stepping leader=$leaderEntityId leaderPos=(${leaderPos.x},${leaderPos.y}) trailingSide=${preferredTrailingSide?.name ?? '-'} destination=(${destination.x},${destination.y}) next=(${nextPos.x},${nextPos.y}) playerPos=(${_world.player.pos.x},${_world.player.pos.y})',
    );
    return true;
  }

  bool _runScenarioFaceCharacter({
    required String entityId,
    required String direction,
  }) {
    final facing = _parseEntityFacing(direction);
    if (facing == null) {
      debugPrint(
        '[scenario_runtime] faceCharacter invalid direction="$direction"',
      );
      return false;
    }
    if (entityId == 'player') {
      final next =
          _world.player.copyWith(facing: _directionFromEntityFacing(facing));
      _world = _world.withPlayer(next);
      _syncGameStateFromWorld();
      _player.syncState(_world.player, snapToGrid: true);
      return true;
    }
    final normalizedEntityId = entityId.trim();
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[normalizedEntityId];
    if (actor != null) {
      final movement = scriptedNpcMovementStatus(normalizedEntityId);
      if (movement.state == ScriptedEntityMovementState.moving ||
          actor.isStepping) {
        debugPrint(
          '[scenario_runtime] faceCharacter deferred entity=$normalizedEntityId while moving',
        );
        return true;
      }
      actor.setMotion(facing, CharacterAnimationState.idle);
      return true;
    }

    // Tolérance runtime: si l’entité n’a pas d’acteur visuel actuellement
    // monté (ex: map context différente), on tente au moins de persister
    // l’orientation dans l’état map; sinon on ignore sans bloquer le flow.
    if (_setEntityFacingStateOnly(normalizedEntityId, facing)) {
      debugPrint(
        '[scenario_runtime] faceCharacter applied state-only entity="$normalizedEntityId"',
      );
      return true;
    }
    debugPrint(
      '[scenario_runtime] faceCharacter entity unresolved="$normalizedEntityId" (ignored)',
    );
    return true;
  }

  bool _setEntityFacingStateOnly(String entityId, EntityFacing facing) {
    if (entityId.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return false;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return false;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      mapEntityPresencePredicate:
          _mapEntityPresencePredicateFor(_bundle.manifest),
    );
    _bundle = _bundle.copyWith(
      map: updatedMap,
    );
    _syncGameStateFromWorld();
    return true;
  }

  EntityFacing? _parseEntityFacing(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'north':
        return EntityFacing.north;
      case 'south':
        return EntityFacing.south;
      case 'east':
        return EntityFacing.east;
      case 'west':
        return EntityFacing.west;
      default:
        return null;
    }
  }

  Direction _directionFromEntityFacing(EntityFacing facing) {
    switch (facing) {
      case EntityFacing.north:
        return Direction.north;
      case EntityFacing.south:
        return Direction.south;
      case EntityFacing.east:
        return Direction.east;
      case EntityFacing.west:
        return Direction.west;
    }
  }

  GridPos? _resolveScenarioLeaderPosition(String leaderEntityId) {
    final movementStatus = scriptedNpcMovementStatus(leaderEntityId);
    if (movementStatus.entityId == leaderEntityId &&
        movementStatus.state != ScriptedEntityMovementState.failed) {
      return movementStatus.currentPos;
    }
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[leaderEntityId];
    final actorGridPos = actor?.gridPos;
    if (actorGridPos != null) {
      return actorGridPos;
    }
    final runtimePos = _runtimeNpcPositions[leaderEntityId];
    if (runtimePos != null) {
      return runtimePos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        return entity.pos;
      }
    }
    return null;
  }

  _FollowPathPlan? _resolveFollowPathPlanNearLeader({
    required String leaderEntityId,
    required GridPos leaderPos,
    required Direction? preferredSide,
    required bool strictPreferredSide,
  }) {
    final currentPlayerPos = _world.player.pos;
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final followWorld = _buildFollowPlanningWorldIgnoringLeader(
      leaderEntityId: leaderEntityId,
      leaderPos: leaderPos,
    );
    final candidates = <GridPos>[];
    final preferredCandidates = <GridPos>{};
    if (preferredSide != null) {
      final trailing = _cellsAlongRectSide(leaderRect, preferredSide).toList();
      candidates.addAll(trailing);
      preferredCandidates.addAll(trailing);
    }
    if (!strictPreferredSide) {
      candidates.addAll(_adjacentCellsAroundRect(leaderRect));
    }
    final deduplicated = candidates.toSet().toList(growable: false);
    deduplicated.sort((a, b) {
      final aPreferred = preferredCandidates.contains(a) ? 0 : 1;
      final bPreferred = preferredCandidates.contains(b) ? 0 : 1;
      if (aPreferred != bPreferred) {
        return aPreferred.compareTo(bPreferred);
      }
      final da =
          (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
      final db =
          (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
      return da.compareTo(db);
    });
    for (final candidate in deduplicated) {
      if (!_canPlacePlayerAtForFollow(
        candidate,
        followWorld: followWorld,
        leaderEntityId: leaderEntityId,
      )) {
        continue;
      }
      final path = _computeFollowPlayerPath(
        start: currentPlayerPos,
        goal: candidate,
        followWorld: followWorld,
        leaderEntityId: leaderEntityId,
      );
      if (path == null) {
        continue;
      }
      _lastFollowPathNodeCount = path.length;
      _lastFollowPathDestination = candidate;
      return _FollowPathPlan(
        destination: candidate,
        path: path,
      );
    }

    if (_isPosAdjacentToRect(currentPlayerPos, leaderRect) &&
        _canPlacePlayerAtForFollow(
          currentPlayerPos,
          followWorld: followWorld,
          leaderEntityId: leaderEntityId,
        )) {
      _lastFollowPathNodeCount = 1;
      _lastFollowPathDestination = currentPlayerPos;
      return _FollowPathPlan(
        destination: currentPlayerPos,
        path: <GridPos>[currentPlayerPos],
      );
    }

    // Si la cible "derrière" est impossible en déplacement, on autorise un
    // fallback adjacent pour éviter les blocages durs dans les couloirs.
    if (strictPreferredSide) {
      final relaxedCandidates =
          _adjacentCellsAroundRect(leaderRect).toSet().toList(growable: false);
      relaxedCandidates.sort((a, b) {
        final da =
            (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
        final db =
            (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
        return da.compareTo(db);
      });
      for (final candidate in relaxedCandidates) {
        if (!_canPlacePlayerAtForFollow(
          candidate,
          followWorld: followWorld,
          leaderEntityId: leaderEntityId,
        )) {
          continue;
        }
        final path = _computeFollowPlayerPath(
          start: currentPlayerPos,
          goal: candidate,
          followWorld: followWorld,
          leaderEntityId: leaderEntityId,
        );
        if (path == null) {
          continue;
        }
        _lastFollowPathNodeCount = path.length;
        _lastFollowPathDestination = candidate;
        return _FollowPathPlan(
          destination: candidate,
          path: path,
        );
      }
    }

    if (_isPosAdjacentToRect(currentPlayerPos, leaderRect) &&
        _canPlacePlayerAtForFollow(
          currentPlayerPos,
          followWorld: followWorld,
          leaderEntityId: leaderEntityId,
        )) {
      _lastFollowPathNodeCount = 1;
      _lastFollowPathDestination = currentPlayerPos;
      return _FollowPathPlan(
        destination: currentPlayerPos,
        path: <GridPos>[currentPlayerPos],
      );
    }
    _lastFollowPathNodeCount = 0;
    _lastFollowPathDestination = null;
    return null;
  }

  List<GridPos>? _computeFollowPlayerPath({
    required GridPos start,
    required GridPos goal,
    required GameplayWorldState followWorld,
    required String leaderEntityId,
  }) {
    final result = _followPathfinder.findPath(
      bounds: _world.map.size,
      start: start,
      goal: goal,
      isPassable: (x, y) {
        if (x == start.x && y == start.y) {
          return true;
        }
        final cell = GridPos(x: x, y: y);
        if (!_isWithinMapBounds(_world.map, cell)) {
          return false;
        }
        if (_isCellReservedByScriptedNpc(
          cell,
          ignoreEntityId: leaderEntityId,
        )) {
          return false;
        }
        final trial =
            followWorld.withPlayer(followWorld.player.copyWith(pos: cell));
        return !trial.isBlocked(x, y);
      },
    );
    if (!result.foundPath) {
      return null;
    }
    return result.path;
  }

  Direction? _directionBetweenAdjacent({
    required GridPos from,
    required GridPos to,
  }) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    if (dx == 0 && dy == -1) return Direction.north;
    if (dx == 0 && dy == 1) return Direction.south;
    if (dx == 1 && dy == 0) return Direction.east;
    if (dx == -1 && dy == 0) return Direction.west;
    return null;
  }

  GridPos? _nextFollowPathStep({
    required List<GridPos> path,
    required GridPos currentPos,
  }) {
    if (path.length < 2) {
      return null;
    }
    final currentIndex = path.indexWhere(
      (cell) => cell.x == currentPos.x && cell.y == currentPos.y,
    );
    if (currentIndex < 0 || currentIndex + 1 >= path.length) {
      return null;
    }
    return path[currentIndex + 1];
  }

  void _clearPendingFollowPathCache(_PendingScenarioFollowRequest pending) {
    pending.cachedPath = null;
    pending.cachedPathDestination = null;
    pending.cachedPathLeaderPos = null;
    _lastFollowPathNodeCount = 0;
    _lastFollowPathDestination = null;
  }

  MapRect _resolveScenarioLeaderCollisionFootprint({
    required String leaderEntityId,
    required GridPos fallbackAnchor,
  }) {
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        final footprint = resolveEntityCollisionFootprint(entity);
        final offsetX = footprint.pos.x - entity.pos.x;
        final offsetY = footprint.pos.y - entity.pos.y;
        return MapRect(
          pos: GridPos(
            x: fallbackAnchor.x + offsetX,
            y: fallbackAnchor.y + offsetY,
          ),
          size: footprint.size,
        );
      }
    }
    return MapRect(
      pos: fallbackAnchor,
      size: const GridSize(width: 1, height: 1),
    );
  }

  Iterable<GridPos> _adjacentCellsAroundRect(MapRect rect) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final yielded = <GridPos>{};

    for (var x = left; x <= right; x++) {
      final north = GridPos(x: x, y: top - 1);
      if (yielded.add(north)) {
        yield north;
      }
      final south = GridPos(x: x, y: bottom + 1);
      if (yielded.add(south)) {
        yield south;
      }
    }
    for (var y = top; y <= bottom; y++) {
      final west = GridPos(x: left - 1, y: y);
      if (yielded.add(west)) {
        yield west;
      }
      final east = GridPos(x: right + 1, y: y);
      if (yielded.add(east)) {
        yield east;
      }
    }
  }

  Iterable<GridPos> _cellsAlongRectSide(MapRect rect, Direction side) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    switch (side) {
      case Direction.north:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: top - 1);
        }
      case Direction.south:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: bottom + 1);
        }
      case Direction.east:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: right + 1, y: y);
        }
      case Direction.west:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: left - 1, y: y);
        }
    }
  }

  Direction? _resolveLeaderTravelDirection({
    required _PendingScenarioFollowRequest pending,
    required GridPos leaderPos,
    required ScriptedEntityMovementStatus movementStatus,
  }) {
    final previous = pending.lastLeaderPos;
    pending.lastLeaderPos = leaderPos;
    if (previous != null) {
      final dx = leaderPos.x - previous.x;
      final dy = leaderPos.y - previous.y;
      final fromDelta = _directionFromDelta(dx, dy);
      if (fromDelta != null) {
        pending.lastLeaderTravelDirection = fromDelta;
        return fromDelta;
      }
    }
    if (movementStatus.state == ScriptedEntityMovementState.moving &&
        movementStatus.targetPos != null) {
      final target = movementStatus.targetPos!;
      final dx = target.x - leaderPos.x;
      final dy = target.y - leaderPos.y;
      final fromTargetVector = _directionFromDelta(dx, dy);
      if (fromTargetVector != null) {
        pending.lastLeaderTravelDirection = fromTargetVector;
        return fromTargetVector;
      }
    }
    return pending.lastLeaderTravelDirection;
  }

  Direction? _directionFromDelta(int dx, int dy) {
    if (dx == 0 && dy == 0) {
      return null;
    }
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? Direction.east : Direction.west;
    }
    return dy >= 0 ? Direction.south : Direction.north;
  }

  Direction _oppositeDirection(Direction direction) {
    switch (direction) {
      case Direction.north:
        return Direction.south;
      case Direction.south:
        return Direction.north;
      case Direction.east:
        return Direction.west;
      case Direction.west:
        return Direction.east;
    }
  }

  bool _isPosAdjacentToRect(GridPos pos, MapRect rect) {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final isInside =
        pos.x >= left && pos.x <= right && pos.y >= top && pos.y <= bottom;
    if (isInside) {
      return false;
    }
    final dx =
        pos.x < left ? left - pos.x : (pos.x > right ? pos.x - right : 0);
    final dy =
        pos.y < top ? top - pos.y : (pos.y > bottom ? pos.y - bottom : 0);
    return math.max(dx, dy) == 1;
  }

  GameplayWorldState _buildFollowPlanningWorldIgnoringLeader({
    required String leaderEntityId,
    required GridPos leaderPos,
  }) {
    final normalized = leaderEntityId.trim();
    if (normalized.isEmpty) {
      return _world;
    }
    final index =
        _world.map.entities.indexWhere((entity) => entity.id == normalized);
    if (index < 0) {
      return _world;
    }
    final updatedEntities = List<MapEntity>.from(_world.map.entities);
    final leader = updatedEntities[index];
    updatedEntities[index] = leader.copyWith(
      pos: leaderPos,
      blocksMovement: false,
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    return GameplayWorldState.initial(
      map: updatedMap,
      playerPos: _world.player.pos,
      playerFacing: _world.player.facing,
      playerMovementMode: _world.player.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      mapEntityPresencePredicate:
          _mapEntityPresencePredicateFor(_bundle.manifest),
    );
  }

  bool _canPlacePlayerAtForFollow(
    GridPos pos, {
    required GameplayWorldState followWorld,
    required String leaderEntityId,
  }) {
    if (!_isWithinMapBounds(_world.map, pos)) {
      return false;
    }
    if (_isCellReservedByScriptedNpc(pos, ignoreEntityId: leaderEntityId)) {
      return false;
    }
    final trial = followWorld.withPlayer(followWorld.player.copyWith(pos: pos));
    return !trial.isBlocked(pos.x, pos.y);
  }

  /// Lance un script projet à partir d'un `scriptId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _runScenarioScriptById(
    String scriptId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedScriptId = scriptId.trim();
    if (normalizedScriptId.isEmpty) {
      return false;
    }
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      return false;
    }
    ScriptAsset? scriptAsset;
    for (final entry in _bundle.manifest.scripts) {
      if (entry.id == normalizedScriptId) {
        scriptAsset = entry.asset;
        break;
      }
    }
    if (scriptAsset == null) {
      debugPrint('[scenario_runtime] script not found: $normalizedScriptId');
      return false;
    }
    final source = runtimeSourceId ?? 'scenario';
    _reserveNarrativeContinuationRuntimeSource(source);
    try {
      _startScriptExecution(
        script: scriptAsset,
        startNodeId: startNode,
        runtimeSourceId: source,
      );
    } catch (_) {
      _discardNarrativeContinuationRuntimeSourceReservation(source);
      rethrow;
    }
    return true;
  }

  void _logEncounterCheck(GameplayEncounterCheckResult check) {
    if (!_kVerboseEncounterLogs &&
        check.status != GameplayEncounterCheckStatus.triggered) {
      return;
    }
    final kind = check.encounterKind?.name ?? EncounterKind.walk.name;
    switch (check.status) {
      case GameplayEncounterCheckStatus.noZone:
        debugPrint('[encounter] no compatible zone');
        return;
      case GameplayEncounterCheckStatus.noEncounterTableId:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} has no encounter table id (kind=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.encounterTableNotFound:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} not found',
        );
        return;
      case GameplayEncounterCheckStatus.encounterKindMismatch:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} kind mismatch (expected=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.conditionContextUnavailable:
        debugPrint(
          '[encounter] table=${check.tableId ?? 'unknown'} requires game-state conditions but no context was provided',
        );
        return;
      case GameplayEncounterCheckStatus.conditionsNotMet:
        debugPrint(
          '[encounter] table=${check.tableId ?? 'unknown'} conditions are not met',
        );
        return;
      case GameplayEncounterCheckStatus.invalidEncounterRate:
        debugPrint(
          '[encounter] table=${check.tableId ?? 'unknown'} has an invalid authored rate',
        );
        return;
      case GameplayEncounterCheckStatus.emptyEncounterTable:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} has no valid entries',
        );
        return;
      case GameplayEncounterCheckStatus.rollFailed:
        debugPrint(
          '[encounter] matched zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'}',
        );
        debugPrint(
          '[encounter] rolled no encounter roll=${check.roll?.toStringAsFixed(3) ?? 'n/a'}',
        );
        return;
      case GameplayEncounterCheckStatus.triggered:
        final encounter = check.encounter;
        if (encounter == null) {
          debugPrint('[encounter] triggered status without payload');
          return;
        }
        debugPrint(
          '[encounter] matched zone=${encounter.zoneId} table=${encounter.tableId}',
        );
        debugPrint(
          '[encounter] triggered species=${encounter.speciesId} level=${encounter.level} kind=${encounter.encounterKind.name}',
        );
        return;
    }
  }

  /// Démarre le handoff de combat.
  ///
  /// [request] - La requête de combat (wild ou trainer).
  ///
  /// Cette méthode :
  /// 1. Stocke la requête pour le mapping vers BattleSetup
  /// 2. Passe en phase battleTransition
  /// 3. Affiche l'overlay de transition
  GameState get _battleRuntimeGameState =>
      _activeNarrativeSceneWorkingSession?.gameState ?? _gameState;

  void _replaceBattleRuntimeGameState(GameState gameState) {
    final session = _activeNarrativeSceneWorkingSession;
    if (session != null) {
      session.gameState = gameState;
    } else {
      _gameState = gameState;
    }
  }

  void _startBattleHandoff(BattleStartRequest request) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }
    _setFlowPhase(_RuntimeFlowPhase.battleTransition);
    _notification?.removeFromParent();
    _notification = null;
    _setRuntimeNotificationSnapshot(null);
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _setBattleCommandOverlaySnapshot(null);
    debugPrint(
      '[battle] transition started requestId=${request.requestId} kind=${request.kind.name}',
    );
    final overlay = BattleTransitionOverlayComponent(
      request: request,
      viewportSize: camera.viewport.size,
      onFinished: () {
        // Le mapping vers BattleSetup peut maintenant lire le vrai projet et
        // échouer explicitement. On déclenche donc l'ouverture de manière async
        // au lieu de supposer qu'un setup placeholder sera toujours disponible.
        unawaited(_openBattleOverlay(request));
      },
    );
    camera.viewport.add(overlay);
    _battleTransitionOverlay = overlay;
  }

  /// Ouvre l'overlay de combat après la transition.
  ///
  /// [request] - La requête de combat.
  ///
  /// Cette méthode :
  /// 1. Mappe BattleStartRequest → BattleSetup
  /// 2. Crée la BattleSession
  /// 3. Affiche BattleOverlayComponent avec la session
  Future<void> _openBattleOverlay(BattleStartRequest request) async {
    if (_flowPhase != _RuntimeFlowPhase.battleTransition) {
      return;
    }
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    final battleStopwatch = Stopwatch()..start();
    try {
      await beforeBattleHandoffPreparation?.call();
      if (_flowPhase != _RuntimeFlowPhase.battleTransition) {
        return;
      }
      // BE10 recadré élargit légèrement cet invariant runtime :
      // - on mémorise toujours le slot actif exact utilisé au handoff ;
      // - mais on mémorise aussi l'ordre actif + réserves réellement injecté
      //   dans le combat ;
      // - cela permet ensuite un write-back honnête si le joueur switch.
      //
      // Pourquoi ici :
      // - la sélection se fait sur le vrai GameState runtime, juste avant le
      //   mapping vers BattleSetup ;
      // - on réutilise ensuite ce mapping stable au moment du write-back ;
      // - on évite ainsi le bug classique "recalculer le premier Pokémon
      //   jouable après le combat", qui casserait la cohérence dès qu'un
      //   switch a déplacé l'actif.
      final playerLineup = _traceSync(
        'battle',
        'selectPlayerBattleLineup',
        () => _battleSetupMapper
            .selectPlayerBattleLineup(_battleRuntimeGameState.party),
      );

      PsdkBattleSetup? psdkSetup;
      BattleSetup? setup;
      try {
        // Le bridge PSDK est maintenant le chemin runtime normal dès qu'il
        // peut mapper honnêtement la save et les données projet. Le setup
        // legacy reste uniquement un filet de compatibilité pour les cas que
        // le bridge PSDK ne sait pas encore convertir.
        psdkSetup = await _traceAsync(
          'battle',
          'toPsdkBattleSetup',
          () => _toPsdkBattleSetup(
            request,
            playerPartyIndex: playerLineup.activeIndex,
          ),
        );
      } on RuntimeBattleSetupException catch (psdkSetupError) {
        debugPrint(
          '[battle][psdk] PSDK setup failed, trying legacy bridge: '
          '${psdkSetupError.message} '
          'details=${psdkSetupError.debugDetails ?? 'n/a'}',
        );
        setup = await _traceAsync(
          'battle',
          'toBattleSetup',
          () => _toBattleSetup(
            request,
            playerPartyIndex: playerLineup.activeIndex,
          ),
        );
      }

      // Lot 12 pose le premier write runtime honnête du "seen" :
      // l'espèce ennemie n'est marquée vue qu'une fois le handoff réellement
      // résolu et le combat effectivement prêt à s'ouvrir.
      //
      // On évite volontairement de marquer plus tôt :
      // - une simple case d'herbe ne suffit pas ;
      // - un setup qui échoue ne doit rien écrire ;
      // - aucune capture n'est ouverte ici.
      _replaceBattleRuntimeGameState(_traceSync(
        'battle',
        'markSpeciesSeen',
        () => markSpeciesSeenInGameState(
          _battleRuntimeGameState,
          psdkSetup?.opponent.speciesId ?? setup!.enemyPokemon.speciesId,
        ),
      ));
      _setFlowPhase(_RuntimeFlowPhase.battle);

      // Lot 4 garde le routing de difficulté côté runtime :
      // - la donnée produit vit sur le trainer du projet ;
      // - `map_battle` ne doit recevoir qu'une policy déjà choisie ;
      // - `battle_session.dart` ne redevient donc pas le cerveau de la
      //   difficulté.
      final opponentPolicy = resolveRuntimeTrainerOpponentPolicy(
        request: request,
        manifest: _bundle.manifest,
      );

      if (psdkSetup != null) {
        final psdkOpponentAi = resolveRuntimeTrainerPsdkAi(
          request: request,
          manifest: _bundle.manifest,
        );
        _psdkBattleSession = _traceSync(
          'battle',
          'createPsdkSession',
          () => RuntimePsdkBattleSessionAdapter.fromSetup(
            psdkSetup!,
            opponentAi: psdkOpponentAi,
          ),
        );
        _battleSession = _psdkBattleSession!.createLegacyDisplaySession(
          isTrainerBattle: request is TrainerBattleStartRequest,
          trainerId:
              request is TrainerBattleStartRequest ? request.trainerId : null,
          allowCapture: _battleRequestAllowsCapture(request),
          allowFlee: request.allowsPlayerFlee,
        );
      } else {
        // Créer la session de combat legacy
        _psdkBattleSession = null;
        _battleSession = _traceSync(
          'battle',
          'createSession',
          () => createBattleSession(
            setup!,
            opponentPolicy: opponentPolicy,
          ),
        );
      }
      _activeBattleContext = RuntimeActiveBattleContext.withLineupMapping(
        request: request,
        playerPartyIndex: playerLineup.activeIndex,
        playerPartySlotIndicesByLineupIndex: playerLineup.lineupPartyIndices,
      );
      _captureAttemptReceipt = null;

      // Lot 2 garde la résolution de fond intégralement côté runtime :
      // - le battle-core n'a aucune connaissance de décor ;
      // - on se limite au contexte déjà disponible ici (request + map active) ;
      // - on n'introduit pas encore de resolver contextuel plus large que ce
      //   besoin visible immédiat.
      final backgroundSpec = _traceSync(
        'battle',
        'backgroundResolver',
        () => _battleBackgroundResolver.resolve(
          request: request,
          bundle: _bundle,
        ),
      );
      final genderResolver = await _traceAsync(
        'battle',
        'genderResolver',
        () => buildRuntimeBattleGenderResolver(
          bundle: _bundle,
          gameState: _battleRuntimeGameState,
          request: request,
          playerLineup: playerLineup,
          speciesLoader: _battleSpeciesLoader,
        ),
      );

      // Afficher l'overlay de combat avec la session
      final overlay = _traceSync(
        'battle',
        'overlay',
        () => BattleOverlayComponent(
          session: _battleSession!,
          gameState: _battleRuntimeGameState,
          viewportSize: camera.viewport.size,
          backgroundSpec: backgroundSpec,
          spriteResolver: _battleSpriteResolver,
          visualAssetCache: _battleVisualAssetCache,
          fxBundleCache: _battleFxBundleCache,
          bagItemIconResolver: _battleBagItemIconResolver,
          genderResolver: genderResolver,
          onPlayerChoice: _onPlayerBattleChoice,
          onBagHpHealItemUseRequested: _onBattleBagHpHealItemUseRequested,
          onCommandOverlaySnapshotChanged: (snapshot) {
            _setBattleCommandOverlaySnapshot(snapshot);
          },
          preferTouchListDragScroll: false,
          useFlutterCommandOverlay: _preferBattleFlutterCommandOverlay,
          allowMedicineReserveTargets: true,
        ),
      );
      camera.viewport.add(overlay);
      overlay.setUseFlutterCommandOverlay(_preferBattleFlutterCommandOverlay);
      _battleOverlay = overlay;
      battleStopwatch.stop();
      debugPrint(
          '[perf][battle] total=${battleStopwatch.elapsedMilliseconds}ms');
      debugPrint(
        '[battle] overlay opened requestId=${request.requestId} kind=${request.kind.name}',
      );
    } on RuntimeBattleSetupException catch (error) {
      _cancelBattleHandoff(
        request: request,
        userMessage: error.message,
        debugDetails: error.debugDetails,
      );
    } catch (error, stackTrace) {
      _cancelBattleHandoff(
        request: request,
        userMessage:
            'Impossible de démarrer le combat avec les données locales du projet.',
        debugDetails: '$error\n$stackTrace',
      );
    }
  }

  /// Mappe BattleStartRequest → BattleSetup.
  ///
  /// [request] - La requête de combat depuis le runtime.
  ///
  /// Retourne un BattleSetup pur pour le moteur de combat.
  Future<BattleSetup> _toBattleSetup(
    BattleStartRequest request, {
    int? playerPartyIndex,
  }) {
    return _battleSetupMapper.map(
      bundle: _bundle,
      gameState: _battleRuntimeGameState,
      request: request,
      playerPartyIndex: playerPartyIndex,
    );
  }

  Future<PsdkBattleSetup> _toPsdkBattleSetup(
    BattleStartRequest request, {
    int? playerPartyIndex,
  }) {
    return _psdkBattleSetupMapper.map(
      bundle: _bundle,
      gameState: _battleRuntimeGameState,
      request: request,
      playerPartyIndex: playerPartyIndex,
    );
  }

  bool _battleRequestAllowsCapture(BattleStartRequest? request) {
    return request is WildBattleStartRequest &&
        playerHasAtLeastOneRuntimePokeBall(_battleRuntimeGameState.bag);
  }

  void _cancelBattleHandoff({
    required BattleStartRequest request,
    required String userMessage,
    String? debugDetails,
  }) {
    _completePendingSceneBattleOutcome(
      SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
        message: userMessage,
      ),
    );
    // On nettoie explicitement tout état battle partiellement initialisé.
    // Ce helper évite qu'un mapping KO laisse le runtime coincé en transition.
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _setBattleCommandOverlaySnapshot(null);
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _psdkBattleSession = null;
    _activeBattleContext = null;
    _captureAttemptReceipt = null;
    _isBattleResolving = false;
    _setFlowPhase(_RuntimeFlowPhase.overworld);
    _clearPressedMovementControls();
    final scenarioOwner = _pendingScenarioBattleHandoff;
    if (scenarioOwner?.requestId == request.requestId) {
      _pendingScenarioBattleHandoff = null;
      _cancelNarrativeContinuationBarrier(scenarioOwner!.runtimeSourceId);
    }
    debugPrint(
      '[battle] handoff cancelled message="$userMessage" details=${debugDetails ?? 'n/a'}',
    );
    _showNotification(userMessage);
  }

  void _completePendingSceneBattleOutcome(
    SceneBattleRuntimeOutcomeResult result,
  ) {
    final completer = _pendingSceneBattleOutcomeCompleter;
    if (completer == null) {
      return;
    }
    final requestId = _pendingSceneBattleRequestId;
    _pendingSceneBattleOutcomeCompleter = null;
    _pendingSceneBattleRequestId = null;
    if (!completer.isCompleted) {
      completer.complete(result);
    }
    debugPrint(
      '[scene_runtime] battle outcome completed request=${requestId ?? '-'} '
      'status=${result.status.name} port=${result.scenePortId ?? '-'}',
    );
  }

  SceneBattleRuntimeOutcomeResult _sceneBattleRuntimeOutcomeFromBattle(
    BattleOutcome outcome,
  ) {
    return switch (outcome.type) {
      BattleOutcomeType.victory =>
        const SceneBattleRuntimeOutcomeResult.completed(
          port: SceneBattleRuntimeOutcomePort.victory,
        ),
      BattleOutcomeType.defeat =>
        const SceneBattleRuntimeOutcomeResult.completed(
          port: SceneBattleRuntimeOutcomePort.defeat,
        ),
      BattleOutcomeType.runaway => const SceneBattleRuntimeOutcomeResult.failed(
          errorCode: SceneBattleRuntimeOutcomeErrorCode.unsupportedOutcome,
          message: 'Scene trainer battle does not support runaway outcome.',
        ),
      BattleOutcomeType.captured =>
        const SceneBattleRuntimeOutcomeResult.failed(
          errorCode: SceneBattleRuntimeOutcomeErrorCode.unsupportedOutcome,
          message: 'Scene trainer battle does not support captured outcome.',
        ),
    };
  }

  /// Gère le choix du joueur pendant le combat.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode :
  /// 1. Applique le choix via BattleSession.applyChoice()
  /// 2. Met à jour l'UI
  /// 3. Vérifie si le combat est fini
  /// 4. Si fini, attend la présentation finale puis appelle _onBattleFinished()
  ///
  /// **Lock anti-spam** : `_isBattleResolving` empêche le spam clavier
  /// pendant la résolution d'un tour.
  void _onPlayerBattleChoice(PlayerBattleChoice choice) {
    if (_battleSession == null) {
      return;
    }

    // Lock anti-spam : empêcher traitement multiple pendant résolution
    if (_isBattleResolving) {
      debugPrint('[battle] choice ignored: already resolving');
      return;
    }
    _isBattleResolving = true;
    var battleFinishDeferred = false;

    try {
      final psdkSession = _psdkBattleSession;
      if (psdkSession != null) {
        final request = _activeBattleContext?.request;
        final isTrainerBattle = request is TrainerBattleStartRequest;
        final trainerId = isTrainerBattle ? request.trainerId : null;
        if (choice is PlayerBattleChoiceCapture) {
          final activeContext = _activeBattleContext;
          if (activeContext == null) {
            throw StateError(
                'Capture requires an active runtime battle context.');
          }
          final submission = submitRuntimeBattleCaptureAttempt(
            gameState: _battleRuntimeGameState,
            context: activeContext,
            captureAllowed: psdkSession.decisionRequest.allows(
              const BattleDecision.capture(
                itemId: canonicalPokeBallItemId,
              ),
            ),
            submitToEngine: () => psdkSession.submitPlayerChoice(choice),
          );
          _replaceBattleRuntimeGameState(submission.updatedGameState);
          _captureAttemptReceipt = submission.receipt;
          _battleSession = psdkSession.createLegacyDisplaySession(
            isTrainerBattle: isTrainerBattle,
            trainerId: trainerId,
            allowCapture: _battleRequestAllowsCapture(request),
            allowFlee: request?.allowsPlayerFlee ?? false,
          );
        } else {
          psdkSession.submitPlayerChoice(choice);
          _battleSession = psdkSession.createLegacyDisplaySession(
            isTrainerBattle: isTrainerBattle,
            trainerId: trainerId,
            allowCapture: _battleRequestAllowsCapture(request),
            allowFlee: request?.allowsPlayerFlee ?? false,
          );
        }
      } else {
        if (choice is PlayerBattleChoiceCapture) {
          final activeContext = _activeBattleContext;
          if (activeContext == null) {
            throw StateError(
                'Capture requires an active runtime battle context.');
          }
          final submission = submitRuntimeBattleCaptureAttempt(
            gameState: _battleRuntimeGameState,
            context: activeContext,
            captureAllowed: _battleSession!.decisionRequest.allows(choice),
            submitToEngine: () => _battleSession!.applyChoice(choice),
          );
          _replaceBattleRuntimeGameState(submission.updatedGameState);
          _captureAttemptReceipt = submission.receipt;
          _battleSession = submission.engineResult;
        } else {
          // Appliquer le choix (retourne une nouvelle session immutable)
          _battleSession = _battleSession!.applyChoice(choice);
        }
      }

      // Mettre à jour l'UI avec le nouvel état
      final overlay = _battleOverlay;
      overlay?.updateState(
        _battleSession!,
        gameState: _battleRuntimeGameState,
      );

      // Vérifier si le combat est fini
      if (psdkSession != null && psdkSession.state.isFinished) {
        battleFinishDeferred = true;
        final request = _activeBattleContext?.request;
        final isTrainerBattle = request is TrainerBattleStartRequest;
        final trainerId = isTrainerBattle ? request.trainerId : null;
        unawaited(
          _finishBattleAfterPresentation(
            finishedSession: _battleSession!,
            overlay: overlay,
            outcome: psdkSession.createLegacyOutcome(
              isTrainerBattle: isTrainerBattle,
              trainerId: trainerId,
            ),
          ),
        );
      } else if (_battleSession!.state.isFinished) {
        battleFinishDeferred = true;
        unawaited(
          _finishBattleAfterPresentation(
            finishedSession: _battleSession!,
            overlay: overlay,
            outcome: _battleSession!.state.outcome!,
          ),
        );
      }
    } finally {
      // Unlock après résolution. En fin de combat, on garde le lock jusqu'à
      // la narration finale pour éviter un input entre deux états visuels.
      if (_flowPhase == _RuntimeFlowPhase.battle && !battleFinishDeferred) {
        _isBattleResolving = false;
      }
    }
  }

  bool _onBattleBagHpHealItemUseRequested(
    BattleBagMenuActionMedicineTarget action,
    BattleMedicineTargetEntry entry,
  ) {
    final battleSession = _battleSession;
    final activeBattleContext = _activeBattleContext;
    if (battleSession == null || activeBattleContext == null) {
      return false;
    }

    if (_isBattleResolving) {
      debugPrint('[battle] bag hp-heal item ignored: already resolving');
      return false;
    }

    _isBattleResolving = true;
    var battleFinishDeferred = false;
    try {
      final psdkSession = _psdkBattleSession;
      if (psdkSession != null) {
        final request = activeBattleContext.request;
        final isTrainerBattle = request is TrainerBattleStartRequest;
        final trainerId = isTrainerBattle ? request.trainerId : null;
        final result = tryApplyRuntimePsdkBattleItemUse(
          psdkSession: psdkSession,
          displaySession: battleSession,
          gameState: _battleRuntimeGameState,
          context: activeBattleContext,
          itemId: action.itemId,
          targetLineupIndex: entry.lineupIndex,
          isTrainerBattle: isTrainerBattle,
          trainerId: trainerId,
          allowCapture: _battleRequestAllowsCapture(request),
        );
        if (result == null) {
          return false;
        }

        _battleSession = result.updatedDisplaySession;
        _replaceBattleRuntimeGameState(result.updatedGameState);
        final overlay = _battleOverlay;
        overlay?.updateState(
          _battleSession!,
          gameState: _battleRuntimeGameState,
        );

        if (psdkSession.state.isFinished) {
          battleFinishDeferred = true;
          unawaited(
            _finishBattleAfterPresentation(
              finishedSession: _battleSession!,
              overlay: overlay,
              outcome: psdkSession.createLegacyOutcome(
                isTrainerBattle: isTrainerBattle,
                trainerId: trainerId,
              ),
            ),
          );
        } else if (_flowPhase == _RuntimeFlowPhase.battle) {
          _isBattleResolving = false;
        }

        return true;
      }

      // Lots 9-e à 9-h gardent `PlayableMapGame` comme propriétaire honnête
      // du runtime autour du moteur battle :
      // - le moteur battle produit un `currentTurn` et une timeline honnêtes ;
      // - le runtime reste propriétaire du bag réel et du write-back party ;
      // - on reste borné à `Potion` + `Super Potion` + `Hyper Potion` + `Max Potion`,
      //   sans API item générique.
      final result = switch (action.itemId) {
        'potion' => tryApplyRuntimeBattlePotionUse(
            session: battleSession,
            gameState: _battleRuntimeGameState,
            context: activeBattleContext,
            targetLineupIndex: entry.lineupIndex,
          ),
        'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
            session: battleSession,
            gameState: _battleRuntimeGameState,
            context: activeBattleContext,
            targetLineupIndex: entry.lineupIndex,
          ),
        'hyper-potion' => tryApplyRuntimeBattleHyperPotionUse(
            session: battleSession,
            gameState: _battleRuntimeGameState,
            context: activeBattleContext,
            targetLineupIndex: entry.lineupIndex,
          ),
        'max-potion' => tryApplyRuntimeBattleMaxPotionUse(
            session: battleSession,
            gameState: _battleRuntimeGameState,
            context: activeBattleContext,
            targetLineupIndex: entry.lineupIndex,
          ),
        _ => null,
      };
      if (result == null) {
        return false;
      }

      _battleSession = result.updatedSession;
      _replaceBattleRuntimeGameState(result.updatedGameState);
      _battleOverlay?.updateState(
        _battleSession!,
        gameState: _battleRuntimeGameState,
      );

      if (_battleSession!.state.isFinished) {
        battleFinishDeferred = true;
        unawaited(
          _finishBattleAfterPresentation(
            finishedSession: _battleSession!,
            overlay: _battleOverlay,
            outcome: _battleSession!.state.outcome!,
          ),
        );
      } else if (_flowPhase == _RuntimeFlowPhase.battle) {
        _isBattleResolving = false;
      }

      return true;
    } finally {
      if (_flowPhase == _RuntimeFlowPhase.battle &&
          !battleFinishDeferred &&
          !(_battleSession?.state.isFinished ?? false)) {
        _isBattleResolving = false;
      }
    }
  }

  Future<void> _finishBattleAfterPresentation({
    required BattleSession finishedSession,
    required BattleOverlayComponent? overlay,
    required BattleOutcome outcome,
  }) async {
    try {
      await (overlay?.waitForTurnPresentationComplete() ??
          Future<void>.value());
    } catch (error, stackTrace) {
      debugPrint(
        '[battle] final presentation failed; finishing battle anyway: $error\n$stackTrace',
      );
    }

    if (_flowPhase != _RuntimeFlowPhase.battle ||
        !identical(_battleSession, finishedSession) ||
        _battleOverlay != overlay) {
      return;
    }
    await _beginPostBattleFlow(outcome);
  }

  Future<void> _beginPostBattleFlow(BattleOutcome outcome) async {
    final activeBattleContext = _activeBattleContext;
    if (_flowPhase != _RuntimeFlowPhase.battle ||
        activeBattleContext == null ||
        _isPostBattleFlowRunning) {
      return;
    }

    _isPostBattleFlowRunning = true;
    _isPostBattleCommitCompleted = false;
    _isBattleResolving = true;
    _postBattleInputLock ??= _inputLocks.acquire(
      owner: RuntimeInputLockOwner.postBattleProgression,
      surface: RuntimeInputSurface.progression,
    );
    _battleOverlay?.lockForPostBattle();
    _setBattleCommandOverlaySnapshot(null);
    final generation = ++_postBattleFlowGeneration;
    final completer = Completer<void>();
    _postBattleFlowCompleter = completer;
    _postBattleCompletionFuture = completer.future;

    try {
      final psdkState = _psdkBattleSession?.state.psdkState;
      final transactionBaseState = psdkState == null
          ? _battleRuntimeGameState
          : writePlayerPsdkHeldItemsBackToPartySlots(
              gameState: _battleRuntimeGameState,
              context: activeBattleContext,
              psdkState: psdkState,
            );
      final result = await _postBattleDecisionCoordinator.begin(
        transactionBaseState: transactionBaseState,
        bundle: _bundle,
        runtimeContext: activeBattleContext,
        outcome: outcome,
        captureAttemptReceipt: _captureAttemptReceipt,
      );
      if (generation != _postBattleFlowGeneration ||
          _flowPhase != _RuntimeFlowPhase.battle ||
          !identical(_activeBattleContext, activeBattleContext)) {
        return;
      }

      late final PostBattleProgressionOverlayComponent postBattleOverlay;
      postBattleOverlay = PostBattleProgressionOverlayComponent(
        initialResult: result,
        viewportSize: camera.viewport.size,
        renderInFlame: !_preferPostBattleFlutterOverlay,
        onPresentationSnapshotChanged: _setPostBattlePresentationSnapshot,
        onMoveLearningDecision: (decision) {
          final transaction = postBattleOverlay.currentTransaction;
          if (transaction == null) {
            return result;
          }
          return _postBattleDecisionCoordinator.resolveMoveLearning(
            transaction: transaction,
            decision: decision,
          );
        },
        onEvolutionDecision: (decision) {
          final transaction = postBattleOverlay.currentTransaction;
          if (transaction == null) {
            return result;
          }
          return _postBattleDecisionCoordinator.resolveEvolution(
            transaction: transaction,
            decision: decision,
          );
        },
        onCompleted: () => _completePostBattleFlow(
          overlay: postBattleOverlay,
          outcome: outcome,
        ),
      );
      _postBattleProgressionOverlay = postBattleOverlay;
      final mounter = postBattleOverlayMounter;
      if (mounter == null) {
        await camera.viewport.add(postBattleOverlay);
      } else {
        await mounter(postBattleOverlay);
      }
      if (generation != _postBattleFlowGeneration ||
          _flowPhase != _RuntimeFlowPhase.battle ||
          !identical(_activeBattleContext, activeBattleContext)) {
        postBattleOverlay.removeFromParent();
        if (identical(_postBattleProgressionOverlay, postBattleOverlay)) {
          _postBattleProgressionOverlay = null;
          _setPostBattlePresentationSnapshot(null);
        }
      }
    } catch (error, stackTrace) {
      if (generation != _postBattleFlowGeneration ||
          !identical(_activeBattleContext, activeBattleContext)) {
        return;
      }
      _rollbackPostBattleAfterException(
        outcome: outcome,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _completePostBattleFlow({
    required PostBattleProgressionOverlayComponent overlay,
    required BattleOutcome outcome,
  }) {
    if (!_isPostBattleFlowRunning ||
        _isPostBattleCommitCompleted ||
        !identical(_postBattleProgressionOverlay, overlay)) {
      return;
    }
    _isPostBattleCommitCompleted = true;

    try {
      final failure = overlay.currentFailure;
      final finalState = overlay.currentTransaction?.finalState;
      final failed = failure != null || finalState == null;
      if (failed) {
        _showNotification(
          failure?.message ?? 'La fin du combat ne peut pas être appliquée.',
        );
      } else {
        beforePostBattleStateCommit?.call();
      }
      _onBattleFinished(
        outcome,
        postBattleFinalState: failed ? null : finalState,
        postBattleFailed: failed,
      );
    } catch (error, stackTrace) {
      _rollbackPostBattleAfterException(
        outcome: outcome,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _rollbackPostBattleAfterException({
    required BattleOutcome outcome,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint(
      '[battle] post-battle transaction rolled back: $error\n$stackTrace',
    );
    _showNotification('La fin du combat ne peut pas être appliquée.');
    try {
      _onBattleFinished(outcome, postBattleFailed: true);
    } catch (cleanupError, cleanupStackTrace) {
      debugPrint(
        '[battle] post-battle cleanup failed: '
        '$cleanupError\n$cleanupStackTrace',
      );
      _forcePostBattleCleanup();
    }
  }

  void _forcePostBattleCleanup() {
    final scenarioOwner = _pendingScenarioBattleHandoff;
    if (scenarioOwner != null) {
      _pendingScenarioBattleHandoff = null;
      _cancelNarrativeContinuationBarrier(scenarioOwner.runtimeSourceId);
    }
    _completePendingSceneBattleOutcome(
      const SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
        message: 'Post-battle cleanup failed.',
      ),
    );
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _postBattleProgressionOverlay?.removeFromParent();
    _postBattleProgressionOverlay = null;
    _setPostBattlePresentationSnapshot(null);
    _setBattleCommandOverlaySnapshot(null);
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _psdkBattleSession = null;
    _activeBattleContext = null;
    _captureAttemptReceipt = null;
    _isBattleResolving = false;
    _isPostBattleFlowRunning = false;
    _isPostBattleCommitCompleted = false;
    _releasePostBattleInputLock();
    _setFlowPhase(_RuntimeFlowPhase.overworld);
    _clearPressedMovementControls();
    final postBattleCompleter = _postBattleFlowCompleter;
    if (postBattleCompleter != null && !postBattleCompleter.isCompleted) {
      postBattleCompleter.complete();
    }
  }

  /// Gère la fin du combat.
  ///
  /// [outcome] - Le résultat du combat.
  ///
  /// Cette méthode :
  /// 1. Applique le résultat au vrai GameState runtime
  /// 2. Nettoie l'overlay (SUPPRIME du parent)
  /// 3. Retourne à l'overworld
  void _onBattleFinished(
    BattleOutcome outcome, {
    GameState? postBattleFinalState,
    bool postBattleFailed = false,
  }) {
    debugPrint('[battle] battle finished outcome=${outcome.type.name}');
    final sceneBattleOutcomeResult = _pendingSceneBattleOutcomeCompleter == null
        ? null
        : postBattleFailed
            ? const SceneBattleRuntimeOutcomeResult.failed(
                errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
                message: 'Post-battle transaction failed.',
              )
            : _sceneBattleRuntimeOutcomeFromBattle(outcome);
    final hostedByNarrativeScene = sceneBattleOutcomeResult != null &&
        _activeNarrativeSceneWorkingSession != null;

    // Le lot 10 normalise ici tout le write-back post-combat :
    // - PV du lineup joueur écrits sur les slots exacts mémorisés ;
    // - flag trainer_defeated uniquement sur une vraie victoire trainer ;
    // - aucune tentative de recalcul du Pokémon actif après la fin du combat.
    final activeBattleContext = _activeBattleContext;
    final qualifiedStandaloneOutcome = !postBattleFailed &&
            !hostedByNarrativeScene &&
            activeBattleContext != null &&
            activeBattleContext.request is TrainerBattleStartRequest
        ? _qualifiedStandaloneTrainerBattleOutcome(
            activeBattleContext.request as TrainerBattleStartRequest,
            outcome,
          )
        : null;
    if (activeBattleContext != null) {
      final previousState = _battleRuntimeGameState;
      if (postBattleFinalState != null) {
        commitRuntimeBattleCaptureAttemptReceipt(
          context: activeBattleContext,
          outcome: outcome,
          receipt: _captureAttemptReceipt,
        );
        _replaceBattleRuntimeGameState(postBattleFinalState);
      } else if (!postBattleFailed) {
        _replaceBattleRuntimeGameState(applyRuntimeBattleOutcomeToGameState(
          gameState: _battleRuntimeGameState,
          context: activeBattleContext,
          outcome: outcome,
          captureAttemptReceipt: _captureAttemptReceipt,
          storyFlagsManager: _storyFlags,
        ));
      }

      if (outcome.isDefeat && !postBattleFailed) {
        if (hostedByNarrativeScene) {
          _replaceBattleRuntimeGameState(
            applyRuntimeDefeatRecoveryToGameState(
              gameState: _battleRuntimeGameState,
              playerPartyIndex: activeBattleContext.playerPartyIndex,
              activePlayerLineupIndex: outcome.finalState.player.lineupIndex,
              playerPartySlotIndicesByLineupIndex:
                  activeBattleContext.playerPartySlotIndicesByLineupIndex,
            ),
          );
        }
      }

      if (!postBattleFailed &&
          outcome.isVictory &&
          activeBattleContext.request is TrainerBattleStartRequest) {
        final trainerRequest =
            activeBattleContext.request as TrainerBattleStartRequest;
        debugPrint(
          '[battle] trainer marked as defeated: ${trainerRequest.trainerId}',
        );
      }

      // On ne refresh la présence PNJ que si les story flags ont réellement
      // changé ; cela garde le retour overworld minimal pour wild/defeat/run.
      final updatedState = _battleRuntimeGameState;
      if (!hostedByNarrativeScene &&
          !identical(previousState.storyFlags, updatedState.storyFlags) &&
          previousState.storyFlags != updatedState.storyFlags) {
        _refreshWorldNpcPresence();
      }
    }

    // Nettoyer et retourner à l'overworld
    // IMPORTANT: Il faut SUPPRIMER l'overlay du parent, pas juste mettre à null
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _postBattleProgressionOverlay?.removeFromParent();
    _postBattleProgressionOverlay = null;
    _setPostBattlePresentationSnapshot(null);
    _setBattleCommandOverlaySnapshot(null);
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _psdkBattleSession = null;
    _activeBattleContext = null;
    _captureAttemptReceipt = null;
    _isBattleResolving = false; // Reset lock anti-spam
    _isPostBattleFlowRunning = false;
    _isPostBattleCommitCompleted = false;
    _releasePostBattleInputLock();
    final postBattleCompleter = _postBattleFlowCompleter;
    if (postBattleCompleter != null && !postBattleCompleter.isCompleted) {
      postBattleCompleter.complete();
    }
    // NOTE: NE PAS clear _triggeredTrainerBattles ici!
    // Le lock doit rester actif tant que le joueur est dans la LoS du trainer.
    // Si on clear le lock ici, le trainer sera re-déclenché immédiatement
    // car le joueur est probablement encore dans sa zone de LoS.
    //
    // Le lock sera clear automatiquement quand le joueur quittera la LoS,
    // via le mécanisme de réarmement dans _checkTrainerLineOfSight():
    //   if (_triggeredTrainerBattles.contains(entity.id)) {
    //     if (!inLoS) _triggeredTrainerBattles.remove(entity.id);
    //   }
    //
    // Pour un trainer one-shot, le flag defeated bloque aussi tout nouveau
    // combat. Pour un rematch authorisé, le lock LoS reste la protection
    // immédiate : le joueur doit quitter puis réentrer dans la zone.

    // [SEL-B2] Si ce combat a été lancé depuis un node scénario
    // startTrainerBattle, on pose le flag d'outcome déterministe et on
    // reprend le graphe après le node battle.
    final scenarioOwner = _pendingScenarioBattleHandoff;
    MapEntity? directPostBattleDialogueNpc;
    DialogueRef? directPostBattleDialogueRef;
    if (!postBattleFailed &&
        scenarioOwner == null &&
        sceneBattleOutcomeResult == null &&
        activeBattleContext?.request is TrainerBattleStartRequest) {
      final trainerRequest =
          activeBattleContext!.request as TrainerBattleStartRequest;
      final npc = _world.map.entities.cast<MapEntity?>().firstWhere(
            (entity) => entity?.id == trainerRequest.npcEntityId,
            orElse: () => null,
          );
      final trainer =
          _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
                (entry) => entry?.id == trainerRequest.trainerId,
                orElse: () => null,
              );
      final result = switch (outcome.type) {
        BattleOutcomeType.victory => RuntimeTrainerPostBattleResult.victory,
        BattleOutcomeType.defeat => RuntimeTrainerPostBattleResult.defeat,
        BattleOutcomeType.runaway || BattleOutcomeType.captured => null,
      };
      if (npc?.npc != null && trainer != null && result != null) {
        directPostBattleDialogueNpc = npc;
        directPostBattleDialogueRef = resolveRuntimeTrainerPostBattleDialogue(
          trainer: trainer,
          npc: npc!.npc!,
          result: result,
        );
      }
    }
    if (postBattleFailed &&
        scenarioOwner != null &&
        scenarioOwner.requestId == activeBattleContext?.request.requestId) {
      _pendingScenarioBattleHandoff = null;
      _cancelNarrativeContinuationBarrier(scenarioOwner.runtimeSourceId);
    }
    if (scenarioOwner != null &&
        !postBattleFailed &&
        scenarioOwner.requestId == activeBattleContext?.request.requestId &&
        sceneBattleOutcomeResult == null) {
      // 1. Poser le flag d'outcome déterministe.
      final String outcomeSuffix;
      switch (outcome.type) {
        case BattleOutcomeType.victory:
          outcomeSuffix = kBattleOutcomeSuffixVictory;
        case BattleOutcomeType.defeat:
          outcomeSuffix = kBattleOutcomeSuffixDefeat;
        case BattleOutcomeType.runaway:
          outcomeSuffix = kBattleOutcomeSuffixFlee;
        case BattleOutcomeType.captured:
          outcomeSuffix = kBattleOutcomeSuffixCaptured;
      }
      final flagName = scenarioBattleOutcomeFlagName(
        scenarioOwner.battleId,
        outcomeSuffix,
      );
      final nextState = _storyFlags.set(_gameState, flagName);
      _gameState = nextState;
      debugPrint(
        '[scenario_runtime] battle outcome flag set: $flagName',
      );

      // 2. Nettoyer le pending avant de reprendre le graphe.
      _pendingScenarioBattleHandoff = null;

      // 3. Reprendre le graphe scénario après le node battle.
      // On remet d'abord en overworld pour que la continuation puisse
      // redispatcher sans être bloquée par le flow phase guard.
      _setFlowPhase(_RuntimeFlowPhase.overworld);
      _clearPressedMovementControls();
      _prewarmActiveMapBattleData();
      _refreshWorldNpcPresence();

      _scheduleNarrativeContinuationAdvance(
        scenarioOwner.runtimeSourceId,
        effectOutcomes: <NarrativeOutcomeRef>[
          if (qualifiedStandaloneOutcome != null) qualifiedStandaloneOutcome,
        ],
      );
      debugPrint(
        '[scenario_runtime] battle from scene completed: '
        'battleId=${scenarioOwner.battleId} outcome=${outcome.type.name}',
      );
      return;
    }

    _setFlowPhase(_RuntimeFlowPhase.overworld);
    _clearPressedMovementControls();
    _prewarmActiveMapBattleData();
    if (sceneBattleOutcomeResult != null) {
      _completePendingSceneBattleOutcome(sceneBattleOutcomeResult);
    }
    var standaloneFlowCompletionScheduled = false;
    void completeStandaloneFlowOnce() {
      if (standaloneFlowCompletionScheduled) {
        return;
      }
      standaloneFlowCompletionScheduled = true;
      if (outcome.isDefeat &&
          !hostedByNarrativeScene &&
          activeBattleContext != null) {
        _startDefeatRecovery(
          activeBattleContext,
          activePlayerLineupIndex: outcome.finalState.player.lineupIndex,
        );
      }
      _scheduleRootNarrativeOutcomePublication(qualifiedStandaloneOutcome);
    }

    final postBattleNpc = directPostBattleDialogueNpc;
    final postBattleDialogue = directPostBattleDialogueRef;
    if (postBattleNpc != null && postBattleDialogue != null) {
      // Le loader peut échouer de façon synchrone ou asynchrone. Le guard
      // local garantit que la suite du flow (éventuel whiteout puis outcome)
      // n'est lancée qu'une fois, même si `_tryOpenDialogue` retourne `false`.
      _pendingPostDialogueAction = completeStandaloneFlowOnce;
      final dialogueStarted = _tryOpenDialogue(
        postBattleNpc.id,
        postBattleDialogue,
        postBattleNpc.inspectorHeadline,
        allowAbsentEntity: true,
        onLoadFailed: completeStandaloneFlowOnce,
      );
      if (dialogueStarted) {
        debugPrint(
          '[trainer] post-battle dialogue opened npc=${postBattleNpc.id}',
        );
        return;
      }
      _pendingPostDialogueAction = null;
    }
    completeStandaloneFlowOnce();
    debugPrint('[battle] overworld resumed');
  }

  NarrativeOutcomeRef? _qualifiedStandaloneTrainerBattleOutcome(
    TrainerBattleStartRequest request,
    BattleOutcome outcome,
  ) {
    final outcomeId = switch (outcome.type) {
      BattleOutcomeType.victory => 'victory',
      BattleOutcomeType.defeat => 'defeat',
      BattleOutcomeType.runaway || BattleOutcomeType.captured => null,
    };
    if (outcomeId == null) {
      return null;
    }
    return _qualifiedTrainerBattleOutcome(request.trainerId, outcomeId);
  }

  void _scheduleRootNarrativeOutcomePublication(
    NarrativeOutcomeRef? outcome,
  ) {
    _scheduleNarrativeOutcomePublication(outcome);
  }

  void _scheduleNarrativeOutcomePublication(
    NarrativeOutcomeRef? outcome, {
    _NarrativeOutcomeContinuationContext? continuation,
  }) {
    if (outcome == null) {
      return;
    }
    _scheduleNarrativeOutcomesPublication(
      <NarrativeOutcomeRef>[outcome],
      continuation: continuation,
    );
  }

  void _scheduleNarrativeOutcomesPublication(
    List<NarrativeOutcomeRef> outcomes, {
    _NarrativeOutcomeContinuationContext? continuation,
  }) {
    if (outcomes.isEmpty) {
      return;
    }
    unawaited(
      _publishNarrativeOutcomesSafely(
        outcomes,
        continuation: continuation,
      ),
    );
  }

  Future<bool> _publishNarrativeOutcomesSafely(
    List<NarrativeOutcomeRef> outcomes, {
    _NarrativeOutcomeContinuationContext? continuation,
  }) async {
    if (outcomes.isEmpty) {
      return true;
    }
    final publication = continuation == null
        ? _publishRootNarrativeOutcomes(outcomes)
        : _publishNarrativeOutcomes(
            outcomes,
            causationId: continuation.causationId,
            correlationId: continuation.correlationId,
            depth: continuation.depth,
          );
    try {
      await publication;
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[event_v2] outcome publication failed: $error\n$stackTrace',
      );
      _showNotification('Résultat narratif impossible.');
      return false;
    }
  }

  void _startDefeatRecovery(
    RuntimeActiveBattleContext battleContext, {
    required int activePlayerLineupIndex,
  }) {
    _clearPressedMovementControls();
    _defeatRecoveryFuture = _applyDefeatRecovery(
      battleContext,
      activePlayerLineupIndex: activePlayerLineupIndex,
    );
    unawaited(_defeatRecoveryFuture);
  }

  Future<void> _applyDefeatRecovery(
    RuntimeActiveBattleContext battleContext, {
    required int activePlayerLineupIndex,
  }) async {
    final recoveryLock = _inputLocks.acquire(
      owner: RuntimeInputLockOwner.checkpoint,
      surface: RuntimeInputSurface.transition,
    );
    try {
      final fallbackPoint = await _resolveDefeatFallbackPoint(battleContext);
      final capsLoader = defeatRecoveryCapsLoader;
      final caps = capsLoader == null
          ? await loadRuntimePlayerServiceRecoveryCaps(
              gameState: _gameState,
              projectRootDirectory: _bundle.projectRootDirectory,
              pokemonConfig: _bundle.manifest.pokemon,
              speciesLoader: _battleSpeciesLoader,
              moveCatalogLoader: _battleMoveCatalogLoader,
            )
          : await capsLoader(_gameState);
      final recovery = applyPlayerDefeatRecovery(
        state: _gameState,
        fallbackPoint: fallbackPoint,
        maxHpByPartyIndex: caps.maxHpByPartyIndex,
        maxPpByPartyIndex: caps.maxPpByPartyIndex,
      );
      final sourceMapId = _activeMapId;
      if (recovery.recoveryPoint.mapId == sourceMapId) {
        _gameState = recovery.state;
        _world = _buildSafeWorldState(
          map: _bundle.map,
          project: _bundle.manifest,
          preferredPos: recovery.recoveryPoint.position,
          fallbackFacing: recovery.recoveryPoint.facing.asDirection,
          tileWidth: _bundle.manifest.settings.tileWidth,
          tileHeight: _bundle.manifest.settings.tileHeight,
        );
        _player.syncState(_world.player, snapToGrid: true);
        _syncGameStateFromWorld(mapIdOverride: _activeMapId);
        _configureCameraViewport();
        _syncCameraToPlayer();
        _preloadActiveMapConnections();
        _prewarmActiveMapBattleData();
        _pruneLoadedMapsToActiveNeighborhood();
        _resetTriggerEnterOccupancy();
        _refreshWorldNpcPresence();
        _setFlowPhase(_RuntimeFlowPhase.overworld);
      } else {
        _gameState = recovery.state.copyWith(
          currentMapId: sourceMapId,
          playerPosition: _world.player.pos,
          playerFacing: _world.player.facing.asFacing,
        );
        _setFlowPhase(_RuntimeFlowPhase.overworld);
        await _handleWarp(
          TriggeredWarp(
            warpId: 'runtime:whiteout-recovery',
            targetMapId: recovery.recoveryPoint.mapId,
            targetPos: recovery.recoveryPoint.position,
            triggerMode: MapWarpTriggerMode.onEnter,
          ),
        );
        _world = _world.withPlayer(
          _gridAlignedPlayerState(
            position: _world.player.pos,
            facing: recovery.recoveryPoint.facing.asDirection,
            movementMode: MovementMode.walk,
          ),
        );
        _player.syncState(_world.player, snapToGrid: true);
        _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      }
      _showNotification(_defeatRecoveryMessage(recovery.moneyLost));
      await defeatRecoveryCheckpointEmitter?.call();
    } catch (error, stackTrace) {
      debugPrint('[whiteout] recovery failed: $error\n$stackTrace');
      _gameState = applyRuntimeDefeatRecoveryToGameState(
        gameState: _gameState,
        playerPartyIndex: battleContext.playerPartyIndex,
        activePlayerLineupIndex: activePlayerLineupIndex,
        playerPartySlotIndicesByLineupIndex:
            battleContext.playerPartySlotIndicesByLineupIndex,
      );
      final respawn = _resolveWhiteoutLiteRespawn(battleContext);
      _world = _buildSafeWorldState(
        map: _bundle.map,
        project: _bundle.manifest,
        preferredPos: respawn.pos,
        fallbackFacing: respawn.facing,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
      );
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      _setFlowPhase(_RuntimeFlowPhase.overworld);
      _showNotification(_defeatRecoveryFailureMessage);
      await defeatRecoveryCheckpointEmitter?.call();
    } finally {
      _inputLocks.release(
        owner: RuntimeInputLockOwner.checkpoint,
        token: recoveryLock,
      );
      _syncDerivedInputLocks();
    }
  }

  Future<PlayerRecoveryPoint> _resolveDefeatFallbackPoint(
    RuntimeActiveBattleContext battleContext,
  ) async {
    final recorded = PlayerRecoveryPoint.tryRead(_gameState);
    if (recorded != null) return recorded;
    try {
      final configuredMapId = _bundle.manifest.newGame.startMapId.trim();
      final fallbackBundle =
          configuredMapId.isEmpty || configuredMapId == _activeMapId
              ? _bundle
              : await _loadRuntimeMapBundleCached(configuredMapId);
      final spawn = resolveInitialPlayerSpawn(fallbackBundle.map);
      return PlayerRecoveryPoint(
        mapId: fallbackBundle.map.id,
        position: spawn.pos,
        facing: spawn.facing.asFacing,
      );
    } catch (_) {
      final respawn = _resolveWhiteoutLiteRespawn(battleContext);
      return PlayerRecoveryPoint(
        mapId: _activeMapId,
        position: respawn.pos,
        facing: respawn.facing.asFacing,
      );
    }
  }

  String _defeatRecoveryMessage(int moneyLost) {
    final french = runtimeLocale.toLowerCase().startsWith('fr');
    if (moneyLost <= 0) {
      return french
          ? 'Défaite… retour au Centre Pokémon.'
          : 'Defeat… returning to the Pokémon Center.';
    }
    return french
        ? 'Défaite… retour au Centre Pokémon. $moneyLost ₽ perdus.'
        : 'Defeat… returning to the Pokémon Center. Lost $moneyLost ₽.';
  }

  String get _defeatRecoveryFailureMessage =>
      runtimeLocale.toLowerCase().startsWith('fr')
          ? 'Défaite… reprise de secours appliquée.'
          : 'Defeat… emergency recovery applied.';

  GameplayPlayerState _resolveWhiteoutLiteRespawn(
    RuntimeActiveBattleContext activeBattleContext,
  ) {
    try {
      return resolveInitialPlayerSpawn(_bundle.map);
    } catch (_) {
      // Fallback minimal :
      // - si la map courante n'a pas de spawn joueur exploitable, on repart de
      //   la position overworld mémorisée au moment du handoff combat ;
      // - `_buildSafeWorldState` gardera ensuite le dernier mot pour éviter une
      //   cellule bloquée et trouver un point sûr si nécessaire.
      return GameplayPlayerState.fromGridSpawn(
        cell: activeBattleContext.request.returnContext.playerPos,
        facing: activeBattleContext.request.returnContext.playerFacing,
        tileWidthPx: _bundle.manifest.settings.tileWidth,
        tileHeightPx: _bundle.manifest.settings.tileHeight,
        mapWidthCells: _bundle.map.size.width,
        mapHeightCells: _bundle.map.size.height,
      );
    }
  }

  void _handleInteract() {
    final result = stepGameplayWorld(_world, const InteractIntent());
    _world = result.world;

    final entity = switch (result) {
      NpcInteracted(:final entity) => entity,
      SignInteracted(:final entity) => entity,
      ItemInteracted(:final entity) => entity,
      EntityInteracted(:final entity) => entity,
      _ => null,
    };
    if (entity != null && entity.kind != MapEntityKind.spawn) {
      if (entity.kind == MapEntityKind.npc) {
        _faceNpcTowardPlayer(entity.id);
      }
      _runDetachedNarrativeTask(
        operation: 'entityInteract',
        task: () => _dispatchNarrativeEntityInteraction(result, entity),
      );
      return;
    }

    _runLegacyInteractionFallback(result);
  }

  Future<void> _dispatchNarrativeEntityInteraction(
    GameplayStepResult result,
    MapEntity entity,
  ) async {
    await _dispatchSpatialOccurrence(
      occurrence: NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.entityInteract(
          _activeMapId,
          entity.id,
        ),
      ),
      legacyFallback: (_) async => _runLegacyInteractionFallback(result),
    );
  }

  void _runLegacyInteractionFallback(GameplayStepResult result) {
    var scenarioHandledEntityInteraction = false;

    switch (result) {
      case NothingToInteract():
        debugPrint('[interact] Nothing to interact with');
        _showNotification('...');
      case NpcInteracted(:final entity):
        debugPrint('[interact] NPC: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _handleNpcInteraction(entity);
        }
      case SignInteracted(:final entity):
        debugPrint('[interact] Sign: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _tryOpenDialogue(
              entity.id, entity.sign?.dialogue, entity.inspectorHeadline);
        }
      case ItemInteracted(:final entity):
        debugPrint('[interact] Item: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _showNotification(entity.inspectorHeadline);
        }
      case EntityInteracted(:final entity):
        debugPrint('[interact] Entity: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _showNotification(entity.inspectorHeadline);
        }
      case PlacedElementInteracted(
          :final element,
          :final behavior,
          :final trigger,
        ):
        debugPrint('[interact] PlacedElement: ${element.id}');
        _executePlacedElementBehavior(
          element: element,
          behavior: behavior,
          trigger: trigger,
        );
      default:
        break;
    }

    if (result is NothingToInteract ||
        (result is EntityInteracted && !scenarioHandledEntityInteraction)) {
      _tryInteractWithMapEvent();
    }
  }

  bool _tryDispatchScenarioEntityInteraction(String entityId) {
    final result = _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.entityInteract(
        mapId: _activeMapId,
        entityId: entityId,
      ),
    );
    return result.handled;
  }

  void _tryInteractWithMapEvent() {
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      debugPrint('[interact] blocked: script is active');
      return;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[interact] blocked: flow phase is $_flowPhase');
      return;
    }

    final facing = _world.player.facing;
    final tx = _world.player.pos.x + facing.dx;
    final ty = _world.player.pos.y + facing.dy;

    final map = _bundle.map;
    MapEventDefinition? event;
    for (final e in map.events) {
      if (e.position.x == tx && e.position.y == ty) {
        event = e;
        break;
      }
    }

    if (event == null) return;

    final factContext = ScriptEvaluationContext(
      narrativeFactResolver: _narrativeFactResolver,
    );
    final activePage = _storyBranching.pageResolver.resolve(
      event,
      _gameState,
      contextForPage: (page) =>
          hasEventBuilderPageProvenance(page) ? factContext : null,
    );

    if (activePage == null) return;

    final worldRuleProjection = _resolveWorldRuleProjectionForMap(
      map.id,
      _bundle.manifest,
    );
    final defaultEnabled = !activePage.page.isDisabled;
    if (worldRuleProjection != null &&
        !worldRuleProjection.canTriggerMapEvent(
          event,
          defaultEnabled: defaultEnabled,
        )) {
      return;
    }
    if (worldRuleProjection == null && activePage.page.isDisabled) return;

    debugPrint('[interact] MapEvent: ${event.id} page=${activePage.pageIndex}');
    _handleMapEventInteraction(event, activePage);
  }

  void _handleMapEventInteraction(
    MapEventDefinition event,
    ActiveEventPage page,
  ) {
    if (page.page.sceneTarget != null) {
      unawaited(_runSceneTargetForMapEvent(event, page));
      return;
    }

    if (page.page.script != null) {
      final message = page.page.message?.trim();
      if (message != null && message.isNotEmpty) {
        _showNotification(message);
      }
      _executeEventScript(event, page, page.page.script!);
    } else if (page.page.message != null && page.page.message!.isNotEmpty) {
      _showNotification(page.page.message!);
    } else {
      _showNotification('...');
    }
  }

  Future<void> _runSceneTargetForMapEvent(
    MapEventDefinition event,
    ActiveEventPage page,
  ) async {
    try {
      await _narrativeActivityGate.runWithActivity<void>(
        NarrativeRuntimeActivity.sceneActive,
        () => _runSceneTargetForMapEventWithActivity(event, page),
      );
    } on NarrativeRuntimeActivityBlockedException {
      // Fail closed: no working session, dialogue or Battle handoff may be
      // created while a checkpoint owns the shared narrative gate.
      debugPrint(
        '[scene_runtime] map event blocked by checkpoint '
        'event=${event.id} page=${page.pageIndex}',
      );
    }
  }

  Future<void> _runSceneTargetForMapEventWithActivity(
    MapEventDefinition event,
    ActiveEventPage page,
  ) async {
    if (_activeNarrativeSceneWorkingSession != null) {
      _showNotification('Scene V1 impossible.');
      return;
    }
    try {
      final session = _NarrativeSceneWorkingSession(_gameState);
      final hostedBattleOutcomes = <NarrativeOutcomeRef>[];
      final consequenceWriter = await _buildSceneConsequenceRuntimeWriter(
        project: _bundle.manifest,
        mapsById: <String, MapData>{_bundle.map.id: _bundle.map},
        sceneId: page.page.sceneTarget!.sceneId,
        gameState: session.gameState,
      );
      _activeNarrativeSceneWorkingSession = session;
      late final SceneEventRuntimeHookResult result;
      try {
        result = await SceneEventRuntimeHook(
          consequenceWriter: consequenceWriter,
          callbacks: _buildSceneRuntimeHostCallbacks(
            runtimeSourceId:
                'scene:${_bundle.map.id}:${event.id}:${page.pageIndex}',
            defaultNpcEntityId: event.id,
            currentGameState: () => session.gameState,
            onQualifiedBattleOutcome: hostedBattleOutcomes.add,
          ),
        ).runForEventPage(
          project: _bundle.manifest,
          map: _bundle.map,
          event: event,
          page: page.page,
          gameState: session.gameState,
          currentGameState: () => session.gameState,
        );
      } finally {
        _activeNarrativeSceneWorkingSession = null;
      }

      debugPrint(
        '[scene_runtime] event=${event.id} page=${page.pageIndex} '
        'status=${result.status.name} scene=${result.sceneId ?? '-'} '
        'message=${result.message ?? '-'}',
      );

      if (!result.success && result.handled) {
        _showNotification(result.message ?? 'Scene V1 impossible.');
      } else if (result.success) {
        session.gameState = await _hydrateOwnedPlayerPokemonProgression(
          result.updatedGameState ?? session.gameState,
        );
        final gameCompletion = result.consequenceWriteResult?.gameCompletion;
        if (gameCompletion != null) {
          final coordinator = _gameCompletionCoordinator;
          if (coordinator == null) {
            throw StateError(
              'Finish Game requires an active session completion port.',
            );
          }
          coordinator.queue(gameCompletion);
        }
        _applyNarrativeGameState(session.gameState);
        final outcomes = <NarrativeOutcomeRef>[
          ...hostedBattleOutcomes,
          if (result.executionResult?.sceneOutcomeId case final outcomeId?)
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: result.sceneId!,
              outcomeId: outcomeId,
            ),
        ];
        await _publishRootNarrativeOutcomes(outcomes);
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[scene_runtime] unhandled hook error event=${event.id} '
        'page=${page.pageIndex} error=$error\n$stackTrace',
      );
      _showNotification('Scene V1 impossible.');
    }
  }

  SceneRuntimeHostCallbacks _buildSceneRuntimeHostCallbacks({
    required String runtimeSourceId,
    required String defaultNpcEntityId,
    required GameState Function() currentGameState,
    void Function(NarrativeOutcomeRef outcome)? onQualifiedBattleOutcome,
  }) {
    return SceneRuntimeHostCallbacks(
      evaluateCondition: (intent) => _resolveSceneConditionOutput(
        intent,
        // Dialogue and battle callbacks may commit a newer runtime snapshot
        // before a later Scene branch is evaluated. Preserve the pre-V2
        // dynamic condition semantics instead of capturing a stale snapshot.
        gameState: currentGameState(),
      ),
      showDialogue: (intent) {
        final adapter = SceneDialogueRuntimeAwaitableAdapter(
          runtimeSourceId: runtimeSourceId,
          launcher: _CallbackSceneDialogueRuntimeLauncher(
            _startSceneDialogue,
          ),
        );
        return adapter.showDialogue(intent).then((result) {
          final scenePortId = result.scenePortId;
          if (!result.success || scenePortId == null) {
            throw StateError(
              result.message ??
                  'Scene V1 dialogue handoff failed '
                      '(dialogueId=${intent.dialogueId}, '
                      'yarnNodeName=${intent.yarnNodeName}).',
            );
          }
          return scenePortId;
        });
      },
      startBattle: (intent) {
        final adapter = SceneBattleRuntimeOutcomeAdapter(
          runtimeSourceId: runtimeSourceId,
          defaultNpcEntityId: defaultNpcEntityId,
          launcher: _CallbackSceneBattleRuntimeLauncher(
            _startSceneBattle,
          ),
        );
        return adapter.startBattle(intent).then((result) {
          final scenePortId = result.scenePortId;
          if (!result.success || scenePortId == null) {
            throw StateError(
              result.message ??
                  'Scene V1 battle handoff failed '
                      '(battleKind=${intent.battleKind}, '
                      'trainerId=${intent.trainerId}).',
            );
          }
          final qualifiedOutcome = _qualifiedSceneTrainerBattleOutcome(
            intent,
            scenePortId,
          );
          if (qualifiedOutcome != null) {
            onQualifiedBattleOutcome?.call(qualifiedOutcome);
          }
          return scenePortId;
        });
      },
      playCinematic: (intent) {
        final adapter = SceneCinematicRuntimeAwaitableAdapter(
          runtimeSourceId: runtimeSourceId,
          project: _bundle.manifest,
          player: _cinematicRuntimeController,
        );
        return adapter.playCinematic(intent).then((result) {
          final scenePortId = result.scenePortId;
          if (!result.success || scenePortId == null) {
            throw StateError(
              result.message ??
                  'Scene V1 cinematic handoff failed '
                      '(cinematicId=${intent.cinematicId}).',
            );
          }
          return scenePortId;
        });
      },
      executeInteractiveCommand: SceneInteractiveCommandRuntimeExecutor(
        warp: (command) => _executeSceneWarpCommand(
          command,
          currentGameState: currentGameState,
        ),
        moveNpc: (command) => _executeSceneMoveNpcCommand(
          command,
          currentGameState: currentGameState,
        ),
        openWorldService: _executeSceneWorldServiceRequest,
      ).execute,
    );
  }

  Future<SceneConsequenceRuntimeWriter> _buildSceneConsequenceRuntimeWriter({
    required ProjectManifest project,
    required Map<String, MapData> mapsById,
    required String sceneId,
    required GameState gameState,
  }) async {
    SceneAsset? scene;
    for (final candidate in project.scenes) {
      if (candidate.id == sceneId) {
        scene = candidate;
        break;
      }
    }
    final requiresRecoveryCaps = scene?.graph.nodes.any((node) {
          final payload = node.payload;
          return payload is SceneActionPayload &&
              payload.consequence is SceneHealPartyConsequence;
        }) ??
        false;
    var recoveryCaps = const RuntimePlayerServiceRecoveryCaps(
      maxHpByPartyIndex: <int, int>{},
    );
    if (requiresRecoveryCaps) {
      recoveryCaps = await loadRuntimePlayerServiceRecoveryCaps(
        gameState: gameState,
        projectRootDirectory: _bundle.projectRootDirectory,
        pokemonConfig: project.pokemon,
        speciesLoader: _battleSpeciesLoader,
        moveCatalogLoader: _battleMoveCatalogLoader,
      );
    }
    return SceneConsequenceRuntimeWriter(
      project: project,
      mapsById: mapsById,
      maxHpByPartyIndex: recoveryCaps.maxHpByPartyIndex,
      maxPpByPartyIndex: recoveryCaps.maxPpByPartyIndex,
    );
  }

  Future<String> _executeSceneWarpCommand(
    SceneInteractiveCommand command, {
    required GameState Function() currentGameState,
  }) async {
    if (command is! SceneWarpInteractiveCommand) return 'blocked';
    if (!isLoaded) {
      _notifySceneCommand('Warp indisponible avant le chargement de la map.');
      return 'blocked';
    }
    try {
      final destination = await _loadRuntimeMapBundleCached(
        command.destinationMapId,
      );
      MapWarp? arrival;
      for (final warp in destination.map.warps) {
        if (warp.id == command.warpId) {
          arrival = warp;
          break;
        }
      }
      if (arrival == null) {
        _notifySceneCommand(
          'Warp ${command.warpId} introuvable sur '
          '${command.destinationMapId}.',
        );
        return 'blocked';
      }

      // Preserve all consequences already accumulated by the Scene before the
      // existing transition pipeline synchronizes the map and player position.
      _applyNarrativeGameState(currentGameState());
      await _handleWarp(
        TriggeredWarp(
          warpId: command.warpId,
          targetMapId: command.destinationMapId,
          targetPos: arrival.pos,
          triggerMode: arrival.triggerMode,
        ),
        allowMapActivationWork: true,
      );
      final completed = _activeMapId == command.destinationMapId &&
          _world.player.pos == arrival.pos;
      if (!completed) return 'blocked';
      final session = _activeNarrativeSceneWorkingSession;
      if (session != null) session.gameState = _gameState;
      return 'completed';
    } catch (error, stackTrace) {
      debugPrint(
        '[scene_runtime] warp command failed '
        'map=${command.destinationMapId} warp=${command.warpId} '
        'error=$error\n$stackTrace',
      );
      _notifySceneCommand('Warp impossible.');
      return 'blocked';
    }
  }

  Future<String> _executeSceneMoveNpcCommand(
    SceneInteractiveCommand command, {
    required GameState Function() currentGameState,
  }) {
    if (command is! SceneMoveNpcInteractiveCommand || !isLoaded) {
      return Future<String>.value('blocked');
    }
    if (command.mapId != _activeMapId) {
      _notifySceneCommand(
        'Le PNJ doit être déplacé depuis la map active.',
      );
      return Future<String>.value('blocked');
    }
    final map = _world.map;
    final entity = map.entities
        .where(
          (candidate) =>
              candidate.id == command.entityId &&
              candidate.kind == MapEntityKind.npc,
        )
        .firstOrNull;
    final warpExists = map.warps.any((warp) => warp.id == command.warpId);
    final present = entity != null &&
        _npcPresencePredicateFor(
          _bundle.manifest,
          gameStateOverride: currentGameState(),
        )(map.id, entity);
    if (!present || !warpExists) {
      _notifySceneCommand('Déplacement du PNJ impossible.');
      return Future<String>.value('blocked');
    }
    if (_pendingSceneNpcMovesByEntity.containsKey(command.entityId)) {
      _notifySceneCommand('Ce PNJ est déjà en déplacement.');
      return Future<String>.value('blocked');
    }
    final started = _runScenarioMoveCharacter(
      entityId: command.entityId,
      targetKind: 'warp',
      targetId: command.warpId,
      waitForCompletion: false,
      runtimeSourceId: 'scene.moveNpc:${command.mapId}:${command.entityId}',
    );
    if (!started) {
      return Future<String>.value('blocked');
    }
    final completer = Completer<String>();
    _pendingSceneNpcMovesByEntity[command.entityId] = completer;
    return completer.future;
  }

  void _processPendingSceneNpcMoves() {
    if (_pendingSceneNpcMovesByEntity.isEmpty) return;
    final entityIds = _pendingSceneNpcMovesByEntity.keys.toList(growable: false)
      ..sort();
    for (final entityId in entityIds) {
      final completer = _pendingSceneNpcMovesByEntity[entityId];
      if (completer == null) continue;
      final status = scriptedNpcMovementStatus(entityId);
      final output = switch (status.state) {
        ScriptedEntityMovementState.completed ||
        ScriptedEntityMovementState.idle =>
          'completed',
        ScriptedEntityMovementState.failed => 'blocked',
        ScriptedEntityMovementState.moving => null,
      };
      if (output == null) continue;
      _pendingSceneNpcMovesByEntity.remove(entityId);
      if (!completer.isCompleted) completer.complete(output);
    }
  }

  Future<String> _executeSceneWorldServiceRequest(
    RuntimeWorldServiceRequest request,
  ) async {
    final controller = _playerServiceRuntimeController;
    if (controller == null) {
      _notifySceneCommand('Service joueur indisponible dans ce host.');
      return 'cancelled';
    }
    switch (request) {
      case OpenShopService(:final shopId):
        return _executeSceneOpenShopRequest(
          controller,
          request,
          shopId,
        );
      case OpenPcService():
        return _scenePortForPlayerService(
          await controller.openPc(request: request),
        );
      case OpenHealService():
        return _scenePortForPlayerService(
          await controller.openHealCenter(request: request),
        );
    }
  }

  Future<String> _executeSceneOpenShopRequest(
    PlayerServiceRuntimeController controller,
    OpenShopService request,
    String shopId,
  ) async {
    ShopDefinition? shop;
    for (final candidate in _bundle.manifest.shops) {
      if (candidate.id == shopId) {
        shop = candidate;
        break;
      }
    }
    if (shop == null) {
      _notifySceneCommand('Boutique $shopId introuvable.');
      return 'cancelled';
    }
    return _scenePortForPlayerService(
      await controller.openShop(shop, request: request),
    );
  }

  String _scenePortForPlayerService(PlayerServiceRuntimeResult result) {
    switch (result.status) {
      case PlayerServiceRuntimeStatus.completed:
        final nextState = result.gameState;
        if (nextState == null) {
          _notifySceneCommand('Service joueur incomplet.');
          return 'cancelled';
        }
        final session = _activeNarrativeSceneWorkingSession;
        if (session != null) session.gameState = nextState;
        return 'completed';
      case PlayerServiceRuntimeStatus.cancelled:
        return 'cancelled';
      case PlayerServiceRuntimeStatus.unavailable:
        _notifySceneCommand(
          result.safeMessage ?? 'Service joueur indisponible.',
        );
        return 'cancelled';
      case PlayerServiceRuntimeStatus.busy:
        _notifySceneCommand('Un service joueur est déjà ouvert.');
        return 'cancelled';
      case PlayerServiceRuntimeStatus.failed:
        debugPrint('[scene_runtime] player service failed: ${result.error}');
        _notifySceneCommand('Service joueur impossible.');
        return 'cancelled';
    }
  }

  void _notifySceneCommand(String message) {
    if (isLoaded) {
      _showNotification(message);
    } else {
      debugPrint('[scene_runtime] $message');
    }
  }

  @visibleForTesting
  Future<String> debugExecuteSceneInteractiveCommand(
    SceneInteractiveCommand command,
  ) async {
    final callback = _buildSceneRuntimeHostCallbacks(
      runtimeSourceId: 'debug:interactive-command',
      defaultNpcEntityId: 'debug',
      currentGameState: () => playerServiceGameStateSnapshot,
    ).executeInteractiveCommand!;
    return await callback(
      SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
    );
  }

  NarrativeOutcomeRef? _qualifiedSceneTrainerBattleOutcome(
    SceneRuntimePlanIntent intent,
    String outcomeId,
  ) {
    final trainerId = intent.trainerId?.trim() ?? '';
    final battleKind = intent.battleKind?.trim();
    if ((battleKind != 'trainer' && battleKind != 'static') ||
        trainerId.isEmpty) {
      return null;
    }
    return _qualifiedBattleOutcome(
      battleKind: battleKind!,
      opponentProfileId: trainerId,
      outcomeId: outcomeId,
    );
  }

  NarrativeOutcomeRef? _qualifiedBattleOutcome({
    required String battleKind,
    required String opponentProfileId,
    required String outcomeId,
  }) {
    final battleRefId = '$battleKind:$opponentProfileId';
    final contracts = buildBattlePublicContracts(_bundle.manifest);
    for (final contract in contracts) {
      if (contract.battleRefId != battleRefId) continue;
      final declaresOutcome = contract.possibleOutcomes.any(
        (outcome) => outcome.id == outcomeId,
      );
      if (!declaresOutcome) return null;
      return NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: battleRefId,
        outcomeId: outcomeId,
      );
    }
    return null;
  }

  NarrativeOutcomeRef? _qualifiedTrainerBattleOutcome(
    String trainerId,
    String outcomeId,
  ) {
    final battleRefId = 'trainer:$trainerId';
    final contracts = buildBattlePublicContracts(_bundle.manifest);
    for (final contract in contracts) {
      if (contract.battleRefId != battleRefId) {
        continue;
      }
      final declaresOutcome = contract.possibleOutcomes.any(
        (outcome) => outcome.id == outcomeId,
      );
      if (!declaresOutcome) {
        return null;
      }
      return NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: battleRefId,
        outcomeId: outcomeId,
      );
    }
    return null;
  }

  Future<SceneDialogueRuntimeAwaitableResult> _startSceneDialogue(
    SceneDialogueRuntimeDialogueRequest request,
  ) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return Future.value(
        const SceneDialogueRuntimeAwaitableResult.failed(
          errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
          message: 'Scene dialogue requires overworld flow.',
        ),
      );
    }
    if (_activeBlockingInteractionSerial != null || _dialogueOverlay != null) {
      return Future.value(
        const SceneDialogueRuntimeAwaitableResult.failed(
          errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
          message: 'A dialogue is already active.',
        ),
      );
    }
    if (_pendingSceneDialogueCompleter != null) {
      return Future.value(
        const SceneDialogueRuntimeAwaitableResult.failed(
          errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
          message: 'A Scene dialogue is already pending.',
        ),
      );
    }

    final resolved = resolveDialogue(
      entityId: request.requestId,
      ref: DialogueRef(
        dialogueId: request.dialogueId,
        startNode: request.yarnNodeName,
      ),
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );
    if (resolved == null) {
      final message = 'Dialogue introuvable: ${request.dialogueId}';
      _showNotification(message);
      return Future.value(
        SceneDialogueRuntimeAwaitableResult.failed(
          errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
          message: message,
        ),
      );
    }

    final serial = _beginBlockingInteraction(
      source: request.requestId,
      pendingDialogueLoad: true,
    );
    final completer = Completer<SceneDialogueRuntimeAwaitableResult>();
    _pendingSceneDialogueCompleter = completer;
    _pendingSceneDialogueRequestId = request.requestId;
    final stopwatch = Stopwatch()..start();

    void completeLoadFailure(
      SceneDialogueRuntimeAwaitableResult result, {
      Object? error,
      StackTrace? stackTrace,
    }) {
      stopwatch.stop();
      if (!_isBlockingInteractionActive(serial)) {
        debugPrint(
          '[scene_runtime] stale dialogue response ignored '
          'request=${request.requestId} serial=$serial',
        );
        if (identical(_pendingSceneDialogueCompleter, completer)) {
          _completePendingSceneDialogue(
            const SceneDialogueRuntimeAwaitableResult.failed(
              errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
              message: 'Scene dialogue load was cancelled.',
            ),
          );
        }
        return;
      }
      if (error == null) {
        debugPrint(
          '[scene_runtime] dialogue load failed '
          'request=${request.requestId}',
        );
      } else {
        debugPrint(
          '[scene_runtime] dialogue load error '
          'request=${request.requestId} error=$error'
          '${stackTrace == null ? '' : '\n$stackTrace'}',
        );
      }
      _releaseBlockingInteraction(
        serial: serial,
        source: request.requestId,
        reason: 'sceneDialogueLoadFailed',
      );
      _showNotification('Dialogue introuvable: ${request.dialogueId}');
      if (identical(_pendingSceneDialogueCompleter, completer)) {
        _completePendingSceneDialogue(
          result,
        );
      }
    }

    late final Future<DialogueSession?> loadFuture;
    try {
      loadFuture = _dialogueSessionLoader(resolved);
    } catch (error, stackTrace) {
      completeLoadFailure(
        SceneDialogueRuntimeAwaitableResult.failed(
          errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
          message: 'Scene dialogue launcher failed: $error',
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return completer.future;
    }

    loadFuture.then((session) {
      stopwatch.stop();
      if (!_isBlockingInteractionActive(serial)) {
        debugPrint(
          '[scene_runtime] stale dialogue response ignored '
          'request=${request.requestId} serial=$serial',
        );
        if (identical(_pendingSceneDialogueCompleter, completer)) {
          _completePendingSceneDialogue(
            const SceneDialogueRuntimeAwaitableResult.failed(
              errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
              message: 'Scene dialogue load was cancelled.',
            ),
          );
        }
        return;
      }
      if (session == null) {
        completeLoadFailure(
          SceneDialogueRuntimeAwaitableResult.failed(
            errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
            message: 'Dialogue introuvable: ${request.dialogueId}',
          ),
        );
        return;
      }
      debugPrint(
        '[scene_runtime] dialogue content loaded '
        'request=${request.requestId} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      _openDialogue(
        session,
        onDialogueFinished: (outcomeId) {
          _completePendingSceneDialogue(
            SceneDialogueRuntimeAwaitableResult.completed(
              outcomeId: outcomeId,
            ),
          );
        },
      );
    }).onError((Object error, StackTrace stackTrace) {
      completeLoadFailure(
        SceneDialogueRuntimeAwaitableResult.failed(
          errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
          message: 'Scene dialogue launcher failed: $error',
        ),
        error: error,
        stackTrace: stackTrace,
      );
    });

    return completer.future;
  }

  void _completePendingSceneDialogue(
    SceneDialogueRuntimeAwaitableResult result,
  ) {
    final completer = _pendingSceneDialogueCompleter;
    if (completer == null) {
      return;
    }
    final requestId = _pendingSceneDialogueRequestId;
    _pendingSceneDialogueCompleter = null;
    _pendingSceneDialogueRequestId = null;
    if (!completer.isCompleted) {
      completer.complete(result);
    }
    debugPrint(
      '[scene_runtime] dialogue completed request=${requestId ?? '-'} '
      'status=${result.status.name} port=${result.scenePortId ?? '-'}',
    );
  }

  Future<SceneBattleRuntimeOutcomeResult> _startSceneBattle(
    SceneBattleRuntimeBattleRequest request,
  ) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return Future.value(
        const SceneBattleRuntimeOutcomeResult.failed(
          errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
          message: 'Scene trainer battle requires overworld flow.',
        ),
      );
    }
    if (_hasClaimedBattleHandoff) {
      return Future.value(
        const SceneBattleRuntimeOutcomeResult.failed(
          errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
          message: 'Another Battle handoff already owns runtime execution.',
        ),
      );
    }

    final completer = Completer<SceneBattleRuntimeOutcomeResult>();
    _pendingSceneBattleOutcomeCompleter = completer;
    _pendingSceneBattleRequestId = request.requestId;

    final returnContext = OverworldReturnContext(
      mapId: _world.map.id,
      playerPos: _world.player.pos,
      playerFacing: _world.player.facing,
    );
    final battleRequest = switch (request.battleKind) {
      'trainer' => TrainerBattleStartRequest(
          requestId: request.requestId,
          createdAtEpochMs: request.createdAtEpochMs,
          returnContext: returnContext,
          trainerId: request.trainerId,
          npcEntityId: request.npcEntityId,
          mapId: _world.map.id,
          playerPos: _world.player.pos,
        ),
      'static' => StaticBattleStartRequest(
          requestId: request.requestId,
          createdAtEpochMs: request.createdAtEpochMs,
          returnContext: returnContext,
          battleId: request.battleTemplateId ?? request.trainerId,
          opponentProfileId: request.trainerId,
          entityId: request.npcEntityId,
          mapId: _world.map.id,
          playerPos: _world.player.pos,
        ),
      _ => null,
    };
    if (battleRequest == null) {
      _pendingSceneBattleOutcomeCompleter = null;
      _pendingSceneBattleRequestId = null;
      return Future.value(
        SceneBattleRuntimeOutcomeResult.failed(
          errorCode: SceneBattleRuntimeOutcomeErrorCode.unsupportedBattleKind,
          message: 'Scene battle kind "${request.battleKind}" is unsupported.',
        ),
      );
    }
    _startBattleHandoff(battleRequest);
    return completer.future;
  }

  String _resolveSceneConditionOutput(
    SceneRuntimePlanIntent intent, {
    required GameState gameState,
  }) {
    final source = intent.conditionSource;
    if (source == null) {
      throw StateError('Scene condition intent is missing a condition source.');
    }

    if (source.sourceKind == SceneConditionSourceKind.fact) {
      return evaluateCanonicalNarrativeFactSceneCondition(
        source: source,
        gameState: gameState,
        resolver: _narrativeFactResolver,
      )
          ? 'true'
          : 'false';
    }

    final value = switch (source.sourceKind) {
      SceneConditionSourceKind.factLikeStoryFlag =>
        gameState.storyFlags.activeFlags.contains(source.sourceId) ||
            gameState.progression.storyFlags.contains(source.sourceId),
      SceneConditionSourceKind.storyStepCompletion =>
        gameState.progression.completedStepIds.contains(source.sourceId),
      SceneConditionSourceKind.consumedEvent =>
        gameState.consumedEventIds.contains(source.sourceId),
      _ => throw UnsupportedError(
          'Scene condition source ${source.sourceKind.name} is not supported '
          'by runtime hook V0.',
        ),
    };

    final matched = switch (source.operator) {
      SceneConditionOperator.isTrue => value,
      SceneConditionOperator.isFalse => !value,
      SceneConditionOperator.equals =>
        _matchesSceneConditionEquals(source, value),
    };
    return matched ? 'true' : 'false';
  }

  bool _matchesSceneConditionEquals(
    SceneConditionSource source,
    bool resolvedValue,
  ) {
    return switch (source.value) {
      'true' => resolvedValue,
      'false' => !resolvedValue,
      SceneConditionValues.completed => resolvedValue,
      SceneConditionValues.notCompleted => !resolvedValue,
      _ => throw UnsupportedError(
          'Scene condition equality value "${source.value}" is not supported '
          'by runtime hook V0.',
        ),
    };
  }

  void _executeEventScript(
    MapEventDefinition event,
    ActiveEventPage page,
    ScriptRef scriptRef,
  ) {
    final scriptAsset = _bundle.manifest.scripts
        .firstWhere(
          (s) => s.id == scriptRef.scriptId,
          orElse: () =>
              throw StateError('Script not found: ${scriptRef.scriptId}'),
        )
        .asset;
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: scriptRef.startNode,
      runtimeSourceId: event.id,
    );
  }

  /// Démarrage générique d'exécution script.
  ///
  /// Cette méthode factorise le chemin script:
  /// - scripts de pages d'event map,
  /// - scripts déclenchés par le Scenario Runtime Bridge.
  void _startScriptExecution({
    required ScriptAsset script,
    String? startNodeId,
    required String runtimeSourceId,
  }) {
    _activeScriptRuntimeSourceId = runtimeSourceId;
    _beginBlockingInteraction(source: runtimeSourceId);
    final context = ScriptExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      onDialogueOpened: (dialogue) {
        _openDialogueForScriptSource(runtimeSourceId, dialogue);
      },
      onWarpRequested: (mapId, x, y) {
        final warp = TriggeredWarp(
          warpId: 'script_warp',
          targetMapId: mapId,
          targetPos: GridPos(x: x, y: y),
          triggerMode: MapWarpTriggerMode.onEnter,
        );
        final owner = _PendingScenarioWarpHandoff(
          runtimeSourceId: runtimeSourceId,
          expectedWarp: warp,
          kind: _ScenarioWarpHandoffKind.script,
        );
        if (!_tryEnqueueWarp(warp, scenarioOwner: owner)) {
          throw StateError(
            'Cannot enqueue script warp while another warp handoff is pending.',
          );
        }
      },
    );

    _activeScriptController = ScriptRuntimeController(
      script: script,
      context: context,
      startNodeId: startNodeId,
    );
    _runScriptStep();
  }

  void _runScriptStep() {
    while (true) {
      final controller = _activeScriptController;
      if (controller == null) {
        return;
      }

      final source = _activeScriptRuntimeSourceId ?? 'script';
      if (controller.isTerminated) {
        final serial = _activeBlockingInteractionSerial;
        final warpOwner = _pendingScenarioWarpHandoff;
        final ownsPendingWarp = warpOwner != null &&
            warpOwner.kind == _ScenarioWarpHandoffKind.script &&
            warpOwner.runtimeSourceId == source &&
            warpOwner.matches(_pendingWarp);
        _activeScriptController = null;
        _activeScriptRuntimeSourceId = null;
        if (serial != null && ownsPendingWarp) {
          _clearBlockingInteractionWithoutUnlock(
            reason: 'scriptWarpPending',
          );
          _setFlowPhase(_RuntimeFlowPhase.overworld);
        } else if (serial != null) {
          _releaseBlockingInteraction(
            serial: serial,
            source: source,
            reason: 'scriptCompleted',
          );
        }
        if (!ownsPendingWarp && source.startsWith('scenario:')) {
          scheduleMicrotask(
            () => _scheduleNarrativeContinuationAdvance(source),
          );
        }
        return;
      }

      if (controller.isSuspended) {
        _markBlockingInteractionPendingDialogue();
        return;
      }

      late final ScriptCommandResult result;
      try {
        result = controller.step();
      } catch (error, stackTrace) {
        _abortActiveScriptExecution(
          source: source,
          reason: 'scriptException',
          fallbackLabel: 'Script interrompu',
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }

      if (result is ScriptCommandResultSuspended) {
        _markBlockingInteractionPendingDialogue();
        return;
      }
      if (result is ScriptCommandResultError) {
        _abortActiveScriptExecution(
          source: source,
          reason: 'scriptCommandError',
          fallbackLabel: 'Script interrompu',
          error: result.message,
        );
        return;
      }
    }
  }

  void _openDialogueForScriptSource(
      String runtimeSourceId, YarnDialogueRef dialogueRef) {
    final serial = _activeBlockingInteractionSerial ??
        _beginBlockingInteraction(
          source: runtimeSourceId,
          pendingDialogueLoad: true,
        );
    _markBlockingInteractionPendingDialogue();
    final resolved = resolveDialogue(
      entityId: runtimeSourceId,
      ref: DialogueRef(
        dialogueId: '',
        scriptPathRelative: dialogueRef.filePath,
        startNode: dialogueRef.startNode,
      ),
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      debugPrint(
          '[script] failed to resolve dialogue: ${dialogueRef.filePath}');
      _abortActiveScriptAfterDialogueFailure(
        serial: serial,
        source: runtimeSourceId,
        fallbackLabel: 'Dialogue introuvable',
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    _dialogueSessionLoader(resolved).then((session) {
      stopwatch.stop();
      if (!_isBlockingInteractionActive(serial)) {
        debugPrint(
          '[dialogue] stale response ignored source=$runtimeSourceId serial=$serial',
        );
        return;
      }
      debugPrint(
        '[dialogue] content loaded source=$runtimeSourceId elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      if (session == null) {
        debugPrint('[script] failed to load dialogue');
        _abortActiveScriptAfterDialogueFailure(
          serial: serial,
          source: runtimeSourceId,
          fallbackLabel: 'Dialogue introuvable',
        );
        return;
      }

      _pendingPostDialogueAction = () {
        _resumeActiveScriptAfterDialogue(runtimeSourceId);
      };

      _openDialogue(session);
    }).onError((Object error, StackTrace stackTrace) {
      debugPrint(
        '[dialogue] failed to load source=$runtimeSourceId error=$error\n$stackTrace',
      );
      _abortActiveScriptAfterDialogueFailure(
        serial: serial,
        source: runtimeSourceId,
        fallbackLabel: 'Dialogue introuvable',
      );
    });
  }

  void _executePlacedElementBehavior({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    if (!behavior.enabled) {
      return;
    }
    final effect = behavior.effect;
    final cooldownKey = _buildPlacedBehaviorCooldownKey(
      element: element,
      behavior: behavior,
      trigger: trigger,
    );
    final cooldownOverride = _resolvePlacedBehaviorCooldownOverride(behavior);
    if (!_placedBehaviorCooldownGate.canTrigger(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
    )) {
      final remainingMs = _placedBehaviorCooldownGate.remainingMs(
        key: cooldownKey,
        nowMs: _runtimeClockMs,
      );
      debugPrint(
        '[placed_behavior] cooldown blocked trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name} remainingMs=${remainingMs.toStringAsFixed(0)}',
      );
      _updateBehaviorDebugLine(
        'Cooldown ${effect.type.name} (${remainingMs.toStringAsFixed(0)} ms) · ${element.id}#${cooldownKey.behaviorId} (${behavior.triggerScope.name})',
      );
      return;
    }
    debugPrint(
      '[placed_behavior] trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name}',
    );
    var effectApplied = false;
    switch (effect.type) {
      case MapPlacedElementEffectType.showMessage:
        final text = effect.message?.trim() ?? '';
        if (text.isEmpty) {
          debugPrint(
            '[placed_behavior] showMessage ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=empty_message',
          );
          return;
        }
        _showNotification(text);
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.openDialogue:
        effectApplied =
            _tryOpenDialogue(element.id, effect.dialogue, element.elementId);
        break;
      case MapPlacedElementEffectType.setAnimationEnabled:
        final enabled = effect.animationEnabled;
        if (enabled == null) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=missing_value',
          );
          return;
        }
        final currentEnabled = _resolvePlacedElementAnimationEnabled(
          element.id,
        );
        if (currentEnabled == enabled) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_change value=$enabled',
          );
          _updateBehaviorDebugLine(
            'Animation déjà ${enabled ? 'active' : 'inactive'} · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        }
        _applyPlacedElementAnimationEnabled(
          instanceId: element.id,
          enabled: enabled,
        );
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.playAnimationOnce:
        final triggered =
            _playPlacedElementAnimationOnce(instanceId: element.id);
        if (!triggered) {
          debugPrint(
            '[placed_behavior] playAnimationOnce ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_animatable_frames',
          );
          _updateBehaviorDebugLine(
            'Animation 1x indisponible · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        } else {
          debugPrint(
            '[placed_behavior] playAnimationOnce started instance=${element.id} behavior=${cooldownKey.behaviorId} strategy=restart',
          );
        }
        effectApplied = true;
        break;
    }
    if (!effectApplied) {
      return;
    }
    _placedBehaviorCooldownGate.markTriggered(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
      overrideDuration: cooldownOverride,
    );
    _updateBehaviorDebugLine(
      'Triggered ${trigger.name}/${behavior.triggerScope.name} -> ${effect.type.name} · ${element.id}#${cooldownKey.behaviorId}',
    );
  }

  bool _playPlacedElementAnimationOnce({
    required String instanceId,
  }) {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return false;
    }
    final fromBackground =
        loaded.backgroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    final fromForeground =
        loaded.foregroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    return fromBackground || fromForeground;
  }

  void _applyPlacedElementAnimationEnabled({
    required String instanceId,
    required bool enabled,
  }) {
    try {
      final updatedMap = setMapPlacedElementAnimationEnabled(
        _world.map,
        instanceId: instanceId,
        enabled: enabled,
      );
      _world = GameplayWorldState.initial(
        map: updatedMap,
        playerPos: _world.player.pos,
        playerFacing: _world.player.facing,
        playerMovementMode: _world.player.movementMode,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
        mapEntityPresencePredicate:
            _mapEntityPresencePredicateFor(_bundle.manifest),
      );
      _bundle = _bundle.copyWith(
        map: updatedMap,
      );
      final activeLoaded = _loadedMapsById[_activeMapId];
      if (activeLoaded != null) {
        activeLoaded.backgroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        activeLoaded.foregroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        _loadedMapsById[_activeMapId] = _LoadedPlayableMap(
          bundle: _bundle,
          originCellX: activeLoaded.originCellX,
          originCellY: activeLoaded.originCellY,
          backgroundLayers: activeLoaded.backgroundLayers,
          foregroundLayers: activeLoaded.foregroundLayers,
          occlusionPatches: activeLoaded.occlusionPatches,
          npcActors: activeLoaded.npcActors,
          npcActorByEntityId: activeLoaded.npcActorByEntityId,
          tileImagesById: activeLoaded.tileImagesById,
        );
        _refreshProjectedBuildingShadowCollection(_bundle);
        _refreshStaticPlacedElementShadowCollection(_bundle);
      }
      debugPrint(
        '[placed_behavior] setAnimationEnabled applied instance=$instanceId enabled=$enabled',
      );
    } catch (e, st) {
      debugPrint(
        '[placed_behavior] setAnimationEnabled failed instance=$instanceId enabled=$enabled error=$e\n$st',
      );
      _showNotification('Animation update failed');
    }
  }

  bool _tryOpenDialogue(
    String entityId,
    DialogueRef? ref,
    String fallbackLabel, {
    bool allowAbsentEntity = false,
    void Function()? onLoadFailed,
  }) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) return false;
    if (_activeBlockingInteractionSerial != null) return false;
    if (_dialogueOverlay != null) return false;
    if (!allowAbsentEntity &&
        !_npcEntityAllowedOnActiveMapForDialogue(entityId)) {
      debugPrint('[dialogue] blocked: npc absent entityId=$entityId');
      return false;
    }

    final resolved = resolveDialogue(
      entityId: entityId,
      ref: ref,
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      _showNotification(fallbackLabel);
      return false;
    }

    final serial = _beginBlockingInteraction(
      source: entityId,
      pendingDialogueLoad: true,
    );
    final stopwatch = Stopwatch()..start();

    void failDialogueLoad({
      Object? error,
      StackTrace? stackTrace,
    }) {
      stopwatch.stop();
      if (!_isBlockingInteractionActive(serial)) {
        debugPrint(
          '[dialogue] stale response ignored source=$entityId serial=$serial',
        );
        return;
      }
      if (error == null) {
        debugPrint('[dialogue] failed to load session for entity=$entityId');
      } else {
        debugPrint(
          '[dialogue] failed to load source=$entityId error=$error'
          '${stackTrace == null ? '' : '\n$stackTrace'}',
        );
      }
      _releaseBlockingInteraction(
        serial: serial,
        source: entityId,
        reason: 'dialogueLoadFailed',
      );
      _pendingPostDialogueAction = null;
      _cancelNarrativeContinuationBarrier(entityId);
      _showNotification(fallbackLabel);
      onLoadFailed?.call();
    }

    late final Future<DialogueSession?> loadFuture;
    try {
      loadFuture = _dialogueSessionLoader(resolved);
    } catch (error, stackTrace) {
      failDialogueLoad(error: error, stackTrace: stackTrace);
      return false;
    }

    loadFuture.then((session) {
      stopwatch.stop();
      if (!_isBlockingInteractionActive(serial)) {
        debugPrint(
          '[dialogue] stale response ignored source=$entityId serial=$serial',
        );
        return;
      }
      if (session == null) {
        failDialogueLoad();
        return;
      }
      debugPrint(
        '[dialogue] content loaded source=$entityId elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      debugPrint('[dialogue] opening dialogue for entity=$entityId');
      _openDialogue(session);
    }).onError((Object error, StackTrace stackTrace) {
      failDialogueLoad(error: error, stackTrace: stackTrace);
    });
    return true;
  }

  void _openDialogue(
    DialogueSession session, {
    void Function(String? outcomeId)? onDialogueFinished,
  }) {
    session = interpolateDialogueVariables(
      session,
      _gameState.scriptVariables,
    );
    _notification?.removeFromParent();
    _notification = null;
    _setRuntimeNotificationSnapshot(null);
    _clearBlockingInteractionWithoutUnlock(reason: 'dialogueOpened');
    _clearPressedMovementControls();
    _setFlowPhase(_RuntimeFlowPhase.dialogue);

    final overlay = DialogueOverlayComponent(
      session: session,
      viewportSize: camera.viewport.size,
      textSpeed: _dialogueTextSpeed,
      renderInFlame: !_preferDialogueFlutterOverlay,
      onPresentationSnapshotChanged: _setDialoguePresentationSnapshot,
      onFinished: (outcomeId) {
        debugPrint('[dialogue] dialogue closed');
        _dialogueOverlay = null;
        _setDialoguePresentationSnapshot(null);
        _setFlowPhase(_RuntimeFlowPhase.overworld);
        _awaitingSurfConfirmation = false;
        final action = _pendingPostDialogueAction;
        _pendingPostDialogueAction = null;
        try {
          action?.call();
        } finally {
          onDialogueFinished?.call(outcomeId);
        }
      },
    );
    camera.viewport.add(overlay);
    _dialogueOverlay = overlay;
    final openedState = session.state;
    if (openedState is DialogueShowingLine) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} text="${openedState.text}"');
    } else if (openedState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} choice count=${openedState.choices.length}');
    }
  }

  void _advanceDialogue() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.advance();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  void _moveChoiceCursor(int delta) {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    overlay.moveCursor(delta);
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      debugPrint('[dialogue] choice moved selected=${state.selectedIndex}');
    }
  }

  void _confirmDialogueChoice() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      final idx = state.selectedIndex;
      debugPrint(
          '[dialogue] choice confirmed index=$idx text="${state.choices[idx].text}"');
      if (_awaitingSurfConfirmation) {
        if (idx == 0) {
          _pendingPostDialogueAction = () {
            setSurfingEnabled(true);
            debugPrint('[surf] mode activated via dialogue choice');
          };
        }
        _awaitingSurfConfirmation = false;
      }
    }
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.confirmChoice();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  /// Garde-fou : tout dialogue / combat PNJ passe par ici ou [_tryOpenDialogue].
  bool _npcEntityAllowedOnActiveMapForDialogue(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return true;
    }
    MapEntity? found;
    for (final e in _world.map.entities) {
      if (e.id == normalized) {
        found = e;
        break;
      }
    }
    if (found == null) {
      return true;
    }
    if (found.kind != MapEntityKind.npc) {
      return true;
    }
    return _npcPresencePredicateFor(_bundle.manifest)(
      _world.map.id,
      found,
    );
  }

  void _handleNpcInteraction(MapEntity entity) {
    if (!_npcPresencePredicateFor(_bundle.manifest)(_world.map.id, entity)) {
      debugPrint('[interact] ignored absent npc=${entity.id}');
      return;
    }
    final trainerId = entity.npc?.trainerId?.trim();

    // Cas 1: pas de trainerId → dialogue normal
    if (trainerId == null || trainerId.isEmpty) {
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Cas 2: trainerId invalide → log + fallback dialogue
    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint(
        '[battle] trainer not found: $trainerId for npc=${entity.id}, fallback to dialogue',
      );
      _showNotification('Dresseur introuvable.');
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Le cycle de vie tranche désormais entre dialogue, combat, rematch et
    // blocage one-shot. Une interaction manuelle peut explicitement relancer
    // un rematch même si le verrou LoS de la rencontre précédente est actif.
    _triggerTrainerBattle(entity, fromManualInteraction: true);
  }

  /// DEBUG-ONLY: Marque un trainer comme battu.
  ///
  /// **À n'utiliser qu'en debug/dev pour tester le flux de défaite.**
  /// Tant que le gameplay de combat n'est pas implémenté, ce mécanisme
  /// permet de simuler une victoire pour vérifier le defeat dialogue.
  ///
  /// En production, ce flag devrait être positionné automatiquement
  /// après une vraie victoire en combat.
  void debugMarkTrainerAsDefeated(String trainerId) {
    final trimmedId = trainerId.trim();
    if (trimmedId.isEmpty) {
      debugPrint('[debug] invalid trainerId, ignored');
      return;
    }
    _gameState = _storyFlags.markTrainerDefeated(_gameState, trimmedId);
    debugPrint('[debug] trainer $trimmedId marked as defeated');
    _refreshWorldNpcPresence();
  }

  /// Vérifie la Line of Sight (LoS) des trainers et déclenche automatiquement
  /// le battle si le joueur est détecté.
  ///
  /// **Conditions de déclenchement :**
  /// 1. Runtime stable : overworld, pas de dialogue, pas de battle pending
  /// 2. Trainer avec trainerId valide et lineOfSightRange > 0
  /// 3. Trainer non déjà battu (flag trainer_defeated:{id})
  /// 4. Joueur dans la LoS du trainer (checkLineOfSight)
  /// 5. Trainer pas déjà dans _triggeredTrainerBattles (anti-retrigger)
  ///
  /// **Réarmement :**
  /// - Quand le joueur sort de la LoS → lock retirée
  /// - Sur changement de map → toutes les locks retirées
  ///
  /// **Origine du calcul :**
  /// - Depuis entity.pos du NPC
  /// - Axe cardinal uniquement (nord/sud/est/ouest)
  /// - Aucune diagonale
  /// - Obstacles via world.isBlocked() sur les cases STRICTEMENT entre
  ///   le NPC et le joueur (exclut case du NPC et case du joueur)
  void _checkTrainerLineOfSight() {
    // Condition de stabilité runtime stricte
    if (_flowPhase != _RuntimeFlowPhase.overworld) return;
    if (_dialogueOverlay != null) return;
    if (_pendingBattleRequest != null) return;

    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!_npcPresencePredicateFor(_bundle.manifest)(
        _world.map.id,
        entity,
      )) {
        continue;
      }

      final trainerId = entity.npc?.trainerId;
      if (trainerId == null || trainerId.isEmpty) continue;

      final losRange = entity.npc?.lineOfSightRange ?? 0;
      if (losRange <= 0) continue;

      final trainer =
          _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
                (candidate) => candidate?.id == trainerId,
                orElse: () => null,
              );
      if (trainer == null) continue;

      // Les dresseurs one-shot restent inertes après leur défaite. Un trainer
      // explicitement rematchable peut se réarmer après sortie de sa LoS.
      if (_storyBranching.isTrainerDefeated(_gameState, trainerId) &&
          trainer.rematchPolicy != ProjectTrainerRematchPolicy.allowed) {
        continue;
      }

      // Anti-retrigger : ignorer si déjà déclenché dans cette session
      if (_triggeredTrainerBattles.contains(entity.id)) {
        // Réarmement : si joueur sort de LoS, retirer le lock
        final inLoS = checkLineOfSight(
          npcPos: entity.pos,
          npcFacing: entity.npc!.facing,
          lineOfSightRange: losRange,
          playerPos: _world.player.pos,
          world: _world,
        );
        if (!inLoS) {
          _triggeredTrainerBattles.remove(entity.id);
        }
        continue;
      }

      // Check LoS
      final inLoS = checkLineOfSight(
        npcPos: entity.pos,
        npcFacing: entity.npc!.facing,
        lineOfSightRange: losRange,
        playerPos: _world.player.pos,
        world: _world,
      );

      if (inLoS) {
        _triggerTrainerBattle(entity);
      }
    }
  }

  /// Déclenche un battle trainer (appelé par interaction manuelle OU LoS auto).
  ///
  /// **Gestion d'erreur :**
  /// - trainerId invalide → log + notification + pas de crash
  /// - Battle request null → log + pas de battle
  void _triggerTrainerBattle(
    MapEntity entity, {
    bool lifecycleDialogueHandled = false,
    bool fromManualInteraction = false,
  }) {
    final npc = entity.npc;
    final trainerId = npc?.trainerId;
    if (trainerId == null || trainerId.isEmpty) {
      debugPrint('[trainer] no trainerId for entity=${entity.id}');
      return;
    }

    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint('[trainer] not found trainer=$trainerId entity=${entity.id}');
      _showNotification('Dresseur introuvable.');
      return;
    }

    final isDefeated = _storyBranching.isTrainerDefeated(_gameState, trainerId);
    final plan = resolveRuntimeTrainerInteractionPlan(
      trainer: trainer,
      npc: npc!,
      isDefeated: isDefeated,
    );

    if (!lifecycleDialogueHandled) {
      switch (plan.disposition) {
        case RuntimeTrainerInteractionDisposition.dialogueOnly:
          debugPrint(
            '[trainer] defeated dialogue trainer=$trainerId entity=${entity.id}',
          );
          _tryOpenDialogue(
            entity.id,
            plan.dialogue,
            entity.inspectorHeadline,
          );
          return;
        case RuntimeTrainerInteractionDisposition.blocked:
          debugPrint('[trainer] already defeated trainer=$trainerId');
          _showNotification('Le dresseur est déjà vaincu.');
          return;
        case RuntimeTrainerInteractionDisposition.dialogueThenBattle:
          if (_triggeredTrainerBattles.contains(entity.id) &&
              !fromManualInteraction) {
            return;
          }
          _pendingPostDialogueAction = () => _triggerTrainerBattle(
                entity,
                lifecycleDialogueHandled: true,
                fromManualInteraction: fromManualInteraction,
              );
          final dialogueStarted = _tryOpenDialogue(
            entity.id,
            plan.dialogue,
            entity.inspectorHeadline,
          );
          if (dialogueStarted) {
            return;
          }
          _pendingPostDialogueAction = null;
          break;
        case RuntimeTrainerInteractionDisposition.battle:
          break;
      }
    }

    if (isDefeated &&
        trainer.rematchPolicy != ProjectTrainerRematchPolicy.allowed) {
      debugPrint('[trainer] already defeated trainer=$trainerId');
      return;
    }
    if (_triggeredTrainerBattles.contains(entity.id) &&
        !fromManualInteraction) {
      return;
    }

    // Créer battle request
    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
          '[trainer] battle triggered trainer=$trainerId entity=${entity.id}');
      _triggeredTrainerBattles.add(entity.id);
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      if (!_tryEnqueueBattleRequest(request)) {
        _triggeredTrainerBattles.remove(entity.id);
        debugPrint(
          '[trainer] battle request rejected: another Battle handoff is pending',
        );
      }
    } else {
      debugPrint(
          '[trainer] battle request failed trainer=$trainerId entity=${entity.id}');
    }
  }

  void _showNotification(String text) {
    _notification?.removeFromParent();
    _notification = null;
    _publishRuntimeNotification(text);
    final revision = _runtimeNotificationRevision;
    TextComponent? component;
    if (!_preferFlutterNotifications) {
      final paint = TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          backgroundColor: Color(0xAA000000),
        ),
      );
      component = TextComponent(
        text: text,
        textRenderer: paint,
        anchor: Anchor.topCenter,
      );
      component.position = Vector2(
        camera.viewport.size.x / 2,
        camera.viewport.size.y - 48,
      );
      camera.viewport.add(component);
      _notification = component;
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (_runtimeNotificationNotifier.value?.revision == revision) {
        component?.removeFromParent();
        if (_notification == component) {
          _notification = null;
        }
        _setRuntimeNotificationSnapshot(null);
      } else if (_notification == component) {
        component?.removeFromParent();
        _notification = null;
      }
    });
  }

  void _handleWaterBlocked() {
    final delta = _runtimeClockMs - _lastWaterRequiresSurfMessageAtMs;
    if (delta < _kWaterRequiresSurfMessageCooldownMs) {
      return;
    }
    _lastWaterRequiresSurfMessageAtMs = _runtimeClockMs;

    final evaluation = evaluateSurfAttempt(
      gameState: _gameState,
      isTargetWater: true,
    );
    final yarnNode = surfEvaluationToYarnNode(evaluation);
    if (yarnNode == null) {
      return;
    }

    final session = loadSurfDialogueSession(yarnNode);
    if (session == null) {
      debugPrint('[surf] failed to load dialogue node=$yarnNode');
      _showNotification(waterRequiresSurfFeedbackMessage);
      return;
    }

    debugPrint(
        '[surf] evaluation=${evaluation.runtimeType} -> dialogue=$yarnNode');

    if (evaluation is CanPromptSurf) {
      _awaitingSurfConfirmation = true;
    }
    _openDialogue(session);
  }

  /// Sauvegarde l'état actuel de la partie.
  ///
  /// Retourne `true` si la sauvegarde a réussi.
  Future<bool> saveGame() async {
    if (_hasCheckpointUnsafeRuntimeWorkForSave) {
      _logCheckpointInterlock('save');
      return false;
    }
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    if (kDebugMode) {
      debugPrint(
        '[step_studio_trace] runtime_save_requested map=$_activeMapId completedStepIds=${_gameState.progression.completedStepIds} completedCutsceneIds=${_gameState.progression.completedCutsceneIds}',
      );
    }
    return _saveGameUseCase.execute(_gameState);
  }

  /// Charge l'état de la partie et resync complètement le runtime.
  ///
  /// Retourne `true` si le chargement a réussi.
  /// Retourne `false` si aucune sauvegarde n'existe ou en cas d'échec.
  ///
  /// Effets de bord :
  /// - Modifie `_gameState`
  /// - Modifie `_activeMapId`
  /// - Recharge la map courante
  /// - Reconstruit `_world` avec la position/facing du joueur
  /// - Resync `_player` avec le nouveau `_world`
  /// - Resync caméra / streaming / bounds
  ///
  /// **Note** : Cette méthode ne restaure pas les overlays actifs (dialogue,
  /// battle transition) ni les états transitoires. Elle restaure uniquement
  /// l'état principal du runtime.
  ///
  /// La sauvegarde, la map cible et le monde sont préparés avant la mutation.
  /// Si le commit, le remontage ou le `mapEnter` final échoue, le snapshot
  /// runtime précédent est remonté et la sauvegarde fautive reste intacte.
  Future<bool> loadGame() async {
    if (_hasCheckpointUnsafeRuntimeWork) {
      _logCheckpointInterlock('load');
      return false;
    }
    _isLoadActivationWorkInFlight = true;
    if (_flowPhase == _RuntimeFlowPhase.overworld) {
      _clearPressedMovementControls();
    }
    try {
      return await _loadGameWithActivationWorkAcquired();
    } finally {
      _isLoadActivationWorkInFlight = false;
    }
  }

  Future<bool> _loadGameWithActivationWorkAcquired() async {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    final source = _LoadRuntimeSnapshot(
      gameState: _gameState,
      bundle: _bundle,
      world: _world,
      activeMapId: _activeMapId,
      previousMapId: _previousMapId,
      flowPhase: _flowPhase,
      currentMapActivationId: _currentMapActivationId,
      completedMapActivationDispatchCount: _completedMapActivationDispatchCount,
      lastCompletedMapActivation: _lastCompletedMapActivation,
    );

    // 1. Lire puis migrer la sauvegarde sans toucher au runtime courant.
    GameState? rawLoadedState;
    try {
      rawLoadedState = await _loadGameUseCase.executeOrThrow();
    } on GameSaveException catch (error, stackTrace) {
      debugPrint('[load] save is unreadable: $error\n$stackTrace');
      _showNotification(
        'Chargement impossible : la sauvegarde est illisible. '
        'La partie en cours et le fichier ont été conservés.',
      );
      return false;
    }
    if (rawLoadedState == null) {
      debugPrint('[load] no save found');
      return false;
    }
    late GameState loadedState;
    try {
      loadedState = normalizeLoadedGameState(rawLoadedState);
    } on Object catch (error, stackTrace) {
      debugPrint(
          '[load] save migration or validation failed: $error\n$stackTrace');
      _showNotification(
        'Chargement impossible : la sauvegarde est invalide. '
        'La partie en cours et le fichier ont été conservés.',
      );
      return false;
    }
    if (loadedState.currentMapId.trim().isEmpty) {
      debugPrint('[load] saved map id is empty');
      _showNotification(
        'Chargement impossible : la sauvegarde ne référence aucune map. '
        'La partie en cours a été conservée.',
      );
      return false;
    }
    final activation = _createMapActivation(
      mapId: loadedState.currentMapId,
      reason: MapActivationReason.saveRestore,
    );

    // 2. Charger et valider toutes les données/ressources avant la mutation.
    RuntimeMapBundle newBundle;
    try {
      newBundle = await _loadRuntimeMapBundleCached(loadedState.currentMapId);
      if (newBundle.map.id != loadedState.currentMapId) {
        throw StateError(
          'Loaded map ${newBundle.map.id} does not match saved map '
          '${loadedState.currentMapId}.',
        );
      }
      loadedState = await _hydrateOwnedPlayerPokemonProgression(
        loadedState,
        bundle: newBundle,
      );
    } catch (e, st) {
      debugPrint('[load] failed to load map or Pokemon catalogues: $e\n$st');
      _showNotification(
        'Chargement impossible : la map sauvegardée est indisponible. '
        'La partie en cours et la sauvegarde ont été conservées.',
      );
      return false;
    }

    Map<String, RuntimeTilesetImage> newImages;
    BorderRuntimeAssetBundle newBorderAssets;
    GameplayWorldState preparedWorld;
    try {
      newImages = await _loadTilesetImagesCached(
        newBundle.tilesetAbsolutePathsById,
        manifest: newBundle.manifest,
      );
      newBorderAssets = await _loadBorderRuntimeAssets(newBundle);
      newBundle = await prepareBorderRuntimeBundle(newBundle);
      if (!_isWithinMapBounds(newBundle.map, loadedState.playerPosition)) {
        throw StateError(
          'Saved player position ${loadedState.playerPosition} is outside '
          '${newBundle.map.id}.',
        );
      }
      preparedWorld = GameplayWorldState.initial(
        map: newBundle.map,
        project: newBundle.manifest,
        playerPos: loadedState.playerPosition,
        playerFacing: loadedState.playerFacing.asDirection,
        playerMovementMode: loadedState.playerMovementMode,
        tileWidth: newBundle.manifest.settings.tileWidth,
        tileHeight: newBundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(
          newBundle.manifest,
          gameStateOverride: loadedState,
          mapOverride: newBundle.map,
        ),
        mapEntityPresencePredicate: _mapEntityPresencePredicateFor(
          newBundle.manifest,
          gameStateOverride: loadedState,
          mapOverride: newBundle.map,
        ),
      );
      if (preparedWorld.isBlocked(
        loadedState.playerPosition.x,
        loadedState.playerPosition.y,
      )) {
        throw StateError(
          'Saved player position ${loadedState.playerPosition} is blocked '
          'on ${newBundle.map.id}.',
        );
      }
    } catch (e, st) {
      debugPrint('[load] failed to prepare restored world: $e\n$st');
      _showNotification(
        'Chargement impossible : le monde sauvegardé ne peut pas être '
        'reconstruit. La partie en cours et la sauvegarde ont été conservées.',
      );
      return false;
    }

    // 3. Commit atomique. Tout échec après ce point restaure [source].
    try {
      _gameState = loadedState;
      _clearTransientScenarioWorkForLoad();
      _clearTransientUiState();
      await _narrativeStateTransactions.transact<void>((_) {
        return NarrativeEventStateTransaction.commit(loadedState, null);
      });

      _unmountAllLoadedMaps();
      _bundle = newBundle;
      final root = await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        borderAssets: newBorderAssets,
        originCellX: 0,
        originCellY: 0,
      );

      _world = preparedWorld.withNpcMapPresencePredicate(
        _npcPresencePredicateFor(newBundle.manifest),
      );
      _world = _world.withMapEntityPresencePredicate(
        _mapEntityPresencePredicateFor(newBundle.manifest),
      );
      _activeMapId = loadedState.currentMapId;
      _previousMapId = null;
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _prewarmActiveMapBattleData();
      _pruneLoadedMapsToActiveNeighborhood();
      _applyDebugTileMarker();
      _resetTriggerEnterOccupancy();

      _refreshWorldNpcPresence();
      await beforeLoadCommitCompletion?.call();

      _setFlowPhase(_RuntimeFlowPhase.overworld);
      _installMapActivation(activation);
      final dispatchResult = await _dispatchCompletedMapActivation(activation);
      if (dispatchResult is MapEnterProductionDispatchFailed ||
          dispatchResult is MapEnterProductionDispatchAuthorityBlocked) {
        throw StateError(
          'saveRestore mapEnter rejected completion: '
          '${dispatchResult.runtimeType}',
        );
      }

      debugPrint('[load] game loaded from saveId=${loadedState.saveId}');
      return true;
    } catch (e, st) {
      debugPrint('[load] commit failed, rolling back: $e\n$st');
      final rolledBack = await _restoreFailedLoad(source);
      _showNotification(
        rolledBack
            ? 'Chargement annulé : la partie en cours et la sauvegarde ont '
                'été conservées. Vous pouvez réessayer.'
            : 'Chargement annulé et restauration visuelle incomplète. '
                'La sauvegarde n’a pas été modifiée ; relancez le jeu.',
      );
      return false;
    }
  }

  Future<bool> _restoreFailedLoad(_LoadRuntimeSnapshot source) async {
    try {
      _gameState = source.gameState;
      await _narrativeStateTransactions.transact<void>((_) {
        return NarrativeEventStateTransaction.commit(source.gameState, null);
      });

      var sourceBundle = await prepareBorderRuntimeBundle(source.bundle);
      final sourceImages = await _loadTilesetImagesCached(
        sourceBundle.tilesetAbsolutePathsById,
        manifest: sourceBundle.manifest,
      );
      final sourceBorderAssets = await _loadBorderRuntimeAssets(sourceBundle);

      _unmountAllLoadedMaps();
      _bundle = sourceBundle;
      _world = source.world.withNpcMapPresencePredicate(
        _npcPresencePredicateFor(sourceBundle.manifest),
      );
      _world = _world.withMapEntityPresencePredicate(
        _mapEntityPresencePredicateFor(sourceBundle.manifest),
      );
      _activeMapId = source.activeMapId;
      _previousMapId = source.previousMapId;
      final root = await _mountLoadedMap(
        bundle: sourceBundle,
        tileImagesById: sourceImages,
        borderAssets: sourceBorderAssets,
        originCellX: 0,
        originCellY: 0,
      );
      sourceBundle = root.bundle;
      _bundle = sourceBundle;
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _prewarmActiveMapWarpTargets();
      _prewarmActiveMapBattleData();
      _pruneLoadedMapsToActiveNeighborhood();
      _resetTriggerEnterOccupancy();
      _refreshWorldNpcPresence();
      _setFlowPhase(source.flowPhase);
      _currentMapActivationId = source.currentMapActivationId;
      _completedMapActivationDispatchCount =
          source.completedMapActivationDispatchCount;
      _lastCompletedMapActivation = source.lastCompletedMapActivation;
      debugPrint(
        '[load] rollback restored map=${source.activeMapId} '
        'pos=${source.world.player.pos}',
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('[load] rollback failed: $error\n$stackTrace');
      _gameState = source.gameState;
      _bundle = source.bundle;
      _world = source.world;
      _activeMapId = source.activeMapId;
      _previousMapId = source.previousMapId;
      _setFlowPhase(source.flowPhase);
      _currentMapActivationId = source.currentMapActivationId;
      _completedMapActivationDispatchCount =
          source.completedMapActivationDispatchCount;
      _lastCompletedMapActivation = source.lastCompletedMapActivation;
      return false;
    }
  }

  PlacedBehaviorRuntimeKey _buildPlacedBehaviorCooldownKey({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    final trimmedBehaviorId = behavior.id.trim();
    final behaviorId = trimmedBehaviorId.isEmpty ? 'legacy' : trimmedBehaviorId;
    return PlacedBehaviorRuntimeKey(
      instanceId: element.id,
      behaviorId: behaviorId,
      trigger: trigger,
      effectType: behavior.effect.type,
    );
  }

  Duration? _resolvePlacedBehaviorCooldownOverride(
    MapPlacedElementBehavior behavior,
  ) {
    final cooldownMs = behavior.cooldownMs;
    if (cooldownMs == null) {
      return null;
    }
    if (cooldownMs <= 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: cooldownMs);
  }

  bool _resolvePlacedElementAnimationEnabled(String instanceId) {
    for (final instance in _world.map.placedElements) {
      if (instance.id != instanceId) {
        continue;
      }
      return instance.animation?.enabled ?? false;
    }
    return false;
  }

  void _ensureBehaviorDebugOverlay() {
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    final existing = _behaviorDebugOverlay;
    if (existing != null) {
      existing.text = _lastBehaviorDebugLine;
      return;
    }
    final overlay = TextComponent(
      text: _lastBehaviorDebugLine,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          backgroundColor: Color(0xAA111111),
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 10),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _behaviorDebugOverlay = overlay;
  }

  void _ensureFpsOverlay() {
    if (!_showFpsOverlay) {
      return;
    }
    final existing = _fpsOverlay;
    if (existing != null) {
      existing.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
      return;
    }
    final overlay = TextComponent(
      text: 'FPS ${_currentFps.toStringAsFixed(1)}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.lightGreenAccent,
          backgroundColor: Color(0xAA111111),
          fontWeight: FontWeight.w600,
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 28),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _fpsOverlay = overlay;
  }

  void _updateFps(double dt) {
    _fpsAccumulatorSeconds += dt;
    _fpsFrameCount += 1;

    // Fenêtre courte de 250ms: stable sans être trop lente.
    if (_fpsAccumulatorSeconds < 0.25) {
      return;
    }
    _currentFps = _fpsFrameCount / _fpsAccumulatorSeconds;
    _fpsAccumulatorSeconds = 0.0;
    _fpsFrameCount = 0;

    if (_showFpsOverlay) {
      _ensureFpsOverlay();
      _fpsOverlay?.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
    }
  }

  void _updateBehaviorDebugLine(String line) {
    _lastBehaviorDebugLine = line;
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    _ensureBehaviorDebugOverlay();
    final overlay = _behaviorDebugOverlay;
    if (overlay == null) {
      return;
    }
    overlay.text = line;
  }

  Future<void> _handleWarp(
    TriggeredWarp warp, {
    bool allowMapActivationWork = false,
    bool skipVisualTransition = false,
  }) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld ||
        (!allowMapActivationWork && _blocksOverworldForMapActivationWork)) {
      debugPrint(
        '[warp] ignored: flow=${_flowPhase.name} '
        'loadActivationWork=$_isLoadActivationWorkInFlight '
        'activationDispatches=${_inFlightMapActivationDispatchIds.join(',')}',
      );
      return;
    }
    _setFlowPhase(_RuntimeFlowPhase.mapTransition);
    final activation = _createMapActivation(
      mapId: warp.targetMapId,
      reason: MapActivationReason.warp,
    );
    final sourceBundle = _bundle;
    final sourceWorld = _world;
    final sourceMapId = _activeMapId;
    final sourcePos = _world.player.pos;
    final sourceFacing = _world.player.facing;
    WarpTransitionOverlayComponent? overlay;
    var swapCompleted = false;
    try {
      _clearTransientUiState();
      if (!skipVisualTransition) {
        overlay = WarpTransitionOverlayComponent(
          viewportSize: camera.viewport.size,
        );
        camera.viewport.add(overlay);
        _warpTransitionOverlay = overlay;
      }
      debugPrint(
        '[warp] start transition warp=${warp.warpId} map=$sourceMapId -> ${warp.targetMapId} target=(${warp.targetPos.x}, ${warp.targetPos.y})',
      );
      final warpStopwatch = Stopwatch()..start();
      var newBundle = await _traceAsync(
        'warp',
        'loadBundle',
        () => _loadRuntimeMapBundleCached(warp.targetMapId),
      );
      debugPrint('[warp] target map loaded id=${newBundle.map.id}');
      final transitionSpec = _resolveWarpTransitionSpec(
        sourceMap: sourceBundle.map,
        targetMap: newBundle.map,
      );
      if (!skipVisualTransition &&
          transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade out durationMs=${transitionSpec.fadeOut.inMilliseconds}',
        );
        await overlay!.fadeOut(duration: transitionSpec.fadeOut);
      }
      if (!_isWithinMapBounds(newBundle.map, warp.targetPos)) {
        throw StateError(
          'warp target out of bounds map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y}) size=${newBundle.map.size.width}x${newBundle.map.size.height}',
        );
      }
      final newWorld = _traceSync(
        'warp',
        'worldInitial',
        () => GameplayWorldState.initial(
          map: newBundle.map,
          playerPos: warp.targetPos,
          playerFacing: sourceFacing,
          playerMovementMode: sourceWorld.player.movementMode,
          project: newBundle.manifest,
          tileWidth: newBundle.manifest.settings.tileWidth,
          tileHeight: newBundle.manifest.settings.tileHeight,
          npcMapPresencePredicate: _npcPresencePredicateFor(newBundle.manifest),
          mapEntityPresencePredicate:
              _mapEntityPresencePredicateFor(newBundle.manifest),
        ),
      );
      if (newWorld.isBlocked(warp.targetPos.x, warp.targetPos.y)) {
        throw StateError(
          'warp target blocked map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y})',
        );
      }
      debugPrint('[warp] loading target map visuals id=${newBundle.map.id}');
      final newImages = await _traceAsync(
        'warp',
        'loadTilesets',
        () => _loadTilesetImagesCached(
          newBundle.tilesetAbsolutePathsById,
          manifest: newBundle.manifest,
        ),
      );
      final newBorderAssets = await _traceAsync(
        'warp',
        'loadBorderAssets',
        () => _loadBorderRuntimeAssets(newBundle),
      );
      newBundle = await _traceAsync(
        'warp',
        'revalidateBorderBeforeSwap',
        () => prepareBorderRuntimeBundle(newBundle),
      );
      _unmountAllLoadedMaps();
      final root = await _traceAsync(
        'warp',
        'mountMap',
        () => _mountLoadedMap(
          bundle: newBundle,
          tileImagesById: newImages,
          borderAssets: newBorderAssets,
          originCellX: 0,
          originCellY: 0,
        ),
      );
      _bundle = newBundle;
      _world = newWorld;
      _activeMapId = newBundle.map.id;
      _previousMapId = null;
      _triggeredTrainerBattles.clear(); // Reset LoS locks on map change
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      swapCompleted = true;
      debugPrint(
        '[warp] player placed at map=${newBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      _traceSync('warp', 'configureCamera', () {
        _configureCameraViewport();
        _syncCameraToPlayer();
      });
      _traceSync('warp', 'preloadConnectionsKickoff', () {
        _preloadActiveMapConnections();
      });
      _traceSync('warp', 'prewarmWarpsKickoff', () {
        _prewarmActiveMapWarpTargets();
      });
      _traceSync('warp', 'prewarmBattleKickoff', () {
        _prewarmActiveMapBattleData();
      });
      _traceSync('warp', 'pruneLoadedMaps', () {
        _pruneLoadedMapsToActiveNeighborhood();
      });
      _traceSync('warp', 'refreshWorldNpcPresence', () {
        _refreshWorldNpcPresence();
      });
      if (!skipVisualTransition &&
          transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade in durationMs=${transitionSpec.fadeIn.inMilliseconds}',
        );
        await overlay!.fadeIn(duration: transitionSpec.fadeIn);
      }
      warpStopwatch.stop();
      debugPrint('[perf][warp] total=${warpStopwatch.elapsedMilliseconds}ms');
      debugPrint('[warp] transition completed');
    } catch (e, st) {
      debugPrint('[warp] transition failed: $e\n$st');
      _showNotification('Warp failed');
      if (!swapCompleted) {
        await _recoverFromWarpFailure(
          sourceBundle: sourceBundle,
          sourceWorld: sourceWorld,
          sourceMapId: sourceMapId,
        );
      }
      if (overlay != null) {
        await overlay.fadeIn(duration: const Duration(milliseconds: 140));
      }
    } finally {
      _warpTransitionOverlay?.close();
      _warpTransitionOverlay = null;
      _setFlowPhase(_RuntimeFlowPhase.overworld);
      debugPrint(
        '[warp] gameplay unlocked map=$_activeMapId pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      final pendingLeaderWarpHandoff = _pendingScenarioLeaderWarpHandoff;
      if (pendingLeaderWarpHandoff != null) {
        final ownsHandledWarp = pendingLeaderWarpHandoff.matches(warp);
        final reachedExpectedTarget = ownsHandledWarp &&
            swapCompleted &&
            _activeMapId == pendingLeaderWarpHandoff.targetMapId &&
            _world.player.pos == pendingLeaderWarpHandoff.targetPos;
        if (reachedExpectedTarget) {
          debugPrint(
            '[scenario_runtime] followCharacter playerWarpHandoff '
            'leader=${pendingLeaderWarpHandoff.leaderEntityId} '
            'map=$_activeMapId pos=(${_world.player.pos.x},${_world.player.pos.y}) '
            'source=${pendingLeaderWarpHandoff.runtimeSourceId ?? 'non_awaited'}',
          );
          if (_pendingScenarioFollowRequest?.leaderEntityId ==
              pendingLeaderWarpHandoff.leaderEntityId) {
            _pendingScenarioFollowRequest = null;
          }
          _pendingScenarioLeaderWarpHandoff = null;
          debugPrint(
            '[scenario_runtime] followCharacter completed leader=${pendingLeaderWarpHandoff.leaderEntityId} reason=warp_handoff',
          );
        } else {
          if (_pendingScenarioFollowRequest?.leaderEntityId ==
              pendingLeaderWarpHandoff.leaderEntityId) {
            _pendingScenarioFollowRequest = null;
          }
          _pendingScenarioLeaderWarpHandoff = null;
          debugPrint(
            '[scenario_runtime] followCharacter canceled '
            'leader=${pendingLeaderWarpHandoff.leaderEntityId} '
            'reason=${ownsHandledWarp ? 'warp_handoff_failed' : 'wrong_warp'} '
            'expectedMap=${pendingLeaderWarpHandoff.targetMapId} '
            'actualMap=$_activeMapId '
            'expectedPos=(${pendingLeaderWarpHandoff.targetPos.x},${pendingLeaderWarpHandoff.targetPos.y}) '
            'actualPos=(${_world.player.pos.x},${_world.player.pos.y})',
          );
        }
      }
      if (swapCompleted) {
        _installMapActivation(activation);
        _resetTriggerEnterOccupancy();
        await _dispatchCompletedMapActivation(activation);
      }
      if (_activeMapId == sourceMapId &&
          _world.player.pos.x == sourcePos.x &&
          _world.player.pos.y == sourcePos.y) {
        _player.syncState(_world.player, snapToGrid: true);
      }
    }
  }

  _WarpTransitionSpec _resolveWarpTransitionSpec({
    required MapData sourceMap,
    required MapData targetMap,
  }) {
    final sourceIndoor = sourceMap.mapMetadata.isIndoor ||
        sourceMap.mapMetadata.mapType == MapType.building ||
        sourceMap.mapMetadata.mapType == MapType.interior ||
        sourceMap.mapMetadata.mapType == MapType.cave ||
        sourceMap.mapMetadata.mapType == MapType.facility;
    final targetIndoor = targetMap.mapMetadata.isIndoor ||
        targetMap.mapMetadata.mapType == MapType.building ||
        targetMap.mapMetadata.mapType == MapType.interior ||
        targetMap.mapMetadata.mapType == MapType.cave ||
        targetMap.mapMetadata.mapType == MapType.facility;
    final duration = sourceIndoor == targetIndoor
        ? const Duration(milliseconds: 170)
        : const Duration(milliseconds: 230);
    return _WarpTransitionSpec(
      style: _WarpTransitionStyle.fade,
      fadeOut: duration,
      fadeIn: duration,
    );
  }

  Future<void> _recoverFromWarpFailure({
    required RuntimeMapBundle sourceBundle,
    required GameplayWorldState sourceWorld,
    required String sourceMapId,
  }) async {
    if (_loadedMapsById.isNotEmpty && _activeMapId == sourceMapId) {
      _bundle = sourceBundle;
      _world = sourceWorld;
      _syncGameStateFromWorld(mapIdOverride: sourceMapId);
      _player.syncState(_world.player, snapToGrid: true);
      _configureCameraViewport();
      _syncCameraToPlayer();
      debugPrint('[warp] rollback no-op (source map still mounted)');
      return;
    }

    try {
      var fallbackBundle = await _loadRuntimeMapBundleCached(sourceMapId);
      final fallbackWorld = _buildSafeWorldState(
        map: fallbackBundle.map,
        project: fallbackBundle.manifest,
        preferredPos: sourceWorld.player.pos,
        fallbackFacing: sourceWorld.player.facing,
        tileWidth: fallbackBundle.manifest.settings.tileWidth,
        tileHeight: fallbackBundle.manifest.settings.tileHeight,
      );
      final fallbackImages = await _loadTilesetImagesCached(
        fallbackBundle.tilesetAbsolutePathsById,
        manifest: fallbackBundle.manifest,
      );
      final fallbackBorderAssets =
          await _loadBorderRuntimeAssets(fallbackBundle);
      fallbackBundle = await prepareBorderRuntimeBundle(fallbackBundle);
      _unmountAllLoadedMaps();
      final root = await _mountLoadedMap(
        bundle: fallbackBundle,
        tileImagesById: fallbackImages,
        borderAssets: fallbackBorderAssets,
        originCellX: 0,
        originCellY: 0,
      );
      _bundle = fallbackBundle;
      _world = fallbackWorld;
      _activeMapId = fallbackBundle.map.id;
      _previousMapId = null;
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _prewarmActiveMapBattleData();
      _pruneLoadedMapsToActiveNeighborhood();
      debugPrint(
        '[warp] rollback restored map=${fallbackBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } catch (e, st) {
      debugPrint('[warp] rollback failed: $e\n$st');
    }
  }

  GameplayWorldState _buildSafeWorldState({
    required MapData map,
    required ProjectManifest project,
    required GridPos preferredPos,
    required Direction fallbackFacing,
    required int tileWidth,
    required int tileHeight,
  }) {
    final safePos = _isWithinMapBounds(map, preferredPos)
        ? preferredPos
        : const GridPos(x: 0, y: 0);
    final world = GameplayWorldState.initial(
      map: map,
      playerPos: safePos,
      playerFacing: fallbackFacing,
      project: project,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(project),
      mapEntityPresencePredicate: _mapEntityPresencePredicateFor(project),
    );
    if (!world.isBlocked(safePos.x, safePos.y)) {
      return world;
    }

    try {
      final spawn = resolveInitialPlayerSpawn(map);
      final spawnWorld = GameplayWorldState.initial(
        map: map,
        playerPos: spawn.pos,
        playerFacing: fallbackFacing,
        project: project,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(project),
        mapEntityPresencePredicate: _mapEntityPresencePredicateFor(project),
      );
      if (!spawnWorld.isBlocked(spawn.pos.x, spawn.pos.y)) {
        return spawnWorld;
      }
    } catch (_) {}

    for (var y = 0; y < map.size.height; y++) {
      for (var x = 0; x < map.size.width; x++) {
        if (!world.isBlocked(x, y)) {
          return GameplayWorldState.initial(
            map: map,
            playerPos: GridPos(x: x, y: y),
            playerFacing: fallbackFacing,
            project: project,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            npcMapPresencePredicate: _npcPresencePredicateFor(project),
            mapEntityPresencePredicate: _mapEntityPresencePredicateFor(project),
          );
        }
      }
    }

    return world;
  }

  bool _isWithinMapBounds(MapData map, GridPos pos) {
    return pos.x >= 0 &&
        pos.y >= 0 &&
        pos.x < map.size.width &&
        pos.y < map.size.height;
  }

  Future<void> _handleConnection(TriggeredConnection connection) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld ||
        _blocksOverworldForMapActivationWork) {
      debugPrint(
        '[connection] ignored: flow=${_flowPhase.name} '
        'loadActivationWork=$_isLoadActivationWorkInFlight '
        'activationDispatches=${_inFlightMapActivationDispatchIds.join(',')}',
      );
      return;
    }
    _setFlowPhase(_RuntimeFlowPhase.mapTransition);
    final activation = _createMapActivation(
      mapId: connection.targetMapId,
      reason: MapActivationReason.connection,
    );
    var transitionCompleted = false;
    final connectionStopwatch = Stopwatch()..start();
    try {
      _clearTransientUiState();
      final sourcePlayerScreenTopLeft = debugPlayerScreenTopLeft;
      final sourceCameraWorldTopLeft = debugCameraWorldTopLeft;
      debugPrint(
        '[connection] attempting map=${_bundle.map.id} direction=${connection.direction.name} target=${connection.targetMapId} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y})',
      );
      final source = _loadedMapsById[_activeMapId];
      if (source == null) {
        debugPrint(
            '[connection] source map visuals missing for id=$_activeMapId');
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      final target = await _ensureConnectionTargetLoaded(
        source: source,
        connection: connection,
      );
      if (target == null) {
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      debugPrint('[connection] resolved target map=${target.bundle.map.id}');
      final targetPos = resolveConnectedMapTargetPos(
        sourcePos: connection.sourcePos,
        sourceSize: source.bundle.map.size,
        targetSize: target.bundle.map.size,
        direction: connection.direction,
        offset: connection.offset,
      );
      if (targetPos == null) {
        debugPrint(
          '[connection] invalid entry coordinates direction=${connection.direction.name} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y}) sourceSize=${source.bundle.map.size.width}x${source.bundle.map.size.height} targetSize=${target.bundle.map.size.width}x${target.bundle.map.size.height}',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection invalid');
        return;
      }
      debugPrint(
        '[connection] computed entry pos=(${targetPos.x}, ${targetPos.y})',
      );
      final newWorld = GameplayWorldState.initial(
        map: target.bundle.map,
        playerPos: targetPos,
        playerFacing: _world.player.facing,
        playerMovementMode: _world.player.movementMode,
        project: target.bundle.manifest,
        tileWidth: target.bundle.manifest.settings.tileWidth,
        tileHeight: target.bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate:
            _npcPresencePredicateFor(target.bundle.manifest),
        mapEntityPresencePredicate:
            _mapEntityPresencePredicateFor(target.bundle.manifest),
      );
      if (newWorld.isBlocked(targetPos.x, targetPos.y)) {
        debugPrint(
          '[connection] blocked entry map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection blocked');
        return;
      }
      _bundle = target.bundle;
      _world = newWorld;
      _previousMapId = _activeMapId;
      _activeMapId = target.bundle.map.id;
      _resetScriptedNpcMovementController();
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      final targetOriginPx = _originPixelsOf(target);
      final entryStartCell = _connectionEntryStartCell(
        targetPos: targetPos,
        direction: connection.direction,
      );
      final entryStartTopLeft = _worldTopLeftForPlayerSpawnCell(
        bundle: target.bundle,
        mapOrigin: targetOriginPx,
        cell: GridPos(x: entryStartCell.x, y: entryStartCell.y),
        playerState: _world.player,
      );
      _player.setMapOrigin(targetOriginPx, snapToGrid: false);
      _player.startVisualStepFromWorldTopLeft(
        _world.player,
        fromWorldTopLeft: entryStartTopLeft,
      );
      _configureCameraViewport();
      final continuityCameraWorldTopLeft = Vector2(
        entryStartTopLeft.x - sourcePlayerScreenTopLeft.x,
        entryStartTopLeft.y - sourcePlayerScreenTopLeft.y,
      );
      _setCameraWorldTopLeft(continuityCameraWorldTopLeft);
      final visibleSize = camera.viewfinder.visibleGameSize;
      debugPrint(
        '[connection] camera after transition focus=(${_player.focusPoint.x.toStringAsFixed(1)}, ${_player.focusPoint.y.toStringAsFixed(1)}) viewport=(${(visibleSize?.x ?? 0).toStringAsFixed(1)}, ${(visibleSize?.y ?? 0).toStringAsFixed(1)})',
      );
      debugPrint(
        '[connection] screen continuity sourceScreen=(${sourcePlayerScreenTopLeft.x.toStringAsFixed(1)}, ${sourcePlayerScreenTopLeft.y.toStringAsFixed(1)}) targetStartScreen=(${debugPlayerScreenTopLeft.x.toStringAsFixed(1)}, ${debugPlayerScreenTopLeft.y.toStringAsFixed(1)}) sourceCameraTopLeft=(${sourceCameraWorldTopLeft.x.toStringAsFixed(1)}, ${sourceCameraWorldTopLeft.y.toStringAsFixed(1)}) targetCameraTopLeft=(${debugCameraWorldTopLeft.x.toStringAsFixed(1)}, ${debugCameraWorldTopLeft.y.toStringAsFixed(1)})',
      );
      debugPrint(
        '[connection] visual entry step direction=${connection.direction.name} fromCell=(${entryStartCell.x},${entryStartCell.y}) toCell=(${targetPos.x},${targetPos.y}) durationMs=${(PlayerComponent.kDefaultStepSeconds * 1000).round()}',
      );
      _preloadActiveMapConnections();
      _prewarmActiveMapWarpTargets();
      _prewarmActiveMapBattleData();
      _pruneLoadedMapsToActiveNeighborhood();
      _refreshWorldNpcPresence();
      _pendingConnectionEntryAnimation = _PendingConnectionEntryAnimation(
        mapId: target.bundle.map.id,
        initialCameraWorldTopLeft: continuityCameraWorldTopLeft,
        activation: activation,
      );
      connectionStopwatch.stop();
      debugPrint(
        '[perf][connection] total=${connectionStopwatch.elapsedMilliseconds}ms',
      );
      transitionCompleted = true;
    } catch (e, st) {
      debugPrint('[connection] transition failed: $e\n$st');
      _player.syncState(_world.player, snapToGrid: true);
      _showNotification('Connection failed');
    } finally {
      if (!transitionCompleted) {
        _setFlowPhase(_RuntimeFlowPhase.overworld);
      }
      if (transitionCompleted && _pendingConnectionEntryAnimation == null) {
        _installMapActivation(activation);
        _resetTriggerEnterOccupancy();
        await _dispatchCompletedMapActivation(activation);
      }
    }
  }

  void _clearTransientScenarioWorkForLoad() {
    _cancelCutsceneForLoad();
    _pendingCutsceneChoiceRequest = null;

    final battleOwner = _pendingScenarioBattleHandoff;
    _pendingScenarioBattleHandoff = null;
    if (battleOwner != null) {
      _cancelNarrativeContinuationBarrier(battleOwner.runtimeSourceId);
    }

    final warpOwner = _pendingScenarioWarpHandoff;
    if (warpOwner != null) {
      if (warpOwner.matches(_pendingWarp)) {
        _pendingWarp = null;
      }
      _cancelOwnedScenarioWarpContinuation(warpOwner);
      _pendingScenarioWarpHandoff = null;
    }

    final moveContinuations = _pendingScenarioMoveContinuationsByEntity.values
        .toList(growable: false);
    _pendingScenarioMoveContinuationsByEntity.clear();
    for (final continuation in moveContinuations) {
      _cancelNarrativeContinuationBarrier(continuation.runtimeSourceId);
    }

    // A successful load is a hard lifetime boundary for work owned by the old
    // map. None of these owners may observe or complete against the restored
    // GameState on a later update tick.
    _pendingScenarioFollowRequest = null;
    _pendingScenarioTransitionMapRequest = null;
    _pendingScenarioNpcWarpEntries.clear();
    _pendingScenarioLeaderWarpHandoff = null;
    _pendingScenarioReachedEndQueue.clear();
    _lastScenarioCompletionBlockReason = null;
    _lastFollowPathNodeCount = 0;
    _lastFollowPathDestination = null;

    _activeScriptController = null;
    _activeScriptRuntimeSourceId = null;
  }

  void _clearTransientUiState() {
    _cinematicRuntimeController.cancel(
      message: 'Cinematic playback was cancelled by transient UI reset.',
    );
    _pendingWarp = null;
    _pendingConnection = null;
    _pendingConnectionEntryAnimation = null;
    _pendingPostDialogueAction = null;
    _awaitingSurfConfirmation = false;
    _clearBlockingInteractionWithoutUnlock(reason: 'clearTransientUiState');
    // CRITICAL: Do NOT clear _pendingBattleRequest if a battle is active!
    // This would cancel a pending wild encounter battle.
    // Only clear if we're in overworld phase (no battle in progress).
    if (_flowPhase == _RuntimeFlowPhase.overworld) {
      _pendingBattleRequest = null;
    }
    _pendingPlacedElementBehavior = null;
    _notification?.removeFromParent();
    _notification = null;
    _setRuntimeNotificationSnapshot(null);
    _completePendingSceneDialogue(
      const SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
        message: 'Scene dialogue was cancelled by transient UI reset.',
      ),
    );
    _dialogueOverlay?.removeFromParent();
    _dialogueOverlay = null;
    _setDialoguePresentationSnapshot(null);
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _setBattleCommandOverlaySnapshot(null);
    // Blindage défensif lot 10 :
    // ce reset central est utilisé par plusieurs chemins runtime (load, warp,
    // connection). Si un contexte battle survivait ici, on garderait en
    // mémoire un slot party et une requête de combat qui ne correspondent plus
    // à l'état overworld courant. On l'efface donc explicitement avec le reste
    // de l'UI transitoire.
    _activeBattleContext = null;
    _psdkBattleSession = null;
    _warpTransitionOverlay?.removeFromParent();
    _warpTransitionOverlay = null;
    _clearPressedMovementControls();
  }

  void _unmountAllLoadedMaps() {
    final ids = _loadedMapsById.keys.toList(growable: false);
    for (final id in ids) {
      _unmountLoadedMap(id);
    }
    _loadedMapsById.clear();
    _loadMapFutureById.clear();
  }

  void _applyDebugTileMarker() {
    _debugTileMarkerFill?.removeFromParent();
    _debugTileMarkerFill = null;
    _debugTileMarkerBorder?.removeFromParent();
    _debugTileMarkerBorder = null;
    _debugTileMarkerText?.removeFromParent();
    _debugTileMarkerText = null;

    final pos = _debugTileMarkerPos;
    if (pos == null) {
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return;
    }
    final origin = _originPixelsOf(loaded);
    final x = origin.x + pos.x * _cellWidth;
    final y = origin.y + pos.y * _cellHeight;
    final size = Vector2(_cellWidth, _cellHeight);

    final fill = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()..color = const ui.Color(0x66FF9800),
      priority: 150000,
    );
    final border = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()
        ..color = const ui.Color(0xFFFF6D00)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
      priority: 150001,
    );
    world.add(fill);
    world.add(border);
    _debugTileMarkerFill = fill;
    _debugTileMarkerBorder = border;

    final label = _debugTileMarkerLabel?.trim();
    if (label == null || label.isEmpty) {
      return;
    }
    final text = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(x + 2, y + 2),
      priority: 150002,
    );
    world.add(text);
    _debugTileMarkerText = text;
  }

  void _clearNpcCollisionDebugOverlay() {
    final ids = _npcCollisionDebugByEntityId.keys.toList(growable: false);
    for (final id in ids) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _syncNpcCollisionDebugOverlay() {
    if (!_showNpcCollisionDebugOverlay) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final origin = _originPixelsOf(loaded);
    final seen = <String>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final actor = loaded.npcActorByEntityId[entity.id];
      if (actor == null) {
        continue;
      }
      seen.add(entity.id);
      final visual = _npcCollisionDebugByEntityId.putIfAbsent(entity.id, () {
        final spriteRect = RectangleComponent(
          priority: 200000,
          paint: ui.Paint()
            ..color = const ui.Color(0xAA00E5FF)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final collisionRect = RectangleComponent(
          priority: 200001,
          paint: ui.Paint()
            ..color = const ui.Color(0xAAFF1744)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final anchorMarker = CircleComponent(
          radius: 3.0,
          priority: 200002,
          paint: ui.Paint()..color = const ui.Color(0xFFFFEA00),
        );
        world.add(spriteRect);
        world.add(collisionRect);
        world.add(anchorMarker);
        return _NpcCollisionDebugVisual(
          spriteRect: spriteRect,
          collisionRect: collisionRect,
          anchorMarker: anchorMarker,
        );
      });

      // 1) Bounding box visuelle réelle du sprite.
      visual.spriteRect
        ..position = actor.position.clone()
        ..size = actor.size.clone();

      // 2) Footprint collision gameplay (grille -> pixels).
      final footprint = resolveEntityCollisionFootprint(entity);
      visual.collisionRect
        ..position = Vector2(
          origin.x + footprint.pos.x * _cellWidth,
          origin.y + footprint.pos.y * _cellHeight,
        )
        ..size = Vector2(
          footprint.size.width * _cellWidth,
          footprint.size.height * _cellHeight,
        );

      // 3) Point d'ancrage logique MapEntity.pos (top-left cellule logique).
      visual.anchorMarker.position = Vector2(
        origin.x + entity.pos.x * _cellWidth + (_cellWidth / 2) - 3,
        origin.y + entity.pos.y * _cellHeight + (_cellHeight / 2) - 3,
      );
    }

    final stale = _npcCollisionDebugByEntityId.keys
        .where((id) => !seen.contains(id))
        .toList(growable: false);
    for (final id in stale) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _unmountLoadedMap(String mapId) {
    _clearNpcCollisionDebugOverlay();
    final loaded = _loadedMapsById.remove(mapId);
    if (loaded == null) {
      return;
    }
    loaded.backgroundLayers.removeFromParent();
    loaded.foregroundLayers.removeFromParent();
    for (final patch in loaded.occlusionPatches) {
      patch.removeFromParent();
    }
    for (final actor in loaded.npcActors) {
      actor.removeFromParent();
      _npcActors.remove(actor);
    }
    _projectedBuildingShadowCollectionByMapId.remove(mapId);
    _staticShadowCollectionByMapId.remove(mapId);
    _mergedShadowCollectionCacheByMapId.remove(mapId);
    _worldRuleProjectionCacheByMapId.remove(mapId);
  }

  Future<_LoadedPlayableMap> _mountLoadedMap({
    required RuntimeMapBundle bundle,
    required Map<String, RuntimeTilesetImage> tileImagesById,
    BorderRuntimeAssetBundle? borderAssets,
    required int originCellX,
    required int originCellY,
  }) async {
    final preparedBundle = await prepareBorderRuntimeBundle(bundle);
    final resolvedBorderAssets =
        borderAssets ?? await _loadBorderRuntimeAssets(preparedBundle);
    final npcPred = _npcPresencePredicateFor(preparedBundle.manifest);
    final backgroundLayers = MapLayersComponent(
      bundle: preparedBundle,
      tileImagesByTilesetId: tileImagesById,
      showCollisionOverlay: _showCollisionOverlay,
      npcMapPresencePredicate: npcPred,
      mapEntityPresencePredicate:
          _mapEntityPresencePredicateFor(preparedBundle.manifest),
      shadowCollectionProvider:
          _shadowCollectionProviderForMap(preparedBundle.map.id),
      borderAssets: resolvedBorderAssets,
    );
    backgroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    backgroundLayers.priority = 0;
    await world.add(backgroundLayers);

    final foregroundLayers = MapLayersComponent(
      bundle: preparedBundle,
      tileImagesByTilesetId: tileImagesById,
      renderPass: MapLayerRenderPass.foreground,
      showCollisionOverlay: false,
      npcMapPresencePredicate: npcPred,
      mapEntityPresencePredicate:
          _mapEntityPresencePredicateFor(preparedBundle.manifest),
    );
    foregroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    foregroundLayers.priority = 100000;
    await world.add(foregroundLayers);

    final occlusionPatches = <PlacedElementOcclusionPatchComponent>[];
    final occlusionInstructions =
        resolveStaticPlacedElementOcclusionPatchInstructions(
      bundle: preparedBundle,
      originCellX: originCellX,
      originCellY: originCellY,
    );
    for (final instruction in occlusionInstructions) {
      final tilesetImage = tileImagesById[instruction.tilesetId];
      if (tilesetImage == null) {
        continue;
      }
      final patch = PlacedElementOcclusionPatchComponent(
        instruction: instruction,
        tilesetImage: tilesetImage,
        visibleWorldRectProvider: () => camera.visibleWorldRect,
      );
      occlusionPatches.add(patch);
      await world.add(patch);
    }

    final npcActors = <OverworldActorComponent>[];
    final npcActorByEntityId = <String, OverworldActorComponent>{};
    final charById = {
      for (final c in preparedBundle.manifest.characters) c.id: c,
    };
    final cw = preparedBundle.cellWidth;
    final ch = preparedBundle.cellHeight;
    final originPx =
        _originPixels(originCellX: originCellX, originCellY: originCellY);
    for (final entity in preparedBundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!npcPred(preparedBundle.map.id, entity)) {
        // Pas de création d'acteur si la règle runtime dit "absent".
        debugPrint(
          '[step_studio_trace] npc_mount_skipped map=${preparedBundle.map.id} entity=${entity.id} reason=presence_predicate_false',
        );
        continue;
      }
      final charId = resolveNpcCharacterId(entity, preparedBundle.manifest);
      if (charId == null || charId.isEmpty) continue;
      final char = charById[charId];
      if (char == null) continue;
      final actor = OverworldActorComponent(
        character: char,
        tileImages: tileImagesById,
        tileWidth: preparedBundle.manifest.settings.tileWidth,
        tileHeight: preparedBundle.manifest.settings.tileHeight,
        cellWidth: cw,
        cellHeight: ch,
        facing: entity.npc?.facing ?? EntityFacing.south,
      );
      actor.configureGridPlacement(
        pos: entity.pos,
        footprint: entity.size,
        mapOrigin: originPx,
        snapToGrid: true,
      );
      npcActors.add(actor);
      npcActorByEntityId[entity.id] = actor;
      _npcActors.add(actor);
      await world.add(actor);
      debugPrint(
        '[step_studio_trace] npc_mount_added map=${preparedBundle.map.id} entity=${entity.id}',
      );
    }

    final loaded = _LoadedPlayableMap(
      bundle: preparedBundle,
      originCellX: originCellX,
      originCellY: originCellY,
      backgroundLayers: backgroundLayers,
      foregroundLayers: foregroundLayers,
      occlusionPatches: occlusionPatches,
      npcActors: npcActors,
      npcActorByEntityId: npcActorByEntityId,
      tileImagesById: tileImagesById,
    );
    _loadedMapsById[preparedBundle.map.id] = loaded;
    _runtimeBundleByMapId[preparedBundle.map.id] = preparedBundle;
    _refreshProjectedBuildingShadowCollection(preparedBundle);
    _refreshStaticPlacedElementShadowCollection(preparedBundle);
    _applyNpcVisibilityToLoadedMap(loaded);
    return loaded;
  }

  Future<_LoadedPlayableMap?> _ensureConnectionTargetLoaded({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
  }) async {
    final targetMapId = connection.targetMapId;
    final existing = _loadedMapsById[targetMapId];
    if (existing != null) {
      final expected = _computeConnectedOriginCells(
        source: source,
        connection: connection,
        targetSize: existing.bundle.map.size,
      );
      if (expected.x != existing.originCellX ||
          expected.y != existing.originCellY) {
        debugPrint(
          '[connection] origin mismatch target=$targetMapId existing=(${existing.originCellX}, ${existing.originCellY}) expected=(${expected.x}, ${expected.y})',
        );
        return _repositionLoadedMap(
          existing,
          originCellX: expected.x,
          originCellY: expected.y,
        );
      }
      return existing;
    }
    final inFlight = _loadMapFutureById[targetMapId];
    if (inFlight != null) {
      return await inFlight;
    }

    Future<_LoadedPlayableMap?> load() async {
      try {
        final bundle = await _loadRuntimeMapBundleCached(targetMapId);
        final origin = _computeConnectedOriginCells(
          source: source,
          connection: connection,
          targetSize: bundle.map.size,
        );
        final images = await _loadTilesetImagesCached(
          bundle.tilesetAbsolutePathsById,
          manifest: bundle.manifest,
        );
        final loaded = await _mountLoadedMap(
          bundle: bundle,
          tileImagesById: images,
          originCellX: origin.x,
          originCellY: origin.y,
        );
        debugPrint(
          '[connection] loaded map=${bundle.map.id} origin=(${origin.x}, ${origin.y})',
        );
        return loaded;
      } catch (e, st) {
        debugPrint(
            '[connection] load failed target=$targetMapId error=$e\n$st');
        return null;
      }
    }

    final future = load();
    _loadMapFutureById[targetMapId] = future;
    try {
      return await future;
    } finally {
      final current = _loadMapFutureById[targetMapId];
      if (identical(current, future)) {
        _loadMapFutureById.remove(targetMapId);
      }
    }
  }

  _GridCellPos _computeConnectedOriginCells({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
    required GridSize targetSize,
  }) {
    return switch (connection.direction) {
      MapConnectionDirection.east => _GridCellPos(
          x: source.originCellX + source.bundle.map.size.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.west => _GridCellPos(
          x: source.originCellX - targetSize.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.north => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY - targetSize.height,
        ),
      MapConnectionDirection.south => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY + source.bundle.map.size.height,
        ),
    };
  }

  _LoadedPlayableMap _repositionLoadedMap(
    _LoadedPlayableMap loaded, {
    required int originCellX,
    required int originCellY,
  }) {
    final oldOriginPx = _originPixels(
      originCellX: loaded.originCellX,
      originCellY: loaded.originCellY,
    );
    final originPx = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    final originDelta = originPx - oldOriginPx;
    loaded.backgroundLayers.position = originPx.clone();
    loaded.foregroundLayers.position = originPx.clone();
    for (final patch in loaded.occlusionPatches) {
      patch.translateByMapOriginDelta(originDelta);
    }
    for (final entity in loaded.bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final actor = loaded.npcActorByEntityId[entity.id];
      if (actor == null) {
        continue;
      }
      actor.configureGridPlacement(
        pos: entity.pos,
        footprint: entity.size,
        mapOrigin: originPx,
        snapToGrid: true,
      );
    }
    final updated = _LoadedPlayableMap(
      bundle: loaded.bundle,
      originCellX: originCellX,
      originCellY: originCellY,
      backgroundLayers: loaded.backgroundLayers,
      foregroundLayers: loaded.foregroundLayers,
      occlusionPatches: loaded.occlusionPatches,
      npcActors: loaded.npcActors,
      npcActorByEntityId: loaded.npcActorByEntityId,
      tileImagesById: loaded.tileImagesById,
    );
    _loadedMapsById[loaded.bundle.map.id] = updated;
    return updated;
  }

  void _preloadActiveMapConnections() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final connection in active.bundle.map.connections) {
      _ensureConnectionTargetLoaded(
        source: active,
        connection: TriggeredConnection(
          direction: connection.direction,
          targetMapId: connection.targetMapId,
          offset: connection.offset,
          sourcePos: _world.player.pos,
        ),
      );
    }
  }

  void _prewarmActiveMapWarpTargets() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final warp in active.bundle.map.warps) {
      _prewarmWarpTargetResources(warp.targetMapId);
    }
  }

  void _prewarmWarpTargetResources(String targetMapId) {
    final normalizedTargetMapId = targetMapId.trim();
    if (normalizedTargetMapId.isEmpty) {
      return;
    }
    final inFlight = _prewarmedWarpTargetFutureByMapId[normalizedTargetMapId];
    if (inFlight != null) {
      return;
    }

    late final Future<void> future;
    future = () async {
      try {
        final bundle = await _loadRuntimeMapBundleCached(normalizedTargetMapId);
        await _loadTilesetImagesCached(
          bundle.tilesetAbsolutePathsById,
          manifest: bundle.manifest,
        );
        await _loadBorderRuntimeAssets(bundle);
      } catch (error, stackTrace) {
        debugPrint(
          '[perf][warp][real] prewarmTargetFailed map=$normalizedTargetMapId error=$error\n$stackTrace',
        );
      } finally {
        final current =
            _prewarmedWarpTargetFutureByMapId[normalizedTargetMapId];
        if (identical(current, future)) {
          _prewarmedWarpTargetFutureByMapId.remove(normalizedTargetMapId);
        }
      }
    }();

    _prewarmedWarpTargetFutureByMapId[normalizedTargetMapId] = future;
  }

  void _prewarmActiveMapBattleData() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    final prewarmKey = [
      active.bundle.map.id,
      ..._gameState.party.members.map((member) => member.speciesId.trim()),
    ].join('|');
    final inFlight = _prewarmedBattleDataFutureByKey[prewarmKey];
    if (inFlight != null) {
      return;
    }

    final completer = Completer<void>();
    _prewarmedBattleDataFutureByKey[prewarmKey] = completer.future;
    unawaited(() async {
      try {
        final speciesIds = _collectActiveMapBattleSpeciesIds(active.bundle);
        final backgroundPaths =
            _collectBattleBackgroundPathsForBundle(active.bundle).toList();
        if (speciesIds.isEmpty && backgroundPaths.isEmpty) {
          return;
        }
        if (!await _canPrewarmBattleData(active.bundle)) {
          return;
        }
        await _battleMoveCatalogLoader.load(
          projectRootDirectory: active.bundle.projectRootDirectory,
          pokemonConfig: active.bundle.manifest.pokemon,
        );
        for (final speciesId in speciesIds) {
          final species = await _battleSpeciesLoader.loadById(
            projectRootDirectory: active.bundle.projectRootDirectory,
            pokemonConfig: active.bundle.manifest.pokemon,
            speciesId: speciesId,
          );
          await _battleLearnsetLoader.loadByRef(
            projectRootDirectory: active.bundle.projectRootDirectory,
            pokemonConfig: active.bundle.manifest.pokemon,
            speciesRef: species.learnsetRef,
            fallbackSpeciesId: species.id,
          );
          await _prewarmBattleSpriteAssetsForSpecies(species.id);
        }
        for (final backgroundPath in backgroundPaths) {
          await _battleVisualAssetCache.prewarmImage(backgroundPath);
        }
      } catch (error, stackTrace) {
        debugPrint(
          '[perf][battle][real] prewarmActiveMapDataFailed map=${active.bundle.map.id} error=$error\n$stackTrace',
        );
      } finally {
        final current = _prewarmedBattleDataFutureByKey[prewarmKey];
        if (identical(current, completer.future)) {
          _prewarmedBattleDataFutureByKey.remove(prewarmKey);
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }());
  }

  Future<bool> _canPrewarmBattleData(RuntimeMapBundle bundle) async {
    final movesCatalogPath = _resolveProjectPath(
      bundle.projectRootDirectory,
      bundle.manifest.pokemon.catalogFiles['moves']?.trim() ?? '',
    );
    if (movesCatalogPath == null || !await File(movesCatalogPath).exists()) {
      return false;
    }

    final speciesDirectoryPath = _resolveProjectPath(
      bundle.projectRootDirectory,
      _normalizeConfiguredRelativePath(
        bundle.manifest.pokemon.speciesDir,
        fallback: 'data/pokemon/species',
      ),
    );
    if (speciesDirectoryPath == null ||
        !await Directory(speciesDirectoryPath).exists()) {
      return false;
    }

    return true;
  }

  String _normalizeConfiguredRelativePath(
    String? configuredPath, {
    required String fallback,
  }) {
    final normalized = configuredPath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }
    return normalized;
  }

  String? _resolveProjectPath(
    String projectRootDirectory,
    String relativeOrAbsolutePath,
  ) {
    final normalizedPath = relativeOrAbsolutePath.trim();
    if (normalizedPath.isEmpty) {
      return null;
    }
    if (p.isAbsolute(normalizedPath)) {
      return p.normalize(normalizedPath);
    }
    return p.normalize(p.join(projectRootDirectory, normalizedPath));
  }

  Set<String> _collectActiveMapBattleSpeciesIds(RuntimeMapBundle bundle) {
    final speciesIds = <String>{};
    for (final member in _gameState.party.members) {
      final speciesId = member.speciesId.trim();
      if (speciesId.isNotEmpty) {
        speciesIds.add(speciesId);
      }
    }

    for (final zone in bundle.map.gameplayZones) {
      if (zone.kind != GameplayZoneKind.encounter) {
        continue;
      }
      final tableId = zone.encounter?.encounterTableId?.trim() ?? '';
      if (tableId.isEmpty) {
        continue;
      }
      final table = _findEncounterTable(bundle.manifest, tableId);
      if (table == null) {
        continue;
      }
      for (final entry in table.entries) {
        final speciesId = entry.speciesId.trim();
        if (speciesId.isNotEmpty) {
          speciesIds.add(speciesId);
        }
      }
    }

    for (final entity in bundle.map.entities) {
      final trainerId = entity.npc?.trainerId?.trim() ?? '';
      if (trainerId.isEmpty) {
        continue;
      }
      final trainer = _findTrainerEntry(bundle.manifest, trainerId);
      if (trainer == null) {
        continue;
      }
      for (final teamMember in trainer.team) {
        final speciesId = teamMember.speciesId.trim();
        if (speciesId.isNotEmpty) {
          speciesIds.add(speciesId);
        }
      }
    }

    return speciesIds;
  }

  Iterable<String> _collectBattleBackgroundPathsForBundle(
    RuntimeMapBundle bundle,
  ) sync* {
    for (final zone in bundle.map.gameplayZones) {
      final relativePath =
          zone.encounter?.battleBackgroundRelativePath?.trim() ?? '';
      if (relativePath.isEmpty) {
        continue;
      }
      yield p.normalize(p.join(bundle.projectRootDirectory, relativePath));
    }

    for (final entity in bundle.map.entities) {
      final trainerId = entity.npc?.trainerId?.trim() ?? '';
      if (trainerId.isEmpty) {
        continue;
      }
      final trainer = _findTrainerEntry(bundle.manifest, trainerId);
      final relativePath = trainer?.battleBackgroundRelativePath?.trim() ?? '';
      if (relativePath.isEmpty) {
        continue;
      }
      yield p.normalize(p.join(bundle.projectRootDirectory, relativePath));
    }
  }

  ProjectEncounterTable? _findEncounterTable(
    ProjectManifest manifest,
    String encounterTableId,
  ) {
    for (final table in manifest.encounterTables) {
      if (table.id == encounterTableId) {
        return table;
      }
    }
    return null;
  }

  ProjectTrainerEntry? _findTrainerEntry(
    ProjectManifest manifest,
    String trainerId,
  ) {
    for (final trainer in manifest.trainers) {
      if (trainer.id == trainerId) {
        return trainer;
      }
    }
    return null;
  }

  Future<void> _prewarmBattleSpriteAssetsForSpecies(String speciesId) async {
    final enemySpriteSpec = await _battleSpriteResolver.resolve(
      speciesId: speciesId,
      isPlayerSide: false,
    );
    final playerSpriteSpec = await _battleSpriteResolver.resolve(
      speciesId: speciesId,
      isPlayerSide: true,
    );

    final enemySpritePath = enemySpriteSpec.explicitImageAbsolutePath?.trim();
    if (enemySpritePath != null && enemySpritePath.isNotEmpty) {
      await _battleVisualAssetCache.prewarmSprite(enemySpritePath);
    }
    final playerSpritePath = playerSpriteSpec.explicitImageAbsolutePath?.trim();
    if (playerSpritePath != null && playerSpritePath.isNotEmpty) {
      await _battleVisualAssetCache.prewarmSprite(playerSpritePath);
    }
  }

  void _pruneLoadedMapsToActiveNeighborhood() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    final keep = <String>{
      active.bundle.map.id,
      ...active.bundle.map.connections.map((c) => c.targetMapId),
    };
    final previousMapId = _previousMapId;
    if (previousMapId != null && previousMapId.isNotEmpty) {
      keep.add(previousMapId);
    }
    final toRemove = _loadedMapsById.keys
        .where((id) => !keep.contains(id))
        .toList(growable: false);
    for (final id in toRemove) {
      _unmountLoadedMap(id);
    }
  }

  Vector2 _originPixels({
    required int originCellX,
    required int originCellY,
  }) {
    return Vector2(originCellX * _cellWidth, originCellY * _cellHeight);
  }

  Vector2 _originPixelsOf(_LoadedPlayableMap map) {
    return _originPixels(
      originCellX: map.originCellX,
      originCellY: map.originCellY,
    );
  }

  ProjectCharacterEntry? _resolvePlayerCharacter(RuntimeMapBundle bundle) {
    final selectedCharacterId =
        _gameState.trainerProfile.avatarCharacterId?.trim();
    if (selectedCharacterId != null && selectedCharacterId.isNotEmpty) {
      final selected = bundle.manifest.characters
          .where((character) => character.id == selectedCharacterId)
          .firstOrNull;
      if (selected != null) return selected;
    }
    return resolveDefaultPlayerCharacter(bundle.manifest);
  }

  void _faceNpcTowardPlayer(String entityId) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return;
    }
    final playerFacing = _world.player.facing;
    final npcFacing = switch (playerFacing) {
      Direction.north => EntityFacing.south,
      Direction.south => EntityFacing.north,
      Direction.east => EntityFacing.west,
      Direction.west => EntityFacing.east,
    };
    actor.setMotion(npcFacing, CharacterAnimationState.idle);
  }

  /// Construit le runner cutscene MVP avec callbacks runtime concrets.
  ///
  /// Le runner reste découplé de Flame; `PlayableMapGame` lui injecte juste
  /// les opérations nécessaires.
  CutsceneRuntimeRunner _buildCutsceneRuntimeRunner() {
    return CutsceneRuntimeRunner(
      context: CutsceneRuntimeContext(
        openDialogue: (dialogueId, {startNode}) {
          return _openScenarioDialogueById(
            dialogueId,
            startNode: startNode,
            runtimeSourceId: 'cutscene',
          );
        },
        isDialogueOpen: () => _dialogueOverlay != null,
        requestChoice: (request) {
          _pendingCutsceneChoiceRequest = request;
          return true;
        },
        resolveCutsceneById: _findRuntimeCutsceneById,
        moveNpcTo: ({required entityId, required destination}) {
          return startScriptedNpcMove(
            entityId: entityId,
            destination: destination,
          );
        },
        readNpcMovementStatus: (entityId) {
          return scriptedNpcMovementStatus(entityId);
        },
        faceNpc: ({required entityId, required facing}) {
          return _setNpcFacing(entityId, facing);
        },
        emitOutcome: (outcomeId) {
          _emitCutsceneOutcome(outcomeId);
        },
        setFlag: (flagName) {
          _gameState = _storyFlags.set(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        clearFlag: (flagName) {
          _gameState = _storyFlags.clear(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        isFlagSet: (flagName) => _storyFlags.isSet(_gameState, flagName),
        isOutcomeSet: (outcomeId) =>
            _storyFlags.isSet(_gameState, scenarioOutcomeFlagName(outcomeId)),
      ),
    );
  }

  RuntimeCutsceneAsset? _findRuntimeCutsceneById(String cutsceneId) {
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final candidate in runtimeCutscenes) {
      if (candidate.id == normalized) {
        return candidate;
      }
    }
    return null;
  }

  /// Oriente explicitement un PNJ (étape `faceNpc` de cutscene).
  ///
  /// On met à jour:
  /// - l'acteur visuel (immédiat),
  /// - la map runtime en mémoire (facing npc), pour rester cohérent avec les
  ///   futures logiques gameplay lisant l'orientation d'entité.
  bool _setNpcFacing(String entityId, EntityFacing facing) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    actor.setMotion(facing, CharacterAnimationState.idle);

    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return true;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return true;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: _world.player.pos,
      playerFacing: _world.player.facing,
      playerMovementMode: _world.player.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      mapEntityPresencePredicate:
          _mapEntityPresencePredicateFor(_bundle.manifest),
    );
    _bundle = _bundle.copyWith(
      map: updatedMap,
    );
    return true;
  }

  /// Émet un outcome depuis une cutscene.
  ///
  /// MVP:
  /// 1) on persiste l'outcome comme flag `scenario.outcome.*`,
  /// 2) on tente une transition vers un scénario global via `sourceOutcome`.
  void _emitCutsceneOutcome(String outcomeId) {
    final normalized = outcomeId.trim();
    if (normalized.isEmpty) {
      return;
    }
    _gameState =
        _storyFlags.set(_gameState, scenarioOutcomeFlagName(normalized));
    _refreshWorldNpcPresence();
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.outcomeReceived(
        outcomeId: normalized,
      ),
    );
  }

  /// (Re)crée le contrôleur de déplacement scripté pour la map active.
  ///
  /// Cette méthode est appelée:
  /// - au chargement initial,
  /// - après warp/connection/load game (changement de map).
  ///
  /// On repart à chaque fois d'un snapshot propre des PNJ actifs pour éviter
  /// toute dérive d'état entre maps.
  void _resetScriptedNpcMovementController() {
    _runtimeNpcPositions
      ..clear()
      ..addAll(_collectCurrentNpcPositions());
    _runtimeNpcPositions['player'] = _world.player.pos;
    _scriptedNpcReservedOccupiedCellsByEntity.clear();

    final controller = ScriptedEntityMovementController(
      mapSize: _world.map.size,
      isCellBlocked: _isNpcCellBlockedForRoutePlanning,
      startEntityStep: _startScriptedNpcStep,
      isEntityStepping: _isScriptedNpcStepping,
      onEntityPositionCommitted: _commitScriptedNpcPosition,
      validateEntityStep: _validateScriptedNpcStepRuntimeCollision,
    );
    controller.replaceTrackedEntities(_runtimeNpcPositions);
    _scriptedEntityMovementController = controller;
    _applyNpcOverworldDefaultMovement();
  }

  void _applyNpcOverworldDefaultMovement() {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return;
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        controller.stopPatrol(entity.id);
        continue;
      }
      final route = resolveNpcDefaultPatrolRoute(entity);
      if (route == null) {
        controller.stopPatrol(entity.id);
        continue;
      }
      controller.startPatrol(route);
    }
  }

  Map<String, GridPos> _collectCurrentNpcPositions() {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return const <String, GridPos>{};
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    final byId = <String, GridPos>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        continue;
      }
      // On ne suit que les PNJ présents **et** encore montés en acteur.
      if (!loaded.npcActorByEntityId.containsKey(entity.id)) {
        continue;
      }
      byId[entity.id] = entity.pos;
    }
    return byId;
  }

  bool _isNpcCellBlockedForRoutePlanning(
    int x,
    int y, {
    String? ignoreEntityId,
  }) {
    final normalizedIgnore = ignoreEntityId?.trim();
    if (normalizedIgnore == null || normalizedIgnore.isEmpty) {
      return _world.isBlocked(x, y);
    }
    if (normalizedIgnore == 'player') {
      final mode = _world.player.movementMode;
      if (_world.movementBlockReasonAt(
            x: x,
            y: y,
            movementMode: mode,
          ) !=
          null) {
        return true;
      }
      return _isScriptedNpcDynamicallyBlockedCell(
        GridPos(x: x, y: y),
        ignoreEntityId: 'player',
      );
    }

    // Pathfinding anchor validation:
    // - `x,y` est la position logique MapEntity.pos (top-left),
    // - on valide le footprint collision réel (important pour NPC 2x2),
    // - on ignore l'auto-collision de l'entité courante.
    //
    // Ce callback tourne une fois par nœud A* expansé : l'entité et ses
    // offsets de collision sont préparés une fois par (entité, monde), et le
    // blocage dynamique interroge l'état vivant sans matérialiser de Set.
    final prepared = _npcRoutePlanningProbeFor(normalizedIgnore);
    if (prepared == null) {
      return true;
    }
    final probe = prepared.probe!.evaluate(
      world: _world,
      anchorPos: GridPos(x: x, y: y),
      movementMode: MovementMode.walk,
      isDynamicallyBlocked: prepared.isDynamicallyBlocked,
    );
    // Le log (avec sa jointure de footprint) ne doit exister qu'en debug.
    if (kDebugMode && !probe.passable) {
      debugPrint(
        '[npc_patrol] blocked anchor entity=$normalizedIgnore anchor=($x,$y) reason="${probe.reason}" footprint=${probe.evaluatedCollisionCells.map((c) => '(${c.x},${c.y})').join(',')}',
      );
    }
    return !probe.passable;
  }

  _PreparedNpcRoutePlanningProbe? _cachedNpcRoutePlanningProbe;

  /// Sonde préparée mémoïsée par (entité, identité du monde). `_world` est
  /// remplacé par une nouvelle instance à chaque mutation (commits de
  /// position, warps), donc le test d'identité suffit à invalider.
  _PreparedNpcRoutePlanningProbe? _npcRoutePlanningProbeFor(String entityId) {
    final cached = _cachedNpcRoutePlanningProbe;
    if (cached != null &&
        cached.entityId == entityId &&
        identical(cached.world, _world)) {
      return cached.probe == null ? null : cached;
    }
    final probe = PreparedScriptedNpcAnchorProbe.forEntity(
      world: _world,
      entityId: entityId,
    );
    final prepared = _PreparedNpcRoutePlanningProbe(
      entityId: entityId,
      world: _world,
      probe: probe,
      isDynamicallyBlocked: (cell) => _isScriptedNpcDynamicallyBlockedCell(
        cell,
        ignoreEntityId: entityId,
      ),
    );
    _cachedNpcRoutePlanningProbe = prepared;
    return probe == null ? null : prepared;
  }

  /// Équivalent requêtable de [_scriptedNpcDynamicBlockedCells] : interroge
  /// l'état vivant (position joueur, cellule pieds rendue, réservations) sans
  /// matérialiser l'énumération — donc jamais périmé, même quand les
  /// réservations changent au milieu d'un tick.
  bool _isScriptedNpcDynamicallyBlockedCell(
    GridPos cell, {
    String? ignoreEntityId,
  }) {
    final activeFollowLeader = _pendingScenarioFollowRequest?.leaderEntityId;
    final ignorePlayerForLeader = activeFollowLeader != null &&
        ignoreEntityId != null &&
        ignoreEntityId == activeFollowLeader;
    if (!ignorePlayerForLeader) {
      final canonical = _world.player.pos;
      if (canonical.x == cell.x && canonical.y == cell.y) {
        return true;
      }
      final rendered = _renderedPlayerFootGridCell();
      if (rendered != null &&
          rendered.x == cell.x &&
          rendered.y == cell.y) {
        return true;
      }
    }
    return _isCellReservedByScriptedNpc(cell, ignoreEntityId: ignoreEntityId);
  }

  String? _validateScriptedNpcStepRuntimeCollision({
    required String entityId,
    required GridPos from,
    required GridPos to,
  }) {
    if (entityId.trim() == 'player') {
      final mode = _world.player.movementMode;
      final block = _world.movementBlockReasonAt(
        x: to.x,
        y: to.y,
        movementMode: mode,
      );
      if (block != null) {
        debugPrint(
          '[npc_patrol] runtime step rejected entity=player from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason=${block.name}',
        );
        return block.name;
      }
      for (final cell
          in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
        if (cell.x == to.x && cell.y == to.y) {
          debugPrint(
            '[npc_patrol] runtime step rejected entity=player to=(${to.x},${to.y}) reason=dynamic_blocker',
          );
          return 'Dynamic blocker at destination.';
        }
      }
      return null;
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: to,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] runtime step rejected entity=$entityId from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason="${probe.reason}"',
      );
      return probe.reason;
    }
    return null;
  }

  /// Cellules dynamiques à bloquer pour un pas NPC scripté.
  ///
  /// Frontière conceptuelle:
  /// - collision "statique" (layers + entités map) => via GameplayWorldState;
  /// - collision "dynamique" hors map entities (joueur) => injectée ici.
  ///
  /// On inclut volontairement:
  /// 1) la cellule logique canonique du joueur (`_world.player.pos`);
  /// 2) la cellule visuelle actuelle au niveau des pieds du player pendant
  ///    l'interpolation de pas.
  ///
  /// Le point (2) évite les traversées visuelles quand la simulation logique a
  /// déjà commité un déplacement joueur mais que le sprite est encore en train
  /// d'animer son pas.
  Iterable<GridPos> _scriptedNpcDynamicBlockedCells({
    String? ignoreEntityId,
  }) sync* {
    final activeFollowLeader = _pendingScenarioFollowRequest?.leaderEntityId;
    final ignorePlayerForLeader = activeFollowLeader != null &&
        ignoreEntityId != null &&
        ignoreEntityId == activeFollowLeader;

    if (!ignorePlayerForLeader) {
      final canonical = _world.player.pos;
      yield canonical;

      final rendered = _renderedPlayerFootGridCell();
      if (rendered != null &&
          (rendered.x != canonical.x || rendered.y != canonical.y)) {
        yield rendered;
      }
    }

    // Réservations de destination des autres PNJ en cours de pas.
    for (final entry in _scriptedNpcReservedOccupiedCellsByEntity.entries) {
      if (ignoreEntityId != null && entry.key == ignoreEntityId) {
        continue;
      }
      yield* entry.value;
    }
  }

  GridPos? _renderedPlayerFootGridCell() {
    final origin = _player.mapOrigin;
    if (_cellWidth <= 0 || _cellHeight <= 0) {
      return null;
    }
    final foot = _player.footPoint;
    final cellX = ((foot.x - origin.x) / _cellWidth).floor();
    final cellY = ((foot.y - 1 - origin.y) / _cellHeight).floor();
    if (cellX < 0 ||
        cellY < 0 ||
        cellX >= _world.map.size.width ||
        cellY >= _world.map.size.height) {
      return null;
    }
    return GridPos(x: cellX, y: cellY);
  }

  bool _startScriptedNpcStep({
    required String entityId,
    required GridPos from,
    required GridPos to,
    required EntityFacing facing,
    double? durationSeconds,
  }) {
    if (entityId.trim() == 'player') {
      final walkFacing = _directionFromEntityFacing(facing);
      final nextState = _gridAlignedPlayerState(
        position: to,
        facing: walkFacing,
      );
      _player.startStep(
        nextState,
        durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
      );
      _reserveScriptedNpcStepOccupiedCells(
        entityId: entityId,
        fromAnchorPos: from,
        toAnchorPos: to,
      );
      return true;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    final started = actor.startGridStep(
      to: to,
      facing: facing,
      durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
    );
    if (!started) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return false;
    }
    _reserveScriptedNpcStepOccupiedCells(
      entityId: entityId,
      fromAnchorPos: from,
      toAnchorPos: to,
    );
    return true;
  }

  bool _isScriptedNpcStepping(String entityId) {
    if (entityId.trim() == 'player') {
      return _player.isStepping;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    return actor?.isStepping ?? false;
  }

  void _commitScriptedNpcPosition(String entityId, GridPos position) {
    if (entityId.trim() == 'player') {
      final from = _world.player.pos;
      final facing = _directionBetweenAdjacent(from: from, to: position) ??
          _world.player.facing;
      _world = _world.withPlayer(
        _gridAlignedPlayerState(
          position: position,
          facing: facing,
        ),
      );
      _runtimeNpcPositions['player'] = position;
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld();
      return;
    }
    _runtimeNpcPositions[entityId] = position;
    _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
    _world = _world.withEntityPosition(entityId, position);
  }

  bool _isCellReservedByScriptedNpc(
    GridPos cell, {
    String? ignoreEntityId,
  }) {
    for (final entry in _scriptedNpcReservedOccupiedCellsByEntity.entries) {
      if (ignoreEntityId != null && entry.key == ignoreEntityId) {
        continue;
      }
      final cells = entry.value;
      if (cells.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  GameplayPlayerState _gridAlignedPlayerState({
    required GridPos position,
    Direction? facing,
    MovementMode? movementMode,
  }) {
    final current = _world.player;
    return GameplayPlayerState.fromGridSpawn(
      cell: position,
      facing: facing ?? current.facing,
      movementMode: movementMode ?? current.movementMode,
      tileWidthPx: _bundle.manifest.settings.tileWidth,
      tileHeightPx: _bundle.manifest.settings.tileHeight,
      mapWidthCells: _world.map.size.width,
      mapHeightCells: _world.map.size.height,
      spriteWidthPx: current.playerSpriteWidthPx,
      spriteHeightPx: current.playerSpriteHeightPx,
    );
  }

  void _reserveScriptedNpcStepOccupiedCells({
    required String entityId,
    required GridPos fromAnchorPos,
    required GridPos toAnchorPos,
  }) {
    if (entityId.trim() == 'player') {
      _scriptedNpcReservedOccupiedCellsByEntity[entityId] = <GridPos>{
        GridPos(x: fromAnchorPos.x, y: fromAnchorPos.y),
        GridPos(x: toAnchorPos.x, y: toAnchorPos.y),
      };
      return;
    }
    final entity = _world.map.entities
        .where((candidate) => candidate.id == entityId)
        .cast<MapEntity?>()
        .firstWhere((candidate) => candidate != null, orElse: () => null);
    if (entity == null) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }

    // Réservation "anti-traversée visuelle":
    // - footprint collision de la destination (cohérence gameplay stricte),
    // - footprint visuel grille du NPC sur source + destination (cohérence
    //   perceptuelle pendant l'interpolation visuelle du sprite).
    final reserved = <GridPos>{}
      ..addAll(_resolveEntityCollisionCellsAtAnchor(entity, toAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, fromAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, toAnchorPos));
    if (reserved.isEmpty) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }
    _scriptedNpcReservedOccupiedCellsByEntity[entityId] = reserved;
  }

  Set<GridPos> _resolveEntityCollisionCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final moved = entity.copyWith(pos: anchorPos);
    return resolveEntityCollisionCells(moved).where(_isInMapBounds).toSet();
  }

  Set<GridPos> _resolveEntityVisualCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final cells = <GridPos>{};
    for (var dy = 0; dy < entity.size.height; dy++) {
      for (var dx = 0; dx < entity.size.width; dx++) {
        final cell = GridPos(
          x: anchorPos.x + dx,
          y: anchorPos.y + dy,
        );
        if (_isInMapBounds(cell)) {
          cells.add(cell);
        }
      }
    }
    return cells;
  }

  bool _isInMapBounds(GridPos cell) {
    return cell.x >= 0 &&
        cell.y >= 0 &&
        cell.x < _world.map.size.width &&
        cell.y < _world.map.size.height;
  }

  double get _cellWidth =>
      _bundle.manifest.settings.tileWidth *
      _bundle.manifest.settings.displayScale;

  double get _cellHeight =>
      _bundle.manifest.settings.tileHeight *
      _bundle.manifest.settings.displayScale;

  void _configureCameraViewport() {
    final cw = _bundle.cellWidth;
    final ch = _bundle.cellHeight;
    final mw = _bundle.map.size.width * cw;
    final mh = _bundle.map.size.height * ch;
    final vw = math.min(_kViewportTilesX * cw, mw);
    final vh = math.min(_kViewportTilesY * ch, mh);
    camera.viewfinder.visibleGameSize = Vector2(vw, vh);
  }

  void _setCameraWorldTopLeft(Vector2 worldTopLeft) {
    final visibleSize = camera.viewfinder.visibleGameSize;
    final viewportSize =
        visibleSize ?? Vector2(camera.viewport.size.x, camera.viewport.size.y);
    camera.viewfinder.position = Vector2(
      worldTopLeft.x + viewportSize.x / 2,
      worldTopLeft.y + viewportSize.y / 2,
    );
  }

  void _syncCameraToPlayer() {
    if (!isLoaded) {
      return;
    }
    _setCameraWorldTopLeft(
      Vector2(
        _player.focusPoint.x -
            (camera.viewfinder.visibleGameSize?.x ?? camera.viewport.size.x) /
                2,
        _player.focusPoint.y -
            (camera.viewfinder.visibleGameSize?.y ?? camera.viewport.size.y) /
                2,
      ),
    );
  }

  /// Propage le rectangle visible caméra vers tous les [MapLayersComponent]
  /// chargés, en coordonnées locales de chaque composant.
  ///
  /// Utilise [CameraComponent.visibleWorldRect] qui tient compte du ratio
  /// d'aspect réel de l'écran (un écran PC large affiche plus de monde que
  /// le [visibleGameSize] demandé).
  ///
  /// Appelé une fois par frame dans [update], après la synchronisation caméra.
  void _syncViewportCullingRects() {
    if (!isLoaded) {
      return;
    }
    final worldRect = camera.visibleWorldRect;

    for (final loaded in _loadedMapsById.values) {
      final origin = _originPixelsOf(loaded);
      final localRect = Rect.fromLTRB(
        worldRect.left - origin.x,
        worldRect.top - origin.y,
        worldRect.right - origin.x,
        worldRect.bottom - origin.y,
      );
      loaded.backgroundLayers.setVisibleLocalRect(localRect);
      loaded.foregroundLayers.setVisibleLocalRect(localRect);
    }
  }
}

final class _PlayableMapCinematicRuntimeHost
    implements FlameCinematicRuntimeHost, FlameCinematicFxHost {
  _PlayableMapCinematicRuntimeHost(this._game);

  final PlayableMapGame _game;
  TextComponent? _dialogueLineOverlay;
  RectangleComponent? _fadeOverlay;
  Paint? _fadePaint;
  TextComponent? _emoteOverlay;
  final Map<String, RectangleComponent> _fxOverlays = {};

  String? get dialogueLine => _dialogueLineOverlay?.text;

  double? get fadeOpacity => _fadePaint?.color.a;

  @override
  bool get isReady => _game.isLoaded && _game._activeMapId.isNotEmpty;

  @override
  String get activeMapId => _game._activeMapId;

  @override
  Vector2 get cameraPosition => _game.camera.viewfinder.position.clone();

  @override
  set cameraPosition(Vector2 value) {
    _game.camera.viewfinder.position = value.clone();
  }

  @override
  Vector2? get cameraVisibleGameSize =>
      _game.camera.viewfinder.visibleGameSize?.clone();

  @override
  set cameraVisibleGameSize(Vector2? value) {
    _game.camera.viewfinder.visibleGameSize = value?.clone();
  }

  @override
  Vector2 get sceneCenter {
    final loaded = _game._loadedMapsById[_game._activeMapId];
    if (loaded == null) return _game._player.focusPoint;
    final origin = _game._originPixelsOf(loaded);
    return Vector2(
      origin.x + loaded.bundle.map.size.width * loaded.bundle.cellWidth / 2,
      origin.y + loaded.bundle.map.size.height * loaded.bundle.cellHeight / 2,
    );
  }

  @override
  FlameCinematicRuntimeActorHandle? get playerActor {
    if (!isReady) return null;
    return _PlayableMapPlayerCinematicActorHandle(_game._player);
  }

  @override
  FlameCinematicRuntimeActorHandle? mapEntityActor(String entityId) {
    final actor =
        _game._loadedMapsById[_game._activeMapId]?.npcActorByEntityId[entityId];
    return actor == null ? null : _PlayableMapNpcCinematicActorHandle(actor);
  }

  @override
  Vector2? mapEntityFocusPoint(String entityId) {
    final actor = mapEntityActor(entityId);
    if (actor != null) return actor.focusPoint;
    final loaded = _game._loadedMapsById[_game._activeMapId];
    if (loaded == null) return null;
    MapEntity? entity;
    for (final candidate in loaded.bundle.map.entities) {
      if (candidate.id == entityId) {
        entity = candidate;
        break;
      }
    }
    if (entity == null) return null;
    final origin = _game._originPixelsOf(loaded);
    return Vector2(
      origin.x +
          (entity.pos.x + entity.size.width / 2) * loaded.bundle.cellWidth,
      origin.y +
          (entity.pos.y + entity.size.height / 2) * loaded.bundle.cellHeight,
    );
  }

  @override
  Vector2 stagePointFocusPoint(CinematicStagePoint point) {
    final loaded = _game._loadedMapsById[_game._activeMapId];
    if (loaded == null) return Vector2(point.x, point.y);
    final origin = _game._originPixelsOf(loaded);
    return Vector2(
      origin.x + point.x * loaded.bundle.cellWidth,
      origin.y + point.y * loaded.bundle.cellHeight,
    );
  }

  @override
  void setCinematicInputLocked(bool locked) {
    _game._setCinematicInputLocked(locked);
  }

  @override
  void showCinematicDialogueLine(String? text) {
    _dialogueLineOverlay?.removeFromParent();
    _dialogueLineOverlay = null;
    if (text == null || text.trim().isEmpty) return;
    final component = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Color(0xDD000000),
          fontSize: 16,
          height: 1.35,
        ),
      ),
      anchor: Anchor.bottomCenter,
    )
      ..position = Vector2(
        _game.camera.viewport.size.x / 2,
        _game.camera.viewport.size.y - 24,
      )
      ..priority = 130;
    _game.camera.viewport.add(component);
    _dialogueLineOverlay = component;
  }

  @override
  Future<void> playCinematicDialogueAsset(String dialogueId) async {
    final result = await _game._startSceneDialogue(
      SceneDialogueRuntimeDialogueRequest(
        requestId: 'cinematic:$dialogueId',
        createdAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        dialogueId: dialogueId,
      ),
    );
    if (!result.success) {
      throw StateError(
        result.message ?? 'Cinematic dialogue "$dialogueId" failed.',
      );
    }
  }

  @override
  void cancelCinematicDialogueAsset() {
    _game._completePendingSceneDialogue(
      const SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
        message: 'Cinematic dialogue was cancelled.',
      ),
    );
    _game._dialogueOverlay?.removeFromParent();
    _game._dialogueOverlay = null;
    _game._setDialoguePresentationSnapshot(null);
    if (_game._flowPhase == _RuntimeFlowPhase.dialogue) {
      _game._setFlowPhase(_RuntimeFlowPhase.overworld);
    }
    _game._clearBlockingInteractionWithoutUnlock(
      reason: 'cinematicDialogueCancelled',
    );
  }

  @override
  void setCinematicFadeOpacity(double? opacity) {
    if (opacity == null) {
      _fadeOverlay?.removeFromParent();
      _fadeOverlay = null;
      _fadePaint = null;
      return;
    }
    var paint = _fadePaint;
    if (paint == null) {
      paint = Paint();
      final component = RectangleComponent(
        size: _game.camera.viewport.size.clone(),
        paint: paint,
      )..priority = 120;
      _game.camera.viewport.add(component);
      _fadePaint = paint;
      _fadeOverlay = component;
    }
    paint.color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0));
  }

  @override
  void showCinematicActorEmote(
    FlameCinematicRuntimeActorHandle? actor,
    String? emoteId,
  ) {
    _emoteOverlay?.removeFromParent();
    _emoteOverlay = null;
    if (actor == null || emoteId == null) return;
    final component = TextComponent(
      text: _cinematicEmoteGlyph(emoteId),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: <Shadow>[
            Shadow(color: Colors.black, blurRadius: 3),
          ],
        ),
      ),
      anchor: Anchor.bottomCenter,
    )
      ..position = actor.focusPoint - Vector2(0, 22)
      ..priority = 200000;
    _game.world.add(component);
    _emoteOverlay = component;
  }

  @override
  void showCinematicFx(String assetId, {required double intensity}) {
    hideCinematicFx(assetId);
    final component = RectangleComponent(
      size: _game.camera.viewport.size.clone(),
      paint: Paint()
        ..color = Color.fromRGBO(
          210,
          230,
          235,
          (0.08 + intensity.clamp(0.0, 1.0) * 0.18).clamp(0.0, 1.0),
        ),
    )..priority = 110;
    _game.camera.viewport.add(component);
    _fxOverlays[assetId] = component;
  }

  @override
  void hideCinematicFx(String assetId) {
    _fxOverlays.remove(assetId)?.removeFromParent();
  }

  @override
  void clearCinematicFx() {
    for (final overlay in _fxOverlays.values) {
      overlay.removeFromParent();
    }
    _fxOverlays.clear();
  }

  void onViewportResize(Vector2 size) {
    _dialogueLineOverlay?.position = Vector2(size.x / 2, size.y - 24);
    _fadeOverlay?.size = size.clone();
    for (final overlay in _fxOverlays.values) {
      overlay.size = size.clone();
    }
  }
}

final class _PlayableMapPlayerCinematicActorHandle
    implements FlameCinematicRuntimeActorHandle {
  const _PlayableMapPlayerCinematicActorHandle(this._player);

  final PlayerComponent _player;

  @override
  Vector2 get focusPoint => _player.focusPoint;

  @override
  EntityFacing get facing => _player.cinematicFacing;

  @override
  void setFocusPoint(Vector2 focusPoint) {
    final delta = focusPoint - _player.focusPoint;
    _player.position += delta;
  }

  @override
  void setFacing(EntityFacing facing) {
    _player.setCinematicFacing(facing);
  }
}

final class _PlayableMapNpcCinematicActorHandle
    implements FlameCinematicRuntimeActorHandle {
  const _PlayableMapNpcCinematicActorHandle(this._actor);

  final OverworldActorComponent _actor;

  @override
  Vector2 get focusPoint => _actor.position + _actor.size / 2;

  @override
  EntityFacing get facing => _actor.facing;

  @override
  void setFocusPoint(Vector2 focusPoint) {
    _actor.position = focusPoint - _actor.size / 2;
  }

  @override
  void setFacing(EntityFacing facing) {
    _actor.setMotion(facing, CharacterAnimationState.idle);
  }
}

String _cinematicEmoteGlyph(String emoteId) {
  return switch (emoteId) {
    'exclamation' || 'alert' => '!',
    'anger' => '#',
    'thought' || 'silence' => '…',
    'question' => '?',
    'music' => '♪',
    'idea' => '*',
    'heart' => '♥',
    'sweat' => '◢',
    _ => '•',
  };
}

class _LoadedPlayableMap {
  _LoadedPlayableMap({
    required this.bundle,
    required this.originCellX,
    required this.originCellY,
    required this.backgroundLayers,
    required this.foregroundLayers,
    required this.occlusionPatches,
    required this.npcActors,
    required this.npcActorByEntityId,
    required this.tileImagesById,
  });

  final RuntimeMapBundle bundle;
  final int originCellX;
  final int originCellY;
  final MapLayersComponent backgroundLayers;
  final MapLayersComponent foregroundLayers;
  final List<PlacedElementOcclusionPatchComponent> occlusionPatches;
  final List<OverworldActorComponent> npcActors;
  final Map<String, OverworldActorComponent> npcActorByEntityId;
  final Map<String, RuntimeTilesetImage> tileImagesById;
}

final class _LoadRuntimeSnapshot {
  const _LoadRuntimeSnapshot({
    required this.gameState,
    required this.bundle,
    required this.world,
    required this.activeMapId,
    required this.previousMapId,
    required this.flowPhase,
    required this.currentMapActivationId,
    required this.completedMapActivationDispatchCount,
    required this.lastCompletedMapActivation,
  });

  final GameState gameState;
  final RuntimeMapBundle bundle;
  final GameplayWorldState world;
  final String activeMapId;
  final String? previousMapId;
  final _RuntimeFlowPhase flowPhase;
  final String? currentMapActivationId;
  final int completedMapActivationDispatchCount;
  final MapActivation? lastCompletedMapActivation;
}

class _NpcCollisionDebugVisual {
  _NpcCollisionDebugVisual({
    required this.spriteRect,
    required this.collisionRect,
    required this.anchorMarker,
  });

  final RectangleComponent spriteRect;
  final RectangleComponent collisionRect;
  final CircleComponent anchorMarker;
}

class _GridCellPos {
  const _GridCellPos({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;
}

class _PendingConnectionEntryAnimation {
  _PendingConnectionEntryAnimation({
    required this.mapId,
    required this.initialCameraWorldTopLeft,
    required this.activation,
  });

  final String mapId;
  final Vector2 initialCameraWorldTopLeft;
  final MapActivation activation;
  bool holdInitialCameraFrame = true;
}

class _EncounterCheckMarker {
  const _EncounterCheckMarker({
    required this.mapId,
    required this.pos,
    required this.kind,
  });

  final String mapId;
  final GridPos pos;
  final EncounterKind kind;

  @override
  bool operator ==(Object other) {
    return other is _EncounterCheckMarker &&
        other.mapId == mapId &&
        other.pos == pos &&
        other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(mapId, pos, kind);
}

class _PendingScenarioFollowRequest {
  _PendingScenarioFollowRequest({
    required this.leaderEntityId,
    required this.requestedAtMs,
  });

  final String leaderEntityId;
  final double requestedAtMs;
  GridPos? lastLeaderPos;
  Direction? lastLeaderTravelDirection;
  List<GridPos>? cachedPath;
  GridPos? cachedPathDestination;
  GridPos? cachedPathLeaderPos;
  int consecutiveBlockedSteps = 0;
}

final class _CallbackSceneBattleRuntimeLauncher
    implements SceneBattleRuntimeLauncher {
  const _CallbackSceneBattleRuntimeLauncher(this._startTrainerBattle);

  final Future<SceneBattleRuntimeOutcomeResult> Function(
    SceneBattleRuntimeBattleRequest request,
  ) _startTrainerBattle;

  @override
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
    SceneBattleRuntimeBattleRequest request,
  ) {
    return _startTrainerBattle(request);
  }
}

final class _CallbackSceneDialogueRuntimeLauncher
    implements SceneDialogueRuntimeLauncher {
  const _CallbackSceneDialogueRuntimeLauncher(this._showDialogue);

  final Future<SceneDialogueRuntimeAwaitableResult> Function(
    SceneDialogueRuntimeDialogueRequest request,
  ) _showDialogue;

  @override
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneDialogueRuntimeDialogueRequest request,
  ) {
    return _showDialogue(request);
  }
}

final class _PendingNarrativeTriggerEntry {
  const _PendingNarrativeTriggerEntry({
    required this.activationId,
    required this.mapId,
    required this.triggerId,
  });

  final String? activationId;
  final String mapId;
  final String triggerId;
}

final class _NarrativeSceneWorkingSession {
  _NarrativeSceneWorkingSession(this.gameState);

  GameState gameState;
}

final class _NarrativeOutcomeContinuationContext {
  const _NarrativeOutcomeContinuationContext({
    required this.causationId,
    required this.correlationId,
    required this.depth,
  });

  final String causationId;
  final String correlationId;
  final int depth;
}

final class _NarrativeContinuationBarrier {
  _NarrativeContinuationBarrier({
    required this.runtimeSourceId,
    required this.continuation,
    required this.lease,
    required this.resumesScenario,
    required this.postCommitEffect,
  });

  String runtimeSourceId;
  _NarrativeOutcomeContinuationContext continuation;
  final NarrativeRuntimeActivityLease lease;
  final bool resumesScenario;
  final Future<void> Function()? postCommitEffect;
  final Completer<void> closedCompleter = Completer<void>();
  bool advancing = false;
  bool postCommitEffectStarted = false;
  bool cancelled = false;
  bool closed = false;
  _PendingScenarioTransitionMapRequest? ownedTransitionMapRequest;

  Future<void> get closedFuture => closedCompleter.future;
}

final class _ScenarioContinuationResumeResult {
  const _ScenarioContinuationResumeResult({
    required this.outcomes,
    required this.nextRuntimeSourceId,
    required this.ownedTransitionMapRequest,
  });

  const _ScenarioContinuationResumeResult.invalid()
      : outcomes = const <NarrativeOutcomeRef>[],
        nextRuntimeSourceId = null,
        ownedTransitionMapRequest = null;

  final List<NarrativeOutcomeRef> outcomes;
  final String? nextRuntimeSourceId;
  final _PendingScenarioTransitionMapRequest? ownedTransitionMapRequest;
}

class _PendingScenarioTransitionMapRequest {
  const _PendingScenarioTransitionMapRequest({
    required this.mapId,
    required this.warpId,
  });

  final String mapId;
  final String warpId;
}

final class _PendingScenarioBattleHandoff {
  const _PendingScenarioBattleHandoff({
    required this.requestId,
    required this.runtimeSourceId,
    required this.battleId,
  });

  final String requestId;
  final String runtimeSourceId;
  final String battleId;
}

enum _ScenarioWarpHandoffKind { script, playerMove, leaderMove }

final class _PendingScenarioWarpHandoff {
  const _PendingScenarioWarpHandoff({
    required this.runtimeSourceId,
    required this.expectedWarp,
    required this.kind,
    this.entityId,
  });

  final String runtimeSourceId;
  final TriggeredWarp expectedWarp;
  final _ScenarioWarpHandoffKind kind;
  final String? entityId;

  bool matches(TriggeredWarp? warp) {
    return warp != null &&
        warp.warpId == expectedWarp.warpId &&
        warp.targetMapId == expectedWarp.targetMapId &&
        warp.targetPos == expectedWarp.targetPos &&
        warp.triggerMode == expectedWarp.triggerMode;
  }
}

class _PendingScenarioNpcWarpEntry {
  const _PendingScenarioNpcWarpEntry({
    required this.entityId,
    required this.warpId,
    required this.warpPos,
    required this.approachPos,
  });

  final String entityId;
  final String warpId;
  final GridPos warpPos;
  final GridPos approachPos;
}

class _PendingScenarioLeaderWarpHandoff {
  const _PendingScenarioLeaderWarpHandoff({
    required this.leaderEntityId,
    required this.warpId,
    required this.targetMapId,
    required this.targetPos,
    required this.triggerMode,
    required this.runtimeSourceId,
  });

  final String leaderEntityId;
  final String warpId;
  final String targetMapId;
  final GridPos targetPos;
  final MapWarpTriggerMode triggerMode;
  final String? runtimeSourceId;

  bool matches(TriggeredWarp? warp) {
    return warp != null &&
        warp.warpId == warpId &&
        warp.targetMapId == targetMapId &&
        warp.targetPos == targetPos &&
        warp.triggerMode == triggerMode;
  }
}

class _PendingScenarioMoveContinuation {
  const _PendingScenarioMoveContinuation({
    required this.entityId,
    required this.runtimeSourceId,
    required this.targetKind,
  });

  final String entityId;
  final String runtimeSourceId;
  final String targetKind;
}

class _PendingScenarioReachedEnd {
  const _PendingScenarioReachedEnd({
    required this.scenarioId,
    required this.origin,
    required this.queuedAtMs,
  });

  final String scenarioId;
  final String origin;
  final double queuedAtMs;
}

class _FollowPathPlan {
  const _FollowPathPlan({
    required this.destination,
    required this.path,
  });

  final GridPos destination;
  final List<GridPos> path;
}

enum _WarpTransitionStyle {
  fade,
}

class _WarpTransitionSpec {
  const _WarpTransitionSpec({
    required this.style,
    required this.fadeOut,
    required this.fadeIn,
  });

  final _WarpTransitionStyle style;
  final Duration fadeOut;
  final Duration fadeIn;
}

/// Projection World Rules mémoïsée avec les entrées identitaires qui l'ont
/// produite (manifeste, état de jeu, carte).
class _WorldRuleProjectionCache {
  const _WorldRuleProjectionCache({
    required this.manifest,
    required this.gameState,
    required this.map,
    required this.projection,
  });

  final ProjectManifest manifest;
  final GameState gameState;
  final MapData map;
  final RuntimeWorldRuleProjectionState? projection;
}

/// Contexte de planification de route préparé pour une entité : sonde de
/// passabilité (offsets figés) + prédicat de blocage dynamique lié.
class _PreparedNpcRoutePlanningProbe {
  const _PreparedNpcRoutePlanningProbe({
    required this.entityId,
    required this.world,
    required this.probe,
    required this.isDynamicallyBlocked,
  });

  final String entityId;
  final GameplayWorldState world;
  final PreparedScriptedNpcAnchorProbe? probe;
  final ScriptedNpcDynamicCellBlocked isDynamicallyBlocked;
}

/// Fusion d'ombres mémoïsée avec les collections sources ayant servi à la
/// construire ; la validité se vérifie par identité des sources.
class _MergedShadowCollectionCache {
  const _MergedShadowCollectionCache({
    required this.projected,
    required this.staticCollection,
    required this.actorCollection,
    required this.merged,
  });

  final ShadowRuntimeInstructionCollection? projected;
  final ShadowRuntimeInstructionCollection? staticCollection;
  final ShadowRuntimeInstructionCollection? actorCollection;
  final ShadowRuntimeInstructionCollection? merged;
}
