import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_input_scope.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';

/// Responsive, data-only shop rendered from a runtime-owned snapshot.
///
/// Prices, stock, funds and transaction results are never derived here. The
/// overlay only emits versioned intents back to the active runtime session.
class PlayerShopOverlay extends StatefulWidget {
  const PlayerShopOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  State<PlayerShopOverlay> createState() => _PlayerShopOverlayState();
}

class _PlayerShopOverlayState extends State<PlayerShopOverlay> {
  String? _quantityItemId;
  (String, int)? _pendingSelection;

  RuntimeWorldServiceSnapshot get snapshot => widget.snapshot;

  @override
  void didUpdateWidget(PlayerShopOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final content = snapshot.content;
    final previous = oldWidget.snapshot.content;
    if (content is! RuntimeShopServiceContent ||
        previous is! RuntimeShopServiceContent ||
        oldWidget.snapshot.request.interactionId !=
            snapshot.request.interactionId ||
        (oldWidget.snapshot.request is OpenShopService &&
            snapshot.request is OpenShopService &&
            (oldWidget.snapshot.request as OpenShopService).shopId !=
                (snapshot.request as OpenShopService).shopId) ||
        content.mode != previous.mode) {
      _quantityItemId = null;
      _pendingSelection = null;
      return;
    }
    if (_pendingSelection case (final id, final revision)?
        when snapshot.revision > revision && content.selectedItemId == id) {
      _quantityItemId = id;
      _pendingSelection = null;
    }
    if (_quantityItemId != null &&
        (!content.entries.any((entry) => entry.itemId == _quantityItemId) ||
            content.selectedItemId != _quantityItemId)) {
      _quantityItemId = null;
    }
  }

  void _returnToList() => setState(() {
    _quantityItemId = null;
    _pendingSelection = null;
  });

  void _select(String id) {
    if (!snapshot.isActionEnabled(RuntimeWorldServiceAction.select)) return;
    setState(() => _pendingSelection = (id, snapshot.revision));
    _emit(RuntimeWorldServiceAction.select, targetId: id);
  }

  void _setMode(RuntimeWorldServiceAction action) {
    if (!snapshot.isActionEnabled(action)) return;
    _returnToList();
    _emit(action);
  }

