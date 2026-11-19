import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_story/map_story.dart';

import '../player/runtime_player_feedback.dart';
import '../player/runtime_player_pause_data.dart';
import '../player/runtime_player_pause_data_builder.dart';
import '../player/runtime_world_service_models.dart';
import 'runtime_battle_combatant_seed_builder.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_move_machine_loader.dart';
import 'runtime_item_catalog_loader.dart';
import 'runtime_player_pokemon_progression_hydrator.dart';
import 'runtime_pokemon_evolution_loader.dart';
import 'runtime_pokemon_evolution_held_item_policy.dart';
import 'runtime_pokemon_species_loader.dart';
import 'scene_runtime/runtime_scene_pokemon_catalog.dart';
import '../player/runtime_pokemon_summary.dart';
import 'scene_runtime/world_presentation_image_loader.dart';

part 'runtime_party_trade_service.dart';
part 'runtime_deferred_crafting_service.dart';
part 'runtime_image_puzzle_service.dart';
part 'runtime_periodic_reward_service.dart';
part 'runtime_scene_text_input_service.dart';

enum RuntimeContextualItemUseDisposition { noMatch, reserved, refused, cancelled }

final class RuntimePlayerServiceRecoveryCaps {
  const RuntimePlayerServiceRecoveryCaps({
    required this.maxHpByPartyIndex,
    this.maxPpByPartyIndex = const <int, Map<String, int>>{},
    this.baseStatsByPartyIndex = const <int, PokemonBaseStats>{},
  });

  final Map<int, int> maxHpByPartyIndex;
  final Map<int, Map<String, int>> maxPpByPartyIndex;
  final Map<int, PokemonBaseStats> baseStatsByPartyIndex;
}

sealed class PlayerServiceRequest {
  const PlayerServiceRequest({
    required this.gameState,
    required this.recoveryCaps,
  });

  final GameState gameState;
  final RuntimePlayerServiceRecoveryCaps recoveryCaps;
}

final class PlayerServiceShopRequest extends PlayerServiceRequest {
  const PlayerServiceShopRequest({
    required super.gameState,
    required super.recoveryCaps,
    this.worldRequest,
    required this.shop,
    required this.resolvedState,
    required this.conditionContext,
    required this.itemCatalog,
  });

  final OpenShopService? worldRequest;
  final ShopDefinition shop;
  final ResolvedShopState resolvedState;
  final ScriptEvaluationContext conditionContext;
  final ItemCatalogSnapshot itemCatalog;
}

final class PlayerServicePcRequest extends PlayerServiceRequest {
  const PlayerServicePcRequest({
    required super.gameState,
    required super.recoveryCaps,
    this.worldRequest,
  });

  final OpenPcService? worldRequest;
}

final class PlayerServiceHealRequest extends PlayerServiceRequest {
  const PlayerServiceHealRequest({
    required super.gameState,
    required super.recoveryCaps,
    this.worldRequest,
  });

  final OpenHealService? worldRequest;
}

final class PlayerServiceHostResult {
  const PlayerServiceHostResult.completed(this.gameState) : cancelled = false;

  const PlayerServiceHostResult.cancelled()
      : gameState = null,
        cancelled = true;

  final GameState? gameState;
  final bool cancelled;
}

abstract interface class PlayerServiceOverlayHost {
  Future<PlayerServiceHostResult> openShop(PlayerServiceShopRequest request);

  Future<PlayerServiceHostResult> openPc(PlayerServicePcRequest request);

  Future<PlayerServiceHostResult> openHealCenter(
    PlayerServiceHealRequest request,
  );
}

enum PlayerServiceRuntimeStatus {
  completed,
  cancelled,
  unavailable,
  busy,
  failed,
}

final class PlayerServiceRuntimeResult {
  const PlayerServiceRuntimeResult._({
    required this.status,
    this.gameState,
    this.error,
    this.safeMessage,
    this.imagePuzzleOutcome,
  });

  const PlayerServiceRuntimeResult.completed(GameState gameState)
      : this._(
          status: PlayerServiceRuntimeStatus.completed,
          gameState: gameState,
        );

  const PlayerServiceRuntimeResult.imagePuzzle(GameState state, ImagePuzzleOutcome outcome)
      : this._(status: PlayerServiceRuntimeStatus.completed, gameState: state, imagePuzzleOutcome: outcome);

  const PlayerServiceRuntimeResult.cancelled()
      : this._(status: PlayerServiceRuntimeStatus.cancelled);

  const PlayerServiceRuntimeResult.unavailable(String safeMessage)
      : this._(
          status: PlayerServiceRuntimeStatus.unavailable,
          safeMessage: safeMessage,
        );

  const PlayerServiceRuntimeResult.busy()
      : this._(status: PlayerServiceRuntimeStatus.busy);

  const PlayerServiceRuntimeResult.failed(Object error)
      : this._(status: PlayerServiceRuntimeStatus.failed, error: error);

  final ImagePuzzleOutcome? imagePuzzleOutcome;
  final PlayerServiceRuntimeStatus status;
  final GameState? gameState;
  final Object? error;
  final String? safeMessage;
}

const nativeHealingDisplayDuration = Duration(milliseconds: 2900);

typedef PlayerServiceHealingDisplayMapReader = MapData? Function(String mapId);
typedef PlayerServiceHealingDisplayWaiter = Future<void> Function(Duration duration);

Future<void> _defaultHealingDisplayWaiter(Duration duration) => Future<void>.delayed(duration);

typedef PlayerServiceGameStateReader = GameState Function();
typedef PlayerServiceStateTransaction = Future<void> Function(GameState state);
typedef PlayerServiceInputLockSetter = void Function(bool locked);
typedef PlayerServiceRecoveryCapsLoader
    = Future<RuntimePlayerServiceRecoveryCaps> Function(GameState state);

/// Coordinates one player-service overlay at a time without knowing Flutter.
///
/// The host owns presentation. This controller owns ordering, input release and
/// the single commit-and-save transaction after a successful close.
final class PlayerServiceRuntimeController implements RuntimeWorldServicePort {
  PlayerServiceRuntimeController({
    required PlayerServiceGameStateReader currentGameState,
    required PlayerServiceOverlayHost host,
    required PlayerServiceStateTransaction commitAndSave,
    PlayerServiceStateTransaction? commitCraftingAndSave,
    PlayerServiceStateTransaction? commitImagePuzzleAndSave,
    PlayerServiceStateTransaction? commitPeriodicRewardAndSave,
    Future<RuntimeImagePuzzleBitmap> Function(String)? loadImagePuzzleBitmap,
    required PlayerServiceInputLockSetter setInputLocked,
    required PlayerServiceRecoveryCapsLoader loadRecoveryCaps,
    this._healingDisplayMapReader,
    this._waitForHealingDisplay = _defaultHealingDisplayWaiter,
    ScriptEvaluationContext conditionContext = const ScriptEvaluationContext(),
    Set<String> grantedCapabilities = const <String>{},
    String? projectRootDirectory,
    ProjectPokemonConfig? pokemonConfig,
    RuntimePokemonEvolutionLoader? evolutionLoader,
    RuntimeMoveMachineLoader? moveMachineLoader,
    RuntimePokemonSpeciesLoader? pokemonSpeciesLoader,
    ItemCatalogSnapshot? itemCatalog,
    this.bagCapacity = const ProjectBagCapacity.unlimited(),
    RuntimeItemCatalogLoader itemCatalogLoader =
        const RuntimeItemCatalogLoader(),
    String locale = 'fr-FR',
    String Function()? displayLocale,
    RuntimePlayerFeedbackLocalizer? feedbackLocalizer,
    this.supportsRepel = false,
    DateTime Function()? civilNow,
  })  : _civilNow = civilNow ?? DateTime.now,
        _displayLocaleReader = displayLocale ?? (() => locale),
        _feedbackLocalizer = feedbackLocalizer,
        _currentGameState = currentGameState,
        _host = host,
        _commitAndSave = commitAndSave,
        _commitCraftingAndSave = commitCraftingAndSave,
        _commitImagePuzzleAndSave = commitImagePuzzleAndSave,
        _commitPeriodicRewardAndSave = commitPeriodicRewardAndSave,
        _loadImagePuzzleBitmap = loadImagePuzzleBitmap,
        _setInputLocked = setInputLocked,
        _loadRecoveryCaps = loadRecoveryCaps,
        _conditionContext = conditionContext,
        _grantedCapabilities = Set<String>.unmodifiable(grantedCapabilities),
        _projectRootDirectory = projectRootDirectory,
        _pokemonConfig = pokemonConfig,
        _itemCatalog = itemCatalog,
        _itemCatalogLoader = itemCatalogLoader,
        _evolutionLoader = evolutionLoader ?? RuntimePokemonEvolutionLoader(),
        _moveMachineLoader = moveMachineLoader ?? RuntimeMoveMachineLoader(),
        _pokemonSpeciesLoader =
            pokemonSpeciesLoader ?? RuntimePokemonSpeciesLoader();

  PlayerServiceRuntimeController.contextual({
    required PlayerServiceGameStateReader currentGameState,
    required PlayerServiceStateTransaction commitAndSave,
    PlayerServiceStateTransaction? commitCraftingAndSave,
    PlayerServiceStateTransaction? commitImagePuzzleAndSave,
    PlayerServiceStateTransaction? commitPeriodicRewardAndSave,
    Future<RuntimeImagePuzzleBitmap> Function(String)? loadImagePuzzleBitmap,
    required PlayerServiceInputLockSetter setInputLocked,
    required PlayerServiceRecoveryCapsLoader loadRecoveryCaps,
    this._healingDisplayMapReader,
    this._waitForHealingDisplay = _defaultHealingDisplayWaiter,
    ScriptEvaluationContext conditionContext = const ScriptEvaluationContext(),
    Set<String> grantedCapabilities = const <String>{},
    String? projectRootDirectory,
    ProjectPokemonConfig? pokemonConfig,
    RuntimePokemonEvolutionLoader? evolutionLoader,
    RuntimeMoveMachineLoader? moveMachineLoader,
    RuntimePokemonSpeciesLoader? pokemonSpeciesLoader,
    ItemCatalogSnapshot? itemCatalog,
    this.bagCapacity = const ProjectBagCapacity.unlimited(),
    RuntimeItemCatalogLoader itemCatalogLoader =
        const RuntimeItemCatalogLoader(),
    String locale = 'fr-FR',
    String Function()? displayLocale,
    RuntimePlayerFeedbackLocalizer? feedbackLocalizer,
    this.supportsRepel = false,
    DateTime Function()? civilNow,
  })  : _civilNow = civilNow ?? DateTime.now,
        _displayLocaleReader = displayLocale ?? (() => locale),
        _feedbackLocalizer = feedbackLocalizer,
        _currentGameState = currentGameState,
        _host = null,
        _commitAndSave = commitAndSave,
        _commitCraftingAndSave = commitCraftingAndSave,
        _commitImagePuzzleAndSave = commitImagePuzzleAndSave,
        _commitPeriodicRewardAndSave = commitPeriodicRewardAndSave,
        _loadImagePuzzleBitmap = loadImagePuzzleBitmap,
        _setInputLocked = setInputLocked,
        _loadRecoveryCaps = loadRecoveryCaps,
        _conditionContext = conditionContext,
        _grantedCapabilities = Set<String>.unmodifiable(grantedCapabilities),
        _projectRootDirectory = projectRootDirectory,
        _pokemonConfig = pokemonConfig,
        _itemCatalog = itemCatalog,
        _itemCatalogLoader = itemCatalogLoader,
        _evolutionLoader = evolutionLoader ?? RuntimePokemonEvolutionLoader(),
        _moveMachineLoader = moveMachineLoader ?? RuntimeMoveMachineLoader(),
        _pokemonSpeciesLoader =
            pokemonSpeciesLoader ?? RuntimePokemonSpeciesLoader();

  final PlayerServiceGameStateReader _currentGameState;
  final PlayerServiceOverlayHost? _host;
  final PlayerServiceStateTransaction _commitAndSave;
  final PlayerServiceStateTransaction? _commitCraftingAndSave;
  final PlayerServiceStateTransaction? _commitImagePuzzleAndSave;
  final PlayerServiceStateTransaction? _commitPeriodicRewardAndSave;
  Future<void>? _periodicRewardCommit;
  final Future<RuntimeImagePuzzleBitmap> Function(String)? _loadImagePuzzleBitmap;
  _RuntimeImagePuzzleSession? _imagePuzzleSession;
  var _imagePuzzleRevision = -1;
  String? Function()? _pauseMutationUnavailableReason;
  Future<bool> Function(ProjectItemDefinition, GameState)? _escapeRopeConsumer;
  FutureOr<RuntimeContextualItemUseDisposition> Function(ProjectItemDefinition, GameState)? _contextualItemUseConsumer;

  void setContextualItemUseConsumer(
    FutureOr<RuntimeContextualItemUseDisposition> Function(ProjectItemDefinition, GameState) consumer,
  ) {
    _contextualItemUseConsumer = consumer;
  }
  bool _escapeRopeResumesGameplay = false;

  FutureOr<FishingBlockReason?> Function(ProjectItemDefinition, GameState)? _fishingConsumer;

  void setFishingConsumer(
    FutureOr<FishingBlockReason?> Function(ProjectItemDefinition, GameState) consumer,
  ) {
    _fishingConsumer = consumer;
  }

  Future<bool> Function(ProjectItemDefinition, GameState)? _bicycleConsumer;

  void setBicycleConsumer(
    Future<bool> Function(ProjectItemDefinition, GameState) consumer,
  ) {
    _bicycleConsumer = consumer;
  }

