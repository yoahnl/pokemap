import 'dart:typed_data';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/pokemon_providers.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_player_ui/map_player_ui.dart'
    show PokeMapPlayerLocalizations;

import 'project_pokemon_import.dart';

part 'project_pokemon_species_details.dart';

class ProjectPokemonPage extends ConsumerStatefulWidget {
  const ProjectPokemonPage({
    super.key,
    required this.session,
    required this.onImporting,
  });

  final ProjectSession session;
  final ValueChanged<bool> onImporting;

  @override
  ConsumerState<ProjectPokemonPage> createState() => _ProjectPokemonPageState();
}

class _ProjectPokemonPageState extends ConsumerState<ProjectPokemonPage> {
  final _search = TextEditingController();
  var _view = PokemonWorkspaceView.pokedex;
  Future<PokemonWorkspaceIndex>? _index;
  Future<PokemonCommerceSnapshot>? _commerce;
  Future<PokemonCombatSnapshot>? _combat;
  PokemonSpeciesSummary? _selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final port = ref.watch(pokemonPortProvider(widget.session));
    final commerce = _view == PokemonWorkspaceView.shops
        ? ref.watch(pokemonCommercePortProvider(widget.session))
        : null;
    final combat = _view == PokemonWorkspaceView.combats
        ? ref.watch(pokemonCombatPortProvider(widget.session))
        : null;
    return FutureBuilder(
      key: const ValueKey('studio-project-pokemon'),
      future: _index ??= Future.sync(port.loadIndex),
      builder: (context, snapshot) {
        final index = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioPageHeader(
              title: l10n.railPokemon,
              prominent: true,
              alignActionsToEnd: true,
              actions: [
                if (index?.enabled == true)
                  StudioButton(
                    label: l10n.pokemonImportSpecies,
                    icon: Icons.download_outlined,
                    onPressed: () async {
                      widget.onImporting(true);
                      try {
                        final imported = await showProjectPokemonImport(
                          context,
                          port: port,
                        );
                        if (mounted && imported == true) {
                          setState(() {
                            _selected = null;
                            _index = Future.sync(port.loadIndex);
                          });
                        }
                      } finally {
                        if (mounted) widget.onImporting(false);
                      }
                    },
                  ),
              ],
            ),
            Expanded(
              child: switch (snapshot.connectionState) {
                ConnectionState.waiting => const Center(
                  child: CircularProgressIndicator(),
                ),
                _ when snapshot.hasError => StudioEmptyState(
                  title: l10n.pokemonReadFailed,
                  description: '${snapshot.error}',
                  action: StudioButton(
                    label: l10n.pokemonRetry,
                    onPressed: () => setState(() => _index = null),
                  ),
                ),
                _ when index != null && index.enabled => _catalog(
                  index,
                  commerce: commerce,
                  combat: combat,
                ),
                _ => StudioEmptyState(
                  title: l10n.pokemonDisabled,
                  icon: Icons.catching_pokemon,
                ),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _catalog(
    PokemonWorkspaceIndex index, {
    required PokemonCommercePort? commerce,
    required PokemonCombatPort? combat,
  }) {
    final l10n = context.l10n;
    final types = PokeMapPlayerLocalizations.lookup(Locale(l10n.localeName));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioTabBar(
          tabs: [
            StudioTab(
              value: PokemonWorkspaceView.pokedex,
              label: l10n.pokemonSpecies,
            ),
            StudioTab(
              value: PokemonWorkspaceView.moves,
              label: l10n.pokemonMoves,
            ),
            StudioTab(
              value: PokemonWorkspaceView.items,
              label: l10n.pokemonItems,
            ),
            StudioTab(
              value: PokemonWorkspaceView.shops,
              label: l10n.pokemonShops,
            ),
            StudioTab(
              value: PokemonWorkspaceView.combats,
              label: l10n.pokemonCombats,
            ),
          ],
          selected: _view,
          onSelected: (view) {
            if (view == _view) return;
            setState(() {
              _view = view;
              _search.clear();
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.l),
          child: SizedBox(
            width: 360,
            child: StudioSearchField(
              controller: _search,
              label: l10n.pokemonSearch,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        Expanded(
          child: switch (_view) {
            PokemonWorkspaceView.pokedex => _species(index),
            PokemonWorkspaceView.moves => _rows(
              index.moves.entries.map(
                (move) => (
                  label: move.name,
                  detail: [
                    if (move.type case final type?) types.battleMoveType(type),
                    ?move.description,
                  ].join(' · '),
                ),
              ),
              problem: index.moves.problem,
            ),
            PokemonWorkspaceView.items => _rows(
              index.items.values.map((name) => (label: name, detail: '')),
            ),
            PokemonWorkspaceView.shops => _shops(commerce!),
            PokemonWorkspaceView.combats => _combats(combat!),
          },
        ),
      ],
    );
  }

  Widget _species(PokemonWorkspaceIndex index) {
    final selection = _selected;
    final entries = index.entries
        .where(
          (entry) => _matches(entry.name) || _matches('${entry.nationalDex}'),
        )
        .toList(growable: false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: selection == null ? 1 : 2,
          child: entries.isEmpty
              ? StudioEmptyState(title: context.l10n.pokemonNoResults)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StudioSpacing.l,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return StudioNavigationEntry(
                      label: entry.name,
                      detail: '#${entry.nationalDex}',
                      icon: Icons.catching_pokemon,
                      selected: entry == selection,
                      onTap: () => setState(() => _selected = entry),
                    );
                  },
                ),
        ),
        if (selection != null) ...[
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: _SpeciesDetails(
              key: ValueKey(selection.id),
              entry: selection,
              thumbnail: () => ref
                  .read(pokemonPortProvider(widget.session))
                  .loadThumbnail(selection),
            ),
          ),
        ],
      ],
    );
  }

  Widget _shops(PokemonCommercePort port) => FutureBuilder(
    future: _commerce ??= Future.sync(port.load),
    builder: (context, snapshot) => _loaded(
      snapshot,
      (data) =>
          _rows(data.shops.map((shop) => (label: shop.label, detail: ''))),
      () => setState(() => _commerce = null),
    ),
  );

  Widget _combats(PokemonCombatPort port) => FutureBuilder(
    future: _combat ??= Future.sync(port.load),
    builder: (context, snapshot) => _loaded(
      snapshot,
      (data) => _rows([
        for (final table in data.project.encounterTables)
          (label: table.name, detail: context.l10n.pokemonEncounterTable),
        for (final trainer in data.project.trainers)
          (label: trainer.name, detail: context.l10n.pokemonTrainer),
      ]),
      () => setState(() => _combat = null),
    ),
  );

  Widget _loaded<T>(
    AsyncSnapshot<T> snapshot,
    Widget Function(T) data,
    VoidCallback onRetry,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasData) return data(snapshot.requireData);
    return StudioEmptyState(
      title: context.l10n.pokemonReadFailed,
      description: '${snapshot.error}',
      action: StudioButton(
        label: context.l10n.pokemonRetry,
        onPressed: onRetry,
      ),
    );
  }

  bool _matches(String label) =>
      label.toLowerCase().contains(_search.text.trim().toLowerCase());

  Widget _rows(
    Iterable<({String label, String detail})> rows, {
    String? problem,
  }) {
    final matches = rows
        .where((row) => _matches(row.label))
        .toList(growable: false);
    if (matches.isEmpty) {
      return StudioEmptyState(
        title: problem == null
            ? context.l10n.pokemonNoResults
            : context.l10n.pokemonReadFailed,
        description: problem,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final row = matches[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
          child: StudioPanel(
            compact: true,
            title: row.label,
            children: [if (row.detail.isNotEmpty) Text(row.detail)],
          ),
        );
      },
    );
  }
}
