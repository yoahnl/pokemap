import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_image.dart';
import '../foundation/player_input_scope.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_bag_strings.dart';
import 'player_pokemon_image.dart';
import 'runtime_player_party.dart';
import 'runtime_player_actions.dart';

final class RuntimePlayerBagNavigation extends ChangeNotifier {
  bool Function()? _back;
  Widget Function(BuildContext, Widget?)? _actions;

  bool back() => _back?.call() ?? false;
  Widget buildActions(BuildContext context, {Widget? returnAction}) =>
      _actions?.call(context, returnAction) ??
      returnAction ??
      const SizedBox.shrink();
  void refresh() => notifyListeners();
}

class RuntimePlayerBag extends StatefulWidget {
  const RuntimePlayerBag({
    super.key,
    required this.detail,
    this.onCommand,
    this.navigation,
    this.favoriteItemIds = const {},
    this.onFavoriteChanged,
  });

  final RuntimePlayerPauseDetailSnapshot detail;
  final FutureOr<void> Function(RuntimePlayerPauseCommand)? onCommand;
  final RuntimePlayerBagNavigation? navigation;
  final Set<String> favoriteItemIds;
  final Future<void> Function(String itemId, bool favorite)? onFavoriteChanged;

  @override
  State<RuntimePlayerBag> createState() => _RuntimePlayerBagState();
}

class _RuntimePlayerBagState extends State<RuntimePlayerBag> {
  static const _favorites = '@favorites';
  final _selections = <String, String>{};
  final _nodes = <String, FocusNode>{};
  final _detailFocus = FocusNode();
  final _descriptionFocus = FocusNode(debugLabel: 'Bag description');
  int _pocketPage = 0;
  String? _pocket;
  String? _failure;
  bool _showDetail = false;
  bool _busy = false;
  bool _targetDialogOpen = false;
  bool _initialFocusPending = true;
  String? _pendingItemFocus;

