import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_menu_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'runtime_player_actions.dart';

enum RuntimePlayerPokedexFilter { all, seen, caught }

final class RuntimePlayerPokedexNavigation extends ChangeNotifier {
  bool Function()? _back;
  VoidCallback? _reset;
  String? _selectedEntryId;
  String _query = '';
  RuntimePlayerPokedexFilter _filter = RuntimePlayerPokedexFilter.all;
  double _listScrollOffset = 0;

  String? get selectedEntryId => _selectedEntryId;
  String get query => _query;
  RuntimePlayerPokedexFilter get filter => _filter;

  bool back() => _back?.call() ?? false;
  void _refresh() => notifyListeners();

  void clearForNewSession() {
    _selectedEntryId = null;
    _query = '';
    _filter = RuntimePlayerPokedexFilter.all;
    _listScrollOffset = 0;
    _reset?.call();
    notifyListeners();
  }
}

class RuntimePlayerPokedex extends StatefulWidget {
  const RuntimePlayerPokedex({
    super.key,
    required this.detail,
    this.navigation,
  });

  final RuntimePlayerPauseDetailSnapshot detail;
  final RuntimePlayerPokedexNavigation? navigation;

  @override
  State<RuntimePlayerPokedex> createState() => _RuntimePlayerPokedexState();
}

