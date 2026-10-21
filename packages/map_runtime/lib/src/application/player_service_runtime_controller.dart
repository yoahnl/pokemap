import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

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
import '../player/runtime_pokemon_summary.dart';

part 'runtime_party_trade_service.dart';
part 'runtime_scene_text_input_service.dart';

final class RuntimePlayerServiceRecoveryCaps {
  const RuntimePlayerServiceRecoveryCaps({
    required this.maxHpByPartyIndex,
    this.maxPpByPartyIndex = const <int, Map<String, int>>{},
  });

  final Map<int, int> maxHpByPartyIndex;
  final Map<int, Map<String, int>> maxPpByPartyIndex;
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
  });

  const PlayerServiceRuntimeResult.completed(GameState gameState)
      : this._(
          status: PlayerServiceRuntimeStatus.completed,
          gameState: gameState,
        );

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
    this.supportsRepel = false,
  })  : _locale = locale,
        _currentGameState = currentGameState,
        _host = host,
        _commitAndSave = commitAndSave,
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
    this.supportsRepel = false,
  })  : _locale = locale,
        _currentGameState = currentGameState,
        _host = null,
        _commitAndSave = commitAndSave,
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
  String? Function()? _pauseMutationUnavailableReason;
  Future<bool> Function(ProjectItemDefinition, GameState)? _escapeRopeConsumer;

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
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Vous ne possédez pas de vélo utilisable.');
    }
    return useBagItemOutsideBattle(
      RuntimePlayerPauseCommand.useBagItem(itemTargetId: item.id));
  }

  void setEscapeRopeConsumer(
    Future<bool> Function(ProjectItemDefinition, GameState) consumer,
  ) {
    _escapeRopeConsumer = consumer;
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
  final String _locale;
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
        final detail = request.stage == PokemonGiftInteractionStage.pokedex
            ? await const RuntimePlayerPauseDataBuilder()
                  .buildPokemonGiftPokedexEntry(
                    gameState: request.projectedState,
                    speciesId: request.pokemon.speciesId,
                    projectRootDirectory: root,
                    pokemonConfig: config,
                    locale: _locale,
                  )
            : null;
        presented = OpenPokemonGiftInteractionService(
          interactionId: request.interactionId,
          interaction: request.interaction,
          stage: request.stage,
          pokemon: request.pokemon,
          projectedState: request.projectedState,
          pokedexDetail: detail,
          speciesName: species.displayName(_locale),
        );
      } else if (request.stage == PokemonGiftInteractionStage.pokedex &&
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
                reason: SceneInteractionCancellationReason.disposed,
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
      return const PlayerServiceRuntimeResult.unavailable(
        'Cette variable de scénario ne contient pas du texte.',
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
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
        safeMessage: 'Cette demande est déjà terminée.',
      );
    }
    final interaction = session.interaction!;
    final result = command.interactionResult;
    if (result != null &&
        (result.requestId != interaction.requestId ||
            result.revision != interaction.revision)) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
        safeMessage: 'La demande a changé avant cette réponse.',
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
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: 'Cette réponse ne contient pas du texte.',
      );
    }
    if (interaction.validateResult(result).isNotEmpty) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: 'La longueur du texte ne respecte pas cette demande.',
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
            safeMessage: 'Le texte n’a pas pu être enregistré.',
          ),
        );
      }
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.failed,
        safeMessage: 'Le texte n’a pas pu être enregistré.',
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
      return const PlayerServiceRuntimeResult.unavailable(
        'Aucune carte régionale n’est disponible.',
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
    FlyBlockReason.underwater =>
      'Remontez à la surface avec Plongée avant d’utiliser Vol.',
    FlyBlockReason.indoor =>
      'Vol est indisponible à l’intérieur et dans les grottes.',
    FlyBlockReason.notVisited => 'Visitez ce lieu avant de pouvoir y voler.',
    FlyBlockReason.missingMove =>
      'Un Pokémon en état de combattre doit connaître Vol.',
    FlyBlockReason.locked =>
      'Vol n’est pas encore débloqué dans votre progression.',
    FlyBlockReason.unsupportedMap =>
      'Vol est disponible uniquement sur les cartes 2D natives.',
    FlyBlockReason.invalidSpawn =>
      'Le point d’arrivée de ce lieu est indisponible.',
    FlyBlockReason.invalidDestination ||
    null => 'Cette destination est indisponible pour Vol.',
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
        session.message = 'Cette destination est indisponible pour Vol.';
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
          : 'Voler vers ${point!.label} ?';
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
            ? 'Le transfert a échoué et sa restauration ne peut pas être confirmée. Relancez la partie.'
            : 'Le Vol a été annulé. La partie a été conservée.';
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
        summaryBuilder: await _resolvePokemonSummaryBuilder(state),
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
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'L’équipe est occupée pour le moment.',
      );
    }
    final state = _currentGameState();
    final firstIndex = _partyIndexFromTarget(state, command.partyTargetId);
    if (firstIndex == null) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Cette cible n’est plus disponible.',
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
        successMessage = 'Nouveau Pokémon de tête enregistré.';
      case RuntimePlayerPauseCommandKind.reorderPartyMember:
        final secondTarget = command.secondPartyTargetId;
        final secondIndex = secondTarget == null
            ? null
            : _partyIndexFromTarget(state, secondTarget);
        if (secondIndex == null) {
          return const RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: 'Cette cible n’est plus disponible.',
          );
        }
        result = operations.swapPartyMembers(
          state: state,
          firstIndex: firstIndex,
          secondIndex: secondIndex,
        );
        successMessage = 'Équipe réordonnée et progression sauvegardée.';
      case RuntimePlayerPauseCommandKind.useBagItem:
      case RuntimePlayerPauseCommandKind.equipHeldItem:
      case RuntimePlayerPauseCommandKind.unequipHeldItem:
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Cette commande ne concerne pas l’équipe.',
        );
    }
    if (!result.isSuccess) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Cette cible n’est plus disponible.',
      );
    }
    try {
      await _commitAndSave(result.state);
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.accepted,
        safeMessage: successMessage,
      );
    } catch (_) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: 'L’équipe n’a pas pu être réordonnée ni sauvegardée.',
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
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Le sac est occupé pour le moment.',
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
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Le sac est occupé pour le moment.',
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
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Cette cible n’est plus disponible.',
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
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'La définition de cet objet est absente ou invalide.',
      );
    }
    if (command.kind == RuntimePlayerPauseCommandKind.useBagItem &&
        definition.uses.any((use) => use.effect is ProjectItemFishingEffectDefinition)) {
      final consumer = _fishingConsumer;
      if (consumer == null) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'La pêche est disponible uniquement dans un runtime 2D compatible.',
        );
      }
      if (_currentGameState() != state || _pauseMutationRefusal() != null) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'La pêche n’est pas disponible pour le moment.',
        );
      }
      try {
        final reason = await consumer(definition, state);
        return RuntimePlayerPauseCommandResult(
          status: reason == null ? RuntimePlayerPauseCommandStatus.accepted
              : RuntimePlayerPauseCommandStatus.unavailable,
          resumeGameplay: reason == null,
          safeMessage: switch (reason) {
            null => 'Préparation de la pêche.',
            FishingBlockReason.unsupportedMap => 'La pêche nécessite une carte 2D compatible.',
            FishingBlockReason.invalidItem => 'Cet objet n’est pas une canne utilisable.',
            FishingBlockReason.insufficientQuantity => 'Cette canne n’est plus dans le sac.',
            FishingBlockReason.notWater => 'Placez-vous face à l’eau pour pêcher.',
            FishingBlockReason.noEncounterSource || FishingBlockReason.encounterUnavailable =>
              'Aucune rencontre de pêche n’est disponible ici avec cette canne.',
            FishingBlockReason.checkpointFailed => 'La descente du vélo n’a pas pu être sauvegardée.',
            _ => 'La pêche n’est pas disponible pour le moment.',
          },
        );
      } on Object {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.failed,
          safeMessage: 'La pêche n’a pas pu commencer.',
        );
      }
    }
    if (command.kind == RuntimePlayerPauseCommandKind.useBagItem &&
        definition.uses.any((use) => use.effect is ProjectItemBicycleEffectDefinition)) {
      final consumer = _bicycleConsumer;
      if (consumer == null) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Le vélo est disponible uniquement dans un runtime 2D compatible.');
      }
      if (_currentGameState() != state || _pauseMutationRefusal() != null) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Le vélo n’est pas disponible pour le moment.');
      }
      _setInputLocked(true);
      try {
        final applied = await consumer(definition, state);
        return RuntimePlayerPauseCommandResult(
          status: applied ? RuntimePlayerPauseCommandStatus.accepted
              : RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: applied ? 'Changement de déplacement sauvegardé.'
              : 'Le vélo est indisponible ici, ses animations sont incomplètes ou la sauvegarde a échoué.');
      } on Object {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.failed,
          safeMessage: 'Le changement de déplacement n’a pas pu être sauvegardé.');
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
        return const RuntimePlayerPauseCommandResult(status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'La Corde Sortie est disponible uniquement dans un runtime 2D compatible.');
      }
      if (_currentGameState() != state ||
          _pauseMutationRefusal() != null) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'La Corde Sortie n’est pas disponible pour le moment.',
        );
      }
      _setInputLocked(true);
      try {
        final applied = await consumer(definition, state);
        return RuntimePlayerPauseCommandResult(
          status: applied
              ? RuntimePlayerPauseCommandStatus.accepted
              : RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: applied
              ? 'Vous êtes de retour à l’entrée. Progression sauvegardée.'
              : 'La sortie est inconnue, interdite ou bloquée. La Corde Sortie est conservée.',
        );
      } on Object {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.failed,
          safeMessage: 'Le retour n’a pas pu être effectué ni sauvegardé.',
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
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'La Repousse n’est pas disponible dans ce mode de jeu.',
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
                ? 'Une Repousse est déjà active.'
                : _bagItemFailureMessage(result.failure!),
          );
        }
        final refusal = await _commitPauseMutation(result.state);
        if (refusal != null) return refusal;
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.accepted,
          safeMessage: 'La Repousse est active. Progression sauvegardée.',
        );
      } catch (_) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.failed,
          safeMessage: 'La Repousse n’a pas pu être utilisée ni sauvegardée.',
        );
      }
    }
    if (partyIndex == null || _currentGameState() != state) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Cette cible n’est plus disponible.',
      );
    }
    if (command.kind == RuntimePlayerPauseCommandKind.equipHeldItem) {
      final heldItemResolution = resolveRuntimeHeldItemEffect(
        itemCatalog: itemCatalog,
        itemId: definition.id,
      );
      switch (heldItemResolution.status) {
        case RuntimeHeldItemSupportStatus.invalidDefinition:
          return const RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: 'La définition de cet objet est absente ou invalide.',
          );
        case RuntimeHeldItemSupportStatus.passive:
          return const RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: 'Cet objet ne possède aucun effet tenu.',
          );
        case RuntimeHeldItemSupportStatus.unsupported:
          return const RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage:
                'Cet effet d’objet tenu n’est pas pris en charge en combat.',
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
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Cet objet ne peut pas être utilisé ici.',
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
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Cet objet ne peut pas être utilisé ici.',
      );
    }
    if (partyIndex >= state.party.members.length) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Cette cible n’est plus disponible.',
      );
    }
    try {
      final caps = await _loadRecoveryCaps(state);
      final maxHp = caps.maxHpByPartyIndex[partyIndex];
      if (maxHp == null || maxHp <= 0) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Les données de la cible sont incomplètes.',
        );
      }
      final result = PlayerItemUseService(snapshot: itemCatalog).use(
        PlayerItemUseRequest(
          state: state,
          itemId: command.itemTargetId,
          context: ProjectItemUseContext.overworld,
          partyIndex: partyIndex,
          maxHp: maxHp,
          moveId: command.moveTargetId,
          maxPpByMoveId:
              caps.maxPpByPartyIndex[partyIndex] ?? const <String, int>{},
        ),
      );
      if (!result.isSuccess) {
        return RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: _bagItemFailureMessage(result.failure!),
        );
      }
      final refusal = await _commitPauseMutation(result.state);
      if (refusal != null) return refusal;
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.accepted,
        safeMessage: 'Objet utilisé et progression sauvegardée.',
      );
    } catch (_) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: 'L’objet n’a pas pu être utilisé ni sauvegardé.',
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
            'Cette cible ou cet objet n’est plus disponible.',
          HeldItemTransferFailure.itemMissing =>
            'Cet objet n’est plus présent dans le sac.',
          HeldItemTransferFailure.noHeldItem =>
            'Ce Pokémon ne tient aucun objet.',
          HeldItemTransferFailure.alreadyEquipped =>
            'Ce Pokémon tient déjà cet objet.',
          HeldItemTransferFailure.quantityOverflow =>
            'Le sac ne peut pas récupérer l’objet actuellement tenu.',
          HeldItemTransferFailure.bagFull =>
            'Le sac est plein pour cet objet. Libérez de la place avant de le récupérer.',
          HeldItemTransferFailure.missingItemCatalog ||
          HeldItemTransferFailure.unknownItem =>
            'Le catalogue des objets ne permet pas de vérifier la place dans le sac.',
        },
      );
    }
    try {
      final refusal = await _commitPauseMutation(result.state);
      if (refusal != null) return refusal;
      return RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.accepted,
        safeMessage: result.status == HeldItemTransferStatus.unequipped
            ? 'Objet retiré et progression sauvegardée.'
            : 'Objet tenu modifié et progression sauvegardée.',
      );
    } catch (_) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: 'L’objet tenu n’a pas pu être modifié ni sauvegardé.',
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
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Cette cible n’est plus disponible.',
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
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Ce Pokémon n’est pas compatible avec cette machine.',
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
                ? 'Capacité remplacée et progression sauvegardée.'
                : 'Capacité apprise et progression sauvegardée.',
          );
        case PokemonMoveMachineUseStatus.replacementRequired:
          return const RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: 'Choisissez une capacité à oublier.',
          );
        case PokemonMoveMachineUseStatus.declined:
          return const RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: 'Apprentissage annulé.',
          );
        case PokemonMoveMachineUseStatus.failed:
          return const RuntimePlayerPauseCommandResult(
            status: RuntimePlayerPauseCommandStatus.unavailable,
            safeMessage: 'Cette machine ne peut pas être utilisée ici.',
          );
      }
    } catch (error, stackTrace) {
      debugPrint('[move_machine] use failed: $error\n$stackTrace');
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: 'La capacité n’a pas pu être apprise ni sauvegardée.',
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
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Cet objet ne peut pas être utilisé ici.',
      );
    }
    try {
      final pokemon = state.party.members[partyIndex];
      final heldPolicy = resolveRuntimeEvolutionHeldItemPolicy(itemCatalog);
      if (!heldPolicy.recognizes(pokemon.heldItemId) || heldPolicy.preventsEvolution(pokemon.heldItemId)) {
        return const RuntimePlayerPauseCommandResult(status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'L’objet tenu ne permet pas cette évolution.');
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
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Cet objet ne provoque aucune évolution ici.',
        );
      }
      if (eligible.length > 1) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage:
              'Plusieurs évolutions sont possibles pour cette combinaison.',
        );
      }
      final caps = await _loadRecoveryCaps(state);
      final maxHp = caps.maxHpByPartyIndex[partyIndex];
      if (maxHp == null || maxHp <= 0) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Les données de la cible sont incomplètes.',
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
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Cet objet ne provoque aucune évolution ici.',
        );
      }
      final refusal = await _commitPauseMutation(result.state);
      if (refusal != null) return refusal;
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.accepted,
        safeMessage: 'Évolution réussie et progression sauvegardée.',
      );
    } catch (_) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.failed,
        safeMessage: 'L’évolution n’a pas pu être appliquée ni sauvegardée.',
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
      final session = _ContextualHealSession(
        request: request,
        gameState: state,
        recoveryCaps: caps,
        displayEntity: _resolveHealDisplayEntity(request, state),
      );
      _healSession = session;
      if (!request.requiresConfirmation) {
        if (!_hasAllHealCaps(session)) {
          return const PlayerServiceRuntimeResult.unavailable(
            'Les données de soin de l’équipe sont incomplètes.',
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
    final snapshot = _buildHealSnapshot(session, stage: RuntimeWorldServiceStage.applying,
        safeMessage: 'Soin en cours…');
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
        return 'L’affichage du soin n’est pas disponible sur cette carte.';
      }
    }
    final missingCapabilities =
        request.requiredCapabilities.difference(_grantedCapabilities);
    if (missingCapabilities.isNotEmpty) {
      return 'Ce service n’est pas pris en charge par ce jeu.';
    }
    final condition = request.availabilityCondition;
    if (condition != null &&
        !const ScriptConditionEvaluator().evaluate(
          condition,
          state,
          context: _conditionContext,
        )) {
      return 'Ce service n’est pas disponible pour le moment.';
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
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.failed,
        safeMessage: 'Le service joueur est fermé.',
      );
    }
    final snapshot = _worldServiceSnapshot;
    if (snapshot == null) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: 'Aucun service contextuel n’est ouvert.',
      );
    }
    if (command.snapshotRevision != snapshot.revision) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
        safeMessage: 'Le service a changé avant cette action.',
      );
    }
    if (command.interactionResult != null &&
        snapshot.request is! OpenTextInputService && snapshot.request is! OpenSceneTextInteractionService && snapshot.request is! OpenPokemonGiftInteractionService) {
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.stale,
        safeMessage: 'Cette réponse appartient à une autre demande.',
      );
    }
    if (!snapshot.isActionEnabled(command.action)) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: snapshot.unavailableReasonFor(command.action) ??
            'Cette action n’est pas disponible.',
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
    final trade = _partyTradeSession;
    if (trade != null) return _dispatchPartyTrade(trade, command);
    final text = _textSession;
    if (text != null) return _dispatchText(text, command);
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.unavailable,
      safeMessage: 'Ce service n’accepte pas cette action.',
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
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: 'Cette box n’est plus disponible.',
          );
        }
        session.selectedBoxId = boxId;
        _publishWorldService(_buildPcSnapshot(session));
      case RuntimeWorldServiceAction.deposit:
      case RuntimeWorldServiceAction.withdraw:
        final targetId = command.targetId;
        final target = targetId == null ? null : session.targets[targetId];
        if (target == null || target.action != command.action) {
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: 'Ce Pokémon n’est plus disponible.',
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
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: 'Ce Pokémon n’est plus disponible.',
          );
        }
        // Le null-check est nécessaire au `!` du transfert ; l'EXISTENCE de la
        // box, elle, est déjà typée par l'opération pure (invalidBoxId → « Box
        // inconnue. »). La re-vérifier ici était redondant — mesuré par
        // sabotage : la retirer ne changeait aucun comportement observable.
        if (destinationBoxId == null) {
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: 'Cette box n’est plus disponible.',
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
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: 'Cet échange n’est plus disponible.',
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
      case RuntimeWorldServiceAction.showPurchases:
      case RuntimeWorldServiceAction.showSales:
      case RuntimeWorldServiceAction.decreaseQuantity:
      case RuntimeWorldServiceAction.increaseQuantity:
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
          safeMessage: 'Cette commande ne concerne pas le PC.',
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
      final message = _pcFailureMessage(result.failure!);
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
        safeMessage: 'Enregistrement du PC…',
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
            RuntimeWorldServiceAction.deposit => 'Pokémon déposé dans la box.',
            RuntimeWorldServiceAction.withdraw => 'Pokémon ajouté à l’équipe.',
            RuntimeWorldServiceAction.swap => 'Échange effectué.',
            RuntimeWorldServiceAction.move => 'Pokémon déplacé de box.',
            _ => throw StateError('Unsupported PC transfer action.'),
          },
        ),
      );
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.accepted,
      );
    } catch (error) {
      const message = 'La modification du PC n’a pas pu être enregistrée.';
      _publishWorldService(
        _buildPcSnapshot(session, safeMessage: message),
      );
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.failed,
        safeMessage: message,
      );
    }
  }

  /// Charge les catalogues nécessaires à la fiche canonique.
  ///
  /// Retourne `null` si le projet ne les expose pas : le PC retombe alors sur
  /// ses champs bruts, ce qui reste préférable à un écran vide.
  Future<RuntimePokemonSummaryBuilder?> _resolvePokemonSummaryBuilder(
    GameState state,
  ) async {
    final projectRootDirectory = _projectRootDirectory;
    final pokemonConfig = _pokemonConfig;
    if (projectRootDirectory == null || pokemonConfig == null) {
      return null;
    }
    final pokemon = <PlayerPokemon>[
      ...state.party.members,
      for (final box in state.pokemonStorage.normalized().boxes) ...box.pokemon,
    ];
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
    return runtimePokemonSummaryBuilderFor(
      locale: _locale,
      speciesLabelFor: (speciesId) =>
          _localizedSpeciesName(speciesById[speciesId], speciesId),
      calculatedStatsFor: (entry) =>
          _calculatedStatsFor(speciesById[entry.speciesId], entry),
      itemLabelFor: (itemId) => itemCatalog.definitionFor(itemId)?.displayName,
      moveFor: moveCatalog?.lookup,
    );
  }

  String _localizedSpeciesName(
    RuntimePokemonSpecies? species,
    String speciesId,
  ) {
    if (species == null) {
      return runtimePokemonHumanizeId(speciesId);
    }
    return resolveLocalizedName(
      names: species.names,
      locale: _locale,
      fallback: runtimePokemonHumanizeId(speciesId),
    );
  }

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
      targets[targetId] = _PcTransferTarget(
        action: RuntimeWorldServiceAction.deposit,
        index: index,
        individualId: pokemon.individualId,
      );
      party.add(
        RuntimePcPokemonSnapshot(
          targetId: targetId,
          label: _pokemonDisplayLabel(pokemon),
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
              result.isSuccess ? null : _pcFailureMessage(result.failure!),
          summary: session.summaryBuilder?.build(pokemon, targetId: targetId),
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
      targets[targetId] = _PcTransferTarget(
        action: RuntimeWorldServiceAction.withdraw,
        index: index,
        boxId: selectedBox.id,
        individualId: pokemon.individualId,
      );
      stored.add(
        RuntimePcPokemonSnapshot(
          targetId: targetId,
          label: _pokemonDisplayLabel(pokemon),
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
              result.isSuccess ? null : _pcFailureMessage(result.failure!),
          summary: session.summaryBuilder?.build(pokemon, targetId: targetId),
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
        title: 'PC Pokémon',
        message: 'Organisez votre équipe et vos boxes.',
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
                      'Aucun Pokémon ne peut être déposé.',
                ),
              if (canWithdraw)
                const RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.withdraw,
                )
              else
                RuntimeWorldServiceActionAvailability.disabled(
                  RuntimeWorldServiceAction.withdraw,
                  reason: stored.firstOrNull?.unavailableReason ??
                      'Aucun Pokémon ne peut être retiré.',
                ),
              if (canSwap)
                const RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.swap,
                )
              else
                RuntimeWorldServiceActionAvailability.disabled(
                  RuntimeWorldServiceAction.swap,
                  reason: 'Aucun échange valide n’est disponible.',
                ),
              if (stored.isNotEmpty && boxes.length > 1)
                const RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.move,
                )
              else
                RuntimeWorldServiceActionAvailability.disabled(
                  RuntimeWorldServiceAction.move,
                  reason: stored.isEmpty
                      ? 'Aucun Pokémon à déplacer dans cette box.'
                      : 'Aucune autre box de destination.',
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
              session.failure = StateError('The healing session changed before commit.');
              _publishWorldService(_buildHealSnapshot(session, stage: RuntimeWorldServiceStage.failed,
                  safeMessage: 'Le soin a été interrompu avant son enregistrement.'));
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
            ..failure = null;
          if (!_disposed) {
            _publishWorldService(
            _buildHealSnapshot(
              session,
              stage: RuntimeWorldServiceStage.completed,
              safeMessage: recovered == session.initialGameState
                  ? 'Votre équipe est déjà entièrement soignée.'
                  : 'Votre équipe est entièrement soignée.',
            ),
            );
          }
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.accepted,
          );
        } catch (error) {
          session.failure = error;
          const message = 'Le soin n’a pas pu être enregistré.';
          if (!_disposed) {
            _publishWorldService(
            _buildHealSnapshot(
              session,
              stage: RuntimeWorldServiceStage.failed,
              safeMessage: message,
            ),
            );
          }
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.failed,
            safeMessage: message,
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
      case RuntimeWorldServiceAction.showPurchases:
      case RuntimeWorldServiceAction.showSales:
      case RuntimeWorldServiceAction.decreaseQuantity:
      case RuntimeWorldServiceAction.increaseQuantity:
      case RuntimeWorldServiceAction.deposit:
      case RuntimeWorldServiceAction.withdraw:
      case RuntimeWorldServiceAction.swap:
      case RuntimeWorldServiceAction.move:
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
          safeMessage: 'Cette commande ne concerne pas le soin.',
        );
    }
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  RuntimeWorldServiceSnapshot _buildHealSnapshot(
    _ContextualHealSession session, {
    RuntimeWorldServiceStage stage = RuntimeWorldServiceStage.active,
    String? safeMessage,
  }) {
    final members = <RuntimeHealPartyMemberSnapshot>[];
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
          label: _shopItemLabel(member.speciesId),
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
        title: 'Centre Pokémon',
        message: stage == RuntimeWorldServiceStage.completed
            ? 'Le soin est terminé.'
            : 'Restaurer les PV, les PP et les altérations de statut.',
        members: members,
        wasHealed: session.wasHealed,
        display: stage == RuntimeWorldServiceStage.applying &&
                session.request.displayEntityId != null && members.isNotEmpty
            ? RuntimeHealingDisplaySnapshot(mapId: session.gameState.currentMapId,
                entityId: session.request.displayEntityId!, memberCount: members.length)
            : null,
      ),
      safeMessage: safeMessage,
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
                    ? 'Aucun Pokémon dans l’équipe.'
                    : 'Les données de soin de l’équipe sont incomplètes.',
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
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: 'Cet objet n’est plus disponible.',
          );
        }
        session
          ..selectedItemId = targetId
          ..quantity = 1;
        _publishWorldService(_buildShopSnapshot(session));
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
        return const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
          safeMessage: 'Cette commande ne concerne pas la Boutique.',
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
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: 'Sélectionnez un objet.',
      );
    }
    final result = _previewShopPurchase(session, itemId, quantity);
    if (!result.isSuccess) {
      final message = _shopFailureMessage(result.failure!);
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
            ? 'Achat effectué. Cadeau : ${result.bonusQuantity} × ${_shopItemLabel(result.bonusItemId!)}.'
            : 'Achat effectué.',
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
      return const RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: 'Sélectionnez un objet.',
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
      final message = _shopSaleFailureMessage(result.failure!);
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
        safeMessage: 'Vente effectuée.',
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
        ? 'Cette boutique est fermée.'
        : selected == null
            ? session.mode == RuntimeShopMode.sell
                ? 'Le sac est vide.'
                : 'Cette boutique est vide.'
            : !selected.canTransact
                ? selected.unavailableReason
                : session.mode == RuntimeShopMode.sell
                    ? selected.ownedQuantity < session.quantity
                        ? 'Quantité possédée insuffisante.'
                        : null
                    : purchaseFailure == null
                        ? null
                        : _shopFailureMessage(purchaseFailure);
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
                ? 'Le sac est vide.'
                : 'Cette boutique est vide.',
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
            reason: 'La quantité minimale est 1.',
          ),
        if (selected != null &&
            session.quantity < _maximumShopQuantity(session))
          const RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.increaseQuantity,
          )
        else
          RuntimeWorldServiceActionAvailability.disabled(
            RuntimeWorldServiceAction.increaseQuantity,
            reason: 'Quantité maximale atteinte.',
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
                    ? 'Vente indisponible.'
                    : 'Achat indisponible.'),
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
            ? _shopFailureMessage(ShopPurchaseFailure.bagFull)
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
          final unavailableReason = _shopSaleUnavailableReason(
            bagEntry: bagEntry,
            sellPrice: sellPrice,
            itemCatalog: session.itemCatalog,
          );
          return RuntimeShopEntrySnapshot(
            itemId: bagEntry.itemId,
            label: _shopItemLabel(bagEntry.itemId),
            unitPrice: sellPrice ?? 0,
            ownedQuantity: bagEntry.quantity,
            canTransact: unavailableReason == null,
            unavailableReason: unavailableReason,
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
    this.displayEntity,
  })  : initialGameState = gameState,
        gameState = gameState;

  final OpenHealService request;
  final GameState initialGameState;
  final MapEntity? displayEntity;
  final RuntimePlayerServiceRecoveryCaps recoveryCaps;
  final result = Completer<PlayerServiceRuntimeResult>();
  Future<void>? pendingCommit;
  GameState? pendingState;
  GameState gameState;
  bool wasHealed = false;
  Object? failure;
}

