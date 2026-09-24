import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_base_stats.dart';
import 'pokemon_draft_controls.dart';
import 'pokemon_ui_parts.dart';

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
    final content = (json['dexContent'] as Map?)?.cast<String, dynamic>() ?? {};
    final typeJson = (json['typing'] as Map?)?.cast<String, dynamic>() ?? {};
    final selectedTypes = List<String>.from(typeJson['types'] as List? ?? []);
    final typeOptions = {
      '': 'Aucun',
      for (final type in controller.index?.types ?? const <String>[])
        type: pokemonTypeLabel(type),
    };
    final identity = Column(
      children: [
        StudioPanel(
          title: 'Identité et description',
          children: [
            PokemonDataRow(label: 'Identifiant', value: draft.id),
            PokemonDataRow(label: 'Slug', value: '${json['slug'] ?? '—'}'),
            PokemonDataRow(
              label: 'Numéro national',
              value: '${json['nationalDex'] ?? '—'}',
            ),
            const Divider(height: 24),
            for (final language in names.keys)
              fields.text('Nom · $language', ['names', language]),
            fields.text('Description du Pokédex', [
              'dexContent',
              'flavorText',
            ], lines: 3),
            LayoutBuilder(
              builder: (context, bounds) {
                final compact = bounds.maxWidth < 440;
                final first = StudioSelect(
                  label: 'Type principal',
                  value: selectedTypes.firstOrNull,
                  options: typeOptions,
                  onChanged: (value) => _setType(0, value),
                );
                final second = StudioSelect(
                  label: 'Type secondaire',
                  value: selectedTypes.length > 1 ? selectedTypes[1] : '',
                  options: typeOptions,
                  onChanged: (value) => _setType(1, value),
                );
                return compact
                    ? Column(
                        children: [first, const SizedBox(height: 9), second],
                      )
                    : Row(
                        children: [
                          Expanded(child: first),
                          const SizedBox(width: 10),
                          Expanded(child: second),
                        ],
                      );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Classification consultable',
          children: [
            PokemonDataRow(
              label: 'Génération',
              value: '${json['genIntroduced'] ?? 'Non renseignée'}',
            ),
            PokemonDataRow(
              label: 'Taille',
              value: content['heightM'] == null
                  ? 'Non renseignée'
                  : '${content['heightM']} m',
            ),
            PokemonDataRow(
              label: 'Poids',
              value: content['weightKg'] == null
                  ? 'Non renseigné'
                  : '${content['weightKg']} kg',
            ),
          ],
        ),
      ],
    );
    final abilities =
        (json['abilities'] as Map?)?.values
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .toList() ??
        const <String>[];
    final right = Column(
      children: [
        PokemonBaseStats(
          stats: (json['baseStats'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Talents référencés',
          children: [
            if (abilities.isEmpty)
              const Text('Aucun talent renseigné.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ability in abilities) PokemonPill(label: ability),
                ],
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
      ],
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        final columns =
            bounds.maxWidth >= 760 &&
            MediaQuery.textScalerOf(context).scale(14) <= 18;
        if (!columns) {
          return Column(
            children: [identity, const SizedBox(height: 12), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: identity),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
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