  Future<RuntimePlayerPauseCommandResult> useBicycleShortcut() async {
    final catalog = await _resolveItemCatalog();
    final state = _currentGameState();
    final item = catalog.catalog.entries.where((item) =>
        isBicycleItem(item) &&
        state.bag.entries.any((entry) => entry.itemId == item.id && entry.quantity > 0))
        .firstOrNull;
    if (item == null) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.bicycleMissing));
    }
    return useBagItemOutsideBattle(
      RuntimePlayerPauseCommand.useBagItem(itemTargetId: item.id));
  }

  void setEscapeRopeConsumer(
    Future<bool> Function(ProjectItemDefinition, GameState) consumer, {
    bool resumeGameplayOnSuccess = false,
  }) {
    _escapeRopeConsumer = consumer;
    _escapeRopeResumesGameplay = resumeGameplayOnSuccess;
  }

  final PlayerServiceInputLockSetter _setInputLocked;
  final PlayerServiceRecoveryCapsLoader _loadRecoveryCaps;
  final PlayerServiceHealingDisplayMapReader? _healingDisplayMapReader;
  final PlayerServiceHealingDisplayWaiter _waitForHealingDisplay;
  final ScriptEvaluationContext _conditionContext;
  final Set<String> _grantedCapabilities;
  final String? _projectRootDirectory;
  final ProjectPokemonConfig? _pokemonConfig;
  ItemCatalogSnapshot? _itemCatalog;
  final ProjectBagCapacity bagCapacity;
  final RuntimeItemCatalogLoader _itemCatalogLoader;
  final RuntimePokemonEvolutionLoader _evolutionLoader;
  final RuntimeMoveMachineLoader _moveMachineLoader;
  final RuntimePokemonSpeciesLoader _pokemonSpeciesLoader;
  final DateTime Function() _civilNow;
  _ContextualCraftingSession? _craftingSession;
  var _craftingRevision = -1;
  final String Function() _displayLocaleReader;
  String get _displayLocale => _displayLocaleReader();
  final RuntimePlayerFeedbackLocalizer? _feedbackLocalizer;

  String _feedback(
    RuntimeServiceFeedback feedback, [
    Map<String, Object> arguments = const {},
  ]) => feedback.resolve(_feedbackLocalizer, _displayLocale, arguments);
  final bool supportsRepel;
  final _worldServiceSnapshots =
      StreamController<RuntimeWorldServiceSnapshot?>.broadcast();
  bool _active = false;
  bool _pauseBagMutationBusy = false;
  bool _disposed = false;
  RuntimeWorldServiceSnapshot? _worldServiceSnapshot;
  _ContextualShopSession? _shopSession;
  _ContextualHealSession? _healSession;
  _ContextualPcSession? _pcSession;
  _ContextualRegionalMapSession? _regionalMapSession;
  var _regionalMapRevision = -1;
  _ContextualPartyTradeSession? _partyTradeSession;
  var _partyTradeRevision = -1;
  _ContextualTextSession? _textSession;
  HeadlessSceneInteractionPort? _sceneTextPort;
  var _textRevision = -1;
  var _giftRevision = -1;
  _ContextualPokemonGiftSession? _giftSession;

  Future<SceneInteractionResult> openPokemonGiftInteraction({
    required OpenPokemonGiftInteractionService request,
  }) async {
    if (_disposed || _active) {
      throw StateError('The Pokemon gift modal is unavailable.');
    }
    _active = true;
    final session = _ContextualPokemonGiftSession(request);
    _giftSession = session;
    var locked = false;
    try {
      _setInputLocked(true);
      locked = true;
      var presented = request;
      final root = _projectRootDirectory;
      final config = _pokemonConfig;
      if (root != null && config != null) {
        final species = await _pokemonSpeciesLoader.loadById(
          projectRootDirectory: root,
          pokemonConfig: config,
          speciesId: request.pokemon.speciesId,
        );
        final displayLocale = _displayLocale;
        final detail = request.isNewPokedexEntry ||
                request.stage == PokemonGiftInteractionStage.pokedex
            ? await const RuntimePlayerPauseDataBuilder()
                  .buildPokemonGiftPokedexEntry(
                    gameState: request.projectedState,
                    speciesId: request.pokemon.speciesId,
                    projectRootDirectory: root,
                    pokemonConfig: config,
                    locale: displayLocale,
                  )
            : null;
        presented = OpenPokemonGiftInteractionService(
          interactionId: request.interactionId,
          interaction: request.interaction,
          stage: request.stage,
          pokemon: request.pokemon,
          projectedState: request.projectedState,
          pokedexDetail: detail,
          speciesName: species.displayName(displayLocale),
          isNewPokedexEntry: request.isNewPokedexEntry,
        );
      } else if ((request.isNewPokedexEntry ||
              request.stage == PokemonGiftInteractionStage.pokedex) &&
          request.pokedexDetail == null) {
        throw StateError(
          'The native Pokedex gift entry requires the project catalog.',
        );
      }
      if (_disposed || !identical(_giftSession, session)) {
        throw StateError('The Pokemon gift modal was disposed.');
      }
      _giftRevision =
          ((_worldServiceSnapshot?.revision ?? -1) > _giftRevision
              ? _worldServiceSnapshot!.revision
              : _giftRevision) +
          1;
      _publishWorldService(
        RuntimeWorldServiceSnapshot(
          revision: _giftRevision,
          request: presented,
          stage: RuntimeWorldServiceStage.active,
          content: presented.interaction,
          actions: const [
            RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.confirm,
            ),
            RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.cancel,
            ),
          ],
        ),
      );
      return await session.result.future;
    } finally {
      if (identical(_giftSession, session)) {
        _giftSession = null;
        _publishWorldService(null);
      }
      if (locked) _setInputLocked(false);
      _active = false;
    }
  }

  RuntimeWorldServiceCommandResult _dispatchPokemonGift(
    _ContextualPokemonGiftSession session,
    RuntimeWorldServiceCommand command,
  ) {
    if (session.result.isCompleted) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
      );
    }
    final request = session.request.interaction;
    final result =
        command.interactionResult ??
        (command.action == RuntimeWorldServiceAction.cancel
            ? SceneInteractionResult.cancelled(
                requestId: request.requestId,
                revision: request.revision,
                reason: SceneInteractionCancellationReason.user,
              )
            : null);
    if (result == null || request.validateResult(result).isNotEmpty) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
      );
    }
    session.result.complete(result);
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  bool get isActive => _active;
  bool get supportsBicycle => _bicycleConsumer != null;
  bool get supportsFishing => _fishingConsumer != null;

  ProjectItemDefinition? currentItemDefinition(String itemId) =>
      _disposed ? null : _itemCatalog?.definitionFor(itemId);
  bool get supportsEscapeRope => _escapeRopeConsumer != null;

  @override
  RuntimeWorldServiceSnapshot? get worldServiceSnapshot =>
      _worldServiceSnapshot;

  @override
  Stream<RuntimeWorldServiceSnapshot?> get worldServiceSnapshots =>
      _worldServiceSnapshots.stream;

  void refreshPokemonDisplayNames() {
    final snapshot = _worldServiceSnapshot;
    if (snapshot == null ||
        snapshot.stage == RuntimeWorldServiceStage.opening ||
        snapshot.stage == RuntimeWorldServiceStage.applying) {
      return;
    }
    if (_pcSession case final session?) {
      _publishWorldService(
        _buildPcSnapshot(
          session,
          stage: snapshot.stage,
          safeMessage: snapshot.safeMessage,
        ),
      );
    } else if (_healSession case final session?) {
      _publishWorldService(
        _buildHealSnapshot(
          session,
          stage: snapshot.stage,
        ),
      );
    } else if (_partyTradeSession case final session?) {
      _publishPartyTrade(session);
    }
  }

  Future<PlayerServiceRuntimeResult> openTextInput({
    required OpenTextInputService request,
  }) async {
    if (_disposed) {
      return PlayerServiceRuntimeResult.failed(
        StateError('The player-service controller is disposed.'),
      );
    }
    if (_active) return const PlayerServiceRuntimeResult.busy();
    final state = _currentGameState();
    final unavailableReason = _worldRequestUnavailableReason(request, state);
    if (unavailableReason != null) {
      return PlayerServiceRuntimeResult.unavailable(unavailableReason);
    }
    final currentValue = state.scriptVariables.values[request.variableId];
    if (currentValue != null && currentValue is! ScriptVariableValueString) {
      return PlayerServiceRuntimeResult.unavailable(
        _feedback(.textVariableInvalid),
      );
    }
    _active = true;
    var inputLocked = false;
    final session = _ContextualTextSession(request: request);
    try {
      _setInputLocked(true);
      inputLocked = true;
      _textSession = session;
      _publishWorldService(_buildTextSnapshot(session));
      if (request.interaction.timeout case final timeout?) {
        session.timer = Timer(timeout, () {
          if (!session.result.isCompleted) {
            session.result.complete(
              const PlayerServiceRuntimeResult.cancelled(),
            );
          }
        });
      }
      return await session.result.future;
    } catch (error) {
      return PlayerServiceRuntimeResult.failed(error);
    } finally {
      session.timer?.cancel();
      if (identical(_textSession, session)) {
        _textSession = null;
        _publishWorldService(null);
      }
      if (inputLocked) _setInputLocked(false);
      _active = false;
    }
  }

  Future<SceneInteractionResult> openSceneTextInteraction({required OpenSceneTextInteractionService request}) =>
      _openSceneTextInteraction(this, request);

  RuntimeWorldServiceSnapshot _buildTextSnapshot(
    _ContextualTextSession session, {
    RuntimeWorldServiceStage stage = RuntimeWorldServiceStage.active,
    String? safeMessage,
  }) {
    final previousRevision = _worldServiceSnapshot?.revision ?? -1;
    _textRevision =
        (previousRevision > _textRevision ? previousRevision : _textRevision) +
            1;
    final revision = _textRevision;
    final source = session.request.interaction;
    session.interaction = SceneTextInteractionRequest(
      requestId: source.requestId,
      revision: revision,
      prompt: source.prompt,
      constraints: source.constraints,
      initialValue: session.value ?? source.initialValue,
      timeout: source.timeout,
    );
    return RuntimeWorldServiceSnapshot(
      revision: revision,
      request: session.request,
      stage: stage,
      content: session.interaction,
      safeMessage: safeMessage,
      actions: stage == RuntimeWorldServiceStage.applying
          ? const []
          : const [
              RuntimeWorldServiceActionAvailability.enabled(
                RuntimeWorldServiceAction.confirm,
              ),
              RuntimeWorldServiceActionAvailability.enabled(
                RuntimeWorldServiceAction.cancel,
              ),
            ],
    );
  }

  Future<RuntimeWorldServiceCommandResult> _dispatchText(
    _ContextualTextSession session,
    RuntimeWorldServiceCommand command,
  ) async {
    if (session.result.isCompleted) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
        safeMessage: _feedback(.requestClosed),
      );
    }
    final interaction = session.interaction!;
    final result = command.interactionResult;
    if (result != null &&
        (result.requestId != interaction.requestId ||
            result.revision != interaction.revision)) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
        safeMessage: _feedback(.requestChanged),
      );
    }
    if (command.action == RuntimeWorldServiceAction.cancel ||
        command.action == RuntimeWorldServiceAction.close) {
      session.result.complete(const PlayerServiceRuntimeResult.cancelled());
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.cancelled,
      );
    }
    if (result == null || result is! SceneTextSubmittedInteractionResult) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: _feedback(.responseNotText),
      );
    }
    if (interaction.validateResult(result).isNotEmpty) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: _feedback(.responseLengthInvalid),
      );
    }
    session.value = result.value;
    session.timer?.cancel();
    _publishWorldService(
      _buildTextSnapshot(session, stage: RuntimeWorldServiceStage.applying),
    );
    try {
      final currentState = _currentGameState();
      final currentValue =
          currentState.scriptVariables.values[session.request.variableId];
      if (currentValue != null && currentValue is! ScriptVariableValueString) {
        throw StateError('The text variable type changed during the request.');
      }
      final next = const GameStateMutations().setVariable(
        currentState,
        session.request.variableId,
        ScriptVariableValue.string(result.value),
      );
      await _commitAndSave(next);
      if (_disposed || !identical(_textSession, session)) {
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.cancelled,
        );
      }
      session.result.complete(PlayerServiceRuntimeResult.completed(next));
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.accepted,
      );
    } catch (error) {
      if (!_disposed && identical(_textSession, session)) {
        _publishWorldService(
          _buildTextSnapshot(
            session,
            stage: RuntimeWorldServiceStage.failed,
            safeMessage: _feedback(.textSaveFailed),
          ),
        );
      }
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.failed,
        safeMessage: _feedback(.textSaveFailed),
      );
    }
  }

  Future<PlayerServiceRuntimeResult> openShop(
    ShopDefinition shop, {
    OpenShopService? request,
  }) {
    final worldRequest = request ??
        OpenShopService(
          interactionId: 'runtime.shop:${shop.id}',
          shopId: shop.id,
        );
    if (worldRequest.shopId != shop.id) {
      return Future<PlayerServiceRuntimeResult>.value(
        PlayerServiceRuntimeResult.failed(
          ArgumentError(
            'The world-service shop id does not match the resolved shop.',
          ),
        ),
      );
    }
    return _run(
      worldRequest,
      (state, caps) async {
        final normalizedShop = shop.normalized();
        final resolvedState = const ShopStateResolver().resolve(
          shop: normalizedShop,
          gameState: state,
          conditionContext: _conditionContext,
        );
        final itemCatalog = await _resolveItemCatalog();
        final serviceRequest = PlayerServiceShopRequest(
          gameState: state,
          recoveryCaps: caps,
          worldRequest: worldRequest,
          shop: normalizedShop,
          resolvedState: resolvedState,
          conditionContext: _conditionContext,
          itemCatalog: itemCatalog,
        );
        final host = _host;
        return host == null
            ? _openContextualShop(serviceRequest)
            : host.openShop(serviceRequest);
      },
    );
  }

  Future<PlayerServiceRuntimeResult> openRegionalMap({
    required OpenRegionalMapService request,
    required RuntimePlayerPauseDetailSnapshot detail,
    Future<({FlyActionTicket? ticket, FlyBlockReason? reason})> Function(
      String pointId,
    )?
    prepareFly,
    Future<bool> Function(FlyActionTicket ticket)? applyFly,
  }) async {
    if (_disposed) {
      return PlayerServiceRuntimeResult.failed(
        StateError('The player-service controller is disposed.'),
      );
    }
    if (_active) return const PlayerServiceRuntimeResult.busy();
    final reason = _worldRequestUnavailableReason(request, _currentGameState());
    if (reason != null) return PlayerServiceRuntimeResult.unavailable(reason);
    if (detail.section != RuntimePlayerPauseSection.map ||
        (detail.regionalMap?.regions.isEmpty ?? true)) {
      return PlayerServiceRuntimeResult.unavailable(
        _feedback(.regionalMapUnavailable),
      );
    }
    final session = _ContextualRegionalMapSession(
      request: request,
      detail: detail,
      prepareFly: prepareFly,
      applyFly: applyFly,
    );
    _regionalMapSession = session;
    _active = true;
    var inputLocked = false;
    try {
      _setInputLocked(true);
      inputLocked = true;
      _publishRegionalMap(session);
      return await session.result.future;
    } catch (error) {
      return PlayerServiceRuntimeResult.failed(error);
    } finally {
      if (identical(_regionalMapSession, session)) _regionalMapSession = null;
      _publishWorldService(null);
      if (inputLocked) _setInputLocked(false);
      _active = false;
    }
  }

  void _publishRegionalMap(_ContextualRegionalMapSession session) {
    _publishWorldService(
      RuntimeWorldServiceSnapshot(
        revision: ++_regionalMapRevision,
        request: session.request,
        stage: session.applying
            ? RuntimeWorldServiceStage.applying
            : RuntimeWorldServiceStage.active,
        content: RuntimeRegionalMapServiceContent(
          detail: session.detail,
          selectedPointId: session.ticket?.evaluation.pointId,
          message: session.message,
          applying: session.applying,
        ),
        actions: [
          if (!session.applying) ...[
            const RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.close,
            ),
            const RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.cancel,
            ),
            if (session.prepareFly != null && session.applyFly != null)
              const RuntimeWorldServiceActionAvailability.enabled(
                RuntimeWorldServiceAction.select,
              ),
            if (session.ticket != null)
              const RuntimeWorldServiceActionAvailability.enabled(
                RuntimeWorldServiceAction.confirm,
              ),
          ],
        ],
      ),
    );
  }

  String _flyUnavailableMessage(FlyBlockReason? reason) => switch (reason) {
    FlyBlockReason.disabled => _feedback(.flyDisabled),
    FlyBlockReason.underwater =>
      _feedback(.flyUnderwater),
    FlyBlockReason.indoor =>
      _feedback(.flyIndoors),
    FlyBlockReason.notVisited => _feedback(.flyDestinationUnvisited),
    FlyBlockReason.missingMove =>
      _feedback(.flyPokemonRequired),
    FlyBlockReason.locked =>
      _feedback(.flyLocked),
    FlyBlockReason.unsupportedMap =>
      _feedback(.flyMapUnsupported),
    FlyBlockReason.invalidSpawn =>
      _feedback(.flyArrivalUnavailable),
    FlyBlockReason.invalidDestination ||
    null => _feedback(.flyDestinationUnavailable),
  };

  Future<RuntimeWorldServiceCommandResult> _dispatchRegionalMap(
    _ContextualRegionalMapSession session,
    RuntimeWorldServiceCommand command,
  ) async {
    if (session.result.isCompleted || session.applying) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
      );
    }
    if (command.action == RuntimeWorldServiceAction.select) {
      final id = command.targetId;
      final point = session.detail.regionalMap!.regions
          .expand((region) => region.points)
          .where((point) => point.id == id)
          .firstOrNull;
      if (id != null && point == null) {
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
        );
      }
      session.ticket = null;
      session.message = null;
      _publishRegionalMap(session);
      if (id == null) {
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.accepted,
        );
      }
      final revision = _worldServiceSnapshot!.revision;
      FlyActionTicket? ticket;
      FlyBlockReason? reason;
      try {
        final preparation = await session.prepareFly!(id);
        ticket = preparation.ticket;
        reason = preparation.reason;
      } on Object {
        session.message = _feedback(.flyDestinationUnavailable);
      }
      if (_disposed ||
          !identical(_regionalMapSession, session) ||
          session.result.isCompleted ||
          _worldServiceSnapshot?.revision != revision) {
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.stale,
        );
      }
      session.ticket = ticket;
      session.message = ticket == null
          ? _flyUnavailableMessage(reason)
          : _feedback(.flyConfirm, {'place': point!.label});
      _publishRegionalMap(session);
      return RuntimeWorldServiceCommandResult(
        status: ticket == null
            ? RuntimeWorldServiceCommandStatus.unavailable
            : RuntimeWorldServiceCommandStatus.accepted,
        safeMessage: ticket == null ? session.message : null,
      );
    }
    if (command.action == RuntimeWorldServiceAction.cancel &&
        session.ticket != null) {
      session.ticket = null;
      session.message = null;
      _publishRegionalMap(session);
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.accepted,
      );
    }
    if (command.action == RuntimeWorldServiceAction.confirm &&
        session.ticket != null) {
      final ticket = session.ticket!;
      session.ticket = null;
      session.applying = true;
      _publishRegionalMap(session);
      var applied = false;
      var failed = false;
      try {
        applied = await session.applyFly!(ticket);
      } on Object {
        failed = true;
      }
      if (_disposed ||
          !identical(_regionalMapSession, session) ||
          session.result.isCompleted) {
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.cancelled,
        );
      }
      if (applied) {
        session.result.complete(
          PlayerServiceRuntimeResult.completed(_currentGameState()),
        );
      } else {
        session.applying = false;
        session.message = failed
            ? _feedback(.flyRecoveryFailed)
            : _feedback(.flyCancelled);
        _publishRegionalMap(session);
      }
      return RuntimeWorldServiceCommandResult(
        status: applied
            ? RuntimeWorldServiceCommandStatus.accepted
            : RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: applied ? null : session.message,
      );
    }
    session.result.complete(
      command.action == RuntimeWorldServiceAction.cancel
          ? const PlayerServiceRuntimeResult.cancelled()
          : PlayerServiceRuntimeResult.completed(_currentGameState()),
    );
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }
  Future<PlayerServiceRuntimeResult> openPc({
    OpenPcService? request,
  }) {
    final worldRequest =
        request ?? const OpenPcService(interactionId: 'runtime.pc:default');
    if (_host == null) {
      return _runContextualPc(worldRequest);
    }
    return _run(
      worldRequest,
      (state, caps) {
        return _host!.openPc(
          PlayerServicePcRequest(
            gameState: state,
            recoveryCaps: caps,
            worldRequest: worldRequest,
          ),
        );
      },
    );
  }

  Future<PlayerServiceRuntimeResult> _runContextualPc(
    OpenPcService request,
  ) async {
    if (_disposed) {
      return PlayerServiceRuntimeResult.failed(
        StateError('The player-service controller is disposed.'),
      );
    }
    if (_active) return const PlayerServiceRuntimeResult.busy();
    final currentState = _currentGameState();
    final state = currentState.copyWith(
      pokemonStorage: currentState.pokemonStorage.normalized(),
    );
    final unavailableReason = _worldRequestUnavailableReason(request, state);
    if (unavailableReason != null) {
      return PlayerServiceRuntimeResult.unavailable(unavailableReason);
    }
    _active = true;
    var inputLocked = false;
    try {
      _setInputLocked(true);
      inputLocked = true;
      final boxes = state.pokemonStorage.boxes;
      final preferredBoxId = request.storageId;
      final selectedBoxId =
          preferredBoxId != null && boxes.any((box) => box.id == preferredBoxId)
              ? preferredBoxId
              : boxes.first.id;
      final session = _ContextualPcSession(
        request: request,
        gameState: state,
        selectedBoxId: selectedBoxId,
        summaryBuilderFor: await _loadPokemonSummaryBuilderFor(state),
      );
      _pcSession = session;
      _publishWorldService(_buildPcSnapshot(session));
      return await session.result.future;
    } catch (error) {
      return PlayerServiceRuntimeResult.failed(error);
    } finally {
      _pcSession = null;
      _publishWorldService(null);
      if (inputLocked) _setInputLocked(false);
      _active = false;
    }
  }

  Future<PlayerServiceRuntimeResult> openHealCenter({
    OpenHealService? request,
  }) {
    final worldRequest =
        request ?? const OpenHealService(interactionId: 'runtime.heal:default');
    if (_host == null) {
      return _runContextualHeal(worldRequest);
    }
    return _run(
      worldRequest,
      (state, caps) {
        return _host!.openHealCenter(
          PlayerServiceHealRequest(
            gameState: state,
            recoveryCaps: caps,
            worldRequest: worldRequest,
          ),
        );
      },
    );
  }

  /// Réordonnancement et changement de lead — BETA-PTY-002.
  ///
  /// Les opérations pures existaient (swapPartyMembers, setLead, et leurs
  /// variantes par individualId) sans aucun appelant : le joueur ne pouvait ni
  /// réordonner ni changer de lead. Même contrat que le sac : validation des
  /// cibles, opération par INDIVIDUALID quand l'équipe en porte (la sélection
  /// suit l'individu, pas la position), commit-et-sauvegarde, message sûr.
  Future<RuntimePlayerPauseCommandResult> reorderPartyOutsideBattle(
    RuntimePlayerPauseCommand command,
  ) async {
    if (_disposed || _active) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.partyBusy),
      );
    }
    final state = _currentGameState();
    final firstIndex = _partyIndexFromTarget(state, command.partyTargetId);
    if (firstIndex == null) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.targetUnavailable),
      );
    }
    const operations = PlayerStorageOperations();
    final PlayerStorageOperationResult result;
    final String successMessage;
    switch (command.kind) {
      case RuntimePlayerPauseCommandKind.setPartyLead:
        // Le ciblage stable vient de la RÉSOLUTION des cibles : _partyIndexFromTarget
        // traduit `pokemon.<individualId>` en index frais sur l'état courant.
        // Opérer ensuite par variante ByIndividualId re-résoudrait le même id
        // dans le même état — mesuré par sabotage, strictement équivalent.
        result = operations.setLead(state: state, partyIndex: firstIndex);
        successMessage = _feedback(.partyLeadSaved);
      case RuntimePlayerPauseCommandKind.reorderPartyMember:
        final secondTarget = command.secondPartyTargetId;
        final secondIndex = secondTarget == null
            ? null
            : _partyIndexFromTarget(state, secondTarget);
        if (secondIndex == null) {
          return RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: _feedback(.targetUnavailable),
          );
        }
        result = operations.swapPartyMembers(
          state: state,
          firstIndex: firstIndex,
          secondIndex: secondIndex,
        );
        successMessage = _feedback(.partyReorderSaved);
      case RuntimePlayerPauseCommandKind.useBagItem:
      case RuntimePlayerPauseCommandKind.callContact:
      case RuntimePlayerPauseCommandKind.equipHeldItem:
      case RuntimePlayerPauseCommandKind.unequipHeldItem:
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.partyCommandInvalid),
        );
    }
    if (!result.isSuccess) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.targetUnavailable),
      );
    }
    try {
      await _commitAndSave(result.state);
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.accepted,
        safeMessage: successMessage,
      );
    } catch (_) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: _feedback(.partyReorderFailed),
      );
    }
  }

  void setPauseMutationGuard(String? Function() unavailableReason) {
    _pauseMutationUnavailableReason = unavailableReason;
  }

  RuntimePlayerPauseCommandResult? _pauseMutationRefusal() {
    final reason = _pauseMutationUnavailableReason?.call();
    return reason == null
        ? null
        : RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: reason,
          );
  }

  Future<RuntimePlayerPauseCommandResult?> _commitPauseMutation(
    GameState state,
  ) async {
    final refusal = _pauseMutationRefusal();
    if (refusal != null) return refusal;
    await _commitAndSave(state);
    return null;
  }

  Future<RuntimePlayerPauseCommandResult> useBagItemOutsideBattle(
    RuntimePlayerPauseCommand command,
  ) async {
    if (_pauseBagMutationBusy) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.bagBusy),
      );
    }
    _pauseBagMutationBusy = true;
    try {
      return await _useBagItemOutsideBattle(command);
    } finally {
      _pauseBagMutationBusy = false;
    }
  }

  Future<RuntimePlayerPauseCommandResult> _useBagItemOutsideBattle(
    RuntimePlayerPauseCommand command,
  ) async {
    if (_disposed || _active) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.bagBusy),
      );
    }
    final refusal = _pauseMutationRefusal();
    if (refusal != null) return refusal;
    final state = _currentGameState();
    final partyIndex = _partyIndexFromTarget(state, command.partyTargetId);
    if (command.kind == RuntimePlayerPauseCommandKind.unequipHeldItem &&
        partyIndex != null) {
      final itemCatalog = await _resolveItemCatalog();
      if (_currentGameState() != state || _pauseMutationRefusal() != null) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.targetUnavailable),
        );
      }
      final individualId = state.party.members[partyIndex].individualId;
      return _applyHeldItemTransfer(
        individualId.isEmpty
            ? const HeldItemOperations().unequip(
                state,
                partyIndex: partyIndex,
                bagCapacity: bagCapacity,
                itemCatalog: itemCatalog,
              )
            : const HeldItemOperations().unequipByIndividualId(
                state,
                individualId: individualId,
                bagCapacity: bagCapacity,
                itemCatalog: itemCatalog,
              ),
      );
    }
    final itemCatalog = await _resolveItemCatalog();
    final definition = itemCatalog.definitionFor(command.itemTargetId);
    if (definition == null) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.bagItemDefinitionInvalid),
      );
    }
    if (_disposed || _currentGameState() != state || _pauseMutationRefusal() != null) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.bagStateChanged),
      );
    }
    if (command.kind == RuntimePlayerPauseCommandKind.useBagItem && _contextualItemUseConsumer != null) {
      if (!state.bag.entries.any((entry) => entry.itemId == definition.id && entry.quantity > 0)) {
        return RuntimePlayerPauseCommandResult(status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.bagItemRemoved));
      }
      try {
        final disposition = await _contextualItemUseConsumer!(definition, state);
        if (disposition != RuntimeContextualItemUseDisposition.noMatch) {
          return RuntimePlayerPauseCommandResult(
            status: disposition == RuntimeContextualItemUseDisposition.reserved
                ? RuntimePlayerPauseCommandStatus.accepted : RuntimePlayerPauseCommandStatus.unavailable,
            resumeGameplay: disposition == RuntimeContextualItemUseDisposition.reserved,
            safeMessage: switch (disposition) {
              RuntimeContextualItemUseDisposition.reserved => _feedback(.bagContextualUse),
              RuntimeContextualItemUseDisposition.cancelled => _feedback(.bagContextualCancelled),
              _ => _feedback(.bagContextualUnavailable),
            },
          );
        }
      } on Object {
        return RuntimePlayerPauseCommandResult(status: RuntimePlayerPauseCommandStatus.failed,
          safeMessage: _feedback(.bagContextualFailed));
      }
      if (_disposed || _currentGameState() != state || _pauseMutationRefusal() != null) {
        return RuntimePlayerPauseCommandResult(status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.bagContextualStateChanged));
      }
    }
    if (command.kind == RuntimePlayerPauseCommandKind.useBagItem &&
        definition.uses.any((use) => use.effect is ProjectItemFishingEffectDefinition)) {
      final consumer = _fishingConsumer;
      if (consumer == null) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.fishingUnsupported),
        );
      }
      if (_currentGameState() != state || _pauseMutationRefusal() != null) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.fishingUnavailable),
        );
      }
      try {
        final reason = await consumer(definition, state);
        return RuntimePlayerPauseCommandResult(
          status: reason == null ? RuntimePlayerPauseCommandStatus.accepted
              : RuntimePlayerPauseCommandStatus.unavailable,
          resumeGameplay: reason == null,
          safeMessage: switch (reason) {
            null => _feedback(.fishingPreparing),
            FishingBlockReason.unsupportedMap => _feedback(.fishingMapUnsupported),
            FishingBlockReason.invalidItem => _feedback(.fishingRodInvalid),
            FishingBlockReason.insufficientQuantity => _feedback(.fishingRodMissing),
            FishingBlockReason.notWater => _feedback(.fishingFaceWater),
            FishingBlockReason.noEncounterSource || FishingBlockReason.encounterUnavailable =>
              _feedback(.fishingNoEncounter),
            FishingBlockReason.checkpointFailed => _feedback(.fishingDismountSaveFailed),
            _ => _feedback(.fishingUnavailable),
          },
        );
      } on Object {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.failed,
          safeMessage: _feedback(.fishingStartFailed),
        );
      }
    }
    if (command.kind == RuntimePlayerPauseCommandKind.useBagItem &&
        definition.uses.any((use) => use.effect is ProjectItemBicycleEffectDefinition)) {
      final consumer = _bicycleConsumer;
      if (consumer == null) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.bicycleUnsupported));
      }
      if (_currentGameState() != state || _pauseMutationRefusal() != null) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.bicycleUnavailable));
      }
      _setInputLocked(true);
      try {
        final applied = await consumer(definition, state);
        return RuntimePlayerPauseCommandResult(
          status: applied ? RuntimePlayerPauseCommandStatus.accepted
              : RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: applied ? _feedback(.bicycleChanged)
              : _feedback(.bicycleChangeUnavailable));
      } on Object {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.failed,
          safeMessage: _feedback(.bicycleSaveFailed));
      } finally {
        _setInputLocked(false);
      }
    }
    if (command.kind == RuntimePlayerPauseCommandKind.useBagItem &&
        definition.uses.any(
          (use) =>
              use.contexts.contains(ProjectItemUseContext.overworld) &&
              use.effect is ProjectItemEscapeRopeEffectDefinition,
        )) {
      final consumer = _escapeRopeConsumer;
      if (consumer == null) {
        return RuntimePlayerPauseCommandResult(status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.escapeRopeUnsupported));
      }
      if (_currentGameState() != state ||
          _pauseMutationRefusal() != null) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.escapeRopeUnavailable),
        );
      }
      _setInputLocked(true);
      try {
        final applied = await consumer(definition, state);
        return RuntimePlayerPauseCommandResult(
          resumeGameplay: applied && _escapeRopeResumesGameplay,
          status: applied
              ? RuntimePlayerPauseCommandStatus.accepted
              : RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: applied
              ? _feedback(.escapeRopeReturned)
              : _feedback(.escapeRopeExitBlocked),
        );
      } on Object {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.failed,
          safeMessage: _feedback(.escapeRopeSaveFailed),
        );
      } finally {
        _setInputLocked(false);
      }
    }
    if (command.kind == RuntimePlayerPauseCommandKind.useBagItem &&
        definition.uses.any(
          (use) =>
              use.contexts.contains(ProjectItemUseContext.overworld) &&
              use.target == ProjectItemTargetKind.world &&
              use.effect is ProjectItemRepelEffectDefinition,
        )) {
      if (!supportsRepel) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.repelUnsupported),
        );
      }
      try {
        final current = _currentGameState();
        final result = PlayerItemUseService(snapshot: itemCatalog).use(
          PlayerItemUseRequest(
            state: current,
            itemId: definition.id,
            context: ProjectItemUseContext.overworld,
          ),
        );
        if (!result.isSuccess) {
          return RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: result.failure == PlayerItemUseFailure.noEffect
                ? _feedback(.repelAlreadyActive)
                : _feedback(_bagItemFailureFeedback(result.failure!)),
          );
        }
        final refusal = await _commitPauseMutation(result.state);
        if (refusal != null) return refusal;
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.accepted,
          safeMessage: _feedback(.repelApplied),
        );
      } catch (_) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.failed,
          safeMessage: _feedback(.repelSaveFailed),
        );
      }
    }
    if (partyIndex == null || _currentGameState() != state) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.targetUnavailable),
      );
    }
    if (command.kind == RuntimePlayerPauseCommandKind.equipHeldItem) {
      final heldItemResolution = resolveRuntimeHeldItemEffect(
        itemCatalog: itemCatalog,
        itemId: definition.id,
      );
      switch (heldItemResolution.status) {
        case RuntimeHeldItemSupportStatus.invalidDefinition:
          return RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: _feedback(.bagItemDefinitionInvalid),
          );
        case RuntimeHeldItemSupportStatus.passive:
          return RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: _feedback(.heldItemNoEffect),
          );
        case RuntimeHeldItemSupportStatus.unsupported:
          return RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage:
                _feedback(.heldItemUnsupported),
          );
        case RuntimeHeldItemSupportStatus.nativePassive:
        case RuntimeHeldItemSupportStatus.supported:
          break;
      }
      final individualId = state.party.members[partyIndex].individualId;
      return _applyHeldItemTransfer(
        individualId.isEmpty
            ? const HeldItemOperations().equip(
                state,
                partyIndex: partyIndex,
                itemId: definition.id,
                bagCapacity: bagCapacity,
                itemCatalog: itemCatalog,
              )
            : const HeldItemOperations().equipByIndividualId(
                state,
                individualId: individualId,
                itemId: definition.id,
                bagCapacity: bagCapacity,
                itemCatalog: itemCatalog,
              ),
      );
    }
    if (definition.machine != null) {
      final moveMachineResult = await _useMoveMachineOutsideBattle(
        state: state,
        itemId: command.itemTargetId,
        machine: definition.machine!,
        partyIndex: partyIndex,
        replacementMoveId: command.moveTargetId,
        itemCatalog: itemCatalog,
      );
      if (moveMachineResult != null) return moveMachineResult;
    }
    final capability = ItemCapabilityResolver(itemCatalog).resolveUse(
      itemId: command.itemTargetId,
      context: ProjectItemUseContext.overworld,
    );
    if (!capability.isAvailable) {
      if (definition.tags.contains('key-item') || definition.capture != null) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.bagItemCannotUse),
        );
      }
      if (definition.tags.contains('evolution')) {
        return _useEvolutionItemOutsideBattle(
          state: state,
          itemId: definition.id,
          partyIndex: partyIndex,
          itemCatalog: itemCatalog,
        );
      }
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.bagItemCannotUse),
      );
    }
    if (partyIndex >= state.party.members.length) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.targetUnavailable),
      );
    }
    try {
      final caps = await _loadRecoveryCaps(state);
      final maxHp = caps.maxHpByPartyIndex[partyIndex];
      if (maxHp == null || maxHp <= 0) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.targetDataIncomplete),
        );
      }
      final result = PlayerItemUseService(snapshot: itemCatalog).use(
        PlayerItemUseRequest(
          state: state,
          itemId: command.itemTargetId,
          context: ProjectItemUseContext.overworld,
          partyIndex: partyIndex,
          maxHp: maxHp,
          baseStats: caps.baseStatsByPartyIndex[partyIndex],
          moveId: command.moveTargetId,
          maxPpByMoveId:
              caps.maxPpByPartyIndex[partyIndex] ?? const <String, int>{},
        ),
      );
      if (!result.isSuccess) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(_bagItemFailureFeedback(result.failure!)),
        );
      }
      final refusal = await _commitPauseMutation(result.state);
      if (refusal != null) return refusal;
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.accepted,
        safeMessage: _feedback(.bagItemUsed),
      );
    } catch (_) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: _feedback(.bagItemSaveFailed),
      );
    }
  }

  Future<ItemCatalogSnapshot> _resolveItemCatalog() async {
    final current = _itemCatalog;
    if (current != null) {
      return current;
    }
    final projectRootDirectory = _projectRootDirectory;
    final pokemonConfig = _pokemonConfig;
    if (projectRootDirectory == null || pokemonConfig == null) {
      return ItemCatalogSnapshot.empty();
    }
    final loaded = await _itemCatalogLoader.loadSnapshot(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    _itemCatalog = loaded;
    return loaded;
  }

  Future<RuntimePlayerPauseCommandResult> _applyHeldItemTransfer(
    HeldItemTransferResult result,
  ) async {
    if (!result.isSuccess) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: switch (result.failure!) {
          HeldItemTransferFailure.invalidRequest ||
          HeldItemTransferFailure.invalidTarget =>
            _feedback(.heldItemTargetUnavailable),
          HeldItemTransferFailure.itemMissing =>
            _feedback(.heldItemMissing),
          HeldItemTransferFailure.noHeldItem =>
            _feedback(.heldItemNone),
          HeldItemTransferFailure.alreadyEquipped =>
            _feedback(.heldItemUnchanged),
          HeldItemTransferFailure.quantityOverflow =>
            _feedback(.heldItemBagCannotReceive),
          HeldItemTransferFailure.bagFull =>
            _feedback(.heldItemBagFull),
          HeldItemTransferFailure.missingItemCatalog ||
          HeldItemTransferFailure.unknownItem =>
            _feedback(.heldItemBagCapacityUnknown),
        },
      );
    }
    try {
      final refusal = await _commitPauseMutation(result.state);
      if (refusal != null) return refusal;
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.accepted,
        safeMessage: result.status == HeldItemTransferStatus.unequipped
            ? _feedback(.heldItemRemoved)
            : _feedback(.heldItemChanged),
      );
    } catch (_) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: _feedback(.heldItemSaveFailed),
      );
    }
  }

  Future<RuntimePlayerPauseCommandResult?> _useMoveMachineOutsideBattle({
    required GameState state,
    required String itemId,
    required ProjectMoveMachineItemDefinition machine,
    required int partyIndex,
    required String? replacementMoveId,
    required ItemCatalogSnapshot itemCatalog,
  }) async {
    final projectRootDirectory = _projectRootDirectory;
    final pokemonConfig = _pokemonConfig;
    if (projectRootDirectory == null || pokemonConfig == null) return null;
    try {
      if (partyIndex >= state.party.members.length) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.targetUnavailable),
        );
      }
      final pokemon = state.party.members[partyIndex];
      final species = await _pokemonSpeciesLoader.loadById(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
        speciesId: pokemon.speciesId,
      );
      final candidate =
          await _moveMachineLoader.learnsetLoader.loadMoveMachineCandidate(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
        itemId: itemId,
        moveId: machine.moveId,
        machineKind: machine.kind.name,
        consumable: machine.consumable,
        speciesRef: species.learnsetRef,
        fallbackSpeciesId: pokemon.speciesId,
      );
      if (candidate == null) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.moveMachineIncompatible),
        );
      }
      final decision = replacementMoveId == null
          ? const PokemonMoveMachineDecision.learn()
          : PokemonMoveMachineDecision.replace(
              expectedMoveId: replacementMoveId,
            );
      final result = const PokemonMoveMachineService().apply(
        state,
        ruleset: pokemonConfig.ruleset,
        partyIndex: partyIndex,
        candidate: candidate,
        decision: decision,
        itemCatalog: itemCatalog,
      );
      switch (result.status) {
        case PokemonMoveMachineUseStatus.learned:
        case PokemonMoveMachineUseStatus.replaced:
          final refusal = await _commitPauseMutation(result.state);
          if (refusal != null) return refusal;
          return RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.accepted,
            safeMessage: result.status == PokemonMoveMachineUseStatus.replaced
                ? _feedback(.moveMachineReplaced)
                : _feedback(.moveMachineLearned),
          );
        case PokemonMoveMachineUseStatus.replacementRequired:
          return RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: _feedback(.moveMachineForgetPrompt),
          );
        case PokemonMoveMachineUseStatus.declined:
          return RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: _feedback(.moveMachineCancelled),
          );
        case PokemonMoveMachineUseStatus.failed:
          return RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: _feedback(.moveMachineCannotUse),
          );
      }
    } catch (error, stackTrace) {
      debugPrint('[move_machine] use failed: $error\n$stackTrace');
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: _feedback(.moveMachineSaveFailed),
      );
    }
  }

  Future<RuntimePlayerPauseCommandResult> _useEvolutionItemOutsideBattle({
    required GameState state,
    required String itemId,
    required int partyIndex,
    required ItemCatalogSnapshot itemCatalog,
  }) async {
    final projectRootDirectory = _projectRootDirectory;
    final pokemonConfig = _pokemonConfig;
    if (projectRootDirectory == null ||
        pokemonConfig == null ||
        partyIndex >= state.party.members.length) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: _feedback(.bagItemCannotUse),
      );
    }
    try {
      final pokemon = state.party.members[partyIndex];
      final heldPolicy = resolveRuntimeEvolutionHeldItemPolicy(itemCatalog);
      if (!heldPolicy.recognizes(pokemon.heldItemId) || heldPolicy.preventsEvolution(pokemon.heldItemId)) {
        return RuntimePlayerPauseCommandResult(status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.evolutionHeldItemInvalid));
      }
      final candidates = await _evolutionLoader.loadItemUseCandidates(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
        sourceSpeciesId: pokemon.speciesId,
        itemId: itemId,
      );
      final eligible = candidates
          .where(
            (candidate) => candidate.isEligible(
              pokemon,
              trigger: PokemonEvolutionTrigger.itemUse(itemId),
            ),
          )
          .toList(growable: false);
      if (eligible.isEmpty) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.evolutionUnavailable),
        );
      }
      if (eligible.length > 1) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage:
              _feedback(.evolutionAmbiguous),
        );
      }
      final caps = await _loadRecoveryCaps(state);
      final maxHp = caps.maxHpByPartyIndex[partyIndex];
      if (maxHp == null || maxHp <= 0) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.targetDataIncomplete),
        );
      }
      final result = pokemon.individualId.isEmpty
          ? const PokemonEvolutionItemOperations().useItem(
              state,
              ruleset: pokemonConfig.ruleset,
              itemId: itemId,
              partyIndex: partyIndex,
              candidate: eligible.single,
              sourceMaxHp: maxHp,
              itemCatalog: itemCatalog,
              heldItemPolicy: heldPolicy,
            )
          : const PokemonEvolutionItemOperations().useItemByIndividualId(
              state,
              ruleset: pokemonConfig.ruleset,
              itemId: itemId,
              individualId: pokemon.individualId,
              candidate: eligible.single,
              sourceMaxHp: maxHp,
              itemCatalog: itemCatalog,
              heldItemPolicy: heldPolicy,
            );
      if (!result.isSuccess) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _feedback(.evolutionUnavailable),
        );
      }
      final refusal = await _commitPauseMutation(result.state);
      if (refusal != null) return refusal;
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.accepted,
        safeMessage: _feedback(.evolutionSaved),
      );
    } catch (_) {
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: _feedback(.evolutionSaveFailed),
      );
    }
  }

  Future<PlayerServiceRuntimeResult> _run(
    RuntimeWorldServiceRequest request,
    Future<PlayerServiceHostResult> Function(
      GameState state,
      RuntimePlayerServiceRecoveryCaps caps,
    ) open,
  ) async {
    if (_disposed) {
      return PlayerServiceRuntimeResult.failed(
        StateError('The player-service controller is disposed.'),
      );
    }
    if (_active) return const PlayerServiceRuntimeResult.busy();
    final state = _currentGameState();
    final unavailableReason = _worldRequestUnavailableReason(request, state);
    if (unavailableReason != null) {
      return PlayerServiceRuntimeResult.unavailable(unavailableReason);
    }
    _active = true;
    var inputLocked = false;
    try {
      _setInputLocked(true);
      inputLocked = true;
      final caps = await _loadRecoveryCaps(state);
      final hostResult = await open(state, caps);
      if (hostResult.cancelled) {
        return const PlayerServiceRuntimeResult.cancelled();
      }
      final nextState = hostResult.gameState;
      if (nextState == null) {
        return PlayerServiceRuntimeResult.failed(
          StateError('A completed player service returned no GameState.'),
        );
      }
      await _commitAndSave(nextState);
      return PlayerServiceRuntimeResult.completed(nextState);
    } catch (error) {
      return PlayerServiceRuntimeResult.failed(error);
    } finally {
      if (inputLocked) _setInputLocked(false);
      _active = false;
    }
  }

  Future<PlayerServiceRuntimeResult> _runContextualHeal(
    OpenHealService request,
  ) async {
    if (_disposed) {
      return PlayerServiceRuntimeResult.failed(
        StateError('The player-service controller is disposed.'),
      );
    }
    if (_active) return const PlayerServiceRuntimeResult.busy();
    final state = _currentGameState();
    final unavailableReason = _worldRequestUnavailableReason(request, state);
    if (unavailableReason != null) {
      return PlayerServiceRuntimeResult.unavailable(unavailableReason);
    }
    _active = true;
    var inputLocked = false;
    try {
      _setInputLocked(true);
      inputLocked = true;
      final caps = await _loadRecoveryCaps(state);
      if (_disposed || _currentGameState() != state) {
        return const PlayerServiceRuntimeResult.cancelled();
      }
      final speciesById = await _loadPokemonSpeciesFor(state.party.members);
      if (_disposed || _currentGameState() != state) {
        return const PlayerServiceRuntimeResult.cancelled();
      }
      final session = _ContextualHealSession(
        request: request,
        gameState: state,
        recoveryCaps: caps,
        speciesById: speciesById,
        displayEntity: _resolveHealDisplayEntity(request, state),
      );
      _healSession = session;
      if (!request.requiresConfirmation) {
        if (!_hasAllHealCaps(session)) {
          return PlayerServiceRuntimeResult.unavailable(
            _feedback(.healCapsIncomplete),
          );
        }
        if (!await _prepareHealPresentation(session)) {
          return const PlayerServiceRuntimeResult.cancelled();
        }
        final recovered = _recoverHealSession(session);
        if (recovered != state) await _commitHealState(session, recovered);
        return PlayerServiceRuntimeResult.completed(recovered);
      }
      _publishWorldService(_buildHealSnapshot(session));
      return await session.result.future;
    } catch (error) {
      return PlayerServiceRuntimeResult.failed(error);
    } finally {
      _healSession = null;
      _publishWorldService(null);
      if (inputLocked) _setInputLocked(false);
      _active = false;
    }
  }

  Future<void> _commitHealState(
    _ContextualHealSession session,
    GameState recovered,
  ) {
    session.pendingState = recovered;
    final commit = Future<void>.microtask(() => _commitAndSave(recovered));
    session.pendingCommit = commit;
    return commit;
  }

  Future<bool> _prepareHealPresentation(_ContextualHealSession session) async {
    if (!_canContinueHeal(session)) return false;
    session.feedback = .healApplying;
    final snapshot = _buildHealSnapshot(
      session,
      stage: RuntimeWorldServiceStage.applying,
    );
    _publishWorldService(snapshot);
    if ((snapshot.content as RuntimeHealServiceContent).display != null) {
      await Future.any<void>([
        _waitForHealingDisplay(nativeHealingDisplayDuration),
        session.result.future.then((_) {}),
      ]);
    }
    return _canContinueHeal(session);
  }

  MapEntity? _resolveHealDisplayEntity(OpenHealService request, GameState state) {
    final id = request.displayEntityId;
    if (id == null) return null;
    final map = _healingDisplayMapReader?.call(state.currentMapId);
    return map == null || map.id != state.currentMapId ? null : resolveHealingDisplayEntity(map, id);
  }

  bool _canContinueHeal(_ContextualHealSession session) => !_disposed &&
      identical(_healSession, session) && !session.result.isCompleted &&
      _currentGameState() == session.gameState &&
      _resolveHealDisplayEntity(session.request, session.gameState) == session.displayEntity &&
      _worldRequestUnavailableReason(session.request, session.gameState) == null;

  String? _worldRequestUnavailableReason(
    RuntimeWorldServiceRequest request,
    GameState state,
  ) {
    if (request is OpenHealService && request.displayEntityId != null) {
      final map = _healingDisplayMapReader?.call(state.currentMapId);
      if (_host != null || map == null || map.id != state.currentMapId ||
          state.party.members.length > 6 ||
          resolveHealingDisplayEntity(map, request.displayEntityId!) == null) {
        return _feedback(.healDisplayUnavailable);
      }
    }
    final missingCapabilities =
        request.requiredCapabilities.difference(_grantedCapabilities);
    if (missingCapabilities.isNotEmpty) {
      return _feedback(.serviceUnsupported);
    }
    final condition = request.availabilityCondition;
    if (condition != null &&
        !const ScriptConditionEvaluator().evaluate(
          condition,
          state,
          context: _conditionContext,
        )) {
      return _feedback(.serviceUnavailable);
    }
    return null;
  }

  Future<PlayerServiceHostResult> _openContextualShop(
    PlayerServiceShopRequest request,
  ) async {
    final session = _ContextualShopSession(
      request: request,
      gameState: request.gameState,
      itemCatalog: request.itemCatalog,
    );
    _shopSession = session;
    _publishWorldService(_buildShopSnapshot(session));
    return await session.result.future.whenComplete(() {
      if (identical(_shopSession, session)) {
        _shopSession = null;
        _publishWorldService(null);
      }
    });
  }

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) async {
    if (_disposed) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.failed,
        safeMessage: _feedback(.serviceClosed),
      );
    }
    final snapshot = _worldServiceSnapshot;
    if (snapshot == null) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: _feedback(.serviceNotOpen),
      );
    }
    if (command.snapshotRevision != snapshot.revision) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
        safeMessage: _feedback(.serviceChanged),
      );
    }
    if (command.interactionResult != null &&
        snapshot.request is! OpenTextInputService && snapshot.request is! OpenSceneTextInteractionService && snapshot.request is! OpenPokemonGiftInteractionService) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
        safeMessage: _feedback(.serviceWrongRequest),
      );
    }
    if (!snapshot.isActionEnabled(command.action)) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: snapshot.unavailableReasonFor(command.action) ??
            _feedback(.serviceActionUnavailable),
      );
    }
    final gift = _giftSession;
    if (gift != null) return _dispatchPokemonGift(gift, command);
    if (_sceneTextPort != null) return _dispatchSceneTextInteraction(this, command);
    final shop = _shopSession;
    if (shop != null) return _dispatchShop(shop, command);
    final heal = _healSession;
    if (heal != null) return _dispatchHeal(heal, command);
    final pc = _pcSession;
    if (pc != null) return _dispatchPc(pc, command);
    final regionalMap = _regionalMapSession;
    if (regionalMap != null) return _dispatchRegionalMap(regionalMap, command);
    final puzzle = _imagePuzzleSession;
    if (puzzle != null) return _dispatchImagePuzzle(puzzle, command);
    final crafting = _craftingSession;
    if (crafting != null) return _dispatchCrafting(crafting, command);
    final trade = _partyTradeSession;
    if (trade != null) return _dispatchPartyTrade(trade, command);
    final text = _textSession;
    if (text != null) return _dispatchText(text, command);
    return RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.unavailable,
      safeMessage: _feedback(.serviceActionInvalid),
    );
  }

  Future<RuntimeWorldServiceCommandResult> _dispatchPc(
    _ContextualPcSession session,
    RuntimeWorldServiceCommand command,
  ) async {
    switch (command.action) {
      case RuntimeWorldServiceAction.select:
        final boxId = command.targetId;
        if (boxId == null ||
            !session.gameState.pokemonStorage.boxes
                .any((box) => box.id == boxId)) {
          return RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: _feedback(.pcBoxUnavailable),
          );
        }
        session.selectedBoxId = boxId;
        _publishWorldService(_buildPcSnapshot(session));
      case RuntimeWorldServiceAction.deposit:
      case RuntimeWorldServiceAction.withdraw:
        final targetId = command.targetId;
        final target = targetId == null ? null : session.targets[targetId];
        if (target == null || target.action != command.action) {
          return RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: _feedback(.pokemonUnavailable),
          );
        }
        return _applyPcTransfer(
          session,
          action: command.action,
          target: target,
        );
      case RuntimeWorldServiceAction.move:
        // BETA-PTY-003. moveWithinBox et moveBetweenBoxes existaient, testés
        // unitairement, SANS AUCUN APPELANT : le joueur ne pouvait pas ranger
        // ses boxes. Même motif que le réordonnancement d'équipe (PTY-002).
        final moveTargetId = command.targetId;
        final moveTarget =
            moveTargetId == null ? null : session.targets[moveTargetId];
        final destinationBoxId = command.secondaryTargetId;
        if (moveTarget == null ||
            moveTarget.action != RuntimeWorldServiceAction.withdraw ||
            moveTarget.boxId == null) {
          return RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: _feedback(.pokemonUnavailable),
          );
        }
        // Le null-check est nécessaire au `!` du transfert ; l'EXISTENCE de la
        // box, elle, est déjà typée par l'opération pure (invalidBoxId → « Box
        // inconnue. »). La re-vérifier ici était redondant — mesuré par
        // sabotage : la retirer ne changeait aucun comportement observable.
        if (destinationBoxId == null) {
          return RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: _feedback(.pcBoxUnavailable),
          );
        }
        return _applyPcTransfer(
          session,
          action: RuntimeWorldServiceAction.move,
          target: moveTarget,
          destinationBoxId: destinationBoxId,
        );
      case RuntimeWorldServiceAction.swap:
        final boxTargetId = command.targetId;
        final partyTargetId = command.secondaryTargetId;
        final boxTarget =
            boxTargetId == null ? null : session.targets[boxTargetId];
        final partyTarget =
            partyTargetId == null ? null : session.targets[partyTargetId];
        if (boxTarget == null ||
            boxTarget.action != RuntimeWorldServiceAction.withdraw ||
            partyTarget == null ||
            partyTarget.action != RuntimeWorldServiceAction.deposit) {
          return RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: _feedback(.tradeUnavailable),
          );
        }
        return _applyPcTransfer(
          session,
          action: RuntimeWorldServiceAction.swap,
          target: boxTarget,
          secondaryTarget: partyTarget,
        );
      case RuntimeWorldServiceAction.close:
        session.result.complete(
          PlayerServiceRuntimeResult.completed(session.gameState),
        );
      case RuntimeWorldServiceAction.cancel:
        session.result.complete(
          PlayerServiceRuntimeResult.completed(session.gameState),
        );
      case RuntimeWorldServiceAction.confirm:
      case RuntimeWorldServiceAction.rotate:
      case RuntimeWorldServiceAction.reset:
      case RuntimeWorldServiceAction.showPurchases:
      case RuntimeWorldServiceAction.showSales:
      case RuntimeWorldServiceAction.decreaseQuantity:
      case RuntimeWorldServiceAction.increaseQuantity:
        return RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
          safeMessage: _feedback(.pcCommandInvalid),
        );
    }
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  Future<RuntimeWorldServiceCommandResult> _applyPcTransfer(
    _ContextualPcSession session, {
    required RuntimeWorldServiceAction action,
    required _PcTransferTarget target,
    _PcTransferTarget? secondaryTarget,
    String? destinationBoxId,
  }) async {
    const operations = PlayerStorageOperations();
    final result = switch (action) {
      RuntimeWorldServiceAction.deposit => target.individualId.isEmpty
          ? operations.deposit(
              state: session.gameState,
              partyIndex: target.index,
              boxId: session.selectedBoxId,
            )
          : operations.depositByIndividualId(
              state: session.gameState,
              individualId: target.individualId,
              boxId: session.selectedBoxId,
            ),
      RuntimeWorldServiceAction.withdraw => target.individualId.isEmpty
          ? operations.withdraw(
              state: session.gameState,
              boxId: target.boxId!,
              boxIndex: target.index,
            )
          : operations.withdrawByIndividualId(
              state: session.gameState,
              individualId: target.individualId,
            ),
      RuntimeWorldServiceAction.move => operations.moveBetweenBoxes(
          state: session.gameState,
          sourceBoxId: target.boxId!,
          sourceIndex: target.index,
          targetBoxId: destinationBoxId!,
        ),
      RuntimeWorldServiceAction.swap =>
        target.individualId.isEmpty || secondaryTarget!.individualId.isEmpty
            ? operations.swapPartyWithBox(
                state: session.gameState,
                partyIndex: secondaryTarget!.index,
                boxId: target.boxId!,
                boxIndex: target.index,
              )
            : operations.swapPartyWithBoxByIndividualId(
                state: session.gameState,
                partyIndividualId: secondaryTarget.individualId,
                boxIndividualId: target.individualId,
              ),
      _ => throw StateError('Unsupported PC transfer action.'),
    };
    if (!result.isSuccess) {
      final message = _feedback(_pcFailureFeedback(result.failure!));
      _publishWorldService(
        _buildPcSnapshot(session, safeMessage: message),
      );
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: message,
      );
    }

    _publishWorldService(
      _buildPcSnapshot(
        session,
        stage: RuntimeWorldServiceStage.applying,
        safeMessage: _feedback(.pcSaving),
      ),
    );
    try {
      await _commitAndSave(result.state);
      session.gameState = result.state.copyWith(
        pokemonStorage: result.state.pokemonStorage.normalized(),
      );
      _publishWorldService(
        _buildPcSnapshot(
          session,
          safeMessage: switch (action) {
            RuntimeWorldServiceAction.deposit => _feedback(.pcDeposited),
            RuntimeWorldServiceAction.withdraw => _feedback(.pcWithdrawn),
            RuntimeWorldServiceAction.swap => _feedback(.pcSwapped),
            RuntimeWorldServiceAction.move => _feedback(.pcMoved),
            _ => throw StateError('Unsupported PC transfer action.'),
          },
        ),
      );
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.accepted,
      );
    } catch (error) {
      final message = _feedback(.pcSaveFailed);
      _publishWorldService(
        _buildPcSnapshot(session, safeMessage: message),
      );
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.failed,
        safeMessage: message,
      );
    }
  }

  /// Charge les catalogues nécessaires à la fiche canonique.
  ///
  /// Retourne `null` si le projet ne les expose pas : le PC retombe alors sur
  /// ses champs bruts, ce qui reste préférable à un écran vide.
  Future<RuntimePokemonSummaryBuilder Function(String locale)?>
  _loadPokemonSummaryBuilderFor(GameState state) async {
    final projectRootDirectory = _projectRootDirectory;
    final pokemonConfig = _pokemonConfig;
    if (projectRootDirectory == null || pokemonConfig == null) {
      return null;
    }
    final speciesById = await _loadPokemonSpeciesFor(<PlayerPokemon>[
      ...state.party.members,
      for (final box in state.pokemonStorage.normalized().boxes) ...box.pokemon,
    ]);
    RuntimeMoveCatalog? moveCatalog;
    try {
      moveCatalog = await RuntimeMoveCatalogLoader().load(
        projectRootDirectory: projectRootDirectory,
        pokemonConfig: pokemonConfig,
      );
    } on Object {
      moveCatalog = null;
    }
    final itemCatalog = await _resolveItemCatalog();
    return (locale) => runtimePokemonSummaryBuilderFor(
      locale: locale,
      speciesLabelFor: (speciesId) =>
          _localizedSpeciesName(speciesById[speciesId], speciesId, locale),
      calculatedStatsFor: (entry) =>
          _calculatedStatsFor(speciesById[entry.speciesId], entry),
      itemLabelFor: (itemId) => itemCatalog.definitionFor(itemId)?.displayName,
      moveFor: moveCatalog?.lookup,
    );
  }

  Future<Map<String, RuntimePokemonSpecies>> _loadPokemonSpeciesFor(
    Iterable<PlayerPokemon> pokemon,
  ) async {
    final projectRootDirectory = _projectRootDirectory;
    final pokemonConfig = _pokemonConfig;
    if (projectRootDirectory == null || pokemonConfig == null) return const {};
    final speciesById = <String, RuntimePokemonSpecies>{};
    for (final speciesId in pokemon.map((entry) => entry.speciesId).toSet()) {
      try {
        speciesById[speciesId] = await _pokemonSpeciesLoader.loadById(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
          speciesId: speciesId,
        );
      } on Object {
        continue;
      }
    }
    return speciesById;
  }

  String _localizedSpeciesName(
    RuntimePokemonSpecies? species,
    String speciesId,
    String locale,
  ) => species?.displayName(locale) ?? runtimePokemonHumanizeId(speciesId);

  PokemonCalculatedStats? _calculatedStatsFor(
    RuntimePokemonSpecies? species,
    PlayerPokemon pokemon,
  ) {
    if (species == null) {
      return null;
    }
    try {
      return const PokemonStatCalculator().calculate(
        baseStats: PokemonBaseStats(
          hp: species.baseHp,
          attack: species.baseAttack,
          defense: species.baseDefense,
          specialAttack: species.baseSpecialAttack,
          specialDefense: species.baseSpecialDefense,
          speed: species.baseSpeed,
        ),
        ivs: pokemon.ivs,
        evs: pokemon.evs,
        level: pokemon.level,
        naturePolicy: PokemonNatureStatPolicy.canonical,
        natureId: pokemon.natureId,
      );
    } on Object {
      return null;
    }
  }

  RuntimeWorldServiceSnapshot _buildPcSnapshot(
    _ContextualPcSession session, {
    RuntimeWorldServiceStage stage = RuntimeWorldServiceStage.active,
    String? safeMessage,
  }) {
    final boxes = session.gameState.pokemonStorage.normalized().boxes;
    if (!boxes.any((box) => box.id == session.selectedBoxId)) {
      session.selectedBoxId = boxes.first.id;
    }
    final selectedBox =
        boxes.firstWhere((box) => box.id == session.selectedBoxId);
    final targets = <String, _PcTransferTarget>{};
    final party = <RuntimePcPokemonSnapshot>[];
    final summaryBuilder = session.summaryBuilderFor?.call(_displayLocale);
    const operations = PlayerStorageOperations();
    for (var index = 0;
        index < session.gameState.party.members.length;
        index++) {
      final pokemon = session.gameState.party.members[index];
      final result = operations.deposit(
        state: session.gameState,
        partyIndex: index,
        boxId: selectedBox.id,
      );
      final targetId = pokemon.individualId.isEmpty
          ? 'party-slot-$index'
          : 'pokemon.${pokemon.individualId}';
      final summary = summaryBuilder?.build(pokemon, targetId: targetId);
      targets[targetId] = _PcTransferTarget(
        action: RuntimeWorldServiceAction.deposit,
        index: index,
        individualId: pokemon.individualId,
      );
      party.add(
        RuntimePcPokemonSnapshot(
          targetId: targetId,
          label: summary?.displayLabel ?? _pokemonDisplayLabel(pokemon),
          speciesId: pokemon.speciesId,
          formId: pokemon.formId,
          level: pokemon.level,
          natureId: pokemon.natureId,
          abilityId: pokemon.abilityId,
          currentHp: pokemon.currentHp,
          gender: pokemon.gender,
          statusId: pokemon.statusId,
          isShiny: pokemon.isShiny,
          heldItemId: pokemon.heldItemId,
          nickname: pokemon.nickname,
          friendship: pokemon.friendship,
          originKind: pokemon.provenance?.kind.name ??
              PlayerPokemonOriginKind.unknown.name,
          metMapId: pokemon.provenance?.mapId ?? '',
          metSourceId: pokemon.provenance?.sourceId ?? '',
          ballItemId: pokemon.provenance?.ballItemId ?? '',
          metLevel: pokemon.provenance?.metLevel,
          knownMoveIds: pokemon.knownMoveIds,
          canTransfer: result.isSuccess,
          unavailableReason:
              result.isSuccess ? null : _feedback(_pcFailureFeedback(result.failure!)),
          summary: summary,
        ),
      );
    }
    final stored = <RuntimePcPokemonSnapshot>[];
    for (var index = 0; index < selectedBox.pokemon.length; index++) {
      final pokemon = selectedBox.pokemon[index];
      final result = operations.withdraw(
        state: session.gameState,
        boxId: selectedBox.id,
        boxIndex: index,
      );
      final targetId = pokemon.individualId.isEmpty
          ? 'box-slot-${selectedBox.id}-$index'
          : 'pokemon.${pokemon.individualId}';
      final summary = summaryBuilder?.build(pokemon, targetId: targetId);
      targets[targetId] = _PcTransferTarget(
        action: RuntimeWorldServiceAction.withdraw,
        index: index,
        boxId: selectedBox.id,
        individualId: pokemon.individualId,
      );
      stored.add(
        RuntimePcPokemonSnapshot(
          targetId: targetId,
          label: summary?.displayLabel ?? _pokemonDisplayLabel(pokemon),
          speciesId: pokemon.speciesId,
          formId: pokemon.formId,
          level: pokemon.level,
          natureId: pokemon.natureId,
          abilityId: pokemon.abilityId,
          currentHp: pokemon.currentHp,
          gender: pokemon.gender,
          statusId: pokemon.statusId,
          isShiny: pokemon.isShiny,
          heldItemId: pokemon.heldItemId,
          nickname: pokemon.nickname,
          friendship: pokemon.friendship,
          originKind: pokemon.provenance?.kind.name ??
              PlayerPokemonOriginKind.unknown.name,
          metMapId: pokemon.provenance?.mapId ?? '',
          metSourceId: pokemon.provenance?.sourceId ?? '',
          ballItemId: pokemon.provenance?.ballItemId ?? '',
          metLevel: pokemon.provenance?.metLevel,
          knownMoveIds: pokemon.knownMoveIds,
          canTransfer: result.isSuccess,
          unavailableReason:
              result.isSuccess ? null : _feedback(_pcFailureFeedback(result.failure!)),
          summary: summary,
        ),
      );
    }
    session.targets = targets;
    final canDeposit = party.any((pokemon) => pokemon.canTransfer);
    final canWithdraw = stored.any((pokemon) => pokemon.canTransfer);
    final canSwap = selectedBox.pokemon.asMap().entries.any(
          (boxEntry) => session.gameState.party.members.asMap().entries.any(
                (partyEntry) => operations
                    .swapPartyWithBox(
                      state: session.gameState,
                      partyIndex: partyEntry.key,
                      boxId: selectedBox.id,
                      boxIndex: boxEntry.key,
                    )
                    .isSuccess,
              ),
        );
    return RuntimeWorldServiceSnapshot(
      revision: (_worldServiceSnapshot?.revision ?? -1) + 1,
      request: session.request,
      stage: stage,
      content: RuntimePcServiceContent(
        title: _feedback(.pcTitle),
        message: _feedback(.pcHelp),
        selectedBoxId: selectedBox.id,
        boxes: boxes
            .map(
              (box) => RuntimePcBoxSnapshot(
                boxId: box.id,
                label: box.label,
                count: box.pokemon.length,
                capacity: box.capacity,
              ),
            )
            .toList(growable: false),
        party: party,
        stored: stored,
      ),
      safeMessage: safeMessage,
      logicalSelectionId: selectedBox.id,
      actions: stage == RuntimeWorldServiceStage.applying
          ? const <RuntimeWorldServiceActionAvailability>[]
          : <RuntimeWorldServiceActionAvailability>[
              const RuntimeWorldServiceActionAvailability.enabled(
                RuntimeWorldServiceAction.select,
              ),
              if (canDeposit)
                const RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.deposit,
                )
              else
                RuntimeWorldServiceActionAvailability.disabled(
                  RuntimeWorldServiceAction.deposit,
                  reason: party.firstOrNull?.unavailableReason ??
                      _feedback(.pcNoDeposit),
                ),
              if (canWithdraw)
                const RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.withdraw,
                )
              else
                RuntimeWorldServiceActionAvailability.disabled(
                  RuntimeWorldServiceAction.withdraw,
                  reason: stored.firstOrNull?.unavailableReason ??
                      _feedback(.pcNoWithdraw),
                ),
              if (canSwap)
                const RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.swap,
                )
              else
                RuntimeWorldServiceActionAvailability.disabled(
                  RuntimeWorldServiceAction.swap,
                  reason: _feedback(.pcNoSwap),
                ),
              if (stored.isNotEmpty && boxes.length > 1)
                const RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.move,
                )
              else
                RuntimeWorldServiceActionAvailability.disabled(
                  RuntimeWorldServiceAction.move,
                  reason: stored.isEmpty
                      ? _feedback(.pcNoMove)
                      : _feedback(.pcNoDestination),
                ),
              const RuntimeWorldServiceActionAvailability.enabled(
                RuntimeWorldServiceAction.close,
              ),
            ],
    );
  }

  Future<RuntimeWorldServiceCommandResult> _dispatchHeal(
    _ContextualHealSession session,
    RuntimeWorldServiceCommand command,
  ) async {
    switch (command.action) {
      case RuntimeWorldServiceAction.confirm:
        try {
          if (!await _prepareHealPresentation(session)) {
            if (!_disposed) {
              session
                ..failure = StateError('The healing session changed before commit.')
                ..feedback = .healInterrupted;
              _publishWorldService(
                _buildHealSnapshot(
                  session,
                  stage: RuntimeWorldServiceStage.failed,
                ),
              );
            }
            return const RuntimeWorldServiceCommandResult(status: RuntimeWorldServiceCommandStatus.stale);
          }
          final recovered = _recoverHealSession(session);
          if (recovered != session.gameState) {
            await _commitHealState(session, recovered);
          }
          session
            ..gameState = recovered
            ..wasHealed = true
            ..failure = null
            ..feedback = recovered == session.initialGameState
                ? .healAlreadyHealthy
                : .healPartyHealed;
          if (!_disposed) {
            _publishWorldService(
              _buildHealSnapshot(
                session,
                stage: RuntimeWorldServiceStage.completed,
              ),
            );
          }
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.accepted,
          );
        } catch (error) {
          session
            ..failure = error
            ..feedback = .healSaveFailed;
          if (!_disposed) {
            _publishWorldService(
              _buildHealSnapshot(
                session,
                stage: RuntimeWorldServiceStage.failed,
              ),
            );
          }
          return RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.failed,
            safeMessage: _feedback(.healSaveFailed),
          );
        }
      case RuntimeWorldServiceAction.close:
      case RuntimeWorldServiceAction.cancel:
        if (session.wasHealed) {
          session.result.complete(
            PlayerServiceRuntimeResult.completed(session.gameState),
          );
        } else if (session.failure case final error?) {
          session.result.complete(PlayerServiceRuntimeResult.failed(error));
        } else {
          session.result.complete(
            const PlayerServiceRuntimeResult.cancelled(),
          );
        }
      case RuntimeWorldServiceAction.select:
      case RuntimeWorldServiceAction.rotate:
      case RuntimeWorldServiceAction.reset:
      case RuntimeWorldServiceAction.showPurchases:
      case RuntimeWorldServiceAction.showSales:
      case RuntimeWorldServiceAction.decreaseQuantity:
      case RuntimeWorldServiceAction.increaseQuantity:
      case RuntimeWorldServiceAction.deposit:
      case RuntimeWorldServiceAction.withdraw:
      case RuntimeWorldServiceAction.swap:
      case RuntimeWorldServiceAction.move:
        return RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
          safeMessage: _feedback(.healCommandInvalid),
        );
    }
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  RuntimeWorldServiceSnapshot _buildHealSnapshot(
    _ContextualHealSession session, {
    RuntimeWorldServiceStage stage = RuntimeWorldServiceStage.active,
  }) {
    final members = <RuntimeHealPartyMemberSnapshot>[];
    final locale = _displayLocale;
    for (var index = 0;
        index < session.gameState.party.members.length;
        index++) {
      final member = session.gameState.party.members[index];
      final maxHp =
          session.recoveryCaps.maxHpByPartyIndex[index] ?? member.currentHp;
      final moveCaps = session.recoveryCaps.maxPpByPartyIndex[index] ??
          const <String, int>{};
      final depletedMoveCount = member.knownMoveIds.where((moveId) {
        final maxPp = moveCaps[moveId];
        final currentPp = member.currentPpByMoveId?[moveId];
        return maxPp != null && currentPp != null && currentPp < maxPp;
      }).length;
      members.add(
        RuntimeHealPartyMemberSnapshot(
          partyIndex: index,
          label: _localizedSpeciesName(
            session.speciesById[member.speciesId],
            member.speciesId,
            locale,
          ),
          currentHp: member.currentHp,
          maxHp: maxHp > 0 ? maxHp : 1,
          hasStatus: member.statusId.isNotEmpty,
          depletedMoveCount: depletedMoveCount,
        ),
      );
    }
    final canHeal = members.isNotEmpty && _hasAllHealCaps(session);
    return RuntimeWorldServiceSnapshot(
      revision: (_worldServiceSnapshot?.revision ?? -1) + 1,
      request: session.request,
      stage: stage,
      content: RuntimeHealServiceContent(
        title: _feedback(.healTitle),
        message: stage == RuntimeWorldServiceStage.completed
            ? _feedback(.healCompleted)
            : _feedback(.healHelp),
        members: members,
        wasHealed: session.wasHealed,
        display: stage == RuntimeWorldServiceStage.applying &&
                session.request.displayEntityId != null && members.isNotEmpty
            ? RuntimeHealingDisplaySnapshot(mapId: session.gameState.currentMapId,
                entityId: session.request.displayEntityId!, memberCount: members.length)
            : null,
      ),
      safeMessage: switch (session.feedback) {
        final feedback? => _feedback(feedback),
        null => null,
      },
      actions: switch (stage) {
        RuntimeWorldServiceStage.applying =>
          const <RuntimeWorldServiceActionAvailability>[],
        RuntimeWorldServiceStage.completed =>
          const <RuntimeWorldServiceActionAvailability>[
            RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.close,
            ),
          ],
        RuntimeWorldServiceStage.failed ||
        RuntimeWorldServiceStage.active ||
        RuntimeWorldServiceStage.opening =>
          <RuntimeWorldServiceActionAvailability>[
            if (canHeal)
              const RuntimeWorldServiceActionAvailability.enabled(
                RuntimeWorldServiceAction.confirm,
              )
            else
              RuntimeWorldServiceActionAvailability.disabled(
                RuntimeWorldServiceAction.confirm,
                reason: members.isEmpty
                    ? _feedback(.partyEmpty)
                    : _feedback(.healCapsIncomplete),
              ),
            const RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.cancel,
            ),
            const RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.close,
            ),
          ],
      },
    );
  }

  bool _hasAllHealCaps(_ContextualHealSession session) {
    return List<int>.generate(
      session.gameState.party.members.length,
      (index) => index,
    ).every(
      (index) => (session.recoveryCaps.maxHpByPartyIndex[index] ?? 0) > 0,
    );
  }

  GameState _recoverHealSession(_ContextualHealSession session) {
    final recovered = const GameStateMutations().recoverParty(
      session.initialGameState,
      maxHpByPartyIndex: session.recoveryCaps.maxHpByPartyIndex,
      maxPpByPartyIndex: session.recoveryCaps.maxPpByPartyIndex,
    );
    return recovered.currentMapId.trim().isEmpty
        ? recovered
        : recordPlayerRecoveryPoint(recovered);
  }

  RuntimeWorldServiceCommandResult _dispatchShop(
    _ContextualShopSession session,
    RuntimeWorldServiceCommand command,
  ) {
    switch (command.action) {
      case RuntimeWorldServiceAction.select:
        final targetId = command.targetId;
        if (targetId == null ||
            !_shopEntries(session).any((entry) => entry.itemId == targetId)) {
          return RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: _feedback(.shopItemUnavailable),
          );
        }
        session
          ..selectedItemId = targetId
          ..quantity = 1;
        _publishWorldService(_buildShopSnapshot(session));
      case RuntimeWorldServiceAction.rotate:
      case RuntimeWorldServiceAction.reset:
      case RuntimeWorldServiceAction.showPurchases:
        session
          ..mode = RuntimeShopMode.buy
          ..selectedItemId = null
          ..quantity = 1;
        _publishWorldService(_buildShopSnapshot(session));
      case RuntimeWorldServiceAction.showSales:
        session
          ..mode = RuntimeShopMode.sell
          ..selectedItemId = null
          ..quantity = 1;
        _publishWorldService(_buildShopSnapshot(session));
      case RuntimeWorldServiceAction.decreaseQuantity:
        session.quantity = (session.quantity - 1).clamp(1, 10);
        _publishWorldService(_buildShopSnapshot(session));
      case RuntimeWorldServiceAction.increaseQuantity:
        final maximum = _maximumShopQuantity(session);
        session.quantity = (session.quantity + 1).clamp(1, maximum);
        _publishWorldService(_buildShopSnapshot(session));
      case RuntimeWorldServiceAction.confirm:
        return session.mode == RuntimeShopMode.buy
            ? _purchaseFromShop(session, command)
            : _sellToShop(session, command);
      case RuntimeWorldServiceAction.close:
        session.result.complete(
          PlayerServiceHostResult.completed(session.gameState),
        );
      case RuntimeWorldServiceAction.cancel:
        session.result.complete(const PlayerServiceHostResult.cancelled());
      case RuntimeWorldServiceAction.deposit:
      case RuntimeWorldServiceAction.withdraw:
      case RuntimeWorldServiceAction.swap:
      case RuntimeWorldServiceAction.move:
        return RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
          safeMessage: _feedback(.shopCommandInvalid),
        );
    }
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  RuntimeWorldServiceCommandResult _purchaseFromShop(
    _ContextualShopSession session,
    RuntimeWorldServiceCommand command,
  ) {
    final itemId = command.targetId ?? session.selectedItemId;
    final quantity = command.quantity ?? session.quantity;
    if (itemId == null) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: _feedback(.shopChooseItem),
      );
    }
    final result = _previewShopPurchase(session, itemId, quantity);
    if (!result.isSuccess) {
      final message = _feedback(_shopFailureFeedback(result.failure!));
      _publishWorldService(
        _buildShopSnapshot(session, safeMessage: message),
      );
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: message,
      );
    }
    session
      ..gameState = result.state
      ..resolved = const ShopStateResolver().resolve(
        shop: session.request.shop,
        gameState: result.state,
        conditionContext: session.request.conditionContext,
      )
      ..selectedItemId = itemId
      ..quantity = 1;
    _publishWorldService(
      _buildShopSnapshot(
        session,
        safeMessage: result.bonusQuantity > 0
            ? _feedback(.shopPurchaseBonus, {
                'quantity': result.bonusQuantity,
                'item': session.itemCatalog.definitionFor(result.bonusItemId!)?.displayName ??
                    _shopItemLabel(result.bonusItemId!),
              })
            : _feedback(.shopPurchaseComplete),
      ),
    );
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  ShopPurchaseResult _previewShopPurchase(
    _ContextualShopSession session,
    String itemId,
    int quantity,
  ) {
    return const GameStateMutations().purchaseFromResolvedShop(
      session.gameState,
      shop: session.request.shop,
      expectedStateId: session.resolved.stateId,
      itemId: itemId,
      quantity: quantity,
      itemCatalog: session.itemCatalog,
      bagCapacity: bagCapacity,
      conditionContext: session.request.conditionContext,
    );
  }

  RuntimeWorldServiceCommandResult _sellToShop(
    _ContextualShopSession session,
    RuntimeWorldServiceCommand command,
  ) {
    final itemId = command.targetId ?? session.selectedItemId;
    final quantity = command.quantity ?? session.quantity;
    if (itemId == null) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: _feedback(.shopChooseItem),
      );
    }
    final result = const GameStateMutations().sellToResolvedShop(
      session.gameState,
      shop: session.request.shop,
      expectedStateId: session.resolved.stateId,
      itemId: itemId,
      quantity: quantity,
      itemCatalog: session.itemCatalog,
      conditionContext: session.request.conditionContext,
    );
    if (!result.isSuccess) {
      final message = _feedback(_shopSaleFailureFeedback(result.failure!));
      _publishWorldService(
        _buildShopSnapshot(session, safeMessage: message),
      );
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: message,
      );
    }
    session
      ..gameState = result.state
      ..resolved = const ShopStateResolver().resolve(
        shop: session.request.shop,
        gameState: result.state,
        conditionContext: session.request.conditionContext,
      )
      ..selectedItemId = itemId
      ..quantity = 1;
    _publishWorldService(
      _buildShopSnapshot(
        session,
        safeMessage: _feedback(.shopSaleComplete),
      ),
    );
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  RuntimeWorldServiceSnapshot _buildShopSnapshot(
    _ContextualShopSession session, {
    String? safeMessage,
  }) {
    final entries = _shopEntries(session);
    if (!entries.any((entry) => entry.itemId == session.selectedItemId)) {
      session.selectedItemId =
          entries.where((entry) => entry.canTransact).firstOrNull?.itemId ??
              entries.firstOrNull?.itemId;
      session.quantity = 1;
    }
    final selected = entries
        .where((entry) => entry.itemId == session.selectedItemId)
        .firstOrNull;
    final totalPrice = (selected?.unitPrice ?? 0) * session.quantity;
    final purchaseFailure =
        session.mode == RuntimeShopMode.buy && selected != null
        ? _previewShopPurchase(session, selected.itemId, session.quantity).failure
        : null;
    final canTransact = session.resolved.isOpen &&
        selected != null &&
        selected.canTransact &&
        (session.mode == RuntimeShopMode.sell
            ? selected.ownedQuantity >= session.quantity
            : purchaseFailure == null);
    final confirmReason = !session.resolved.isOpen
        ? _feedback(.shopClosed)
        : selected == null
            ? session.mode == RuntimeShopMode.sell
                ? _feedback(.shopBagEmpty)
                : _feedback(.shopEmpty)
            : !selected.canTransact
                ? selected.unavailableReason
                : session.mode == RuntimeShopMode.sell
                    ? selected.ownedQuantity < session.quantity
                        ? _feedback(.shopInsufficientQuantity)
                        : null
                    : purchaseFailure == null
                        ? null
                        : _feedback(_shopFailureFeedback(purchaseFailure));
    return RuntimeWorldServiceSnapshot(
      revision: (_worldServiceSnapshot?.revision ?? -1) + 1,
      request: session.request.worldRequest!,
      stage: RuntimeWorldServiceStage.active,
      content: RuntimeShopServiceContent(
        title: session.resolved.storefrontLabel,
        message: session.resolved.message,
        money: session.gameState.trainerProfile.money,
        entries: entries,
        mode: session.mode,
        selectedItemId: session.selectedItemId,
        quantity: session.quantity,
        totalPrice: totalPrice,
      ),
      safeMessage: safeMessage,
      logicalSelectionId: session.selectedItemId,
      actions: <RuntimeWorldServiceActionAvailability>[
        const RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.showPurchases,
        ),
        const RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.showSales,
        ),
        if (entries.isEmpty)
          RuntimeWorldServiceActionAvailability.disabled(
            RuntimeWorldServiceAction.select,
            reason: session.mode == RuntimeShopMode.sell
                ? _feedback(.shopBagEmpty)
                : _feedback(.shopEmpty),
          )
        else
          const RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.select,
          ),
        if (session.quantity > 1)
          const RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.decreaseQuantity,
          )
        else
          RuntimeWorldServiceActionAvailability.disabled(
            RuntimeWorldServiceAction.decreaseQuantity,
            reason: _feedback(.shopMinimumQuantity),
          ),
        if (selected != null &&
            session.quantity < _maximumShopQuantity(session))
          const RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.increaseQuantity,
          )
        else
          RuntimeWorldServiceActionAvailability.disabled(
            RuntimeWorldServiceAction.increaseQuantity,
            reason: _feedback(.shopMaximumQuantity),
          ),
        if (canTransact)
          const RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.confirm,
          )
        else
          RuntimeWorldServiceActionAvailability.disabled(
            RuntimeWorldServiceAction.confirm,
            reason: confirmReason ??
                (session.mode == RuntimeShopMode.sell
                    ? _feedback(.shopSaleUnavailable)
                    : _feedback(.shopPurchaseUnavailable)),
          ),
        const RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );
  }

  List<RuntimeShopEntrySnapshot> _shopEntries(
    _ContextualShopSession session,
  ) {
    if (session.mode == RuntimeShopMode.buy) {
      return session.resolved.entries.map((entry) {
        final capacityFailure = bagCapacity.pockets.isNotEmpty &&
                _previewShopPurchase(session, entry.itemId, 1).failure ==
                    ShopPurchaseFailure.bagFull
            ? _feedback(_shopFailureFeedback(ShopPurchaseFailure.bagFull))
            : null;
        return RuntimeShopEntrySnapshot(
          itemId: entry.itemId,
          label: _shopItemLabel(entry.itemId),
          unitPrice: entry.price,
          remainingStock: _remainingShopStock(session, entry),
          canTransact: capacityFailure == null,
          unavailableReason: capacityFailure,
        );
      }).toList(growable: false);
    }

    return session.gameState.bag
        .normalized()
        .entries
        .map((bagEntry) {
          final shopEntry = session.resolved.entries
              .where((entry) => entry.itemId == bagEntry.itemId)
              .firstOrNull;
          final sellPrice =
              session.request.shop.sellPolicy == ShopSellPolicy.catalogPrices
              ? session.itemCatalog.definitionFor(bagEntry.itemId)?.sellPrice
              : shopEntry?.sellPrice;
          final unavailable = _shopSaleUnavailableFeedback(
            bagEntry: bagEntry,
            sellPrice: sellPrice,
            itemCatalog: session.itemCatalog,
          );
          return RuntimeShopEntrySnapshot(
            itemId: bagEntry.itemId,
            label: _shopItemLabel(bagEntry.itemId),
            unitPrice: sellPrice ?? 0,
            ownedQuantity: bagEntry.quantity,
            canTransact: unavailable == null,
            unavailableReason: unavailable == null ? null : _feedback(unavailable),
          );
        })
        .toList(growable: false);
  }

  int _maximumShopQuantity(_ContextualShopSession session) {
    final itemId = session.selectedItemId;
    if (itemId == null) return 1;
    if (session.mode == RuntimeShopMode.sell) {
      final entry = _shopEntries(session)
          .where((candidate) => candidate.itemId == itemId)
          .firstOrNull;
      return (entry?.ownedQuantity ?? 1).clamp(1, 10);
    }
    final entry = session.resolved.entries
        .where((candidate) => candidate.itemId == itemId)
        .firstOrNull;
    if (entry == null) return 1;
    final remaining = _remainingShopStock(session, entry);
    final maximum = remaining == null ? 10 : remaining.clamp(1, 10);
    for (var quantity = maximum; quantity > 1; quantity--) {
      if (_previewShopPurchase(session, itemId, quantity).isSuccess) {
        return quantity;
      }
    }
    return 1;
  }

  int? _remainingShopStock(
    _ContextualShopSession session,
    ShopEntryDefinition entry,
  ) {
    final stock = entry.stock;
    final stockKey =
        '${session.request.shop.id}::'
        '${session.resolved.stateId}::${entry.itemId}';
    final purchased =
        session.gameState.progression.shopPurchaseCounts[stockKey] ?? 0;
    final remainingStock = stock == null
        ? null
        : (stock - purchased).clamp(0, stock);
    final ownedLimit = entry.maximumOwnedQuantity;
    if (ownedLimit == null) return remainingStock;
    final owned = session.gameState.bag
        .normalized()
        .entries
        .where((item) => item.itemId == entry.itemId)
        .fold(0, (total, item) => total + item.quantity);
    final remainingOwned = (ownedLimit - owned).clamp(0, ownedLimit);
    return remainingStock == null || remainingOwned < remainingStock
        ? remainingOwned
        : remainingStock;
  }

  void _publishWorldService(RuntimeWorldServiceSnapshot? snapshot) {
    _worldServiceSnapshot = snapshot;
    if (!_worldServiceSnapshots.isClosed) {
      _worldServiceSnapshots.add(snapshot);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final gift = _giftSession;
    if (gift != null && !gift.result.isCompleted) {
      final interaction = gift.request.interaction;
      gift.result.complete(
        SceneInteractionResult.cancelled(
          requestId: interaction.requestId,
          revision: interaction.revision,
          reason: SceneInteractionCancellationReason.disposed,
        ),
      );
    }
    try {
      await _periodicRewardCommit;
    } catch (_) {}
    await _disposeImagePuzzle();
    await _disposeCrafting();
    await _disposePartyTrade();
    final shop = _shopSession;
    if (shop != null && !shop.result.isCompleted) {
      shop.result.complete(const PlayerServiceHostResult.cancelled());
    }
    _shopSession = null;
    final heal = _healSession;
    if (heal != null && !heal.result.isCompleted) {
      final pending = heal.pendingCommit;
      if (pending == null) {
        heal.result.complete(const PlayerServiceRuntimeResult.cancelled());
      } else {
        try {
          await pending;
          if (!heal.result.isCompleted) {
            heal.result.complete(PlayerServiceRuntimeResult.completed(heal.pendingState!));
          }
        } catch (error) {
          if (!heal.result.isCompleted) {
            heal.result.complete(PlayerServiceRuntimeResult.failed(error));
          }
        }
      }
    }
    _healSession = null;
    final pc = _pcSession;
    if (pc != null && !pc.result.isCompleted) {
      pc.result.complete(const PlayerServiceRuntimeResult.cancelled());
    }
    _pcSession = null;
    final regionalMap = _regionalMapSession;
    if (regionalMap != null && !regionalMap.result.isCompleted) {
      regionalMap.result.complete(const PlayerServiceRuntimeResult.cancelled());
    }
    _regionalMapSession = null;
    final text = _textSession;
    if (text != null && !text.result.isCompleted) {
      text.result.complete(const PlayerServiceRuntimeResult.cancelled());
    }
    _textSession = null;
    _sceneTextPort?.close();
    _sceneTextPort = null;
    _publishWorldService(null);
    await _worldServiceSnapshots.close();
  }
}

