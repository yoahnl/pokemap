import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';

/// Responsive, data-only shop rendered from a runtime-owned snapshot.
///
/// Prices, stock, funds and transaction results are never derived here. The
/// overlay only emits versioned intents back to the active runtime session.
class PlayerShopOverlay extends StatelessWidget {
  const PlayerShopOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final content = snapshot.content;
    if (content is! RuntimeShopServiceContent) {
      return _InvalidShopOverlay(
        onClose: () => _emit(RuntimeWorldServiceAction.close),
      );
    }

    return ColoredBox(
      color: context.playerColors.scrim,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            return Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(PlayerSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: PlayerPanel(
                    elevated: true,
                    padding: const EdgeInsets.all(PlayerSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _ShopHeader(
                          title: content.title,
                          money: content.money,
                          onClose: () => _emit(RuntimeWorldServiceAction.close),
                        ),
                        if (content.message.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: PlayerSpacing.xs),
                          Text(
                            content.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: PlayerSpacing.sm),
                        _ShopModeSwitcher(
                          mode: content.mode,
                          onBuy: () =>
                              _emit(RuntimeWorldServiceAction.showPurchases),
                          onSell: () =>
                              _emit(RuntimeWorldServiceAction.showSales),
                        ),
                        const SizedBox(height: PlayerSpacing.md),
                        if (content.entries.isEmpty)
                          _EmptyShop(
                            mode: content.mode,
                            reason: snapshot.unavailableReasonFor(
                                  RuntimeWorldServiceAction.confirm,
                                ) ??
                                (content.mode == RuntimeShopMode.sell
                                    ? context.playerL10n.shopBagEmpty
                                    : context.playerL10n.shopEmpty),
                          )
                        else if (compact)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _ShopInventory(
                                snapshot: snapshot,
                                content: content,
                                onCommand: onCommand,
                              ),
                              const SizedBox(height: PlayerSpacing.md),
                              _ShopPurchasePanel(
                                snapshot: snapshot,
                                content: content,
                                onCommand: onCommand,
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                flex: 3,
                                child: _ShopInventory(
                                  snapshot: snapshot,
                                  content: content,
                                  onCommand: onCommand,
                                ),
                              ),
                              const SizedBox(width: PlayerSpacing.md),
                              Expanded(
                                flex: 2,
                                child: _ShopPurchasePanel(
                                  snapshot: snapshot,
                                  content: content,
                                  onCommand: onCommand,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _emit(
    RuntimeWorldServiceAction action, {
    String? targetId,
    int? quantity,
  }) {
    onCommand(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: snapshot.revision,
        targetId: targetId,
        quantity: quantity,
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
    required this.title,
    required this.money,
    required this.onClose,
  });

  final String title;
  final int money;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          PlayerBadge(
            label: '$money ₽',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(width: PlayerSpacing.xs),
          IconButton(
            key: const ValueKey<String>('shop-close'),
            tooltip: context.playerL10n.close,
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      );
}

class _ShopModeSwitcher extends StatelessWidget {
  const _ShopModeSwitcher({
    required this.mode,
    required this.onBuy,
    required this.onSell,
  });

  final RuntimeShopMode mode;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(
            child: PlayerActionButton(
              key: const ValueKey<String>('shop-mode-buy'),
              label: context.playerL10n.shopBuy,
              icon: Icons.shopping_bag_outlined,
              selected: mode == RuntimeShopMode.buy,
              secondary: mode != RuntimeShopMode.buy,
              onPressed: onBuy,
            ),
          ),
          const SizedBox(width: PlayerSpacing.xs),
          Expanded(
            child: PlayerActionButton(
              key: const ValueKey<String>('shop-mode-sell'),
              label: context.playerL10n.shopSell,
              icon: Icons.sell_outlined,
              selected: mode == RuntimeShopMode.sell,
              secondary: mode != RuntimeShopMode.sell,
              onPressed: onSell,
            ),
          ),
        ],
      );
}

class _ShopInventory extends StatelessWidget {
  const _ShopInventory({
    required this.snapshot,
    required this.content,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final RuntimeShopServiceContent content;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.playerL10n.shopItems,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PlayerSpacing.xs),
          for (final entry in content.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: PlayerSpacing.xs),
              child: _ShopEntry(
                entry: entry,
                mode: content.mode,
                selected: entry.itemId == content.selectedItemId,
                onPressed: snapshot.isActionEnabled(
                  RuntimeWorldServiceAction.select,
                )
                    ? () => onCommand(
                          RuntimeWorldServiceCommand(
                            action: RuntimeWorldServiceAction.select,
                            snapshotRevision: snapshot.revision,
                            targetId: entry.itemId,
                          ),
                        )
                    : null,
              ),
            ),
        ],
      );
}

class _ShopEntry extends StatelessWidget {
  const _ShopEntry({
    required this.entry,
    required this.mode,
    required this.selected,
    required this.onPressed,
  });

  final RuntimeShopEntrySnapshot entry;
  final RuntimeShopMode mode;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final stock = entry.remainingStock;
    final selling = mode == RuntimeShopMode.sell;
    final l10n = context.playerL10n;
    return PlayerActionButton(
      key: ValueKey<String>('shop-item-${entry.itemId}'),
      label: entry.label,
      icon: selected ? Icons.check_circle : Icons.inventory_2_outlined,
      selected: selected,
      secondary: !selected,
      onPressed: onPressed,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            selling && !entry.canTransact
                ? l10n.shopUnsellable
                : '${entry.unitPrice} ₽',
          ),
          if (selling)
            Text(
              l10n.shopOwned(entry.ownedQuantity),
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (stock != null)
            Text(
              l10n.shopStock(stock),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _ShopPurchasePanel extends StatelessWidget {
  const _ShopPurchasePanel({
    required this.snapshot,
    required this.content,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final RuntimeShopServiceContent content;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final l10n = context.playerL10n;
    final selling = content.mode == RuntimeShopMode.sell;
    final selectedId = content.selectedItemId;
    final canDecrease = snapshot.isActionEnabled(
      RuntimeWorldServiceAction.decreaseQuantity,
    );
    final canIncrease = snapshot.isActionEnabled(
      RuntimeWorldServiceAction.increaseQuantity,
    );
    final canConfirm =
        snapshot.isActionEnabled(RuntimeWorldServiceAction.confirm);
    final disabledReason = snapshot.unavailableReasonFor(
      RuntimeWorldServiceAction.confirm,
    );

    void emit(RuntimeWorldServiceAction action) {
      onCommand(
        RuntimeWorldServiceCommand(
          action: action,
          snapshotRevision: snapshot.revision,
          targetId: selectedId,
          quantity: content.quantity,
        ),
      );
    }

    return PlayerPanel(
      padding: const EdgeInsets.all(PlayerSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.shopQuantity,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PlayerSpacing.xs),
          Row(
            children: <Widget>[
              IconButton.filledTonal(
                key: const ValueKey<String>('shop-quantity-minus'),
                tooltip: l10n.shopDecreaseQuantity,
                onPressed: canDecrease
                    ? () => emit(
                          RuntimeWorldServiceAction.decreaseQuantity,
                        )
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '${content.quantity}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey<String>('shop-quantity-plus'),
                tooltip: l10n.shopIncreaseQuantity,
                onPressed: canIncrease
                    ? () => emit(
                          RuntimeWorldServiceAction.increaseQuantity,
                        )
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: PlayerSpacing.md),
          Text(
            l10n.shopTotal(content.totalPrice),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: PlayerSpacing.md),
          PlayerActionButton(
            key: ValueKey<String>(selling ? 'shop-sell' : 'shop-buy'),
            label: selling ? l10n.shopSell : l10n.shopBuy,
            icon: selling ? Icons.sell_outlined : Icons.shopping_bag_outlined,
            disabledReason: disabledReason,
            onPressed: canConfirm && selectedId != null
                ? () => emit(RuntimeWorldServiceAction.confirm)
                : null,
          ),
          if (snapshot.safeMessage case final message?
              when message.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: PlayerSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyShop extends StatelessWidget {
  const _EmptyShop({
    required this.mode,
    required this.reason,
  });

  final RuntimeShopMode mode;
  final String reason;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PlayerEmptyState(
            icon: Icons.inventory_2_outlined,
            title: context.playerL10n.shopNoItems,
            message: reason,
          ),
          const SizedBox(height: PlayerSpacing.sm),
          PlayerActionButton(
            key: ValueKey<String>(
              mode == RuntimeShopMode.sell ? 'shop-sell' : 'shop-buy',
            ),
            label: mode == RuntimeShopMode.sell
                ? context.playerL10n.shopSell
                : context.playerL10n.shopBuy,
            icon: mode == RuntimeShopMode.sell
                ? Icons.sell_outlined
                : Icons.shopping_bag_outlined,
            disabledReason: reason,
          ),
        ],
      );
}

class _InvalidShopOverlay extends StatelessWidget {
  const _InvalidShopOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.playerColors.scrim,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(PlayerSpacing.md),
              child: PlayerPanel(
                elevated: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      context.playerL10n.shopCannotDisplay,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: PlayerSpacing.md),
                    PlayerActionButton(
                      label: context.playerL10n.close,
                      icon: Icons.close,
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
