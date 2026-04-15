import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late InitializePokemonProjectStorageUseCase useCase;
  late ProjectFileSystem workspace;
  late LoadPokemonMovesCatalogUseCase loadMovesCatalogUseCase;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('pokemon_project_storage_');
    useCase = const InitializePokemonProjectStorageUseCase();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    loadMovesCatalogUseCase = const LoadPokemonMovesCatalogUseCase(
      readRepository: FilePokemonReadRepository(),
    );
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('InitializePokemonProjectStorageUseCase', () {
    test('creates the expected structure inside the project workspace',
        () async {
      await useCase.execute(workspace);

      for (final relativeDir in _expectedDirectories) {
        final dir =
            Directory(workspace.resolveProjectRelativePath(relativeDir));
        expect(
          await dir.exists(),
          isTrue,
          reason: 'Missing directory $relativeDir in project workspace',
        );
      }

      for (final relativeFile in _expectedFiles) {
        final file = File(
          workspace.resolveProjectRelativePath(relativeFile),
        );
        expect(
          await file.exists(),
          isTrue,
          reason: 'Missing file $relativeFile in project workspace',
        );
      }

      // Garde-fou important pour ce lot : seules les metadonnees JSON passent
      // par `data/pokemon/...`. Il ne faut pas recreer les anciens chemins
      // ambigus ou errones sous `data/pokemon/`.
      expect(
        await Directory(
          workspace.resolveProjectRelativePath('data/pokemon/cries'),
        ).exists(),
        isFalse,
      );
      expect(
        await Directory(
          workspace.resolveProjectRelativePath('data/pokemon/media'),
        ).exists(),
        isTrue,
      );
    });

    test(
        'writes only inside workspace projectRoot and not from cwd-relative paths',
        () async {
      final cwd = Directory.current.path;
      final cwdManifest = File(
        p.join(cwd, 'data', 'pokemon', 'pokemon_data_manifest.json'),
      );
      final cwdSprites = Directory(
        p.join(cwd, 'assets', 'pokemon', 'sprites'),
      );

      expect(
        p.equals(workspace.projectRoot, cwd),
        isFalse,
        reason: 'Test workspace must differ from cwd to validate confinement.',
      );
      expect(await cwdManifest.exists(), isFalse);
      expect(await cwdSprites.exists(), isFalse);

      await useCase.execute(workspace);

      expect(await cwdManifest.exists(), isFalse);
      expect(await cwdSprites.exists(), isFalse);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/pokemon_data_manifest.json',
          ),
        ).exists(),
        isTrue,
      );
    });

    test('creates valid json payloads with the expected schema', () async {
      await useCase.execute(workspace);

      final manifest = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/pokemon_data_manifest.json',
        ),
      );
      expect(manifest['schemaVersion'], 1);
      expect(manifest['kind'], 'pokemon_data_manifest');
      expect(manifest['meta'], <String, Object?>{
        'description':
            'Root manifest for the local Pokemon data stored inside a project workspace.',
        'notes': <Object?>[],
      });
      expect(manifest['futureDataFolders'], <String, Object?>{
        'species': 'species/',
        'learnsets': 'learnsets/',
        'evolutions': 'evolutions/',
        'media': 'media/',
      });

      final catalogFiles = manifest['catalogFiles'] as Map<String, dynamic>;
      expect(
          catalogFiles.keys,
          containsAll(<String>[
            'moves',
            'abilities',
            'items',
            'types',
            'growth_rates',
            'natures',
            'egg_groups',
            'habitats',
            'generations',
            'version_groups',
            'encounter_rules',
          ]));

      for (final entry in _expectedCatalogs.entries) {
        final catalog = await _readJsonMap(
          workspace.resolveProjectRelativePath(entry.value),
        );
        expect(catalog['schemaVersion'], 1);
        expect(catalog['kind'], 'pokemon_catalog');
        expect(catalog['catalog'], entry.key);
        if (entry.key == 'moves') {
          expect(catalog['meta'], <String, Object?>{
            'description': _expectedCatalogDescriptions[entry.key]!,
            'sourcePriority': <Object?>['internal'],
            'notes': <Object?>[
              'Embedded canonical move seed shipped with map_editor for offline bootstrap.',
              'Curated from Showdown-backed move data and versioned in the repository.',
              'bootstrap_seed_version:1',
            ],
          });
          expect(catalog['entries'], isNotEmpty);
        } else {
          expect(catalog['meta'], <String, Object?>{
            'description': _expectedCatalogDescriptions[entry.key]!,
            'sourcePriority': <Object?>['internal'],
            'notes': <Object?>[],
          });
          expect(catalog['entries'], isEmpty);
        }
      }
    });

    test('writes a canonical non-empty moves seed without legacy dead fields',
        () async {
      await useCase.execute(workspace);

      final catalog = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/moves.json',
        ),
      );
      final entries = (catalog['entries'] as List<dynamic>)
          .cast<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);

      expect(entries, isNotEmpty);

      for (final entry in entries) {
        expect(() => PokemonMove.fromJson(entry), returnsNormally);
        expect(entry.containsKey('power'), isFalse);
        expect(entry.containsKey('accuracyText'), isFalse);
        expect(entry.containsKey('shortDesc'), isFalse);
      }

      expect(
        entries.map((entry) => entry['id']),
        containsAll(<String>[
          'tackle',
          'growl',
          'vine_whip',
          'razor_leaf',
          'thunderbolt',
          'trick_room',
        ]),
      );
    });

    test('keeps enriched contract absent from the monorepo root', () async {
      await useCase.execute(workspace);

      final rootManifest = File(
        p.join(Directory.current.path, 'data', 'pokemon',
            'pokemon_data_manifest.json'),
      );
      final rootMoves = File(
        p.join(
          Directory.current.path,
          'data',
          'pokemon',
          'catalogs',
          'moves.json',
        ),
      );

      expect(await rootManifest.exists(), isFalse);
      expect(await rootMoves.exists(), isFalse);
    });

    test('is idempotent and never overwrites an existing json file', () async {
      await useCase.execute(workspace);

      final movesPath = workspace.resolveProjectRelativePath(
        'data/pokemon/catalogs/moves.json',
      );
      final file = File(movesPath);
      const customPayload = '{\n  "kept": true\n}';
      await file.writeAsString(customPayload);

      await useCase.execute(workspace);

      expect(await file.readAsString(), customPayload);
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
          'Pokemon Workspace Test', tempProjectRoot.path);

      final manifestFile = File(workspace.projectManifestPath);
      final before = await manifestFile.readAsString();

      await useCase.execute(workspace);

      final after = await manifestFile.readAsString();
      expect(after, before);
    });

    test('bootstrapped moves seed is readable by the existing local loader',
        () async {
      await useCase.execute(workspace);

      final result = await loadMovesCatalogUseCase.execute(workspace);

      expect(result.isAvailable, isTrue);
      expect(result.entries, isNotEmpty);
      expect(
        result.entries.map((entry) => entry.id),
        containsAll(<String>[
          'tackle',
          'growl',
          'vine_whip',
          'razor_leaf',
        ]),
      );
    });

    test('does not run automatically when a project is created', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );

      await createProjectUseCase.execute(
          'Manual Pokemon Bootstrap', tempProjectRoot.path);

      expect(
        await Directory(
          workspace.resolveProjectRelativePath('data/pokemon'),
        ).exists(),
        isFalse,
      );
      expect(
        await Directory(
          workspace.resolveProjectRelativePath('assets/pokemon'),
        ).exists(),
        isFalse,
      );

      await useCase.execute(workspace);

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/pokemon_data_manifest.json',
          ),
        ).exists(),
        isTrue,
      );
    });
  });
}

