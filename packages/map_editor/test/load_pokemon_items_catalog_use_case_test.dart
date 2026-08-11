import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';

void main() {
  group('LoadPokemonItemsCatalogUseCase', () {
    test(
      'loads strict definitions with the shared codec and projects the view',
      () async {
        final catalog = ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'tm-protect',
              displayName: 'TM Protect',
              pocketId: 'machines',
              machine: const ProjectMoveMachineItemDefinition(
                kind: ProjectMoveMachineKind.tm,
                moveId: 'protect',
                consumable: true,
              ),
            ),
            ProjectItemDefinition(
              id: 'oran-berry',
              displayName: 'Oran Berry',
              aliases: const ['oran'],
              pocketId: 'berries',
              description: 'Restores HP.',
              buyPrice: 80,
            ),
          ],
        ).normalized();
        final workspace = _FakeWorkspace(
          files: {
            '/project/data/pokemon/catalogs/items.json': jsonEncode(
              encodeProjectItemCatalog(catalog),
            ),
            '/project/data/pokemon/assets/items/oran-berry.png': '',
          },
        );
        const useCase = LoadPokemonItemsCatalogUseCase();

        final result = await useCase.execute(workspace);

        expect(result.loadState, PokemonItemsCatalogLoadState.ready);
        expect(result.canonicalCatalog, catalog);
        expect(result.entries.map((entry) => entry.id), [
          'oran-berry',
          'tm-protect',
        ]);
        expect(result.entries.first.name, 'Oran Berry');
        expect(result.entries.first.aliases, ['oran']);
        expect(result.entries.first.pocketId, 'berries');
        expect(result.entries.first.cost, 80);
        expect(result.entries.first.effectText, 'Restores HP.');
        expect(
          result.entries.first.localSpritePath,
          'data/pokemon/assets/items/oran-berry.png',
        );
        expect(result.entries.last.machineKind, 'tm');
        expect(result.entries.last.machineMoveId, 'protect');
        expect(result.entries.last.machineConsumable, isTrue);
        expect(
          result.entries.every((entry) => entry.categoryId == null),
          isTrue,
        );
      },
    );

    test('rejects a legacy catalog instead of falling back', () async {
      final workspace = _FakeWorkspace(
        files: {
          '/project/data/pokemon/catalogs/items.json': jsonEncode({
            'catalog': 'items',
            'entries': [
              {'id': 'potion', 'name': 'Potion', 'categoryId': 'medicine'},
            ],
          }),
        },
      );
      const useCase = LoadPokemonItemsCatalogUseCase();

      final result = await useCase.execute(workspace);

      expect(result.loadState, PokemonItemsCatalogLoadState.loadError);
      expect(result.entries, isEmpty);
      expect(result.canonicalCatalog, isNull);
      expect(result.message, contains('catalog'));
    });

    test('reports a missing strict catalog honestly', () async {
      const useCase = LoadPokemonItemsCatalogUseCase();

      final result = await useCase.execute(_FakeWorkspace());

      expect(result.loadState, PokemonItemsCatalogLoadState.missingCatalog);
      expect(result.entries, isEmpty);
      expect(result.canonicalCatalog, isNull);
      expect(result.catalogRelativePath, 'data/pokemon/catalogs/items.json');
    });
  });
}

class _FakeWorkspace implements ProjectWorkspace {
  _FakeWorkspace({Map<String, String> files = const {}})
      : files = Map.of(files);

  final Map<String, String> files;

  @override
  String get projectManifestPath => '/project/project.json';

  @override
  String get projectRoot => '/project';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => files.containsKey(path);

  @override
  String getMapPath(String mapId) => '/project/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => files[path]!;

  @override
  String resolveMapPath(String relativePath) => '/project/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/project/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/project/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {
    files[path] = contents;
  }
}
