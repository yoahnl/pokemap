import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_battle/map_battle.dart';

import '../../application/battle_start_request.dart';
import '../../application/dialogue_runtime_models.dart';
import '../../application/cutscene_runtime_models.dart';
import '../../application/cutscene_runtime_runner.dart';
import '../../application/encounter_to_battle_request.dart';
import '../../application/field_move_dialogue.dart';
import '../../application/load_dialogue_content.dart';
import '../../application/placed_behavior_runtime_cooldown.dart';
import '../../application/movement_feedback.dart';
import '../../application/npc_overworld_movement_defaults.dart';
import '../../application/scripted_npc_anchor_passability.dart';
import '../../application/load_runtime_map_bundle.dart';
import '../../application/resolve_dialogue.dart';
import '../../application/runtime_character_refs.dart';
import '../../application/runtime_map_bundle.dart';
import '../../application/runtime_story_branching.dart';
import '../../application/scenario_runtime/scenario_runtime_executor.dart';
import '../../application/scenario_runtime/scenario_runtime_models.dart';
import '../../application/scripted_entity_movement_controller.dart';
import '../../application/scripted_entity_movement_models.dart';
import '../../application/script_runtime_state.dart';
import '../../application/script_runtime_controller.dart';
import '../../application/story_flags_manager.dart';
import '../../application/trainer_battle_request.dart';
import '../../../domain/repositories/game_save_repository.dart';
import '../../../src/application/save_game_use_case.dart';
import '../../../src/application/load_game_use_case.dart';
import '../../../src/infrastructure/file_game_save_repository.dart';
import '../../infrastructure/tile_image_loader.dart';
import 'battle_overlay_component.dart';
import 'battle_transition_overlay_component.dart';
import 'dialogue_overlay_component.dart';
import 'map_layers_component.dart';
import 'overworld_actor_component.dart';
import 'player_component.dart';
import 'warp_transition_overlay_component.dart';

const double _kViewportTilesX = 15.0;
const double _kViewportTilesY = 11.0;
const double _kWaterRequiresSurfMessageCooldownMs = 900;
const GameplayEncounterPolicy _kEncounterPolicy = GameplayEncounterPolicy(
  chancePerStep: 0.12,
);

enum _RuntimeFlowPhase {
  overworld,
  dialogue,
  mapTransition,
  battleTransition,
  battle,
}

class PlayableMapGame extends FlameGame with KeyboardEvents {
  PlayableMapGame({
    required RuntimeMapBundle bundle,
    required this.projectFilePath,
    SaveData? saveData,
    GameSaveRepository? saveRepository,
    this.bundleTransformer,
    this.runtimeCutscenes = const <RuntimeCutsceneAsset>[],
  })  : _bundle = bundle,
        _gameState = normalizeLoadedGameState(
          saveData == null
              ? const GameState(saveId: 'default')
              : gameStateFromSaveData(saveData),
        ),
        _saveRepo = saveRepository ?? FileGameSaveRepository() {
    if (bundleTransformer != null) {
      _bundle = bundleTransformer!(_bundle);
    }
    _saveGameUseCase = SaveGameUseCase(_saveRepo);
    _loadGameUseCase = LoadGameUseCase(_saveRepo);
  }

  final String projectFilePath;
  final RuntimeMapBundle Function(RuntimeMapBundle bundle)? bundleTransformer;
  final List<RuntimeCutsceneAsset> runtimeCutscenes;
  RuntimeMapBundle _bundle;
  GameState _gameState;
  late GameplayWorldState _world;
  late PlayerComponent _player;
  String _activeMapId = '';
  String? _previousMapId;
  _RuntimeFlowPhase _flowPhase = _RuntimeFlowPhase.overworld;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  LogicalKeyboardKey? _lastMoveKey;
  TriggeredWarp? _pendingWarp;
  TriggeredConnection? _pendingConnection;
  BattleStartRequest? _pendingBattleRequest;
  PlacedElementInteracted? _pendingPlacedElementBehavior;
  DialogueOverlayComponent? _dialogueOverlay;
  BattleTransitionOverlayComponent? _battleTransitionOverlay;
  BattleOverlayComponent? _battleOverlay;
  WarpTransitionOverlayComponent? _warpTransitionOverlay;
  TextComponent? _notification;
  final List<OverworldActorComponent> _npcActors = [];
  final Map<String, _LoadedPlayableMap> _loadedMapsById = {};
  final Map<String, Future<_LoadedPlayableMap?>> _loadMapFutureById = {};
  final math.Random _encounterRandom = math.Random();
  final GridPathfinder _followPathfinder = const GridPathfinder();
  final PlacedBehaviorCooldownGate _placedBehaviorCooldownGate =
      PlacedBehaviorCooldownGate();
  final StoryFlagsManager _storyFlags = const StoryFlagsManager();
  final RuntimeStoryBranching _storyBranching = const RuntimeStoryBranching();
  final ScenarioRuntimeExecutor _scenarioRuntime =
      const ScenarioRuntimeExecutor();
  late final CutsceneRuntimeRunner _cutsceneRunner =
      _buildCutsceneRuntimeRunner();
  CutsceneChoiceRequest? _pendingCutsceneChoiceRequest;
  ScriptedEntityMovementController? _scriptedEntityMovementController;
  final Map<String, GridPos> _runtimeNpcPositions = <String, GridPos>{};
  // Réservations temporaires d'occupation pour PNJ scriptés en cours de pas.
  //
  // Frontière intentionnelle:
  // - `GameplayWorldState` reste la source canonique des positions *commitées*.
  // - pendant une interpolation visuelle d'un pas PNJ, on réserve aussi les
  //   cellules de destination pour éviter les traversées joueur<->PNJ / PNJ<->PNJ.
  final Map<String, Set<GridPos>> _scriptedNpcReservedOccupiedCellsByEntity =
      <String, Set<GridPos>>{};
  double _runtimeClockMs = 0;
  double _lastWaterRequiresSurfMessageAtMs = -1000000000;
  void Function()? _pendingPostDialogueAction;
  bool _awaitingSurfConfirmation = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showBehaviorDebugOverlay = false;
  TextComponent? _behaviorDebugOverlay;
  String _lastBehaviorDebugLine = 'Aucun behavior déclenché';
  GridPos? _debugTileMarkerPos;
  String? _debugTileMarkerLabel;
  RectangleComponent? _debugTileMarkerFill;
  RectangleComponent? _debugTileMarkerBorder;
  TextComponent? _debugTileMarkerText;
  final Map<String, _NpcCollisionDebugVisual> _npcCollisionDebugByEntityId =
      <String, _NpcCollisionDebugVisual>{};