  String _text(String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  String _id(RuntimePlayerDetailEntrySnapshot e) => e.bagItem?.itemId ?? e.id;
  String _entryPocket(RuntimePlayerDetailEntrySnapshot e) =>
      e.bagItem?.pocketId ?? '';
  List<RuntimePlayerBagPocketSnapshot> get _pockets {
    final authored = widget.detail.bagPockets;
    final ids = <String>{...authored.map((p) => p.id)};
    return [
      ...authored,
      for (final entry in widget.detail.entries)
        if (ids.add(_entryPocket(entry)))
          RuntimePlayerBagPocketSnapshot(
            id: _entryPocket(entry),
            label: _entryPocket(entry).isEmpty
                ? widget.detail.title
                : _entryPocket(entry),
          ),
      if (widget.onFavoriteChanged != null)
        RuntimePlayerBagPocketSnapshot(
          id: _favorites,
          label: _text('Favoris', 'Favorites'),
        ),
    ];
  }

  List<RuntimePlayerDetailEntrySnapshot> _entries(String? pocket) => widget
      .detail
      .entries
      .where(
        (e) => pocket == _favorites
            ? widget.favoriteItemIds.contains(_id(e))
            : _entryPocket(e) == pocket,
      )
      .toList();
  List<RuntimePlayerDetailEntrySnapshot> get _visible => _entries(_pocket);
  RuntimePlayerDetailEntrySnapshot? get _selected =>
      _visible.where((e) => _id(e) == _selections[_pocket]).firstOrNull ??
      _visible.firstOrNull;
  FocusNode _node(String id) =>
      _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'Bag $id'));

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    widget.navigation?._back = _back;
    widget.navigation?._actions = _actions;
  }

  @override
  void didUpdateWidget(RuntimePlayerBag oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigation != widget.navigation) {
      oldWidget.navigation?._back = null;
      oldWidget.navigation?._actions = null;
      _bind();
    }
    final id = _selections[_pocket];
    if (id != null && !_visible.any((e) => _id(e) == id)) {
      final old = oldWidget.detail.entries
          .where(
            (e) => _pocket == _favorites
                ? oldWidget.favoriteItemIds.contains(_id(e))
                : _entryPocket(e) == _pocket,
          )
          .toList();
      final index = old.indexWhere((e) => _id(e) == id);
      if (_visible.isNotEmpty) {
        _selections[_pocket!] = _id(
          _visible[index.clamp(0, _visible.length - 1)],
        );
        _focusSelected();
      } else {
        _selections.remove(_pocket);
        _showDetail = false;
      }
    }
  }

  @override
  void dispose() {
    widget.navigation?._back = null;
    widget.navigation?._actions = null;
    for (final node in _nodes.values) {
      node.dispose();
    }
    _detailFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _focusSelected() {
    _pendingItemFocus = _selected == null ? null : _id(_selected!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreItemFocus());
  }

  void _restoreItemFocus() {
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    final id = _pendingItemFocus;
    if (id == null) return;
    final node = _node(id);
    if (node.context != null && node.canRequestFocus) {
      _pendingItemFocus = null;
      node.requestFocus();
    }
  }

  void _focusDetail() {
    final node = _detailFocus.context != null && _detailFocus.canRequestFocus
        ? _detailFocus
        : _descriptionFocus;
    if (node.context != null) node.requestFocus();
  }

  bool _back() {
    if (!_showDetail) return false;
    setState(() => _showDetail = false);
    _focusSelected();
    return true;
  }

  void _changePocket(String pocket) {
    setState(() {
      _pocket = pocket;
      _showDetail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pockets = _pockets;
    if (!pockets.any((p) => p.id == _pocket)) _pocket = pockets.firstOrNull?.id;
    if (_selected case final entry?) _selections[_pocket!] = _id(entry);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.navigation?.refresh();
        if (_initialFocusPending) {
          _initialFocusPending = false;
          _focusSelected();
        }
      }
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 300;
        return Column(
          key: const ValueKey('runtime-player-detail-bag'),
          children: [
            if (!_showDetail) ...[
              SizedBox(height: 48, child: _pocketBar(pockets, short: short)),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: _showDetail && _selected != null
                  ? _detail(_selected!)
                  : _list(),
            ),
            if (_failure ?? widget.detail.message case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  label: message,
                  excludeSemantics: true,
                  child: Text(
                    message,
                    key: const ValueKey('runtime-player-bag-message'),
                    style: context.playerMenuTheme.meta,
                  ),
                ),
              ),
            if (widget.navigation == null) _actions(context),
          ],
        );
      },
    );
  }

  Widget _pocketBar(
    List<RuntimePlayerBagPocketSnapshot> pockets, {
    required bool short,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final paged =
          pockets.length * 56 + (pockets.length - 1) * 8 > constraints.maxWidth;
      final count = ((constraints.maxWidth - (paged ? 112 : 0) + 8) / 64)
          .floor()
          .clamp(1, pockets.length.clamp(1, 100));
      final pages = (pockets.length / count).ceil().clamp(1, 100);
      final tabWidth =
          (constraints.maxWidth - (paged ? 112 : 0) - (count - 1) * 8) / count;
      final showText =
          (tabWidth >= 96 || pockets.length <= 5 && tabWidth >= 56) &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3;
      _pocketPage = _pocketPage.clamp(0, pages - 1);
      void focusPocket(int index) {
        final chosen = index.clamp(0, pockets.length - 1);
        setState(() {
          _pocketPage = chosen ~/ count;
          _pocket = pockets[chosen].id;
          _showDetail = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _node('pocket-${pockets[chosen].id}').requestFocus();
        });
      }

      Widget arrow(bool forward) => SizedBox(
        width: 48,
        child: PlayerMenuSelectableRow(
          key: ValueKey(forward ? 'bag-pockets-next' : 'bag-pockets-previous'),
          id: forward ? 'bag-pockets-next' : 'bag-pockets-previous',
          label: '',
          iconOnly: true,
          integrated: true,
          semanticValue: forward
              ? _text('Poches suivantes', 'Next pockets')
              : _text('Poches précédentes', 'Previous pockets'),
          leading: Icon(forward ? Icons.chevron_right : Icons.chevron_left),
          onPressed: () => focusPocket(
            forward ? (_pocketPage + 1) * count : _pocketPage * count - 1,
          ),
        ),
      );
      return Row(
        key: const ValueKey('bag-pockets'),
        children: [
          if (paged) ...[
            if (_pocketPage > 0) arrow(false) else const SizedBox(width: 48),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Row(
              children: [
                for (
                  var index = _pocketPage * count;
                  index < pockets.length && index < (_pocketPage + 1) * count;
                  index++
                ) ...[
                  if (index > _pocketPage * count) const SizedBox(width: 8),
                  Expanded(
                    child: Actions(
                      actions: {
                        RuntimePlayerLogicalIntent:
                            CallbackAction<RuntimePlayerLogicalIntent>(
                              onInvoke: (intent) {
                                if (intent.action == PlayerInputAction.left ||
                                    intent.action == PlayerInputAction.right) {
                                  focusPocket(
                                    index +
                                        (intent.action ==
                                                PlayerInputAction.right
                                            ? 1
                                            : -1),
                                  );
                                  return null;
                                }
                                return Actions.invoke(context, intent);
                              },
                            ),
                      },
                      child: Focus(
                        onKeyEvent: (_, event) {
                          if (event is! KeyDownEvent) {
                            return KeyEventResult.ignored;
                          }
                          final direction =
                              event.logicalKey == LogicalKeyboardKey.arrowRight
                              ? 1
                              : event.logicalKey == LogicalKeyboardKey.arrowLeft
                              ? -1
                              : 0;
                          if (direction == 0) return KeyEventResult.ignored;
                          focusPocket(index + direction);
                          return KeyEventResult.handled;
                        },
                        child: Tooltip(
                          message: pockets[index].label,
                          child: PlayerMenuSelectableRow(
                            key: ValueKey('bag-pocket-${pockets[index].id}'),
                            id: 'bag-pocket-${pockets[index].id}',
                            label: pockets[index].label,
                            tab: true,
                            integrated: true,
                            iconOnly: !showText,
                            reserveFocusMarker: !showText,
                            labelMaxLines: 2,
                            labelStyle: context.playerMenuTheme.label.copyWith(
                              fontSize: tabWidth < 120 ? 12 : 14,
                              height: 1.25,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: showText
                                ? null
                                : Icon(
                                    _pocketIcon(pockets[index].id),
                                    size: 28,
                                  ),
                            selected: pockets[index].id == _pocket,
                            focusNode: _node('pocket-${pockets[index].id}'),

                            onPressed: () => _changePocket(pockets[index].id),
                            onFocusChanged: (focused) {
                              if (focused) _changePocket(pockets[index].id);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (paged) ...[
            const SizedBox(width: 8),
            if (_pocketPage + 1 < pages)
              arrow(true)
            else
              const SizedBox(width: 48),
          ],
        ],
      );
    },
  );

  IconData _pocketIcon(String id) => switch (id.replaceAll('_', '-')) {
    '@favorites' => Icons.star_rounded,
    'medicine' => Icons.medication_rounded,
    'balls' => Icons.catching_pokemon,
    'berries' => Icons.spa_rounded,
    'machines' => Icons.album_rounded,
    'battle-items' => Icons.shield_rounded,
    'key-items' => Icons.vpn_key_rounded,
    'held-items' => Icons.diamond_outlined,
    'evolution-items' => Icons.auto_awesome_rounded,
    _ => Icons.inventory_2_rounded,
  };

  Widget _list() {
    if (_visible.isEmpty) {
      return PlayerEmptyState(
        key: const ValueKey('bag-pocket-empty'),
        icon: Icons.backpack_outlined,
        title:
            _pockets.where((p) => p.id == _pocket).firstOrNull?.label ??
            widget.detail.title,
        message: widget.detail.entries.isEmpty
            ? widget.detail.emptyMessage ??
                  _text('Votre sac est vide.', 'Your bag is empty.')
            : _text('Cette poche est vide.', 'This pocket is empty.'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final companion = PlayerCompanionScope.of(context);
        final landscape = MediaQuery.sizeOf(context).aspectRatio > 1;
        final columns = MediaQuery.textScalerOf(context).scale(1) >= 1.5
            ? (landscape && constraints.maxWidth >= 600 ? 2 : 1)
            : landscape || companion
            ? (companion || constraints.maxWidth < 600 ? 2 : 3)
            : 1;
        return PlayerPagedList(
          key: ValueKey('bag-list-$_pocket'),
          sideNavigation: constraints.maxHeight < 240 && _visible.length > 6,
          onPageReady: _restoreItemFocus,
          revealChildKey: ValueKey(
            'bag-list-row-$_pocket-${(_visible.indexOf(_selected!) ~/ columns) * columns}',
          ),
          children: [
            for (var i = 0; i < _visible.length; i += columns)
              KeyedSubtree(
                key: ValueKey('bag-list-row-$_pocket-$i'),
                child: columns == 1
                    ? _itemRow(
                        _visible[i],
                        compact: constraints.maxHeight < 496,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var column = 0; column < columns; column++) ...[
                            if (column > 0) const SizedBox(width: 8),
                            Expanded(
                              child: i + column < _visible.length
                                  ? _itemRow(
                                      _visible[i + column],
                                      compact: true,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
              ),
          ],
        );
      },
    );
  }

  Widget _itemRow(
    RuntimePlayerDetailEntrySnapshot entry, {
    bool compact = false,
  }) {
    final id = _id(entry);
    final favorite = widget.favoriteItemIds.contains(id);
    final quantityWidth = (compact ? 36.0 : 40.0) + (favorite ? 16 : 0);
    final row = PlayerMenuSelectableRow(
      key: ValueKey('bag-item-$id'),
      id: 'bag-item-$id',
      label: entry.title,
      reserveFocusMarker: false,
      contentGap: 8,
      supportingContent: compact
          ? null
          : Text(
              entry.bagItem?.description ?? entry.subtitle ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.35,
                color: id == _id(_selected!)
                    ? context.playerMenuTheme.selectionText.withValues(
                        alpha: .75,
                      )
                    : context.playerMenuTheme.secondary,
              ),
            ),
      selected: id == _id(_selected!),
      focusNode: _node(id),
      minimumHeight: compact ? 56 : 76,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 12,
        vertical: compact ? 8 : 10,
      ),
      labelMaxLines: 1,
      labelStyle: context.playerMenuTheme.label.copyWith(
        fontSize: compact ? 14 : 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      leading: PlayerCompanionScope.of(context)
          ? null
          : PlayerBagItemImage(entry: entry, size: compact ? 24 : 32),
      semanticValue: '${entry.bagItem?.quantity ?? entry.trailingLabel ?? ''}',
      trailing: SizedBox(
        key: ValueKey('bag-quantity-$id'),
        width: quantityWidth,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (favorite) ...[
              Icon(
                Icons.star_rounded,
                key: ValueKey('bag-favorite-marker-$id'),
                size: 12,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                '× ${entry.bagItem?.quantity ?? entry.trailingLabel ?? '—'}',
                maxLines: 1,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      trailingWidth: quantityWidth,
      onFocusChanged: (focused) {
        if (focused && _selections[_pocket!] != id) {
          _pendingItemFocus = id;
          setState(() => _selections[_pocket!] = id);
        }
      },
      onPressed: _busy
          ? null
          : () {
              setState(() => _selections[_pocket!] = id);
              final action = entry.bagAction;
              if (action?.isEnabled == true && widget.onCommand != null) {
                unawaited(_use(entry, action!));
              } else {
                setState(
                  () => _failure =
                      action?.unavailableReason ??
                      _text(
                        'Cet objet ne peut pas être utilisé ici.',
                        'This item cannot be used here.',
                      ),
                );
              }
            },
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: row),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: compact ? 56 : 76,
          child: IconButton(
            key: ValueKey('bag-info-$id'),
            tooltip: '${_text('Informations', 'Information')} · ${entry.title}',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _selections[_pocket!] = id;
                      _showDetail = true;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _focusDetail();
                    });
                  },
            style: IconButton.styleFrom(
              foregroundColor: context.playerMenuTheme.secondary,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: context.playerMenuTheme.border),
              ),
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ),
      ],
    );
  }

  Widget _detail(RuntimePlayerDetailEntrySnapshot entry) => Focus(
    focusNode: _descriptionFocus,
    child: PlayerMenuPanel(
      key: ValueKey('bag-detail-${_id(entry)}'),
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = context.playerMenuTheme;
          final short = constraints.maxHeight < 250;
          final description =
              entry.bagItem?.description ??
              entry.subtitle ??
              _text(
                'Aucune description disponible.',
                'No description available.',
              );
          final chunks = <String>[];
          var chunk = '';
          final pageHeight = (constraints.maxHeight - 64).clamp(
            32.0,
            double.infinity,
          );
          for (final word in description.split(RegExp(r'\s+'))) {
            final candidate = chunk.isEmpty ? word : '$chunk $word';
            final measure = TextPainter(
              text: TextSpan(text: candidate, style: theme.body),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: constraints.maxWidth);
            final overflows = measure.height > pageHeight;
            measure.dispose();
            if (overflows && chunk.isNotEmpty) {
              chunks.add(chunk);
              chunk = word;
            } else {
              chunk = candidate;
            }
          }
          if (chunk.isNotEmpty) chunks.add(chunk);
          return PlayerPagedList(
            key: ValueKey(
              'bag-description-${_id(entry)}-${constraints.maxWidth}-${constraints.maxHeight}-${MediaQuery.textScalerOf(context).scale(1)}',
            ),
            children: [
              Row(
                children: [
                  ColoredBox(
                    color: theme.recessed,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PlayerBagItemImage(
                        entry: entry,
                        size: short ? 32 : 48,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      entry.title,
                      style: theme.subtitle.copyWith(
                        fontSize: short ? 18 : 22,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (entry.bagItem?.quantity case final quantity?) ...[
                    const SizedBox(width: 8),
                    Text(
                      '× $quantity',
                      key: ValueKey('bag-detail-quantity-${_id(entry)}'),
                      style: theme.numbers,
                    ),
                  ],
                ],
              ),
              for (var index = 0; index < chunks.length; index++)
                Text(
                  chunks[index],
                  key: ValueKey('bag-description-chunk-$index'),
                  style: theme.body,
                ),
              if (entry.bagAction?.unavailableReason case final reason?)
                Text(reason, style: theme.meta),
            ],
          );
        },
      ),
    ),
  );

  Widget _actions(BuildContext context, [Widget? returnAction]) {
    final entry = _selected;
    if (entry == null) return returnAction ?? const SizedBox.shrink();
    final action = entry.bagAction;
    final children = <Widget>[
      if (_showDetail && action?.isEnabled == true && widget.onCommand != null)
        PlayerMenuSelectableRow(
          key: ValueKey('runtime-player-bag-use-${action!.itemTargetId}'),
          id: 'runtime-player-bag-use-${action.itemTargetId}',
          integrated: returnAction == null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          label: PlayerBagStrings.of(context).use,
          focusNode: _detailFocus,
          leading: const Icon(Icons.healing),
          busy: _busy,
          onPressed: _busy ? null : () => _use(entry, action),
        ),
      if (widget.onFavoriteChanged != null)
        Tooltip(
          message: widget.favoriteItemIds.contains(_id(entry))
              ? _text('Retirer des favoris', 'Remove from favorites')
              : _text('Ajouter aux favoris', 'Add to favorites'),
          child: PlayerMenuSelectableRow(
            key: ValueKey('bag-favorite-${_id(entry)}'),
            focusNode: action?.isEnabled == true && widget.onCommand != null
                ? null
                : _detailFocus,
            id: 'bag-favorite-${_id(entry)}',
            integrated: returnAction == null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            label: _text('Favori', 'Favorite'),
            semanticValue: widget.favoriteItemIds.contains(_id(entry))
                ? _text('Retirer des favoris', 'Remove from favorites')
                : _text('Ajouter aux favoris', 'Add to favorites'),
            leading: Icon(
              widget.favoriteItemIds.contains(_id(entry))
                  ? Icons.star
                  : Icons.star_border,
            ),
            busy: _busy,
            onPressed: _busy
                ? null
                : () => _run(
                    () => widget.onFavoriteChanged!(
                      _id(entry),
                      !widget.favoriteItemIds.contains(_id(entry)),
                    ),
                  ),
          ),
        ),
    ];
    return PlayerMenuThemeScope(
      role: ProjectPresentationSurfaceRole.bag,
      child: returnAction == null
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final child in children) IntrinsicWidth(child: child),
              ],
            )
          : children.isEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
              width: 88 * MediaQuery.textScalerOf(context).scale(1),
              child: returnAction,
            ),
            )
          : PlayerMenuActionGroup(children: [...children, returnAction]),
    );
  }

  Future<void> _use(
    RuntimePlayerDetailEntrySnapshot entry,
    RuntimePlayerBagItemActionSnapshot action,
  ) async {
    if (_busy ||
        _targetDialogOpen ||
        !action.isEnabled ||
        widget.onCommand == null) {
      return;
    }
    final eligible = widget.detail.bagTargets
        .where((target) => action.allowsPartyTarget(target.targetId))
        .toList();
    final world = action.targetKind == RuntimePlayerBagUseTargetKind.world;
    if (!world && eligible.isEmpty) {
      setState(
        () => _failure = _text(
          'Aucun compagnon ne peut recevoir cet objet.',
          'No companion can receive this item.',
        ),
      );
      return;
    }
    if (!action.requiresConfirmation &&
        (world ||
            action.targetKind == RuntimePlayerBagUseTargetKind.partyMember &&
                eligible.length == 1)) {
      await _run(
        () async => await widget.onCommand!(
          RuntimePlayerPauseCommand.useBagItem(
            itemTargetId: action.itemTargetId,
            partyTargetId: world ? '' : eligible.single.targetId,
          ),
        ),
      );
      if (mounted) _focusSelected();
      return;
    }
    _targetDialogOpen = true;
    final locale = Localizations.localeOf(context);
    final mediaQuery = MediaQuery.of(context);
    final opaque = context.playerMenuTheme.opaque;
    RuntimePlayerPauseCommand? command;
    try {
      command = await showDialog<RuntimePlayerPauseCommand>(
        context: context,
        builder: (context) => Localizations.override(
          context: context,
          locale: locale,
          delegates: PokeMapPlayerLocalizations.localizationsDelegates,
          child: MediaQuery(
            data: mediaQuery,
            child: PlayerMenuThemeScope(
              role: ProjectPresentationSurfaceRole.bag,
              opaque: opaque,
              child: _BagTargetDialog(
                entry: entry,
                action: action,
                targets: widget.detail.bagTargets,
              ),
            ),
          ),
        ),
      );
    } finally {
      _targetDialogOpen = false;
    }
    if (!mounted) return;
    if (command case final acceptedCommand?) {
      await _run(() async => await widget.onCommand!(acceptedCommand));
    }
    if (mounted) _focusSelected();
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await operation();
    } on RuntimePlayerPartyCommandFailure catch (e) {
      if (mounted) _failure = e.safeMessage;
    } catch (_) {
      if (mounted) {
        _failure = _text(
          'Cette action a échoué. Réessayez.',
          'The action failed. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class PlayerBagItemImage extends StatelessWidget {
  const PlayerBagItemImage({
    super.key,
    required this.entry,
    required this.size,
  });
  final RuntimePlayerDetailEntrySnapshot entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = entry.bagItem?.iconFilePath;
    final placeholder = Icon(
      Icons.inventory_2_outlined,
      key: ValueKey('bag-image-missing-${entry.id}'),
      size: size,
      color: IconTheme.of(context).color ?? context.playerMenuTheme.text,
    );
    return Semantics(
      image: true,
      label: entry.title,
      child: SizedBox(
        width: size,
        height: size,
        child: path == null
            ? placeholder
            : PlayerFileImage(
                path: path,
                key: ValueKey('${entry.id}-$path-$size'),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                fallback: placeholder,
              ),
      ),
    );
  }
}

class _BagTargetDialog extends StatefulWidget {
  const _BagTargetDialog({
    required this.entry,
    required this.action,
    required this.targets,
  });
  final RuntimePlayerDetailEntrySnapshot entry;
  final RuntimePlayerBagItemActionSnapshot action;
  final List<RuntimePlayerBagPartyTargetSnapshot> targets;
  @override
  State<_BagTargetDialog> createState() => _BagTargetDialogState();
}

class _BagTargetDialogState extends State<_BagTargetDialog> {
  final _targetFocus = FocusNode();
  final _moveFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _backFocus = FocusNode();
  RuntimePlayerBagPartyTargetSnapshot? _target;
  RuntimePlayerBagMoveTargetSnapshot? _move;
  bool _confirm = false;
  bool _submitted = false;
  String _text(String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  bool get _isWorld =>
      widget.action.targetKind == RuntimePlayerBagUseTargetKind.world;
  bool get _needsMove =>
      widget.action.targetKind == RuntimePlayerBagUseTargetKind.partyMove ||
      widget.action.targetKind ==
              RuntimePlayerBagUseTargetKind.partyMoveReplacement &&
          _target!.requiresMoveReplacement;

  String? get _firstEligibleTargetId => widget.targets
      .where(
        (target) =>
            widget.action.allowsPartyTarget(target.targetId) &&
            widget.action.unavailablePartyTargetReasons[target.targetId] ==
                null,
      )
      .firstOrNull
      ?.targetId;

  @override
  void initState() {
    super.initState();
    final eligible = widget.targets
        .where((target) => widget.action.allowsPartyTarget(target.targetId))
        .toList();
    if (!_isWorld && eligible.length == 1) {
      _target = eligible.single;
      _confirm = !_needsMove;
    }
    _focusCurrentStage();
  }

  @override
  void dispose() {
    _targetFocus.dispose();
    _moveFocus.dispose();
    _confirmFocus.dispose();
    _backFocus.dispose();
    super.dispose();
  }

  void _focusCurrentStage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _submitted ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final node = _isWorld
          ? _confirmFocus
          : _target == null
          ? (_firstEligibleTargetId == null ? _backFocus : _targetFocus)
          : _confirm
          ? _confirmFocus
          : (_target!.moves.isEmpty ? _backFocus : _moveFocus);
      node.requestFocus();
      final targetContext = node.context;
      if (targetContext != null) {
        Scrollable.ensureVisible(targetContext, alignment: .5);
      }
    });
  }

  void _submit() {
    if (_submitted) return;
    setState(() => _submitted = true);
    Navigator.of(context).pop(
      RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: widget.action.itemTargetId,
        partyTargetId: _target?.targetId ?? '',
        moveTargetId: _move?.targetId,
      ),
    );
  }

  void _back() {
    if (_confirm && _needsMove) {
      setState(() {
        _confirm = false;
        _move = null;
      });
      _focusCurrentStage();
    } else if (_target != null) {
      setState(() {
        _target = null;
        _move = null;
        _confirm = false;
      });
      _focusCurrentStage();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _target == null || _submitted,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: RuntimePlayerActions(
      onBack: _back,
      onMenu: _back,
      onInputSourceChanged: (_) {},
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 560,
          height: (MediaQuery.sizeOf(context).height - 32).clamp(160.0, 640.0),
          child: PlayerMenuPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${PlayerBagStrings.of(context).use} ${widget.entry.title}',
                        style: context.playerMenuTheme.subtitle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 132,
                      child: PlayerActionButton(
                        key: const ValueKey('runtime-player-bag-target-close'),
                        focusNode: _backFocus,
                        label: context.playerL10n.back,
                        icon: Icons.arrow_back,
                        secondary: true,
                        onPressed: _back,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: PlayerPagedList(children: _choices(context))),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _choices(BuildContext context) {
    if (_isWorld || _confirm) {
      return [
        if (_target != null)
          Text(_target!.label, style: context.playerMenuTheme.subtitle),
        Text(
          widget.action.targetKind ==
                  RuntimePlayerBagUseTargetKind.partyMoveReplacement
              ? '${_text('Apprendre', 'Learn')} ${widget.action.learnedMoveLabel ?? widget.entry.title}'
                    '${_move == null ? '' : ' — ${_text('oublier', 'forget')} ${_move!.label}'}'
              : widget.entry.title,
          style: context.playerMenuTheme.body,
        ),
        PlayerActionButton(
          key: const ValueKey('bag-use-confirm'),
          focusNode: _confirmFocus,
          label: _text('Confirmer', 'Confirm'),
          icon: Icons.check,
          onPressed: _submitted ? null : _submit,
        ),
      ];
    }
    if (_target == null) {
      return [
        for (final target in widget.targets)
          PlayerMenuSelectableRow(
            key: ValueKey('runtime-player-bag-target-${target.targetId}'),
            id: 'runtime-player-bag-target-${target.targetId}',
            focusNode: target.targetId == _firstEligibleTargetId
                ? _targetFocus
                : null,
            label: target.label,
            subtitle: target.subtitle,
            leading: target.pokemonSummary == null
                ? null
                : PlayerPokemonImage(
                    summary: target.pokemonSummary!,
                    thumbnail: true,
                    width: 48,
                    height: 48,
                  ),
            disabledReason:
                widget.action.unavailablePartyTargetReasons[target.targetId] ??
                (widget.action.allowsPartyTarget(target.targetId)
                    ? null
                    : _text('Non compatible.', 'Not compatible.')),
            onPressed: () {
              _target = target;
              if (!_needsMove && !widget.action.requiresConfirmation) {
                _submit();
              } else {
                setState(() => _confirm = !_needsMove);
                _focusCurrentStage();
              }
            },
          ),
      ];
    }
    return [
      Text(_target!.label, style: context.playerMenuTheme.label),
      for (final move in _target!.moves)
        PlayerMenuSelectableRow(
          key: ValueKey(
            'runtime-player-bag-target-${_target!.targetId}-${move.targetId}',
          ),
          id: 'runtime-player-bag-target-${_target!.targetId}-${move.targetId}',
          focusNode: move == _target!.moves.first ? _moveFocus : null,
          label: move.label,
          subtitle: move.subtitle,
          onPressed: () {
            _move = move;
            if (!widget.action.requiresConfirmation) {
              _submit();
            } else {
              setState(() => _confirm = true);
              _focusCurrentStage();
            }
          },
        ),
    ];
  }
}
