import 'dart:async';

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
final class PlayerServiceRuntimeController implements RuntimeWorldServicePort {
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

  PlayerServiceRuntimeController.contextual({
    required PlayerServiceGameStateReader currentGameState,
    required PlayerServiceStateTransaction commitAndSave,
    required PlayerServiceInputLockSetter setInputLocked,
    required PlayerServiceRecoveryCapsLoader loadRecoveryCaps,
    ScriptEvaluationContext conditionContext = const ScriptEvaluationContext(),
    Set<String> grantedCapabilities = const <String>{},
  })  : _currentGameState = currentGameState,
        _host = null,
        _commitAndSave = commitAndSave,
        _setInputLocked = setInputLocked,
        _loadRecoveryCaps = loadRecoveryCaps,
        _conditionContext = conditionContext,
        _grantedCapabilities = Set<String>.unmodifiable(grantedCapabilities);

  final PlayerServiceGameStateReader _currentGameState;
  final PlayerServiceOverlayHost? _host;
  final PlayerServiceStateTransaction _commitAndSave;
  final PlayerServiceInputLockSetter _setInputLocked;
  final PlayerServiceRecoveryCapsLoader _loadRecoveryCaps;
  final ScriptEvaluationContext _conditionContext;
  final Set<String> _grantedCapabilities;
  final _worldServiceSnapshots =
      StreamController<RuntimeWorldServiceSnapshot?>.broadcast();
  bool _active = false;
  bool _disposed = false;
  RuntimeWorldServiceSnapshot? _worldServiceSnapshot;
  _ContextualShopSession? _shopSession;
  _ContextualHealSession? _healSession;

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
    return _run(
      worldRequest,
      (state, caps) {
        final host = _host;
        if (host == null) {
          return Future<PlayerServiceHostResult>.value(
            const PlayerServiceHostResult.cancelled(),
          );
        }
        return host.openPc(
          PlayerServicePcRequest(
            gameState: state,
            recoveryCaps: caps,
            worldRequest: worldRequest,
          ),
        );
      },
    );
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
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.unavailable,
      safeMessage: 'Ce service n’accepte pas cette action.',
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
      case RuntimeWorldServiceAction.decreaseQuantity:
      case RuntimeWorldServiceAction.increaseQuantity:
      case RuntimeWorldServiceAction.deposit:
      case RuntimeWorldServiceAction.withdraw:
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
    return const GameStateMutations().recoverParty(
      session.initialGameState,
      maxHpByPartyIndex: session.recoveryCaps.maxHpByPartyIndex,
      maxPpByPartyIndex: session.recoveryCaps.maxPpByPartyIndex,
    );
  }

  RuntimeWorldServiceCommandResult _dispatchShop(
    _ContextualShopSession session,
    RuntimeWorldServiceCommand command,
  ) {
    switch (command.action) {
      case RuntimeWorldServiceAction.select:
        final targetId = command.targetId;
        if (targetId == null ||
            !session.resolved.entries
                .any((entry) => entry.itemId == targetId)) {
          return const RuntimeWorldServiceCommandResult(
            status: RuntimeWorldServiceCommandStatus.unavailable,
            safeMessage: 'Cet objet n’est plus disponible.',
          );
        }
        session
          ..selectedItemId = targetId
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
        return _purchaseFromShop(session, command);
      case RuntimeWorldServiceAction.close:
        session.result.complete(
          PlayerServiceHostResult.completed(session.gameState),
        );
      case RuntimeWorldServiceAction.cancel:
        session.result.complete(const PlayerServiceHostResult.cancelled());
      case RuntimeWorldServiceAction.deposit:
      case RuntimeWorldServiceAction.withdraw:
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
      categoryId: _categoryForShopItem(itemId),
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

  RuntimeWorldServiceSnapshot _buildShopSnapshot(
    _ContextualShopSession session, {
    String? safeMessage,
  }) {
    final entries = session.resolved.entries
        .map(
          (entry) => RuntimeShopEntrySnapshot(
            itemId: entry.itemId,
            label: _shopItemLabel(entry.itemId),
            unitPrice: entry.price,
            remainingStock: _remainingShopStock(
              session,
              entry,
            ),
          ),
        )
        .toList(growable: false);
    session.selectedItemId ??= entries.firstOrNull?.itemId;
    final selected = entries
        .where((entry) => entry.itemId == session.selectedItemId)
        .firstOrNull;
    final totalPrice = (selected?.unitPrice ?? 0) * session.quantity;
    final canPurchase = session.resolved.isOpen &&
        selected != null &&
        (selected.remainingStock == null ||
            selected.remainingStock! >= session.quantity) &&
        totalPrice <= session.gameState.trainerProfile.money;
    final confirmReason = !session.resolved.isOpen
        ? 'Cette boutique est fermée.'
        : selected == null
            ? 'Cette boutique est vide.'
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
        selectedItemId: session.selectedItemId,
        quantity: session.quantity,
        totalPrice: totalPrice,
      ),
      safeMessage: safeMessage,
      logicalSelectionId: session.selectedItemId,
      actions: <RuntimeWorldServiceActionAvailability>[
        if (entries.isEmpty)
          RuntimeWorldServiceActionAvailability.disabled(
            RuntimeWorldServiceAction.select,
            reason: 'Cette boutique est vide.',
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
        if (canPurchase)
          const RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.confirm,
          )
        else
          RuntimeWorldServiceActionAvailability.disabled(
            RuntimeWorldServiceAction.confirm,
            reason: confirmReason ?? 'Achat indisponible.',
          ),
        const RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );
  }

  int _maximumShopQuantity(_ContextualShopSession session) {
    final itemId = session.selectedItemId;
    if (itemId == null) return 1;
    final entry =
        session.resolved.entries.where((entry) => entry.itemId == itemId).first;
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

String _categoryForShopItem(String itemId) {
  final effect = const PlayerItemEffectRegistry.mvp().effectFor(itemId);
  return switch (effect?.kind) {
    PlayerItemEffectKind.healHp ||
    PlayerItemEffectKind.cureStatus ||
    PlayerItemEffectKind.revive ||
    PlayerItemEffectKind.restorePp =>
      'medicine',
    _ => 'items',
  };
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

String _shopItemLabel(String itemId) => itemId
    .replaceAll('_', '-')
    .split('-')
    .where((part) => part.isNotEmpty)
    .map(
      (part) => '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

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