  ScriptRuntimeController? _activeScriptController;
  bool _isAwaitingScriptResume = false;
  Set<String> _activeScenarioTriggerIds = <String>{};
  _PendingScenarioFollowRequest? _pendingScenarioFollowRequest;
  _PendingScenarioTransitionMapRequest? _pendingScenarioTransitionMapRequest;
  final Map<String, _PendingScenarioNpcWarpEntry>
      _pendingScenarioNpcWarpEntries = <String, _PendingScenarioNpcWarpEntry>{};

  // Save/Load system
  final GameSaveRepository _saveRepo;
  late SaveGameUseCase _saveGameUseCase;
  late LoadGameUseCase _loadGameUseCase;

  // Battle system (map_battle integration)
  BattleSession? _battleSession;
  BattleStartRequest?
      _battleStartRequest; // Pour mapping vers BattleSetup et marquage trainer

  // Battle flow hardening
  bool _isBattleResolving =
      false; // Lock pour empêcher spam clavier pendant résolution

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

  MovementMode get playerMovementMode {
    if (isLoaded) {
      return _world.player.movementMode;
    }
    return _gameState.playerMovementMode;
  }

  bool get isSurfing => playerMovementMode == MovementMode.surf;

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

  void _syncGameStateFromWorld({String? mapIdOverride}) {
    final mapId = mapIdOverride ?? _activeMapId;
    _gameState = _gameState.copyWith(
      currentMapId: mapId,
      playerPosition: _world.player.pos,
      playerFacing: _world.player.facing.asFacing,
      playerMovementMode: _world.player.movementMode,
    );
  }

