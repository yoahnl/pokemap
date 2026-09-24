import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import 'pokemon_move_detail.dart';
import 'pokemon_move_list_item.dart';
import 'pokemon_moves_sync_panel.dart';
import 'pokemon_ui_parts.dart';

class PokemonMovesLibrary extends StatefulWidget {
  const PokemonMovesLibrary({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  State<PokemonMovesLibrary> createState() => _PokemonMovesLibraryState();
}

class _PokemonMovesLibraryState extends State<PokemonMovesLibrary> {
  late final search = TextEditingController(text: widget.controller.moveSearch);
  bool showCompactDetail = false;
  bool showSync = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final catalog = controller.index!.moves;
    final entries = controller.visibleMoves;
    final move = catalog.entries
        .where((item) => item.id == controller.selectedMoveId)
        .firstOrNull;
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact =
            bounds.maxWidth < 930 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Catalogue des attaques',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StudioButton(
                    label: showSync
                        ? 'Masquer la synchronisation'
                        : 'Synchronisation',
                    icon: Icons.sync,
                    secondary: true,
                    onPressed: () => setState(() => showSync = !showSync),
                  ),
                ],
              ),
            ),
            if (showSync ||
                controller.movesPreview != null ||
                catalog.problem != null)
              SizedBox(
                height: (bounds.maxHeight * .38).clamp(120, 270),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: PokemonMovesSyncPanel(controller: controller),
                  ),
                ),
              ),
            Expanded(
              child: compact && showCompactDetail && move != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StudioButton(
                                label: 'Retour aux attaques',
                                secondary: true,
                                icon: Icons.arrow_back,
                                onPressed: () =>
                                    setState(() => showCompactDetail = false),
                              ),
                              if (controller.moveInsertGroup != null)
                                StudioButton(
                                  label: 'Choisir cette attaque',
                                  onPressed: () =>
                                      controller.chooseMove(move.id),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: PokemonMoveDetail(move: move),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: compact
                              ? bounds.maxWidth
                              : (bounds.maxWidth * .28).clamp(300, 360),
                          child: ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PokemonSectionHeading(
                                    title:
                                        'Attaques · ${catalog.entries.length}',
                                    description:
                                        entries.length == catalog.entries.length
                                        ? 'Sélectionnez une attaque pour voir ses valeurs.'
                                        : '${entries.length} résultat(s) affiché(s)',
                                  ),
                                  StudioSearchField(
                                    controller: search,
                                    onChanged: controller.setMoveSearch,
                                    label: 'Rechercher une attaque',
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: entries.isEmpty
                                        ? PokemonEmptyState(
                                            title: catalog.problem == null
                                                ? 'Aucune attaque trouvée'
                                                : 'Catalogue indisponible',
                                            description: catalog.problem == null
                                                ? 'Essayez une autre recherche.'
                                                : 'Préparez le catalogue avec la synchronisation.',
                                            icon: Icons.search_off,
                                          )
                                        : ListView.builder(
                                            key: const PageStorageKey(
                                              'pokemon-moves-list',
                                            ),
                                            itemCount: entries.length,
                                            itemBuilder: (context, index) =>
                                                PokemonMoveListItem(
                                                  entry: entries[index],
                                                  selected:
                                                      entries[index].id ==
                                                      controller.selectedMoveId,
                                                  choosing:
                                                      controller
                                                          .moveInsertGroup !=
                                                      null,
                                                  onTap: () {
                                                    controller.selectMove(
                                                      entries[index].id,
                                                    );
                                                    if (compact) {
                                                      setState(
                                                        () =>
                                                            showCompactDetail =
                                                                true,
                                                      );
                                                    }
                                                  },
                                                  onChoose: () =>
                                                      controller.chooseMove(
                                                        entries[index].id,
                                                      ),
                                                ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!compact) ...[
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: move == null
                                  ? const PokemonEmptyState(
                                      title: 'Choisissez une attaque',
                                      description:
                                          'Le catalogue du projet est consultable ici.',
                                      icon: Icons.menu_book_outlined,
                                    )
                                  : SingleChildScrollView(
                                      child: PokemonMoveDetail(move: move),
                                    ),
                            ),
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
}
