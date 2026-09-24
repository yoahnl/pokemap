import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'pokemon_ui_parts.dart';

class PokemonEvolutionEntry extends StatelessWidget {
  const PokemonEvolutionEntry({
    super.key,
    required this.controller,
    required this.index,
    required this.value,
    required this.speciesOptions,
    required this.onRemove,
  });

  final PokemonWorkspaceController controller;
  final int index;
  final Map<String, dynamic> value;
  final Map<String, String> speciesOptions;
  final VoidCallback onRemove;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokemonSectionHeading(
          title: 'Relation ${index + 1}',
          description:
              'Une condition enregistrée ne garantit pas son exécution en jeu.',
          trailing: IconButton(
            tooltip: 'Retirer cette évolution',
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ),
        StudioSelect(
          label: 'Espèce cible',
          value: value['targetSpeciesId'] as String?,
          options: speciesOptions,
          onChanged: (selected) => _edit('targetSpeciesId', selected),
        ),
        const SizedBox(height: 11),
        StudioDraftField(
          key: ValueKey('evolution-$index-method'),
          label: 'Méthode conservée',
          value: '${value['method'] ?? ''}',
          onChanged: (text) => _edit('method', text),
        ),
        const SizedBox(height: 11),
        LayoutBuilder(
          builder: (context, bounds) {
            final level = StudioDraftField(
              key: ValueKey('evolution-$index-minLevel'),
              label: 'Niveau minimum',
              value: '${value['minLevel'] ?? ''}',
              onChanged: (text) => _edit(
                'minLevel',
                text.isEmpty ? null : int.tryParse(text) ?? text,
              ),
            );
            final friendship = StudioDraftField(
              key: ValueKey('evolution-$index-minFriendship'),
              label: 'Amitié minimum',
              value: '${value['minFriendship'] ?? ''}',
              onChanged: (text) => _edit(
                'minFriendship',
                text.isEmpty ? null : int.tryParse(text) ?? text,
              ),
            );
            return bounds.maxWidth < 430
                ? Column(
                    children: [level, const SizedBox(height: 11), friendship],
                  )
                : Row(
                    children: [
                      Expanded(child: level),
                      const SizedBox(width: 10),
                      Expanded(child: friendship),
                    ],
                  );
          },
        ),
        const SizedBox(height: 11),
        StudioSelect(
          label: 'Objet requis',
          value: value['itemId'] as String? ?? '',
          options: {'': 'Aucun', ...?controller.index?.items},
          onChanged: (selected) =>
              _edit('itemId', selected.isEmpty ? null : selected),
        ),
        const SizedBox(height: 11),
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
        const SizedBox(height: 11),
        for (final language in {'fr', 'en', ...conditions.keys}) ...[
          StudioDraftField(
            key: ValueKey('evolution-$index-condition-$language'),
            label: 'Condition · $language',
            value: '${conditions[language] ?? ''}',
            onChanged: (text) => _condition(language, text),
          ),
          const SizedBox(height: 11),
        ],
      ],
    );
  }
}
