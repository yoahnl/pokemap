import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class PokemonSpeciesEvolutionEditor extends StatelessWidget {
  const PokemonSpeciesEvolutionEditor({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final json = controller.selectedDraft?.document(
      PokemonDocumentFamily.evolution,
    );
    if (json == null) {
      return const StudioPanel(
        children: [Text('Aucune chaîne d’évolution associée à cette espèce.')],
      );
    }
    final options = {
      '': 'Aucune',
      for (final entry
          in controller.index?.entries ?? const <PokemonSpeciesSummary>[])
        entry.id: '${entry.name} · ${entry.id}',
    };
    final previous = json['preEvolution'] as String? ?? '';
    final evolutions = json['evolutions'] as List? ?? const [];
    return Column(
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
              onPressed: () => _chooseTarget(context, options),
            ),
          ],
          children: [
            if (evolutions.isEmpty) const Text('Aucune évolution renseignée.'),
            for (var i = 0; i < evolutions.length; i++)
              if (evolutions[i] is Map)
                _EvolutionEntry(
                  controller: controller,
                  index: i,
                  value: (evolutions[i] as Map).cast<String, dynamic>(),
                  speciesOptions: options,
                ),
            const Text(
              'Une condition enregistrée ne garantit pas son exécution dans le jeu.',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _chooseTarget(
    BuildContext context,
    Map<String, String> options,
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
    if (target == null || target.isEmpty) return;
    controller.edit(PokemonDocumentFamily.evolution, (json) {
      final entries = List<dynamic>.from(json['evolutions'] as List? ?? []);
      entries.add(<String, dynamic>{
        'targetSpeciesId': target,
        'method': 'level',
        'conditionText': <String, String>{},
      });
      json['evolutions'] = entries;
    });
  }
}

class _EvolutionEntry extends StatelessWidget {
  const _EvolutionEntry({
    required this.controller,
    required this.index,
    required this.value,
    required this.speciesOptions,
  });

  final PokemonWorkspaceController controller;
  final int index;
  final Map<String, dynamic> value;
  final Map<String, String> speciesOptions;

  void _edit(String key, Object? change) {
    controller.edit(PokemonDocumentFamily.evolution, (json) {
      final entries = List<dynamic>.from(json['evolutions'] as List? ?? []);
      final current = Map<String, dynamic>.from(entries[index] as Map);
      current[key] = change;
      entries[index] = current;
      json['evolutions'] = entries;
    });
  }

  void _condition(String language, String text) {
    final conditions = Map<String, dynamic>.from(
      value['conditionText'] as Map? ?? {},
    );
    conditions[language] = text;
    _edit('conditionText', conditions);
  }

  @override
  Widget build(BuildContext context) {
    final conditions =
        (value['conditionText'] as Map?)?.cast<String, dynamic>() ?? {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cible ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: 'Retirer cette évolution',
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.edit(PokemonDocumentFamily.evolution, (json) {
                    final entries = List<dynamic>.from(
                      json['evolutions'] as List? ?? [],
                    );
                    entries.removeAt(index);
                    json['evolutions'] = entries;
                  });
                },
              ),
            ],
          ),
          StudioSelect(
            label: 'Espèce cible',
            value: value['targetSpeciesId'] as String?,
            options: speciesOptions,
            onChanged: (selected) => _edit('targetSpeciesId', selected),
          ),
          StudioDraftField(
            key: ValueKey('evolution-$index-method'),
            label: 'Méthode conservée',
            value: '${value['method'] ?? ''}',
            onChanged: (text) => _edit('method', text),
          ),
          StudioDraftField(
            key: ValueKey('evolution-$index-minLevel'),
            label: 'Niveau minimum',
            value: '${value['minLevel'] ?? ''}',
            onChanged: (text) => _edit(
              'minLevel',
              text.isEmpty ? null : int.tryParse(text) ?? text,
            ),
          ),
          StudioDraftField(
            key: ValueKey('evolution-$index-minFriendship'),
            label: 'Amitié minimum',
            value: '${value['minFriendship'] ?? ''}',
            onChanged: (text) => _edit(
              'minFriendship',
              text.isEmpty ? null : int.tryParse(text) ?? text,
            ),
          ),
          StudioSelect(
            label: 'Objet requis',
            value: value['itemId'] as String? ?? '',
            options: {'': 'Aucun', ...?controller.index?.items},
            onChanged: (selected) =>
                _edit('itemId', selected.isEmpty ? null : selected),
          ),
          StudioSelect(
            label: 'Attaque requise',
            value: value['requiredMoveId'] as String? ?? '',
            options: {
              '': 'Aucune',
              for (final move
                  in controller.index?.moves.entries ??
                      const <PokemonMoveSummary>[])
                move.id: '${move.name} · ${move.id}',
            },
            onChanged: (selected) =>
                _edit('requiredMoveId', selected.isEmpty ? null : selected),
          ),
          for (final language in {'fr', 'en', ...conditions.keys})
            StudioDraftField(
              key: ValueKey('evolution-$index-condition-$language'),
              label: 'Condition · $language',
              value: '${conditions[language] ?? ''}',
              onChanged: (text) => _condition(language, text),
            ),
        ],
      ),
    );
  }
}
