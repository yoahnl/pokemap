import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/design_system/pokemap_dropdown_field.dart';
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
            home: Material(
              child: CupertinoPageScaffold(
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

  Future<void> pressCupertinoButtonWithText(
    WidgetTester tester,
    String label,
  ) async {
    final text = find.text(label);
    await tester.ensureVisible(text);
    tester
        .widget<CupertinoButton>(
          find.ancestor(of: text, matching: find.byType(CupertinoButton)),
        )
        .onPressed!
        .call();
    await settleTrainerUi(tester);
  }

  Future<void> openTrainerEditor(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Modifier'),
      -400,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-detail-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await settleTrainerUi(tester);
    await tester.tap(find.text('Modifier').first);
    await settleTrainerUi(tester);
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

  Future<void> selectTrainerLevel(WidgetTester tester, int level) async {
    final popup = find.byKey(const Key('trainer-library-pokemon-level-popup'));
    await tester.ensureVisible(popup);
    final widget = tester.widget<MacosPopupButton<int>>(popup);
    expect(widget.items.map((item) => item.value), contains(level));
    widget.onChanged?.call(level);
    await settleTrainerUi(tester);
  }

  Future<void> selectTrainerGender(WidgetTester tester, String gender) async {
    final option = find.byKey(
      Key('trainer-library-pokemon-gender-option-$gender'),
    );
    await tester.ensureVisible(option);
    await tester.tap(option);
    await settleTrainerUi(tester);
  }

  testWidgets('embedded mode opens the trainer section of Encounter Studio', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_embedded',
      project: ProjectManifest(
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

    expect(
      find.byKey(const Key('trainer-library-open-studio-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-new-trainer-button')),
      findsNothing,
    );
    expect(find.text('Dresseurs'), findsWidgets);

    await tester.tap(
      find.byKey(const Key('trainer-library-open-studio-button')),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.encounter,
    );
    expect(
      container.read(editorNotifierProvider).encounterStudioSection,
      EncounterStudioSection.trainers,
    );
    expect(container.read(editorNotifierProvider).selectedTrainerId, 'misty');
  });

  testWidgets(
    'creates a trainer and saves a complete team entry with assisted refs',
    (tester) async {
      final repository = _FakeProjectRepository();
      const workspace = _FakeWorkspace();
      final itemCatalog = await const LoadPokemonItemsCatalogUseCase().execute(workspace);
      expect(itemCatalog.isAvailable, isTrue, reason: itemCatalog.message);
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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_test',
        project: ProjectManifest(
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
      await pressCupertinoButtonWithText(
        tester,
        'Afficher les références optionnelles',
      );
      await tester.enterText(
        find.byKey(const Key('trainer-library-create-battle-music-field')),
        'battle_misty',
      );
      await tester.enterText(
        find.byKey(const Key('trainer-library-create-victory-music-field')),
        'victory_misty',
      );
      await tester.enterText(
        find.byKey(const Key('trainer-library-create-tags-field')),
        ' rival, gym ',
      );

      await pressCupertinoButtonWithText(tester, 'Créer');

      final trainer = container
          .read(editorNotifierProvider)
          .project!
          .trainers
          .single;
      expect(trainer.name, 'Misty');
      expect(trainer.battleDifficulty, isNull);
      expect(trainer.battleMusicPath, 'battle_misty');
      expect(trainer.victoryMusicPath, 'victory_misty');
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
      final heldItemPicker = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(const Key('trainer-library-pokemon-item-dropdown-button')),
      );
      expect(heldItemPicker.items.map((item) => item.label), <String>[
        'Aucun objet',
        'Leftovers',
      ]);
      heldItemPicker.onChanged('leftovers');
      await tester.pumpAndSettle();
      final ballPicker = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(const Key('trainer-library-pokemon-ball-dropdown-button')),
      );
      expect(ballPicker.items.map((item) => item.label), <String>[
        'Aucune Ball',
        'Orbe lunaire',
      ]);
      expect(ballPicker.value, '');
      ballPicker.onChanged('lunar_orb');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('trainer-library-pokemon-form-suggestion-blossom'),
        ),
      );
      await tester.pumpAndSettle();

      final savePokemonButton = find.byKey(
        const Key('trainer-library-pokemon-save-button'),
      );
      await tester.ensureVisible(savePokemonButton);
      await settleTrainerUi(tester);
      tester.widget<CupertinoButton>(savePokemonButton).onPressed!.call();
      await settleTrainerUi(tester);

      final savedTrainer = container
          .read(editorNotifierProvider)
          .project!
          .trainers
          .single;
      final pokemon = savedTrainer.team.single;
      expect(pokemon.speciesId, 'bulbasaur');
      expect(pokemon.level, 12);
      expect(pokemon.moves, <String>['tackle', 'growl']);
      expect(pokemon.heldItemId, 'leftovers');
      expect(pokemon.toJson()['ballItemId'], 'lunar_orb');
      expect(pokemon.formId, 'blossom');
      expect(pokemon.gender, 'female');
      expect(pokemon.shiny, isFalse);
      expect(pokemon.natureId, isNull);
      expect(pokemon.ivs, isNull);
      expect(pokemon.evs, isNull);
      final pokemonRow = find.byKey(Key('trainer-library-pokemon-row-${trainer.id}-0'));
      tester.widget<CupertinoButton>(
        find.descendant(of: pokemonRow, matching: find.byType(CupertinoButton)).first,
      ).onPressed!.call();
      await settleTrainerUi(tester);
      final existingBallPicker = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(const Key('trainer-library-pokemon-ball-dropdown-button')),
      );
      expect(existingBallPicker.value, 'lunar_orb');
      existingBallPicker.onChanged('');
      await settleTrainerUi(tester);
      tester.widget<CupertinoButton>(savePokemonButton).onPressed!.call();
      await settleTrainerUi(tester);
      final cleared = container.read(editorNotifierProvider).project!.trainers.single.team.single;
      expect(cleared.ballItemId, isNull);
      expect(cleared.heldItemId, 'leftovers');
      expect(
        find.byKey(Key('trainer-library-pokemon-row-${trainer.id}-0')),
        findsOneWidget,
      );
    },
  );

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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_difficulty_test',
        project: ProjectManifest(
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

      expect(
        find.text('Difficulté de combat · valeur par défaut'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('trainer-library-create-name-field')),
        'Brock',
      );
      await tester.enterText(
        find.byKey(const Key('trainer-library-create-class-field')),
        'Gym Leader',
      );

      await pressCupertinoButtonWithText(tester, 'Créer');

      var trainer = container
          .read(editorNotifierProvider)
          .project!
          .trainers
          .single;
      expect(trainer.battleDifficulty, isNull);

      await openTrainerEditor(tester);

      final slider = tester.widget<CupertinoSlider>(
        find.byKey(const Key('trainer-library-edit-difficulty-slider')),
      );
      slider.onChanged!(7);
      await settleTrainerUi(tester);
      await pressCupertinoButtonWithText(tester, 'Enregistrer');

      trainer = container.read(editorNotifierProvider).project!.trainers.single;
      expect(trainer.battleDifficulty, 7);

      await openTrainerEditor(tester);
      await tester.tap(
        find.byKey(const Key('trainer-library-edit-difficulty-clear-button')),
      );
      await settleTrainerUi(tester);
      await pressCupertinoButtonWithText(tester, 'Enregistrer');

      trainer = container.read(editorNotifierProvider).project!.trainers.single;
      expect(trainer.battleDifficulty, isNull);
    },
  );

  testWidgets('authors individual trainer stats with strict raw drafts', (
    tester,
  ) async {
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
          (_, id) async => _detailsById[id]!,
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = const EditorState(
      projectRootPath: '/tmp/trainers_stats_test',
      project: ProjectManifest(
        name: 'Stats',
        maps: [],
        tilesets: [],
        trainers: [
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Leader',
            team: [
              ProjectTrainerPokemonEntry(
                speciesId: 'bulbasaur',
                level: 50,
                moves: ['tackle'],
                shiny: true,
              ),
            ],
          ),
        ],
      ),
    );
    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);
    final row = find.byKey(const Key('trainer-library-pokemon-row-misty-0'));
    tester
        .widget<CupertinoButton>(
          find
              .descendant(of: row, matching: find.byType(CupertinoButton))
              .first,
        )
        .onPressed!();
    await settleTrainerUi(tester);
    final mode = find.byKey(const Key('trainer-library-pokemon-stats-mode'));
    expect(mode, findsOneWidget);
    expect(tester.widget<PokeMapDropdownField<String>>(mode).value, 'standard');
    tester.widget<PokeMapDropdownField<String>>(mode).onChanged('advanced');
    await settleTrainerUi(tester);
    final nature = tester.widget<PokeMapDropdownField<String>>(
      find.byKey(const Key('trainer-library-pokemon-nature')),
    );
    for (final group in ['ivs', 'evs']) {
      for (final stat in trainerPokemonStatKeys) {
        final field = find.byKey(Key('trainer-library-pokemon-$group-$stat'));
        await tester.ensureVisible(field);
        await settleTrainerUi(tester);
        expect(field.hitTestable(), findsOneWidget);
      }
    }
    for (final key in [
      'trainer-library-pokemon-save-button',
      'trainer-library-pokemon-cancel-button',
    ]) {
      final command = find.byKey(Key(key));
      await tester.ensureVisible(command);
      await settleTrainerUi(tester);
      expect(command.hitTestable(), findsOneWidget);
    }
    expect(nature.items, hasLength(25));
    expect(
      nature.items.firstWhere((value) => value.value == 'adamant').label,
      contains('Attaque +10%'),
    );
    nature.onChanged('adamant');
    await settleTrainerUi(tester);
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('trainer-library-pokemon-preview-attack')),
          )
          .data,
      'Attaque : 67',
    );
    await selectTrainerLevel(tester, 25);
    await settleTrainerUi(tester);
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('trainer-library-pokemon-preview-attack')),
          )
          .data,
      'Attaque : 36',
    );
    await selectTrainerLevel(tester, 50);
    final iv = find.byKey(const Key('trainer-library-pokemon-ivs-attack'));
    await tester.ensureVisible(iv);
    await tester.enterText(iv, '2.5');
    await settleTrainerUi(tester);
    expect(
      find.byKey(const Key('trainer-library-pokemon-stats-preview')),
      findsNothing,
    );
    tester
        .widget<CupertinoButton>(
          find.byKey(const Key('trainer-library-pokemon-save-button')),
        )
        .onPressed!();
    await settleTrainerUi(tester);
    expect(
      notifier.state.project!.trainers.single.team.single.natureId,
      isNull,
    );
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: iv, matching: find.byType(EditableText)),
          )
          .controller
          .text,
      '2.5',
    );
    await tester.enterText(iv, '31');
    await settleTrainerUi(tester);
    expect(
      find.byKey(const Key('trainer-library-pokemon-stats-preview')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('trainer-library-pokemon-preview-attack')),
          )
          .data,
      'Attaque : 75',
    );
    for (final invalid in ['-1', '32', '1.0', 'abc', '0x10', '']) {
      await tester.enterText(iv, invalid);
      await settleTrainerUi(tester);
      expect(
        find.byKey(const Key('trainer-library-pokemon-stats-preview')),
        findsNothing,
      );
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('trainer-library-pokemon-save-button')),
          )
          .onPressed!();
      await settleTrainerUi(tester);
      expect(
        notifier.state.project!.trainers.single.team.single.natureId,
        isNull,
      );
    }
    await tester.enterText(iv, '31');
    Future<void> ev(String stat, String value) async {
      final field = find.byKey(Key('trainer-library-pokemon-evs-$stat'));
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
      await settleTrainerUi(tester);
    }

    for (final invalid in ['2.5', '-1', '253']) {
      await ev('hp', invalid);
      expect(
        find.byKey(const Key('trainer-library-pokemon-stats-preview')),
        findsNothing,
      );
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('trainer-library-pokemon-save-button')),
          )
          .onPressed!();
      await settleTrainerUi(tester);
      expect(
        notifier.state.project!.trainers.single.team.single.natureId,
        isNull,
      );
    }
    await ev('hp', '252');
    await ev('attack', '252');
    await ev('speed', '7');
    expect(find.text('Total EV : 511/510'), findsOneWidget);
    expect(
      find.byKey(const Key('trainer-library-pokemon-stats-preview')),
      findsNothing,
    );
    tester
        .widget<CupertinoButton>(
          find.byKey(const Key('trainer-library-pokemon-save-button')),
        )
        .onPressed!();
    await settleTrainerUi(tester);
    expect(
      notifier.state.project!.trainers.single.team.single.natureId,
      isNull,
    );
    await ev('speed', '6');
    expect(find.text('Total EV : 510/510'), findsOneWidget);
    tester
        .widget<CupertinoButton>(
          find.byKey(const Key('trainer-library-pokemon-save-button')),
        )
        .onPressed!();
    await settleTrainerUi(tester);
    final saved = notifier.state.project!.trainers.single.team.single;
    expect(saved.natureId, 'adamant');
    expect(saved.ivs!.attack, 31);
    expect(saved.evs, const PokemonStatSpread(hp: 252, attack: 252, speed: 6));
    expect(saved.shiny, isTrue);
    Future<void> reopen() async {
      tester
          .widget<CupertinoButton>(
            find
                .descendant(of: row, matching: find.byType(CupertinoButton))
                .first,
          )
          .onPressed!();
      await settleTrainerUi(tester);
    }

    await reopen();
    expect(tester.widget<PokeMapDropdownField<String>>(mode).value, 'advanced');
    await tester.ensureVisible(iv);
    await tester.enterText(iv, 'broken');
    tester
        .widget<CupertinoButton>(
          find.byKey(const Key('trainer-library-pokemon-cancel-button')),
        )
        .onPressed!();
    await settleTrainerUi(tester);
    await reopen();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: iv, matching: find.byType(EditableText)),
          )
          .controller
          .text,
      '31',
    );
    tester.widget<PokeMapDropdownField<String>>(mode).onChanged('standard');
    await settleTrainerUi(tester);
    expect(
      find.byKey(const Key('trainer-library-pokemon-nature')),
      findsNothing,
    );
    tester
        .widget<CupertinoButton>(
          find.byKey(const Key('trainer-library-pokemon-save-button')),
        )
        .onPressed!();
    await settleTrainerUi(tester);
    final standard = notifier.state.project!.trainers.single.team.single;
    expect(standard.natureId, isNull);
    expect(standard.ivs, isNull);
    expect(standard.evs, isNull);
    expect(standard.shiny, isTrue);
  });

  testWidgets(
    'preview hides stale species and teammate deletion keeps the active draft',
    (tester) async {
      final waiting = Completer<PokedexSpeciesDetail>();
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
          pokedexSpeciesDetailLoaderProvider.overrideWithValue((_, id) async {
            if (id == 'waiting') return waiting.future;
            if (id == 'bulbasaur') return _buildDetail();
            throw EditorNotFoundException('Missing $id');
          }),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        projectRootPath: '/tmp/trainers_stats_lifecycle',
        project: ProjectManifest(
          name: 'Stats',
          maps: [],
          tilesets: [],
          trainers: [
            ProjectTrainerEntry(
              id: 'misty',
              name: 'Misty',
              trainerClass: 'Leader',
              team: [
                ProjectTrainerPokemonEntry(
                  speciesId: 'bulbasaur',
                  level: 10,
                  moves: ['tackle'],
                ),
                ProjectTrainerPokemonEntry(
                  speciesId: 'bulbasaur',
                  level: 20,
                  moves: ['tackle'],
                ),
                ProjectTrainerPokemonEntry(
                  speciesId: 'bulbasaur',
                  level: 50,
                  moves: ['tackle'],
                  shiny: true,
                ),
              ],
            ),
          ],
        ),
      );
      await pumpTrainerPanel(tester, container);
      await settleTrainerUi(tester);
      final row = find.byKey(const Key('trainer-library-pokemon-row-misty-2'));
      tester
          .widget<CupertinoButton>(
            find
                .descendant(of: row, matching: find.byType(CupertinoButton))
                .first,
          )
          .onPressed!();
      await settleTrainerUi(tester);
      tester
          .widget<PokeMapDropdownField<String>>(
            find.byKey(const Key('trainer-library-pokemon-stats-mode')),
          )
          .onChanged('advanced');
      await settleTrainerUi(tester);
      final iv = find.byKey(const Key('trainer-library-pokemon-ivs-attack'));
      await tester.ensureVisible(iv);
      await tester.enterText(iv, 'broken');
      tester
          .widget<CupertinoButton>(
            find
                .descendant(
                  of: find.byKey(
                    const Key('trainer-library-pokemon-row-misty-0'),
                  ),
                  matching: find.byType(CupertinoButton),
                )
                .last,
          )
          .onPressed!();
      await settleTrainerUi(tester);
      expect(notifier.state.project!.trainers.single.team, hasLength(2));
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: iv, matching: find.byType(EditableText)),
            )
            .controller
            .text,
        'broken',
      );
      await tester.enterText(iv, '31');
      await settleTrainerUi(tester);
      final toggle = find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      );
      await tester.ensureVisible(toggle);
      await settleTrainerUi(tester);
      await tester.tap(toggle);
      await settleTrainerUi(tester);
      final species = find.byKey(
        const Key('trainer-library-pokemon-species-field'),
      );
      await tester.ensureVisible(species);
      await tester.enterText(species, 'waiting');
      await settleTrainerUi(tester);
      final preview = find.byKey(
        const Key('trainer-library-pokemon-stats-preview'),
      );
      expect(preview, findsNothing);
      final original = _buildDetail().species;
      waiting.complete(
        PokedexSpeciesDetail(
          species: PokemonSpeciesFile.fromJson({
            ...original.toJson(),
            'id': 'waiting',
            'baseStats': {...original.baseStats.toJson(), 'atk': 100},
          }),
        ),
      );
      await settleTrainerUi(tester);
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('trainer-library-pokemon-preview-attack')),
            )
            .data,
        'Attaque : 120',
      );
      await tester.enterText(species, 'missing');
      await settleTrainerUi(tester);
      expect(preview, findsNothing);
      await tester.enterText(species, 'bulbasaur');
      await settleTrainerUi(tester);
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('trainer-library-pokemon-save-button')),
          )
          .onPressed!();
      await settleTrainerUi(tester);
      final saved = notifier.state.project!.trainers.single.team;
      expect(saved.first.level, 20);
      expect(saved.first.ivs, isNull);
      expect(saved.last.level, 50);
      expect(saved.last.ivs!.attack, 31);
      expect(saved.last.shiny, isTrue);
      final editedRow = find.byKey(
        const Key('trainer-library-pokemon-row-misty-1'),
      );
      tester
          .widget<CupertinoButton>(
            find
                .descendant(
                  of: editedRow,
                  matching: find.byType(CupertinoButton),
                )
                .first,
          )
          .onPressed!();
      await settleTrainerUi(tester);
      tester
          .widget<CupertinoButton>(
            find
                .descendant(
                  of: editedRow,
                  matching: find.byType(CupertinoButton),
                )
                .last,
          )
          .onPressed!();
      await settleTrainerUi(tester);
      expect(
        find.byKey(const Key('trainer-library-pokemon-stats-mode')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'authors finite trainer battle stock and preserves invalid drafts',
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
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        projectRootPath: '/tmp/trainers_battle_stock_test',
        project: ProjectManifest(
          name: 'Stock',
          maps: [],
          tilesets: [],
          trainers: [
            ProjectTrainerEntry(
              id: 'misty',
              name: 'Misty',
              trainerClass: 'Leader',
              rewardItemGrants: [
                ProjectTrainerItemGrant(itemId: 'oran_berry', quantity: 7),
              ],
            ),
          ],
        ),
      );
      await pumpTrainerPanel(tester, container);
      await settleTrainerUi(tester);
      await tester.tap(find.text('Modifier').first);
      await settleTrainerUi(tester);
      final picker = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(const Key('trainer-library-edit-battle-item-picker')),
      );
      expect(picker.items.map((item) => item.value), ['', 'oran_berry']);
      picker.onChanged('oran_berry');
      await settleTrainerUi(tester);
      final quantity = find.byKey(
        const Key('trainer-library-edit-battle-item-oran_berry-quantity'),
      );
      await tester.ensureVisible(quantity);
      await tester.enterText(quantity, '2.5');
      await pressCupertinoButtonWithText(tester, 'Enregistrer');
      expect(notifier.state.project!.trainers.single.battleItems, isEmpty);

      expect(tester.widget<TextField>(quantity).controller!.text, '2.5');
      expect(find.textContaining('entier entre 1 et 99'), findsWidgets);
      await tester.enterText(quantity, '2');
      await pressCupertinoButtonWithText(tester, 'Enregistrer');
      expect(notifier.state.project!.trainers.single.battleItems, {
        'oran_berry': 2,
      });
      expect(
        notifier
            .state
            .project!
            .trainers
            .single
            .rewardItemGrants
            .single
            .quantity,
        7,
      );
      await openTrainerEditor(tester);
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const Key('trainer-library-edit-battle-item-oran_berry-remove'),
            ),
          )
          .onPressed!();
      await settleTrainerUi(tester);
      await pressCupertinoButtonWithText(tester, 'Enregistrer');
      expect(notifier.state.project!.trainers.single.battleItems, isEmpty);
      final createButton = find.byKey(
        const Key('trainer-library-new-trainer-button'),
      );
      await tester.ensureVisible(createButton);
      await settleTrainerUi(tester);
      await tester.tap(createButton);
      await settleTrainerUi(tester);
      await tester.enterText(
        find.byKey(const Key('trainer-library-create-name-field')),
        'Brock',
      );
      await tester.enterText(
        find.byKey(const Key('trainer-library-create-class-field')),
        'Leader',
      );
      tester
          .widget<PokeMapDropdownField<String>>(
            find.byKey(const Key('trainer-library-create-battle-item-picker')),
          )
          .onChanged('oran_berry');
      await settleTrainerUi(tester);
      final createQuantity = find.byKey(
        const Key('trainer-library-create-battle-item-oran_berry-quantity'),
      );
      await tester.ensureVisible(createQuantity);
      await tester.enterText(createQuantity, '100');
      await pressCupertinoButtonWithText(tester, 'Créer');
      expect(notifier.state.project!.trainers, hasLength(1));
      expect(tester.widget<TextField>(createQuantity).controller!.text, '100');
      await tester.enterText(createQuantity, '3');
      await pressCupertinoButtonWithText(tester, 'Créer');
      final created = notifier.state.project!.trainers.last;
      expect(created.id, 'brock');
      expect(created.battleItems, {'oran_berry': 3});
      expect(created.rewardItemGrants, isEmpty);
      expect(repository.lastSavedProject!.trainers.last.battleItems, {
        'oran_berry': 3,
      });
    },
  );

  testWidgets(
    'authors complete trainer victory rewards through guided controls',
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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_rewards_test',
        project: ProjectManifest(
          name: 'trainers_panel_rewards_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          badges: <BadgeDefinition>[
            BadgeDefinition(id: 'tide_badge', label: 'Badge Marée'),
          ],
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
      await tester.tap(find.text('Modifier').first);
      await settleTrainerUi(tester);

      await tester.enterText(
        find.byKey(const Key('trainer-library-edit-reward-money-field')),
        '480',
      );
      await tester.enterText(
        find.byKey(const Key('trainer-library-edit-reward-flags-field')),
        'story:misty_defeated, story:cerulean_open',
      );

      final rewardItemPicker = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(const Key('trainer-library-edit-reward-item-dropdown')),
      );
      expect(rewardItemPicker.items.map((item) => item.label), <String>[
        'Sélectionner un objet du catalogue',
        'Leftovers',
        'Oran Berry',
        'Orbe lunaire',
      ]);
      expect(
        rewardItemPicker.items.map((item) => item.label),
        isNot(contains('oran_berry')),
      );
      rewardItemPicker.onChanged('oran_berry');
      await settleTrainerUi(tester);
      await tester.enterText(
        find.byKey(
          const Key('trainer-library-edit-reward-item-quantity-field'),
        ),
        '2',
      );
      final addItemButton = find.byKey(
        const Key('trainer-library-edit-reward-item-add-button'),
      );
      await tester.ensureVisible(addItemButton);
      tester.widget<PokeMapButton>(addItemButton).onPressed!.call();
      await settleTrainerUi(tester);

      tester
          .widget<PokeMapDropdownField<String>>(
            find.byKey(const Key('trainer-library-edit-reward-badge-dropdown')),
          )
          .onChanged('tide_badge');
      tester
          .widget<PokeMapDropdownField<String>>(
            find.byKey(
              const Key('trainer-library-edit-reward-field-ability-dropdown'),
            ),
          )
          .onChanged(FieldAbility.surf.moveId);
      await settleTrainerUi(tester);

      await pressCupertinoButtonWithText(tester, 'Enregistrer');

      final trainer = container
          .read(editorNotifierProvider)
          .project!
          .trainers
          .single;
      expect(trainer.moneyReward, 480);
      expect(trainer.rewardItemGrants, const <ProjectTrainerItemGrant>[
        ProjectTrainerItemGrant(itemId: 'oran_berry', quantity: 2),
      ]);
      expect(trainer.rewardFlagIds, const <String>[
        'story:misty_defeated',
        'story:cerulean_open',
      ]);
      expect(trainer.rewardBadgeId, 'tide_badge');
      expect(trainer.rewardFieldAbilityUnlock, FieldAbility.surf);
    },
  );

  testWidgets('authors a rival lifecycle through guided template controls', (
    tester,
  ) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_lifecycle_test',
      project: ProjectManifest(
        name: 'trainers_panel_lifecycle_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        dialogues: <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'lysa_before',
            name: 'Lysa · avant combat',
            relativePath: 'dialogues/lysa_before.yarn',
          ),
          ProjectDialogueEntry(
            id: 'lysa_victory',
            name: 'Lysa · après victoire',
            relativePath: 'dialogues/lysa_victory.yarn',
          ),
          ProjectDialogueEntry(
            id: 'lysa_defeat',
            name: 'Lysa · après défaite',
            relativePath: 'dialogues/lysa_defeat.yarn',
          ),
        ],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'lysa',
            name: 'Lysa',
            trainerClass: 'Dresseuse',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);
    await tester.tap(find.text('Modifier').first);
    await settleTrainerUi(tester);

    void selectLifecycle(String suffix, String value) {
      tester
          .widget<PokeMapDropdownField<String>>(
            find.byKey(Key('trainer-library-edit-lifecycle-$suffix-dropdown')),
          )
          .onChanged(value);
    }

    selectLifecycle('template', 'rival');
    selectLifecycle('rematch', 'allowed');
    selectLifecycle('pre-battle', 'lysa_before');
    selectLifecycle('victory', 'lysa_victory');
    selectLifecycle('defeat', 'lysa_defeat');
    await tester.enterText(
      find.byKey(const Key('trainer-library-edit-reward-flags-field')),
      'story:lysa_follow_up',
    );
    await settleTrainerUi(tester);

    final saveButton = find.text('Enregistrer');
    await tester.ensureVisible(saveButton);
    tester
        .widget<CupertinoButton>(
          find.ancestor(of: saveButton, matching: find.byType(CupertinoButton)),
        )
        .onPressed!
        .call();
    await settleTrainerUi(tester);

    final trainer = container
        .read(editorNotifierProvider)
        .project!
        .trainers
        .single;
    expect(trainer.templateKind, ProjectTrainerTemplateKind.rival);
    expect(trainer.rematchPolicy, ProjectTrainerRematchPolicy.allowed);
    expect(trainer.preBattleDialogueId, 'lysa_before');
    expect(trainer.victoryDialogueId, 'lysa_victory');
    expect(trainer.defeatDialogueId, 'lysa_defeat');
    expect(trainer.rewardFlagIds, const <String>['story:lysa_follow_up']);
    expect(trainer.trainerClass, 'Rival');
    expect(trainer.battleDifficulty, 8);
    expect(trainer.tags, containsAll(const <String>['rival', 'story']));
    expect(repository.lastSavedProject?.trainers.single, trainer);
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
        project: ProjectManifest(
          name: 'trainer_picker_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          trainers: <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'mira',
              name: 'Mira',
              trainerClass: 'Rookie',
              battleDifficulty: 6,
              battleBackgroundRelativePath:
                  'assets/battle_backgrounds/mira.png',
            ),
          ],
        ),
      );

      await pumpTrainerPanel(tester, container);
      await settleTrainerUi(tester);

      expect(find.textContaining('AI 6'), findsOneWidget);

      await tester.tap(find.text('Modifier').first);
      await settleTrainerUi(tester);

      expect(
        find.byKey(const Key('trainer-library-edit-difficulty-slider')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Profil tactique · analyse dégâts/types · switch tactique · soins selon stock configuré',
        ),
        findsOneWidget,
      );

      var difficultySlider = tester.widget<CupertinoSlider>(
        find.byKey(const Key('trainer-library-edit-difficulty-slider')),
      );
      difficultySlider.onChanged!(2);
      await settleTrainerUi(tester);
      expect(
        find.text(
          'Profil basique · choix simples · aucun switch tactique · soins selon stock configuré',
        ),
        findsOneWidget,
      );

      difficultySlider = tester.widget<CupertinoSlider>(
        find.byKey(const Key('trainer-library-edit-difficulty-slider')),
      );
      difficultySlider.onChanged!(9);
      await settleTrainerUi(tester);
      expect(
        find.text(
          'Profil avancé · analyse statuts/utilité · switch tactique · soins selon stock configuré',
        ),
        findsOneWidget,
      );

      await pressCupertinoButtonWithText(
        tester,
        'Afficher les références optionnelles',
      );

      expect(find.text('assets/battle_backgrounds/mira.png'), findsOneWidget);
      expect(
        find.byKey(const Key('trainer-library-edit-background-pick-button')),
        findsOneWidget,
      );
      tester
          .widget<CupertinoButton>(
            find.byKey(
              const Key('trainer-library-edit-background-clear-button'),
            ),
          )
          .onPressed!
          .call();
      await settleTrainerUi(tester);
      expect(find.text('Aucun fond spécifique sélectionné.'), findsOneWidget);
    },
  );

  testWidgets('shows the defeated trainer battle sprite controls in the editor '
      '(BETA-BAT-017)', (tester) async {
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(_FakeProjectRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: ProjectManifest(
        name: 'trainer_sprite_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'mira',
            name: 'Mira',
            trainerClass: 'Rookie',
            battleSpriteRelativePath: 'assets/trainers/mira_battle.png',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);
    await tester.tap(find.text('Modifier').first);
    await settleTrainerUi(tester);
    await pressCupertinoButtonWithText(
      tester,
      'Afficher les références optionnelles',
    );

    expect(find.text('assets/trainers/mira_battle.png'), findsOneWidget);
    expect(
      find.byKey(const Key('trainer-library-edit-sprite-pick-button')),
      findsOneWidget,
    );
    tester
        .widget<CupertinoButton>(
          find.byKey(const Key('trainer-library-edit-sprite-clear-button')),
        )
        .onPressed!
        .call();
    await settleTrainerUi(tester);
    expect(
      find.text('Aucun sprite spécifique sélectionné.'),
      findsOneWidget,
      reason: 'le sprite du dresseur vaincu s’édite et s’efface comme le fond',
    );
  });

  testWidgets('shows the trainer battle transition chips and selects one '
      '(BETA-BAT-019)', (tester) async {
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(_FakeProjectRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: ProjectManifest(
        name: 'trainer_transition_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        battleTransitions: ProjectBattleTransitionConfig(
          definitions: [
            for (final id in ['hgss_trainer', 'dpp_trainer'])
              BattleTransitionDefinition.fromJson({
                'id': id,
                'label': id,
                'usages': ['trainer'],
                'phases': [
                  {'kind': 'fadeToBlack', 'durationSeconds': 0.1},
                ],
              }),
          ],
        ),
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'mira',
            name: 'Mira',
            trainerClass: 'Rookie',
            battleTransitionId: 'hgss_trainer',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await settleTrainerUi(tester);
    await tester.tap(find.text('Modifier').first);
    await settleTrainerUi(tester);
    await pressCupertinoButtonWithText(
      tester,
      'Afficher les références optionnelles',
    );

    final hgssChip = find.byKey(
      const Key('trainer-library-edit-transition-hgss_trainer'),
    );
    final dppChip = find.byKey(
      const Key('trainer-library-edit-transition-dpp_trainer'),
    );
    await tester.ensureVisible(hgssChip);
    expect(hgssChip, findsOneWidget);
    expect(dppChip, findsOneWidget);
    expect(
      find.byKey(const Key('trainer-library-edit-transition-default')),
      findsOneWidget,
      reason: 'le retour au défaut du projet reste toujours proposé',
    );

    await tester.tap(dppChip);
    await settleTrainerUi(tester);
    expect(
      find.text(
        'BETA-BAT-019 : la transition de ce dresseur gagne sur la zone et sur le défaut du projet.',
      ),
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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_test',
        project: ProjectManifest(
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
        find.byKey(
          const Key('trainer-library-pokemon-selected-species-status'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Espèce sélectionnée : Caterpie'),
        findsOneWidget,
      );
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
      expect(find.text('Aucune espèce locale ne correspond.'), findsOneWidget);
      expect(
        find.textContaining('Espèce sélectionnée : Caterpie'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('trainer-library-pokemon-species-close-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Espèce sélectionnée : Caterpie'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('trainer-library-pokemon-species-clear-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Aucune espèce sélectionnée pour le moment.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('trainer-library-pokemon-species-dropdown-button'),
          ),
          matching: find.text('Sélectionnez une espèce de Pokémon'),
        ),
        findsOneWidget,
      );
    },
  );

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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_test',
        project: ProjectManifest(
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
      expect(find.textContaining('Niv. 7'), findsWidgets);

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
    },
  );

  testWidgets('shows inline validation when a move is unknown locally', (
    tester,
  ) async {
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
          const LoadPokemonItemsCatalogUseCase(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
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
    await settleTrainerUi(tester);
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

    final savePokemonButton = find.byKey(
      const Key('trainer-library-pokemon-save-button'),
    );
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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_test',
        project: ProjectManifest(
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
        find.byKey(const Key('trainer-library-pokemon-move-1-search-empty')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('trainer-library-pokemon-move-1-close-button')),
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
      await settleTrainerUi(tester);
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

      final savePokemonButton = find.byKey(
        const Key('trainer-library-pokemon-save-button'),
      );
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
    },
  );

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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_test',
        project: ProjectManifest(
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
          'Aucune suggestion de forme locale disponible pour cette espèce. Saisie brute disponible.',
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
          'Aucune suggestion de forme locale disponible pour cette espèce. Saisie brute disponible.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('trainer-library-pokemon-form-suggestion-base')),
        findsNothing,
      );
    },
  );

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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_test',
        project: ProjectManifest(
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
        find.text('Cette espèce est asexuée dans le Pokédex local.'),
        findsOneWidget,
      );
    },
  );

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
            (_, _) async => throw StateError('detail loader exploded'),
          ),
          loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_test',
        project: ProjectManifest(
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
      final rawFallbackToggle = find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      );
      await tester.ensureVisible(rawFallbackToggle);
      await settleTrainerUi(tester);
      await tester.tap(rawFallbackToggle);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('trainer-library-pokemon-species-field')),
        'bulbasaur',
      );
      await selectTrainerLevel(tester, 10);
      await tester.scrollUntilVisible(
        find.text(
          'Impossible de vérifier les formes locales pour cette espèce. Saisie brute disponible.',
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
          'Impossible de vérifier les formes locales pour cette espèce. Saisie brute disponible.',
        ),
        findsOneWidget,
      );

      final savePokemonButton = find.byKey(
        const Key('trainer-library-pokemon-save-button'),
      );
      await tester.ensureVisible(savePokemonButton);
      await tester.pumpAndSettle();
      await tester.tap(savePokemonButton);
      await tester.pumpAndSettle();

      final savedTrainer = container
          .read(editorNotifierProvider)
          .project!
          .trainers
          .single;
      expect(savedTrainer.team.single.speciesId, 'bulbasaur');

      await tester.scrollUntilVisible(
        find.text(
          'Index d’espèces local indisponible. La valeur brute est conservée telle quelle.',
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
          'Index d’espèces local indisponible. La valeur brute est conservée telle quelle.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'keeps the trainer surface usable when moves and items lookups fail unexpectedly',
    (tester) async {
      final repository = _FakeProjectRepository();
      final workspace = _FakeWorkspace(
        itemCatalogError: StateError('items loader exploded'),
      );
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          projectWorkspaceFactoryProvider.overrideWithValue(
            _FakeWorkspaceFactory(workspace),
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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_test',
        project: ProjectManifest(
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
          'Impossible de charger le catalogue local (des capacités) pour ce projet. ',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Impossible de charger le catalogue local (des objets) pour ce projet. ',
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
      final rawFallbackToggle = find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      );
      await tester.ensureVisible(rawFallbackToggle);
      await settleTrainerUi(tester);
      await tester.tap(rawFallbackToggle);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('trainer-library-pokemon-move-0-field')),
        'missing_move',
      );
      expect(
        find.byKey(const Key('trainer-library-pokemon-item-field')),
        findsNothing,
      );

      final savePokemonButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('trainer-library-pokemon-save-button')),
      );
      savePokemonButton.onPressed!.call();
      await tester.pumpAndSettle();

      final savedTrainer = container
          .read(editorNotifierProvider)
          .project!
          .trainers
          .single;
      final pokemon = savedTrainer.team.single;
      expect(pokemon.speciesId, 'bulbasaur');
      expect(pokemon.level, 10);
      expect(pokemon.moves, <String>['missing_move']);
      expect(pokemon.heldItemId, isNull);
    },
  );

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
            const LoadPokemonItemsCatalogUseCase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/trainers_panel_test',
        project: ProjectManifest(
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
          'Aucun learnset local n’est disponible pour cette espèce. Les suggestions sont indisponibles, mais les ID bruts restent possibles.',
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
      await settleTrainerUi(tester);
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

      final savedTrainer = container
          .read(editorNotifierProvider)
          .project!
          .trainers
          .single;
      expect(savedTrainer.team.single.moves, <String>['tackle']);
    },
  );
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

