import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_ui_parts.dart';

String pokemonSpeciesSource(Map<String, dynamic> species) {
  final meta = (species['sourceMeta'] as Map?)?.cast<String, dynamic>() ?? {};
  final seededBy = (meta['seededBy'] as String?)?.trim();
  return switch (seededBy) {
    null || '' => 'Créée dans le projet, sans source d’import enregistrée',
    'pokemon_sdk_studio' => 'Importée de Pokémon SDK',
    'showdown' => 'Importée de Showdown',
    'external_api' => 'Complétée par PokéAPI',
    final other => 'Graine du projet « $other »',
  };
}

const _sections = {
  'abilities': 'Talents',
  'baseStats': 'Statistiques de base',
  'breeding': 'Reproduction',
  'classification': 'Classification',
  'dexContent': 'Pokédex',
  'forms': 'Formes',
  'gameplayFlags': 'Présence dans le jeu',
  'genIntroduced': 'Génération',
  'names': 'Noms',
  'nationalDex': 'Numéro national',
  'progression': 'Progression',
  'refs': 'Liens de documents',
  'slug': 'Slug',
  'sourceMeta': 'Provenance',
  'speciesName': 'Nom',
  'typing': 'Types',
};

List<String> pokemonDraftCorrections(PokemonSpeciesDraft draft) {
  final species = draft.document(PokemonDocumentFamily.species) ?? const {};
  final saved =
      draft.base.source(PokemonDocumentFamily.species)?.document ?? const {};
  return [
    for (final key in {...saved.keys, ...species.keys})
      if (jsonEncode(saved[key]) != jsonEncode(species[key]))
        _sections[key] ?? key,
    for (final family in draft.changedFamilies)
      ?switch (family) {
        PokemonDocumentFamily.species => null,
        PokemonDocumentFamily.learnset => 'Attaques apprises',
        PokemonDocumentFamily.evolution => 'Évolutions',
        PokemonDocumentFamily.media => 'Médias',
      },
  ];
}

String pokemonSpeciesScope(String speciesId, ProjectManifest? project) {
  if (project == null) {
    return 'Inconnue tant que les combats ne sont pas chargés : ouvrez Combats '
        'pour voir les tables et dresseurs concernés.';
  }
  String names(List<String> values) => values.length <= 3
      ? values.join(', ')
      : '${values.take(3).join(', ')} et ${values.length - 3} autres';
  final tables = [
    for (final table in project.encounterTables)
      if (table.allEntries.any((entry) => entry.speciesId == speciesId))
        table.name,
  ];
  final trainers = [
    for (final trainer in project.trainers)
      if (trainer.team.any((member) => member.speciesId == speciesId))
        trainer.name,
  ];
  if (tables.isEmpty && trainers.isEmpty) {
    return 'Aucune table de rencontre ni équipe de dresseur ne l’utilise.';
  }
  return [
    'Une modification s’applique partout où elle est utilisée',
    if (tables.isNotEmpty)
      '${tables.length} ${tables.length == 1 ? 'table' : 'tables'} de '
          'rencontre (${names(tables)})',
    if (trainers.isNotEmpty)
      '${trainers.length} ${trainers.length == 1 ? 'dresseur' : 'dresseurs'} '
          '(${names(trainers)})',
  ].join(' · ');
}

class PokemonSpeciesProvenance extends StatelessWidget {
  const PokemonSpeciesProvenance({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final draft = controller.selectedDraft!;
    final species = draft.document(PokemonDocumentFamily.species) ?? const {};
    final version = ((species['sourceMeta'] as Map?)?['seedVersion'] as num?)
        ?.toString();
    final corrections = pokemonDraftCorrections(draft);
    return StudioPanel(
      key: const ValueKey('pokemon-species-provenance'),
      title: 'Provenance et portée',
      children: [
        PokemonDataRow(label: 'Source', value: pokemonSpeciesSource(species)),
        if (version != null)
          PokemonDataRow(label: 'Version de la source', value: version),
        PokemonDataRow(
          label: 'Corrections en attente',
          value: corrections.isEmpty
              ? 'Aucune'
              : corrections.toSet().join(', '),
        ),
        PokemonDataRow(
          label: 'Portée',
          value: pokemonSpeciesScope(
            draft.id,
            controller.combat?.snapshot?.project,
          ),
        ),
        Text(
          'Une correction enregistrée remplace la valeur importée dans les '
          'données du projet. La version importée d’origine n’est pas '
          'conservée : les champs corrigés auparavant ne sont pas listés.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
