import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late FileProjectRepository repository;
  late CreateProjectUseCase createProjectUseCase;
  late LoadProjectUseCase loadProjectUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('project_pokemon_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    repository = FileProjectRepository();
    createProjectUseCase = CreateProjectUseCase(
      repository,
      const FileProjectWorkspaceFactory(),
    );
    loadProjectUseCase = LoadProjectUseCase(repository);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('Project pokemon config', () {
    test('loads an older project without pokemon config and applies defaults',
        () async {
      await createProjectUseCase.execute('Legacy Pokemon Project', tempProjectRoot.path);

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      final json = jsonDecode(await projectFile.readAsString())
          as Map<String, dynamic>;
      json.remove('pokemon');
      await projectFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );

      final loaded = await loadProjectUseCase.execute(projectFile.path);

      expect(loaded.pokemon, const ProjectPokemonConfig());
    });

    test('creates a new project with the default lightweight pokemon config',
        () async {
      final manifest = await createProjectUseCase.execute(
        'Pokemon Config Project',
        tempProjectRoot.path,
      );

      expect(manifest.pokemon, const ProjectPokemonConfig());

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      final json = jsonDecode(await projectFile.readAsString())
          as Map<String, dynamic>;
      final pokemon = json['pokemon'] as Map<String, dynamic>;

      expect(
        pokemon.keys.toSet(),
        equals(<String>{
          'enabled',
          'dataRoot',
          'speciesDir',
          'learnsetsDir',
          'evolutionsDir',
          'mediaDir',
          'catalogFiles',
        }),
      );
      expect(pokemon['enabled'], isTrue);
      expect(pokemon['dataRoot'], 'data/pokemon');
      expect(pokemon['speciesDir'], 'data/pokemon/species');
      expect(pokemon['learnsetsDir'], 'data/pokemon/learnsets');
      expect(pokemon['evolutionsDir'], 'data/pokemon/evolutions');
      expect(pokemon['mediaDir'], 'data/pokemon/media');
      expect(
        pokemon['catalogFiles'],
        <String, Object?>{
          'moves': 'data/pokemon/catalogs/moves.json',
          'abilities': 'data/pokemon/catalogs/abilities.json',
          'items': 'data/pokemon/catalogs/items.json',
          'types': 'data/pokemon/catalogs/types.json',
          'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
          'natures': 'data/pokemon/catalogs/natures.json',
        },
      );

      expect(pokemon.containsKey('species'), isFalse);
      expect(pokemon.containsKey('learnsets'), isFalse);
      expect(pokemon.containsKey('evolutions'), isFalse);
      expect(pokemon.containsKey('entries'), isFalse);
    });

    test('round-trips pokemon config through save and load without corruption',
        () async {
      await createProjectUseCase.execute('Pokemon Roundtrip Project', tempProjectRoot.path);

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      final before = await projectFile.readAsString();

      final loaded = await loadProjectUseCase.execute(projectFile.path);
      await repository.saveProject(loaded, projectFile.path);

      final after = await projectFile.readAsString();

      expect(after, before);
    });

    test('loads project config without reading pokemon data files', () async {
      await createProjectUseCase.execute('Pokemon Lazy Config Project', tempProjectRoot.path);

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      final loaded = await loadProjectUseCase.execute(projectFile.path);

      expect(loaded.pokemon, const ProjectPokemonConfig());
      expect(
        Directory(p.join(tempProjectRoot.path, 'data', 'pokemon')).existsSync(),
        isFalse,
      );
      expect(
        Directory(p.join(tempProjectRoot.path, 'assets', 'pokemon')).existsSync(),
        isFalse,
      );
    });

    test('does not recreate data or assets at the monorepo root', () async {
      await createProjectUseCase.execute('Pokemon Root Guard Project', tempProjectRoot.path);

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      await loadProjectUseCase.execute(projectFile.path);

      expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
      expect(Directory(p.join(repoRootPath, 'assets')).existsSync(), isFalse);
    });
  });
}

String _resolveRepositoryRootFromCurrentDirectory() {
  var current = Directory.current.absolute;

  while (true) {
    final agentsFile = File(p.join(current.path, 'AGENTS.md'));
    final mapEditorDir = Directory(p.join(current.path, 'packages', 'map_editor'));
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
