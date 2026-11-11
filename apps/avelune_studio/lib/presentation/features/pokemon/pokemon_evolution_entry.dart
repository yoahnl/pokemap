import '../../../features/pokemon/application/pokemon_document_editing.dart';

import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_section.dart';
import '../../../features/pokemon/application/pokemon_evolution_rule.dart';
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

  void _edit(String key, Object? change) => controller.edit(
    PokemonDocumentFamily.evolution,
    (json) => PokemonDocumentEditing.editEvolution(json, index, key, change),
  );

  void _condition(String language, String text) => controller.edit(
    PokemonDocumentFamily.evolution,
    (json) => PokemonDocumentEditing.editEvolutionCondition(
      json,
      index,
      language,
      text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final conditions =
        (value['conditionText'] as Map?)?.cast<String, dynamic>() ?? {};
    final method = '${value['method'] ?? ''}'.trim();
    final kind = pokemonEvolutionRuleKind(value);
    final moves = {
      for (final move
          in controller.index?.moves.entries ?? const <PokemonMoveSummary>[])
        move.id: move.name,
    };
    final items = controller.index?.items ?? const <String, String>{};
    final rule = pokemonEvolutionRule(
      value,
      itemName: (id) => items[id] ?? id,
      moveName: (id) => moves[id] ?? id,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokemonSectionHeading(
          title: 'Relation ${index + 1}',
          description: 'Seule la règle exécutée est lue par le jeu ; la description reste un texte libre.',
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
        const SizedBox(height: 14),
        Text(
          'Règle exécutée par le jeu',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        StudioSelect(
          label: 'Déclenchement en jeu',
          value: method,
          options: pokemonEvolutionMethodOptions(value),
          onChanged: pokemonEvolutionGuidedMethodLocked(value)
              ? null
              : (selected) => _edit('method', selected),
        ),
        const SizedBox(height: 8),
        if (rule.executable)
          Text(rule.sentence, key: ValueKey('evolution-$index-rule'))
        else
          StudioNotice(
            rule.sentence,
            key: ValueKey('evolution-$index-rule'),
            isError: kind != PokemonEvolutionRuleKind.unsupported,
          ),
        const SizedBox(height: 11),
        if (pokemonEvolutionShowsField(value, 'minLevel')) ...[
          StudioDraftField(
            key: ValueKey('evolution-$index-minLevel'),
            label: 'Niveau minimum',
            value: '${value['minLevel'] ?? ''}',
            onChanged: (text) =>
                _edit('minLevel', pokemonDocumentNumberInput(text)),
          ),
          const SizedBox(height: 11),
        ],
        if (pokemonEvolutionShowsField(value, 'minFriendship')) ...[
          StudioDraftField(
            key: ValueKey('evolution-$index-minFriendship'),
            label: 'Amitié minimum',
            value: '${value['minFriendship'] ?? ''}',
            onChanged: (text) =>
                _edit('minFriendship', pokemonDocumentNumberInput(text)),
          ),
          const SizedBox(height: 11),
        ],
        if (pokemonEvolutionShowsField(value, 'itemId')) ...[
          StudioSelect(
            label: 'Objet requis',
            value: value['itemId'] as String? ?? '',
            options: {'': 'Aucun', ...items},
            onChanged: (selected) =>
                _edit('itemId', pokemonOptionalChoice(selected)),
          ),
          const SizedBox(height: 11),
        ],
        if (pokemonEvolutionShowsField(value, 'requiredMoveId')) ...[
          StudioSelect(
            label: 'Attaque requise',
            value: value['requiredMoveId'] as String? ?? '',
            options: {
              '': 'Aucune',
              for (final move in moves.entries)
                move.key: '${move.value} · ${move.key}',
            },
            onChanged: (selected) =>
                _edit('requiredMoveId', pokemonOptionalChoice(selected)),
          ),
          const SizedBox(height: 11),
        ],
        const SizedBox(height: 6),
        Text('Description', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Texte libre pour décrire l’évolution. Le jeu ne lit pas ce texte : il ne déclenche ni n’empêche rien.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final language in {'fr', 'en', ...conditions.keys}) ...[
          StudioDraftField(
            key: ValueKey('evolution-$index-condition-$language'),
            label: 'Description · $language',
            value: '${conditions[language] ?? ''}',
            onChanged: (text) => _condition(language, text),
          ),
          const SizedBox(height: 11),
        ],
        StudioSection(
          key: PageStorageKey<String>('evolution-$index-technical'),
          title: 'Données techniques',
          collapsible: true,
          initiallyExpanded: false,
          children: [
            SizedBox(
              key: PageStorageKey<String>('evolution-$index-technical-fields'),
              width: double.infinity,
              child: StudioDraftField(
                key: ValueKey('evolution-$index-method'),
                label: 'Identifiant de méthode conservé',
                value: method,
                onChanged: (text) => _edit('method', text),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
