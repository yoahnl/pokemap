import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/trainer_library_panel.dart';

void main() {
  Future<void> pumpTrainerPanel(
    WidgetTester tester,
    ProviderContainer container, {
    bool embedded = false,
  }) async {
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
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: embedded ? 420 : 1280,
                height: 1800,
                child: embedded
                    ? const TrainerLibraryPanel(embedded: true)
                    : const TrainerLibraryPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settleTrainerUi(WidgetTester tester) async {
    // The macOS-styled surface keeps a few short implicit animations alive.
    // A bounded settle loop is enough for this panel and avoids tests hanging
    // forever when a real workspace path introduces extra async churn.
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openTrainerDropdown(
    WidgetTester tester,
    String keyPrefix,
  ) async {
    final button = find.byKey(Key('$keyPrefix-dropdown-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await settleTrainerUi(tester);
    expect(find.byKey(Key('$keyPrefix-dropdown-menu')), findsOneWidget);
  }

  Future<void> filterTrainerDropdown(
    WidgetTester tester,
    String keyPrefix,
    String query,
  ) async {
    final searchField = find.byKey(Key('$keyPrefix-search-field'));
    if (searchField.evaluate().isEmpty) {
      await openTrainerDropdown(tester, keyPrefix);
    }
    await tester.enterText(find.byKey(Key('$keyPrefix-search-field')), query);
    await settleTrainerUi(tester);
  }

  Future<void> selectTrainerDropdownSuggestion(
    WidgetTester tester,
    String keyPrefix,
    String id, {
    String? query,
  }) async {
    if (query != null) {
      await filterTrainerDropdown(tester, keyPrefix, query);
    } else {
      final menu = find.byKey(Key('$keyPrefix-dropdown-menu'));
      if (menu.evaluate().isEmpty) {
        await openTrainerDropdown(tester, keyPrefix);
      }
    }
    await tester.tap(find.byKey(Key('$keyPrefix-suggestion-$id')));
    await settleTrainerUi(tester);
  }

  Future<void> selectTrainerLevel(
    WidgetTester tester,
    int level,
  ) async {
    final popup = find.byKey(
      const Key('trainer-library-pokemon-level-popup'),
    );
    await tester.ensureVisible(popup);
    await tester.tap(popup);
    await settleTrainerUi(tester);

    final option = find.byKey(
      Key('trainer-library-pokemon-level-option-$level'),
    );
    expect(option, findsWidgets);
    await tester.tap(option.last);
    await settleTrainerUi(tester);
  }

  Future<void> selectTrainerGender(
    WidgetTester tester,
    String gender,
  ) async {
    final option = find.byKey(
      Key('trainer-library-pokemon-gender-option-$gender'),
    );
    await tester.ensureVisible(option);
    await tester.tap(option);
    await settleTrainerUi(tester);
  }

  testWidgets('embedded mode acts as a launcher for the main Trainer Studio',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_embedded',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_embedded',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container, embedded: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('trainer-library-open-studio-button')),
        findsOneWidget);
    expect(find.byKey(const Key('trainer-library-new-trainer-button')),
        findsNothing);
    expect(find.text('Trainer Studio'), findsWidgets);

    await tester
        .tap(find.byKey(const Key('trainer-library-open-studio-button')));
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.trainer,
    );
    expect(
      container.read(editorNotifierProvider).selectedTrainerId,
      'misty',
    );
  });

  testWidgets(
      'creates a trainer and saves a complete team entry with assisted refs',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-new-trainer-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-create-name-field')),
      'Misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-class-field')),
      'Gym Leader',
    );
    await tester.tap(find.text('Show optional references'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-battle-theme-field')),
      'battle_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-victory-theme-field')),
      'victory_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-tags-field')),
      ' rival, gym ',
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final trainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(trainer.name, 'Misty');
    expect(trainer.battleDifficulty, isNull);
    expect(trainer.battleThemeId, 'battle_misty');
    expect(trainer.victoryThemeId, 'victory_misty');
    expect(trainer.tags, <String>['rival', 'gym']);

    await tester.tap(
      find.byKey(Key('trainer-library-add-pokemon-button-${trainer.id}')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      findsNothing,
    );
    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );

    await selectTrainerLevel(tester, 12);
    await selectTrainerGender(tester, 'female');

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-move-0',
      'tackle',
      query: 'tackle',
    );

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-move-1',
      'growl',
      query: 'growl',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-dropdown-button')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-item',
      'oran_berry',
      query: 'oran',
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-form-suggestion-blossom'),
      ),
    );
    await tester.pumpAndSettle();

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await settleTrainerUi(tester);
    tester.widget<CupertinoButton>(savePokemonButton).onPressed!.call();
    await settleTrainerUi(tester);

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 12);
    expect(pokemon.moves, <String>['tackle', 'growl']);
    expect(pokemon.heldItemId, 'oran_berry');
    expect(pokemon.formId, 'blossom');
    expect(pokemon.gender, 'female');
    expect(pokemon.shiny, isFalse);
    expect(
      find.byKey(Key('trainer-library-pokemon-row-${trainer.id}-0')),
      findsOneWidget,
    );
  });

  testWidgets(
      'trainer difficulty authoring stays in fallback until the slider is actually used',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_difficulty_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_difficulty_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);

    await tester.tap(
      find.byKey(const Key('trainer-library-new-trainer-button')),
    );
    await settleTrainerUi(tester);

    expect(find.text('Battle difficulty · legacy fallback'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('trainer-library-create-name-field')),
      'Brock',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-class-field')),
      'Gym Leader',
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    var trainer = container.read(editorNotifierProvider).project!.trainers.single;
    expect(trainer.battleDifficulty, isNull);

    await tester.tap(find.text('Edit').first);
    await settleTrainerUi(tester);

    final slider = tester.widget<CupertinoSlider>(
      find.byKey(const Key('trainer-library-edit-difficulty-slider')),
    );
    slider.onChanged!(7);
    await settleTrainerUi(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    trainer = container.read(editorNotifierProvider).project!.trainers.single;
    expect(trainer.battleDifficulty, 7);

    await tester.tap(find.text('Edit').first);
    await settleTrainerUi(tester);
    await tester.tap(
      find.byKey(const Key('trainer-library-edit-difficulty-clear-button')),
    );
    await settleTrainerUi(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    trainer = container.read(editorNotifierProvider).project!.trainers.single;
    expect(trainer.battleDifficulty, isNull);
  });

  testWidgets(
      'shows trainer difficulty and background authoring controls in the editor',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(_FakeProjectRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainer_picker_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'mira',
            name: 'Mira',
            trainerClass: 'Rookie',
            battleDifficulty: 6,
            battleBackgroundRelativePath: 'assets/battle_backgrounds/mira.png',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);

    expect(find.textContaining('AI 6'), findsOneWidget);

    await tester.tap(find.text('Edit').first);
    await settleTrainerUi(tester);

    expect(
      find.byKey(const Key('trainer-library-edit-difficulty-slider')),
      findsOneWidget,
    );

    await tester.tap(find.text('Show optional references'));
    await settleTrainerUi(tester);

    expect(
      find.text('assets/battle_backgrounds/mira.png'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-edit-background-pick-button')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('trainer-library-edit-background-clear-button')),
    );
    await settleTrainerUi(tester);
    expect(
      find.text('No explicit trainer background selected.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps the active species selection stable while the dropdown search changes',
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
          (_) async => const <PokemonDatabaseIndexEntry>[
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
              id: 'caterpie',
              nationalDex: 10,
              primaryName: 'Caterpie',
              genIntroduced: 1,
              types: <String>['bug'],
              isEnabledInProject: true,
              refs: PokemonDatabaseIndexRefs(
                learnset: 'caterpie',
                evolution: 'caterpie',
                media: 'caterpie',
              ),
            ),
          ],
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await settleTrainerUi(tester);

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'caterpie',
      query: 'cater',
    );

    expect(
      find.byKey(const Key('trainer-library-pokemon-selected-species-status')),
      findsOneWidget,
    );
    expect(find.textContaining('Selected species: Caterpie'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const Key('trainer-library-pokemon-species-dropdown-button'),
        ),
        matching: find.text('Caterpie'),
      ),
      findsOneWidget,
    );

    await openTrainerDropdown(tester, 'trainer-library-pokemon-species');
    await filterTrainerDropdown(
      tester,
      'trainer-library-pokemon-species',
      'pikachu',
    );

    expect(
      find.byKey(const Key('trainer-library-pokemon-species-search-empty')),
      findsOneWidget,
    );
    expect(
      find.text('No local species match this search.'),
      findsOneWidget,
    );
    expect(find.textContaining('Selected species: Caterpie'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-close-button'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Selected species: Caterpie'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-clear-button'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No species selected yet.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const Key('trainer-library-pokemon-species-dropdown-button'),
        ),
        matching: find.text('Select a Pokémon species'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows guided move suggestions from the selected learnset and level',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );

    await selectTrainerLevel(tester, 12);

    expect(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-field')),
      findsNothing,
    );
    await filterTrainerDropdown(
      tester,
      'trainer-library-pokemon-move-0',
      'vine',
    );

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-vine_whip'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Lv.7'), findsWidgets);

    await filterTrainerDropdown(
      tester,
      'trainer-library-pokemon-move-0',
      'razor',
    );

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-razor_leaf'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-empty')),
      findsOneWidget,
    );
  });

  testWidgets('shows inline validation when a move is unknown locally',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );
    await selectTrainerLevel(tester, 10);
    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await settleTrainerUi(tester);
    tester.widget<CupertinoButton>(savePokemonButton).onPressed!.call();
    await settleTrainerUi(tester);

    expect(
      find.text('Move 1 references an unknown local move: missing_move'),
      findsOneWidget,
    );
    expect(
      container.read(editorNotifierProvider).project!.trainers.single.team,
      isEmpty,
    );
  });

  testWidgets(
      'blocks duplicate moves in both guided selection and raw fallback save',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await settleTrainerUi(tester);

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );
    await selectTrainerLevel(tester, 12);
    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-move-0',
      'tackle',
      query: 'tackle',
    );

    await filterTrainerDropdown(
      tester,
      'trainer-library-pokemon-move-1',
      'tackle',
    );
    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-1-search-empty'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-move-1-close-button'),
      ),
    );
    await settleTrainerUi(tester);

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-1-field')),
      'TACKLE',
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await settleTrainerUi(tester);
    tester.widget<CupertinoButton>(savePokemonButton).onPressed!.call();
    await settleTrainerUi(tester);

    expect(
      find.text('Move 2 duplicates another selected move: TACKLE'),
      findsOneWidget,
    );
    expect(
      container.read(editorNotifierProvider).project!.trainers.single.team,
      isEmpty,
    );
  });

  testWidgets(
      'does not invent a base form suggestion when the local species detail has none',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(
                  forms: const PokemonSpeciesForms(
                    baseFormId: 'bulbasaur',
                    isBaseForm: true,
                    formId: '',
                    otherForms: <String>[],
                  ),
                )
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );

    await tester.scrollUntilVisible(
      find.text(
        'No local form suggestion is available for this species. The raw fallback remains available.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No local form suggestion is available for this species. The raw fallback remains available.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-form-suggestion-base')),
      findsNothing,
    );
  });

  testWidgets(
      'shows a dedicated genderless choice when the selected species has no gender',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(
                  breeding: const PokemonSpeciesBreeding(
                    genderRatio: <String, double>{'genderless': 1.0},
                    eggGroups: <String>['undiscovered'],
                    hatchCycles: 120,
                  ),
                )
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await settleTrainerUi(tester);

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-gender-option-genderless'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-gender-option-male')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-gender-option-female')),
      findsNothing,
    );
    expect(
      find.text('This species is genderless in the local Pokédex.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps species and form messaging honest when local species assistance is unavailable',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, __) async => throw StateError('detail loader exploded'),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
        'Impossible de charger les espèces locales. La saisie brute reste possible.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-field')),
      'bulbasaur',
    );
    await selectTrainerLevel(tester, 10);
    await tester.scrollUntilVisible(
      find.text(
        'Unable to verify local forms for this species right now. The raw fallback remains available.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to verify local forms for this species right now. The raw fallback remains available.',
      ),
      findsOneWidget,
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await tester.pumpAndSettle();
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(savedTrainer.team.single.speciesId, 'bulbasaur');

    await tester.scrollUntilVisible(
      find.text(
        'Local species index unavailable. The raw value is kept as-is.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-detail-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Local species index unavailable. The raw value is kept as-is.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps the trainer surface usable when moves and items lookups fail unexpectedly',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => throw StateError('moves loader exploded'),
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogError: StateError('items loader exploded'),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
        'Unable to load the local move data for this project.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Unable to load the local item data for this project.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );
    await selectTrainerLevel(tester, 10);
    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      'mystery_item',
    );

    final savePokemonButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('trainer-library-pokemon-save-button')),
    );
    savePokemonButton.onPressed!.call();
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 10);
    expect(pokemon.moves, <String>['missing_move']);
    expect(pokemon.heldItemId, 'mystery_item');
  });

  testWidgets(
      'keeps raw move fallback available when the local learnset is unavailable',
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
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(learnset: null)
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await selectTrainerDropdownSuggestion(
      tester,
      'trainer-library-pokemon-species',
      'bulbasaur',
      query: 'bulba',
    );
    await selectTrainerLevel(tester, 12);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No local learnset is available for this species. Guided move suggestions are unavailable, but raw IDs stay possible.',
      ),
      findsWidgets,
    );

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'tackle',
    );

    final savePokemonButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('trainer-library-pokemon-save-button')),
    );
    savePokemonButton.onPressed!.call();
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(savedTrainer.team.single.moves, <String>['tackle']);
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
];

