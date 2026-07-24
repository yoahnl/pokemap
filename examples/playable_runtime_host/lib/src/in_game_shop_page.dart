import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'evaluation/interactive/player_service_automation_port.dart';

typedef InGamePlayerStateCommit = Future<void> Function(GameState state);
typedef InGamePlayerStateReader = GameState Function();
typedef InGamePlayerServiceClose = Future<void> Function();

class InGameShopPage extends StatefulWidget {
  const InGameShopPage({
    super.key,
    required this.gameState,
    required this.shops,
    required this.onStateCommitted,
    this.currentGameState,
    this.conditionContext = const ScriptEvaluationContext(),
    this.automationPort,
    this.onAutomationClose,
  });

  final GameState gameState;
  final List<ShopDefinition> shops;
  final InGamePlayerStateCommit onStateCommitted;
  final InGamePlayerStateReader? currentGameState;
  final ScriptEvaluationContext conditionContext;
  final PlayerServiceAutomationPort? automationPort;
  final InGamePlayerServiceClose? onAutomationClose;

  @override
  State<InGameShopPage> createState() => _InGameShopPageState();
}

class _InGameShopPageState extends State<InGameShopPage> {
  static const _mutations = GameStateMutations();
  static const _resolver = ShopStateResolver();

  late GameState _gameState = widget.gameState;
  late String? _shopId = widget.shops.isEmpty ? null : widget.shops.first.id;
  final Map<String, int> _quantityByItemId = <String, int>{};
  bool _busy = false;
  String? _feedback;
  bool _feedbackIsError = false;
  late final _ShopAutomationSession _automationSession =
      _ShopAutomationSession(this);

