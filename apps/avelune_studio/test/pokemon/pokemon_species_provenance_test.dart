import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_species_provenance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

PokemonSpeciesDraft _draft(Map<String, dynamic>? meta) => PokemonSpeciesDraft(
  PokemonSpeciesBundle(
    species: PokemonDocumentSource(
      family: PokemonDocumentFamily.species,
      relativePath: 'data/pokemon/species/bayleef.json',
      bytes: const [],
      document: {
        'id': 'bayleef',
        'baseStats': {'hp': 60, 'atk': 62},
        'typing': {
          'types': ['grass'],
        },
        'sourceMeta': ?meta,
      },
    ),
    learnset: const PokemonDocumentSource(
      family: PokemonDocumentFamily.learnset,
      relativePath: 'data/pokemon/learnsets/bayleef.json',
      bytes: [],
      document: {'id': 'bayleef', 'levelUp': []},
    ),
    evolution: null,
    media: null,
  ),
);

void main() {
  test('the import source is named from the species metadata', () {
    String source(Map<String, dynamic>? meta) => pokemonSpeciesSource(
      _draft(meta).document(PokemonDocumentFamily.species)!,
    );
    expect(source(null), startsWith('Créée dans le projet'));
    expect(
      source({'seededBy': 'pokemon_sdk_studio'}),
      'Importée de Pokémon SDK',
    );
    expect(source({'seededBy': 'showdown'}), 'Importée de Showdown');
    expect(source({'seededBy': 'external_api'}), 'Complétée par PokéAPI');
    expect(
      source({'seededBy': 'heartgold-fr-rom:chapter7-personal-learnset'}),
      'Graine du projet « heartgold-fr-rom:chapter7-personal-learnset »',
    );
  });

  test('pending corrections name the edited sections only', () {
    final draft = _draft({'seededBy': 'showdown', 'seedVersion': 1});
    expect(pokemonDraftCorrections(draft), isEmpty);
    draft.edit(PokemonDocumentFamily.species, (json) {
      json['baseStats'] = {'hp': 70, 'atk': 62};
    });
    draft.edit(PokemonDocumentFamily.learnset, (json) {
      json['levelUp'] = [
        {'level': 1, 'moveId': 'tackle'},
      ];
    });
    expect(pokemonDraftCorrections(draft), [
      'Statistiques de base',
      'Attaques apprises',
    ]);
    draft.undo();
    draft.undo();
    expect(pokemonDraftCorrections(draft), isEmpty);
  });

  test('the scope names the tables and trainers a change reaches', () {
    expect(pokemonSpeciesScope('bayleef', null), startsWith('Inconnue'));
    final project = ProjectManifest(
      name: 'Portée',
      maps: const [],
      tilesets: const [],
      encounterTables: [
        ProjectEncounterTable(
          id: 'route-29',
          name: 'Route 29',
          encounterKind: EncounterKind.values.first,
          entries: const [
            ProjectEncounterEntry(
              speciesId: 'bayleef',
              minLevel: 3,
              maxLevel: 5,
            ),
          ],
        ),
        ProjectEncounterTable(
          id: 'cave',
          name: 'Grotte',
          encounterKind: EncounterKind.values.first,
          entries: const [
            ProjectEncounterEntry(speciesId: 'zubat', minLevel: 3, maxLevel: 5),
          ],
        ),
      ],
      trainers: [
        ProjectTrainerEntry(
          id: 'rival',
          name: 'Rival',
          trainerClass: 'Rival',
          team: const [
            ProjectTrainerPokemonEntry(speciesId: 'bayleef', level: 16),
          ],
        ),
      ],
    );
    expect(
      pokemonSpeciesScope('bayleef', project),
      'Une modification s’applique partout où elle est utilisée · '
      '1 table de rencontre (Route 29) · 1 dresseur (Rival)',
    );
    expect(
      pokemonSpeciesScope('chikorita', project),
      'Aucune table de rencontre ni équipe de dresseur ne l’utilise.',
    );
  });
}