final class _ContextualRegionalMapSession {
  _ContextualRegionalMapSession({required this.request, required this.detail, this.prepareFly, this.applyFly});
  final OpenRegionalMapService request;
  final RuntimePlayerPauseDetailSnapshot detail;
  final Future<({FlyActionTicket? ticket, FlyBlockReason? reason})> Function(String pointId)? prepareFly;
  final Future<bool> Function(FlyActionTicket ticket)? applyFly;
  FlyActionTicket? ticket;
  String? message;
  bool applying = false;
  final result = Completer<PlayerServiceRuntimeResult>();
}

final class _ContextualTextSession {
  _ContextualTextSession({required this.request});

  final OpenTextInputService request;
  final result = Completer<PlayerServiceRuntimeResult>();
  SceneTextInteractionRequest? interaction;
  Timer? timer;
  String? value;
}

final class _ContextualShopSession {
  _ContextualShopSession({
    required this.request,
    required this.gameState,
    required this.itemCatalog,
  })  : resolved = request.resolvedState,
        selectedItemId = request.resolvedState.entries.firstOrNull?.itemId;

  final PlayerServiceShopRequest request;
  final ItemCatalogSnapshot itemCatalog;
  final result = Completer<PlayerServiceHostResult>();
  GameState gameState;
  ResolvedShopState resolved;
  RuntimeShopMode mode = RuntimeShopMode.buy;
  String? selectedItemId;
  int quantity = 1;
}

