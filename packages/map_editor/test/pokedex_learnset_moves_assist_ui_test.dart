import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_evolution_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_learnset_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_media_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';

void main() {
  const sampleProject = ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
    name: 'pokedex_ui_test',
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
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(width: 1280, height: 900, child: child),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('adds a starting move through explicit local catalog selection',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final store = _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        'bulbasaur': _buildDetail(
          id: 'bulbasaur',
          learnset: const PokemonLearnsetFile(
            speciesId: 'bulbasaur',
            startingMoves: <String>['tackle'],
          ),
        ),
      },
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        learnsetSaver: store.saveLearnset,
        metadataSaver: store.saveMetadata,
        formsClassificationSaver: store.saveFormsClassification,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
        movesCatalogLoader: (_) async => _movesCatalogView(),
        movesCatalogPreviewer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: true,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
        movesCatalogSyncer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: false,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-learnset-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-starting-search-field')),
      'vine',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pokedex-learnset-starting-suggestion-vine_whip')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('pokedex-learnset-starting-suggestion-vine_whip')),
    );
    await tester.pumpAndSettle();

    final startingField = tester.widget<CupertinoTextField>(
      find.byKey(const Key('pokedex-learnset-starting-field')),
    );
    expect(startingField.controller!.text, 'tackle\nvine_whip');
    expect(find.text('Vine Whip • vine_whip'), findsWidgets);
  });

  testWidgets(
      'adds a structured TM entry through assisted move selection and save',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final store = _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        'bulbasaur': _buildDetail(
          id: 'bulbasaur',
          learnset: const PokemonLearnsetFile(
            speciesId: 'bulbasaur',
            startingMoves: <String>['tackle'],
          ),
        ),
      },
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        learnsetSaver: store.saveLearnset,
        metadataSaver: store.saveMetadata,
        formsClassificationSaver: store.saveFormsClassification,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
        movesCatalogLoader: (_) async => _movesCatalogView(),
        movesCatalogPreviewer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: true,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
        movesCatalogSyncer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: false,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-learnset-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-tm-search-field')),
      'protect',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-learnset-tm-suggestion-protect')),
    );
    await tester.tap(
      find.byKey(const Key('pokedex-learnset-tm-suggestion-protect')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-tm-version-group')),
      'scarlet-violet',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-learnset-tm-add-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-save-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-save-learnset-button')));
    await tester.pumpAndSettle();

    expect(store.learnsetSaveCallCount, 1);
    expect(store.learnsetById('bulbasaur')?.tm.single.moveId, 'protect');
    expect(
      store.learnsetById('bulbasaur')?.tm.single.versionGroup,
      'scarlet-violet',
    );
  });

  testWidgets('keeps legacy moves visible and flags them as missing locally',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final store = _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        'bulbasaur': _buildDetail(
          id: 'bulbasaur',
          learnset: const PokemonLearnsetFile(
            speciesId: 'bulbasaur',
            startingMoves: <String>['legacy_move'],
          ),
        ),
      },
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        learnsetSaver: store.saveLearnset,
        metadataSaver: store.saveMetadata,
        formsClassificationSaver: store.saveFormsClassification,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
        movesCatalogLoader: (_) async => _movesCatalogView(),
        movesCatalogPreviewer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: true,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
        movesCatalogSyncer: (_) async => const PokemonMovesCatalogSyncResult(
          dryRun: false,
          externalEntryCount: 0,
          createdIds: <String>[],
          updatedIds: <String>[],
          unchangedIds: <String>[],
          preservedLocalOnlyIds: <String>[],
          resultingEntryCount: 4,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-learnset-button')));
    await tester.pumpAndSettle();

    expect(find.text('legacy_move'), findsWidgets);
    expect(find.text('Absent du catalogue local'), findsWidgets);
  });
}

class _FakePokedexWorkspaceStore {
  _FakePokedexWorkspaceStore({
    required Map<String, PokedexSpeciesDetail> detailsById,
  }) : _detailsById = Map<String, PokedexSpeciesDetail>.from(detailsById);

  final Map<String, PokedexSpeciesDetail> _detailsById;

  int learnsetSaveCallCount = 0;

