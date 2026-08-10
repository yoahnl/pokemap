import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

const encounterStudioFixtureProject = ProjectManifest(
  name: 'Encounter Studio certification',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  encounterTables: <ProjectEncounterTable>[
    ProjectEncounterTable(
      id: 'route_1_grass',
      name: 'Route 1 — Hautes herbes',
      encounterKind: EncounterKind.walk,
      chancePerStep: 0.12,
      tags: <String>['extérieur', 'début'],
      entries: <ProjectEncounterEntry>[
        ProjectEncounterEntry(
          speciesId: 'pidgey',
          minLevel: 2,
          maxLevel: 5,
          weight: 40,
        ),
        ProjectEncounterEntry(
          speciesId: 'rattata',
          minLevel: 2,
          maxLevel: 4,
          weight: 35,
        ),
        ProjectEncounterEntry(
          speciesId: 'caterpie',
          minLevel: 3,
          maxLevel: 5,
          weight: 25,
        ),
        ProjectEncounterEntry(
          speciesId: 'weedle',
          minLevel: 3,
          maxLevel: 5,
          weight: 8,
        ),
        ProjectEncounterEntry(
          speciesId: 'pikachu',
          minLevel: 3,
          maxLevel: 5,
          weight: 2,
        ),
      ],
    ),
    ProjectEncounterTable(
      id: 'route_1_surf',
      name: 'Route 1 — Surf',
      encounterKind: EncounterKind.surf,
      chancePerStep: 0.08,
      entries: <ProjectEncounterEntry>[
        ProjectEncounterEntry(
          speciesId: 'magikarp',
          minLevel: 5,
          maxLevel: 8,
          weight: 70,
        ),
        ProjectEncounterEntry(
          speciesId: 'tentacool',
          minLevel: 6,
          maxLevel: 9,
          weight: 30,
        ),
      ],
    ),
  ],
);

const encounterStudioFixtureState = EditorState(
  projectRootPath: '/tmp/encounter-studio-phase-3',
  project: encounterStudioFixtureProject,
  workspaceMode: EditorWorkspaceMode.encounter,
  encounterStudioTableId: 'route_1_grass',
);

const encounterStudioFixtureSpecies = <PokemonDatabaseIndexEntry>[
  PokemonDatabaseIndexEntry(
    id: 'pidgey',
    nationalDex: 16,
    primaryName: 'Roucool',
    genIntroduced: 1,
    types: <String>['normal', 'flying'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'pidgey',
      evolution: 'pidgey',
      media: 'pidgey',
    ),
  ),
  PokemonDatabaseIndexEntry(
    id: 'rattata',
    nationalDex: 19,
    primaryName: 'Rattata',
    genIntroduced: 1,
    types: <String>['normal'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'rattata',
      evolution: 'rattata',
      media: 'rattata',
    ),
  ),
  PokemonDatabaseIndexEntry(
    id: 'caterpie',
    nationalDex: 10,
    primaryName: 'Chenipan',
    genIntroduced: 1,
    types: <String>['bug'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'caterpie',
      evolution: 'caterpie',
      media: 'caterpie',
    ),
  ),
  PokemonDatabaseIndexEntry(
    id: 'weedle',
    nationalDex: 13,
    primaryName: 'Aspicot',
    genIntroduced: 1,
    types: <String>['bug', 'poison'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'weedle',
      evolution: 'weedle',
      media: 'weedle',
    ),
  ),
  PokemonDatabaseIndexEntry(
    id: 'pikachu',
    nationalDex: 25,
    primaryName: 'Pikachu',
    genIntroduced: 1,
    types: <String>['electric'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'pikachu',
      evolution: 'pikachu',
      media: 'pikachu',
    ),
  ),
  PokemonDatabaseIndexEntry(
    id: 'magikarp',
    nationalDex: 129,
    primaryName: 'Magicarpe',
    genIntroduced: 1,
    types: <String>['water'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'magikarp',
      evolution: 'magikarp',
      media: 'magikarp',
    ),
  ),
  PokemonDatabaseIndexEntry(
    id: 'tentacool',
    nationalDex: 72,
    primaryName: 'Tentacool',
    genIntroduced: 1,
    types: <String>['water', 'poison'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'tentacool',
      evolution: 'tentacool',
      media: 'tentacool',
    ),
  ),
];
