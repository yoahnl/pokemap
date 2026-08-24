import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/encounter_table_persistence_gateway.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/encounter_table_use_cases.dart';

void main() {
  late _RecordingEncounterTablePersistenceGateway gateway;
  const workspace = _FakeWorkspace();

  setUp(() {
    gateway = _RecordingEncounterTablePersistenceGateway();
  });

  group('encounter table use cases', () {
    test('routes table creation through the encounter authoring gateway',
        () async {
      final project = _project();
      final created = await CreateEncounterTableUseCase(gateway).execute(
        workspace,
        project,
        name: 'Grass Patch',
        encounterKind: EncounterKind.walk,
      );

      expect(gateway.expectedProjects, <ProjectManifest>[project]);
      expect(gateway.upsertedTables.single.id, 'grass_patch');
      expect(created.encounterTables.single.id, 'grass_patch');
    });

    test('create, update and delete tables persist through the gateway',
        () async {
      final createUseCase = CreateEncounterTableUseCase(gateway);
      final updateUseCase = UpdateEncounterTableUseCase(gateway);
      final deleteUseCase = DeleteEncounterTableUseCase(gateway);

      final created = await createUseCase.execute(
        workspace,
        _project(),
        name: '  Grass Patch  ',
        encounterKind: EncounterKind.walk,
        chancePerStep: 0.2,
        conditions: <ScriptCondition>[
          ScriptConditionFactory.flagIsSet('route_1_open'),
        ],
      );

      expect(created.encounterTables.single.id, 'grass_patch');
      expect(created.encounterTables.single.name, 'Grass Patch');
      expect(created.encounterTables.single.chancePerStep, 0.2);
      expect(created.encounterTables.single.conditions, hasLength(1));

      final updated = await updateUseCase.execute(
        workspace,
        created,
        tableId: 'grass_patch',
        name: ' Tall Grass ',
        encounterKind: EncounterKind.surf,
        chancePerStep: 0.35,
        conditions: <ScriptCondition>[
          ScriptConditionFactory.fieldAbilityUnlocked(FieldAbility.surf),
        ],
      );

      expect(updated.encounterTables.single.name, 'Tall Grass');
      expect(updated.encounterTables.single.encounterKind, EncounterKind.surf);
      expect(updated.encounterTables.single.chancePerStep, 0.35);
      expect(
        updated.encounterTables.single.conditions.single.type,
        ScriptConditionType.fieldAbilityUnlocked,
      );

      final deleted = await deleteUseCase.execute(
        workspace,
        updated,
        tableId: 'grass_patch',
      );

      expect(deleted.encounterTables, isEmpty);
      expect(gateway.expectedProjects, hasLength(3));
    });

    test('add, update and delete entries keep valid encounter data stable',
        () async {
      final addUseCase = AddEncounterEntryUseCase(gateway);
      final updateUseCase = UpdateEncounterEntryUseCase(gateway);
      final deleteUseCase = DeleteEncounterEntryUseCase(gateway);

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
      expect(gateway.expectedProjects, hasLength(3));
    });

    test('rejects invalid entry data before any save happens', () async {
      final addUseCase = AddEncounterEntryUseCase(gateway);
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

      expect(gateway.expectedProjects, isEmpty);
    });

    test('authors, preserves and clears wild generation overrides', () async {
      final project = _project(
        encounterTables: const <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
        ],
      );
      final created = await AddEncounterEntryUseCase(gateway).execute(
        workspace,
        project,
        tableId: 'grass_patch',
        speciesId: 'eevee',
        minLevel: 8,
        maxLevel: 8,
        pokemonOverrides: const ProjectEncounterPokemonOverrides(
          natureId: 'jolly',
          shinyPolicy: ProjectEncounterShinyPolicy.never,
        ),
      );
      final preserved = await UpdateEncounterEntryUseCase(gateway).execute(
        workspace,
        created,
        tableId: 'grass_patch',
        entryIndex: 0,
        weight: 2,
      );
      final cleared = await UpdateEncounterEntryUseCase(gateway).execute(
        workspace,
        preserved,
        tableId: 'grass_patch',
        entryIndex: 0,
        clearPokemonOverrides: true,
      );

      expect(
        created.encounterTables.single.entries.single.pokemonOverrides,
        const ProjectEncounterPokemonOverrides(
          natureId: 'jolly',
          shinyPolicy: ProjectEncounterShinyPolicy.never,
        ),
      );
      expect(
        preserved.encounterTables.single.entries.single.pokemonOverrides,
        created.encounterTables.single.entries.single.pokemonOverrides,
      );
      expect(
        cleared.encounterTables.single.entries.single.pokemonOverrides,
        isNull,
      );
    });
  });
}

ProjectManifest _project({
  List<ProjectEncounterTable> encounterTables = const <ProjectEncounterTable>[],
}) {
  return ProjectManifest(
    name: 'encounter_table_use_case_test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    encounterTables: encounterTables,
  );
}

class _RecordingEncounterTablePersistenceGateway
    implements EncounterTablePersistenceGateway {
  final List<ProjectManifest> expectedProjects = <ProjectManifest>[];
  final List<ProjectEncounterTable> upsertedTables = <ProjectEncounterTable>[];

  @override
  Future<ProjectManifest> updateBattleTransitionDefaults({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    String? wildTransitionId,
    String? trainerTransitionId,
  }) async {
    // Ce harnais couvre les use cases de tables ; le défaut projet a sa
    // propre suite côté map_authoring (BETA-BAT-034, lot 2).
    throw UnimplementedError();
  }

  @override
  Future<ProjectManifest> remove({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String tableId,
  }) async {
    expectedProjects.add(expectedProject);
    return expectedProject.copyWith(
      encounterTables: expectedProject.encounterTables
          .where((table) => table.id != tableId)
          .toList(growable: false),
    );
  }

  @override
  Future<ProjectManifest> upsert({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required ProjectEncounterTable table,
  }) async {
    expectedProjects.add(expectedProject);
    upsertedTables.add(table);
    return expectedProject.copyWith(
      encounterTables: <ProjectEncounterTable>[
        for (final existing in expectedProject.encounterTables)
          if (existing.id != table.id) existing,
        table,
      ],
    );
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
