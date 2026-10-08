import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../application/battle_start_request.dart';
import '../application/player_service_runtime_controller.dart';
import '../application/runtime_battle_bag_hp_heal_item_apply.dart';
import '../application/runtime_battle_outcome_apply.dart';
import '../application/runtime_battle_setup_mapper.dart';
import '../player/runtime_capture_sprite_resolver.dart';
import '../application/runtime_item_catalog_loader.dart';
import '../application/runtime_map_bundle.dart';
import '../application/runtime_move_catalog_loader.dart';
import '../application/runtime_player_pokemon_progression_hydrator.dart';
import '../application/runtime_post_battle_decision_coordinator.dart';
import '../application/runtime_psdk_battle_session_adapter.dart';
import '../application/runtime_psdk_battle_setup_mapper.dart';
import '../infrastructure/tile_image_loader.dart';
import '../presentation/flame/battle_background_resolver.dart';
import '../presentation/flame/battle_bag_item_icon_resolver.dart';
import '../presentation/flame/battle_bag_menu_model.dart';
import '../presentation/flame/battle_combatant_ball_resolver.dart';
import '../presentation/flame/battle_fx_bundle_cache.dart';
import '../presentation/flame/battle_medicine_target_menu_model.dart';
import '../presentation/flame/battle_overlay_component.dart';
import '../presentation/flame/battle_pokemon_sprite_resolver.dart';
import '../presentation/flame/battle_visual_asset_cache.dart';
import '../presentation/flame/post_battle_progression_overlay_component.dart';
import '../presentation/flame/runtime_input_event.dart';
import '../presentation/flame/runtime_trainer_battle_overrides.dart';

enum SpatialBattlePhase { idle, loading, battle, postBattle }

final class SpatialBattleRuntime extends ChangeNotifier {
  SpatialBattleRuntime({
    required this.readGameState,
    required this.commitGameState,
    this.onCompleted,
    this.onError,
  });

  final GameState Function() readGameState;
  final bool Function(GameState expected, GameState next) commitGameState;
  final FutureOr<void> Function(BattleOutcome outcome)? onCompleted;
  final void Function(Object error)? onError;
  SpatialBattlePhase phase = SpatialBattlePhase.idle;
  static final _externalPause = Object();
  final _pauseOwners = <Object>{};
  bool get isPaused => _pauseOwners.isNotEmpty;
  Object? error;
  BattleSession? displaySession;
  RuntimeActiveBattleContext? context;
  BattleOverlayComponent? battleOverlay;
  PostBattleProgressionOverlayComponent? postBattleOverlay;
  RuntimePsdkBattleSessionAdapter? _engine;
  RuntimeMapBundle? _bundle;
  GameState? _base;
  GameState? _working;
  ItemCatalogSnapshot? _items;
  RuntimePostBattleDecisionCoordinator? _coordinator;
  RuntimeBattleCaptureAttemptReceipt? _captureReceipt;
  BattleVisualAssetCache? _images;
  BattleFxBundleCache? _effects;
  Completer<bool>? _completion;
  Completer<void>? _resumed;
  bool _resolving = false;
  bool _committing = false;
  bool _disposed = false;
  int _generation = 0;

  bool get isActive => phase != SpatialBattlePhase.idle;
  BattlePublicState? get engineState => _engine?.state;
  bool _current(int generation) =>
      !_disposed && generation == _generation && isActive;

  Future<bool> start(
      {required RuntimeMapBundle bundle, required BattleStartRequest request}) {
    if (_disposed || isActive) return Future.value(false);
    final completion = _completion = Completer<bool>();
    final generation = ++_generation;
    error = null;
    _base = readGameState();
    _bundle = bundle;
    phase = SpatialBattlePhase.loading;
    notifyListeners();
    unawaited(_prepare(bundle, request, generation));
    return completion.future;
  }

  Future<GameState> _hydrate(GameState state, RuntimeMapBundle bundle) async {
    final catalogs = await loadRuntimePlayerPokemonProgressionCatalogs(
        gameState: state,
        projectRootDirectory: bundle.projectRootDirectory,
        pokemonConfig: bundle.manifest.pokemon);
    return hydrateRuntimePlayerPokemonProgression(
        gameState: state,
        catalogs: catalogs,
        ruleset: bundle.manifest.pokemon.ruleset,
        defaultOrigin: PlayerPokemonHydrationOrigin.legacySave);
  }

