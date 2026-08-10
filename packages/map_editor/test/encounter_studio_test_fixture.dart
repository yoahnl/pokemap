import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:path/path.dart' as p;

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
    thumbnailRelativePath: 'assets/pokemon/sprites/pidgey/front.png',
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
    thumbnailRelativePath: 'assets/pokemon/sprites/rattata/front.png',
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
    thumbnailRelativePath: 'assets/pokemon/sprites/caterpie/front.png',
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
    thumbnailRelativePath: 'assets/pokemon/sprites/weedle/front.png',
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
    thumbnailRelativePath: 'assets/pokemon/sprites/pikachu/front.png',
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

Future<String> createEncounterStudioVisualProjectRoot() async {
  final projectRoot = await Directory.systemTemp.createTemp(
    'encounter_studio_visual_',
  );
  for (final entry in _encounterStudioSpriteBytes.entries) {
    final file = File(
      p.join(projectRoot.path, 'assets/pokemon/sprites/${entry.key}/front.png'),
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(base64Decode(entry.value));
  }
  return projectRoot.path;
}

const _encounterStudioSpriteBytes = <String, String>{
  'pidgey':
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgBAMAAAAQtmoLAAAALVBMVEUAAAAQEBBBKRhzSjGDg4OkYlq9KSC9vb3Ng1rmvWLuYkH/rHP/7pz/9r3///9WNuoZAAAAAXRSTlMAQObYZgAAAa5JREFUWMPt1LFKA0EQBuCLh9buaUAbSTZc1CBBPIQE4isIWRmIRZqgB2onvoAegQ3YeEHIQBqbFIe1jZWCkIPtbLSwEKx9BvcI1jdrYbV/vR+zs8Os49jY2NjY/CXutiFoGIJABiZi3pWRNAHdhpRGJTSIgo+YfqNXGe19vHED0O++I2KJChaODxHLjF7h7OGYeR6Qm154TO7qa55PB0kyEXWPt8mA1yYpcjpwqr2aUjGHRSqohSca+NCmirnkXqUcQF5RJ8G3FPrQkVIQhYt4qwtI2RcGoJMBKFEBwoYGAkpuQNhWDcYvflbA5w3ZiHKFm47VM8h+H0QMQUde5oGWUhqALiDiA909FQCIzaddaLPcAbauf8E4LbZXIicfTFXqg9BAsSLkfyDN1nSsR61bUKoIkH8lt4mDYZy1oK6XGCNMbiUYNtEXehzTG9KoC3rUGJcRByMacFYzgQxHeEkDhZkorw6oSzQTcZmRF7tQQRyS/75sT3ussmNwnFd7+vegg/X9sFcNQ/KV5i6+vPppcnROrsBY4es7ZMygaWf50+i4ftdFx8bGxsbm3/IDKBea6AbhhdgAAAAASUVORK5CYII=',
  'rattata':
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgBAMAAAAQtmoLAAAAMFBMVEUAAAAQEBBKKUFaWlpiSgiLSoukGDmkcwi0c73NrGLNzc3VnNXmWnPmzXPu3rT///9wkIOdAAAAAXRSTlMAQObYZgAAAbNJREFUWMPtlDFLw0AYhi+hoeKUgFILUmohUuyvEDLYpWjpYUD7DxxUKNGl2MDhJ51akCpIwc1NLAiB+wHdhY4dCopkuaXgWi/pD7g70KXcO9wReB/u3sv3fQhpaWlp/ZUA1PxrlGIloEsxHKoB1A9VAItGhBRVCBdCUALMkqsGcPmd/wasFQDKyoAttOBlvcGNJGBRsiztd0nArKQl3R2lm3kkfpZLqJdKZXpclgU+wgql0ShoJa3gijOjJvfTLpm2QgsfygIRkOmk4wMR3yhAJnA/QHPS4au4Q2vnJvcRF4ifAOL+yXz53Lb7wpctKQAl/vBnATtO4oe6EDjhAU7PFnAbBFccEKf2CQwZi4M2Y58g80zWHVvK8w6kgAxj+3l+gpdGwGIAed7cGbI4sfsEY/GvXl/MnRqLSTcq97EMgF7nTpXFm5TmH0tY5k57z9tjNuMVlfeQi3vigYobT2NmV+ibh5AxEAMubgzaM8QB/pGvXgiBHK5XmW1SmgyYjZwwtHF9XzQcZNIosRqG8ACj10+27APYkqPLTo3tWG3kZb+ZrQQYhYIaIJNWS0tLS2uV9QujEKugSNyd7gAAAABJRU5ErkJggg==',
  'caterpie':
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgBAMAAAAQtmoLAAAAMFBMVEUAAAAAAAAYWkEge0oxrEFKxSlSYkpq1TF7OUp7g0qs9kHmzZT27ov/QUH/e0H/tDlsaQRjAAAAAXRSTlMAQObYZgAAAbZJREFUGBntwbFrE2EYB+DfJXAk232mg5IMsU3p0CXWQAanu7xQ6I0iXRxSlYI0i8XjA6fg4i1FRRAkWZwKNzUmBI43SwcDId/SLcu1q5OzU7T/wb0OOn3PA8uyLMv6N+I+bsV9CJXe/wIQ/15BqHSz7hc2b9ZXECplP9/uxOvsClJn1z/i6yy7U4eQc5Zl2UrpDqTuZtlKaa2bkCm8ylZKR08OH0Om8DV+p/VT8z2AzE4SHyTR8mhGHkS23ySJjuZHNfIgsk10qKNLVSUPIsXkvKOjVA3Ig0g7OddtHfIkgEw72Io6ERH5kNnbf90K6FalDhFH60bQIvKpDpQ/IF9lk+5XyG/snwLDFAJKfVJqg8wpymaBfO6AOVWtUF/CNXPk6y2YeUyhHsGdTZGvly45fUnEHlzuIl81NcvhlIg8uNxFPufecG5GRD7gTiFRW3zmUcv3gHIXEq4xqupXPeBRFxK9oWGmyQWK1IREbcB8/CLc2GuFTUhUU57O5v7DsDGGiKO+fDSj3cbkWwcyjjGqQkEYeBCqMT+ngMaQck6mTAF7EHNPmHcf4C8Uj59twbIsy/o//gARmZNQERHLaQAAAABJRU5ErkJggg==',
  'weedle':
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgBAMAAAAQtmoLAAAALVBMVEUAAAAYGBhaWmJqOQiLi5SUWgicKSDFxcXNcxDeWlLunIvurEH/3s3/5nv////6NZQnAAAAAXRSTlMAQObYZgAAAVJJREFUWMPtk7FKw0AcxpPUimOuwXDZxFUohoKkLyEula4ihCSbk1shBsMfgoMIgZudCi4SCoF7FMlgcXDKM3jXvsCXQRC53/z9uHx3XyzLYDAYDP+Eg6HC5cmvC9uBwuprcTUk7/T92WaI8dD3ldzg+aN29S2lPIeFqqNKCQUsPHWdyssGzY9k96GFFv2m0afc0bqoMFFpJREsxLGUkwGCL4S+pBYWgrd1rQQitHQgRK0PyNFrtYWIVR4XLHYbkcLFx8R1PmxwwVYnMHrHhcNX5t3sOpyitXm55lqYgj83o1JwXXoKNg+JYv1uTn+HrUlVJmYNEQrG9DCce0y40O+wF7AOmRY8lR0vMCGIyqTgx+PZElys7WV1TvmymD2C12oHz5zyhqI5usBQ7S8vrn2GrilNyiTK0wCeuB9ltR8yhg+czV9SPL5XQtcyGAwGwx/lByg/eOn1qW2DAAAAAElFTkSuQmCC',
  'pikachu':
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgBAMAAAAQtmoLAAAAKlBMVEUAAAAAAAApKSlBQUpiMQhzc4OcUgDFIBjelADmWkH2vSD25lL/9qT////Vai+KAAAAAXRSTlMAQObYZgAAAdlJREFUWMPtlsFqwkAQhjclhB6ztRRReqiHXnoSbz0piLX2JcwliD6A0JsgEuoDlNJTQKzsnkJpSDN9A3PpG3U2ST12J4dCKftjNML/MTObndkwZmRkZPTX5Vb0Wxe/DrQq5nRSHehWBK4PQKtFAWpiU9wctTodygI0SsCZQqfTJgK+P3ZmgAClfltsJ9k+Qf8bKQACQZZlgHptqwC+lhh+ZNleAVz5HRjrAEwGUi4Tr/wX61JaSMzm8wrygo9BD5wjENVKYI3hNDnZbRiqlHJfAHrAuVQmeH9eqooJwB3AABN5egyL+rVF3MrldDtJ5/OwDKADbkSuHJAVgJf7kE1FTmg2lCNKheoOCa7froU2OSo5owLSHeG33s+aJQCuTfKzJhQBsNjRlpEAJHZSrY4tKBNkHeNSqk3XZXUKYEFSApH18D1BfgYAmwZ7CKJhsOsRgHUB7CAMgj5lGM9AIfgJ6wtGA2Ko45UK7lPmUjPGmRThlQr3zCMAM/BxhXz1MLhPAKyiBwCkEH2PkJIlCn+apiKklGDlPQBCYoSQdKBMxUG0o6hx8O9oh53VEAHnqndIj42x/kotpjWYrGgB7Djp5c6R8GgR+Gn5G0cVXwl41bcUIyMjo/+qLw92FGczGN4XAAAAAElFTkSuQmCC',
};