final class _ContextualHealSession {
  _ContextualHealSession({
    required this.request,
    required GameState gameState,
    required this.recoveryCaps,
    required this.speciesById,
    this.displayEntity,
  })  : initialGameState = gameState,
        gameState = gameState;

  final OpenHealService request;
  final GameState initialGameState;
  final MapEntity? displayEntity;
  final RuntimePlayerServiceRecoveryCaps recoveryCaps;
  final Map<String, RuntimePokemonSpecies> speciesById;
  final result = Completer<PlayerServiceRuntimeResult>();
  Future<void>? pendingCommit;
  GameState? pendingState;
  GameState gameState;
  bool wasHealed = false;
  RuntimeServiceFeedback? feedback;
  Object? failure;
}

final class _ContextualPcSession {
  _ContextualPcSession({
    required this.request,
    required this.gameState,
    required this.selectedBoxId,
    this.summaryBuilderFor,
  });

  /// Résolu une fois à l'ouverture : `_buildPcSnapshot` est synchrone alors que
  /// les catalogues se chargent en asynchrone.
  final RuntimePokemonSummaryBuilder Function(String locale)? summaryBuilderFor;

  final OpenPcService request;
  final result = Completer<PlayerServiceRuntimeResult>();
  GameState gameState;
  String selectedBoxId;
  Map<String, _PcTransferTarget> targets = const <String, _PcTransferTarget>{};
}

