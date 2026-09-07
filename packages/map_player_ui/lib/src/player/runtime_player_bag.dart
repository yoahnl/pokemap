import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
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
  const RuntimePlayerBag(
      {super.key,
      required this.detail,
      this.onCommand,
      this.navigation,
      this.favoriteItemIds = const {},
      this.onFavoriteChanged});

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
  final _scrolls = <String, ScrollController>{};
  final _listStorage = PageStorageBucket();
  final _nodes = <String, FocusNode>{};
  final _pocketsScroll = ScrollController();
  final _detailFocus = FocusNode();
  final _descriptionFocus = FocusNode(debugLabel: 'Bag description');
  final _descriptionScrolls = <String, ScrollController>{};
  String? _pocket;
  String? _failure;
  bool _showDetail = false;
  bool _busy = false;
  bool _targetDialogOpen = false;
  bool _initialFocusPending = true;

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
                  : _entryPocket(entry)),
      if (widget.onFavoriteChanged != null)
        RuntimePlayerBagPocketSnapshot(
            id: _favorites, label: _text('Favoris', 'Favorites')),
    ];
  }

  List<RuntimePlayerDetailEntrySnapshot> _entries(String? pocket) =>
      widget.detail.entries
          .where((e) => pocket == _favorites
              ? widget.favoriteItemIds.contains(_id(e))
              : _entryPocket(e) == pocket)
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
    _pocketsScroll.addListener(_restorePocketArrowFocus);
    _bind();
  }

  void _restorePocketArrowFocus() {
    if (!_pocketsScroll.hasClients) return;
    final pockets = _pockets;
    if (pockets.isEmpty) return;
    final position = _pocketsScroll.position;
    final pocket =
        position.pixels <= .5 && _nodes['pockets-previous']?.hasFocus == true
            ? pockets.first
            : position.pixels >= position.maxScrollExtent - .5 &&
                    _nodes['pockets-next']?.hasFocus == true
                ? pockets.last
                : null;
    if (pocket != null) _node('pocket-${pocket.id}').requestFocus();
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
          .where((e) => _pocket == _favorites
              ? oldWidget.favoriteItemIds.contains(_id(e))
              : _entryPocket(e) == _pocket)
          .toList();
      final index = old.indexWhere((e) => _id(e) == id);
      if (_visible.isNotEmpty) {
        _selections[_pocket!] =
            _id(_visible[index.clamp(0, _visible.length - 1)]);
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
    for (final controller in _scrolls.values) {
      controller.dispose();
    }
    for (final node in _nodes.values) {
      node.dispose();
    }
    _pocketsScroll.dispose();
    _detailFocus.dispose();
    _descriptionFocus.dispose();
    for (final controller in _descriptionScrolls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _focusSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      final entry = _selected;
      final row = entry == null ? null : _node(_id(entry));
      if (row?.context != null) {
        row!.requestFocus();
      } else {
        _focusDetail();
      }
    });
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
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 760 ||
          constraints.maxWidth < 1024 &&
              constraints.maxHeight > constraints.maxWidth ||
          MediaQuery.textScalerOf(context).scale(1) >= 1.8;
      final short = constraints.maxHeight < 250;
      return Column(
          key: const ValueKey('runtime-player-detail-bag'),
          children: [
            if (!_showDetail || !compact) ...[
              SizedBox(
                  height: short
                      ? 48
                      : MediaQuery.textScalerOf(context).scale(1) > 1.5
                          ? 72
                          : 56,
                  child: _pocketBar(pockets, short: short)),
              SizedBox(height: short ? 8 : 16),
            ],
            Expanded(
                child: compact
                    ? _showDetail && _selected != null
                        ? _detail(_selected!)
                        : _list(compact, showTitle: !short)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            Expanded(flex: 30, child: _list(false)),
                            const SizedBox(width: 24),
                            Expanded(
                                flex: 23,
                                child: _selected == null
                                    ? const SizedBox.shrink()
                                    : _detail(_selected!)),
                          ])),
            if (_failure ?? widget.detail.message case final message?)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                      liveRegion: true,
                      label: message,
                      excludeSemantics: true,
                      child: Text(message,
                          key: const ValueKey('runtime-player-bag-message'),
                          style: context.playerMenuTheme.meta))),
            if (widget.navigation == null) _actions(context),
          ]);
    });
  }

  Widget _pocketBar(List<RuntimePlayerBagPocketSnapshot> pockets,
      {required bool short}) {
    const width = 72.0;
    void focusPocket(int index) {
      final pocket = pockets[index.clamp(0, pockets.length - 1)];
      _changePocket(pocket.id);
      _node('pocket-${pocket.id}').requestFocus();
    }

    Widget arrow(bool forward, bool enabled) {
      final label = forward
          ? _text('Poches suivantes', 'Next pockets')
          : _text('Poches précédentes', 'Previous pockets');
      return SizedBox(
        width: 56,
        child: Tooltip(
          message: label,
          child: PlayerMenuSelectableRow(
            key:
                ValueKey(forward ? 'bag-pockets-next' : 'bag-pockets-previous'),
            id: forward ? 'bag-pockets-next' : 'bag-pockets-previous',
            label: '',
            semanticValue: label,
            focusNode: _node(forward ? 'pockets-next' : 'pockets-previous'),
            iconOnly: true,
            integrated: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(forward ? Icons.chevron_right : Icons.chevron_left,
                size: 20),
            onPressed: enabled
                ? () {
                    final position = _pocketsScroll.position;
                    _pocketsScroll.animateTo(
                      (position.pixels +
                              (forward ? 1 : -1) *
                                  position.viewportDimension *
                                  .8)
                          .clamp(0, position.maxScrollExtent),
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                    );
                  }
                : null,
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final overflows = pockets.length * width +
              (pockets.isEmpty ? 0 : pockets.length - 1) * 8 >
          constraints.maxWidth;
      return AnimatedBuilder(
        animation: _pocketsScroll,
        builder: (_, __) => Row(children: [
          if (overflows) ...[
            if (_pocketsScroll.hasClients && _pocketsScroll.offset > .5)
              arrow(false, true)
            else
              const SizedBox(width: 56),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: FocusTraversalGroup(
              child: SingleChildScrollView(
                key: const ValueKey('bag-pockets'),
                controller: _pocketsScroll,
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < pockets.length; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      SizedBox(
                        width: width,
                        child: Actions(
                          actions: {
                            RuntimePlayerLogicalIntent:
                                CallbackAction<RuntimePlayerLogicalIntent>(
                                    onInvoke: (intent) {
                              if (intent.action == PlayerInputAction.left ||
                                  intent.action == PlayerInputAction.right) {
                                focusPocket(index +
                                    (intent.action == PlayerInputAction.right
                                        ? 1
                                        : -1));
                                return null;
                              }
                              return Actions.invoke(context, intent);
                            }),
                          },
                          child: Focus(
                            onKeyEvent: (_, event) {
                              if (event is! KeyDownEvent) {
                                return KeyEventResult.ignored;
                              }
                              final direction = event.logicalKey ==
                                      LogicalKeyboardKey.arrowRight
                                  ? 1
                                  : event.logicalKey ==
                                          LogicalKeyboardKey.arrowLeft
                                      ? -1
                                      : 0;
                              if (direction == 0) return KeyEventResult.ignored;
                              focusPocket(index + direction);
                              return KeyEventResult.handled;
                            },
                            child: Tooltip(
                              message: pockets[index].label,
                              child: PlayerMenuSelectableRow(
                                id: 'bag-pocket-${pockets[index].id}',
                                key:
                                    ValueKey('bag-pocket-${pockets[index].id}'),
                                label: pockets[index].label,
                                iconOnly: true,
                                integrated: true,
                                labelMaxLines: 1,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                selected: pockets[index].id == _pocket,
                                focusNode: _node('pocket-${pockets[index].id}'),
                                leading: Icon(_pocketIcon(pockets[index].id),
                                    size: 28),
                                onPressed: () =>
                                    _changePocket(pockets[index].id),
                                onFocusChanged: (focused) {
                                  if (!focused) return;
                                  _changePocket(pockets[index].id);
                                  final target =
                                      _node('pocket-${pockets[index].id}')
                                          .context;
                                  if (target != null) {
                                    Scrollable.ensureVisible(target,
                                        alignment: .5);
                                  }
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
            ),
          ),
          if (overflows) ...[
            const SizedBox(width: 4),
            if (!_pocketsScroll.hasClients ||
                _pocketsScroll.offset <
                    _pocketsScroll.position.maxScrollExtent - .5)
              arrow(true, true)
            else
              const SizedBox(width: 56),
          ],
        ]),
      );
    });
  }

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

  Widget _list(bool compact, {bool showTitle = true}) {
    if (_visible.isEmpty) {
      return PlayerEmptyState(
          key: const ValueKey('bag-pocket-empty'),
          icon: Icons.backpack_outlined,
          title: _pockets.where((p) => p.id == _pocket).firstOrNull?.label ??
              widget.detail.title,
          message: widget.detail.entries.isEmpty
              ? widget.detail.emptyMessage ??
                  _text('Votre sac est vide.', 'Your bag is empty.')
              : _text('Cette poche est vide.', 'This pocket is empty.'));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (showTitle) ...[
        Text(_pockets.firstWhere((p) => p.id == _pocket).label,
            style: context.playerMenuTheme.label),
        const SizedBox(height: 12),
      ],
      Expanded(
          child: PageStorage(
              bucket: _listStorage,
              child: FocusTraversalGroup(
                  key: PageStorageKey('bag-scroll-pocket-$_pocket'),
                  child: ListView.separated(
                    key: ValueKey('bag-list-$_pocket'),
                    controller:
                        _scrolls.putIfAbsent(_pocket!, ScrollController.new),
                    itemCount: _visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = _visible[index];
                      final id = _id(entry);
                      return PlayerMenuSelectableRow(
                        key: ValueKey('bag-item-$id'),
                        id: 'bag-item-$id',
                        label: entry.title,
                        selected: id == _id(_selected!),
                        focusNode: _node(id),
                        minimumHeight: 52,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4.5),
                        leading: PlayerBagItemImage(entry: entry, size: 40),
                        semanticValue:
                            '${entry.bagItem?.quantity ?? entry.trailingLabel ?? ''}',
                        trailing: SizedBox(
                            key: ValueKey('bag-quantity-$id'),
                            width: 72,
                            child: Text(
                                '${widget.favoriteItemIds.contains(id) ? '★ ' : ''}× ${entry.bagItem?.quantity ?? entry.trailingLabel ?? '—'}',
                                textAlign: TextAlign.right)),
                        trailingWidth: 72,
                        onFocusChanged: (focused) {
                          if (focused) {
                            setState(() => _selections[_pocket!] = id);
                          }
                        },
                        onPressed: () {
                          setState(() {
                            _selections[_pocket!] = id;
                            _showDetail = compact;
                          });
                          if (compact) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _focusDetail();
                            });
                          }
                        },
                      );
                    },
                  )))),
    ]);
  }

  Widget _detail(RuntimePlayerDetailEntrySnapshot entry) {
    final controller =
        _descriptionScrolls.putIfAbsent(_id(entry), ScrollController.new);
    void scroll(double direction) {
      if (!controller.hasClients) return;
      controller.animateTo(
          (controller.offset + direction * 120)
              .clamp(0, controller.position.maxScrollExtent),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut);
    }

    return Actions(
        actions: {
          RuntimePlayerLogicalIntent:
              CallbackAction<RuntimePlayerLogicalIntent>(onInvoke: (intent) {
            if (intent.action == PlayerInputAction.down ||
                intent.action == PlayerInputAction.up) {
              scroll(intent.action == PlayerInputAction.down ? 1 : -1);
              return null;
            }
            return Actions.invoke(context, intent);
          }),
        },
        child: Focus(
            focusNode: _descriptionFocus,
            onKeyEvent: (_, event) {
              if (event is KeyUpEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                  event.logicalKey == LogicalKeyboardKey.arrowUp) {
                scroll(
                    event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Semantics(
                label: entry.title,
                child: LayoutBuilder(builder: (context, constraints) {
                  final short = constraints.hasBoundedHeight &&
                      constraints.maxHeight < 320 &&
                      constraints.maxWidth >= 400;
                  final padding = short ? 16.0 : 24.0;
                  final imageSize = short
                      ? (constraints.maxHeight - padding * 2).clamp(64.0, 160.0)
                      : 240.0;
                  final image = SizedBox(
                      height: imageSize,
                      child: PlayerBagItemImage(entry: entry, size: imageSize));
                  final description = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.title,
                            style: context.playerMenuTheme.subtitle),
                        const Divider(),
                        Text(
                            entry.bagItem?.description ??
                                entry.subtitle ??
                                _text('Aucune description disponible.',
                                    'No description available.'),
                            style: context.playerMenuTheme.body),
                        if (entry.bagAction?.unavailableReason
                            case final reason?) ...[
                          const SizedBox(height: 16),
                          Text(reason, style: context.playerMenuTheme.meta),
                        ],
                      ]);
                  return SingleChildScrollView(
                    key: ValueKey('bag-detail-${_id(entry)}'),
                    controller: controller,
                    child: PlayerMenuPanel(
                        padding: EdgeInsets.all(padding),
                        child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.hasBoundedHeight
                                    ? (constraints.maxHeight - padding * 2)
                                        .clamp(0, double.infinity)
                                    : 0),
                            child: short
                                ? Row(children: [
                                    SizedBox(width: imageSize, child: image),
                                    const SizedBox(width: 24),
                                    Expanded(child: description),
                                  ])
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                        image,
                                        const SizedBox(height: 16),
                                        description,
                                      ]))),
                  );
                }))));
  }

  Widget _actions(BuildContext context, [Widget? returnAction]) {
    final entry = _selected;
    if (entry == null) return returnAction ?? const SizedBox.shrink();
    final action = entry.bagAction;
    final children = <Widget>[
      if (action?.isEnabled == true && widget.onCommand != null)
        PlayerMenuSelectableRow(
            key: ValueKey('runtime-player-bag-use-${action!.itemTargetId}'),
            id: 'runtime-player-bag-use-${action.itemTargetId}',
            integrated: returnAction == null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            label: PlayerBagStrings.of(context).use,
            focusNode: _detailFocus,
            leading: const Icon(Icons.healing),
            busy: _busy,
            onPressed: _busy ? null : () => _use(entry, action)),
      if (widget.onFavoriteChanged != null)
        PlayerMenuSelectableRow(
            key: ValueKey('bag-favorite-${_id(entry)}'),
            focusNode: action?.isEnabled == true && widget.onCommand != null
                ? null
                : _detailFocus,
            id: 'bag-favorite-${_id(entry)}',
            integrated: returnAction == null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            label: widget.favoriteItemIds.contains(_id(entry))
                ? _text('Retirer des favoris', 'Unfavorite')
                : _text('Favori', 'Favorite'),
            leading: Icon(widget.favoriteItemIds.contains(_id(entry))
                ? Icons.star
                : Icons.star_border),
            busy: _busy,
            onPressed: _busy
                ? null
                : () => _run(() => widget.onFavoriteChanged!(
                    _id(entry), !widget.favoriteItemIds.contains(_id(entry))))),
    ];
    return PlayerMenuThemeScope(
        role: ProjectPresentationSurfaceRole.bag,
        child: returnAction == null
            ? Wrap(spacing: 8, runSpacing: 8, children: [
                for (final child in children) IntrinsicWidth(child: child),
              ])
            : PlayerMenuActionGroup(children: [...children, returnAction]));
  }

  Future<void> _use(RuntimePlayerDetailEntrySnapshot entry,
      RuntimePlayerBagItemActionSnapshot action) async {
    if (_busy || _targetDialogOpen) return;
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
                          targets: widget.detail.bagTargets)))));
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
        _failure = _text('Cette action a échoué. Réessayez.',
            'The action failed. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class PlayerBagItemImage extends StatelessWidget {
  const PlayerBagItemImage(
      {super.key, required this.entry, required this.size});
  final RuntimePlayerDetailEntrySnapshot entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = entry.bagItem?.iconFilePath;
    final placeholder = Icon(Icons.inventory_2_outlined,
        key: ValueKey('bag-image-missing-${entry.id}'),
        size: size > 40 ? 80 : 28,
        color: context.playerMenuTheme.secondary);
    return Semantics(
        image: true,
        label: entry.title,
        child: SizedBox(
            width: size,
            height: size,
            child: path == null
                ? placeholder
                : Image(
                    image: ResizeImage(
                      FileImage(File(path)),
                      width: (size * MediaQuery.devicePixelRatioOf(context))
                          .ceil(),
                      height: (size * MediaQuery.devicePixelRatioOf(context))
                          .ceil(),
                      policy: ResizeImagePolicy.fit,
                    ),
                    key: ValueKey('${entry.id}-$path-$size'),
                    fit: BoxFit.contain,
                    gaplessPlayback: false,
                    filterQuality: FilterQuality.none,
                    frameBuilder: (_, child, frame, sync) =>
                        sync || frame != null ? child : placeholder,
                    errorBuilder: (_, __, ___) => placeholder)));
  }
}