final class _ContextualPcSession {
  _ContextualPcSession({
    required this.request,
    required this.gameState,
    required this.selectedBoxId,
    this.summaryBuilder,
  });

  /// Résolu une fois à l'ouverture : `_buildPcSnapshot` est synchrone alors que
  /// les catalogues se chargent en asynchrone.
  final RuntimePokemonSummaryBuilder? summaryBuilder;

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

String _shopFailureMessage(ShopPurchaseFailure failure) => switch (failure) {
  ShopPurchaseFailure.invalidRequest => 'Achat invalide.',
  ShopPurchaseFailure.unknownItem => 'Objet inconnu.',
  ShopPurchaseFailure.insufficientFunds => 'Fonds insuffisants.',
  ShopPurchaseFailure.outOfStock => 'Stock insuffisant.',
  ShopPurchaseFailure.ownershipLimit =>
    'La quantité maximale possédée est atteinte.',
  ShopPurchaseFailure.bagFull =>
    'Le sac est plein pour cet achat. Libérez de la place avant de réessayer.',
  ShopPurchaseFailure.shopClosed => 'Cette boutique est fermée.',
  ShopPurchaseFailure.shopStateChanged =>
    'La boutique a changé. Le catalogue a été actualisé.',
};

String _shopSaleFailureMessage(ShopSaleFailure failure) => switch (failure) {
      ShopSaleFailure.invalidRequest => 'Vente invalide.',
      ShopSaleFailure.unknownItem => 'Objet inconnu.',
      ShopSaleFailure.insufficientQuantity => 'Quantité possédée insuffisante.',
      ShopSaleFailure.unsellable => 'Cet objet ne peut pas être vendu.',
      ShopSaleFailure.keyItem => 'Les objets importants sont invendables.',
      ShopSaleFailure.shopClosed => 'Cette boutique est fermée.',
      ShopSaleFailure.shopStateChanged =>
        'La boutique a changé. Le catalogue a été actualisé.',
    };

String? _shopSaleUnavailableReason({
  required BagEntry bagEntry,
  required int? sellPrice,
  required ItemCatalogSnapshot itemCatalog,
}) {
  if (itemCatalog.definitionFor(bagEntry.itemId)?.tags.contains('key-item') ??
      false) {
    return 'Les objets importants sont invendables.';
  }
  if (sellPrice == null || sellPrice <= 0) {
    return 'Cette boutique ne reprend pas cet objet.';
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
  return nickname.isEmpty ? _shopItemLabel(pokemon.speciesId) : nickname;
}

String _pcFailureMessage(PlayerStorageFailure failure) => switch (failure) {
      PlayerStorageFailure.invalidRequest => 'Opération PC invalide.',
      PlayerStorageFailure.invalidPartyIndex => 'Slot d’équipe invalide.',
      PlayerStorageFailure.invalidBoxId => 'Box inconnue.',
      PlayerStorageFailure.invalidBoxIndex => 'Slot de box invalide.',
      PlayerStorageFailure.partyFull => 'L’équipe est pleine.',
      PlayerStorageFailure.boxFull => 'Cette box est pleine.',
      PlayerStorageFailure.storageFull => 'Le PC est plein.',
      PlayerStorageFailure.lastUsablePokemon =>
        'Impossible de déposer le dernier Pokémon utilisable.',
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

String _bagItemFailureMessage(PlayerItemUseFailure failure) =>
    switch (failure) {
      PlayerItemUseFailure.invalidRequest ||
      PlayerItemUseFailure.invalidTarget =>
        'Cette cible n’est plus disponible.',
      PlayerItemUseFailure.unknownDefinition =>
        'La définition de cet objet est absente ou invalide.',
      PlayerItemUseFailure.insufficientQuantity =>
        'Vous ne possédez plus cet objet.',
      PlayerItemUseFailure.wrongTarget =>
        'Cet objet ne convient pas à cette cible.',
      PlayerItemUseFailure.noEffect => 'Cet objet n’aurait aucun effet.',
      PlayerItemUseFailure.unavailableInContext =>
        'Cet objet ne peut pas être utilisé ici.',
      PlayerItemUseFailure.unsupportedCapability =>
        'Cette capacité d’objet n’est pas encore prise en charge.',
      PlayerItemUseFailure.protectedKeyItem =>
        'Cet objet important ne peut pas être consommé.',
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
  for (var index = 0; index < gameState.party.members.length; index++) {
    final pokemon = gameState.party.members[index];
    final species = await loader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: pokemon.speciesId,
    );
    final stats = const PokemonStatCalculator().calculate(
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
    maxPpByPartyIndex:
        Map<int, Map<String, int>>.unmodifiable(maxPpByPartyIndex),
  );
}

final class _ContextualPokemonGiftSession {
  _ContextualPokemonGiftSession(this.request);
  final OpenPokemonGiftInteractionService request;
  final result = Completer<SceneInteractionResult>();
}
