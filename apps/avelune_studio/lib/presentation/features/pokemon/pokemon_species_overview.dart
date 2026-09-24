import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_base_stats.dart';
import 'pokemon_draft_controls.dart';
import 'pokemon_ui_parts.dart';

class PokemonSpeciesOverview extends StatefulWidget {
  const PokemonSpeciesOverview({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  State<PokemonSpeciesOverview> createState() => _PokemonSpeciesOverviewState();
}

class _PokemonSpeciesOverviewState extends State<PokemonSpeciesOverview> {
  bool translationsOpen = false;
  bool technicalOpen = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final draft = controller.selectedDraft!;
    final json = draft.document(PokemonDocumentFamily.species)!;
    final fields = PokemonDraftControls(
      controller,
      PokemonDocumentFamily.species,
    );
    final names = (json['names'] as Map?)?.cast<String, dynamic>() ?? {};
    final content = (json['dexContent'] as Map?)?.cast<String, dynamic>() ?? {};
    final typing = (json['typing'] as Map?)?.cast<String, dynamic>() ?? {};
    final types = List<String>.from(typing['types'] as List? ?? []);
    final activeLanguage =
        controller.editingLanguage ?? controller.index?.locale ?? 'fr';
    final languages = {
      activeLanguage,
      'fr',
      'en',
      'de',
      'es',
      'it',
      'ja',
      ...names.keys,
    }.toList()..sort();
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
            StudioSelect(
              label: 'Langue d’édition du nom',
              value: activeLanguage,
              options: {for (final key in languages) key: _languageLabel(key)},
              onChanged: controller.setEditingLanguage,
            ),
            const SizedBox(height: 10),
            if (names[activeLanguage] == null ||
                '${names[activeLanguage]}'.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Aucune traduction pour $activeLanguage. Une valeur ne sera '
                  'créée que si vous la saisissez.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            fields.text('Nom · ${_languageLabel(activeLanguage)}', [
              'names',
              activeLanguage,
            ]),
            fields.text('Description du Pokédex · texte commun', [
              'dexContent',
              'flavorText',
            ], lines: 3),
            LayoutBuilder(
              builder: (context, bounds) {
                final first = StudioSelect(
                  label: 'Type principal',
                  value: types.firstOrNull,
                  options: typeOptions,
                  onChanged: (value) => _setType(0, value),
                );
                final second = StudioSelect(
                  label: 'Type secondaire',
                  value: types.length > 1 ? types[1] : '',
                  options: typeOptions,
                  onChanged: (value) => _setType(1, value),
                );
                return bounds.maxWidth < 440
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
          title: 'Autres traductions',
          children: [
            TextButton.icon(
              onPressed: () =>
                  setState(() => translationsOpen = !translationsOpen),
              icon: Icon(
                translationsOpen ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(
                translationsOpen
                    ? 'Masquer les langues'
                    : 'Voir les ${names.length} langues disponibles',
              ),
            ),
            if (translationsOpen)
              for (final key in names.keys.where(
                (key) => key != activeLanguage,
              ))
                fields.text('Nom · ${_languageLabel(key)} ($key)', [
                  'names',
                  key,
                ]),
          ],
        ),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Détails techniques',
          children: [
            TextButton.icon(
              onPressed: () => setState(() => technicalOpen = !technicalOpen),
              icon: Icon(technicalOpen ? Icons.expand_less : Icons.expand_more),
              label: Text(
                technicalOpen
                    ? 'Masquer les identifiants'
                    : 'Afficher les identifiants',
              ),
            ),
            if (technicalOpen) ...[
              PokemonDataRow(label: 'Identifiant', value: draft.id),
              PokemonDataRow(label: 'Slug', value: '${json['slug'] ?? '—'}'),
              PokemonDataRow(
                label: 'Numéro national',
                value: '${json['nationalDex'] ?? '—'}',
              ),
            ],
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
        (json['abilities'] as Map?)?.cast<String, dynamic>() ?? {};
    final abilityNames =
        controller.index?.abilityNames ?? const <String, String>{};
    final right = Column(
      children: [
        PokemonBaseStats(
          stats: (json['baseStats'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Talents référencés',
          children: [
            if (abilities.values.whereType<String>().every((id) => id.isEmpty))
              const Text('Aucun talent renseigné.')
            else
              for (final entry in abilities.entries)
                if (entry.value is String && (entry.value as String).isNotEmpty)
                  PokemonDataRow(
                    label: _abilityRole(entry.key),
                    value: switch (abilityNames[entry.value]) {
                      null => '${entry.value} · libellé indisponible',
                      final name when name == entry.value =>
                        '$name · identifiant',
                      final name => '$name (${entry.value})',
                    },
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
        if (bounds.maxWidth < 760 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
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

  String _languageLabel(String key) => switch (key) {
    'fr' => 'Français (fr)',
    'en' => 'Anglais (en)',
    'de' => 'Allemand (de)',
    'es' => 'Espagnol (es)',
    'it' => 'Italien (it)',
    'ja' => 'Japonais (ja)',
    final other => other,
  };

  String _abilityRole(String key) => switch (key) {
    'primary' => 'Principal',
    'secondary' => 'Secondaire',
    'hidden' => 'Caché',
    final other => other,
  };

  void _setType(int position, String value) {
    widget.controller.edit(PokemonDocumentFamily.species, (json) {
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