const PokemonMovesCatalogView _movesCatalogView = PokemonMovesCatalogView(
  entries: <PokemonMoveCatalogEntryView>[
    PokemonMoveCatalogEntryView(
      id: 'growl',
      name: 'Growl',
      type: 'normal',
      category: 'status',
      pp: 40,
    ),
    PokemonMoveCatalogEntryView(
      id: 'tackle',
      name: 'Tackle',
      type: 'normal',
      category: 'physical',
      power: 40,
      pp: 35,
    ),
    PokemonMoveCatalogEntryView(
      id: 'vine_whip',
      name: 'Vine Whip',
      type: 'grass',
      category: 'physical',
      power: 45,
      pp: 25,
    ),
    PokemonMoveCatalogEntryView(
      id: 'razor_leaf',
      name: 'Razor Leaf',
      type: 'grass',
      category: 'physical',
      power: 55,
      pp: 25,
    ),
  ],
  isAvailable: true,
  description: 'Catalogue local des attaques.',
);

const PokemonCatalogFile _itemsCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'items',
  meta: PokemonDataMeta(description: 'Catalogue local des objets.'),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'oran_berry',
      'name': 'Oran Berry',
      'aliases': <String>['oran'],
    },
  ],
);

final Map<String, PokedexSpeciesDetail> _detailsById =
    <String, PokedexSpeciesDetail>{
  'bulbasaur': _buildDetail(),
};

