import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_demo_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const SeedPokemonDemoDataUseCase();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('SeedPokemonDemoDataUseCase', () {
    test('creates the expected demo dataset inside the project workspace',
        () async {
      await useCase.execute(workspace);

      for (final relativePath in _expectedDatasetFiles) {
        expect(
          await File(workspace.resolveProjectRelativePath(relativePath))
              .exists(),
          isTrue,
          reason: 'Missing demo dataset file $relativePath',
        );
      }
    });

    test('creates nothing under the monorepo root', () async {
      await useCase.execute(workspace);

      for (final relativePath in _expectedRootLeakChecks) {
        expect(
          await File(p.join(Directory.current.path, relativePath)).exists(),
          isFalse,
          reason: 'Unexpected file leaked into monorepo root: $relativePath',
        );
      }
    });

    test('generated json files are valid and cross references stay coherent',
        () async {
      await useCase.execute(workspace);

      final bulbasaurSpecies = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final bulbasaurLearnset = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      );
      final bulbasaurEvolution = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur.json',
        ),
      );
      final ivysaurSpecies = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0002-ivysaur.json',
        ),
      );
      final bulbasaurMedia = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/media/bulbasaur.json',
        ),
      );
      final movesCatalog = await _readJsonMap(
        workspace
            .resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
      );
      final abilitiesCatalog = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/abilities.json',
        ),
      );
      final typesCatalog = await _readJsonMap(
        workspace
            .resolveProjectRelativePath('data/pokemon/catalogs/types.json'),
      );
      final growthRatesCatalog = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/growth_rates.json',
        ),
      );

      expect(
        (bulbasaurSpecies['refs'] as Map<String, dynamic>)['learnset'],
        'bulbasaur',
      );
      expect(bulbasaurLearnset['speciesId'], 'bulbasaur');
      expect(
        (bulbasaurSpecies['refs'] as Map<String, dynamic>)['evolution'],
        'bulbasaur',
      );
      expect(bulbasaurEvolution['speciesId'], 'bulbasaur');
      expect(
        (ivysaurSpecies['refs'] as Map<String, dynamic>)['evolution'],
        'ivysaur',
      );
      expect(
        (ivysaurSpecies['refs'] as Map<String, dynamic>)['learnset'],
        'ivysaur',
      );
      expect(
        (bulbasaurSpecies['refs'] as Map<String, dynamic>)['media'],
        'bulbasaur',
      );
      expect(bulbasaurMedia['speciesId'], 'bulbasaur');
      expect(bulbasaurMedia['defaultFormId'], 'base');
      expect(
        (bulbasaurMedia['variants'] as Map<String, dynamic>)
            .containsKey('base'),
        isTrue,
      );

      final levelUp = bulbasaurLearnset['levelUp'] as List<dynamic>;
      expect(levelUp, isNotEmpty);
      expect(levelUp.first, containsPair('moveId', 'tackle'));
      expect(levelUp.first, contains('level'));
      expect(levelUp.first, containsPair('source', 'level_up'));
      expect(levelUp.first, containsPair('versionGroup', 'demo'));
      expect((bulbasaurLearnset['tm'] as List<dynamic>).first,
          containsPair('moveId', 'growl'));

      expect(
        (movesCatalog['entries'] as List<dynamic>).map((e) => e['id']).toSet(),
        containsAll(<String>{'tackle', 'growl', 'vine_whip', 'razor_leaf'}),
      );
      expect(
        (abilitiesCatalog['entries'] as List<dynamic>)
            .map((e) => e['id'])
            .toSet(),
        containsAll(<String>{'overgrow', 'chlorophyll'}),
      );
      expect(
        (typesCatalog['entries'] as List<dynamic>).map((e) => e['id']).toSet(),
        containsAll(<String>{'grass', 'poison'}),
      );
      expect(
        (growthRatesCatalog['entries'] as List<dynamic>)
            .map((e) => e['id'])
            .toSet(),
        contains('medium_slow'),
      );
    });

    test('is idempotent and does not overwrite an existing demo file',
        () async {
      await useCase.execute(workspace);

      final speciesPath = workspace.resolveProjectRelativePath(
        'data/pokemon/species/0001-bulbasaur.json',
      );
      const customPayload = '{\n  "custom": true\n}';
      await File(speciesPath).writeAsString(customPayload);

      await useCase.execute(workspace);

      expect(await File(speciesPath).readAsString(), customPayload);
    });

    test(
        'enriches scaffold catalogs once but preserves a manually edited catalog',
        () async {
      await useCase.execute(workspace);

      final movesPath = workspace.resolveProjectRelativePath(
        'data/pokemon/catalogs/moves.json',
      );
      final initialMoves = await _readJsonMap(movesPath);
      expect((initialMoves['entries'] as List<dynamic>).length, 4);

      const customPayload = '{\n  "entries": ["keep-me"]\n}';
      await File(movesPath).writeAsString(customPayload);

      await useCase.execute(workspace);

      expect(await File(movesPath).readAsString(), customPayload);
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
        'Pokemon Demo Data',
        tempProjectRoot.path,
      );

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await useCase.execute(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });
  });
}

const List<String> _expectedDatasetFiles = <String>[
  'data/pokemon/catalogs/moves.json',
  'data/pokemon/catalogs/abilities.json',
  'data/pokemon/catalogs/types.json',
  'data/pokemon/catalogs/growth_rates.json',
  'data/pokemon/species/0001-bulbasaur.json',
  'data/pokemon/species/0002-ivysaur.json',
  'data/pokemon/learnsets/bulbasaur.json',
  'data/pokemon/learnsets/ivysaur.json',
  'data/pokemon/evolutions/bulbasaur.json',
  'data/pokemon/evolutions/ivysaur.json',
  'data/pokemon/media/bulbasaur.json',
  'data/pokemon/media/ivysaur.json',
];

const List<String> _expectedRootLeakChecks = <String>[
  'data/pokemon/species/0001-bulbasaur.json',
  'data/pokemon/learnsets/bulbasaur.json',
  'data/pokemon/evolutions/bulbasaur.json',
  'data/pokemon/catalogs/moves.json',
];

Future<Map<String, dynamic>> _readJsonMap(String path) async {
  final raw = await File(path).readAsString();
  return jsonDecode(raw) as Map<String, dynamic>;
}