class _RuntimePlayerPokedexState extends State<RuntimePlayerPokedex> {
  final _localNavigation = RuntimePlayerPokedexNavigation();
  final _search = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'Pokedex search');
  final _detailFocus = FocusNode(debugLabel: 'Pokedex detail');
  final _listScroll = ScrollController(keepScrollOffset: false);
  final _filterScroll = ScrollController();
  final _detailScroll = ScrollController();
  final _nodes = <String, FocusNode>{};
  bool _showDetail = false;
  bool _compact = false;

  RuntimePlayerPokedexNavigation get _navigation =>
      widget.navigation ?? _localNavigation;
  List<RuntimePlayerDetailEntrySnapshot> get _entries => widget.detail.entries;

  String _text(String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;

  RuntimePlayerPokedexKnowledge _knowledge(
          RuntimePlayerDetailEntrySnapshot entry) =>
      entry.pokedexEntry?.knowledge ?? RuntimePlayerPokedexKnowledge.unknown;

  bool _known(RuntimePlayerDetailEntrySnapshot entry) =>
      _knowledge(entry) != RuntimePlayerPokedexKnowledge.unknown;

  String _title(RuntimePlayerDetailEntrySnapshot entry) =>
      _known(entry) ? entry.title : '???';

  String _number(RuntimePlayerDetailEntrySnapshot entry) =>
      entry.pokedexEntry?.nationalDex?.toString().padLeft(3, '0') ?? '—';

  String _status(RuntimePlayerDetailEntrySnapshot entry) =>
      switch (_knowledge(entry)) {
        RuntimePlayerPokedexKnowledge.unknown => _text('Inconnu', 'Unknown'),
        RuntimePlayerPokedexKnowledge.seen => _text('Vu', 'Seen'),
        RuntimePlayerPokedexKnowledge.caught => _text('Capturé', 'Caught'),
      };

  String _normalized(String value) {
    const accents = {
      'àáâãäå': 'a',
      'ç': 'c',
      'èéêë': 'e',
      'ìíîï': 'i',
      'ñ': 'n',
      'òóôõöø': 'o',
      'ùúûü': 'u',
      'ýÿ': 'y',
      'œ': 'oe',
      'æ': 'ae',
    };
    var result = value.toLowerCase().trim();
    for (final accent in accents.entries) {
      result = result.replaceAll(RegExp('[${accent.key}]'), accent.value);
    }
    return result.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  }

  List<RuntimePlayerDetailEntrySnapshot> get _visible {
    final query = _normalized(_navigation._query);
    return _entries.where((entry) {
      final matchesFilter = switch (_navigation._filter) {
        RuntimePlayerPokedexFilter.all => true,
        RuntimePlayerPokedexFilter.seen => _known(entry),
        RuntimePlayerPokedexFilter.caught =>
          _knowledge(entry) == RuntimePlayerPokedexKnowledge.caught,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final number = entry.pokedexEntry?.nationalDex;
      return _known(entry) && _normalized(_title(entry)).contains(query) ||
          _normalized(_status(entry)).contains(query) ||
          _known(entry) &&
              entry.pokedexEntry!.typeIds.any((type) =>
                  _normalized(context.playerL10n.battleMoveType(type))
                      .contains(query)) ||
          number != null &&
              ('#$number'.contains(query) ||
                  '#${_number(entry)}'.contains(query));
    }).toList(growable: false);
  }

  RuntimePlayerDetailEntrySnapshot? get _selected =>
      _visible
          .where((entry) => entry.id == _navigation._selectedEntryId)
          .firstOrNull ??
      _visible.firstOrNull;

  FocusNode _node(String id) =>
      _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'Pokedex row'));

  @override
  void initState() {
    super.initState();
    _listScroll.addListener(_rememberListScrollOffset);
    _bind();
    _reconcileSelection();
    _focusSelected(restoreListOffset: true);
  }

  void _bind() {
    _navigation._back = _back;
    _navigation._reset = _reset;
    _search.text = _navigation._query;
  }

  void _unbind(RuntimePlayerPokedexNavigation navigation) {
    navigation._back = null;
    navigation._reset = null;
  }

  @override
  void didUpdateWidget(RuntimePlayerPokedex oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigation != widget.navigation) {
      _unbind(oldWidget.navigation ?? _localNavigation);
      _bind();
      _focusSelected(restoreListOffset: true);
    }
    _reconcileSelection(oldWidget.detail.entries);
    if (_selected == null) _showDetail = false;
  }

  void _reconcileSelection(
      [List<RuntimePlayerDetailEntrySnapshot> previous = const []]) {
    final selectedId = _navigation._selectedEntryId;
    if (_entries.any((entry) => entry.id == selectedId)) return;
    final previousIndex =
        previous.indexWhere((entry) => entry.id == selectedId);
    _navigation._selectedEntryId = _entries.isEmpty
        ? null
        : _entries[previousIndex.clamp(0, _entries.length - 1)].id;
  }

  void _reset() {
    setState(() {
      _search.clear();
      _showDetail = false;
      _reconcileSelection();
    });
    _focusSelected(restoreListOffset: true);
  }

  @override
  void dispose() {
    _unbind(_navigation);
    _localNavigation.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _detailFocus.dispose();
    _listScroll.dispose();
    _filterScroll.dispose();
    _detailScroll.dispose();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _rememberListScrollOffset() {
    if (_listScroll.hasClients) {
      _navigation._listScrollOffset = _listScroll.offset;
    }
  }

  void _focusSelected({bool restoreListOffset = false}) {
    final offset = restoreListOffset ? _navigation._listScrollOffset : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      if (offset != null && _listScroll.hasClients) {
        final target = offset.clamp(_listScroll.position.minScrollExtent,
            _listScroll.position.maxScrollExtent);
        if (_listScroll.offset != target) {
          _listScroll.jumpTo(target);
          _focusSelected();
          return;
        }
      }
      final entry = _selected;
      if (entry == null) return;
      final node = _node(entry.id);
      if (node.context != null) {
        Scrollable.ensureVisible(node.context!);
        node.requestFocus();
      }
    });
  }

  bool _back() {
    if (!_compact || !_showDetail) return false;
    setState(() => _showDetail = false);
    _focusSelected(restoreListOffset: true);
    return true;
  }

  void _queryChanged(String value) {
    setState(() {
      _navigation._query = value;
      _showDetail = false;
    });
    _navigation._refresh();
  }

  void _select(RuntimePlayerDetailEntrySnapshot entry, {bool open = false}) {
    setState(() {
      _navigation._selectedEntryId = entry.id;
      if (open) _showDetail = _compact;
    });
    _navigation._refresh();
    if (_detailScroll.hasClients) _detailScroll.jumpTo(0);
    if (open && _compact) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _detailFocus.context != null) {
          _detailFocus.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _compact = constraints.maxWidth < 900 ||
          MediaQuery.textScalerOf(context).scale(1) >= 1.8;
      final selected = _selected;
      final listing = _listing(
          scrollControls: constraints.maxHeight <
              (MediaQuery.textScalerOf(context).scale(1) >= 1.8 ? 300 : 180));
      return SizedBox.expand(
        key: const ValueKey('runtime-player-detail-pokedex'),
        child: _compact
            ? _showDetail && selected != null
                ? _detail(selected)
                : listing
            : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(
                    key: const ValueKey('pokedex-list-column'),
                    width: math.min(448, (constraints.maxWidth - 24) * .4),
                    child: listing),
                const SizedBox(width: 24),
                Expanded(
                    child: selected == null
                        ? const SizedBox.shrink()
                        : _detail(selected)),
              ]),
      );
    });
  }

  Widget _listing({required bool scrollControls}) {
    final visible = _visible;
    final controls = [
      _searchField(),
      const SizedBox(height: 12),
      _filters(),
      const SizedBox(height: 16),
    ];
    if (scrollControls) {
      return ListView(
          key: const ValueKey('pokedex-list'),
          controller: _listScroll,
          children: [
            ...controls,
            if (visible.isEmpty)
              _empty()
            else
              for (final entry in visible) ...[
                _row(entry),
                const SizedBox(height: 8),
              ],
          ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ...controls,
      Expanded(
          child: visible.isEmpty
              ? SingleChildScrollView(child: _empty())
              : FocusTraversalGroup(
                  child: ListView.separated(
                    key: const ValueKey('pokedex-list'),
                    controller: _listScroll,
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => _row(visible[index]),
                  ),
                )),
    ]);
  }

  Widget _searchField() {
    final theme = context.playerMenuTheme;
    return PlayerMenuPanel(
        key: const ValueKey('pokedex-search-panel'),
        padding: EdgeInsets.zero,
        child: Row(children: [
          Expanded(
              child: TextField(
            key: const ValueKey('pokedex-search'),
            controller: _search,
            focusNode: _searchFocus,
            style: theme.body,
            cursorColor: theme.focus,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _text('Nom ou numéro', 'Name or number'),
              hintStyle: theme.body.copyWith(color: theme.secondary),
              prefixIcon: Icon(Icons.search, color: theme.secondary),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(PokeMapPlayerMenuTheme.panelRadius),
                  borderSide: BorderSide(color: theme.focus, width: 2)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              constraints: const BoxConstraints(minHeight: 48),
            ),
            onChanged: _queryChanged,
            onSubmitted: (_) => _focusSelected(),
          )),
          if (_navigation._query.isNotEmpty)
            SizedBox(
                width: 60,
                child: PlayerMenuSelectableRow(
                    key: const ValueKey('pokedex-search-clear'),
                    id: 'pokedex-search-clear',
                    label: '',
                    semanticValue:
                        _text('Effacer la recherche', 'Clear search'),
                    integrated: true,
                    minimumHeight: 48,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      _queryChanged('');
                      _focusSelected();
                    })),
        ]));
  }

  Widget _filters() => SingleChildScrollView(
      key: const ValueKey('pokedex-filters'),
      controller: _filterScroll,
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final filter in RuntimePlayerPokedexFilter.values) ...[
          if (filter != RuntimePlayerPokedexFilter.all)
            const SizedBox(width: 8),
          IntrinsicWidth(
              child: PlayerMenuSelectableRow(
            key: ValueKey('pokedex-filter-${filter.name}'),
            id: 'pokedex-filter-${filter.name}',
            label: switch (filter) {
              RuntimePlayerPokedexFilter.all => _text('Tous', 'All'),
              RuntimePlayerPokedexFilter.seen => _text('Vus', 'Seen'),
              RuntimePlayerPokedexFilter.caught => _text('Capturés', 'Caught'),
            },
            selected: _navigation._filter == filter,
            minimumHeight: 44,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onPressed: () {
              setState(() {
                _navigation._filter = filter;
                _showDetail = false;
              });
              _navigation._refresh();
            },
          )),
        ],
      ]));

  Widget _row(RuntimePlayerDetailEntrySnapshot entry) =>
      PlayerMenuSelectableRow(
        key: ValueKey('pokedex-entry-${entry.id}'),
        id: 'pokedex-entry-${entry.id}',
        label: _title(entry),
        selected: _selected?.id == entry.id,
        semanticValue: '${_number(entry)}, ${_status(entry)}',
        focusNode: _node(entry.id),
        minimumHeight: 64,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              key: ValueKey('pokedex-number-${entry.id}'),
              width: 56,
              child: Text(_number(entry))),
          const SizedBox(width: 8),
          _image(entry, thumbnail: true),
        ]),
        trailing: Icon(
            _knowledge(entry) == RuntimePlayerPokedexKnowledge.caught
                ? Icons.catching_pokemon
                : _known(entry)
                    ? Icons.visibility_outlined
                    : Icons.help_outline,
            size: 20),
        trailingWidth: 20,
        onFocusChanged: (focused) {
          if (focused) _select(entry);
        },
        onPressed: () => _select(entry, open: true),
      );

  Widget _empty() => PlayerMenuFeedback(
      key: ValueKey(_entries.isEmpty ? 'pokedex-empty' : 'pokedex-no-results'),
      id: _entries.isEmpty ? 'pokedex-empty' : 'pokedex-no-results',
      kind: PlayerMenuFeedbackKind.empty,
      title: _entries.isEmpty
          ? _text('Pokédex vide', 'Empty Pokédex')
          : _text('Aucun résultat', 'No results'),
      message: _entries.isEmpty
          ? widget.detail.emptyMessage ??
              _text('Aucune entrée disponible.', 'No entries available.')
          : _text('Essayez un autre nom, numéro ou filtre.',
              'Try another name, number or filter.'));

  Widget _detail(RuntimePlayerDetailEntrySnapshot entry) {
    final theme = context.playerMenuTheme;
    void scroll(double direction) {
      if (!_detailScroll.hasClients) return;
      _detailScroll.animateTo(
          (_detailScroll.offset + direction * 120)
              .clamp(0, _detailScroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final landscape =
          constraints.maxWidth > 500 && constraints.maxHeight < 320;
      final information = SingleChildScrollView(
          key: ValueKey('pokedex-description-${entry.id}'),
          controller: _detailScroll,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_title(entry),
                style: theme.subtitle.copyWith(fontSize: 22, height: 28 / 22)),
            const SizedBox(height: 4),
            Text('#${_number(entry)} · ${_status(entry)}',
                style: theme.meta.copyWith(color: theme.secondary)),
            if (!landscape) ...[
              const SizedBox(height: 16),
              Center(child: _image(entry)),
            ],
            if (_known(entry) && entry.pokedexEntry!.typeIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final type in entry.pokedexEntry!.typeIds)
                  PlayerMenuBadge(
                      label: context.playerL10n.battleMoveType(type),
                      kind: PlayerMenuBadgeKind.type),
              ]),
            ],
            const SizedBox(height: 24),
            Text(
                !_known(entry)
                    ? _text('Ce Pokémon n’a pas encore été rencontré.',
                        'This Pokémon has not been encountered yet.')
                    : entry.pokedexEntry?.description ??
                        _text('Aucune description disponible.',
                            'No description available.'),
                style: theme.body),
          ]));
      return PlayerMenuPanel(
          key: ValueKey('pokedex-detail-${entry.id}'),
          padding: EdgeInsets.all(landscape ? 12 : 24),
          child: Actions(
              actions: {
                RuntimePlayerLogicalIntent:
                    CallbackAction<RuntimePlayerLogicalIntent>(
                        onInvoke: (intent) {
                  if (intent.action == PlayerInputAction.down ||
                      intent.action == PlayerInputAction.up) {
                    scroll(intent.action == PlayerInputAction.down ? 1 : -1);
                    return null;
                  }
                  return Actions.invoke(context, intent);
                }),
              },
              child: Focus(
                  focusNode: _detailFocus,
                  onKeyEvent: (_, event) {
                    if (event is KeyUpEvent) return KeyEventResult.ignored;
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                        event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      scroll(event.logicalKey == LogicalKeyboardKey.arrowDown
                          ? 1
                          : -1);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: landscape
                      ? Row(children: [
                          _image(entry,
                              width: math.min(220, constraints.maxWidth * .3),
                              height: math.max(0, constraints.maxHeight - 24)),
                          const SizedBox(width: 16),
                          Expanded(child: information),
                        ])
                      : information)));
    });
  }

  Widget _image(RuntimePlayerDetailEntrySnapshot entry,
      {bool thumbnail = false, double width = 300, double height = 280}) {
    final known = _known(entry);
    final media = !known
        ? null
        : thumbnail
            ? entry.pokedexEntry?.media.thumbnail
            : entry.pokedexEntry?.media.illustration;
    final placeholder = Center(
        child: Icon(known ? Icons.catching_pokemon : Icons.help_outline,
            key: ValueKey(known
                ? 'pokedex-image-missing-${entry.id}-${thumbnail ? 'row' : 'detail'}'
                : 'pokedex-unknown-${entry.id}-${thumbnail ? 'row' : 'detail'}'),
            size: thumbnail ? 32 : 80,
            color: context.playerMenuTheme.secondary));
    return Semantics(
        image: true,
        label: _title(entry),
        child: SizedBox(
            key: ValueKey(
                'pokedex-image-${entry.id}-${thumbnail ? 'row' : 'detail'}'),
            width: thumbnail ? 48 : width,
            height: thumbnail ? 48 : height,
            child: media == null
                ? placeholder
                : Image.file(
                    File(media.absoluteFilePath),
                    fit: BoxFit.contain,
                    gaplessPlayback: false,
                    filterQuality:
                        media.sampling == ProjectMenuImageSampling.pixelArt
                            ? FilterQuality.none
                            : FilterQuality.medium,
                    frameBuilder: (_, child, frame, synchronous) =>
                        synchronous || frame != null ? child : placeholder,
                    errorBuilder: (_, error, stack) => placeholder,
                  )));
  }
}
