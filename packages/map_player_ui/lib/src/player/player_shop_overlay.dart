import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';
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

    return PlayerMenuThemeScope(
      child: Builder(
        builder: (context) => ColoredBox(
          color: context.playerColors.scrim,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1000,
                    maxHeight: 800,
                  ),
                  child: PlayerMenuPanel(
                    primary: true,
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final portrait =
                            constraints.maxWidth < constraints.maxHeight;
                        final inventory = _ShopInventory(
                          snapshot: snapshot,
                          content: content,
                          onCommand: onCommand,
                        );
                        final purchase = _ShopPurchasePanel(
                          snapshot: snapshot,
                          content: content,
                          onCommand: onCommand,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ShopHeader(
                              title: content.title,
                              money: content.money,
                              onClose:
                                  snapshot.isActionEnabled(
                                    RuntimeWorldServiceAction.close,
                                  )
                                  ? () => _emit(RuntimeWorldServiceAction.close)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            _ShopModeSwitcher(
                              mode: content.mode,
                              onBuy:
                                  snapshot.isActionEnabled(
                                    RuntimeWorldServiceAction.showPurchases,
                                  )
                                  ? () => _emit(
                                      RuntimeWorldServiceAction.showPurchases,
                                    )
                                  : null,
                              onSell:
                                  snapshot.isActionEnabled(
                                    RuntimeWorldServiceAction.showSales,
                                  )
                                  ? () => _emit(
                                      RuntimeWorldServiceAction.showSales,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: content.entries.isEmpty
                                  ? PlayerPagedList(
                                      children: [
                                        if (content.message.isNotEmpty)
                                          Text(content.message),
                                        _EmptyShop(
                                          mode: content.mode,
                                          reason:
                                              snapshot.unavailableReasonFor(
                                                RuntimeWorldServiceAction
                                                    .confirm,
                                              ) ??
                                              (content.mode ==
                                                      RuntimeShopMode.sell
                                                  ? context
                                                        .playerL10n
                                                        .shopBagEmpty
                                                  : context
                                                        .playerL10n
                                                        .shopEmpty),
                                        ),
                                      ],
                                    )
                                  : portrait
                                  ? Column(
                                      children: [
                                        Expanded(flex: 3, child: inventory),
                                        const SizedBox(height: 8),
                                        Expanded(flex: 2, child: purchase),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(flex: 3, child: inventory),
                                        const SizedBox(width: 12),
                                        Expanded(flex: 2, child: purchase),
                                      ],
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _emit(
    RuntimeWorldServiceAction action, {
    String? targetId,
    int? quantity,
  }) {
    if (!snapshot.isActionEnabled(action)) return;
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
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
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
  final VoidCallback? onBuy;
  final VoidCallback? onSell;

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
  Widget build(BuildContext context) => PlayerPagedList(
    key: ValueKey('shop-inventory-${content.mode.name}'),
    children: [
      if (content.message.isNotEmpty) Text(content.message),
      for (final entry in content.entries)
        _ShopEntry(
          entry: entry,
          mode: content.mode,
          selected: entry.itemId == content.selectedItemId,
          onPressed: snapshot.isActionEnabled(RuntimeWorldServiceAction.select)
              ? () => onCommand(
                  RuntimeWorldServiceCommand(
                    action: RuntimeWorldServiceAction.select,
                    snapshotRevision: snapshot.revision,
                    targetId: entry.itemId,
                  ),
                )
              : null,
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
    final canConfirm = snapshot.isActionEnabled(
      RuntimeWorldServiceAction.confirm,
    );
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

    final french = Localizations.localeOf(context).languageCode == 'fr';
    final balance = selling
        ? content.money + content.totalPrice
        : content.money - content.totalPrice;
    return PlayerMenuPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PlayerPagedList(
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('shop-quantity-minus'),
                      tooltip: l10n.shopDecreaseQuantity,
                      onPressed: canDecrease
                          ? () =>
                                emit(RuntimeWorldServiceAction.decreaseQuantity)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Text(
                        '${l10n.shopQuantity} : ${content.quantity}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('shop-quantity-plus'),
                      tooltip: l10n.shopIncreaseQuantity,
                      onPressed: canIncrease
                          ? () =>
                                emit(RuntimeWorldServiceAction.increaseQuantity)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                Text(
                  l10n.shopTotal(content.totalPrice),
                  textAlign: TextAlign.center,
                  style: context.playerMenuTheme.label,
                ),
                Text(
                  '${french ? 'Solde après' : 'Balance after'} : $balance ₽',
                  key: const ValueKey('shop-balance-after'),
                  textAlign: TextAlign.center,
                ),
                if (snapshot.safeMessage case final message?
                    when message.trim().isNotEmpty)
                  Semantics(
                    liveRegion: true,
                    child: Text(message, textAlign: TextAlign.center),
                  ),
                if (disabledReason != null) Text(disabledReason),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PlayerActionButton(
            key: ValueKey(selling ? 'shop-sell' : 'shop-buy'),
            label: selling ? l10n.shopSell : l10n.shopBuy,
            icon: selling ? Icons.sell_outlined : Icons.shopping_bag_outlined,
            onPressed: canConfirm && selectedId != null
                ? () => emit(RuntimeWorldServiceAction.confirm)
                : null,
          ),
        ],
      ),
    );
  }
}

class _EmptyShop extends StatelessWidget {
  const _EmptyShop({required this.mode, required this.reason});

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

  final VoidCallback? onClose;

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
