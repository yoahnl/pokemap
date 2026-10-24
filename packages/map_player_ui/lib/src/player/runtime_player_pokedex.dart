import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_image.dart';

import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../foundation/player_pokemon_type_badge.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';

enum RuntimePlayerPokedexFilter { all, seen, caught }

final class RuntimePlayerPokedexNavigation extends ChangeNotifier {
  bool Function()? _back;
  VoidCallback? _reset;
  String? _selectedEntryId;
  String _query = '';
  RuntimePlayerPokedexFilter _filter = RuntimePlayerPokedexFilter.all;
  int _listPage = 0;

  String? get selectedEntryId => _selectedEntryId;
  String get query => _query;
  RuntimePlayerPokedexFilter get filter => _filter;

  bool back() => _back?.call() ?? false;
  void _refresh() => notifyListeners();

  void clearForNewSession() {
    _selectedEntryId = null;
    _query = '';
    _filter = RuntimePlayerPokedexFilter.all;
    _listPage = 0;
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
  final _nodes = <String, FocusNode>{};
  bool _showDetail = false;
  bool _compact = false;
  int _browseRevision = 0;

  RuntimePlayerPokedexNavigation get _navigation =>
      widget.navigation ?? _localNavigation;
  List<RuntimePlayerDetailEntrySnapshot> get _entries => widget.detail.entries;

  String _text(String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;

  RuntimePlayerPokedexKnowledge _knowledge(
    RuntimePlayerDetailEntrySnapshot entry,
  ) => entry.pokedexEntry?.knowledge ?? RuntimePlayerPokedexKnowledge.unknown;

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
    return _entries
        .where((entry) {
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
                  entry.pokedexEntry!.typeIds.any(
                    (type) =>
                        _normalized(context.playerL10n.battleMoveType(type))
                            .contains(query),
                  ) ||
              number != null &&
                  ('#$number'.contains(query) ||
                      '#${_number(entry)}'.contains(query));
        })
        .toList(growable: false);
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

  void _reconcileSelection([
    List<RuntimePlayerDetailEntrySnapshot> previous = const [],
  ]) {
    final selectedId = _navigation._selectedEntryId;
    if (_entries.any((entry) => entry.id == selectedId)) return;
    final previousIndex = previous.indexWhere(
      (entry) => entry.id == selectedId,
    );
    _navigation._selectedEntryId = _entries.isEmpty
        ? null
        : _entries[previousIndex.clamp(0, _entries.length - 1)].id;
  }

  void _reset() {
    setState(() {
      _search.clear();
      _browseRevision++;
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
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _focusSelected({bool restoreListOffset = false, int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      final entry = _selected;
      if (entry == null) return;
      final node = _node(entry.id);
      if (node.context != null && node.canRequestFocus) {
        node.requestFocus();
      } else if (attempt < 4) {
        _focusSelected(attempt: attempt + 1);
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
      _navigation._listPage = 0;
      _showDetail = false;
    });
    _navigation._refresh();
  }

  void _select(RuntimePlayerDetailEntrySnapshot entry, {bool open = false}) {
    if (!open && _navigation._selectedEntryId == entry.id) return;
    setState(() {
      _navigation._selectedEntryId = entry.id;
      if (open) _showDetail = _compact;
    });
    _navigation._refresh();
    if (!open) _focusSelected();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        _compact =
            constraints.maxWidth < 600 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.8;
        final selected = _selected;
        final listing = _listing(
          scrollControls:
              constraints.maxHeight <
              180 + 120 * MediaQuery.textScalerOf(context).scale(1),
        );
        return SizedBox.expand(
          key: const ValueKey('runtime-player-detail-pokedex'),
          child: _compact
              ? IndexedStack(
                  index: _showDetail && selected != null ? 1 : 0,
                  children: [
                    listing,
                    if (selected != null)
                      _detail(selected)
                    else
                      const SizedBox.shrink(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      key: const ValueKey('pokedex-list-column'),
                      width: math.min(448, (constraints.maxWidth - 24) * .4),
                      child: listing,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: selected == null
                          ? const SizedBox.shrink()
                          : _detail(selected),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _listing({required bool scrollControls}) {
    final visible = _visible;
    final rows = visible.isEmpty
        ? _emptyRows()
        : <Widget>[for (final entry in visible) _row(entry)];
    Widget pages(List<Widget> children) => KeyedSubtree(
      key: ValueKey(
        'pokedex-browse-$_browseRevision-${_navigation._query}-${_navigation._filter.name}',
      ),
      child: PlayerPagedList(
        key: const ValueKey('pokedex-list'),
        initialPage: _navigation._listPage,
        onPageChanged: (value) => _navigation._listPage = value,
        children: children,
      ),
    );
    if (scrollControls) {
      return pages([_searchField(), _filters(), ...rows]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _searchField(),
        const SizedBox(height: 12),
        _filters(),
        const SizedBox(height: 16),
        Expanded(child: FocusTraversalGroup(child: pages(rows))),
      ],
    );
  }

  Widget _searchField() {
    final theme = context.playerMenuTheme;
    return PlayerMenuPanel(
      key: const ValueKey('pokedex-search-panel'),
      padding: EdgeInsets.zero,
      child: Row(
        children: [
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
                  borderRadius: BorderRadius.circular(
                    PokeMapPlayerMenuTheme.panelRadius,
                  ),
                  borderSide: BorderSide(color: theme.focus, width: 2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                constraints: const BoxConstraints(minHeight: 48),
              ),
              onChanged: _queryChanged,
              onSubmitted: (_) => _focusSelected(),
            ),
          ),
          if (_navigation._query.isNotEmpty)
            SizedBox(
              width: 60,
              child: PlayerMenuSelectableRow(
                key: const ValueKey('pokedex-search-clear'),
                id: 'pokedex-search-clear',
                label: '',
                semanticValue: _text('Effacer la recherche', 'Clear search'),
                integrated: true,
                minimumHeight: 48,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: const Icon(Icons.close),
                onPressed: () {
                  _search.clear();
                  _queryChanged('');
                  _focusSelected();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _filters() => Row(
    key: const ValueKey('pokedex-filters'),
    children: [
      for (final filter in RuntimePlayerPokedexFilter.values) ...[
        if (filter != RuntimePlayerPokedexFilter.all) const SizedBox(width: 8),
        Expanded(
          child: PlayerMenuSelectableRow(
            key: ValueKey('pokedex-filter-${filter.name}'),
            id: 'pokedex-filter-${filter.name}',
            label: switch (filter) {
              RuntimePlayerPokedexFilter.all => _text('Tous', 'All'),
              RuntimePlayerPokedexFilter.seen => _text('Vus', 'Seen'),
              RuntimePlayerPokedexFilter.caught => _text('Capturés', 'Caught'),
            },
            selected: _navigation._filter == filter,
            minimumHeight: 48,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            onPressed: () {
              setState(() {
                _navigation._filter = filter;
                _navigation._listPage = 0;
                _showDetail = false;
              });
              _navigation._refresh();
            },
          ),
        ),
      ],
    ],
  );

  Widget _row(RuntimePlayerDetailEntrySnapshot entry) =>
      PlayerMenuSelectableRow(
        key: ValueKey('pokedex-entry-${entry.id}'),
        id: 'pokedex-entry-${entry.id}',
        label: _title(entry),
        labelMaxLines: 1,
        selected: _selected?.id == entry.id,
        semanticValue: '${_number(entry)}, ${_status(entry)}',
        focusNode: _node(entry.id),
        minimumHeight: 64,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6.5,
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              key: ValueKey('pokedex-number-${entry.id}'),
              width:
                  (MediaQuery.sizeOf(context).shortestSide < 600 ? 40 : 56) *
                  MediaQuery.textScalerOf(context).scale(1),
              child: Text(_number(entry)),
            ),
            const SizedBox(width: 8),
            _image(entry, thumbnail: true),
          ],
        ),
        trailing: Icon(
          _knowledge(entry) == RuntimePlayerPokedexKnowledge.caught
              ? Icons.catching_pokemon
              : _known(entry)
              ? Icons.visibility_outlined
              : Icons.help_outline,
          size: 20,
        ),
        trailingWidth: 20,
        onFocusChanged: (focused) {
          if (focused) _select(entry);
        },
        onPressed: () => _select(entry, open: true),
      );

  List<Widget> _emptyRows() => [
    const Icon(Icons.search_off, size: 32),
    Text(
      _entries.isEmpty
          ? _text('Pokédex vide', 'Empty Pokédex')
          : _text('Aucun résultat', 'No results'),
      key: ValueKey(_entries.isEmpty ? 'pokedex-empty' : 'pokedex-no-results'),
      style: context.playerMenuTheme.subtitle,
    ),
    Text(
      _entries.isEmpty
          ? widget.detail.emptyMessage ??
                _text('Aucune entrée disponible.', 'No entries available.')
          : _text(
              'Essayez un autre nom, numéro ou filtre.',
              'Try another name, number or filter.',
            ),
      style: context.playerMenuTheme.body,
    ),
  ];

  Widget _detail(RuntimePlayerDetailEntrySnapshot entry) => PlayerMenuPanel(
    key: ValueKey('pokedex-detail-${entry.id}'),
    padding: const EdgeInsets.all(8),
    child: Focus(
      focusNode: _detailFocus,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = context.playerMenuTheme;
          final pageHeight = math.max(32.0, constraints.maxHeight - 68);
          List<Widget> textPages(String text, TextStyle style, String id) {
            final chunks = <String>[];
            var chunk = '';
            for (final word in text.split(RegExp(r'\s+'))) {
              final candidate = chunk.isEmpty ? word : '$chunk $word';
              final measure = TextPainter(
                text: TextSpan(text: candidate, style: style),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: constraints.maxWidth);
              final overflow = measure.height > pageHeight;
              measure.dispose();
              if (overflow && chunk.isNotEmpty) {
                chunks.add(chunk);
                chunk = word;
              } else {
                chunk = candidate;
              }
            }
            if (chunk.isNotEmpty) chunks.add(chunk);
            return [
              for (var index = 0; index < chunks.length; index++)
                Text(chunks[index], key: ValueKey('$id-$index'), style: style),
            ];
          }

          return PlayerPagedList(
            key: ValueKey('pokedex-description-${entry.id}'),
            children: [
              ...textPages(
                _title(entry),
                theme.subtitle.copyWith(fontSize: 22, height: 28 / 22),
                'pokedex-title',
              ),
              Text(
                '#${_number(entry)} · ${_status(entry)}',
                style: theme.meta.copyWith(color: theme.secondary),
              ),
              Center(
                child: _image(
                  entry,
                  width: math.min(300, constraints.maxWidth),
                  height: math.min(280, pageHeight),
                ),
              ),
              if (_known(entry) && entry.pokedexEntry!.typeIds.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in entry.pokedexEntry!.typeIds)
                      PlayerPokemonTypeBadge(type: type),
                  ],
                ),
              ...textPages(
                !_known(entry)
                    ? _text(
                        'Ce Pokémon n’a pas encore été rencontré.',
                        'This Pokémon has not been encountered yet.',
                      )
                    : entry.pokedexEntry?.description ??
                          _text(
                            'Aucune description disponible.',
                            'No description available.',
                          ),
                theme.body,
                'pokedex-description-text',
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _image(
    RuntimePlayerDetailEntrySnapshot entry, {
    bool thumbnail = false,
    double width = 300,
    double height = 280,
  }) {
    final known = _known(entry);
    final media = !known
        ? null
        : thumbnail
        ? entry.pokedexEntry?.media.thumbnail
        : entry.pokedexEntry?.media.illustration;
    final placeholder = Center(
      child: Icon(
        known ? Icons.catching_pokemon : Icons.help_outline,
        key: ValueKey(
          known
              ? 'pokedex-image-missing-${entry.id}-${thumbnail ? 'row' : 'detail'}'
              : 'pokedex-unknown-${entry.id}-${thumbnail ? 'row' : 'detail'}',
        ),
        size: thumbnail ? 32 : 80,
        color: context.playerMenuTheme.secondary,
      ),
    );
    return Semantics(
      image: true,
      label: _title(entry),
      child: SizedBox(
        key: ValueKey(
          'pokedex-image-${entry.id}-${thumbnail ? 'row' : 'detail'}',
        ),
        width: thumbnail ? 48 : width,
        height: thumbnail ? 48 : height,
        child: media == null
            ? placeholder
            : PlayerFileImage(
                path: media.absoluteFilePath,
                fit: BoxFit.contain,
                filterQuality:
                    media.sampling == ProjectMenuImageSampling.pixelArt
                    ? FilterQuality.none
                    : FilterQuality.medium,
                fallback: placeholder,
              ),
      ),
    );
  }
}
