import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/encounter_table_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  late _FakeProjectRepository repository;
  const workspace = _FakeWorkspace();

  setUp(() {
    repository = _FakeProjectRepository();
  });

  group('encounter table use cases', () {
    test('create, update and delete tables persist through the project repo',
        () async {
      final createUseCase = CreateEncounterTableUseCase(repository);
      final updateUseCase = UpdateEncounterTableUseCase(repository);
      final deleteUseCase = DeleteEncounterTableUseCase(repository);

      final created = await createUseCase.execute(
        workspace,
        _project(),
        name: '  Grass Patch  ',
        encounterKind: EncounterKind.walk,
      );

      expect(created.encounterTables.single.id, 'grass_patch');
      expect(created.encounterTables.single.name, 'Grass Patch');

      final updated = await updateUseCase.execute(
        workspace,
        created,
        tableId: 'grass_patch',
        name: ' Tall Grass ',
        encounterKind: EncounterKind.surf,
      );

      expect(updated.encounterTables.single.name, 'Tall Grass');
      expect(updated.encounterTables.single.encounterKind, EncounterKind.surf);

      final deleted = await deleteUseCase.execute(
        workspace,
        updated,
        tableId: 'grass_patch',
      );

      expect(deleted.encounterTables, isEmpty);
      expect(repository.savedProjects, hasLength(3));
    });

    test('add, update and delete entries keep valid encounter data stable',
        () async {
      final addUseCase = AddEncounterEntryUseCase(repository);
      final updateUseCase = UpdateEncounterEntryUseCase(repository);
      final deleteUseCase = DeleteEncounterEntryUseCase(repository);

      final created = await addUseCase.execute(
        workspace,
        _project(
          encounterTables: const <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'grass_patch',
              name: 'Grass Patch',
              encounterKind: EncounterKind.walk,
            ),
          ],
        ),
        tableId: 'grass_patch',
        speciesId: '  bulbasaur  ',
        minLevel: 2,
        maxLevel: 4,
        weight: 3,
      );

      final addedEntry = created.encounterTables.single.entries.single;
      expect(addedEntry.speciesId, 'bulbasaur');
      expect(addedEntry.minLevel, 2);
      expect(addedEntry.maxLevel, 4);
      expect(addedEntry.weight, 3);

      final updated = await updateUseCase.execute(
        workspace,
        created,
        tableId: 'grass_patch',
        entryIndex: 0,
        speciesId: ' ivysaur ',
        minLevel: 5,
        maxLevel: 7,
        weight: 6,
      );

      final updatedEntry = updated.encounterTables.single.entries.single;
      expect(updatedEntry.speciesId, 'ivysaur');
      expect(updatedEntry.minLevel, 5);
      expect(updatedEntry.maxLevel, 7);
      expect(updatedEntry.weight, 6);

      final deleted = await deleteUseCase.execute(
        workspace,
        updated,
        tableId: 'grass_patch',
        entryIndex: 0,
      );

      expect(deleted.encounterTables.single.entries, isEmpty);
      expect(repository.savedProjects, hasLength(3));
    });

    test('rejects invalid entry data before any save happens', () async {
      final addUseCase = AddEncounterEntryUseCase(repository);
      final project = _project(
        encounterTables: const <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
        ],
      );

      expect(
        () => addUseCase.execute(
          workspace,
          project,
          tableId: 'grass_patch',
          speciesId: '   ',
          minLevel: 2,
          maxLevel: 4,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        () => addUseCase.execute(
          workspace,
          project,
          tableId: 'grass_patch',
          speciesId: 'bulbasaur',
          minLevel: 5,
          maxLevel: 4,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        () => addUseCase.execute(
          workspace,
          project,
          tableId: 'grass_patch',
          speciesId: 'bulbasaur',
          minLevel: 2,
          maxLevel: 4,
          weight: 0,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(repository.savedProjects, isEmpty);
    });
  });
}

ProjectManifest _project({
  List<ProjectEncounterTable> encounterTables = const <ProjectEncounterTable>[],
}) {
  return ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
    name: 'encounter_table_use_case_test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    encounterTables: encounterTables,
  );
}

class _FakeProjectRepository implements ProjectRepository {
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedProjects.add(project);
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
