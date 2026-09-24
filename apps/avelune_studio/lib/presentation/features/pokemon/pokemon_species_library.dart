import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'pokemon_species_thumbnail.dart';

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

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final entries = controller.visibleSpecies;
    final all = controller.index!.entries;
    final types = <String>{for (final entry in all) ...entry.types};
    final generations = <int>{for (final entry in all) entry.generation};
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pokédex · ${all.length} ${all.length == 1 ? 'espèce' : 'espèces'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          StudioSearchField(
            controller: search,
            onChanged: controller.setSearch,
            label: 'Rechercher une espèce',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 148,
                child: StudioSelect(
                  label: 'Type',
                  value: controller.typeFilter ?? '',
                  options: {
                    '': 'Tous les types',
                    for (final type in types.toList()..sort()) type: type,
                  },
                  onChanged: (value) => controller.setFilters(
                    type: value.isEmpty ? null : value,
                    generation: controller.generationFilter,
                    enabled: controller.enabledFilter,
                  ),
                ),
              ),
              SizedBox(
                width: 148,
                child: StudioSelect(
                  label: 'Génération',
                  value: controller.generationFilter?.toString() ?? '',
                  options: {
                    '': 'Toutes',
                    for (final generation in generations.toList()..sort())
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
                width: 148,
                child: StudioSelect(
                  label: 'Activation',
                  value: controller.enabledFilter?.toString() ?? '',
                  options: const {
                    '': 'Toutes',
                    'true': 'Activées',
                    'false': 'Désactivées',
                  },
                  onChanged: (value) => controller.setFilters(
                    type: controller.typeFilter,
                    generation: controller.generationFilter,
                    enabled: value.isEmpty ? null : value == 'true',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.selectedId != null &&
              !entries.any((entry) => entry.id == controller.selectedId))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'La fiche sélectionnée est masquée par les filtres.',
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
          Expanded(
            child: all.isEmpty
                ? const Center(child: Text('Aucune espèce dans ce projet.'))
                : entries.isEmpty
                ? const Center(child: Text('Aucun résultat pour ces filtres.'))
                : ListView.builder(
                    key: const PageStorageKey('pokemon-species-list'),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        child: ListTile(
                          key: ValueKey('species-${entry.id}'),
                          selected: entry.id == controller.selectedId,
                          leading: PokemonSpeciesThumbnail(
                            key: ValueKey('thumbnail-${entry.id}'),
                            entry: entry,
                            port: controller.port,
                          ),
                          title: Text(entry.name),
                          subtitle: Text(
                            '#${entry.nationalDex} · ${entry.id} · ${entry.types.join(' / ')}',
                          ),
                          trailing: Icon(
                            entry.enabled
                                ? Icons.check_circle_outline
                                : Icons.block_outlined,
                          ),
                          onTap: () async {
                            if (controller.selectedId != entry.id &&
                                controller.hasPendingChanges) {
                              final choice = await showDialog<String>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text(
                                    'Changer de fiche Pokémon ?',
                                  ),
                                  content: const Text(
                                    'La fiche en cours contient un brouillon.',
                                  ),
                                  actions: [
                                    StudioButton(
                                      label: 'Rester',
                                      secondary: true,
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, 'stay'),
                                    ),
                                    StudioButton(
                                      label: 'Annuler les modifications',
                                      secondary: true,
                                      onPressed: () => Navigator.pop(
                                        dialogContext,
                                        'discard',
                                      ),
                                    ),
                                    StudioButton(
                                      label: 'Enregistrer',
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, 'save'),
                                    ),
                                  ],
                                ),
                              );
                              if (!context.mounted ||
                                  choice == null ||
                                  choice == 'stay') {
                                return;
                              }
                              if (choice == 'save' &&
                                  !await controller.save()) {
                                return;
                              }
                              if (choice == 'discard') {
                                controller.discardSelected();
                              }
                            }
                            final selected = await controller.selectSpecies(
                              entry.id,
                            );
                            if (selected && context.mounted) {
                              widget.onSelected();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