  Future<ui.Image> _ownedImage(
      Future<ui.Image> Function() load, int generation) async {
    if (!_current(generation)) {
      throw StateError('Battle image owner was cancelled.');
    }
    final image = await load();
    if (!_current(generation)) {
      image.dispose();
      throw StateError('Battle image owner was cancelled.');
    }
    return image;
  }

  Future<void> _prepare(RuntimeMapBundle bundle, BattleStartRequest request,
      int generation) async {
    try {
      final hydrated = await _hydrate(_base!, bundle);
      if (!_current(generation)) return;
      final mapper = RuntimeBattleSetupMapper();
      if (request is WildBattleStartRequest) {
        request =
            await mapper.hydrateWildRequest(bundle: bundle, request: request);
        if (!_current(generation)) return;
      }
      final items = await const RuntimeItemCatalogLoader().loadSnapshot(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon);
      if (!_current(generation)) return;
      final lineup = mapper.selectPlayerBattleLineup(hydrated.party);
      final setup = await RuntimePsdkBattleSetupMapper().map(
          bundle: bundle,
          gameState: hydrated,
          request: request,
          playerPartyIndex: lineup.activeIndex,
          itemCatalog: items);
      if (!_current(generation)) return;
      final moves = await RuntimeMoveCatalogLoader().load(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon);
      if (!_current(generation)) return;
      _working = markSpeciesSeenInGameState(hydrated, setup.opponent.speciesId);
      _items = items;
      _engine = RuntimePsdkBattleSessionAdapter.fromSetup(setup,
          opponentAi: resolveRuntimeTrainerPsdkAi(
              request: request, manifest: bundle.manifest));
      context = RuntimeActiveBattleContext.withLineupMapping(
          request: request,
          playerPartyIndex: lineup.activeIndex,
          playerPartySlotIndicesByLineupIndex: lineup.lineupPartyIndices,
          playerIndividualId:
              hydrated.party.members[lineup.activeIndex].individualId,
          playerIndividualIdsByLineupIndex: lineup.lineupPartyIndices
              .map((slot) => hydrated.party.members[slot].individualId));
      _coordinator = RuntimePostBattleDecisionCoordinator(
          hydrateOwnedPlayerPokemon: ({required gameState, required bundle}) =>
              _hydrate(gameState, bundle));
      displaySession = _display();
      _images = BattleVisualAssetCache(
          imageLoader: (path) =>
              _ownedImage(() => loadImageFromFilePath(path), generation));
      _effects = BattleFxBundleCache(
          imageLoader: (key) => _ownedImage(() async {
                final data = await rootBundle.load(key);
                final codec = await ui.instantiateImageCodec(data.buffer
                    .asUint8List(data.offsetInBytes, data.lengthInBytes));
                try {
                  return (await codec.getNextFrame()).image;
                } finally {
                  codec.dispose();
                }
              }, generation));
      final captureSprites = RuntimeCaptureSpriteResolver(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon);
      final balls = BattleCombatantBallResolver.fromParty(
          gameState: _working!, lineupPartyIndices: lineup.lineupPartyIndices);
      battleOverlay = BattleOverlayComponent(
          session: displaySession!,
          gameState: _working!,
          viewportSize: Vector2(640, 480),
          backgroundSpec: const BattleBackgroundResolver()
              .resolve(request: request, bundle: bundle),
          spriteResolver: BattlePokemonSpriteResolver(
              manifest: bundle.manifest,
              projectRootDirectory: bundle.projectRootDirectory),
          visualAssetCache: _images,
          fxBundleCache: _effects,
          bagItemIconResolver: BattleBagItemIconResolver(
              manifest: bundle.manifest,
              projectRootDirectory: bundle.projectRootDirectory),
          itemCapabilityResolver: ItemCapabilityResolver(items),
          moveCatalog: moves,
          resolveMoveDisplayName: (id, fallback) =>
              moves.entriesById[id]?.displayName('fr') ?? fallback,
          resolveBallSpritePath: captureSprites.resolve,
          resolveCombatantBallItemId: (side, index) => balls.resolve(
              isPlayerSide: side == BattleSideId.player, lineupIndex: index),
          onPlayerChoice: (choice) => unawaited(submitChoice(choice)),
          onBagHpHealItemUseRequested: _useMedicine);
      phase = SpatialBattlePhase.battle;
      notifyListeners();
    } on Object catch (failure) {
      if (_current(generation)) _fail(failure);
    }
  }

  bool get _allowsCapture =>
      context!.request is WildBattleStartRequest &&
      playerHasAtLeastOneRuntimeCaptureItem(
          _working!.bag, ItemCapabilityResolver(_items!),
          encounterKind:
              (context!.request as WildBattleStartRequest).encounterKind);

