import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_external_batch_selection.dart';
import 'package:map_editor/src/application/models/pokemon_external_query_resolution.dart';
import 'package:map_editor/src/application/models/pokemon_external_species_search_result.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';

void main() {
  const sampleProject = ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
    name: 'pokedex_external_batch_execute_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  Future<void> pumpPokedexWidget(
    WidgetTester tester,
    ProviderContainer container, {
    required Widget child,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MacosApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 900,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openBatchPreview(
    WidgetTester tester, {
    required String query,
  }) async {
    await tester
        .tap(find.byKey(const Key('pokedex-empty-state-import-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-api-source-card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-source-continue-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-mode-batch-option')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-batch-query-field')),
      query,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-preview-button')),
    );
    await tester.pumpAndSettle();
  }

  PokedexWorkspace buildWorkspace({
    required Future<PokemonExternalBatchSelectionResult> Function(
      String rawQuery,
    ) externalBatchSelectionResolver,
    required Future<PokemonExternalBatchImportResult> Function(
      ProjectWorkspace workspace,
      List<String> speciesIds,
    ) externalBatchPreviewer,
    required Future<PokemonExternalBatchImportResult> Function(
      ProjectWorkspace workspace,
      List<String> speciesIds, {
      void Function(PokemonExternalBatchImportProgress progress)? onProgress,
    }) externalBatchImporter,
    required Future<List<PokemonDatabaseIndexEntry>> Function(
      ProjectWorkspace workspace,
    ) loader,
    required Future<PokedexSpeciesDetail> Function(
      ProjectWorkspace workspace,
      String speciesId,
    ) detailLoader,
  }) {
    return PokedexWorkspace(
      loader: loader,
      detailLoader: detailLoader,
      importPreviewer: (_, __) async => throw UnimplementedError(),
      importer: (_, __) async => throw UnimplementedError(),
      externalSpeciesSearcher: (rawQuery) async =>
          const PokemonExternalSpeciesSearchResult.empty(
        rawQuery: '',
        normalizedQuery: '',
      ),
      externalBatchSelectionResolver: externalBatchSelectionResolver,
      externalBatchPreviewer: externalBatchPreviewer,
      externalBatchImporter: externalBatchImporter,
      externalImportPreviewer: (_, __) async => throw UnimplementedError(),
      externalImporter: (_, __) async => throw UnimplementedError(),
    );
  }

  testWidgets(
      'keeps dry-run and batch execution separate and shows a final report',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var previewCallCount = 0;
    var importCallCount = 0;
    final executedSpeciesIds = <List<String>>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
        detailLoader: (_, __) async => _buildDetail(
          id: 'pikachu',
          nationalDex: 25,
          primaryName: 'Pikachu',
          types: const <String>['electric'],
        ),
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, speciesIds) async {
          previewCallCount += 1;
          expect(speciesIds, <String>['pikachu', 'bulbasaur']);
          return _sampleBatchDryRunPreview();
        },
        externalBatchImporter: (_, speciesIds, {onProgress}) async {
          importCallCount += 1;
          executedSpeciesIds.add(List<String>.from(speciesIds));
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 1,
              successfulCount: 1,
              skippedCount: 0,
              conflictCount: 0,
              failedCount: 0,
              lastCompletedSpeciesId: 'pikachu',
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 1,
              skippedCount: 0,
              conflictCount: 1,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _sampleBatchImportResult();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );

    expect(previewCallCount, 1);
    expect(importCallCount, 0);
    expect(
      find.byKey(const Key('pokedex-import-external-batch-preview-step')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pump();

    expect(importCallCount, 1);
    expect(
      find.byKey(const Key('pokedex-import-external-batch-result-step')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Progression observée : 1 / 2'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(previewCallCount, 1);
    expect(
      executedSpeciesIds,
      <List<String>>[
        <String>['pikachu', 'bulbasaur'],
      ],
    );
    expect(
      find.textContaining('Progression observée : 2 / 2'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-result-entry-pikachu'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-result-entry-bulbasaur'),
      ),
      findsOneWidget,
    );
    expect(find.text('Import réussi'), findsOneWidget);
    expect(find.text('Conflit'), findsOneWidget);
  });

  testWidgets(
      'refreshes the workspace and selects the first imported species after a real batch',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final importedDetailsById = <String, PokedexSpeciesDetail>{};
    final detailRequests = <String>[];
    var entries = <PokemonDatabaseIndexEntry>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_workspace_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => entries,
        detailLoader: (_, speciesId) async {
          detailRequests.add(speciesId);
          return importedDetailsById[speciesId]!;
        },
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
        externalBatchImporter: (_, __, {onProgress}) async {
          importedDetailsById['pikachu'] = _buildDetail(
            id: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
          );
          importedDetailsById['bulbasaur'] = _buildDetail(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: const <String>['grass', 'poison'],
          );
          entries = <PokemonDatabaseIndexEntry>[
            _buildEntry(
              id: 'bulbasaur',
              nationalDex: 1,
              primaryName: 'Bulbasaur',
              types: const <String>['grass', 'poison'],
            ),
            _buildEntry(
              id: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: const <String>['electric'],
            ),
          ];
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 2,
              skippedCount: 0,
              conflictCount: 0,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _sampleBatchImportResult(
            orderedEntries: <PokemonExternalBatchImportEntryResult>[
              _successfulBatchEntry(
                speciesId: 'bulbasaur',
                nationalDex: 1,
                primaryName: 'Bulbasaur',
                types: const <String>['grass', 'poison'],
              ),
              _successfulBatchEntry(
                speciesId: 'pikachu',
                nationalDex: 25,
                primaryName: 'Pikachu',
                types: const <String>['electric'],
              ),
            ],
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-import-external-batch-result-step')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
          const Key('pokedex-import-external-batch-result-close-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-row-pikachu')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-row-bulbasaur')), findsOneWidget);
    expect(detailRequests, contains('pikachu'));
    expect(
      find.byKey(const Key('pokedex-feedback-banner')),
      findsOneWidget,
    );
    expect(
      find.text('Batch terminé · 2 succès, 0 conflits, 0 erreurs, 0 skips'),
      findsOneWidget,
    );
    expect(
      find.byIcon(CupertinoIcons.check_mark_circled_solid),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows an error feedback when no species was imported because all entries conflicted',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final detailRequests = <String>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_conflicts_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
        detailLoader: (_, speciesId) async {
          detailRequests.add(speciesId);
          return _buildDetail(
            id: speciesId,
            nationalDex: 25,
            primaryName: 'Unused',
            types: const <String>['normal'],
          );
        },
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
        externalBatchImporter: (_, __, {onProgress}) async {
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 0,
              skippedCount: 0,
              conflictCount: 2,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _conflictsOnlyBatchImportResult();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('pokedex-import-external-batch-result-close-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(detailRequests, isEmpty);
    expect(
      find.text(
          'Aucune espèce importée · 0 succès, 2 conflits, 0 erreurs, 0 skips'),
      findsOneWidget,
    );
    expect(
      find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows an error feedback when no species was imported because all entries were skipped',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final detailRequests = <String>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_skips_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
        detailLoader: (_, speciesId) async {
          detailRequests.add(speciesId);
          return _buildDetail(
            id: speciesId,
            nationalDex: 25,
            primaryName: 'Unused',
            types: const <String>['normal'],
          );
        },
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
        externalBatchImporter: (_, __, {onProgress}) async {
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 0,
              skippedCount: 2,
              conflictCount: 0,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _skipsOnlyBatchImportResult();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('pokedex-import-external-batch-result-close-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(detailRequests, isEmpty);
    expect(
      find.text(
          'Aucune espèce importée · 0 succès, 0 conflits, 0 erreurs, 2 skips'),
      findsOneWidget,
    );
    expect(
      find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows an error feedback when no species was imported because entries were skipped or conflicted',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final detailRequests = <String>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_mixed_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
        detailLoader: (_, speciesId) async {
          detailRequests.add(speciesId);
          return _buildDetail(
            id: speciesId,
            nationalDex: 25,
            primaryName: 'Unused',
            types: const <String>['normal'],
          );
        },
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
        externalBatchImporter: (_, __, {onProgress}) async {
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 0,
              skippedCount: 1,
              conflictCount: 1,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _mixedNoWriteBatchImportResult();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('pokedex-import-external-batch-result-close-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(detailRequests, isEmpty);
    expect(
      find.text(
          'Aucune espèce importée · 0 succès, 1 conflits, 0 erreurs, 1 skips'),
      findsOneWidget,
    );
    expect(
      find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
      findsOneWidget,
    );
  });
}

PokemonExternalBatchSelectionResult _resolvedBatchSelection() {
  return PokemonExternalBatchSelectionResult.resolved(
    rawQuery: 'pikachu, 25, bulbasaur',
    normalizedQuery: 'pikachu, 25, bulbasaur',
    resolution: PokemonExternalExplicitListQueryResolution(
      rawQuery: 'pikachu, 25, bulbasaur',
      normalizedQuery: 'pikachu, 25, bulbasaur',
      queries: const <PokemonExternalSingleQuery>[
        PokemonExternalSingleQuery.species(
          rawValue: 'pikachu',
          normalizedValue: 'pikachu',
        ),
        PokemonExternalSingleQuery.nationalDex(
          rawValue: '25',
          nationalDex: 25,
        ),
        PokemonExternalSingleQuery.species(
          rawValue: 'bulbasaur',
          normalizedValue: 'bulbasaur',
        ),
      ],
    ),
    targets: <PokemonExternalBatchSelectionTarget>[
      PokemonExternalBatchSelectionTarget(
        speciesId: 'pikachu',
        primaryName: 'Pikachu',
        nationalDex: 25,
        generation: 1,
        requestedInputs: const <String>['pikachu', '25'],
      ),
      PokemonExternalBatchSelectionTarget(
        speciesId: 'bulbasaur',
        primaryName: 'Bulbasaur',
        nationalDex: 1,
        generation: 1,
        requestedInputs: const <String>['bulbasaur'],
      ),
    ],
  );
}

PokemonExternalBatchImportResult _sampleBatchDryRunPreview() {
  return PokemonExternalBatchImportResult(
    dryRun: true,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: <PokemonExternalBatchImportEntryResult>[
      _successfulBatchEntry(
        speciesId: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        types: const <String>['electric'],
        dryRun: true,
      ),
      _conflictBatchEntry(
        speciesId: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        types: const <String>['grass', 'poison'],
        dryRun: true,
      ),
    ],
  );
}

PokemonExternalBatchImportResult _sampleBatchImportResult({
  List<PokemonExternalBatchImportEntryResult>? orderedEntries,
}) {
  return PokemonExternalBatchImportResult(
    dryRun: false,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: orderedEntries ??
        <PokemonExternalBatchImportEntryResult>[
          _successfulBatchEntry(
            speciesId: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
          ),
          _conflictBatchEntry(
            speciesId: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: const <String>['grass', 'poison'],
          ),
        ],
  );
}

PokemonExternalBatchImportResult _conflictsOnlyBatchImportResult() {
  return PokemonExternalBatchImportResult(
    dryRun: false,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: <PokemonExternalBatchImportEntryResult>[
      _conflictBatchEntry(
        speciesId: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        types: const <String>['electric'],
      ),
      _conflictBatchEntry(
        speciesId: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        types: const <String>['grass', 'poison'],
      ),
    ],
  );
}

PokemonExternalBatchImportResult _skipsOnlyBatchImportResult() {
  return PokemonExternalBatchImportResult(
    dryRun: false,
    mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
    entries: <PokemonExternalBatchImportEntryResult>[
      _skippedBatchEntry(
        speciesId: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        types: const <String>['electric'],
      ),
      _skippedBatchEntry(
        speciesId: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        types: const <String>['grass', 'poison'],
      ),
    ],
  );
}

PokemonExternalBatchImportResult _mixedNoWriteBatchImportResult() {
  return PokemonExternalBatchImportResult(
    dryRun: false,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: <PokemonExternalBatchImportEntryResult>[
      _conflictBatchEntry(
        speciesId: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        types: const <String>['electric'],
      ),
      _skippedBatchEntry(
        speciesId: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        types: const <String>['grass', 'poison'],
      ),
    ],
  );
}

PokemonExternalBatchImportEntryResult _successfulBatchEntry({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
  bool dryRun = false,
}) {
  return PokemonExternalBatchImportEntryResult(
    speciesId: speciesId,
    result: PokemonExternalImportResult(
      requestedSpeciesId: speciesId,
      importedSpeciesId: speciesId,
      preview: _previewFor(
        speciesId: speciesId,
        nationalDex: nationalDex,
        primaryName: primaryName,
        types: types,
      ),
      dryRun: dryRun,
      mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      artifacts: <PokemonExternalImportArtifactResult>[
        PokemonExternalImportArtifactResult(
          kind: PokemonExternalImportArtifactKind.species,
          relativePath:
              'data/pokemon/species/${nationalDex.toString().padLeft(4, '0')}-$speciesId.json',
          action: dryRun
              ? PokemonExternalImportArtifactAction.create
              : PokemonExternalImportArtifactAction.create,
          existedBefore: false,
        ),
      ],
      downloadedAssets: dryRun
          ? const <PokemonExternalAssetDownloadResult>[]
          : <PokemonExternalAssetDownloadResult>[
              PokemonExternalAssetDownloadResult(
                label: 'Portrait',
                relativePath: 'assets/pokemon/portraits/$speciesId.png',
                sourceUrl: 'https://assets.example.test/$speciesId.png',
                wasWritten: true,
              ),
            ],
      warnings: const <String>[
        'Import best-effort.',
      ],
    ),
  );
}

PokemonExternalBatchImportEntryResult _conflictBatchEntry({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
  bool dryRun = false,
}) {
  return PokemonExternalBatchImportEntryResult(
    speciesId: speciesId,
    result: PokemonExternalImportResult(
      requestedSpeciesId: speciesId,
      importedSpeciesId: speciesId,
      preview: _previewFor(
        speciesId: speciesId,
        nationalDex: nationalDex,
        primaryName: primaryName,
        types: types,
      ),
      dryRun: dryRun,
      mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      artifacts: <PokemonExternalImportArtifactResult>[
        PokemonExternalImportArtifactResult(
          kind: PokemonExternalImportArtifactKind.species,
          relativePath:
              'data/pokemon/species/${nationalDex.toString().padLeft(4, '0')}-$speciesId.json',
          action: PokemonExternalImportArtifactAction.conflict,
          existedBefore: true,
        ),
      ],
    ),
  );
}

PokemonExternalBatchImportEntryResult _skippedBatchEntry({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokemonExternalBatchImportEntryResult(
    speciesId: speciesId,
    result: PokemonExternalImportResult(
      requestedSpeciesId: speciesId,
      importedSpeciesId: speciesId,
      preview: _previewFor(
        speciesId: speciesId,
        nationalDex: nationalDex,
        primaryName: primaryName,
        types: types,
      ),
      dryRun: false,
      mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      artifacts: <PokemonExternalImportArtifactResult>[
        PokemonExternalImportArtifactResult(
          kind: PokemonExternalImportArtifactKind.species,
          relativePath:
              'data/pokemon/species/${nationalDex.toString().padLeft(4, '0')}-$speciesId.json',
          action: PokemonExternalImportArtifactAction.skip,
          existedBefore: true,
        ),
      ],
    ),
  );
}

PokemonExternalImportPreview _previewFor({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokemonExternalImportPreview(
    speciesId: speciesId,
    nationalDex: nationalDex,
    primaryName: primaryName,
    types: types,
    learnset: const PokemonExternalImportPreviewArtifact(
      label: 'Learnset',
      isAvailable: true,
    ),
    evolution: const PokemonExternalImportPreviewArtifact(
      label: 'Evolution',
      isAvailable: true,
    ),
    media: const PokemonExternalImportPreviewArtifact(
      label: 'Media',
      isAvailable: true,
    ),
    cries: const PokemonExternalImportPreviewArtifact(
      label: 'Cries',
      isAvailable: true,
    ),
  );
}

PokemonDatabaseIndexEntry _buildEntry({
  required String id,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokemonDatabaseIndexEntry(
    id: id,
    nationalDex: nationalDex,
    primaryName: primaryName,
    genIntroduced: 1,
    types: types,
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: id,
      evolution: id,
      media: id,
    ),
  );
}

PokedexSpeciesDetail _buildDetail({
  required String id,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: id,
      slug: id,
      nationalDex: nationalDex,
      names: <String, String>{
        'fr': primaryName,
        'en': primaryName,
      },
      speciesName: const <String, String>{
        'fr': 'Pokémon test',
        'en': 'Test Pokemon',
      },
      genIntroduced: 1,
      typing: PokemonSpeciesTyping(types: types),
      baseStats: const PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: const PokemonSpeciesAbilities(primary: 'static'),
      breeding: const PokemonSpeciesBreeding(
        genderRatio: <String, double>{'male': 0.5, 'female': 0.5},
        eggGroups: <String>['field'],
        hatchCycles: 20,
      ),
      progression: const PokemonSpeciesProgression(
        growthRateId: 'medium_fast',
        baseExp: 64,
        catchRate: 45,
        baseFriendship: 50,
      ),
      forms: PokemonSpeciesForms(
        baseFormId: id,
        isBaseForm: true,
        formId: 'base',
        otherForms: const <String>[],
      ),
      classification: const PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: PokemonSpeciesRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
      dexContent: const PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'yellow',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(),
      sourceMeta: const PokemonSpeciesSourceMeta(
        seededBy: 'test',
        seedVersion: 1,
      ),
    ),
    learnset: PokemonLearnsetFile(
      speciesId: id,
    ),
    evolution: PokemonEvolutionFile(
      speciesId: id,
    ),
    media: PokemonMediaFile(
      speciesId: id,
      defaultFormId: 'base',
      variants: const <String, PokemonMediaVariant>{
        'base': PokemonMediaVariant(),
      },
    ),
  );
}