class _BagTargetDialog extends StatefulWidget {
  const _BagTargetDialog(
      {required this.entry, required this.action, required this.targets});
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
  bool get _needsMove =>
      widget.action.targetKind == RuntimePlayerBagUseTargetKind.partyMove ||
      widget.action.targetKind ==
              RuntimePlayerBagUseTargetKind.partyMoveReplacement &&
          _target!.requiresMoveReplacement;

  String? get _firstEligibleTargetId => widget.targets
      .where((target) =>
          widget.action.allowsPartyTarget(target.targetId) &&
          widget.action.unavailablePartyTargetReasons[target.targetId] == null)
      .firstOrNull
      ?.targetId;

  @override
  void initState() {
    super.initState();
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
      final node = _target == null
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
                child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 560, maxHeight: 640),
                    child: PlayerMenuPanel(
                        child: SingleChildScrollView(
                            child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            '${PlayerBagStrings.of(context).use} ${widget.entry.title}',
                            style: context.playerMenuTheme.subtitle),
                        const SizedBox(height: 16),
                        if (_target == null) ...[
                          if (widget.targets.isEmpty)
                            Text(_text('Votre équipe est vide.',
                                'Your party is empty.')),
                          for (final target in widget.targets)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PlayerMenuSelectableRow(
                                  key: ValueKey(
                                      'runtime-player-bag-target-${target.targetId}'),
                                  id: 'runtime-player-bag-target-${target.targetId}',
                                  focusNode:
                                      target.targetId == _firstEligibleTargetId
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
                                          height: 48),
                                  disabledReason: widget.action
                                              .unavailablePartyTargetReasons[
                                          target.targetId] ??
                                      (widget.action.allowsPartyTarget(
                                              target.targetId)
                                          ? null
                                          : _text('Non compatible.',
                                              'Not compatible.')),
                                  onPressed: () {
                                    setState(() {
                                      _target = target;
                                      _confirm = !_needsMove;
                                    });
                                    _focusCurrentStage();
                                  },
                                )),
                        ] else if (!_confirm) ...[
                          Text(_target!.label,
                              style: context.playerMenuTheme.label),
                          for (final move in _target!.moves)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PlayerMenuSelectableRow(
                                    key: ValueKey(
                                        'runtime-player-bag-target-${_target!.targetId}-${move.targetId}'),
                                    id:
                                        'runtime-player-bag-target-${_target!.targetId}-${move.targetId}',
                                    focusNode: move == _target!.moves.first
                                        ? _moveFocus
                                        : null,
                                    label: move.label,
                                    subtitle: move.subtitle,
                                    onPressed: () {
                                      setState(() {
                                        _move = move;
                                        _confirm = true;
                                      });
                                      _focusCurrentStage();
                                    })),
                        ] else ...[
                          Text(_target!.label,
                              style: context.playerMenuTheme.subtitle),
                          const SizedBox(height: 12),
                          Text(widget.action.targetKind ==
                                  RuntimePlayerBagUseTargetKind
                                      .partyMoveReplacement
                              ? '${_text('Apprendre', 'Learn')} ${widget.action.learnedMoveLabel ?? widget.entry.title}'
                                  '${_move == null ? '' : ' — ${_text('oublier', 'forget')} ${_move!.label}'}'
                              : '${widget.entry.title}${_move == null ? '' : ' — ${_move!.label}'}'),
                          const SizedBox(height: 16),
                          PlayerActionButton(
                              key: const ValueKey('bag-use-confirm'),
                              focusNode: _confirmFocus,
                              label: _text('Confirmer', 'Confirm'),
                              icon: Icons.check,
                              onPressed: _submitted
                                  ? null
                                  : () {
                                      if (_submitted) return;
                                      setState(() => _submitted = true);
                                      Navigator.of(context).pop(
                                          RuntimePlayerPauseCommand.useBagItem(
                                              itemTargetId:
                                                  widget.action.itemTargetId,
                                              partyTargetId: _target!.targetId,
                                              moveTargetId: _move?.targetId));
                                    }),
                        ],
                        const SizedBox(height: 12),
                        PlayerActionButton(
                            key: const ValueKey(
                                'runtime-player-bag-target-close'),
                            focusNode: _backFocus,
                            label: context.playerL10n.back,
                            icon: Icons.arrow_back,
                            secondary: true,
                            onPressed: _back),
                      ],
                    )))))),
      );
}