const List<String> _expectedDirectories = <String>[
  'data/pokemon/species',
  'data/pokemon/learnsets',
  'data/pokemon/evolutions',
  'data/pokemon/media',
  'data/pokemon/catalogs',
  'assets/pokemon/sprites',
  'assets/pokemon/cries',
  'assets/pokemon/portraits',
];

const List<String> _expectedFiles = <String>[
  'data/pokemon/pokemon_data_manifest.json',
  'data/pokemon/catalogs/moves.json',
  'data/pokemon/catalogs/abilities.json',
  'data/pokemon/catalogs/items.json',
  'data/pokemon/catalogs/types.json',
  'data/pokemon/catalogs/growth_rates.json',
  'data/pokemon/catalogs/natures.json',
  'data/pokemon/catalogs/egg_groups.json',
  'data/pokemon/catalogs/habitats.json',
  'data/pokemon/catalogs/generations.json',
  'data/pokemon/catalogs/version_groups.json',
  'data/pokemon/catalogs/encounter_rules.json',
];

const Map<String, String> _expectedCatalogs = <String, String>{
  'moves': 'data/pokemon/catalogs/moves.json',
  'abilities': 'data/pokemon/catalogs/abilities.json',
  'items': 'data/pokemon/catalogs/items.json',
  'types': 'data/pokemon/catalogs/types.json',
  'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
  'natures': 'data/pokemon/catalogs/natures.json',
  'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
  'habitats': 'data/pokemon/catalogs/habitats.json',
  'generations': 'data/pokemon/catalogs/generations.json',
  'version_groups': 'data/pokemon/catalogs/version_groups.json',
  'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
};

const Map<String, String> _expectedCatalogDescriptions = <String, String>{
  'moves': 'Move catalog for the local Pokemon project database.',
  'abilities': 'Ability catalog for the local Pokemon project database.',
  'items': 'Item catalog for the local Pokemon project database.',
  'types': 'Type catalog for the local Pokemon project database.',
  'growth_rates': 'Growth rate catalog for the local Pokemon project database.',
  'natures': 'Nature catalog for the local Pokemon project database.',
  'egg_groups': 'Egg group catalog for the local Pokemon project database.',
  'habitats': 'Habitat catalog for the local Pokemon project database.',
  'generations': 'Generation catalog for the local Pokemon project database.',
  'version_groups':
      'Version group catalog for the local Pokemon project database.',
  'encounter_rules':
      'Encounter rule catalog for the local Pokemon project database.',
};

Future<Map<String, dynamic>> _readJsonMap(String path) async {
  final raw = await File(path).readAsString();
  return jsonDecode(raw) as Map<String, dynamic>;
}