  BattleSession _display() {
    final request = context?.request;
    return _engine!.createLegacyDisplaySession(
        isTrainerBattle: request is TrainerBattleStartRequest,
        trainerId:
            request is TrainerBattleStartRequest ? request.trainerId : null,
        allowCapture: context != null && _allowsCapture,
        allowFlee: request?.allowsPlayerFlee ?? true);
  }

  Future<bool> submitChoice(PlayerBattleChoice choice) async {
    if (phase != SpatialBattlePhase.battle ||
        isPaused ||
        _resolving ||
        _disposed) {
      return false;
    }
    if (!_engine!.allowsPlayerChoice(choice)) return false;
    _resolving = true;
    final generation = _generation;
    try {
      if (choice is PlayerBattleChoiceCapture) {
        final capture = _items!.definitionFor(choice.itemId)?.capture;
        if (capture == null) return false;
        final selectedChoice = PlayerBattleChoiceCapture(
            itemId: choice.itemId,
            rateNumerator: capture.rateNumerator,
            rateDenominator: capture.rateDenominator);
        final submission = submitRuntimeBattleCaptureAttempt(
            gameState: _working!,
            context: context!,
            captureAllowed: _engine!.allowsPlayerChoice(selectedChoice),
            itemId: choice.itemId,
            itemCatalog: _items!,
            submitToEngine: () => _engine!.submitPlayerChoice(selectedChoice));
        _working = submission.updatedGameState;
        _captureReceipt = submission.receipt;
      } else {
        _engine!.submitPlayerChoice(choice);
      }
      await _presentTurn(generation);
      return _current(generation);
    } on Object catch (failure) {
      if (_current(generation)) _fail(failure);
      return false;
    } finally {
      if (_current(generation) && phase == SpatialBattlePhase.battle) {
        _resolving = false;
      }
    }
  }