  ShopDefinition? get _shop {
    final id = _shopId;
    if (id == null) return null;
    for (final shop in widget.shops) {
      if (shop.id == id) return shop;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    widget.automationPort?.register(_automationSession);
  }

  @override
  void didUpdateWidget(covariant InGameShopPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.automationPort, oldWidget.automationPort)) {
      oldWidget.automationPort?.unregister(_automationSession);
      widget.automationPort?.register(_automationSession);
    }
    if (widget.gameState != oldWidget.gameState) {
      _gameState = widget.gameState;
    }
  }

  @override
  void dispose() {
    widget.automationPort?.unregister(_automationSession);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = _shop;
    if (shop == null) {
      return const Material(
        child: Center(
          child: Text('Aucune boutique disponible dans ce projet.'),
        ),
      );
    }
    final resolved = _resolver.resolve(
      shop: shop,
      gameState: _gameState,
      conditionContext: widget.conditionContext,
    );
    return Material(
      child: ListView(
        key: const Key('in-game-shop-page'),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Boutique',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Chip(
                key: const Key('shop-player-money'),
                label:
                    Text('${_formatMoney(_gameState.trainerProfile.money)} ₽'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.shops.length > 1)
            DropdownButtonFormField<String>(
              key: const Key('shop-picker'),
              initialValue: shop.id,
              decoration: const InputDecoration(labelText: 'Boutique'),
              items: widget.shops
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.id,
                      child: Text(entry.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _busy
                  ? null
                  : (id) => setState(() {
                        _shopId = id;
                        _feedback = null;
                      }),
            )
          else
            const SizedBox.shrink(),
          Text(
            resolved.storefrontLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (resolved.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              resolved.message,
              key: const Key('shop-profile-message'),
            ),
          ],
          const SizedBox(height: 12),
          if (!resolved.isOpen)
            const SizedBox.shrink()
          else if (resolved.entries.isEmpty)
            const Card(
              child: ListTile(title: Text('Cette boutique est vide.')),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final entry in resolved.entries)
                    _buildEntry(context, shop, resolved, entry),
                ],
              ),
            ),
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _feedback!,
              key: const Key('shop-feedback'),
              style: TextStyle(
                color: _feedbackIsError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntry(
    BuildContext context,
    ShopDefinition shop,
    ResolvedShopState resolved,
    ShopEntryDefinition entry,
  ) {
    final quantity = _quantityByItemId[entry.itemId] ?? 1;
    final stockKey = resolved.isDefault
        ? '${shop.id}::${entry.itemId}'
        : '${shop.id}::${resolved.stateId}::${entry.itemId}';
    final purchased = _gameState.progression.shopPurchaseCounts[stockKey] ?? 0;
    final remaining = entry.stock == null ? null : entry.stock! - purchased;
    final maximumQuantity = remaining == null ? 10 : remaining.clamp(1, 10);
    return ListTile(
      key: Key('shop-entry-${entry.itemId}'),
      title: Text(_itemLabel(entry.itemId)),
      subtitle: Text(
        '${_formatMoney(entry.price)} ₽ · '
        '${remaining == null ? 'Stock illimité' : 'Stock : ${remaining < 0 ? 0 : remaining}'}',
      ),
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          DropdownButton<int>(
            key: Key('shop-quantity-${entry.itemId}'),
            value: quantity > maximumQuantity ? maximumQuantity : quantity,
            items: List<DropdownMenuItem<int>>.generate(
              maximumQuantity,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                child: Text('x${index + 1}'),
              ),
            ),
            onChanged: _busy || remaining == 0
                ? null
                : (value) => setState(
                      () => _quantityByItemId[entry.itemId] = value ?? 1,
                    ),
          ),
          FilledButton(
            key: Key('shop-buy-${entry.itemId}'),
            onPressed: _busy || remaining == 0
                ? null
                : () => _buy(shop, resolved, entry, quantity),
            child: const Text('Acheter'),
          ),
        ],
      ),
    );
  }

  Future<PlayerServiceAutomationResult> _inspectShop() async {
    final shop = _shop;
    if (shop == null) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'No shop is available.',
      );
    }
    final state = widget.currentGameState?.call() ?? _gameState;
    final resolved = _resolver.resolve(
      shop: shop,
      gameState: state,
      conditionContext: widget.conditionContext,
    );
    return PlayerServiceAutomationResult.success(
      details: <String, Object?>{
        'shopId': shop.id,
        'stateId': resolved.stateId,
        'isOpen': resolved.isOpen,
        'catalogue': <String, int>{
          for (final entry in resolved.entries) entry.itemId: entry.price,
        },
        'message': resolved.message,
        'items': resolved.entries
            .map((entry) => entry.itemId)
            .toList(growable: false),
      },
    );
  }

  Future<PlayerServiceAutomationResult> _buyItem(
    String itemId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'Shop quantity must be positive.',
      );
    }
    final shop = _shop;
    if (shop == null) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'No shop is available.',
      );
    }
    final state = widget.currentGameState?.call() ?? _gameState;
    final resolved = _resolver.resolve(
      shop: shop,
      gameState: state,
      conditionContext: widget.conditionContext,
    );
    ShopEntryDefinition? selectedEntry;
    for (final entry in resolved.entries) {
      if (entry.itemId == itemId) {
        selectedEntry = entry;
        break;
      }
    }
    if (!resolved.isOpen || selectedEntry == null) {
      return PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'Item "$itemId" is not available in the visible shop.',
      );
    }
    return _buy(shop, resolved, selectedEntry, quantity);
  }

  Future<PlayerServiceAutomationResult> _buy(
    ShopDefinition shop,
    ResolvedShopState renderedState,
    ShopEntryDefinition entry,
    int quantity,
  ) async {
    if (_busy) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.busy,
        message: 'The shop is already processing a purchase.',
      );
    }
    setState(() {
      _busy = true;
      _feedback = null;
    });
    final transactionState = widget.currentGameState?.call() ?? _gameState;
    final result = _mutations.purchaseFromResolvedShop(
      transactionState,
      shop: shop,
      expectedStateId: renderedState.stateId,
      itemId: entry.itemId,
      categoryId: _categoryFor(entry.itemId),
      quantity: quantity,
      conditionContext: widget.conditionContext,
    );
    if (!result.isSuccess) {
      if (result.failure == ShopPurchaseFailure.shopStateChanged) {
        setState(() {
          _gameState = transactionState;
          _busy = false;
          _feedbackIsError = false;
          _feedback = 'La boutique a changé. Le catalogue a été actualisé.';
        });
        return const PlayerServiceAutomationResult.failed(
          failure: PlayerServiceAutomationFailure.rejected,
          message: 'The shop catalogue changed before the purchase.',
        );
      }
      setState(() {
        _gameState = transactionState;
        _busy = false;
        _feedbackIsError = true;
        _feedback = _failureLabel(result.failure!);
      });
      return PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.rejected,
        message: _failureLabel(result.failure!),
      );
    }
    try {
      await widget.onStateCommitted(result.state);
      if (!mounted) {
        return const PlayerServiceAutomationResult.failed(
          failure: PlayerServiceAutomationFailure.rejected,
          message: 'The shop closed before the purchase completed.',
        );
      }
      setState(() {
        _gameState = result.state;
        _busy = false;
        _feedbackIsError = false;
        _feedback = 'Achat effectué : $quantity × ${_itemLabel(entry.itemId)}.';
      });
      return PlayerServiceAutomationResult.success(
        details: <String, Object?>{
          'itemId': entry.itemId,
          'quantity': quantity,
        },
      );
    } catch (error) {
      if (!mounted) {
        return PlayerServiceAutomationResult.failed(
          failure: PlayerServiceAutomationFailure.rejected,
          message: 'The shop closed after a failed purchase: $error',
        );
      }
      setState(() {
        _busy = false;
        _feedbackIsError = true;
        _feedback = 'Échec de l’achat : $error';
      });
      return PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.rejected,
        message: 'The purchase could not be committed: $error',
      );
    }
  }

  Future<PlayerServiceAutomationResult> _closeFromAutomation() async {
    final close = widget.onAutomationClose;
    if (close == null) {
      return const PlayerServiceAutomationResult.failed(
        failure: PlayerServiceAutomationFailure.invalidRequest,
        message: 'The visible shop cannot be closed by automation.',
      );
    }
    await close();
    return const PlayerServiceAutomationResult.success();
  }
}

