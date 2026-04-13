import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/encounter_tables_panel.dart';

void main() {
  Future<void> pumpEncounterPanel(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 1800,
                child: EncounterTablesPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'creates a table and a valid encounter entry with local species assist',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('encounter-tables-new-table-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-create-name-field')),
      'Grass Patch',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('encounter-tables-create-submit-button')),
    );
    await tester.pumpAndSettle();

    final table =
        container.read(editorNotifierProvider).project!.encounterTables.single;
    expect(table.id, 'grass_patch');
    expect(table.name, 'Grass Patch');

    await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-grass_patch')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('encounter-tables-add-entry-button-grass_patch')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-species-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('encounter-tables-entry-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-min-level-field')),
      '2',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-max-level-field')),
      '4',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-weight-field')),
      '3',
    );

    await tester.tap(
      find.byKey(const Key('encounter-tables-entry-save-button')),
    );
    await tester.pumpAndSettle();

    final savedEntry = container
        .read(editorNotifierProvider)
        .project!
        .encounterTables
        .single
        .entries
        .single;
    expect(savedEntry.speciesId, 'bulbasaur');
    expect(savedEntry.minLevel, 2);
    expect(savedEntry.maxLevel, 4);
    expect(savedEntry.weight, 3);
    expect(
        find.textContaining('Bulbasaur • bulbasaur • Lv.2-4'), findsOneWidget);
    expect(find.textContaining('100.0%'), findsOneWidget);
  });

  testWidgets(
      'shows inline validation and blocks save when local species or levels are invalid',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        encounterTables: <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
        ],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-grass_patch')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('encounter-tables-add-entry-button-grass_patch')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-species-field')),
      'missingno',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-min-level-field')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-max-level-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-weight-field')),
      '0',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Species "missingno" is not present in the local Pokédex.'),
      findsOneWidget,
    );
    expect(
      find.text('Max level must be greater than or equal to min level.'),
      findsOneWidget,
    );
    expect(
      find.text('Weight must be a positive integer.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('encounter-tables-entry-save-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      container
          .read(editorNotifierProvider)
          .project!
          .encounterTables
          .single
          .entries,
      isEmpty,
    );
  });

  testWidgets('closes the table editor after a successful table update',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        encounterTables: <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
        ],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('encounter-tables-table-toggle-grass_patch')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('encounter-tables-edit-name-field-grass_patch')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('encounter-tables-edit-name-field-grass_patch')),
      'Tall Grass',
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('encounter-tables-save-table-button-grass_patch')),
    );
    await tester.pumpAndSettle();

    final savedTable =
        container.read(editorNotifierProvider).project!.encounterTables.single;
    expect(savedTable.name, 'Tall Grass');
    expect(
      find.byKey(const Key('encounter-tables-edit-name-field-grass_patch')),
      findsNothing,
    );
    expect(find.text('Tall Grass'), findsOneWidget);
  });

  testWidgets(
      'keeps the panel usable when the local species index is unavailable',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => throw StateError('species loader exploded'),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        encounterTables: <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
        ],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
          'Unable to load local species data. Raw species IDs are still allowed.'),
      findsOneWidget,
    );

    await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-grass_patch')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('encounter-tables-add-entry-button-grass_patch')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-species-field')),
      'missingno',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-min-level-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-max-level-field')),
      '7',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-weight-field')),
      '2',
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to verify against local species data. Raw species IDs are still allowed.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Local species suggestions are unavailable right now.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('encounter-tables-entry-save-button')),
    );
    await tester.pumpAndSettle();

    final savedEntry = container
        .read(editorNotifierProvider)
        .project!
        .encounterTables
        .single
        .entries
        .single;
    expect(savedEntry.speciesId, 'missingno');
    expect(
      find.text(
        'Local species verification unavailable. The raw species ID is preserved.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps the create form open and surfaces the error when persistence fails',
      (tester) async {
    final repository = _FakeProjectRepository(
      saveError: StateError('disk exploded'),
    );
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('encounter-tables-new-table-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-create-name-field')),
      'Grass Patch',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('encounter-tables-create-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('encounter-tables-create-name-field')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
          'Failed to create encounter table: Bad state: disk exploded'),
      findsWidgets,
    );
    expect(
      container.read(editorNotifierProvider).project!.encounterTables,
      isEmpty,
    );
  });
}

const List<PokemonDatabaseIndexEntry> _speciesEntries =
    <PokemonDatabaseIndexEntry>[
  PokemonDatabaseIndexEntry(
    id: 'bulbasaur',
    nationalDex: 1,
    primaryName: 'Bulbasaur',
    genIntroduced: 1,
    types: <String>['grass', 'poison'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'bulbasaur',
      evolution: 'bulbasaur',
      media: 'bulbasaur',
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
];

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({
    this.saveError,
  });

  final Object? saveError;
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    if (saveError != null) {
      throw saveError!;
    }
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

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory(this.workspace);

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRootPath) => workspace;
}
