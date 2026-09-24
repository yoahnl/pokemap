import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'pokemon_draft_controls.dart';

class PokemonSpeciesOverview extends StatelessWidget {
  const PokemonSpeciesOverview({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final draft = controller.selectedDraft!;
    final json = draft.document(PokemonDocumentFamily.species)!;
    final fields = PokemonDraftControls(
      controller,
      PokemonDocumentFamily.species,
    );
    final names = (json['names'] as Map?)?.cast<String, dynamic>() ?? {};
    final typeJson = (json['typing'] as Map?)?.cast<String, dynamic>() ?? {};
    final selectedTypes = List<String>.from(typeJson['types'] as List? ?? []);
    final typeOptions = {
      '': 'Aucun',
      for (final type in controller.index?.types ?? const <String>[])
        type: type,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioPanel(
          title: 'Identité et description',
          children: [
            Text(
              'Identifiant ${draft.id} · Slug ${json['slug']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final language in names.keys)
              fields.text('Nom · $language', ['names', language]),
            fields.text('Description du Pokédex', ['dexContent', 'flavorText']),
            StudioSelect(
              label: 'Type principal',
              value: selectedTypes.firstOrNull,
              options: typeOptions,
              onChanged: (value) => _setType(0, value),
            ),
            const SizedBox(height: 12),
            StudioSelect(
              label: 'Type secondaire',
              value: selectedTypes.length > 1 ? selectedTypes[1] : '',
              options: typeOptions,
              onChanged: (value) => _setType(1, value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Présence dans le projet',
          children: [
            fields.toggle('Espèce activée', [
              'classification',
              'isEnabledInProject',
            ]),
            fields.toggle('Éligible comme starter', [
              'gameplayFlags',
              'starterEligible',
            ]),
            fields.toggle('Disponible uniquement en cadeau', [
              'gameplayFlags',
              'giftOnly',
            ]),
            fields.toggle('Disponible uniquement par échange', [
              'gameplayFlags',
              'tradeOnly',
            ]),
          ],
        ),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Données consultables',
          children: [
            Text(
              'Statistiques : ${(json['baseStats'] as Map?)?.entries.map((entry) => '${entry.key} ${entry.value}').join(' · ') ?? 'indisponibles'}',
            ),
            Text(
              'Talents : ${(json['abilities'] as Map?)?.values.whereType<String>().join(' · ') ?? 'indisponibles'}',
            ),
          ],
        ),
      ],
    );
  }

  void _setType(int position, String value) {
    controller.edit(PokemonDocumentFamily.species, (json) {
      final typing = Map<String, dynamic>.from(json['typing'] as Map? ?? {});
      final types = List<String>.from(typing['types'] as List? ?? []);
      if (position == 0) {
        if (types.isEmpty) {
          types.add(value);
        } else {
          types[0] = value;
        }
      } else if (value.isEmpty) {
        if (types.length > 1) types.removeAt(1);
      } else if (types.length > 1) {
        types[1] = value;
      } else {
        types.add(value);
      }
      typing['types'] = types.where((type) => type.isNotEmpty).toSet().toList();
      json['typing'] = typing;
    });
  }
}
