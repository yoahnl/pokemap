import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_external_query_resolution.dart';
import 'package:map_editor/src/application/models/pokemon_external_species_search_result.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';

void main() {
  const sampleProject = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
    name: 'pokedex_external_autocomplete_test',
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

  PokedexWorkspace buildWorkspace({
    required Future<PokemonExternalSpeciesSearchResult> Function(
            String rawQuery)
        externalSpeciesSearcher,
  }) {
    return PokedexWorkspace(
      loader: (_) async => const <PokemonDatabaseIndexEntry>[],
      detailLoader: (_, __) async => _unusedDetail(),
      importPreviewer: (_, __) async => throw UnimplementedError(),
      importer: (_, __) async => throw UnimplementedError(),
      externalSpeciesSearcher: externalSpeciesSearcher,
      externalImportPreviewer: (_, __) async => throw UnimplementedError(),
      externalImporter: (_, __) async => throw UnimplementedError(),
    );
  }

  testWidgets('shows loading then allows keyboard selection of a suggestion',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final completer = Completer<PokemonExternalSpeciesSearchResult>();

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_autocomplete_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalSpeciesSearcher: (_) => completer.future,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      '25',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const Key('pokedex-import-external-search-loading')),
      findsOneWidget,
    );

    completer.complete(
      const PokemonExternalSpeciesSearchResult.suggestions(
        rawQuery: '25',
        normalizedQuery: '25',
        resolution: PokemonExternalSingleQueryResolution(
          rawQuery: '25',
          normalizedQuery: '25',
          query: PokemonExternalSingleQuery.nationalDex(
            rawValue: '25',
            nationalDex: 25,
          ),
        ),
        suggestions: <PokemonExternalSpeciesSuggestion>[
          PokemonExternalSpeciesSuggestion(
            speciesId: 'pikachu',
            primaryName: 'Pikachu',
            nationalDex: 25,
            generation: 1,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-import-external-suggestion-pikachu')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-import-external-selected-suggestion')),
      findsOneWidget,
    );
  });

  testWidgets('shows a clean no-result state', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_autocomplete_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalSpeciesSearcher: (rawQuery) async =>
            PokemonExternalSpeciesSearchResult.noResults(
          rawQuery: rawQuery,
          normalizedQuery: rawQuery.trim(),
          resolution: const PokemonExternalSingleQueryResolution(
            rawQuery: 'bulbasaur',
            normalizedQuery: 'bulbasaur',
            query: PokemonExternalSingleQuery.species(
              rawValue: 'bulbasaur',
              normalizedValue: 'bulbasaur',
            ),
          ),
          message:
              'Aucun Pokémon externe trouvé pour cette requête mono-espèce.',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      'bulbasaur',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const Key('pokedex-import-external-search-message')),
      findsOneWidget,
    );
    expect(
      find.text('Aucun Pokémon externe trouvé pour cette requête mono-espèce.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a clean out-of-scope message for generation queries',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_autocomplete_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalSpeciesSearcher: (rawQuery) async =>
            const PokemonExternalSpeciesSearchResult.outOfScopeQuery(
          rawQuery: 'gen 1',
          normalizedQuery: 'gen 1',
          resolution: PokemonExternalGenerationQueryResolution(
            rawQuery: 'gen 1',
            normalizedQuery: 'gen 1',
            generation: 1,
          ),
          message:
              'Cette étape mono-espèce ne gère pas encore les imports par génération.',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      'gen 1',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.text(
        'Cette étape mono-espèce ne gère pas encore les imports par génération.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a clean invalid message for ambiguous queries',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_autocomplete_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalSpeciesSearcher: (rawQuery) async =>
            const PokemonExternalSpeciesSearchResult.invalidQuery(
          rawQuery: 'pikachu eevee abra',
          normalizedQuery: 'pikachu eevee abra',
          resolution: PokemonExternalInvalidQueryResolution(
            rawQuery: 'pikachu eevee abra',
            normalizedQuery: 'pikachu eevee abra',
            code: PokemonExternalInvalidQueryCode
                .ambiguousWhitespaceSeparatedTerms,
            message:
                'La requête contient plusieurs termes séparés par des espaces. Utilisez des virgules pour une liste explicite.',
          ),
          message:
              'La requête contient plusieurs termes séparés par des espaces. Utilisez des virgules pour une liste explicite.',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      'pikachu eevee abra',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.textContaining('Utilisez des virgules pour une liste explicite'),
      findsOneWidget,
    );
  });
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