  @override
  Widget build(BuildContext context) {
    final content = snapshot.content;
    if (content is! RuntimeShopServiceContent) {
      return _InvalidShopOverlay(
        onClose: () => _emit(RuntimeWorldServiceAction.close),
      );
    }
    final quantity = _quantityItemId != null;
    final selected = content.entries
        .where((entry) => entry.itemId == content.selectedItemId)
        .firstOrNull;
    final selling = content.mode == RuntimeShopMode.sell;
    final l10n = context.playerL10n;
    final close = snapshot.isActionEnabled(RuntimeWorldServiceAction.close)
        ? () => _emit(RuntimeWorldServiceAction.close)
        : null;
    return PlayerMenuThemeScope(
      child: Builder(
        builder: (context) => PlayerMenuFrame(
          scrollable: false,
          header: PlayerMenuHeader(
            icon: Icons.storefront_outlined,
            title: quantity && selected != null
                ? '${selling ? l10n.shopSell : l10n.shopBuy} · ${selected.label}'
                : content.title,
            onBack: quantity ? _returnToList : close,
            secondary: Text('${content.money} ₽'),
            alignSecondaryEnd: true,
          ),
          footer: PlayerMenuFooter(
            hints: const [],
            actionsBuilder: (_, _) => PlayerMenuActionGroup(
              children: [
                if (quantity)
                  PlayerActionButton(
                    key: ValueKey(selling ? 'shop-sell' : 'shop-buy'),
                    label:
                        '${selling ? l10n.shopSell : l10n.shopBuy} · ${content.totalPrice} ₽',
                    icon: selling
                        ? Icons.sell_outlined
                        : Icons.shopping_bag_outlined,
                    onPressed:
                        snapshot.isActionEnabled(
                              RuntimeWorldServiceAction.confirm,
                            ) &&
                            selected != null
                        ? () => _emit(
                            RuntimeWorldServiceAction.confirm,
                            targetId: selected.itemId,
                            quantity: content.quantity,
                          )
                        : null,
                    disabledReason: snapshot.unavailableReasonFor(
                      RuntimeWorldServiceAction.confirm,
                    ),
                  ),
                if (quantity)
                  PlayerActionButton(
                    key: const ValueKey('shop-quantity-back'),
                    label: l10n.back,
                    secondary: true,
                    icon: Icons.arrow_back_rounded,
                    onPressed: _returnToList,
                  ),
                PlayerActionButton(
                  key: const ValueKey('shop-close'),
                  label: l10n.close,
                  secondary: true,
                  icon: Icons.close_rounded,
                  onPressed: close,
                ),
              ],
            ),
            returnAction: const SizedBox.shrink(),
          ),
          child: PlayerMenuDetailTransition(
            contentKey: ValueKey(
              quantity
                  ? 'quantity-$_quantityItemId'
                  : 'list-${content.mode.name}',
            ),
            child: quantity
                ? _ShopPurchasePanel(
                    snapshot: snapshot,
                    content: content,
                    onCommand: widget.onCommand,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ShopModeSwitcher(
                        mode: content.mode,
                        onBuy:
                            snapshot.isActionEnabled(
                              RuntimeWorldServiceAction.showPurchases,
                            )
                            ? () => _setMode(
                                RuntimeWorldServiceAction.showPurchases,
                              )
                            : null,
                        onSell:
                            snapshot.isActionEnabled(
                              RuntimeWorldServiceAction.showSales,
                            )
                            ? () =>
                                  _setMode(RuntimeWorldServiceAction.showSales)
                            : null,
                      ),
                      const SizedBox(height: 12),
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
                                          RuntimeWorldServiceAction.confirm,
                                        ) ??
                                        (selling
                                            ? l10n.shopBagEmpty
                                            : l10n.shopEmpty),
                                  ),
                                ],
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final inventory = _ShopInventory(
                                    snapshot: snapshot,
                                    content: content,
                                    onSelect: _select,
                                    columns:
                                        constraints.maxWidth >= 700 ||
                                            PlayerCompanionScope.of(context)
                                        ? 2
                                        : 1,
                                  );
                                  if (constraints.maxWidth < 700 ||
                                      selected == null) {
                                    return inventory;
                                  }
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(flex: 3, child: inventory),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 2,
                                        child: PlayerMenuPanel(
                                          padding: const EdgeInsets.all(12),
                                          child: PlayerPagedList(
                                            children: [
                                              Text(
                                                selected.label,
                                                style: context
                                                    .playerMenuTheme
                                                    .subtitle,
                                              ),
                                              Text(
                                                [
                                                  '${selected.unitPrice} ₽',
                                                  if (selling)
                                                    l10n.shopOwned(
                                                      selected.ownedQuantity,
                                                    ),
                                                  if (!selling &&
                                                      selected.remainingStock !=
                                                          null)
                                                    l10n.shopStock(
                                                      selected.remainingStock!,
                                                    ),
                                                ].join(' · '),
                                                style: context
                                                    .playerMenuTheme
                                                    .meta,
                                              ),
                                              if (selected.unavailableReason !=
                                                  null)
                                                Text(
                                                  selected.unavailableReason!,
                                                ),
                                              PlayerActionButton(
                                                key: const ValueKey(
                                                  'shop-open-quantity',
                                                ),
                                                icon:
                                                    Icons.shopping_bag_outlined,
                                                label: selling
                                                    ? l10n.shopSell
                                                    : l10n.shopBuy,
                                                onPressed:
                                                    snapshot.isActionEnabled(
                                                      RuntimeWorldServiceAction
                                                          .select,
                                                    )
                                                    ? () => _select(
                                                        selected.itemId,
                                                      )
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      if (snapshot.safeMessage case final message?
                          when message.trim().isNotEmpty)
                        Semantics(liveRegion: true, child: Text(message)),
                    ],
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
    widget.onCommand(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: snapshot.revision,
        targetId: targetId,
        quantity: quantity,
      ),
    );
  }
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
    required this.onSelect,
    this.columns = 1,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final RuntimeShopServiceContent content;
  final ValueChanged<String> onSelect;
  final int columns;

  Widget _entry(RuntimeShopEntrySnapshot entry) => _ShopEntry(
    entry: entry,
    mode: content.mode,
    selected: entry.itemId == content.selectedItemId,
    compact: columns > 1,
    onPressed: snapshot.isActionEnabled(RuntimeWorldServiceAction.select)
        ? () => onSelect(entry.itemId)
        : null,
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (content.message.isNotEmpty) ...[
        Text(content.message, style: context.playerMenuTheme.meta),
        const SizedBox(height: 8),
      ],
      Expanded(
        child: PlayerPagedList(
          key: ValueKey('shop-inventory-${content.mode.name}'),
          children: [
            for (
              var offset = 0;
              offset < content.entries.length;
              offset += columns
            )
              if (columns == 1)
                _entry(content.entries[offset])
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _entry(content.entries[offset])),
                    const SizedBox(width: 8),
                    Expanded(
                      child: offset + 1 < content.entries.length
                          ? _entry(content.entries[offset + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
          ],
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
    this.compact = false,
  });

  final RuntimeShopEntrySnapshot entry;
  final RuntimeShopMode mode;
  final bool selected;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stock = entry.remainingStock;
    final selling = mode == RuntimeShopMode.sell;
    final l10n = context.playerL10n;
    return PlayerMenuSelectableRow(
      key: ValueKey<String>('shop-item-${entry.itemId}'),
      id: entry.itemId,
      label: entry.label,
      leading: const Icon(Icons.inventory_2_outlined, size: 24),
      selected: selected,
      onPressed: onPressed,
      minimumHeight: compact ? 58 : 48,
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      contentGap: compact ? 8 : 12,
      subtitle: compact
          ? [
              selling && !entry.canTransact
                  ? l10n.shopUnsellable
                  : '${entry.unitPrice} ₽',
              if (selling) l10n.shopOwned(entry.ownedQuantity),
              if (!selling && stock != null) l10n.shopStock(stock),
            ].join(' · ')
          : null,
      trailingWidth: compact ? 16 : null,
      trailing: compact
          ? const Icon(Icons.chevron_right_rounded, size: 16)
          : Column(
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
    final selected = content.entries
        .where((entry) => entry.itemId == content.selectedItemId)
        .firstOrNull;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final balance = selling
        ? content.money + content.totalPrice
        : content.money - content.totalPrice;
    void emit(RuntimeWorldServiceAction action) => onCommand(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: snapshot.revision,
        targetId: content.selectedItemId,
        quantity: content.quantity,
      ),
    );
    return PlayerPagedList(
      key: const ValueKey('shop-quantity-review'),
      children: [
        if (snapshot.unavailableReasonFor(RuntimeWorldServiceAction.confirm)
            case final reason?)
          Text(reason),
        if (snapshot.safeMessage case final message?
            when message.trim().isNotEmpty)
          Semantics(liveRegion: true, child: Text(message)),
        if (selected != null)
          PlayerMenuPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(selected.label, style: context.playerMenuTheme.subtitle),
                Text(
                  '${french ? 'Prix unitaire' : 'Unit price'} : ${selected.unitPrice} ₽',
                ),
                if (selling) Text(l10n.shopOwned(selected.ownedQuantity)),
                if (!selling && selected.remainingStock != null)
                  Text(l10n.shopStock(selected.remainingStock!)),
              ],
            ),
          ),
        PlayerMenuPanel(
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('shop-quantity-minus'),
                tooltip: l10n.shopDecreaseQuantity,
                onPressed:
                    snapshot.isActionEnabled(
                      RuntimeWorldServiceAction.decreaseQuantity,
                    )
                    ? () => emit(RuntimeWorldServiceAction.decreaseQuantity)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '${l10n.shopQuantity} : ${content.quantity}',
                  textAlign: TextAlign.center,
                  style: context.playerMenuTheme.subtitle,
                ),
              ),
              IconButton(
                key: const ValueKey('shop-quantity-plus'),
                tooltip: l10n.shopIncreaseQuantity,
                onPressed:
                    snapshot.isActionEnabled(
                      RuntimeWorldServiceAction.increaseQuantity,
                    )
                    ? () => emit(RuntimeWorldServiceAction.increaseQuantity)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        PlayerMenuPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.shopTotal(content.totalPrice),
                style: context.playerMenuTheme.subtitle,
              ),
              Text('${french ? 'Argent' : 'Money'} : ${content.money} ₽'),
              Text(
                '${french ? 'Solde après' : 'Balance after'} : $balance ₽',
                key: const ValueKey('shop-balance-after'),
              ),
            ],
          ),
        ),
      ],
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
