// Evaluation deliberately drives the same debug surface already exercised by
// FG-182. These members are not shipped as player-facing runtime APIs.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../contracts/evaluation_state_snapshot.dart';
import '../runner/evaluation_checkpoint_cache.dart';
import 'evaluation_driver.dart';
import 'evaluation_game_fixtures.dart';
import 'evaluation_player_service_host.dart';

final class SelbrumeEvaluationDriver
    implements
        EvaluationDriver,
        EvaluationPlayerServiceAutomation,
        EvaluationRosterAutomation,
        EvaluationBattleAutomation,
        EvaluationPlayerShellProvider {
  SelbrumeEvaluationDriver._({
    required this.game,
    required this.project,
    required this.projectRoot,
    required this.playerServices,
    required PlayerServiceRuntimeController? playerServiceController,
    required EvaluationPlayerServiceAutomation? attachedServices,
    required this.playerShell,
    required bool ownsGame,
    required double playbackRate,
    required this.runId,
    required this.checkpointCache,
    required this.checkpointProvenance,
    required List<GameCompletionRequest> gameCompletionRequests,
  })  : _attachedServices = attachedServices,
        _playerServiceController = playerServiceController,
        _ownsGame = ownsGame,
        _playbackRate = playbackRate,
        _gameCompletionRequests = gameCompletionRequests;

  final PlayableMapGame game;
  final ProjectManifest project;
  final Directory projectRoot;
  final EvaluationPlayerServiceHost? playerServices;
  final PlayerServiceRuntimeController? _playerServiceController;
  final EvaluationPlayerServiceAutomation? _attachedServices;
  @override
  final EvaluationPlayerShellAutomation? playerShell;
  final bool _ownsGame;
  final double _playbackRate;
  final String runId;
  final EvaluationCheckpointCache? checkpointCache;
  final EvaluationCheckpointProvenance? checkpointProvenance;
  final List<GameCompletionRequest> _gameCompletionRequests;
  final Map<String, MapData> _mapsById = <String, MapData>{};
  final Map<String, Set<String>> _runtimeRejectedEdgesByMapId =
      <String, Set<String>>{};
  final Map<String, GameState> _checkpoints = <String, GameState>{};
  Map<String, Object?> _lastShop = const <String, Object?>{};

  GameState get state => game.gameStateSnapshot;

  EvaluationPlayableMapGame get headlessGame {
    final current = game;
    if (current is! EvaluationPlayableMapGame) {
      throw StateError('The attached interactive driver has no headless game.');
    }
    return current;
  }

  EvaluationPlayerServiceHost get headlessPlayerServices =>
      _requireHeadlessPlayerServices();

  UnmodifiableListView<GameCompletionRequest> get gameCompletionRequests =>
      UnmodifiableListView<GameCompletionRequest>(_gameCompletionRequests);

  Future<void> waitUntilRuntimeReady({bool driveDialogue = false}) {
    bool predicate() =>
        game.debugFlowPhaseName == 'overworld' &&
        !game.debugHasPendingMapTransition &&
        !game.debugIsMapActivationDispatchInFlight &&
        !game.debugIsNarrativeSpatialDispatchInFlight &&
        !game.debugIsNarrativeOutcomeWorkInFlight &&
        !game.debugIsCinematicPlaying;
    return _ownsGame
        ? _pumpUntil(
            predicate,
            operation: 'game.ready',
            allowTransitionClock: true,
            maxTicks: 6000,
          )
        : _waitForLiveRuntime(
            predicate,
            operation: 'game.ready',
            driveDialogue: driveDialogue,
          );
  }

  factory SelbrumeEvaluationDriver.attach({
    required PlayableMapGame game,
    required ProjectManifest project,
    required Directory projectRoot,
    required EvaluationPlayerServiceAutomation services,
    EvaluationPlayerShellAutomation? playerShell,
    double playbackRate = 1,
    String runId = 'interactive-evaluation-run',
  }) {
    if (!playbackRate.isFinite || playbackRate <= 0 || playbackRate > 4) {
      throw ArgumentError.value(
        playbackRate,
        'playbackRate',
        'Playback rate must be greater than 0 and at most 4.',
      );
    }
    return SelbrumeEvaluationDriver._(
      game: game,
      project: project,
      projectRoot: projectRoot,
      playerServices: null,
      playerServiceController: null,
      attachedServices: services,
      playerShell: playerShell,
      ownsGame: false,
      playbackRate: playbackRate,
      runId: runId,
      checkpointCache: null,
      checkpointProvenance: null,
      gameCompletionRequests: <GameCompletionRequest>[],
    );
  }

  static Future<SelbrumeEvaluationDriver> start({
    required Directory projectRoot,
    String runId = 'evaluation-run',
    EvaluationCheckpointCache? checkpointCache,
    EvaluationCheckpointProvenance? checkpointProvenance,
  }) async {
    if ((checkpointCache == null) != (checkpointProvenance == null)) {
      throw ArgumentError(
        'checkpointCache and checkpointProvenance must be supplied together.',
      );
    }
    final projectPath = p.join(projectRoot.path, 'project.json');
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: 'map_bourg_selbrume',
    );
    final saveRepository = SerializedEvaluationSaveRepository();
    final playerServices = EvaluationPlayerServiceHost();
    final gameCompletionRequests = <GameCompletionRequest>[];
    final game = EvaluationPlayableMapGame(
      bundle: bundle,
      projectFilePath: projectPath,
      saveRepository: saveRepository,
      encounterRandom: AlwaysEncounterRandom(),
      gameCompletionEmitter: (request) async {
        gameCompletionRequests.add(request);
      },
    );
    final playerServiceController = PlayerServiceRuntimeController(
      currentGameState: () => game.playerServiceGameStateSnapshot,
      host: playerServices,
      commitAndSave: game.commitAndSavePlayerServiceState,
      setInputLocked: (locked) => game.setExternalInputLock(
        RuntimeExternalInputLock.playerService,
        locked: locked,
      ),
      loadRecoveryCaps: (state) => loadRuntimePlayerServiceRecoveryCaps(
        gameState: state,
        projectRootDirectory: bundle.projectRootDirectory,
        pokemonConfig: bundle.manifest.pokemon,
      ),
      conditionContext: ScriptEvaluationContext(
        narrativeFactResolver:
            NarrativeFactRuntimeResolver.fromFacts(bundle.manifest.facts),
      ),
    );
    game.setPlayerServiceRuntimeController(playerServiceController);
    final driver = SelbrumeEvaluationDriver._(
      game: game,
      project: bundle.manifest,
      projectRoot: projectRoot,
      playerServices: playerServices,
      playerServiceController: playerServiceController,
      attachedServices: null,
      playerShell: null,
      ownsGame: true,
      playbackRate: 1,
      runId: runId,
      checkpointCache: checkpointCache,
      checkpointProvenance: checkpointProvenance,
      gameCompletionRequests: gameCompletionRequests,
    );
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await driver._pumpUntil(
      () => !game.debugIsMapActivationDispatchInFlight,
      operation: 'game.start',
    );
    driver._require(
      driver.state.currentMapId == 'map_bourg_selbrume',
      operation: 'game.start',
      message: 'The initial map must be map_bourg_selbrume.',
    );
    driver._require(
      driver.state.party.members.isEmpty,
      operation: 'game.start',
      message: 'A fresh evaluation must start without a party.',
    );
    return driver;
  }

  @override
  EvaluationStateSnapshot snapshot() {
    final current = state;
    final bag = <String, int>{};
    for (final entry in current.bag.entries) {
      bag.update(
        entry.itemId,
        (quantity) => quantity + entry.quantity,
        ifAbsent: () => entry.quantity,
      );
    }
    return EvaluationStateSnapshot(
      projectId: p.basename(projectRoot.path),
      runId: runId,
      mapId: current.currentMapId,
      x: current.playerPosition.x,
      y: current.playerPosition.y,
      movementMode: current.playerMovementMode.name,
      facts: current.narrativeFactRuntimeState.overridesByFactId,
      eventLedger: Map<String, Object?>.from(
        current.narrativeEventProgress.toJson(),
      ),
      progression: Map<String, Object?>.from(current.progression.toJson()),
      money: current.trainerProfile.money,
      badges: current.trainerProfile.badgeIds,
      bag: bag,
      shop: _lastShop,
      party: current.party.members
          .map((pokemon) => Map<String, Object?>.from(pokemon.toJson()))
          .toList(growable: false),
      storage: current.pokemonStorage.boxes
          .expand((box) => box.pokemon)
          .map((pokemon) => Map<String, Object?>.from(pokemon.toJson()))
          .toList(growable: false),
      activeDialogue: game.debugFlowPhaseName == 'dialogue'
          ? <String, Object?>{'active': true}
          : null,
      activeScene: game.debugFlowPhaseName == 'scene'
          ? <String, Object?>{
              'active': true,
              'pendingBattle': game.debugHasPendingSceneBattle,
              'outcomeWorkInFlight': game.debugIsNarrativeOutcomeWorkInFlight,
              'spatialDispatchInFlight':
                  game.debugIsNarrativeSpatialDispatchInFlight,
            }
          : null,
      activeBattle: game.debugBattleSessionSnapshot == null
          ? null
          : <String, Object?>{'active': true},
      outcome: <String, Object?>{
        'flowPhase': game.debugFlowPhaseName,
        'gameCompleted': _gameCompletionRequests.isNotEmpty,
        if (_gameCompletionRequests.lastOrNull case final completion?) ...{
          'endingId': completion.endingId,
          'completionOutcome': completion.outcome.name,
          'destination': completion.destination.name,
          'allowPostGameContinue': completion.allowPostGameContinue,
        },
      },
      saveMetadata: Map<String, Object?>.from(current.metadata),
    );
  }

  @override
  Future<void> startNewGame() async {
    _require(
      state.currentMapId == project.newGame.startMapId &&
          state.party.members.isEmpty,
      operation: 'game.new',
      message: 'game.new requires a fresh worker-owned runtime.',
    );
  }

  @override
  Future<void> navigateTo(int x, int y) async {
    final target = GridPos(x: x, y: y);
    for (var attempt = 0; attempt < 600; attempt += 1) {
      if (game.debugPlayerGridPosition == target) return;
      _require(
        game.debugFlowPhaseName == 'overworld',
        operation: 'movement.navigate',
        message: 'Cannot navigate while flow=${game.debugFlowPhaseName}.',
      );
      final path = _pathTo(target);
      _require(
        path != null && path.isNotEmpty,
        operation: 'movement.navigate',
        message: 'No physical path from ${game.debugPlayerGridPosition} '
            'to $target on ${state.currentMapId}.',
      );
      final direction = path!.first;
      final before = game.debugPlayerGridPosition;
      await _tapMovement(_controlForDirection(direction));
      if (_hasBattleHandoff) {
        await resolveBattle('run');
        continue;
      }
      if (game.debugPlayerGridPosition == before) {
        _runtimeRejectedEdgesByMapId
            .putIfAbsent(state.currentMapId, () => <String>{})
            .add(_edgeKey(before, direction));
      }
    }
    throw EvaluationDriverFailure(
      operation: 'movement.navigate',
      message: 'Physical navigation exceeded 600 steps towards $target.',
      snapshot: snapshot(),
    );
  }

  @override
  Future<void> crossConnection(
    String direction, {
    int? preferredAxis,
  }) async {
    final parsedDirection = MapConnectionDirection.values
        .where((candidate) => candidate.name == direction)
        .firstOrNull;
    _require(
      parsedDirection != null,
      operation: 'movement.crossConnection',
      message: 'Unknown connection direction "$direction".',
    );
    final sourceMap = _currentMap;
    final connection = sourceMap.connections.singleWhere(
      (entry) => entry.direction == parsedDirection,
      orElse: () => throw EvaluationDriverFailure(
        operation: 'movement.crossConnection',
        message: 'No $direction connection exists on ${sourceMap.id}.',
        snapshot: snapshot(),
      ),
    );
    Object? lastFailure;
    for (final boundary in _connectionBoundaryCandidates(
      sourceMap,
      parsedDirection!,
      preferredAxis,
    )) {
      if (_pathTo(boundary) == null) continue;
      final before = state.currentMapId;
      try {
        await navigateTo(boundary.x, boundary.y);
        await _tapMovement(_controlForConnection(parsedDirection));
        await _pumpUntil(
          () => state.currentMapId == connection.targetMapId,
          operation: 'movement.crossConnection',
          maxTicks: 600,
          allowTransitionClock: true,
        );
        await _pumpUntil(
          () =>
              !game.debugHasPendingMapTransition &&
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeSpatialDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              game.debugFlowPhaseName == 'overworld',
          operation: 'movement.crossConnection',
          allowTransitionClock: true,
        );
        return;
      } catch (error) {
        lastFailure = error;
        if (state.currentMapId != before) rethrow;
      }
    }
    throw EvaluationDriverFailure(
      operation: 'movement.crossConnection',
      message: 'No production-input route crossed ${sourceMap.id} '
          '$direction to ${connection.targetMapId}; lastFailure=$lastFailure.',
      snapshot: snapshot(),
    );
  }

  @override
  Future<void> enterGameplayZone(String zoneId) async {
    final zone = _currentMap.gameplayZones
        .where((candidate) => candidate.id == zoneId)
        .firstOrNull;
    _require(
      zone != null,
      operation: 'movement.enterGameplayZone',
      message: 'Gameplay zone "$zoneId" does not exist on '
          '${state.currentMapId}.',
    );
    final target = zone!.area.pos;
    final candidates = <({GridPos position, Direction facing, int length})>[];
    for (final facing in Direction.values) {
      final position = GridPos(
        x: target.x - facing.dx,
        y: target.y - facing.dy,
      );
      final path = _pathTo(position);
      if (path != null) {
        candidates.add((
          position: position,
          facing: facing,
          length: path.length,
        ));
      }
    }
    _require(
      candidates.isNotEmpty,
      operation: 'movement.enterGameplayZone',
      message: 'Gameplay zone "$zoneId" has no reachable approach.',
    );
    candidates.sort((left, right) => left.length.compareTo(right.length));
    final approach = candidates.first;
    await navigateTo(approach.position.x, approach.position.y);
    await _tapMovement(_controlForDirection(approach.facing));
    await _pumpUntil(
      () => game.debugFlowPhaseName == 'dialogue',
      operation: 'movement.enterGameplayZone',
      driveCinematic: true,
      maxTicks: 6000,
    );
    _pressPrimary(operation: 'movement.enterGameplayZone');
    await _pumpUntil(
      () => game.debugFlowPhaseName == 'overworld',
      operation: 'movement.enterGameplayZone',
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
      maxTicks: 6000,
    );
    await _tapMovement(_controlForDirection(approach.facing));
    _require(
      game.debugPlayerGridPosition == target,
      operation: 'movement.enterGameplayZone',
      message: 'Gameplay zone "$zoneId" did not accept physical traversal.',
    );
  }

  @override
  Future<void> interact(String entityId) async {
    final entity =
        _currentMap.entities.where((entry) => entry.id == entityId).firstOrNull;
    _require(
      entity != null,
      operation: 'world.interact',
      message: 'Entity "$entityId" does not exist on ${state.currentMapId}.',
    );
    final approach = _shortestReachableApproach(entity!);
    await navigateTo(approach.stagingPosition.x, approach.stagingPosition.y);
    await _tapMovement(_controlForDirection(approach.facing));
    if (_hasBattleHandoff) {
      await resolveBattle('run');
    }
    _require(
      game.debugPlayerGridPosition == approach.position,
      operation: 'world.interact',
      message: 'The runtime did not reach the interaction front.',
    );
    _pressPrimary(operation: 'world.interact');
    await _microPump();
  }

  @override
  Future<void> enterTrigger(
    String triggerId, {
    bool expectBattle = false,
  }) async {
    final trigger = _currentMap.triggers
        .where((entry) => entry.id == triggerId)
        .firstOrNull;
    _require(
      trigger != null,
      operation: 'world.enterTrigger',
      message: 'Trigger "$triggerId" does not exist on ${state.currentMapId}.',
    );
    if (_contains(trigger!.area, game.debugPlayerGridPosition)) {
      final outside = _reachableCellOutsideArea(trigger.area);
      await navigateTo(outside.x, outside.y);
    }
    final target = _reachableCellInArea(trigger.area);
    if (expectBattle) {
      var movementAttempted = false;
      for (var attempt = 0; attempt < 600; attempt += 1) {
        if (movementAttempted &&
            (game.debugFlowPhaseName == 'battleTransition' ||
                game.debugFlowPhaseName == 'battle')) {
          await _pumpUntil(
            () => game.debugFlowPhaseName == 'battle',
            operation: 'world.enterTrigger',
            driveCinematic: true,
            drivePlainDialogue: true,
            allowTransitionClock: true,
            maxTicks: 6000,
          );
          return;
        }
        if (game.debugPlayerGridPosition == target) break;
        final path = _pathTo(target);
        _require(
          path != null && path.isNotEmpty,
          operation: 'world.enterTrigger',
          message: 'No physical route reaches battle trigger "$triggerId".',
        );
        final direction = path!.first;
        final before = game.debugPlayerGridPosition;
        await _tapMovement(_controlForDirection(direction));
        movementAttempted = true;
        if (game.debugPlayerGridPosition == before &&
            game.debugFlowPhaseName != 'battleTransition' &&
            game.debugFlowPhaseName != 'battle') {
          _runtimeRejectedEdgesByMapId
              .putIfAbsent(state.currentMapId, () => <String>{})
              .add(_edgeKey(before, direction));
        }
      }
      await _pumpUntil(
        () => game.debugFlowPhaseName == 'battle',
        operation: 'world.enterTrigger',
        driveCinematic: true,
        drivePlainDialogue: true,
        allowTransitionClock: true,
        maxTicks: 6000,
      );
      return;
    }
    await navigateTo(target.x, target.y);
  }

  @override
  Future<void> enterWarp(String warpId) async {
    final sourceMapId = state.currentMapId;
    final warp =
        _currentMap.warps.where((entry) => entry.id == warpId).firstOrNull;
    _require(
      warp != null,
      operation: 'world.enterWarp',
      message: 'Warp "$warpId" does not exist on $sourceMapId.',
    );
    if (game.debugPlayerGridPosition == warp!.pos) {
      final adjacent = _adjacentReachableCell(warp.pos);
      await navigateTo(adjacent.x, adjacent.y);
    }
    await navigateTo(warp.pos.x, warp.pos.y);
    await _pumpUntil(
      () =>
          state.currentMapId == warp.targetMapId &&
          !game.debugHasPendingMapTransition,
      operation: 'world.enterWarp',
      allowTransitionClock: true,
    );
    await _pumpUntil(
      () =>
          game.debugFlowPhaseName == 'overworld' &&
          !game.debugIsMapActivationDispatchInFlight &&
          !game.debugIsNarrativeSpatialDispatchInFlight,
      operation: 'world.enterWarp',
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
      maxTicks: 6000,
    );
  }

  @override
  Future<void> enterWildEncounter() async {
    final zone = _currentMap.gameplayZones.firstWhere(
      (candidate) => candidate.kind == GameplayZoneKind.encounter,
      orElse: () => throw EvaluationDriverFailure(
        operation: 'world.enterEncounter',
        message: 'No encounter zone exists on ${state.currentMapId}.',
        snapshot: snapshot(),
      ),
    );
    if (_contains(zone.area, game.debugPlayerGridPosition)) {
      final outside = _reachableCellOutsideArea(zone.area);
      for (var attempt = 0; attempt < 600; attempt += 1) {
        if (_hasBattleHandoff) {
          await _pumpUntil(
            () => game.debugFlowPhaseName == 'battle',
            operation: 'world.enterEncounter',
            allowTransitionClock: true,
          );
          return;
        }
        if (game.debugPlayerGridPosition == outside) break;
        final path = _pathTo(outside);
        _require(
          path != null && path.isNotEmpty,
          operation: 'world.enterEncounter',
          message: 'No physical route exits the encounter zone.',
        );
        await _tapMovement(_controlForDirection(path!.first));
      }
    }
    final target = _reachableCellInArea(zone.area);
    for (var attempt = 0; attempt < 600; attempt += 1) {
      if (_hasBattleHandoff) {
        await _pumpUntil(
          () => game.debugFlowPhaseName == 'battle',
          operation: 'world.enterEncounter',
          allowTransitionClock: true,
        );
        return;
      }
      final path = _pathTo(target);
      _require(
        path != null && path.isNotEmpty,
        operation: 'world.enterEncounter',
        message: 'No physical route reaches the encounter zone.',
      );
      await _tapMovement(_controlForDirection(path!.first));
    }
    throw EvaluationDriverFailure(
      operation: 'world.enterEncounter',
      message: 'No wild encounter started after 600 physical steps.',
      snapshot: snapshot(),
    );
  }

  @override
  Future<void> waitForFact(
    String factId, {
    Duration? timeout,
  }) async {
    final tickBudget = timeout == null
        ? 3000
        : (timeout.inMilliseconds / 16).ceil().clamp(1, 120000);
    await _pumpUntil(
      () => state.narrativeFactRuntimeState.overridesByFactId[factId] == true,
      operation: 'world.waitForFact',
      maxTicks: tickBudget,
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
    );
    await _settleToOverworld(operation: 'world.waitForFact');
  }

  @override
  Future<void> advanceDialogue() async {
    if (game.debugFlowPhaseName != 'dialogue') {
      await _pumpUntil(
        () => game.debugFlowPhaseName == 'dialogue',
        operation: 'dialogue.advance',
        driveCinematic: true,
        maxTicks: 6000,
      );
    }
    _require(
      game.debugFlowPhaseName == 'dialogue',
      operation: 'dialogue.advance',
      message: 'No dialogue is currently open.',
    );
    _pressPrimary(operation: 'dialogue.advance');
    await _microPump();
  }

  @override
  Future<void> chooseDialogue(
    int choiceIndex, {
    int? linesBeforeChoice,
  }) async {
    _require(
      choiceIndex >= 0,
      operation: 'dialogue.choose',
      message: 'choiceIndex must be non-negative.',
    );
    if (game.debugFlowPhaseName != 'dialogue') {
      await _pumpUntil(
        () => game.debugFlowPhaseName == 'dialogue',
        operation: 'dialogue.choose',
        driveCinematic: true,
        maxTicks: 6000,
      );
    }
    _require(
      game.debugFlowPhaseName == 'dialogue',
      operation: 'dialogue.choose',
      message: 'No dialogue is currently open.',
    );
    for (var line = 0; line < (linesBeforeChoice ?? 0); line += 1) {
      _pressPrimary(operation: 'dialogue.choose');
      await _microPump();
    }
    for (var move = 0; move < choiceIndex; move += 1) {
      _pressInput(
        RuntimeInputControl.down,
        operation: 'dialogue.choose',
      );
      await _microPump();
    }
    _pressPrimary(operation: 'dialogue.choose');
    await _microPump();
  }

  @override
  Future<void> chooseBattleMove(int moveIndex) async {
    _require(
      moveIndex >= 0 && moveIndex < 4,
      operation: 'battle.chooseMove',
      message: 'moveIndex must be between 0 and 3.',
    );
    await _waitForBattleInputReady();
    final overlay = game.debugBattleOverlayComponent;
    _require(
      overlay != null,
      operation: 'battle.chooseMove',
      message: 'The battle overlay is not mounted.',
    );
    if (overlay!.currentMenuMode.name == 'continueOnly') {
      _pressPrimary(operation: 'battle.chooseMove');
      await _waitForBattleInputReady();
      return;
    }
    await _returnBattleMenuToRoot(operation: 'battle.chooseMove');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    _pressPrimary(operation: 'battle.chooseMove');
    await _microPump();
    _require(
      overlay.currentMenuMode.name == 'fight',
      operation: 'battle.chooseMove',
      message: 'The runtime did not open the move menu.',
    );
    final battle = game.debugBattleSessionSnapshot;
    _require(
      battle != null && moveIndex < battle.state.player.moves.length,
      operation: 'battle.chooseMove',
      message: 'Move slot $moveIndex is not available.',
    );
    if (moveIndex >= 2) {
      await _pressBattleDirection(RuntimeInputControl.down);
    }
    if (moveIndex.isOdd) {
      await _pressBattleDirection(RuntimeInputControl.right);
    }
    _pressPrimary(operation: 'battle.chooseMove');
    await _waitForBattleInputReady();
  }

  @override
  Future<void> useBattleItem(String itemId) async {
    final before = _bagQuantity(itemId);
    _require(
      before > 0,
      operation: 'battle.useItem',
      message: 'The bag does not contain "$itemId".',
    );
    await _openBattleBag(operation: 'battle.useItem');
    _pressPrimary(operation: 'battle.useItem');
    await _microPump();
    final overlay = game.debugBattleOverlayComponent;
    _require(
      overlay?.currentMenuMode.name == 'bagMedicineTarget',
      operation: 'battle.useItem',
      message: 'The requested item is not available as active medicine.',
    );
    _pressPrimary(operation: 'battle.useItem');
    await _waitForBattleInputReady();
    _require(
      _bagQuantity(itemId) < before,
      operation: 'battle.useItem',
      message: 'The battle item "$itemId" was not consumed.',
    );
  }

  @override
  Future<void> attemptCapture() async {
    await _openBattleBag(operation: 'battle.capture');
    _pressPrimary(operation: 'battle.capture');
    await _waitForBattleInputReady();
  }

  @override
  Future<void> runFromBattle() async {
    await _waitForBattleInputReady();
    final overlay = game.debugBattleOverlayComponent;
    _require(
      overlay != null,
      operation: 'battle.run',
      message: 'The battle overlay is not mounted.',
    );
    if (overlay!.currentMenuMode.name == 'continueOnly') {
      _pressPrimary(operation: 'battle.run');
      await _waitForBattleInputReady();
      return;
    }
    await _returnBattleMenuToRoot(operation: 'battle.run');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    await _pressBattleDirection(RuntimeInputControl.down);
    await _pressBattleDirection(RuntimeInputControl.right);
    _pressPrimary(operation: 'battle.run');
    await _waitForBattleInputReady();
  }

  @override
  Future<void> completePostBattle() async {
    final battleFinished =
        game.debugBattleSessionSnapshot?.state.isFinished ?? false;
    _require(
      game.debugPostBattleOverlayMounted || battleFinished,
      operation: 'battle.completePostBattle',
      message: 'No completed battle is awaiting acknowledgement.',
    );
    await _pumpUntil(
      () =>
          game.debugFlowPhaseName != 'battle' ||
          game.debugPostBattleOverlayMounted,
      operation: 'battle.completePostBattle',
      allowTransitionClock: true,
    );
    for (var acknowledgement = 0;
        acknowledgement < 240 && game.debugPostBattleOverlayMounted;
        acknowledgement += 1) {
      _require(
        game.debugValidatePostBattleChoice(),
        operation: 'battle.completePostBattle',
        message: 'The post-battle choice was rejected.',
      );
      await _microPump();
    }
    _require(
      !game.debugPostBattleOverlayMounted,
      operation: 'battle.completePostBattle',
      message: 'The post-battle queue exceeded 240 acknowledgements.',
    );
    await game.debugWaitForPostBattleCompletion();
  }

  @override
  Future<void> resolveBattle(String strategy) async {
    _require(
      const <String>{'win', 'lose', 'capture', 'run'}.contains(strategy),
      operation: 'battle.resolve',
      message: 'Unknown battle strategy "$strategy".',
    );
    await _pumpUntil(
      () => game.debugFlowPhaseName == 'battle',
      operation: 'battle.resolve',
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
      maxTicks: 6000,
    );
    for (var turn = 0; turn < 80; turn += 1) {
      if (game.debugFlowPhaseName != 'battle') return;
      await _waitForBattleInputReady();
      final finished =
          game.debugBattleSessionSnapshot?.state.isFinished ?? false;
      if (game.debugPostBattleOverlayMounted || finished) {
        await completePostBattle();
        return;
      }
      switch (strategy) {
        case 'capture':
          await attemptCapture();
        case 'run':
          await runFromBattle();
        case 'lose':
          final moves = game.debugBattleSessionSnapshot!.state.player.moves;
          final index = moves.indexWhere(
            (move) => move.power == 0 && move.currentPp > 0,
          );
          _require(
            index >= 0,
            operation: 'battle.resolve',
            message: 'The active battler has no usable status move.',
          );
          await chooseBattleMove(index);
        case 'win':
          final moves = game.debugBattleSessionSnapshot!.state.player.moves;
          var bestIndex = -1;
          var bestPower = -1;
          for (var index = 0; index < moves.length; index += 1) {
            final move = moves[index];
            if (move.currentPp > 0 && move.power > bestPower) {
              bestIndex = index;
              bestPower = move.power;
            }
          }
          _require(
            bestIndex >= 0 && bestPower > 0,
            operation: 'battle.resolve',
            message: 'The active battler has no usable damaging move.',
          );
          await chooseBattleMove(bestIndex);
      }
    }
    throw EvaluationDriverFailure(
      operation: 'battle.resolve',
      message: 'Battle exceeded 80 player turns.',
      snapshot: snapshot(),
    );
  }

  @override
  Future<void> inspectShop() async {
    final attachedServices = _attachedServices;
    if (attachedServices != null) {
      await _runVisiblePlayerService(
        attachedServices,
        kind: 'shop',
        entityId: 'service_port_shop',
        operation: 'service.shop.inspect',
        action: attachedServices.inspectShop,
        openService: () =>
            game.debugOpenPlayerServiceShop('shop_port_supplies'),
      );
      _rememberVisibleShop(attachedServices);
      return;
    }
    final playerServices = _requireHeadlessPlayerServices();
    final requestCount = playerServices.shopRequests.length;
    await interact('service_port_shop');
    await _pumpUntil(
      () => playerServices.shopRequests.length == requestCount + 1,
      operation: 'service.shop.inspect',
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
    );
    _rememberShop(playerServices.shopRequests.last);
    await _settleToOverworld(operation: 'service.shop.inspect');
  }

  @override
  Future<void> buy(String itemId, int quantity) async {
    _require(
      quantity > 0,
      operation: 'service.shop.buy',
      message: 'quantity must be positive.',
    );
    final attachedServices = _attachedServices;
    if (attachedServices != null) {
      await _runVisiblePlayerService(
        attachedServices,
        kind: 'shop',
        entityId: 'service_port_shop',
        operation: 'service.shop.buy',
        action: () => attachedServices.buy(itemId, quantity),
        openService: () =>
            game.debugOpenPlayerServiceShop('shop_port_supplies'),
      );
      _rememberVisibleShop(attachedServices);
      return;
    }
    final playerServices = _requireHeadlessPlayerServices();
    for (var index = 0; index < quantity; index += 1) {
      final purchaseCount = playerServices.purchasedItemIds.length;
      playerServices.queueShopPurchase(itemId);
      await interact('service_port_shop');
      await _pumpUntil(
        () => playerServices.purchasedItemIds.length == purchaseCount + 1,
        operation: 'service.shop.buy',
        driveCinematic: true,
        drivePlainDialogue: true,
        allowTransitionClock: true,
      );
      _rememberShop(playerServices.shopRequests.last);
      await _settleToOverworld(operation: 'service.shop.buy');
    }
  }

  @override
  Future<void> healParty() async {
    final attachedServices = _attachedServices;
    if (attachedServices != null) {
      final hpBefore = state.party.members
          .map((pokemon) => pokemon.currentHp)
          .toList(growable: false);
      await _runVisiblePlayerService(
        attachedServices,
        kind: 'heal',
        entityId: 'service_port_healing',
        operation: 'service.heal',
        action: attachedServices.healParty,
        completedWithoutOverlay: () {
          final hpAfter = state.party.members
              .map((pokemon) => pokemon.currentHp)
              .toList(growable: false);
          return hpAfter.length == hpBefore.length &&
              Iterable<int>.generate(hpAfter.length).any(
                (index) => hpAfter[index] > hpBefore[index],
              );
        },
      );
      return;
    }
    final playerServices = _requireHeadlessPlayerServices();
    final openedCount = playerServices.openedServices.length;
    final hpBefore = state.party.members
        .map((pokemon) => pokemon.currentHp)
        .toList(growable: false);
    await interact('service_port_healing');
    await _pumpUntil(
      () {
        if (playerServices.openedServices.length == openedCount + 1) {
          return true;
        }
        final hpAfter = state.party.members
            .map((pokemon) => pokemon.currentHp)
            .toList(growable: false);
        return hpAfter.length == hpBefore.length &&
            Iterable<int>.generate(hpAfter.length).any(
              (index) => hpAfter[index] > hpBefore[index],
            );
      },
      operation: 'service.heal',
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
    );
    await _settleToOverworld(operation: 'service.heal');
  }

  @override
  Future<void> withdrawFromPc(String pokemonId) async {
    final attachedServices = _attachedServices;
    if (attachedServices != null) {
      await _runVisiblePlayerService(
        attachedServices,
        kind: 'pc',
        entityId: 'service_port_pc',
        operation: 'service.pc.withdraw',
        action: () => attachedServices.withdrawFromPc(pokemonId),
      );
      return;
    }
    final playerServices = _requireHeadlessPlayerServices();
    final stored = state.pokemonStorage.boxes
        .expand((box) => box.pokemon)
        .where((pokemon) => pokemon.speciesId == pokemonId)
        .toList(growable: false);
    _require(
      stored.isNotEmpty,
      operation: 'service.pc.withdraw',
      message: 'Pokemon "$pokemonId" is not present in storage.',
    );
    playerServices.queueCapturedPokemonWithdrawal();
    await interact('service_port_pc');
    await _pumpUntil(
      () => playerServices.withdrawnSpeciesId != null,
      operation: 'service.pc.withdraw',
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
    );
    await _settleToOverworld(operation: 'service.pc.withdraw');
  }

  @override
  Future<void> swapPartyMembers(int firstIndex, int secondIndex) async {
    await _commitStorageOperation(
      const PlayerStorageOperations().swapPartyMembers(
        state: state,
        firstIndex: firstIndex,
        secondIndex: secondIndex,
      ),
      operation: 'party.swap',
    );
  }

  @override
  Future<void> setLeadPokemon(int partyIndex) async {
    await _commitStorageOperation(
      const PlayerStorageOperations().setLead(
        state: state,
        partyIndex: partyIndex,
      ),
      operation: 'party.setLead',
    );
  }

  @override
  Future<void> useBagItem(
    String itemId,
    int partyIndex, {
    String? moveId,
  }) async {
    final controller = _playerServiceController;
    _require(
      controller != null,
      operation: 'bag.use',
      message: 'Bag use requires the runtime player-service controller.',
    );
    final result = await controller!.useBagItemOutsideBattle(
      RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: itemId,
        partyTargetId: 'party.$partyIndex',
        moveTargetId: moveId,
      ),
    );
    _require(
      result.status == RuntimePlayerPauseCommandStatus.accepted,
      operation: 'bag.use',
      message: result.safeMessage,
    );
  }

  @override
  Future<void> depositPartyPokemon(int partyIndex, {String? boxId}) async {
    await _commitStorageOperation(
      const PlayerStorageOperations().deposit(
        state: state,
        partyIndex: partyIndex,
        boxId: boxId,
      ),
      operation: 'service.pc.deposit',
    );
  }

  @override
  Future<void> withdrawPcSlot(String boxId, int boxIndex) async {
    await _commitStorageOperation(
      const PlayerStorageOperations().withdraw(
        state: state,
        boxId: boxId,
        boxIndex: boxIndex,
      ),
      operation: 'service.pc.withdrawSlot',
    );
  }

  @override
  Future<void> swapPartyWithPc(
    int partyIndex,
    String boxId,
    int boxIndex,
  ) async {
    await _commitStorageOperation(
      const PlayerStorageOperations().swapPartyWithBox(
        state: state,
        partyIndex: partyIndex,
        boxId: boxId,
        boxIndex: boxIndex,
      ),
      operation: 'service.pc.swap',
    );
  }

  @override
  Future<void> sell(
    String shopId,
    String expectedStateId,
    String itemId,
    int quantity,
  ) async {
    final shop =
        project.shops.where((candidate) => candidate.id == shopId).firstOrNull;
    _require(
      shop != null,
      operation: 'service.shop.sell',
      message: 'Shop "$shopId" does not exist.',
    );
    final result = const GameStateMutations().sellToResolvedShop(
      state,
      shop: shop!,
      expectedStateId: expectedStateId,
      itemId: itemId,
      quantity: quantity,
      conditionContext: ScriptEvaluationContext(
        narrativeFactResolver:
            NarrativeFactRuntimeResolver.fromFacts(project.facts),
      ),
    );
    _require(
      result.isSuccess,
      operation: 'service.shop.sell',
      message: 'Shop sale failed: ${result.failure?.name ?? 'unknown'}.',
    );
    await game.commitAndSavePlayerServiceState(result.state);
  }

  @override
  Future<void> switchBattlePokemon(int partyIndex) async {
    _require(
      partyIndex > 0 && partyIndex < state.party.members.length,
      operation: 'battle.switch',
      message: 'partyIndex must select a reserve party member.',
    );
    await _waitForBattleInputReady();
    final overlay = game.debugBattleOverlayComponent;
    _require(
      overlay != null,
      operation: 'battle.switch',
      message: 'The battle overlay is not mounted.',
    );
    await _returnBattleMenuToRoot(operation: 'battle.switch');
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    await _pressBattleDirection(RuntimeInputControl.down);
    _pressPrimary(operation: 'battle.switch');
    await _microPump();
    _require(
      overlay!.currentMenuMode.name == 'pokemon',
      operation: 'battle.switch',
      message: 'The runtime did not open the party menu.',
    );
    for (var reset = 0; reset < 6; reset += 1) {
      await _pressBattleDirection(RuntimeInputControl.up);
      await _pressBattleDirection(RuntimeInputControl.left);
    }
    if (partyIndex >= 2) {
      for (var row = 0; row < partyIndex ~/ 2; row += 1) {
        await _pressBattleDirection(RuntimeInputControl.down);
      }
    }
    await _pressBattleDirection(
      partyIndex.isOdd ? RuntimeInputControl.right : RuntimeInputControl.left,
    );
    _pressPrimary(operation: 'battle.switch');
    await _waitForBattleInputReady();
    _require(
      game.debugBattleSessionSnapshot?.state.player.lineupIndex == partyIndex,
      operation: 'battle.switch',
      message: 'The runtime did not switch to party slot $partyIndex.',
    );
  }

  @override
  Future<void> chooseBattleProgression(int decisionIndex) async {
    _require(
      game.debugPostBattleOverlayMounted,
      operation: 'battle.chooseProgression',
      message: 'No post-battle learning or evolution choice is active.',
    );
    final labels = game.debugPostBattleDecisionLabels;
    _require(
      decisionIndex >= 0 && decisionIndex < labels.length,
      operation: 'battle.chooseProgression',
      message: 'decisionIndex $decisionIndex is outside the visible choices.',
    );
    for (var reset = 0; reset < labels.length; reset += 1) {
      await _pressBattleDirection(RuntimeInputControl.up);
    }
    for (var index = 0; index < decisionIndex; index += 1) {
      await _pressBattleDirection(RuntimeInputControl.down);
    }
    _require(
      game.debugValidatePostBattleChoice(),
      operation: 'battle.chooseProgression',
      message: 'The post-battle decision was rejected.',
    );
    await _microPump();
  }

  @override
  Future<void> startTrainerBattle(String trainerId, String npcEntityId) async {
    _require(
      project.trainers.any((trainer) => trainer.id == trainerId),
      operation: 'battle.startTrainer',
      message: 'Trainer "$trainerId" does not exist.',
    );
    await _openExplicitBattle(
      TrainerBattleStartRequest(
        requestId: _nextBattleRequestId('trainer'),
        createdAtEpochMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        returnContext: _returnContext,
        trainerId: trainerId,
        npcEntityId: npcEntityId,
        mapId: state.currentMapId,
        playerPos: state.playerPosition,
      ),
      operation: 'battle.startTrainer',
    );
  }

  @override
  Future<void> startStaticBattle(
    String battleId,
    String opponentProfileId,
    String entityId,
  ) async {
    _require(
      project.trainers.any((trainer) => trainer.id == opponentProfileId),
      operation: 'battle.startStatic',
      message: 'Opponent profile "$opponentProfileId" does not exist.',
    );
    await _openExplicitBattle(
      StaticBattleStartRequest(
        requestId: _nextBattleRequestId('static'),
        createdAtEpochMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        returnContext: _returnContext,
        battleId: battleId,
        opponentProfileId: opponentProfileId,
        entityId: entityId,
        mapId: state.currentMapId,
        playerPos: state.playerPosition,
      ),
      operation: 'battle.startStatic',
    );
  }

  @override
  Future<void> save() async {
    final saved = await game.saveGame();
    _require(
      saved,
      operation: 'save.write',
      message: 'The runtime save repository rejected the write.',
    );
  }

  @override
  Future<void> saveAndReload() async {
    await save();
    final loaded = await game.loadGame();
    _require(
      loaded,
      operation: 'save.reload',
      message: 'The runtime save repository rejected the reload.',
    );
    await _pumpUntil(
      () =>
          !game.debugHasPendingMapTransition &&
          !game.debugIsMapActivationDispatchInFlight,
      operation: 'save.reload',
      allowTransitionClock: true,
    );
  }

  @override
  Future<void> createCheckpoint(String checkpointId) async {
    _require(
      checkpointId.trim().isNotEmpty,
      operation: 'evidence.checkpoint',
      message: 'checkpointId must not be blank.',
    );
    await save();
    _checkpoints[checkpointId] = state;
    final cache = checkpointCache;
    final provenance = checkpointProvenance;
    if (cache != null && provenance != null) {
      await cache.store(checkpointId, provenance, state);
    }
  }

  @override
  Future<void> probeLoadCheckpoint(String checkpointId) async {
    var checkpoint = _checkpoints[checkpointId];
    final cache = checkpointCache;
    final provenance = checkpointProvenance;
    if (checkpoint == null && cache != null && provenance != null) {
      try {
        checkpoint = await cache.load(checkpointId, provenance);
      } on Object catch (failure) {
        throw EvaluationDriverFailure(
          operation: 'probe.loadCheckpoint',
          message: failure.toString(),
          snapshot: snapshot(),
        );
      }
    }
    _require(
      checkpoint != null,
      operation: 'probe.loadCheckpoint',
      message: 'Checkpoint "$checkpointId" does not exist.',
    );
    await _commitProbeState(checkpoint!, operation: 'probe.loadCheckpoint');
  }

  @override
  Future<void> probeGoto(String mapId, int x, int y) async {
    _mapById(mapId);
    await _commitProbeState(
      state.copyWith(
        currentMapId: mapId,
        playerPosition: GridPos(x: x, y: y),
      ),
      operation: 'probe.goto',
    );
  }

  @override
  Future<void> probeOverrideFact(String factId, bool value) async {
    final values = Map<String, NarrativeValue>.from(
      state.narrativeFactRuntimeState.valuesByFactId,
    )..[factId] = NarrativeValue.boolean(value);
    await _commitProbeState(
      state.copyWith(
        narrativeFactRuntimeState:
            NarrativeFactRuntimeState.typed(valuesByFactId: values),
      ),
      operation: 'probe.overrideFact',
    );
  }

  @override
  Future<void> probeSetMoney(int value) async {
    _require(
      value >= 0,
      operation: 'probe.setMoney',
      message: 'Money must be non-negative.',
    );
    await _commitProbeState(
      state.copyWith(
        trainerProfile: state.trainerProfile.copyWith(money: value),
      ),
      operation: 'probe.setMoney',
    );
  }

  @override
  Future<void> probeSeedBag(Map<String, int> quantities) async {
    _require(
      quantities.values.every((quantity) => quantity > 0),
      operation: 'probe.seedBag',
      message: 'Every seeded bag quantity must be positive.',
    );
    await _commitProbeState(
      state.copyWith(
        bag: Bag(
          entries: <BagEntry>[
            for (final entry in quantities.entries)
              BagEntry(
                itemId: entry.key,
                categoryId: _categoryForItem(entry.key),
                quantity: entry.value,
              ),
          ],
        ).normalized(),
      ),
      operation: 'probe.seedBag',
    );
  }

  @override
  Future<void> probeSeedParty(
    List<Map<String, Object?>> pokemon,
  ) async {
    final members = pokemon
        .map(
          (value) => PlayerPokemon.fromJson(
            Map<String, dynamic>.from(value),
          ),
        )
        .toList(growable: false);
    await _commitProbeState(
      state.copyWith(party: PlayerParty(members: members).normalized()),
      operation: 'probe.seedParty',
    );
  }

  @override
  Future<void> dispose() async {
    if (_ownsGame) game.onRemove();
  }

  EvaluationPlayerServiceHost _requireHeadlessPlayerServices() {
    final services = playerServices;
    if (services == null) {
      throw StateError('Headless player services are unavailable.');
    }
    return services;
  }

  int _bagQuantity(String itemId) => state.bag.entries
      .where((entry) => entry.itemId == itemId)
      .fold(0, (total, entry) => total + entry.quantity);

  var _battleRequestSequence = 0;

  String _nextBattleRequestId(String kind) =>
      '$runId:$kind:${++_battleRequestSequence}';

  OverworldReturnContext get _returnContext => OverworldReturnContext(
        mapId: state.currentMapId,
        playerPos: state.playerPosition,
        playerFacing: switch (state.playerFacing) {
          EntityFacing.north => Direction.north,
          EntityFacing.south => Direction.south,
          EntityFacing.east => Direction.east,
          EntityFacing.west => Direction.west,
        },
      );

  Future<void> _openExplicitBattle(
    BattleStartRequest request, {
    required String operation,
  }) async {
    _require(
      game.debugFlowPhaseName == 'overworld',
      operation: operation,
      message: 'An explicit battle can only start from the overworld.',
    );
    await game.debugOpenBattleForTest(request);
    await _pumpUntil(
      () => game.debugFlowPhaseName == 'battle',
      operation: operation,
      allowTransitionClock: true,
    );
  }

  Future<void> _commitStorageOperation(
    PlayerStorageOperationResult result, {
    required String operation,
  }) async {
    _require(
      result.isSuccess,
      operation: operation,
      message:
          'Storage operation failed: ${result.failure?.name ?? 'unknown'}.',
    );
    await game.commitAndSavePlayerServiceState(result.state);
  }

  void _rememberShop(PlayerServiceShopRequest request) {
    _lastShop = <String, Object?>{
      'id': request.shop.id,
      'activeStateId': request.resolvedState.stateId,
      'isOpen': request.resolvedState.isOpen,
      'catalogue': <String, int>{
        for (final entry in request.resolvedState.entries)
          entry.itemId: entry.price,
      },
      'message': request.resolvedState.message,
    };
  }

  void _rememberVisibleShop(EvaluationPlayerServiceAutomation services) {
    if (services
        case EvaluationVisiblePlayerServiceAutomation(
          :final lastShopSnapshot?,
        )) {
      _lastShop = <String, Object?>{
        'id': lastShopSnapshot['shopId'],
        'activeStateId': lastShopSnapshot['stateId'],
        'isOpen': lastShopSnapshot['isOpen'],
        'catalogue': lastShopSnapshot['catalogue'],
        'message': lastShopSnapshot['message'],
      };
    }
  }

  Future<void> _waitForBattleInputReady() async {
    await _pumpUntil(
      () =>
          game.debugFlowPhaseName == 'battle' ||
          game.debugFlowPhaseName == 'overworld',
      operation: 'battle.waitForInput',
      allowTransitionClock: true,
    );
    _require(
      game.debugFlowPhaseName == 'battle',
      operation: 'battle.waitForInput',
      message: 'No active battle is available.',
    );
    await game.debugWaitForBattleOverlaySync();
    await _pumpUntil(
      () =>
          game.debugFlowPhaseName != 'battle' ||
          !(game.debugBattleOverlayComponent?.isTurnPresentationActive ??
              false),
      operation: 'battle.waitForInput',
      allowTransitionClock: true,
    );
  }

  Future<void> _pressBattleDirection(RuntimeInputControl control) async {
    _pressInput(control, operation: 'battle.navigate');
    await _microPump();
  }

  Future<void> _returnBattleMenuToRoot({
    required String operation,
  }) async {
    final overlay = game.debugBattleOverlayComponent;
    _require(
      overlay != null,
      operation: operation,
      message: 'The battle overlay is not mounted.',
    );
    final activeOverlay = overlay!;
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back += 1) {
      _require(
        game.backFromBattleOverlay(),
        operation: operation,
        message: 'The runtime rejected a battle-menu back action.',
      );
      await _microPump();
    }
    _require(
      activeOverlay.currentMenuMode.name == 'root',
      operation: operation,
      message: 'The battle menu could not return to its root.',
    );
  }

  Future<void> _openBattleBag({required String operation}) async {
    await _waitForBattleInputReady();
    await _returnBattleMenuToRoot(operation: operation);
    final overlay = game.debugBattleOverlayComponent!;
    await _pressBattleDirection(RuntimeInputControl.up);
    await _pressBattleDirection(RuntimeInputControl.left);
    await _pressBattleDirection(RuntimeInputControl.right);
    _pressPrimary(operation: operation);
    await _microPump();
    _require(
      overlay.currentMenuMode.name == 'bag',
      operation: operation,
      message: 'The runtime did not open the battle bag.',
    );
  }

  Future<void> _settleToOverworld({required String operation}) {
    return _pumpUntil(
      () =>
          game.debugFlowPhaseName == 'overworld' &&
          !game.debugIsNarrativeSpatialDispatchInFlight &&
          !game.debugIsNarrativeOutcomeWorkInFlight &&
          !game.debugIsCinematicPlaying,
      operation: operation,
      driveCinematic: true,
      drivePlainDialogue: true,
      allowTransitionClock: true,
      maxTicks: 6000,
    );
  }

  Future<void> _runVisiblePlayerService(
    EvaluationPlayerServiceAutomation services, {
    required String kind,
    required String entityId,
    required String operation,
    required Future<void> Function() action,
    bool Function()? completedWithoutOverlay,
    Future<void> Function()? openService,
  }) async {
    if (services is! EvaluationVisiblePlayerServiceAutomation) {
      await action();
      return;
    }
    final serviceCompletion = openService?.call();
    if (serviceCompletion == null) {
      await interact(entityId);
    }
    await _waitForLiveRuntime(
      () =>
          services.activeServiceName == kind ||
          (completedWithoutOverlay?.call() ?? false),
      operation: '$operation.open',
      driveDialogue: true,
    );
    if (services.activeServiceName != kind) {
      await waitUntilRuntimeReady(driveDialogue: true);
      return;
    }
    try {
      await action();
    } finally {
      if (services.activeServiceName == kind) {
        await services.closeActiveService();
      }
      await _waitForLiveRuntime(
        () => services.activeServiceName == null,
        operation: '$operation.close',
      );
    }
    await serviceCompletion;
    await waitUntilRuntimeReady(driveDialogue: true);
  }

  Future<void> _commitProbeState(
    GameState nextState, {
    required String operation,
  }) async {
    await game.commitAndSavePlayerServiceState(nextState);
    final loaded = await game.loadGame();
    _require(
      loaded,
      operation: operation,
      message: 'The probe state could not be reloaded.',
    );
    await _pumpUntil(
      () =>
          !game.debugHasPendingMapTransition &&
          !game.debugIsMapActivationDispatchInFlight,
      operation: operation,
      allowTransitionClock: true,
    );
  }

  bool get _hasBattleHandoff =>
      game.debugPendingBattleRequest != null ||
      game.debugFlowPhaseName == 'battleTransition' ||
      game.debugFlowPhaseName == 'battle';

  Future<void> _microPump() async {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }

  void _pressPrimary({required String operation}) {
    _pressInput(RuntimeInputControl.primary, operation: operation);
  }

  void _pressInput(
    RuntimeInputControl control, {
    required String operation,
  }) {
    _require(
      game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
      operation: operation,
      message: 'The runtime rejected ${control.name} input.',
    );
  }

  Future<void> _tapMovement(RuntimeInputControl control) async {
    _pressInput(control, operation: 'movement.navigate');
    game.update(0.016);
    _require(
      game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
      operation: 'movement.navigate',
      message: 'The runtime rejected ${control.name} release.',
    );
    await _pumpUntil(
      () => !game.debugIsPlayerStepping,
      operation: 'movement.navigate',
      maxTicks: 500,
    );
  }

  MapData get _currentMap => _mapById(state.currentMapId);

  MapData _mapById(String mapId) {
    return _mapsById.putIfAbsent(mapId, () {
      final entry = project.maps.singleWhere((map) => map.id == mapId);
      final json = jsonDecode(
        File(p.join(projectRoot.path, entry.relativePath)).readAsStringSync(),
      ) as Map<String, dynamic>;
      return MapData.fromJson(json);
    });
  }

  GameplayWorldState _pathfindingWorld(MapData map) {
    final projection = const RuntimeWorldRuleProjectionHook().resolve(
      project: project,
      gameState: state,
      map: map,
    );
    bool entityPresence(String _, MapEntity entity) =>
        projection.isMapEntityVisible(entity);
    return GameplayWorldState.initial(
      map: map,
      playerPos: game.debugPlayerGridPosition,
      playerFacing: _directionFromFacing(state.playerFacing),
      project: project,
      tileWidth: project.settings.tileWidth,
      tileHeight: project.settings.tileHeight,
      playerMovementMode: state.playerMovementMode,
      npcMapPresencePredicate: entityPresence,
      mapEntityPresencePredicate: entityPresence,
    );
  }

  List<Direction>? _pathTo(GridPos target) {
    return _findPath(target, avoidEncounters: true) ??
        _findPath(target, avoidEncounters: false);
  }

  List<Direction>? _findPath(
    GridPos target, {
    required bool avoidEncounters,
  }) {
    final map = _currentMap;
    final world = _pathfindingWorld(map);
    final start = game.debugPlayerGridPosition;
    if (start == target) return <Direction>[];
    if (!_inside(map, target) || world.isBlocked(target.x, target.y)) {
      return null;
    }
    final queue = Queue<GridPos>()..add(start);
    final previous = <GridPos, ({GridPos pos, Direction direction})>{};
    final visited = <GridPos>{start};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final direction in const <Direction>[
        Direction.north,
        Direction.east,
        Direction.south,
        Direction.west,
      ]) {
        final next = _translated(current, direction);
        if (!_inside(map, next) ||
            visited.contains(next) ||
            (_runtimeRejectedEdgesByMapId[map.id]
                    ?.contains(_edgeKey(current, direction)) ??
                false) ||
            !_canTakePhysicalStep(world, current, direction, next) ||
            _isUnintendedWarpCell(map, next, target) ||
            (avoidEncounters && _isEncounterCell(map, next))) {
          continue;
        }
        visited.add(next);
        previous[next] = (pos: current, direction: direction);
        if (next == target) {
          final reversed = <Direction>[];
          var cursor = next;
          while (cursor != start) {
            final edge = previous[cursor]!;
            reversed.add(edge.direction);
            cursor = edge.pos;
          }
          return reversed.reversed.toList(growable: false);
        }
        queue.add(next);
      }
    }
    return null;
  }

  bool _canTakePhysicalStep(
    GameplayWorldState baseWorld,
    GridPos from,
    Direction direction,
    GridPos expectedTarget,
  ) {
    final positioned = baseWorld.withPlayer(
      GameplayPlayerState.fromGridSpawn(
        cell: from,
        facing: direction,
        movementMode: state.playerMovementMode,
        tileWidthPx: project.settings.tileWidth,
        tileHeightPx: project.settings.tileHeight,
        mapWidthCells: baseWorld.map.size.width,
        mapHeightCells: baseWorld.map.size.height,
      ),
    );
    var cursor = positioned;
    for (var pixelStep = 0; pixelStep < 32; pixelStep += 1) {
      final result = stepGameplayWorld(cursor, MoveIntent(direction));
      if (result is Blocked) return false;
      cursor = result.world;
      if (cursor.player.pos == expectedTarget) return true;
      if (cursor.player.pos != from) return false;
    }
    return false;
  }

  _EntityApproach _shortestReachableApproach(MapEntity entity) {
    final candidates = <_EntityApproach>[];
    for (final entry in <({Direction facing, GridPos position})>[
      (
        facing: Direction.south,
        position: GridPos(x: entity.pos.x, y: entity.pos.y - 1),
      ),
      (
        facing: Direction.west,
        position: GridPos(x: entity.pos.x + entity.size.width, y: entity.pos.y),
      ),
      (
        facing: Direction.north,
        position:
            GridPos(x: entity.pos.x, y: entity.pos.y + entity.size.height),
      ),
      (
        facing: Direction.east,
        position: GridPos(x: entity.pos.x - 1, y: entity.pos.y),
      ),
    ]) {
      final stagingPosition = GridPos(
        x: entry.position.x - entry.facing.dx,
        y: entry.position.y - entry.facing.dy,
      );
      final stagingPath = _pathTo(stagingPosition);
      final approachPath = _pathTo(entry.position);
      if (stagingPath != null && approachPath != null) {
        candidates.add(
          _EntityApproach(
            position: entry.position,
            stagingPosition: stagingPosition,
            facing: entry.facing,
            pathLength: stagingPath.length + 1,
          ),
        );
      }
    }
    if (candidates.isEmpty) {
      throw EvaluationDriverFailure(
        operation: 'world.interact',
        message: 'Entity ${entity.id} has no reachable interaction front.',
        snapshot: snapshot(),
      );
    }
    candidates
        .sort((left, right) => left.pathLength.compareTo(right.pathLength));
    return candidates.first;
  }

  GridPos _reachableCellInArea(MapRect area) {
    final candidates = <({GridPos pos, int length})>[];
    for (var y = area.pos.y; y < area.pos.y + area.size.height; y += 1) {
      for (var x = area.pos.x; x < area.pos.x + area.size.width; x += 1) {
        final pos = GridPos(x: x, y: y);
        final path = _pathTo(pos);
        if (path != null) candidates.add((pos: pos, length: path.length));
      }
    }
    if (candidates.isEmpty) {
      throw EvaluationDriverFailure(
        operation: 'world.enterTrigger',
        message: 'Trigger area $area has no reachable cell.',
        snapshot: snapshot(),
      );
    }
    candidates.sort((left, right) => left.length.compareTo(right.length));
    return candidates.first.pos;
  }

  GridPos _adjacentReachableCell(GridPos origin) {
    for (final direction in Direction.values) {
      final candidate = _translated(origin, direction);
      if (_pathTo(candidate) != null) return candidate;
    }
    throw EvaluationDriverFailure(
      operation: 'world.enterWarp',
      message: 'No reachable exit adjacent to $origin.',
      snapshot: snapshot(),
    );
  }

  GridPos _reachableCellOutsideArea(MapRect area) {
    final candidates = <({GridPos pos, int length})>[];
    for (var y = area.pos.y - 1; y <= area.pos.y + area.size.height; y += 1) {
      for (final x in <int>[area.pos.x - 1, area.pos.x + area.size.width]) {
        final pos = GridPos(x: x, y: y);
        final path = _pathTo(pos);
        if (path != null) candidates.add((pos: pos, length: path.length));
      }
    }
    for (var x = area.pos.x; x < area.pos.x + area.size.width; x += 1) {
      for (final y in <int>[area.pos.y - 1, area.pos.y + area.size.height]) {
        final pos = GridPos(x: x, y: y);
        final path = _pathTo(pos);
        if (path != null) candidates.add((pos: pos, length: path.length));
      }
    }
    if (candidates.isEmpty) {
      throw EvaluationDriverFailure(
        operation: 'world.enterTrigger',
        message: 'Trigger area $area has no reachable outside cell.',
        snapshot: snapshot(),
      );
    }
    candidates.sort((left, right) => left.length.compareTo(right.length));
    return candidates.first.pos;
  }

  Iterable<GridPos> _connectionBoundaryCandidates(
    MapData map,
    MapConnectionDirection direction,
    int? preferredAxis,
  ) {
    final result = <GridPos>[];
    final axisLength = switch (direction) {
      MapConnectionDirection.north ||
      MapConnectionDirection.south =>
        map.size.width,
      MapConnectionDirection.east ||
      MapConnectionDirection.west =>
        map.size.height,
    };
    final preferred =
        (preferredAxis ?? axisLength ~/ 2).clamp(0, axisLength - 1);
    final axes = List<int>.generate(axisLength, (index) => index)
      ..sort(
        (left, right) =>
            (left - preferred).abs().compareTo((right - preferred).abs()),
      );
    for (final axis in axes) {
      result.add(
        switch (direction) {
          MapConnectionDirection.north => GridPos(x: axis, y: 0),
          MapConnectionDirection.south =>
            GridPos(x: axis, y: map.size.height - 1),
          MapConnectionDirection.east =>
            GridPos(x: map.size.width - 1, y: axis),
          MapConnectionDirection.west => GridPos(x: 0, y: axis),
        },
      );
    }
    return result;
  }

  bool _isEncounterCell(MapData map, GridPos pos) {
    return map.gameplayZones.any(
      (zone) =>
          zone.kind == GameplayZoneKind.encounter &&
          pos.x >= zone.area.pos.x &&
          pos.y >= zone.area.pos.y &&
          pos.x < zone.area.pos.x + zone.area.size.width &&
          pos.y < zone.area.pos.y + zone.area.size.height,
    );
  }

  bool _isUnintendedWarpCell(MapData map, GridPos pos, GridPos target) {
    if (pos == target) return false;
    return map.warps.any(
      (warp) =>
          warp.triggerMode == MapWarpTriggerMode.onEnter && warp.pos == pos,
    );
  }

  void _require(
    bool condition, {
    required String operation,
    required String message,
  }) {
    if (condition) return;
    throw EvaluationDriverFailure(
      operation: operation,
      message: message,
      snapshot: snapshot(),
    );
  }

  Future<void> _pumpUntil(
    bool Function() predicate, {
    required String operation,
    int maxTicks = 3000,
    bool driveCinematic = false,
    bool drivePlainDialogue = false,
    bool allowTransitionClock = false,
  }) async {
    for (var index = 0; index < maxTicks; index += 1) {
      if (predicate()) return;
      if (driveCinematic &&
          game.debugIsCinematicPlaying &&
          game.debugCinematicDialogueLine != null) {
        _pressPrimary(operation: operation);
      } else if (drivePlainDialogue && game.debugFlowPhaseName == 'dialogue') {
        _pressPrimary(operation: operation);
      }
      game.update(0.016);
      await Future<void>.delayed(
        allowTransitionClock ? const Duration(milliseconds: 1) : Duration.zero,
      );
    }
    if (predicate()) return;
    throw EvaluationDriverFailure(
      operation: operation,
      message: 'Timed out after $maxTicks headless ticks.',
      snapshot: snapshot(),
    );
  }

  Future<void> _waitForLiveRuntime(
    bool Function() predicate, {
    required String operation,
    int maxTicks = 3750,
    bool driveDialogue = false,
  }) async {
    final tickDelay = Duration(
      microseconds: (16000 / _playbackRate).round(),
    );
    for (var index = 0; index < maxTicks; index += 1) {
      if (predicate()) return;
      if (driveDialogue &&
          game.debugIsCinematicPlaying &&
          game.debugCinematicDialogueLine != null) {
        _pressPrimary(operation: operation);
      } else if (driveDialogue && game.debugFlowPhaseName == 'dialogue') {
        _pressPrimary(operation: operation);
      }
      await Future<void>.delayed(tickDelay);
    }
    if (predicate()) return;
    throw EvaluationDriverFailure(
      operation: operation,
      message: 'Timed out while waiting for the visible runtime.',
      snapshot: snapshot(),
    );
  }
}