  bool _useMedicine(BattleBagMenuActionMedicineTarget action,
      BattleMedicineTargetEntry entry) {
    if (phase != SpatialBattlePhase.battle || isPaused || _resolving) {
      return false;
    }
    final request = context!.request;
    final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: _engine!,
        displaySession: displaySession!,
        gameState: _working!,
        context: context!,
        itemId: action.itemId,
        targetLineupIndex: entry.lineupIndex,
        isTrainerBattle: request is TrainerBattleStartRequest,
        trainerId:
            request is TrainerBattleStartRequest ? request.trainerId : null,
        allowCapture: _allowsCapture,
        itemCatalog: _items!);
    if (result == null) return false;
    _working = result.updatedGameState;
    _resolving = true;
    final generation = _generation;
    unawaited(_presentTurn(generation).catchError((Object failure) {
      if (_current(generation)) _fail(failure);
    }).whenComplete(() {
      if (_current(generation) && phase == SpatialBattlePhase.battle) {
        _resolving = false;
      }
    }));
    return true;
  }

  Future<void> _waitUntilResumed(int generation) async {
    while (_current(generation) && isPaused) {
      await (_resumed ??= Completer<void>()).future;
    }
  }

  Future<void> _presentTurn(int generation) async {
    displaySession = _display();
    final overlay = battleOverlay;
    if (overlay != null && overlay.isMounted) {
      overlay.updateState(displaySession!, gameState: _working!);
      await overlay.waitForTurnPresentationComplete();
    }
    await _waitUntilResumed(generation);
    if (!_current(generation) || !_engine!.state.isFinished) return;
    final result = await _coordinator!.begin(
        transactionBaseState: _working!,
        bundle: _bundle!,
        runtimeContext: context!,
        outcome: displaySession!.state.outcome!,
        itemCatalog: _items!,
        captureAttemptReceipt: _captureReceipt);
    await _waitUntilResumed(generation);
    if (!_current(generation)) return;
    if (!result.isSuccess) {
      _fail(result.failure!.cause ?? StateError(result.failure!.message));
      return;
    }
    late final PostBattleProgressionOverlayComponent post;
    post = PostBattleProgressionOverlayComponent(
        initialResult: result,
        viewportSize: overlay?.size.clone() ?? Vector2(640, 480),
        onMoveLearningDecision: (decision) => _coordinator!.resolveMoveLearning(
            transaction: post.currentTransaction!, decision: decision),
        onEvolutionDecision: (decision) => _coordinator!.resolveEvolution(
            transaction: post.currentTransaction!, decision: decision),
        onCompleted: () => unawaited(_commit(post, generation)));
    postBattleOverlay = post;
    phase = SpatialBattlePhase.postBattle;
    notifyListeners();
  }

  Future<void> _commit(
      PostBattleProgressionOverlayComponent post, int generation) async {
    if (!_current(generation) || _committing) return;
    _committing = true;
    try {
      await _waitUntilResumed(generation);
      if (!_current(generation)) return;
      var finalState = post.currentTransaction?.finalState;
      if (finalState == null || post.currentFailure != null) {
        throw StateError('Post battle decisions are incomplete.');
      }
      final outcome = displaySession!.state.outcome!;
      if (outcome.isDefeat) {
        final caps = await loadRuntimePlayerServiceRecoveryCaps(
            gameState: finalState,
            projectRootDirectory: _bundle!.projectRootDirectory,
            pokemonConfig: _bundle!.manifest.pokemon);
        await _waitUntilResumed(generation);
        if (!_current(generation)) return;
        finalState = applyPlayerDefeatRecovery(
                state: finalState,
                fallbackPoint: PlayerRecoveryPoint(
                    mapId: _base!.currentMapId,
                    position: _base!.playerPosition,
                    facing: _base!.playerFacing),
                maxHpByPartyIndex: caps.maxHpByPartyIndex,
                maxPpByPartyIndex: caps.maxPpByPartyIndex)
            .state;
      }
      if (!_current(generation)) return;
      if (!commitGameState(_base!, finalState)) {
        throw StateError('Game state changed during battle.');
      }
      commitRuntimeBattleCaptureAttemptReceipt(
          context: context!, outcome: outcome, receipt: _captureReceipt);
      await onCompleted?.call(outcome);
      if (_current(generation)) _end(true);
    } on Object catch (failure) {
      if (_current(generation)) _fail(failure);
    }
  }

  bool handleInput(RuntimeInputEvent event) {
    if (!isActive) return false;
    if (isPaused ||
        !event.isPress ||
        (event.isRepeat && event.control == RuntimeInputControl.primary)) {
      return true;
    }
    final post = postBattleOverlay;
    if (post != null) {
      switch (event.control) {
        case RuntimeInputControl.primary:
          post.validateSelectedChoice();
        case RuntimeInputControl.up:
          post.moveSelectionUp();
        case RuntimeInputControl.down:
          post.moveSelectionDown();
        case RuntimeInputControl.left:
          post.moveSelectionLeft();
        case RuntimeInputControl.right:
          post.moveSelectionRight();
        default:
          break;
      }
    } else {
      final overlay = battleOverlay;
      switch (event.control) {
        case RuntimeInputControl.primary:
          overlay?.validateSelectedChoice();
        case RuntimeInputControl.secondary:
          overlay?.handleEscape();
        case RuntimeInputControl.up:
          overlay?.moveSelectionUp();
        case RuntimeInputControl.down:
          overlay?.moveSelectionDown();
        case RuntimeInputControl.left:
          overlay?.moveSelectionLeft();
        case RuntimeInputControl.right:
          overlay?.moveSelectionRight();
        default:
          break;
      }
    }
    return true;
  }

  void pause({Object? owner}) {
    if (_disposed || !_pauseOwners.add(owner ?? _externalPause)) return;
    notifyListeners();
  }

  void resume({Object? owner}) {
    if (_disposed || !_pauseOwners.remove(owner ?? _externalPause)) return;
    if (!isPaused) {
      _resumed?.complete();
      _resumed = null;
    }
    notifyListeners();
  }

  void _fail(Object failure) {
    error = failure;
    _end(false);
    onError?.call(failure);
  }

  void reportPresentationFailure(Object failure) {
    if (!_disposed && isActive) _fail(failure);
  }

  void cancel() {
    if (_disposed) return;
    _end(false);
  }

  void _end(bool success) {
    ++_generation;
    final completion = _completion;
    _completion = null;
    _resumed?.complete();
    _resumed = null;
    phase = SpatialBattlePhase.idle;
    battleOverlay?.removeFromParent();
    postBattleOverlay?.removeFromParent();
    battleOverlay = null;
    postBattleOverlay = null;
    _images?.dispose();
    _effects?.dispose();
    _images = null;
    _effects = null;
    _engine = null;
    displaySession = null;
    context = null;
    _captureReceipt = null;
    _base = null;
    _working = null;
    _bundle = null;
    _items = null;
    _coordinator = null;
    _resolving = false;
    _committing = false;
    if (completion != null && !completion.isCompleted) {
      completion.complete(success);
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _end(false);
    _disposed = true;
    super.dispose();
  }
}