final class _PcTransferTarget {
  const _PcTransferTarget({
    required this.action,
    required this.index,
    this.individualId = '',
    this.boxId,
  });

  final RuntimeWorldServiceAction action;
  final int index;
  final String individualId;
  final String? boxId;
}

RuntimeServiceFeedback _shopFailureFeedback(ShopPurchaseFailure failure) => switch (failure) {
  ShopPurchaseFailure.invalidRequest => RuntimeServiceFeedback.shopPurchaseInvalid,
  ShopPurchaseFailure.unknownItem => RuntimeServiceFeedback.shopItemUnknown,
  ShopPurchaseFailure.insufficientFunds => RuntimeServiceFeedback.shopFundsInsufficient,
  ShopPurchaseFailure.outOfStock => RuntimeServiceFeedback.shopStockInsufficient,
  ShopPurchaseFailure.ownershipLimit =>
    RuntimeServiceFeedback.shopOwnedLimit,
  ShopPurchaseFailure.bagFull =>
    RuntimeServiceFeedback.shopBagFull,
  ShopPurchaseFailure.shopClosed => RuntimeServiceFeedback.shopClosed,
  ShopPurchaseFailure.shopStateChanged =>
    RuntimeServiceFeedback.shopStateChanged,
};

RuntimeServiceFeedback _shopSaleFailureFeedback(ShopSaleFailure failure) => switch (failure) {
      ShopSaleFailure.invalidRequest => RuntimeServiceFeedback.shopSaleInvalid,
      ShopSaleFailure.unknownItem => RuntimeServiceFeedback.shopItemUnknown,
      ShopSaleFailure.insufficientQuantity => RuntimeServiceFeedback.shopInsufficientQuantity,
      ShopSaleFailure.unsellable => RuntimeServiceFeedback.shopItemUnsellable,
      ShopSaleFailure.keyItem => RuntimeServiceFeedback.shopItemImportant,
      ShopSaleFailure.shopClosed => RuntimeServiceFeedback.shopClosed,
      ShopSaleFailure.shopStateChanged =>
        RuntimeServiceFeedback.shopStateChanged,
    };

