import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../player/runtime_player_pause_data.dart';
import '../player/runtime_world_service_models.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_move_machine_loader.dart';
import 'runtime_item_catalog_loader.dart';
import 'runtime_player_pokemon_progression_hydrator.dart';
import 'runtime_pokemon_evolution_loader.dart';
import 'runtime_pokemon_species_loader.dart';

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
  });

  final OpenShopService? worldRequest;
  final ShopDefinition shop;
  final ResolvedShopState resolvedState;
  final ScriptEvaluationContext conditionContext;
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
    ScriptEvaluationContext conditionContext = const ScriptEvaluationContext(),
    Set<String> grantedCapabilities = const <String>{},
    String? projectRootDirectory,
    ProjectPokemonConfig? pokemonConfig,
    RuntimePokemonEvolutionLoader? evolutionLoader,
    RuntimeMoveMachineLoader? moveMachineLoader,
    RuntimePokemonSpeciesLoader? pokemonSpeciesLoader,
    ItemCatalogSnapshot? itemCatalog,
    RuntimeItemCatalogLoader itemCatalogLoader =
        const RuntimeItemCatalogLoader(),
  })  : _currentGameState = currentGameState,
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
    ScriptEvaluationContext conditionContext = const ScriptEvaluationContext(),
    Set<String> grantedCapabilities = const <String>{},
    String? projectRootDirectory,
    ProjectPokemonConfig? pokemonConfig,
    RuntimePokemonEvolutionLoader? evolutionLoader,
    RuntimeMoveMachineLoader? moveMachineLoader,
    RuntimePokemonSpeciesLoader? pokemonSpeciesLoader,
    ItemCatalogSnapshot? itemCatalog,
    RuntimeItemCatalogLoader itemCatalogLoader =
        const RuntimeItemCatalogLoader(),
  })  : _currentGameState = currentGameState,
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
  final PlayerServiceInputLockSetter _setInputLocked;
  final PlayerServiceRecoveryCapsLoader _loadRecoveryCaps;
  final ScriptEvaluationContext _conditionContext;
  final Set<String> _grantedCapabilities;
  final String? _projectRootDirectory;
  final ProjectPokemonConfig? _pokemonConfig;
  ItemCatalogSnapshot? _itemCatalog;
  final RuntimeItemCatalogLoader _itemCatalogLoader;
  final RuntimePokemonEvolutionLoader _evolutionLoader;
  final RuntimeMoveMachineLoader _moveMachineLoader;
  final RuntimePokemonSpeciesLoader _pokemonSpeciesLoader;
  final _worldServiceSnapshots =
      StreamController<RuntimeWorldServiceSnapshot?>.broadcast();
  bool _active = false;
  bool _disposed = false;
  RuntimeWorldServiceSnapshot? _worldServiceSnapshot;
  _ContextualShopSession? _shopSession;
  _ContextualHealSession? _healSession;
  _ContextualPcSession? _pcSession;

  bool get isActive => _active;

  @override
  RuntimeWorldServiceSnapshot? get worldServiceSnapshot =>
      _worldServiceSnapshot;

  @override
  Stream<RuntimeWorldServiceSnapshot?> get worldServiceSnapshots =>
      _worldServiceSnapshots.stream;

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
      (state, caps) {
        final normalizedShop = shop.normalized();
        final resolvedState = const ShopStateResolver().resolve(
          shop: normalizedShop,
          gameState: state,
          conditionContext: _conditionContext,
        );
        final serviceRequest = PlayerServiceShopRequest(
          gameState: state,
          recoveryCaps: caps,
          worldRequest: worldRequest,
          shop: normalizedShop,
          resolvedState: resolvedState,
          conditionContext: _conditionContext,
        );
        final host = _host;
        return host == null
            ? _openContextualShop(serviceRequest)
            : host.openShop(serviceRequest);
      },
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

  Future<RuntimePlayerPauseCommandResult> useBagItemOutsideBattle(
    RuntimePlayerPauseCommand command,
  ) async {
    if (_disposed || _active) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Le sac est occupé pour le moment.',
      );
    }
    final partyIndex = _partyIndexFromTarget(command.partyTargetId);
    if (partyIndex == null) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Cette cible n’est plus disponible.',
      );
    }
    final state = _currentGameState();
    final itemCatalog = await _resolveItemCatalog();
    final definition = itemCatalog.definitionFor(command.itemTargetId);
    if (definition == null) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'La définition de cet objet est absente ou invalide.',
      );
    }
    if (definition.machine != null) {
      final moveMachineResult = await _useMoveMachineOutsideBattle(
        state: state,
        itemId: command.itemTargetId,
        machine: definition.machine!,
        partyIndex: partyIndex,
        replacementMoveId: command.moveTargetId,
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
      await _commitAndSave(result.state);
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

  Future<RuntimePlayerPauseCommandResult?> _useMoveMachineOutsideBattle({
    required GameState state,
    required String itemId,
    required ProjectMoveMachineItemDefinition machine,
    required int partyIndex,
    required String? replacementMoveId,
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
        partyIndex: partyIndex,
        candidate: candidate,
        decision: decision,
      );
      switch (result.status) {
        case PokemonMoveMachineUseStatus.learned:
        case PokemonMoveMachineUseStatus.replaced:
          await _commitAndSave(result.state);
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
    } catch (_) {
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
      final result = const PokemonEvolutionItemOperations().useItem(
        state,
        itemId: itemId,
        partyIndex: partyIndex,
        candidate: eligible.single,
        sourceMaxHp: maxHp,
      );
      if (!result.isSuccess) {
        return const RuntimePlayerPauseCommandResult(
          status: RuntimePlayerPauseCommandStatus.unavailable,
          safeMessage: 'Cet objet ne provoque aucune évolution ici.',
        );
      }
      await _commitAndSave(result.state);
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
      final session = _ContextualHealSession(
        request: request,
        gameState: state,
        recoveryCaps: caps,
      );
      if (!request.requiresConfirmation) {
        if (!_hasAllHealCaps(session)) {
          return const PlayerServiceRuntimeResult.unavailable(
            'Les données de soin de l’équipe sont incomplètes.',
          );
        }
        final recovered = _recoverHealSession(session);
        if (recovered != state) {
          await _commitAndSave(recovered);
        }
        return PlayerServiceRuntimeResult.completed(recovered);
      }
      _healSession = session;
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

  String? _worldRequestUnavailableReason(
    RuntimeWorldServiceRequest request,
    GameState state,
  ) {
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
  ) {
    final session = _ContextualShopSession(
      request: request,
      gameState: request.gameState,
    );
    _shopSession = session;
    _publishWorldService(_buildShopSnapshot(session));
    return session.result.future.whenComplete(() {
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
    if (!snapshot.isActionEnabled(command.action)) {
      return RuntimeWorldServiceCommandResult(
        status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: snapshot.unavailableReasonFor(command.action) ??
            'Cette action n’est pas disponible.',
      );
    }
    final shop = _shopSession;
    if (shop != null) return _dispatchShop(shop, command);
    final heal = _healSession;
    if (heal != null) return _dispatchHeal(heal, command);
    final pc = _pcSession;
    if (pc != null) return _dispatchPc(pc, command);
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
  }) async {
    const operations = PlayerStorageOperations();
    final result = switch (action) {
      RuntimeWorldServiceAction.deposit => operations.deposit(
          state: session.gameState,
          partyIndex: target.index,
          boxId: session.selectedBoxId,
        ),
      RuntimeWorldServiceAction.withdraw => operations.withdraw(
          state: session.gameState,
          boxId: target.boxId!,
          boxIndex: target.index,
        ),
      RuntimeWorldServiceAction.swap => operations.swapPartyWithBox(
          state: session.gameState,
          partyIndex: secondaryTarget!.index,
          boxId: target.boxId!,
          boxIndex: target.index,
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
      final targetId = 'party-slot-$index';
      targets[targetId] = _PcTransferTarget(
        action: RuntimeWorldServiceAction.deposit,
        index: index,
      );
      party.add(
        RuntimePcPokemonSnapshot(
          targetId: targetId,
          label: _pokemonDisplayLabel(pokemon),
          speciesId: pokemon.speciesId,
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
      final targetId = 'box-slot-${selectedBox.id}-$index';
      targets[targetId] = _PcTransferTarget(
        action: RuntimeWorldServiceAction.withdraw,
        index: index,
        boxId: selectedBox.id,
      );
      stored.add(
        RuntimePcPokemonSnapshot(
          targetId: targetId,
          label: _pokemonDisplayLabel(pokemon),
          speciesId: pokemon.speciesId,
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
        _publishWorldService(
          _buildHealSnapshot(
            session,
            stage: RuntimeWorldServiceStage.applying,
            safeMessage: 'Soin en cours…',
          ),
        );
        try {
          final recovered = _recoverHealSession(session);
          if (recovered != session.gameState) {
            await _commitAndSave(recovered);
          }
          session
            ..gameState = recovered
            ..wasHealed = true
            ..failure = null;
          _publishWorldService(
            _buildHealSnapshot(
              session,
              stage: RuntimeWorldServiceStage.completed,
              safeMessage: recovered == session.initialGameState
                  ? 'Votre équipe est déjà entièrement soignée.'
                  : 'Votre équipe est entièrement soignée.',
            ),
          );
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.accepted,
          );
        } catch (error) {
          session.failure = error;
          const message = 'Le soin n’a pas pu être enregistré.';
          _publishWorldService(
            _buildHealSnapshot(
              session,
              stage: RuntimeWorldServiceStage.failed,
              safeMessage: message,
            ),
          );
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
    final result = const GameStateMutations().purchaseFromResolvedShop(
      session.gameState,
      shop: session.request.shop,
      expectedStateId: session.resolved.stateId,
      itemId: itemId,
      quantity: quantity,
      conditionContext: session.request.conditionContext,
    );
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
        safeMessage: 'Achat effectué.',
      ),
    );
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
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
      itemCatalog: _itemCatalog ?? ItemCatalogSnapshot.empty(),
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
    final canTransact = session.resolved.isOpen &&
        selected != null &&
        selected.canTransact &&
        (session.mode == RuntimeShopMode.sell
            ? selected.ownedQuantity >= session.quantity
            : (selected.remainingStock == null ||
                    selected.remainingStock! >= session.quantity) &&
                totalPrice <= session.gameState.trainerProfile.money);
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
                    : selected.remainingStock != null &&
                            selected.remainingStock! < session.quantity
                        ? 'Stock insuffisant.'
                        : totalPrice > session.gameState.trainerProfile.money
                            ? 'Fonds insuffisants.'
                            : null;
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
      return session.resolved.entries
          .map(
            (entry) => RuntimeShopEntrySnapshot(
              itemId: entry.itemId,
              label: _shopItemLabel(entry.itemId),
              unitPrice: entry.price,
              remainingStock: _remainingShopStock(session, entry),
            ),
          )
          .toList(growable: false);
    }

    return session.gameState.bag.normalized().entries.map((bagEntry) {
      final shopEntry = session.resolved.entries
          .where((entry) => entry.itemId == bagEntry.itemId)
          .firstOrNull;
      final unavailableReason = _shopSaleUnavailableReason(
        bagEntry: bagEntry,
        shopEntry: shopEntry,
        itemCatalog: _itemCatalog ?? ItemCatalogSnapshot.empty(),
      );
      return RuntimeShopEntrySnapshot(
        itemId: bagEntry.itemId,
        label: _shopItemLabel(bagEntry.itemId),
        unitPrice: shopEntry?.sellPrice ?? 0,
        ownedQuantity: bagEntry.quantity,
        canTransact: unavailableReason == null,
        unavailableReason: unavailableReason,
      );
    }).toList(growable: false);
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
    return remaining == null ? 10 : remaining.clamp(1, 10);
  }

  int? _remainingShopStock(
    _ContextualShopSession session,
    ShopEntryDefinition entry,
  ) {
    final stock = entry.stock;
    if (stock == null) return null;
    final stockKey = session.resolved.isDefault
        ? '${session.request.shop.id}::${entry.itemId}'
        : '${session.request.shop.id}::${session.resolved.stateId}::'
            '${entry.itemId}';
    final purchased =
        session.gameState.progression.shopPurchaseCounts[stockKey] ?? 0;
    return (stock - purchased).clamp(0, stock);
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
    final shop = _shopSession;
    if (shop != null && !shop.result.isCompleted) {
      shop.result.complete(const PlayerServiceHostResult.cancelled());
    }
    _shopSession = null;
    final heal = _healSession;
    if (heal != null && !heal.result.isCompleted) {
      heal.result.complete(const PlayerServiceRuntimeResult.cancelled());
    }
    _healSession = null;
    final pc = _pcSession;
    if (pc != null && !pc.result.isCompleted) {
      pc.result.complete(const PlayerServiceRuntimeResult.cancelled());
    }
    _pcSession = null;
    _publishWorldService(null);
    await _worldServiceSnapshots.close();
  }
}

final class _ContextualShopSession {
  _ContextualShopSession({
    required this.request,
    required this.gameState,
  })  : resolved = request.resolvedState,
        selectedItemId = request.resolvedState.entries.firstOrNull?.itemId;

  final PlayerServiceShopRequest request;
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
  })  : initialGameState = gameState,
        gameState = gameState;

  final OpenHealService request;
  final GameState initialGameState;
  final RuntimePlayerServiceRecoveryCaps recoveryCaps;
  final result = Completer<PlayerServiceRuntimeResult>();
  GameState gameState;
  bool wasHealed = false;
  Object? failure;
}

final class _ContextualPcSession {
  _ContextualPcSession({
    required this.request,
    required this.gameState,
    required this.selectedBoxId,
  });

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
    this.boxId,
  });

  final RuntimeWorldServiceAction action;
  final int index;
  final String? boxId;
}

String _shopFailureMessage(ShopPurchaseFailure failure) => switch (failure) {
      ShopPurchaseFailure.invalidRequest => 'Achat invalide.',
      ShopPurchaseFailure.unknownItem => 'Objet inconnu.',
      ShopPurchaseFailure.insufficientFunds => 'Fonds insuffisants.',
      ShopPurchaseFailure.outOfStock => 'Stock insuffisant.',
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
  required ShopEntryDefinition? shopEntry,
  required ItemCatalogSnapshot itemCatalog,
}) {
  if (itemCatalog.definitionFor(bagEntry.itemId)?.tags.contains('key-item') ??
      false) {
    return 'Les objets importants sont invendables.';
  }
  if (shopEntry?.sellPrice == null) {
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

int? _partyIndexFromTarget(String targetId) {
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
