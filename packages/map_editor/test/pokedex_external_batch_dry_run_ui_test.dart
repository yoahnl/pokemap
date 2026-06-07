import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
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
    name: 'pokedex_external_batch_dry_run_test',
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

  Future<void> openExternalImportStep(WidgetTester tester) async {
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
    expect(
      find.byKey(const Key('pokedex-import-external-query-step')),
      findsOneWidget,
    );
  }

  Future<void> switchToBatchMode(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-mode-batch-option')),
    );
    await tester.pumpAndSettle();
  }

  PokedexWorkspace buildWorkspace({
    required Future<PokemonExternalBatchSelectionResult> Function(
            String rawQuery)
        externalBatchSelectionResolver,
    required Future<PokemonExternalBatchImportResult> Function(
      ProjectWorkspace workspace,
      List<String> speciesIds,
    ) externalBatchPreviewer,
  }) {
    return PokedexWorkspace(
      loader: (_) async => const <PokemonDatabaseIndexEntry>[],
      detailLoader: (_, __) async => _unusedDetail(),
      importPreviewer: (_, __) async => throw UnimplementedError(),
      importer: (_, __) async => throw UnimplementedError(),
      externalSpeciesSearcher: (rawQuery) async =>
          const PokemonExternalSpeciesSearchResult.empty(
        rawQuery: '',
        normalizedQuery: '',
      ),
      externalBatchSelectionResolver: externalBatchSelectionResolver,
      externalBatchPreviewer: externalBatchPreviewer,
      externalImportPreviewer: (_, __) async => throw UnimplementedError(),
      externalImporter: (_, __) async => throw UnimplementedError(),
    );
  }

  testWidgets('switches to batch mode, resolves targets and unlocks dry-run',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_dry_run_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalBatchSelectionResolver: (rawQuery) async {
          if (rawQuery.trim() == 'pikachu, 25, bulbasaur') {
            return _resolvedBatchSelection();
          }
          return PokemonExternalBatchSelectionResult.empty(
            rawQuery: rawQuery,
            normalizedQuery: rawQuery.trim(),
          );
        },
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);
    await switchToBatchMode(tester);

    final previewButtonFinder = find.byKey(
      const Key('pokedex-import-external-batch-preview-button'),
    );

    expect(
      tester.widget<PushButton>(previewButtonFinder).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-batch-query-field')),
      'pikachu, 25, bulbasaur',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const Key('pokedex-import-external-batch-resolved-message')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pokedex-import-external-batch-target-pikachu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pokedex-import-external-batch-target-bulbasaur')),
      findsOneWidget,
    );
    expect(
      find.textContaining('1 doublon(s) éliminé(s)'),
      findsOneWidget,
    );
    expect(
      tester.widget<PushButton>(previewButtonFinder).onPressed,
      isNotNull,
    );
  });

  testWidgets('keeps dry-run blocked for out-of-scope mono queries',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_dry_run_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalBatchSelectionResolver: (rawQuery) async =>
            PokemonExternalBatchSelectionResult.outOfScopeQuery(
          rawQuery: rawQuery,
          normalizedQuery: rawQuery.trim(),
          resolution: const PokemonExternalSingleQueryResolution(
            rawQuery: 'pikachu',
            normalizedQuery: 'pikachu',
            query: PokemonExternalSingleQuery.species(
              rawValue: 'pikachu',
              normalizedValue: 'pikachu',
            ),
          ),
          message:
              'Le mode batch attend une liste explicite, une plage Pokédex '
              'ou une génération.',
        ),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);
    await switchToBatchMode(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-batch-query-field')),
      'pikachu',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.textContaining('liste explicite'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PushButton>(
            find.byKey(
              const Key('pokedex-import-external-batch-preview-button'),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('shows a dry-run preview and passes resolved species ids',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final previewedSpeciesIds = <List<String>>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_dry_run_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, speciesIds) async {
          previewedSpeciesIds.add(List<String>.from(speciesIds));
          return _sampleBatchDryRunPreview();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);
    await switchToBatchMode(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-batch-query-field')),
      'pikachu, 25, bulbasaur',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-preview-button')),
    );
    await tester.pumpAndSettle();

    expect(
      previewedSpeciesIds,
      <List<String>>[
        <String>['pikachu', 'bulbasaur'],
      ],
    );
    expect(
      find.byKey(const Key('pokedex-import-external-batch-preview-step')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-preview-entry-pikachu'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-preview-entry-bulbasaur'),
      ),
      findsOneWidget,
    );
    expect(find.text('Dry-run batch API'), findsOneWidget);
    expect(find.text('Conflit détecté'), findsOneWidget);
    expect(find.text('Aperçu disponible'), findsOneWidget);
    expect(
      find.byKey(const Key('pokedex-import-confirm-button')),
      findsNothing,
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
      PokemonExternalBatchImportEntryResult(
        speciesId: 'pikachu',
        result: PokemonExternalImportResult(
          requestedSpeciesId: 'pikachu',
          importedSpeciesId: 'pikachu',
          preview: _previewFor(
            speciesId: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
          ),
          dryRun: true,
          mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
          artifacts: const <PokemonExternalImportArtifactResult>[
            PokemonExternalImportArtifactResult(
              kind: PokemonExternalImportArtifactKind.species,
              relativePath: 'data/pokemon/species/0025-pikachu.json',
              action: PokemonExternalImportArtifactAction.create,
              existedBefore: false,
            ),
          ],
          warnings: const <String>[
            'Learnset payload partiel, import best-effort.',
          ],
        ),
      ),
      const PokemonExternalBatchImportEntryResult(
        speciesId: 'bulbasaur',
        result: PokemonExternalImportResult(
          requestedSpeciesId: 'bulbasaur',
          importedSpeciesId: 'bulbasaur',
          preview: PokemonExternalImportPreview(
            speciesId: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            learnset: PokemonExternalImportPreviewArtifact(
              label: 'Learnset',
              isAvailable: true,
            ),
            evolution: PokemonExternalImportPreviewArtifact(
              label: 'Evolution',
              isAvailable: true,
            ),
            media: PokemonExternalImportPreviewArtifact(
              label: 'Media',
              isAvailable: true,
            ),
            cries: PokemonExternalImportPreviewArtifact(
              label: 'Cries',
              isAvailable: false,
            ),
          ),
          dryRun: true,
          mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
          artifacts: <PokemonExternalImportArtifactResult>[
            PokemonExternalImportArtifactResult(
              kind: PokemonExternalImportArtifactKind.species,
              relativePath: 'data/pokemon/species/0001-bulbasaur.json',
              action: PokemonExternalImportArtifactAction.conflict,
              existedBefore: true,
            ),
          ],
        ),
      ),
    ],
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

PokedexSpeciesDetail _unusedDetail() {
  return const PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: 'bulbasaur',
      slug: 'bulbasaur',
      nationalDex: 1,
      names: <String, String>{
        'fr': 'Bulbizarre',
        'en': 'Bulbasaur',
      },
      speciesName: <String, String>{
        'fr': 'Pokémon Graine',
        'en': 'Seed Pokemon',
      },
      genIntroduced: 1,
      typing: PokemonSpeciesTyping(types: <String>['grass']),
      baseStats: PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: PokemonSpeciesAbilities(primary: 'overgrow'),
      breeding: PokemonSpeciesBreeding(
        genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
        eggGroups: <String>['monster'],
        hatchCycles: 20,
      ),
      progression: PokemonSpeciesProgression(
        growthRateId: 'medium_slow',
        baseExp: 64,
        catchRate: 45,
        baseFriendship: 50,
      ),
      forms: PokemonSpeciesForms(
        baseFormId: 'bulbasaur',
        isBaseForm: true,
        formId: 'base',
        otherForms: <String>[],
      ),
      classification: PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: PokemonSpeciesRefs(
        learnset: 'bulbasaur',
        evolution: 'bulbasaur',
        media: 'bulbasaur',
      ),
      dexContent: PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'green',
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(),
      sourceMeta: PokemonSpeciesSourceMeta(
        seededBy: 'test',
        seedVersion: 1,
      ),
    ),
    learnset: PokemonLearnsetFile(
      speciesId: 'bulbasaur',
      startingMoves: <String>['tackle'],
    ),
    evolution: PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      preEvolution: null,
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
      variants: <String, PokemonMediaVariant>{},
    ),
  );
}