RuntimeServiceFeedback? _shopSaleUnavailableFeedback({
  required BagEntry bagEntry,
  required int? sellPrice,
  required ItemCatalogSnapshot itemCatalog,
}) {
  if (itemCatalog.definitionFor(bagEntry.itemId)?.tags.contains('key-item') ??
      false) {
    return RuntimeServiceFeedback.shopItemImportant;
  }
  if (sellPrice == null || sellPrice <= 0) {
    return RuntimeServiceFeedback.shopItemNotAccepted;
  }
  return null;
}

String _shopItemLabel(String itemId) => itemId
    .replaceAll('_', '-')
    .split('-')
    .where((part) => part.isNotEmpty)
    .map(
      (part) => '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _pokemonDisplayLabel(PlayerPokemon pokemon) {
  final nickname = pokemon.nickname.trim();
  return nickname.isEmpty
      ? runtimePokemonHumanizeId(pokemon.speciesId)
      : nickname;
}

RuntimeServiceFeedback _pcFailureFeedback(PlayerStorageFailure failure) => switch (failure) {
      PlayerStorageFailure.invalidRequest => RuntimeServiceFeedback.pcOperationInvalid,
      PlayerStorageFailure.invalidPartyIndex => RuntimeServiceFeedback.pcPartySlotInvalid,
      PlayerStorageFailure.invalidBoxId => RuntimeServiceFeedback.pcBoxUnknown,
      PlayerStorageFailure.invalidBoxIndex => RuntimeServiceFeedback.pcBoxSlotInvalid,
      PlayerStorageFailure.partyFull => RuntimeServiceFeedback.pcPartyFull,
      PlayerStorageFailure.boxFull => RuntimeServiceFeedback.pcBoxFull,
      PlayerStorageFailure.storageFull => RuntimeServiceFeedback.pcFull,
      PlayerStorageFailure.lastUsablePokemon =>
        RuntimeServiceFeedback.pcLastUsablePokemon,
    };

