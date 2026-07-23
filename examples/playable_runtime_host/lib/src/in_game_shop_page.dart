import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

typedef InGamePlayerStateCommit = Future<void> Function(GameState state);

class InGameShopPage extends StatefulWidget {
  const InGameShopPage({
    super.key,
    required this.gameState,
    required this.shops,
    required this.onStateCommitted,
  });

  final GameState gameState;
  final List<ShopDefinition> shops;
  final InGamePlayerStateCommit onStateCommitted;

  @override
  State<InGameShopPage> createState() => _InGameShopPageState();
}

class _InGameShopPageState extends State<InGameShopPage> {
  static const _mutations = GameStateMutations();

  late GameState _gameState = widget.gameState;
  late String? _shopId = widget.shops.isEmpty ? null : widget.shops.first.id;
  final Map<String, int> _quantityByItemId = <String, int>{};
  bool _busy = false;
  String? _feedback;
  bool _feedbackIsError = false;

  ShopDefinition? get _shop {
    final id = _shopId;
    if (id == null) return null;
    for (final shop in widget.shops) {
      if (shop.id == id) return shop;
    }
    return null;
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
            Text(shop.label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (shop.entries.isEmpty)
            const Card(
              child: ListTile(title: Text('Cette boutique est vide.')),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final entry in shop.entries)
                    _buildEntry(context, shop, entry),
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
    ShopEntryDefinition entry,
  ) {
    final quantity = _quantityByItemId[entry.itemId] ?? 1;
    final purchased = _gameState
            .progression.shopPurchaseCounts['${shop.id}::${entry.itemId}'] ??
        0;
    final remaining = entry.stock == null ? null : entry.stock! - purchased;
    final maximumQuantity = remaining == null ? 10 : remaining.clamp(1, 10);
    return ListTile(
      key: Key('shop-entry-${entry.itemId}'),
      title: Text(entry.itemId),
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
                : () => _buy(shop, entry, quantity),
            child: const Text('Acheter'),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(
    ShopDefinition shop,
    ShopEntryDefinition entry,
    int quantity,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    final result = _mutations.purchaseFromShop(
      _gameState,
      shop: shop,
      itemId: entry.itemId,
      categoryId: _categoryFor(entry.itemId),
      quantity: quantity,
    );
    if (!result.isSuccess) {
      setState(() {
        _busy = false;
        _feedbackIsError = true;
        _feedback = _failureLabel(result.failure!);
      });
      return;
    }
    try {
      await widget.onStateCommitted(result.state);
      if (!mounted) return;
      setState(() {
        _gameState = result.state;
        _busy = false;
        _feedbackIsError = false;
        _feedback = 'Achat effectué : $quantity × ${entry.itemId}.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedbackIsError = true;
        _feedback = 'Échec de l’achat : $error';
      });
    }
  }
}

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