  Future<List<PokemonDatabaseIndexEntry>> loadEntries(
    ProjectWorkspace workspace,
  ) async {
    return _detailsById.values
        .map(
          (detail) => PokemonDatabaseIndexEntry(
            id: detail.species.id,
            nationalDex: detail.species.nationalDex,
            primaryName: detail.species.names['en'] ?? detail.species.id,
            genIntroduced: detail.species.genIntroduced,
            types: detail.species.typing.types,
            isEnabledInProject:
                detail.species.classification.isEnabledInProject,
            refs: PokemonDatabaseIndexRefs(
              learnset: detail.species.refs.learnset,
              evolution: detail.species.refs.evolution,
              media: detail.species.refs.media,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<PokedexSpeciesDetail> loadDetail(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    return _detailsById[speciesId]!;
  }

  Future<PokemonSpeciesFile> saveMetadata(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    return _detailsById[request.speciesId]!.species;
  }

  Future<PokemonSpeciesFile> saveFormsClassification(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    return _detailsById[request.speciesId]!.species;
  }

  Future<PokemonLearnsetFile> saveLearnset(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    learnsetSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updated = PokemonLearnsetFile(
      speciesId: current.species.refs.learnset,
      startingMoves: request.startingMoves,
      relearnMoves: request.relearnMoves,
      levelUp: request.levelUp,
      tm: request.tm,
      tutor: request.tutor,
      egg: request.egg,
      event: request.event,
      transfer: request.transfer,
    );
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: updated,
      evolution: current.evolution,
      media: current.media,
    );
    return updated;
  }

  Future<PokemonEvolutionFile> saveEvolution(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    return _detailsById[request.speciesId]!.evolution!;
  }

  Future<PokemonMediaFile> saveMedia(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    return _detailsById[request.speciesId]!.media!;
  }

  PokemonLearnsetFile? learnsetById(String speciesId) {
    return _detailsById[speciesId]?.learnset;
  }
}

PokedexSpeciesDetail _buildDetail({
  required String id,
  required PokemonLearnsetFile learnset,
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: id,
      slug: id,
      nationalDex: 1,
      names: const <String, String>{'fr': 'Bulbizarre', 'en': 'Bulbasaur'},
      speciesName: const <String, String>{
        'fr': 'Pokémon Graine',
        'en': 'Seed Pokemon',
      },
      genIntroduced: 1,
      typing: const PokemonSpeciesTyping(types: <String>['grass', 'poison']),
      baseStats: const PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: const PokemonSpeciesAbilities(primary: 'overgrow'),
      breeding: const PokemonSpeciesBreeding(
        genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
        eggGroups: <String>['monster', 'grass'],
        hatchCycles: 20,
      ),
      progression: const PokemonSpeciesProgression(
        growthRateId: 'medium_slow',
        baseExp: 64,
        catchRate: 45,
        baseFriendship: 50,
      ),
      forms: PokemonSpeciesForms(
        baseFormId: id,
        isBaseForm: true,
        formId: 'base',
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
        color: 'green',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(
        starterEligible: true,
      ),
      sourceMeta: const PokemonSpeciesSourceMeta(
        seededBy: 'ui-test',
        seedVersion: 1,
      ),
    ),
    learnset: learnset,
    evolution: const PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: const PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
    ),
  );
}

PokemonMovesCatalogView _movesCatalogView() {
  return const PokemonMovesCatalogView(
    isAvailable: true,
    description: 'Catalogue local des attaques pour les tests UI.',
    entries: <PokemonMoveCatalogEntryView>[
      PokemonMoveCatalogEntryView(
        id: 'growl',
        name: 'Growl',
        type: 'normal',
        category: 'status',
        pp: 40,
      ),
      PokemonMoveCatalogEntryView(
        id: 'protect',
        name: 'Protect',
        type: 'normal',
        category: 'status',
        pp: 10,
      ),
      PokemonMoveCatalogEntryView(
        id: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: 'physical',
        power: 40,
        accuracy: 100,
        pp: 35,
      ),
      PokemonMoveCatalogEntryView(
        id: 'vine_whip',
        name: 'Vine Whip',
        type: 'grass',
        category: 'physical',
        power: 45,
        accuracy: 100,
        pp: 25,
      ),
    ],
  );
}