PokedexSpeciesDetail _buildDetail({
  PokemonSpeciesForms forms = const PokemonSpeciesForms(
    baseFormId: 'bulbasaur',
    isBaseForm: true,
    formId: 'base',
    otherForms: <String>['blossom'],
  ),
  PokemonLearnsetFile? learnset = const PokemonLearnsetFile(
    speciesId: 'bulbasaur',
    startingMoves: <String>['tackle'],
    relearnMoves: <String>['growl'],
    levelUp: <PokemonLearnsetLevelUpEntry>[
      PokemonLearnsetLevelUpEntry(
        moveId: 'vine_whip',
        level: 7,
        source: 'level-up',
        versionGroup: 'project',
      ),
      PokemonLearnsetLevelUpEntry(
        moveId: 'razor_leaf',
        level: 20,
        source: 'level-up',
        versionGroup: 'project',
      ),
    ],
  ),
  PokemonSpeciesBreeding breeding = const PokemonSpeciesBreeding(
    genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
    eggGroups: <String>['monster', 'grass'],
    hatchCycles: 20,
  ),
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: 'bulbasaur',
      slug: 'bulbasaur',
      nationalDex: 1,
      names: <String, String>{'en': 'Bulbasaur'},
      speciesName: <String, String>{'en': 'Seed Pokemon'},
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
      breeding: breeding,
      progression: const PokemonSpeciesProgression(
        growthRateId: 'medium_slow',
        baseExp: 64,
        catchRate: 45,
        baseFriendship: 50,
      ),
      forms: forms,
      classification: const PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: const PokemonSpeciesRefs(
        learnset: 'bulbasaur',
        evolution: 'bulbasaur',
        media: 'bulbasaur',
      ),
      dexContent: const PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'green',
        flavorText: 'A strange seed was planted on its back at birth.',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(starterEligible: true),
      sourceMeta:
          const PokemonSpeciesSourceMeta(seededBy: 'test', seedVersion: 1),
    ),
    learnset: learnset,
    evolution: const PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: const PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
      variants: <String, PokemonMediaVariant>{},
    ),
  );
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    lastSavedProject = project;
  }
}

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory(this.workspace);

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRoot) => workspace;
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  static const String projectRootValue = '/tmp';

  @override
  String get projectManifestPath => '$projectRootValue/project.json';

  @override
  String get projectRoot => projectRootValue;

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
  String getMapPath(String mapId) => '$projectRootValue/$mapId.json';

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
  String resolveMapPath(String relativePath) =>
      '$projectRootValue/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRootValue/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) =>
      '$projectRootValue/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

class _FakePokemonReadRepository implements PokemonReadRepository {
  _FakePokemonReadRepository({
    this.catalogByKey = const <String, PokemonCatalogFile>{},
    this.catalogError,
  });

  final Map<String, PokemonCatalogFile> catalogByKey;
  final Object? catalogError;

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    if (catalogError != null) {
      throw catalogError!;
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