  RuntimeMapBundle _resolveRuntimeBundle(RuntimeMapBundle bundle) {
    final transform = bundleTransformer;
    if (transform == null) {
      return bundle;
    }
    return transform(bundle);
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
    return controller.moveEntityTo(
      entityId: entityId,
      destination: destination,
    );
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
    if (!isLoaded) {
      return false;
    }
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return false;
    }
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
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
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
  }

  bool resolvePendingCutsceneChoiceByIndex(int selectedIndex) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByIndex(selectedIndex);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    }
    return resolved;
  }

  bool resolvePendingCutsceneChoiceByValue(String selectedValue) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByValue(selectedValue);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
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
  Future<void> onLoad() async {
    try {
      _world = GameplayWorldState.fromMap(
        _bundle.map,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
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
      );
    }
    final images =
        await loadTilesetImagesById(_bundle.tilesetAbsolutePathsById);
    _activeMapId = _bundle.map.id;
    final rootMap = await _mountLoadedMap(
      bundle: _bundle,
      tileImagesById: images,
      originCellX: 0,
      originCellY: 0,
    );
    final playerChar = _resolvePlayerCharacter(_bundle);
    _player = PlayerComponent(
      bundle: _bundle,
      state: _world.player,
      characterEntry: playerChar,
      tileImages: images,
      mapOrigin: _originPixelsOf(rootMap),
    );
    await world.add(_player);
    _syncGameStateFromWorld();
    _configureCameraViewport();
    _syncCameraToPlayer();
    _preloadActiveMapConnections();
    _ensureBehaviorDebugOverlay();
    _applyDebugTileMarker();
    _resetScriptedNpcMovementController();
    _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: _world.player.pos,
    );
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
    );
    return super.onLoad();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;
    final key = event.logicalKey;

    // IMPORTANT: Handle battle phase FIRST before movement keys
    // Otherwise arrow keys will be captured by movement handler
    if (_flowPhase == _RuntimeFlowPhase.battle) {
      // Navigation dans les choix du combat
      // ↑/↓ pour naviguer, E/Space/Enter pour valider, Escape pour fuir
      final overlay = _battleOverlay;
      if (overlay != null) {
        // ↑ : sélection précédente (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowUp && event is KeyDownEvent) {
          final changed = overlay.moveSelectionUp();
          debugPrint('[battle] ArrowUp pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // ↓ : sélection suivante (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowDown && event is KeyDownEvent) {
          final changed = overlay.moveSelectionDown();
          debugPrint('[battle] ArrowDown pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // E / Space / Enter : validation du choix sélectionné
        // CRITICAL: Only process KeyDownEvent, NOT KeyRepeatEvent!
        // KeyRepeatEvent is sent when key is held down, which causes multiple validations
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.enter)) {
          // CRITICAL: Re-check phase AFTER getting into this block
          // Because the phase might have changed during this same key event processing
          // (e.g., last attack of the battle finished it)
          if (_flowPhase != _RuntimeFlowPhase.battle) {
            debugPrint(
                '[battle] Validate key pressed but phase changed to $_flowPhase, IGNORING');
            return KeyEventResult.ignored;
          }
          // Also check if overlay is still valid (might have been removed)
          if (_battleOverlay == null) {
            debugPrint(
                '[battle] Validate key pressed but overlay is null, IGNORING');
            return KeyEventResult.ignored;
          }
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint(
              '[battle] Validate key pressed (E/Space/Enter), selectedChoice=$selectedChoice');
          final validated = overlay.validateSelectedChoice();
          debugPrint('[battle] validateSelectedChoice returned=$validated');
          return KeyEventResult.handled;
        }
        // Escape : tentative de fuite (seulement si l'action est disponible)
        if (event is KeyDownEvent && key == LogicalKeyboardKey.escape) {
          // Vérifier si l'action "Fuir" est disponible dans les choix
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint('[battle] Escape pressed, selectedChoice=$selectedChoice');
          if (selectedChoice is PlayerBattleChoiceRun) {
            overlay.validateSelectedChoice();
            debugPrint('[battle] Escape validated (run selected)');
            return KeyEventResult.handled;
          }
          // Si "Fuir" n'est pas sélectionné, ne rien faire
          debugPrint('[battle] Escape ignored (run not selected)');
          return KeyEventResult.ignored;
        }
      } else {
        debugPrint('[battle] Keyboard event but overlay is null!');
      }
      return KeyEventResult.ignored;
    }

    // Pendant une cutscene active en overworld, on bloque les entrées joueur
    // directes (déplacement/interact) pour garder la scène déterministe.
    if (isCutsceneRunning && _flowPhase == _RuntimeFlowPhase.overworld) {
      if (_isMovementKey(key)) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.keyE ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
    }

    // Handle movement keys (but NOT during battle)
    if (_isMovementKey(key)) {
      if (_flowPhase == _RuntimeFlowPhase.dialogue) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        if ((_dialogueOverlay?.isShowingChoices ?? false) && isDown) {
          if (key == LogicalKeyboardKey.arrowUp) {
            _moveChoiceCursor(-1);
          } else if (key == LogicalKeyboardKey.arrowDown) {
            _moveChoiceCursor(1);
          }
        }
        return KeyEventResult.handled;
      }
      if (_flowPhase != _RuntimeFlowPhase.overworld) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (isDown) {
        _pressedKeys.add(key);
        _lastMoveKey = key;
      } else if (isUp) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
      }
      return KeyEventResult.handled;
    }

    if (_flowPhase == _RuntimeFlowPhase.mapTransition ||
        _flowPhase == _RuntimeFlowPhase.battleTransition) {
      return KeyEventResult.ignored;
    }
    if (!isDown) return KeyEventResult.ignored;

    if (_flowPhase == _RuntimeFlowPhase.dialogue) {
      final overlay = _dialogueOverlay!;
      if (overlay.isShowingChoices) {
        if (key == LogicalKeyboardKey.arrowUp) {
          _moveChoiceCursor(-1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _moveChoiceCursor(1);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _confirmDialogueChoice();
          return KeyEventResult.handled;
        }
      } else {
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _advanceDialogue();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.keyE || key == LogicalKeyboardKey.space)) {
      _handleInteract();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _runtimeClockMs += dt * 1000;
    _placedBehaviorCooldownGate.prune(nowMs: _runtimeClockMs);
    _updateActorDepthOrdering();
    _syncCameraToPlayer();
    _syncNpcCollisionDebugOverlay();

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }

    final pendingWarp = _pendingWarp;
    if (pendingWarp != null && !_player.isStepping) {
      _pendingWarp = null;
      _handleWarp(pendingWarp);
      return;
    }

    final pendingConnection = _pendingConnection;
    if (pendingConnection != null && !_player.isStepping) {
      _pendingConnection = null;
      _handleConnection(pendingConnection);
      return;
    }

    final pendingBattleRequest = _pendingBattleRequest;
    if (pendingBattleRequest != null && !_player.isStepping) {
      _pendingBattleRequest = null;
      _startBattleHandoff(pendingBattleRequest);
      return;
    }

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

    // Tick du système de déplacement scripté PNJ.
    //
    // Ce tick reste dans le flux overworld pour ce MVP:
    // - pas d'exécution pendant dialogue/battle transition;
    // - base propre pour un futur "wait movement" en cutscene.
    _scriptedEntityMovementController?.update(dt);
    _processPendingScenarioNpcWarpEntries();
    _processPendingScenarioFollowRequest();
    _processPendingScenarioTransitionMapRequest();

    // Tick runner cutscene MVP (séquentiel).
    _cutsceneRunner.update(dt);
    _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    if (isCutsceneRunning) {
      // Tant que la cutscene n'est pas terminée, on ne laisse pas la boucle
      // input joueur déplacer le player.
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

  bool _isMovementKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.keyD;
  }

  GameplayIntent? _intentFromPressedKeys() {
    Direction? dirFor(LogicalKeyboardKey key) {
      if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
        return Direction.north;
      }
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.keyS) {
        return Direction.south;
      }
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.keyA) {
        return Direction.west;
      }
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.keyD) {
        return Direction.east;
      }
      return null;
    }

    final preferred = _lastMoveKey;
    if (preferred != null && _pressedKeys.contains(preferred)) {
      final d = dirFor(preferred);
      if (d != null) {
        return MoveIntent(d);
      }
    }

    for (final key in _pressedKeys) {
      final d = dirFor(key);
      if (d != null) {
        return MoveIntent(d);
      }
    }
    return null;
  }

  void _driveMovement() {
    if (_player.isStepping) {
      return;
    }

    final intent = _intentFromPressedKeys();
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
    _consumePathAnimationSignals(result.pathAnimationSignals);

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
      if (result.warp.triggerMode == MapWarpTriggerMode.onEnter) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player, snapToGrid: true);
      }
      _pendingWarp = result.warp;
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
    debugPrint(
      '[encounter] checking at x=${pos.x} y=${pos.y} kind=${encounterKind.name}',
    );
    final check = checkEncounterAtPlayerPosition(
      world: _world,
      project: _bundle.manifest,
      encounterKind: encounterKind,
      random: _encounterRandom,
      policy: _kEncounterPolicy,
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
    _pendingBattleRequest = request;
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
      _dispatchScenarioRuntimeSource(
        ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: _activeMapId,
          triggerId: triggerId,
        ),
      );
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
    ScenarioRuntimeSourceEvent sourceEvent,
  ) {
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

    final result = _scenarioRuntime.dispatch(
      scenarios: scenarios,
      sourceEvent: sourceEvent,
      context: ScenarioRuntimeExecutionContext(
        gameState: _gameState,
        onGameStateUpdated: (state) {
          _gameState = state;
        },
        openDialogue: _openScenarioDialogueById,
        runScript: _runScenarioScriptById,
        showMessage: (message) => _showNotification(message),
        moveCharacter: ({
          required entityId,
          required targetKind,
          required targetId,
          required waitForCompletion,
        }) {
          return _runScenarioMoveCharacter(
            entityId: entityId,
            targetKind: targetKind,
            targetId: targetId,
            waitForCompletion: waitForCompletion,
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
      ),
    );

    // On maintient une trace explicite en logs pour faciliter le debug.
    if (result.status == ScenarioRuntimeExecutionStatus.noMatchingSource) {
      return result;
    }
    debugPrint(
      '[scenario_runtime] source=${sourceEvent.type.name} map=${sourceEvent.mapId} trigger=${sourceEvent.triggerId ?? '-'} entity=${sourceEvent.entityId ?? '-'} status=${result.status.name} scenario=${result.scenarioId ?? '-'} sourceNode=${result.sourceNodeId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
    return result;
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
    final opened = _tryOpenDialogue(
      runtimeSourceId ?? 'scenario',
      DialogueRef(
        dialogueId: normalizedDialogueId,
        startNode: startNode,
      ),
      'Dialogue introuvable: $normalizedDialogueId',
    );
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
      _resumeScenarioAfterRuntimeSource(runtimeSourceId);
    };
  }

  void _resumeScenarioAfterRuntimeSource(String runtimeSourceId) {
    final parts = runtimeSourceId.split(':');
    if (parts.length != 4) {
      return;
    }
    final scenarioId = parts[1].trim();
    final sourceNodeId = parts[2].trim();
    final resumeAfterNodeId = parts[3].trim();
    if (scenarioId.isEmpty ||
        sourceNodeId.isEmpty ||
        resumeAfterNodeId.isEmpty) {
      return;
    }
    final result = _scenarioRuntime.dispatchContinuation(
      scenarios: _bundle.manifest.scenarios,
      scenarioId: scenarioId,
      sourceNodeId: sourceNodeId,
      resumeAfterNodeId: resumeAfterNodeId,
      context: ScenarioRuntimeExecutionContext(
        gameState: _gameState,
        onGameStateUpdated: (state) {
          _gameState = state;
        },
        openDialogue: _openScenarioDialogueById,
        runScript: _runScenarioScriptById,
        showMessage: (message) => _showNotification(message),
        moveCharacter: ({
          required entityId,
          required targetKind,
          required targetId,
          required waitForCompletion,
        }) {
          return _runScenarioMoveCharacter(
            entityId: entityId,
            targetKind: targetKind,
            targetId: targetId,
            waitForCompletion: waitForCompletion,
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
      ),
    );
    debugPrint(
      '[scenario_runtime] continuation source=$runtimeSourceId status=${result.status.name} scenario=${result.scenarioId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
  }

  bool _runScenarioMoveCharacter({
    required String entityId,
    required String targetKind,
    required String targetId,
    required bool waitForCompletion,
  }) {
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
      debugPrint(
        '[scenario_runtime] moveCharacter started entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y}) waitForCompletion=true (non-blocking bridge)',
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
    _PendingScenarioTransitionMapRequest request,
  ) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint(
        '[scenario_runtime] transitionMap ignored: flow=${_flowPhase.name}',
      );
      return;
    }
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: request.mapId,
      );
      final targetBundle = _resolveRuntimeBundle(loadedBundle);
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
      await _handleWarp(transition);
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

  void _processPendingScenarioNpcWarpEntries() {
    if (_pendingScenarioNpcWarpEntries.isEmpty) {
      return;
    }
    final entityIds =
        _pendingScenarioNpcWarpEntries.keys.toList(growable: false)..sort();
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

  void _completeScenarioNpcWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    final removed = _despawnNpcFromActiveMap(pending.entityId);
    if (!removed) {
      debugPrint(
        '[scenario_runtime] npc warp failed to remove entity=${pending.entityId} warp=${pending.warpId}',
      );
      return;
    }
    debugPrint(
      '[scenario_runtime] npc entered warp entity=${pending.entityId} warp=${pending.warpId} approach=(${pending.approachPos.x},${pending.approachPos.y})',
    );
  }

  bool _despawnNpcFromActiveMap(String entityId) {
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
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );

    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId.remove(normalized);
    if (actor != null) {
      loaded?.npcActors.remove(actor);
      _npcActors.remove(actor);
      actor.removeFromParent();
    }
    final visual = _npcCollisionDebugByEntityId.remove(normalized);
    visual?.spriteRect.removeFromParent();
    visual?.collisionRect.removeFromParent();
    visual?.anchorMarker.removeFromParent();

    _scriptedNpcReservedOccupiedCellsByEntity.remove(normalized);
    _runtimeNpcPositions.remove(normalized);
    _triggeredTrainerBattles.remove(normalized);
    if (_pendingScenarioFollowRequest?.leaderEntityId == normalized) {
      _pendingScenarioFollowRequest = null;
    }
    _pendingScenarioNpcWarpEntries.remove(normalized);
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

    final result = stepGameplayWorld(_world, MoveIntent(direction));
    if (result is! Moved) {
      debugPrint(
        '[scenario_runtime] followCharacter path step blocked leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }
    _world = result.world;
    _syncGameStateFromWorld();
    _consumePathAnimationSignals(result.pathAnimationSignals);
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
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[entityId];
    if (actor == null) {
      debugPrint(
        '[scenario_runtime] faceCharacter entity unresolved="$entityId"',
      );
      return false;
    }
    final movement = scriptedNpcMovementStatus(entityId);
    if (movement.state == ScriptedEntityMovementState.moving ||
        actor.isStepping) {
      debugPrint(
        '[scenario_runtime] faceCharacter deferred entity=$entityId while moving',
      );
      return true;
    }
    actor.setMotion(facing, CharacterAnimationState.idle);
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
    if (movementStatus.entityId == leaderEntityId) {
      return movementStatus.currentPos;
    }
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[leaderEntityId];
    final actorGridPos = actor?.gridPos;
    if (actorGridPos != null) {
      return actorGridPos;
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
      if (!_canPlacePlayerAt(candidate)) {
        continue;
      }
      final path = _computeFollowPlayerPath(
        start: currentPlayerPos,
        goal: candidate,
      );
      if (path == null) {
        continue;
      }
      return _FollowPathPlan(
        destination: candidate,
        path: path,
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
        if (!_canPlacePlayerAt(candidate)) {
          continue;
        }
        final path = _computeFollowPlayerPath(
          start: currentPlayerPos,
          goal: candidate,
        );
        if (path == null) {
          continue;
        }
        return _FollowPathPlan(
          destination: candidate,
          path: path,
        );
      }
    }

    if (_isPosAdjacentToRect(currentPlayerPos, leaderRect) &&
        _canPlacePlayerAt(currentPlayerPos)) {
      return _FollowPathPlan(
        destination: currentPlayerPos,
        path: <GridPos>[currentPlayerPos],
      );
    }
    return null;
  }

  List<GridPos>? _computeFollowPlayerPath({
    required GridPos start,
    required GridPos goal,
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
        if (_isCellReservedByScriptedNpc(cell)) {
          return false;
        }
        final trial = _world.withPlayer(_world.player.copyWith(pos: cell));
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

  bool _canPlacePlayerAt(GridPos pos) {
    if (!_isWithinMapBounds(_world.map, pos)) {
      return false;
    }
    final trial = _world.withPlayer(_world.player.copyWith(pos: pos));
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
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: startNode,
      runtimeSourceId: runtimeSourceId ?? 'scenario',
    );
    return true;
  }

  void _logEncounterCheck(GameplayEncounterCheckResult check) {
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
  void _startBattleHandoff(BattleStartRequest request) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }
    _flowPhase = _RuntimeFlowPhase.battleTransition;
    _notification?.removeFromParent();
    _notification = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    debugPrint(
      '[battle] transition started requestId=${request.requestId} kind=${request.kind.name}',
    );
    final overlay = BattleTransitionOverlayComponent(
      request: request,
      viewportSize: camera.viewport.size,
      onFinished: () => _openBattleOverlay(request),
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
  void _openBattleOverlay(BattleStartRequest request) {
    if (_flowPhase != _RuntimeFlowPhase.battleTransition) {
      return;
    }
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _flowPhase = _RuntimeFlowPhase.battle;

    // Mapper BattleStartRequest → BattleSetup
    final setup = _toBattleSetup(request);

    // Créer la session de combat
    _battleSession = createBattleSession(setup);
    _battleStartRequest = request;

    // Afficher l'overlay de combat avec la session
    final overlay = BattleOverlayComponent(
      session: _battleSession!,
      viewportSize: camera.viewport.size,
      onPlayerChoice: _onPlayerBattleChoice,
    );
    camera.viewport.add(overlay);
    _battleOverlay = overlay;
    debugPrint(
      '[battle] overlay opened requestId=${request.requestId} kind=${request.kind.name}',
    );
  }

  /// Mappe BattleStartRequest → BattleSetup.
  ///
  /// [request] - La requête de combat depuis le runtime.
  ///
  /// Retourne un BattleSetup pur pour le moteur de combat.
  BattleSetup _toBattleSetup(BattleStartRequest request) {
    // Pour ce MVP, on utilise des données simplifiées
    // Dans un vrai jeu, on récupérerait les données du Pokémon depuis une base de données

    // Déterminer l'espèce et le niveau depuis la request
    String playerSpeciesId = 'pikachu'; // Placeholder
    int playerLevel = 5;
    String enemySpeciesId;
    int enemyLevel;

    if (request is WildBattleStartRequest) {
      enemySpeciesId = request.speciesId;
      enemyLevel = request.level;
    } else if (request is TrainerBattleStartRequest) {
      // Pour un combat trainer, on utilise une espèce fixe (placeholder)
      enemySpeciesId = 'lapras';
      enemyLevel = 5;
    } else {
      enemySpeciesId = 'mew';
      enemyLevel = 5;
    }

    return BattleSetup(
      playerPokemon: BattleCombatantData(
        speciesId: playerSpeciesId,
        level: playerLevel,
        maxHp: 20 + (playerLevel * 2), // Formule simple : 20 + 2*level
        moves: const [
          BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          BattleMoveData(id: 'scratch', name: 'Griffe', power: 4),
        ],
      ),
      enemyPokemon: BattleCombatantData(
        speciesId: enemySpeciesId,
        level: enemyLevel,
        maxHp: 15 + (enemyLevel * 3), // Formule simple : 15 + 3*level
        moves: const [
          BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
        ],
      ),
      isTrainerBattle: request is TrainerBattleStartRequest,
      trainerId:
          request is TrainerBattleStartRequest ? request.trainerId : null,
    );
  }

  /// Gère le choix du joueur pendant le combat.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode :
  /// 1. Applique le choix via BattleSession.applyChoice()
  /// 2. Met à jour l'UI
  /// 3. Vérifie si le combat est fini
  /// 4. Si fini, appelle _onBattleFinished()
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

    try {
      // Appliquer le choix (retourne une nouvelle session immutable)
      _battleSession = _battleSession!.applyChoice(choice);

      // Mettre à jour l'UI avec le nouvel état
      final overlay = _battleOverlay;
      overlay?.updateState(_battleSession!);

      // Vérifier si le combat est fini
      if (_battleSession!.state.isFinished) {
        _onBattleFinished(_battleSession!.state.outcome!);
      }
    } finally {
      // Unlock après résolution (ou après fin de combat)
      // Si combat fini, _onBattleFinished() va reset l'état de toute façon
      if (_flowPhase == _RuntimeFlowPhase.battle) {
        _isBattleResolving = false;
      }
    }
  }

  /// Gère la fin du combat.
  ///
  /// [outcome] - Le résultat du combat.
  ///
  /// Cette méthode :
  /// 1. Marque le trainer comme battu si victoire + trainer battle
  /// 2. Nettoie l'overlay (SUPPRIME du parent)
  /// 3. Retourne à l'overworld
  void _onBattleFinished(BattleOutcome outcome) {
    debugPrint('[battle] battle finished outcome=${outcome.type.name}');

    // Marquer le trainer comme battu si victoire + trainer battle
    final request = _battleStartRequest;
    if (outcome.isVictory && request is TrainerBattleStartRequest) {
      _gameState =
          _storyFlags.markTrainerDefeated(_gameState, request.trainerId);
      debugPrint('[battle] trainer marked as defeated: ${request.trainerId}');
    }

    // Nettoyer et retourner à l'overworld
    // IMPORTANT: Il faut SUPPRIMER l'overlay du parent, pas juste mettre à null
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _battleStartRequest = null;
    _isBattleResolving = false; // Reset lock anti-spam

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
    // Et même si le lock est encore actif, le trainer ne sera pas re-déclenché
    // car il est marqué defeated dans storyFlags (guard dans _checkTrainerLineOfSight).

    _flowPhase = _RuntimeFlowPhase.overworld;
    _pressedKeys.clear();
    _lastMoveKey = null;
    debugPrint('[battle] overworld resumed');
  }

  void _handleInteract() {
    final result = stepGameplayWorld(_world, const InteractIntent());
    _world = result.world;
    _consumePathAnimationSignals(result.pathAnimationSignals);
    var scenarioHandledEntityInteraction = false;

    switch (result) {
      case NothingToInteract():
        if (result.pathAnimationSignals.isNotEmpty) {
          debugPrint('[interact] Path animation trigger');
          return;
        }
        debugPrint('[interact] Nothing to interact with');
        _showNotification('...');
      case NpcInteracted(:final entity):
        debugPrint('[interact] NPC: ${entity.id}');
        _faceNpcTowardPlayer(entity.id);
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
        _showNotification(entity.inspectorHeadline);
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

    final activePage = _storyBranching.resolveEventPage(event, _gameState);

    if (activePage == null) return;

    if (activePage.page.isDisabled) return;

    debugPrint('[interact] MapEvent: ${event.id} page=${activePage.pageIndex}');
    _handleMapEventInteraction(event, activePage);
  }

  void _handleMapEventInteraction(
    MapEventDefinition event,
    ActiveEventPage page,
  ) {
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
    final context = ScriptExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
      },
      onDialogueOpened: (dialogue) {
        _openDialogueForScriptSource(runtimeSourceId, dialogue);
      },
      onWarpRequested: (mapId, x, y) {
        _pendingWarp = TriggeredWarp(
          warpId: 'script_warp',
          targetMapId: mapId,
          targetPos: GridPos(x: x, y: y),
          triggerMode: MapWarpTriggerMode.onEnter,
        );
      },
    );

    _activeScriptController = ScriptRuntimeController(
      script: script,
      context: context,
      startNodeId: startNodeId,
    );
    _isAwaitingScriptResume = false;
    _runScriptStep();
  }

  void _runScriptStep() {
    final controller = _activeScriptController;
    if (controller == null) {
      return;
    }

    if (controller.isTerminated) {
      _activeScriptController = null;
      _isAwaitingScriptResume = false;
      return;
    }

    if (controller.isSuspended) {
      _isAwaitingScriptResume = true;
      return;
    }

    final result = controller.step();

    if (result is ScriptCommandResultSuspended) {
      _isAwaitingScriptResume = true;
      if (result.reason == ScriptSuspendReason.waitingForDialogue) {
        _flowPhase = _RuntimeFlowPhase.dialogue;
      }
      return;
    }

    _runScriptStep();
  }

  void _openDialogueForScriptSource(
      String runtimeSourceId, YarnDialogueRef dialogueRef) {
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
      _runScriptStep();
      return;
    }

    loadDialogueContent(resolved).then((session) {
      if (session == null) {
        debugPrint('[script] failed to load dialogue');
        _runScriptStep();
        return;
      }

      _pendingPostDialogueAction = () {
        _flowPhase = _RuntimeFlowPhase.overworld;
        if (_isAwaitingScriptResume) {
          _isAwaitingScriptResume = false;
          _runScriptStep();
        }
      };

      _openDialogue(session);
    });
  }

  void _consumePathAnimationSignals(List<PathAnimationSignal> signals) {
    if (signals.isEmpty) {
      return;
    }
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final signal in signals) {
      switch (signal.kind) {
        case PathAnimationSignalKind.trigger:
          final backgroundApplied =
              active.backgroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] trigger ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] trigger layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
        case PathAnimationSignalKind.setActive:
          final activeValue = signal.active ?? false;
          final backgroundApplied =
              active.backgroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] active ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] active layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
      }
    }
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
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
      );
      _bundle = RuntimeMapBundle(
        manifest: _bundle.manifest,
        map: updatedMap,
        projectRootDirectory: _bundle.projectRootDirectory,
        tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
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
          npcActors: activeLoaded.npcActors,
          npcActorByEntityId: activeLoaded.npcActorByEntityId,
        );
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
      String entityId, DialogueRef? ref, String fallbackLabel) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) return false;
    if (_dialogueOverlay != null) return false;

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

    loadDialogueContent(resolved).then((session) {
      if (_dialogueOverlay != null) return;
      if (session == null) {
        debugPrint('[dialogue] failed to load session for entity=$entityId');
        _showNotification(fallbackLabel);
        return;
      }
      debugPrint('[dialogue] opening dialogue for entity=$entityId');
      _openDialogue(session);
    });
    return true;
  }

  void _openDialogue(DialogueSession session) {
    _notification?.removeFromParent();
    _notification = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
    _flowPhase = _RuntimeFlowPhase.dialogue;

    final overlay = DialogueOverlayComponent(
      session: session,
      viewportSize: camera.viewport.size,
      onFinished: () {
        debugPrint('[dialogue] dialogue closed');
        _dialogueOverlay = null;
        _flowPhase = _RuntimeFlowPhase.overworld;
        _awaitingSurfConfirmation = false;
        final action = _pendingPostDialogueAction;
        _pendingPostDialogueAction = null;
        action?.call();
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

  void _handleNpcInteraction(MapEntity entity) {
    final trainerId = entity.npc?.trainerId?.trim();

    // Cas 1: pas de trainerId → dialogue normal
    if (trainerId == null || trainerId.isEmpty) {
      _tryOpenDialogue(
          entity.id, entity.npc?.dialogue, entity.inspectorHeadline);
      return;
    }

    // Cas 2: trainer déjà battu → defeat dialogue ou fallback
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint(
        '[interact] trainer already defeated trainer=$trainerId npc=${entity.id}',
      );
      _openDefeatDialogue(entity);
      return;
    }

    // Cas 3: trainerId invalide → log + fallback dialogue
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
          entity.id, entity.npc?.dialogue, entity.inspectorHeadline);
      return;
    }

    // Cas 4: trainer non battu → battle normal
    // Vérifier aussi _triggeredTrainerBattles pour éviter double déclenchement
    if (_triggeredTrainerBattles.contains(entity.id)) {
      debugPrint(
        '[interact] trainer battle already triggered (LoS lock) trainer=$trainerId npc=${entity.id}',
      );
      // Ne pas déclencher un autre battle, mais ne pas bloquer l'interaction non plus
      // Juste ignorer silencieusement
      return;
    }

    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
        '[battle] trainer battle triggered npc=${entity.id} trainer=$trainerId',
      );
      // Lock ANTI-RETRIGGER avant de déclencher
      _triggeredTrainerBattles.add(entity.id);
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    }
  }

  void _openDefeatDialogue(MapEntity entity) {
    final defeatRef = entity.npc?.defeatDialogueRef;
    if (defeatRef != null) {
      debugPrint('[interact] opening defeat dialogue npc=${entity.id}');
      _tryOpenDialogue(entity.id, defeatRef, entity.inspectorHeadline);
    } else if (entity.npc?.dialogue != null) {
      debugPrint(
          '[interact] no defeat dialogue, fallback to normal dialogue npc=${entity.id}');
      _tryOpenDialogue(
          entity.id, entity.npc!.dialogue, entity.inspectorHeadline);
    } else {
      debugPrint(
          '[interact] no dialogue for defeated trainer npc=${entity.id}');
      _showNotification('Le dresseur est déjà vaincu.');
    }
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

      final trainerId = entity.npc?.trainerId;
      if (trainerId == null || trainerId.isEmpty) continue;

      final losRange = entity.npc?.lineOfSightRange ?? 0;
      if (losRange <= 0) continue;

      // Vérifier si déjà battu
      if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) continue;

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
        // Lock anti-retrigger AVANT de déclencher
        _triggeredTrainerBattles.add(entity.id);
        _triggerTrainerBattle(entity);
      }
    }
  }

  /// Déclenche un battle trainer (appelé par interaction manuelle OU LoS auto).
  ///
  /// **Factorisation :** Cette méthode factorise UNIQUEMENT le démarrage du battle.
  /// Elle ne gère PAS :
  /// - La vérification trainer déjà battu (déjà fait par l'appelant)
  /// - Le defeat dialogue (géré par _handleNpcInteraction pour interaction manuelle)
  ///
  /// **Gestion d'erreur :**
  /// - trainerId invalide → log + notification + pas de crash
  /// - Battle request null → log + pas de battle
  void _triggerTrainerBattle(MapEntity entity) {
    final trainerId = entity.npc?.trainerId;
    if (trainerId == null || trainerId.isEmpty) {
      debugPrint('[trainer] no trainerId for entity=${entity.id}');
      return;
    }

    // Vérifier si déjà battu (pour LoS — interaction manuelle a déjà son check)
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint('[trainer] already defeated trainer=$trainerId');
      return;
    }

    // Vérifier trainer valide
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

    // Créer battle request
    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
          '[trainer] battle triggered trainer=$trainerId entity=${entity.id}');
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    } else {
      debugPrint(
          '[trainer] battle request failed trainer=$trainerId entity=${entity.id}');
    }
  }

  void _showNotification(String text) {
    _notification?.removeFromParent();
    final paint = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        backgroundColor: Color(0xAA000000),
      ),
    );
    final component = TextComponent(
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
    Future.delayed(const Duration(seconds: 2), () {
      if (_notification == component) {
        component.removeFromParent();
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
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
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
  /// **Limitation** : La phase destructive (à partir de `_gameState = loadedState`)
  /// n'est pas transactionnelle. En cas d'échec pendant le chargement de la map
  /// ou le remontage des layers, le runtime peut rester dans un état partiellement
  /// modifié. Aucun rollback n'est implémenté dans ce lot. Cette limitation sera
  /// adressée dans un futur lot si nécessaire.
  Future<bool> loadGame() async {
    // 1. Charger loadedState
    final rawLoadedState = await _loadGameUseCase.execute();
    if (rawLoadedState == null) {
      debugPrint('[load] no save found');
      return false;
    }
    final loadedState = normalizeLoadedGameState(rawLoadedState);

    // 2. Charger newBundle (avec error handling)
    RuntimeMapBundle newBundle;
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: loadedState.currentMapId,
      );
      newBundle = _resolveRuntimeBundle(loadedBundle);
    } catch (e, st) {
      debugPrint('[load] failed to load map: $e\n$st');
      return false;
    }

    // 3. Charger newImages (avec error handling)
    Map<String, ui.Image> newImages;
    try {
      newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
    } catch (e, st) {
      debugPrint('[load] failed to load tileset images: $e\n$st');
      return false;
    }

    // 4-16. Phase destructive (protégée par try/catch)
    try {
      // 4. Restaurer GameState
      _gameState = loadedState;

      // 5. Nettoyer l'état transitoire
      _clearTransientUiState();

      // 6. Unmount anciennes maps
      _unmountAllLoadedMaps();

      // 7. Assigner _bundle = newBundle
      _bundle = newBundle;

      // 8. Monter nouvelle map
      await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
      );

      // 9. Reconstruire _world
      _world = GameplayWorldState.initial(
        map: newBundle.map,
        project: newBundle.manifest,
        playerPos: loadedState.playerPosition,
        playerFacing: loadedState.playerFacing.asDirection,
        playerMovementMode: loadedState.playerMovementMode,
      );

      // 10. Mettre _activeMapId + reset contrôleur PNJ scripté
      _activeMapId = loadedState.currentMapId;
      _resetScriptedNpcMovementController();

      // 10. Resync _player
      _player.setMapOrigin(Vector2(0, 0), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);

      // 11. Synchroniser GameState
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);

      // 12-15. Resync caméra / streaming / bounds
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _applyDebugTileMarker();
      _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
        map: _bundle.map,
        pos: _world.player.pos,
      );

      debugPrint('[load] game loaded from saveId=${loadedState.saveId}');
      return true;
    } catch (e, st) {
      debugPrint('[load] failed during destructive phase: $e\n$st');
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

  Future<void> _handleWarp(TriggeredWarp warp) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[warp] ignored: flow=${_flowPhase.name}');
      return;
    }
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    final sourceBundle = _bundle;
    final sourceWorld = _world;
    final sourceMapId = _activeMapId;
    final sourcePos = _world.player.pos;
    final sourceFacing = _world.player.facing;
    WarpTransitionOverlayComponent? overlay;
    var swapCompleted = false;
    try {
      _clearTransientUiState();
      overlay = WarpTransitionOverlayComponent(
        viewportSize: camera.viewport.size,
      );
      camera.viewport.add(overlay);
      _warpTransitionOverlay = overlay;
      debugPrint(
        '[warp] start transition warp=${warp.warpId} map=$sourceMapId -> ${warp.targetMapId} target=(${warp.targetPos.x}, ${warp.targetPos.y})',
      );
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: warp.targetMapId,
      );
      final newBundle = _resolveRuntimeBundle(loadedBundle);
      debugPrint('[warp] target map loaded id=${newBundle.map.id}');
      final transitionSpec = _resolveWarpTransitionSpec(
        sourceMap: sourceBundle.map,
        targetMap: newBundle.map,
      );
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade out durationMs=${transitionSpec.fadeOut.inMilliseconds}',
        );
        await overlay.fadeOut(duration: transitionSpec.fadeOut);
      }
      if (!_isWithinMapBounds(newBundle.map, warp.targetPos)) {
        throw StateError(
          'warp target out of bounds map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y}) size=${newBundle.map.size.width}x${newBundle.map.size.height}',
        );
      }
      final newWorld = GameplayWorldState.initial(
        map: newBundle.map,
        playerPos: warp.targetPos,
        playerFacing: sourceFacing,
        project: newBundle.manifest,
        tileWidth: newBundle.manifest.settings.tileWidth,
        tileHeight: newBundle.manifest.settings.tileHeight,
      );
      if (newWorld.isBlocked(warp.targetPos.x, warp.targetPos.y)) {
        throw StateError(
          'warp target blocked map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y})',
        );
      }
      debugPrint('[warp] loading target map visuals id=${newBundle.map.id}');
      final newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
      _unmountAllLoadedMaps();
      final root = await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
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
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade in durationMs=${transitionSpec.fadeIn.inMilliseconds}',
        );
        await overlay.fadeIn(duration: transitionSpec.fadeIn);
      }
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
      _flowPhase = _RuntimeFlowPhase.overworld;
      debugPrint(
        '[warp] gameplay unlocked map=$_activeMapId pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      if (swapCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
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
      _unmountAllLoadedMaps();
      final loadedFallbackBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: sourceMapId,
      );
      final fallbackBundle = _resolveRuntimeBundle(loadedFallbackBundle);
      final fallbackWorld = _buildSafeWorldState(
        map: fallbackBundle.map,
        project: fallbackBundle.manifest,
        preferredPos: sourceWorld.player.pos,
        fallbackFacing: sourceWorld.player.facing,
        tileWidth: fallbackBundle.manifest.settings.tileWidth,
        tileHeight: fallbackBundle.manifest.settings.tileHeight,
      );
      final fallbackImages =
          await loadTilesetImagesById(fallbackBundle.tilesetAbsolutePathsById);
      final root = await _mountLoadedMap(
        bundle: fallbackBundle,
        tileImagesById: fallbackImages,
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
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    var transitionCompleted = false;
    try {
      _clearTransientUiState();
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
        project: target.bundle.manifest,
        tileWidth: target.bundle.manifest.settings.tileWidth,
        tileHeight: target.bundle.manifest.settings.tileHeight,
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
      final fromPx = _player.position.clone();
      final targetOriginPx = _originPixelsOf(target);
      final toPx = Vector2(
        targetOriginPx.x + targetPos.x * _cellWidth,
        targetOriginPx.y + targetPos.y * _cellHeight,
      );
      debugPrint(
        '[connection] player step pixels from=(${fromPx.x.toStringAsFixed(1)}, ${fromPx.y.toStringAsFixed(1)}) to=(${toPx.x.toStringAsFixed(1)}, ${toPx.y.toStringAsFixed(1)})',
      );
      _player.setMapOrigin(targetOriginPx, snapToGrid: false);
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _configureCameraViewport();
      final visibleSize = camera.viewfinder.visibleGameSize;
      debugPrint(
        '[connection] camera after transition focus=(${_player.focusPoint.x.toStringAsFixed(1)}, ${_player.focusPoint.y.toStringAsFixed(1)}) viewport=(${(visibleSize?.x ?? 0).toStringAsFixed(1)}, ${(visibleSize?.y ?? 0).toStringAsFixed(1)})',
      );
      debugPrint(
        '[connection] transition complete -> map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
      );
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      transitionCompleted = true;
    } catch (e, st) {
      debugPrint('[connection] transition failed: $e\n$st');
      _player.syncState(_world.player, snapToGrid: true);
      _showNotification('Connection failed');
    } finally {
      _flowPhase = _RuntimeFlowPhase.overworld;
      if (transitionCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
      }
    }
  }

  void _clearTransientUiState() {
    _pendingWarp = null;
    _pendingConnection = null;
    // CRITICAL: Do NOT clear _pendingBattleRequest if a battle is active!
    // This would cancel a pending wild encounter battle.
    // Only clear if we're in overworld phase (no battle in progress).
    if (_flowPhase == _RuntimeFlowPhase.overworld) {
      _pendingBattleRequest = null;
    }
    _pendingPlacedElementBehavior = null;
    _notification?.removeFromParent();
    _notification = null;
    _dialogueOverlay?.removeFromParent();
    _dialogueOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _warpTransitionOverlay?.removeFromParent();
    _warpTransitionOverlay = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
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
    for (final actor in loaded.npcActors) {
      actor.removeFromParent();
      _npcActors.remove(actor);
    }
  }

  Future<_LoadedPlayableMap> _mountLoadedMap({
    required RuntimeMapBundle bundle,
    required Map<String, ui.Image> tileImagesById,
    required int originCellX,
    required int originCellY,
  }) async {
    final backgroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      showCollisionOverlay: _showCollisionOverlay,
    );
    backgroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    backgroundLayers.priority = 0;
    await world.add(backgroundLayers);

    final foregroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      renderPass: MapLayerRenderPass.foreground,
      showCollisionOverlay: false,
    );
    foregroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    foregroundLayers.priority = 100000;
    await world.add(foregroundLayers);

    final npcActors = <OverworldActorComponent>[];
    final npcActorByEntityId = <String, OverworldActorComponent>{};
    final charById = {for (final c in bundle.manifest.characters) c.id: c};
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final originPx =
        _originPixels(originCellX: originCellX, originCellY: originCellY);
    for (final entity in bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      final charId = resolveNpcCharacterId(entity, bundle.manifest);
      if (charId == null || charId.isEmpty) continue;
      final char = charById[charId];
      if (char == null) continue;
      final actor = OverworldActorComponent(
        character: char,
        tileImages: tileImagesById,
        tileWidth: bundle.manifest.settings.tileWidth,
        tileHeight: bundle.manifest.settings.tileHeight,
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
    }

    final loaded = _LoadedPlayableMap(
      bundle: bundle,
      originCellX: originCellX,
      originCellY: originCellY,
      backgroundLayers: backgroundLayers,
      foregroundLayers: foregroundLayers,
      npcActors: npcActors,
      npcActorByEntityId: npcActorByEntityId,
    );
    _loadedMapsById[bundle.map.id] = loaded;
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
      }
      return existing;
    }
    final inFlight = _loadMapFutureById[targetMapId];
    if (inFlight != null) {
      return await inFlight;
    }

    Future<_LoadedPlayableMap?> load() async {
      try {
        final loadedBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: targetMapId,
        );
        final bundle = _resolveRuntimeBundle(loadedBundle);
        final origin = _computeConnectedOriginCells(
          source: source,
          connection: connection,
          targetSize: bundle.map.size,
        );
        final images =
            await loadTilesetImagesById(bundle.tilesetAbsolutePathsById);
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
        },
        clearFlag: (flagName) {
          _gameState = _storyFlags.clear(_gameState, flagName);
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
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
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
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
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
    final byId = <String, GridPos>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      // On ne suit que les PNJ effectivement montés visuellement.
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

    // Pathfinding anchor validation:
    // - `x,y` est la position logique MapEntity.pos (top-left),
    // - on valide le footprint collision réel (important pour NPC 2x2),
    // - on ignore l'auto-collision de l'entité courante.
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: normalizedIgnore,
      anchorPos: GridPos(x: x, y: y),
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: normalizedIgnore,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] blocked anchor entity=$normalizedIgnore anchor=($x,$y) reason="${probe.reason}" footprint=${probe.evaluatedCollisionCells.map((c) => '(${c.x},${c.y})').join(',')}',
      );
    }
    return !probe.passable;
  }

  String? _validateScriptedNpcStepRuntimeCollision({
    required String entityId,
    required GridPos from,
    required GridPos to,
  }) {
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
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    return actor?.isStepping ?? false;
  }

  void _commitScriptedNpcPosition(String entityId, GridPos position) {
    _runtimeNpcPositions[entityId] = position;
    _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
    _world = _world.withEntityPosition(entityId, position);
  }

  bool _isCellReservedByScriptedNpc(GridPos cell) {
    for (final cells in _scriptedNpcReservedOccupiedCellsByEntity.values) {
      if (cells.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  void _reserveScriptedNpcStepOccupiedCells({
    required String entityId,
    required GridPos fromAnchorPos,
    required GridPos toAnchorPos,
  }) {
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

  void _syncCameraToPlayer() {
    if (!isLoaded) {
      return;
    }
    final focus = _player.focusPoint;
    camera.viewfinder.position = Vector2(
      focus.x.roundToDouble(),
      focus.y.roundToDouble(),
    );
  }
}

class _LoadedPlayableMap {
  _LoadedPlayableMap({
    required this.bundle,
    required this.originCellX,
    required this.originCellY,
    required this.backgroundLayers,
    required this.foregroundLayers,
    required this.npcActors,
    required this.npcActorByEntityId,
  });

  final RuntimeMapBundle bundle;
  final int originCellX;
  final int originCellY;
  final MapLayersComponent backgroundLayers;
  final MapLayersComponent foregroundLayers;
  final List<OverworldActorComponent> npcActors;
  final Map<String, OverworldActorComponent> npcActorByEntityId;
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

class _PendingScenarioTransitionMapRequest {
  const _PendingScenarioTransitionMapRequest({
    required this.mapId,
    required this.warpId,
  });

  final String mapId;
  final String warpId;
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