final class _EntityApproach {
  const _EntityApproach({
    required this.position,
    required this.stagingPosition,
    required this.facing,
    required this.pathLength,
  });

  final GridPos position;
  final GridPos stagingPosition;
  final Direction facing;
  final int pathLength;
}

GridPos _translated(GridPos pos, Direction direction) {
  return switch (direction) {
    Direction.north => GridPos(x: pos.x, y: pos.y - 1),
    Direction.east => GridPos(x: pos.x + 1, y: pos.y),
    Direction.south => GridPos(x: pos.x, y: pos.y + 1),
    Direction.west => GridPos(x: pos.x - 1, y: pos.y),
  };
}

bool _inside(MapData map, GridPos pos) {
  return pos.x >= 0 &&
      pos.y >= 0 &&
      pos.x < map.size.width &&
      pos.y < map.size.height;
}

bool _contains(MapRect area, GridPos pos) {
  return pos.x >= area.pos.x &&
      pos.y >= area.pos.y &&
      pos.x < area.pos.x + area.size.width &&
      pos.y < area.pos.y + area.size.height;
}

Direction _directionFromFacing(EntityFacing facing) {
  return switch (facing) {
    EntityFacing.north => Direction.north,
    EntityFacing.east => Direction.east,
    EntityFacing.south => Direction.south,
    EntityFacing.west => Direction.west,
  };
}

RuntimeInputControl _controlForDirection(Direction direction) {
  return switch (direction) {
    Direction.north => RuntimeInputControl.up,
    Direction.east => RuntimeInputControl.right,
    Direction.south => RuntimeInputControl.down,
    Direction.west => RuntimeInputControl.left,
  };
}

RuntimeInputControl _controlForConnection(MapConnectionDirection direction) {
  return switch (direction) {
    MapConnectionDirection.north => RuntimeInputControl.up,
    MapConnectionDirection.east => RuntimeInputControl.right,
    MapConnectionDirection.south => RuntimeInputControl.down,
    MapConnectionDirection.west => RuntimeInputControl.left,
  };
}

String _edgeKey(GridPos from, Direction direction) =>
    '${from.x}:${from.y}:${direction.name}';

String _categoryForItem(String itemId) => switch (itemId) {
      'potion' || 'super-potion' || 'antidote' => 'medicine',
      'poke-ball' || 'great-ball' || 'ultra-ball' => 'capture',
      _ => 'items',
    };