int? _partyIndexFromTarget(GameState state, String targetId) {
  const individualPrefix = 'pokemon.';
  if (targetId.startsWith(individualPrefix)) {
    final individualId = targetId.substring(individualPrefix.length);
    final matches = state.party.members
        .asMap()
        .entries
        .where((entry) => entry.value.individualId == individualId)
        .toList(growable: false);
    return matches.length == 1 ? matches.single.key : null;
  }
  const prefix = 'party.';
  if (!targetId.startsWith(prefix)) return null;
  return int.tryParse(targetId.substring(prefix.length));
}

RuntimeServiceFeedback _bagItemFailureFeedback(PlayerItemUseFailure failure) =>
    switch (failure) {
      PlayerItemUseFailure.invalidRequest ||
      PlayerItemUseFailure.invalidTarget =>
        RuntimeServiceFeedback.targetUnavailable,
      PlayerItemUseFailure.unknownDefinition =>
        RuntimeServiceFeedback.bagItemDefinitionInvalid,
      PlayerItemUseFailure.insufficientQuantity =>
        RuntimeServiceFeedback.bagItemMissing,
      PlayerItemUseFailure.wrongTarget =>
        RuntimeServiceFeedback.bagItemWrongTarget,
      PlayerItemUseFailure.noEffect => RuntimeServiceFeedback.bagItemNoEffect,
      PlayerItemUseFailure.unavailableInContext =>
        RuntimeServiceFeedback.bagItemCannotUse,
      PlayerItemUseFailure.unsupportedCapability =>
        RuntimeServiceFeedback.bagItemUnsupported,
      PlayerItemUseFailure.protectedKeyItem =>
        RuntimeServiceFeedback.bagKeyItemProtected,
    };

