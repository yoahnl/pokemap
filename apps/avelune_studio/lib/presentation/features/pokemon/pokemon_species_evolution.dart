import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_evolution_entry.dart';
import 'pokemon_ui_parts.dart';

class PokemonSpeciesEvolutionEditor extends StatefulWidget {
  const PokemonSpeciesEvolutionEditor({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  State<PokemonSpeciesEvolutionEditor> createState() =>
      _PokemonSpeciesEvolutionEditorState();
}

class _PokemonSpeciesEvolutionEditorState
    extends State<PokemonSpeciesEvolutionEditor> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final problem = controller.selectedDraft?.base.evolution?.problem;
    if (problem != null) return PokemonSurface(child: Text(problem));
    final json = controller.selectedDraft?.document(
      PokemonDocumentFamily.evolution,
    );
    if (json == null) {
      return const PokemonSurface(
        child: Text('Aucune chaîne d’évolution associée à cette espèce.'),
      );
    }
    final species =
        controller.index?.entries ?? const <PokemonSpeciesSummary>[];
    final options = {
      '': 'Aucune',
      for (final entry in species) entry.id: '${entry.name} · ${entry.id}',
    };
    final previous = json['preEvolution'] as String? ?? '';
    final evolutions = json['evolutions'] as List? ?? const [];
    final current = species
        .where((entry) => entry.id == controller.selectedDraft?.id)
        .firstOrNull;
    final targetIndex = evolutions.isEmpty
        ? null
        : selectedIndex.clamp(0, evolutions.length - 1);
    final graph = StudioPanel(
      title: 'Parcours connu',
      children: [
        Text(
          'Cette vue reflète uniquement les relations stockées dans ce projet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        if (previous.isNotEmpty) ...[
          PokemonSurface(
            emphasized: true,
            child: PokemonDataRow(
              label: 'Prédécesseur',
              value: options[previous] ?? '$previous · non résolu',
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Icon(Icons.arrow_downward, size: 18),
          ),
        ],
        PokemonSurface(
          emphasized: true,
          child: Row(
            children: [
              const Icon(Icons.catching_pokemon_outlined),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  current == null
                      ? '${controller.selectedDraft!.id} · non résolu'
                      : '${current.name} · ${current.id}',
                ),
              ),
              const PokemonPill(label: 'Forme actuelle'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (evolutions.isEmpty)
          const Text('Aucune cible d’évolution renseignée.')
        else
          for (var i = 0; i < evolutions.length; i++)
            if (evolutions[i] is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: PokemonSurface(
                  emphasized: i == targetIndex,
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => setState(() => selectedIndex = i),
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_forward, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _targetLabel(
                                '${(evolutions[i] as Map)['targetSpeciesId'] ?? ''}',
                                options,
                              ),
                            ),
                          ),
                          if (i == targetIndex)
                            Icon(
                              Icons.radio_button_checked,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
    final editor = Column(
      children: [
        StudioPanel(
          title: 'Prédécesseur',
          children: [
            StudioSelect(
              label: 'Espèce précédente',
              value: previous,
              options: options,
              onChanged: (value) => controller.edit(
                PokemonDocumentFamily.evolution,
                (data) => data['preEvolution'] = value.isEmpty ? null : value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Évolutions',
          actions: [
            StudioButton(
              label: 'Ajouter une cible',
              secondary: true,
              icon: Icons.add,
              onPressed: () =>
                  _chooseTarget(context, options, evolutions.length),
            ),
          ],
          children: [
            if (targetIndex == null)
              const Text('Sélectionnez ou ajoutez une relation.')
            else if (evolutions[targetIndex] is Map)
              PokemonEvolutionEntry(
                controller: controller,
                index: targetIndex,
                value: (evolutions[targetIndex] as Map).cast<String, dynamic>(),
                speciesOptions: options,
                onRemove: () => _remove(targetIndex),
              ),
          ],
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        if (bounds.maxWidth < 760 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(children: [graph, const SizedBox(height: 12), editor]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: graph),
            const SizedBox(width: 12),
            Expanded(child: editor),
          ],
        );
      },
    );
  }

  String _targetLabel(String id, Map<String, String> options) =>
      options[id] ?? '$id · non résolu';

  void _remove(int index) {
    widget.controller.edit(PokemonDocumentFamily.evolution, (json) {
      final entries = List<dynamic>.from(json['evolutions'] as List? ?? []);
      entries.removeAt(index);
      json['evolutions'] = entries;
    });
    setState(() => selectedIndex = 0);
  }

  Future<void> _chooseTarget(
    BuildContext context,
    Map<String, String> options,
    int newIndex,
  ) async {
    String? selected;
    final target = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Choisir la cible d’évolution'),
          content: StudioSelect(
            label: 'Espèce cible',
            value: selected,
            options: options,
            onChanged: (value) => refresh(() => selected = value),
          ),
          actions: [
            StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            StudioButton(
              label: 'Ajouter',
              onPressed: selected == null || selected!.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, selected),
            ),
          ],
        ),
      ),
    );
    if (target == null || target.isEmpty || !mounted) return;
    widget.controller.edit(PokemonDocumentFamily.evolution, (json) {
      final entries = List<dynamic>.from(json['evolutions'] as List? ?? []);
      entries.add(<String, dynamic>{
        'targetSpeciesId': target,
        'method': 'level',
        'conditionText': <String, String>{},
      });
      json['evolutions'] = entries;
    });
    setState(() => selectedIndex = newIndex);
  }
}