final Map<String, PokedexSpeciesDetail> _detailsById =
    <String, PokedexSpeciesDetail>{'bulbasaur': _buildDetail()};

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
      sourceMeta: const PokemonSpeciesSourceMeta(
        seededBy: 'test',
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
  const _FakeWorkspace({this.itemCatalogError});

  static const String projectRootValue = '/tmp';
  static const String _itemCatalogPath =
      '$projectRootValue/data/pokemon/catalogs/items.json';
  static const String _itemCatalogJson = '''
{
  "schemaVersion": 1,
  "entries": [
    {
      "id": "oran_berry",
      "displayName": "Oran Berry",
      "aliases": ["oran"],
      "pocketId": "berries",
      "uses": [
        {
          "contexts": ["overworld", "battle"],
          "target": "party_member",
          "consumption": "on_applied",
          "effect": {
            "kind": "heal_hp",
            "mode": "flat",
            "amount": 10
          }
        }
      ]
    },
    {
      "id": "leftovers",
      "displayName": "Leftovers",
      "aliases": [],
      "pocketId": "held_items",
      "buyPrice": 200,
      "heldEffectId": "leftovers"
    },
    {
      "id": "lunar_orb",
      "displayName": "Orbe lunaire",
      "pocketId": "balls",
      "capture": {
        "rateNumerator": 1,
        "rateDenominator": 1,
        "allowedEncounterKinds": ["walk"]
      }
    }
  ]
}
''';

  final Object? itemCatalogError;

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
  Future<bool> fileExists(String path) async => path == _itemCatalogPath || path == projectManifestPath;

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
  Future<String> readTextFile(String path) async {
    if (path == projectManifestPath) {
      return jsonEncode(const ProjectManifest(
        name: 'Trainer fixture', maps: [], tilesets: [],
        pokemon: ProjectPokemonConfig(enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          catalogFiles: {'items': 'data/pokemon/catalogs/items.json'}),
      ).toJson());
    }
    if (path == _itemCatalogPath) {
      if (itemCatalogError != null) {
        throw itemCatalogError!;
      }
      return _itemCatalogJson;
    }
    return '';
  }

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