final class _ShopAutomationSession implements PlayerServiceAutomationSession {
  const _ShopAutomationSession(this.owner);

  final _InGameShopPageState owner;

  @override
  PlayerServiceAutomationKind get kind => PlayerServiceAutomationKind.shop;

  @override
  Future<PlayerServiceAutomationResult> invoke(
    PlayerServiceAutomationCommand command,
  ) =>
      switch (command) {
        InspectShopAutomationCommand() => owner._inspectShop(),
        BuyShopItemAutomationCommand(:final itemId, :final quantity) =>
          owner._buyItem(itemId, quantity),
        CloseShopAutomationCommand() => owner._closeFromAutomation(),
        _ => Future<PlayerServiceAutomationResult>.value(
            const PlayerServiceAutomationResult.failed(
              failure: PlayerServiceAutomationFailure.wrongService,
              message: 'The command does not belong to the Shop service.',
            ),
          ),
      };
}

String _itemLabel(String itemId) => switch (itemId) {
      'potion' => 'Potion',
      'super-potion' => 'Super Potion',
      'hyper-potion' => 'Hyper Potion',
      'max-potion' => 'Potion Max',
      'poke-ball' => 'Poké Ball',
      'antidote' => 'Antidote',
      _ => itemId
          .replaceAll('_', '-')
          .split('-')
          .where((part) => part.isNotEmpty)
          .map(
            (part) => '${part.substring(0, 1).toUpperCase()}'
                '${part.substring(1)}',
          )
          .join(' '),
    };

String _categoryFor(String itemId) {
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

String _failureLabel(ShopPurchaseFailure failure) => switch (failure) {
      ShopPurchaseFailure.invalidRequest => 'Achat invalide.',
      ShopPurchaseFailure.unknownItem => 'Objet inconnu dans cette boutique.',
      ShopPurchaseFailure.insufficientFunds => 'Fonds insuffisants.',
      ShopPurchaseFailure.outOfStock => 'Stock épuisé.',
      ShopPurchaseFailure.shopClosed => 'Cette boutique est fermée.',
      ShopPurchaseFailure.shopStateChanged =>
        'La boutique a changé. Le catalogue a été actualisé.',
    };

String _formatMoney(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    if (index > 0 && (raw.length - index) % 3 == 0) buffer.write(' ');
    buffer.write(raw[index]);
  }
  return buffer.toString();
}