/// Resolves the real HP and PP caps needed by Bag and healing screens.
///
/// Un [speciesLoader] partagé par l'appelant réutilise son cache d'espèces ;
/// l'instance de repli reconstruite ici relit les fichiers à chaque ouverture
/// d'écran Sac/Soin.
Future<RuntimePlayerServiceRecoveryCaps> loadRuntimePlayerServiceRecoveryCaps({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  RuntimePokemonSpeciesLoader? speciesLoader,
  RuntimeMoveCatalogLoader? moveCatalogLoader,
}) async {
  if (gameState.party.members.isEmpty) {
    return const RuntimePlayerServiceRecoveryCaps(
      maxHpByPartyIndex: <int, int>{},
    );
  }
  final loader = speciesLoader ?? RuntimePokemonSpeciesLoader();
  final maxHpByPartyIndex = <int, int>{};
  final baseStatsByPartyIndex = <int, PokemonBaseStats>{};
  for (var index = 0; index < gameState.party.members.length; index++) {
    final pokemon = gameState.party.members[index];
    final species = await loader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: pokemon.speciesId,
    );
    final baseStats = PokemonBaseStats(
      hp: species.baseHp,
      attack: species.baseAttack,
      defense: species.baseDefense,
      specialAttack: species.baseSpecialAttack,
      specialDefense: species.baseSpecialDefense,
      speed: species.baseSpeed,
    );
    baseStatsByPartyIndex[index] = baseStats;
    final stats = const PokemonStatCalculator().calculate(
      baseStats: baseStats,
      ivs: pokemon.ivs,
      evs: pokemon.evs,
      level: pokemon.level,
      naturePolicy: PokemonNatureStatPolicy.canonical,
      natureId: pokemon.natureId,
    );
    maxHpByPartyIndex[index] = stats.maxHp;
  }
  final catalogs = await loadRuntimePlayerPokemonProgressionCatalogs(
    gameState: gameState,
    projectRootDirectory: projectRootDirectory,
    pokemonConfig: pokemonConfig,
    moveCatalogLoader: moveCatalogLoader,
    speciesLoader: speciesLoader,
  );
  final maxPpByPartyIndex = <int, Map<String, int>>{};
  for (var index = 0; index < gameState.party.members.length; index++) {
    final moveCaps = <String, int>{};
    for (final moveId in gameState.party.members[index].knownMoveIds) {
      final maxPp = catalogs.maxPpByMoveId[moveId];
      if (maxPp != null) moveCaps[moveId] = maxPp;
    }
    maxPpByPartyIndex[index] = Map<String, int>.unmodifiable(moveCaps);
  }
  return RuntimePlayerServiceRecoveryCaps(
    maxHpByPartyIndex: Map<int, int>.unmodifiable(maxHpByPartyIndex),
    baseStatsByPartyIndex: Map<int, PokemonBaseStats>.unmodifiable(
      baseStatsByPartyIndex,
    ),
    maxPpByPartyIndex: Map<int, Map<String, int>>.unmodifiable(
      maxPpByPartyIndex,
    ),
  );
}

final class _ContextualPokemonGiftSession {
  _ContextualPokemonGiftSession(this.request);
  final OpenPokemonGiftInteractionService request;
  final result = Completer<SceneInteractionResult>();
}
