import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';

void main() {
  group('LoadPokemonItemsCatalogUseCase', () {
    test('projects the local items catalog into a small readable view',
        () async {
      final useCase = LoadPokemonItemsCatalogUseCase(
        readRepository: _FakePokemonReadRepository(
          catalogByKey: <String, PokemonCatalogFile>{
            'items': const PokemonCatalogFile(
              schemaVersion: 1,
              kind: 'pokemon_catalog',
              catalog: 'items',
              meta: PokemonDataMeta(description: 'Catalogue local des objets.'),
              entries: <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'oran_berry',
                  'name': 'Oran Berry',
                  'aliases': <String>['oran'],
                  'shortDesc': 'Restores HP',
                },
                <String, dynamic>{
                  'id': 'choice_scarf',
                  'names': <String, dynamic>{'en': 'Choice Scarf'},
                },
              ],
            ),
          },
        ),
      );

      final result = await useCase.execute(const _FakeWorkspace());

      expect(result.isAvailable, isTrue);
      expect(result.entries.map((entry) => entry.id).toList(growable: false),
          <String>['choice_scarf', 'oran_berry']);
      expect(result.entries.first.name, 'Choice Scarf');
      expect(result.entries.last.aliases, contains('oran'));
    });

    test('falls back honestly when the local items catalog is missing',
        () async {
      final useCase = LoadPokemonItemsCatalogUseCase(
        readRepository: _FakePokemonReadRepository(
          notFoundCatalogKeys: <String>{'items'},
        ),
      );

      final result = await useCase.execute(const _FakeWorkspace());

      expect(result.isAvailable, isFalse);
      expect(result.entries, isEmpty);
      expect(result.message, contains('items'));
    });
  });
}

class _FakePokemonReadRepository implements PokemonReadRepository {
  _FakePokemonReadRepository({
    this.catalogByKey = const <String, PokemonCatalogFile>{},
    this.notFoundCatalogKeys = const <String>{},
  });

  final Map<String, PokemonCatalogFile> catalogByKey;
  final Set<String> notFoundCatalogKeys;

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    if (notFoundCatalogKeys.contains(catalogKey)) {
      throw EditorNotFoundException('Missing catalog: $catalogKey');
    }
    final catalog = catalogByKey[catalogKey];
    if (catalog == null) {
      throw EditorNotFoundException('Missing catalog: $catalogKey');
    }
    return catalog;
  }

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

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
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/$mapId.json';

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
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}
