import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../player/runtime_world_service_models.dart';
import 'runtime_player_pokemon_progression_hydrator.dart';
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
final class PlayerServiceRuntimeController {
  PlayerServiceRuntimeController({
    required PlayerServiceGameStateReader currentGameState,
    required PlayerServiceOverlayHost host,
    required PlayerServiceStateTransaction commitAndSave,
    required PlayerServiceInputLockSetter setInputLocked,
    required PlayerServiceRecoveryCapsLoader loadRecoveryCaps,
    ScriptEvaluationContext conditionContext = const ScriptEvaluationContext(),
    Set<String> grantedCapabilities = const <String>{},
  })  : _currentGameState = currentGameState,
        _host = host,
        _commitAndSave = commitAndSave,
        _setInputLocked = setInputLocked,
        _loadRecoveryCaps = loadRecoveryCaps,
        _conditionContext = conditionContext,
        _grantedCapabilities = Set<String>.unmodifiable(grantedCapabilities);

  final PlayerServiceGameStateReader _currentGameState;
  final PlayerServiceOverlayHost _host;
  final PlayerServiceStateTransaction _commitAndSave;
  final PlayerServiceInputLockSetter _setInputLocked;
  final PlayerServiceRecoveryCapsLoader _loadRecoveryCaps;
  final ScriptEvaluationContext _conditionContext;
  final Set<String> _grantedCapabilities;
  bool _active = false;

  bool get isActive => _active;

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
        return _host.openShop(
          PlayerServiceShopRequest(
            gameState: state,
            recoveryCaps: caps,
            worldRequest: worldRequest,
            shop: normalizedShop,
            resolvedState: resolvedState,
            conditionContext: _conditionContext,
          ),
        );
      },
    );
  }

  Future<PlayerServiceRuntimeResult> openPc({
    OpenPcService? request,
  }) {
    final worldRequest =
        request ?? const OpenPcService(interactionId: 'runtime.pc:default');
    return _run(
      worldRequest,
      (state, caps) => _host.openPc(
        PlayerServicePcRequest(
          gameState: state,
          recoveryCaps: caps,
          worldRequest: worldRequest,
        ),
      ),
    );
  }

  Future<PlayerServiceRuntimeResult> openHealCenter({
    OpenHealService? request,
  }) {
    final worldRequest =
        request ?? const OpenHealService(interactionId: 'runtime.heal:default');
    return _run(
      worldRequest,
      (state, caps) => _host.openHealCenter(
        PlayerServiceHealRequest(
          gameState: state,
          recoveryCaps: caps,
          worldRequest: worldRequest,
        ),
      ),
    );
  }

  Future<PlayerServiceRuntimeResult> _run(
    RuntimeWorldServiceRequest request,
    Future<PlayerServiceHostResult> Function(
      GameState state,
      RuntimePlayerServiceRecoveryCaps caps,
    ) open,
  ) async {
    if (_active) return const PlayerServiceRuntimeResult.busy();
    final state = _currentGameState();
    final missingCapabilities =
        request.requiredCapabilities.difference(_grantedCapabilities);
    if (missingCapabilities.isNotEmpty) {
      return const PlayerServiceRuntimeResult.unavailable(
        'Ce service n’est pas pris en charge par ce jeu.',
      );
    }
    final condition = request.availabilityCondition;
    if (condition != null &&
        !const ScriptConditionEvaluator().evaluate(
          condition,
          state,
          context: _conditionContext,
        )) {
      return const PlayerServiceRuntimeResult.unavailable(
        'Ce service n’est pas disponible pour le moment.',
      );
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
}

/// Resolves the real HP and PP caps needed by Bag and healing screens.
Future<RuntimePlayerServiceRecoveryCaps> loadRuntimePlayerServiceRecoveryCaps({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  if (gameState.party.members.isEmpty) {
    return const RuntimePlayerServiceRecoveryCaps(
      maxHpByPartyIndex: <int, int>{},
    );
  }
  final speciesLoader = RuntimePokemonSpeciesLoader();
  final maxHpByPartyIndex = <int, int>{};
  for (var index = 0; index < gameState.party.members.length; index++) {
    final pokemon = gameState.party.members[index];
    final species = await speciesLoader.loadById(
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
    );
    maxHpByPartyIndex[index] = stats.maxHp;
  }
  final catalogs = await loadRuntimePlayerPokemonProgressionCatalogs(
    gameState: gameState,
    projectRootDirectory: projectRootDirectory,
    pokemonConfig: pokemonConfig,
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
