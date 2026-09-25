import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'pokemon_species_list_item.dart';
import 'pokemon_ui_parts.dart';

class PokemonSpeciesLibrary extends StatefulWidget {
  const PokemonSpeciesLibrary({
    super.key,
    required this.controller,
    required this.onSelected,
  });

  final PokemonWorkspaceController controller;
  final VoidCallback onSelected;

  @override
  State<PokemonSpeciesLibrary> createState() => _PokemonSpeciesLibraryState();
}

class _PokemonSpeciesLibraryState extends State<PokemonSpeciesLibrary> {
  late final search = TextEditingController(text: widget.controller.search);
  final listScroll = ScrollController();

  @override
  void dispose() {
    search.dispose();
    listScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final entries = controller.visibleSpecies;
    final all = controller.index!.entries;
    final types = <String>{for (final entry in all) ...entry.types};
    final generations = <int>{for (final entry in all) entry.generation};
    final selectedHidden =
        controller.selectedId != null &&
        !entries.any((entry) => entry.id == controller.selectedId);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: LayoutBuilder(
          builder: (context, bounds) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: bounds.maxHeight * .36),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PokemonSectionHeading(
                        title:
                            'Pokédex · ${all.length} '
                            '${all.length == 1 ? 'espèce' : 'espèces'}',
                        description: entries.length == all.length
                            ? 'Sélectionnez une espèce pour consulter sa fiche.'
                            : '${entries.length} résultat(s) affiché(s)',
                      ),
                      StudioSearchField(
                        controller: search,
                        onChanged: controller.setSearch,
                        label: 'Rechercher une espèce',
                      ),
                      const SizedBox(height: 9),
                      LayoutBuilder(
                        builder: (context, bounds) {
                          final width = (bounds.maxWidth - 8) / 2;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 7,
                            children: [
                              SizedBox(
                                width: width,
                                child: StudioSelect(
                                  label: 'Type',
                                  value: controller.typeFilter ?? '',
                                  options: {
                                    '': 'Tous les types',
                                    for (final type in types.toList()..sort())
                                      type: type,
                                  },
                                  onChanged: (value) => controller.setFilters(
                                    type: value.isEmpty ? null : value,
                                    generation: controller.generationFilter,
                                    enabled: controller.enabledFilter,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: StudioSelect(
                                  label: 'Génération',
                                  value:
                                      controller.generationFilter?.toString() ??
                                      '',
                                  options: {
                                    '': 'Toutes',
                                    for (final generation
                                        in generations.toList()..sort())
                                      '$generation': 'Génération $generation',
                                  },
                                  onChanged: (value) => controller.setFilters(
                                    type: controller.typeFilter,
                                    generation: int.tryParse(value),
                                    enabled: controller.enabledFilter,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: StudioSelect(
                                  label: 'Activation',
                                  value:
                                      controller.enabledFilter?.toString() ??
                                      '',
                                  options: const {
                                    '': 'Toutes',
                                    'true': 'Activées',
                                    'false': 'Désactivées',
                                  },
                                  onChanged: (value) => controller.setFilters(
                                    type: controller.typeFilter,
                                    generation: controller.generationFilter,
                                    enabled: value.isEmpty
                                        ? null
                                        : value == 'true',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (selectedHidden)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'La fiche ouverte est masquée par les filtres.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 13),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: all.isEmpty
                    ? const PokemonEmptyState(
                        title: 'Pokédex vide',
                        description: 'Importez une espèce pour commencer.',
                      )
                    : entries.isEmpty
                    ? const PokemonEmptyState(
                        title: 'Aucun résultat',
                        description:
                            'Essayez un autre nom ou ajustez les filtres.',
                        icon: Icons.search_off,
                      )
                    : Scrollbar(
                        controller: listScroll,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: listScroll,
                          key: const PageStorageKey('pokemon-species-list'),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return PokemonSpeciesListItem(
                              entry: entry,
                              port: controller.port,
                              selected: entry.id == controller.selectedId,
                              onTap: () => _select(entry.id),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(String id) async {
    final controller = widget.controller;
    if (controller.selectedId != id && controller.hasPendingChanges) {
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Changer de fiche Pokémon ?'),
          content: const Text('La fiche en cours contient un brouillon.'),
          actions: [
            StudioButton(
              label: 'Rester',
              secondary: true,
              onPressed: () => Navigator.pop(dialogContext, 'stay'),
            ),
            StudioButton(
              label: 'Annuler les modifications',
              secondary: true,
              onPressed: () => Navigator.pop(dialogContext, 'discard'),
            ),
            StudioButton(
              label: 'Enregistrer',
              onPressed: () => Navigator.pop(dialogContext, 'save'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null || choice == 'stay') return;
      if (choice == 'save' && !await controller.saveActiveOwner()) return;
      if (choice == 'discard') controller.discardSelectedSpecies();
    }
    final selected = await controller.selectSpecies(id);
    if (selected && mounted) widget.onSelected();
  }
}
