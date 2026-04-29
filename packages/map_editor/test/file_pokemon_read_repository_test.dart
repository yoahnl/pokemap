import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/application/use_cases/load_pokedex_species_detail_use_case.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late FilePokemonReadRepository repository;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_repo_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    repository = const FilePokemonReadRepository();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('FilePokemonReadRepository', () {
    test('reads from the workspace project and not the monorepo root',
        () async {
      await seedUseCase.execute(workspace);

      final decoy =
          await Directory.systemTemp.createTemp('pokemon_repo_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(
              decoy.path, 'data', 'pokemon', 'species', '0003-venusaur.json'),
        ).writeAsString('''
{
  "id": "venusaur",
  "nationalDex": 3,
  "names": {"en": "Venusaur"},
  "typing": {"types": ["grass", "poison"]}
}
''');

        Directory.current = decoy.path;

        final entries = await repository.listSpeciesIndexEntries(workspace);
        final species =
            await repository.readSpeciesById(workspace, 'bulbasaur');

        expect(entries.map((entry) => entry.id), isNot(contains('venusaur')));
        expect(species.id, 'bulbasaur');
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('reads the seeded pokemon files through the repository abstraction',
        () async {
      await seedUseCase.execute(workspace);

      final manifest = await repository.readManifest(workspace);
      final species = await repository.readSpeciesById(workspace, 'bulbasaur');
      final learnset =
          await repository.readLearnsetById(workspace, 'bulbasaur');
      final evolution =
          await repository.readEvolutionById(workspace, 'bulbasaur');
      final media = await repository.readMediaById(workspace, 'bulbasaur');
      final moves = await repository.readCatalogByKey(workspace, 'moves');

      expect(manifest.kind, 'pokemon_data_manifest');
      expect(species.id, 'bulbasaur');
      expect(learnset.speciesId, 'bulbasaur');
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(media.speciesId, 'bulbasaur');
      expect(media.variants['base']?.cry, 'assets/pokemon/cries/bulbasaur.ogg');
      expect(
        moves.entries.map((entry) => entry['id']),
        containsAll(<String>['tackle', 'growl', 'vine_whip', 'razor_leaf']),
      );
    });

    test(
        'loads species detail and move catalog from project.json-configured paths without pokemon_data_manifest.json',
        () async {
      final customProject = _buildConfiguredPokemonProject();
      await _writeProjectJson(workspace, customProject.toJson());
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/species/0001-bulbasaur.json',
        '''
{
  "id": "bulbasaur",
  "slug": "bulbasaur",
  "nationalDex": 1,
  "names": {"en": "Bulbasaur"},
  "speciesName": {"en": "Seed Pokemon"},
  "genIntroduced": 1,
  "typing": {
    "types": ["grass", "poison"]
  },
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45,
    "bst": 318
  },
  "abilities": {"primary": "overgrow"},
  "breeding": {
    "genderRatio": {"male": 0.875, "female": 0.125},
    "eggGroups": ["monster", "grass"],
    "hatchCycles": 20
  },
  "progression": {
    "growthRateId": "medium_slow",
    "baseExp": 64,
    "catchRate": 45,
    "baseFriendship": 50
  },
  "forms": {
    "baseFormId": "bulbasaur",
    "isBaseForm": true,
    "formId": "base",
    "otherForms": ["blossom"]
  },
  "classification": {
    "isEnabledInProject": true,
    "isObtainable": true
  },
  "refs": {
    "learnset": "bulbasaur",
    "evolution": "bulbasaur",
    "media": "bulbasaur"
  },
  "dexContent": {
    "heightM": 0.7,
    "weightKg": 6.9,
    "color": "green",
    "flavorText": "A strange seed was planted on its back at birth."
  },
  "gameplayFlags": {"starterEligible": true},
  "sourceMeta": {"seededBy": "test", "seedVersion": 1}
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/learnsets/bulbasaur.json',
        '''
{
  "speciesId": "bulbasaur",
  "startingMoves": ["tackle"],
  "relearnMoves": ["growl"],
  "levelUp": [
    {
      "moveId": "vine_whip",
      "level": 7,
      "source": "level_up",
      "versionGroup": "project"
    },
    {
      "moveId": "razor_leaf",
      "level": 20,
      "source": "level_up",
      "versionGroup": "project"
    }
  ]
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/evolutions/bulbasaur.json',
        '''
{
  "speciesId": "bulbasaur",
  "evolutions": []
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/media/bulbasaur.json',
        '''
{
  "speciesId": "bulbasaur",
  "defaultFormId": "base",
  "variants": {}
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/catalogs/moves.json',
        '''
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "moves",
  "meta": {
    "description": "Local move catalog."
  },
  "entries": [
    {
      "id": "tackle",
      "name": "Tackle",
      "type": "normal",
      "category": "physical",
      "power": 40,
      "pp": 35
    },
    {
      "id": "growl",
      "name": "Growl",
      "type": "normal",
      "category": "status",
      "pp": 40
    },
    {
      "id": "vine_whip",
      "name": "Vine Whip",
      "type": "grass",
      "category": "physical",
      "power": 45,
      "pp": 25
    }
  ]
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/catalogs/items.json',
        '''
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "items",
  "meta": {
    "description": "Local item catalog."
  },
  "entries": [
    {
      "id": "oran_berry",
      "name": "Oran Berry",
      "aliases": ["oran"]
    }
  ]
}
''',
      );

      final detailLoader = LoadPokedexSpeciesDetailUseCase(repository);
      final movesLoader = LoadPokemonMovesCatalogUseCase(
        readRepository: repository,
      );
      final itemsLoader = LoadPokemonItemsCatalogUseCase(
        readRepository: repository,
      );

      final detail = await detailLoader.execute(workspace, 'bulbasaur');
      final movesCatalog = await movesLoader.execute(workspace);
      final itemsCatalog = await itemsLoader.execute(workspace);

      expect(detail.species.id, 'bulbasaur');
      expect(detail.learnset, isNotNull);
      expect(
        detail.learnset!.levelUp.map((entry) => entry.moveId),
        containsAll(<String>['vine_whip', 'razor_leaf']),
      );
      expect(movesCatalog.isAvailable, isTrue);
      expect(
        movesCatalog.entries.map((entry) => entry.id),
        containsAll(<String>['tackle', 'growl', 'vine_whip']),
      );
      expect(itemsCatalog.isAvailable, isTrue);
      expect(
        itemsCatalog.entries.map((entry) => entry.id),
        contains('oran_berry'),
      );
    });

    test('throws explicit error when a species file is missing', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => repository.readSpeciesById(workspace, 'venusaur'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species not found'),
          ),
        ),
      );
    });

    test('throws explicit error when a species json file is invalid', () async {
      await seedUseCase.execute(workspace);

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      await speciesFile.writeAsString('{ invalid json');

      expect(
        () => repository.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
          'Pokemon Repo Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await repository.readSpeciesById(workspace, 'bulbasaur');
      await repository.readCatalogByKey(workspace, 'moves');

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('does not recreate data or assets at the monorepo root', () async {
      await seedUseCase.execute(workspace);

      await repository.listSpeciesIndexEntries(workspace);

      expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
      expect(Directory(p.join(repoRootPath, 'assets')).existsSync(), isFalse);
    });
  });
}

String _resolveRepositoryRootFromCurrentDirectory() {
  var current = Directory.current.absolute;

  while (true) {
    final agentsFile = File(p.join(current.path, 'AGENTS.md'));
    final mapEditorDir =
        Directory(p.join(current.path, 'packages', 'map_editor'));
    if (agentsFile.existsSync() && mapEditorDir.existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not resolve repository root from Directory.current: '
        '${Directory.current.path}',
      );
    }
    current = parent;
  }
}

const ProjectManifest _configuredPokemonProject = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
  name: 'Configured Pokemon Project',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  pokemon: ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
      'items': 'custom/pokemon/catalogs/items.json',
    },
  ),
);

ProjectManifest _buildConfiguredPokemonProject() => _configuredPokemonProject;

Future<void> _writeProjectJson(
  ProjectFileSystem workspace,
  Map<String, dynamic> json,
) async {
  await _writeProjectRelativeTextFile(
    workspace,
    'project.json',
    const JsonEncoder.withIndent('  ').convert(json),
  );
}

Future<void> _writeProjectRelativeTextFile(
  ProjectFileSystem workspace,
  String relativePath,
  String contents,
) async {
  final file = File(workspace.resolveProjectRelativePath(relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}
