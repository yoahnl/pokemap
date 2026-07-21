import 'package:pokemap_loader/src/in_game_menu.dart';
import 'package:pokemap_loader/src/runtime_pokedex_loader.dart';
import 'package:pokemap_loader/src/runtime_player_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('pause menu route guard releases the typed owner after completion',
      () async {
    final transitions = <(RuntimeExternalInputLock, bool)>[];

    await runWithRuntimePauseMenuInputLock(
      setExternalInputLock: (owner, {required locked}) {
        transitions.add((owner, locked));
      },
      openMenu: () async {},
    );

    expect(transitions, [
      (RuntimeExternalInputLock.pauseMenu, true),
      (RuntimeExternalInputLock.pauseMenu, false),
    ]);
  });

  test('pause menu route guard releases the typed owner after an error',
      () async {
    final transitions = <(RuntimeExternalInputLock, bool)>[];

    await expectLater(
      runWithRuntimePauseMenuInputLock(
        setExternalInputLock: (owner, {required locked}) {
          transitions.add((owner, locked));
        },
        openMenu: () => Future<void>.error(StateError('navigation failed')),
      ),
      throwsStateError,
    );

    expect(transitions.last, (RuntimeExternalInputLock.pauseMenu, false));
  });

  // Ce test couvre le coeur des lots 48 à 51 :
  // navigation latérale et lecture correcte des données du snapshot runtime.
  testWidgets('navigates across Pokédex, Équipe, Sac and Dresseur sections',
      (tester) async {
    var closeRequested = false;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: InGameMenuPage(
          gameStateSnapshotBuilder: _buildGameState,
          pokedexLoader: () async => const <RuntimePokedexEntry>[
            RuntimePokedexEntry(
              id: 'bulbasaur',
              nationalDex: 1,
              primaryName: 'Bulbasaur',
              types: ['grass', 'poison'],
              isEnabledInProject: true,
              flavorText: 'Seed Pokemon',
            ),
            RuntimePokedexEntry(
              id: 'ivysaur',
              nationalDex: 2,
              primaryName: 'Ivysaur',
              types: ['grass', 'poison'],
              isEnabledInProject: false,
              flavorText: 'Blooming Pokemon',
            ),
          ],
          onSaveRequested: () async => const InGameMenuActionResult(),
          onLoadRequested: () async => const InGameMenuActionResult(),
          playerOptions: const RuntimePlayerOptions(),
          supportsTouchControls: true,
          onOptionsChanged: (_) {},
          onQuitRequested: () {},
          onCloseRequested: () {
            closeRequested = true;
          },
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('in-game-pokedex-list')), findsOneWidget);
    expect(find.text('Bulbasaur'), findsWidgets);
    expect(find.byKey(const Key('pokedex-detail-bulbasaur')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('pokedex-entry-ivysaur')));
    await tester.tap(find.byKey(const Key('pokedex-entry-ivysaur')));
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-ivysaur')), findsOneWidget);
    expect(find.textContaining('Désactivée'), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-party-tile')));
    await tester.pump();

    expect(find.byKey(const Key('in-game-party-section')), findsOneWidget);
    expect(find.byKey(const Key('party-entry-0')), findsOneWidget);
    expect(find.byKey(const Key('party-entry-name-0')), findsOneWidget);
    expect(find.textContaining('Niv. 12'), findsOneWidget);
    expect(find.byKey(const Key('party-move-vine-whip-0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-bag-tile')));
    await tester.pump();

    expect(find.byKey(const Key('in-game-bag-section')), findsOneWidget);
    expect(find.byKey(const Key('bag-entry-potion')), findsOneWidget);
    expect(find.text('x3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-trainer-tile')));
    await tester.pump();

    expect(find.byKey(const Key('in-game-trainer-section')), findsOneWidget);
    expect(find.byKey(const Key('trainer-name')), findsOneWidget);
    expect(find.textContaining('Leaf'), findsOneWidget);
    expect(find.byKey(const Key('trainer-badge-cascade')), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-close-tile')));
    await tester.pump();

    expect(closeRequested, isTrue);
  });

  // On vérifie ici que la section Sauvegarde ne réimplémente rien :
  // elle doit juste relayer les callbacks fournis par le host runtime.
  testWidgets('save and load actions use the provided callbacks',
      (tester) async {
    var saveCount = 0;
    var loadCount = 0;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: InGameMenuPage(
          gameStateSnapshotBuilder: _buildGameState,
          pokedexLoader: () async => const <RuntimePokedexEntry>[],
          onSaveRequested: () async {
            saveCount += 1;
            return const InGameMenuActionResult(
              status: 'Sauvegarde OK · lab (4, 7)',
            );
          },
          onLoadRequested: () async {
            loadCount += 1;
            return const InGameMenuActionResult(
              status: 'Chargement OK · lab (4, 7)',
            );
          },
          playerOptions: const RuntimePlayerOptions(),
          supportsTouchControls: true,
          onOptionsChanged: (_) {},
          onQuitRequested: () {},
          onCloseRequested: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('menu-save-tile')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('in-game-menu-save-button')));
    await tester.pump();

    expect(saveCount, 1);
    expect(find.byKey(const Key('in-game-menu-save-status')), findsOneWidget);
    expect(find.textContaining('Sauvegarde OK'), findsOneWidget);

    await tester.tap(find.byKey(const Key('in-game-menu-load-button')));
    await tester.pump();

    expect(loadCount, 1);
    expect(find.textContaining('Chargement OK'), findsOneWidget);
  });

  testWidgets('offers real options and keyboard navigation closes with Escape',
      (tester) async {
    var closeCount = 0;
    var options = const RuntimePlayerOptions();
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: InGameMenuPage(
          gameStateSnapshotBuilder: _buildGameState,
          pokedexLoader: () async => const <RuntimePokedexEntry>[],
          onSaveRequested: () async => const InGameMenuActionResult(),
          onLoadRequested: () async => const InGameMenuActionResult(),
          playerOptions: options,
          supportsTouchControls: true,
          onOptionsChanged: (next) => options = next,
          onQuitRequested: () {},
          onCloseRequested: () => closeCount += 1,
        ),
      ),
    );
    await tester.pump();

    // The selected first tile owns initial focus, so Tab + Enter reaches Party.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.byKey(const Key('in-game-party-section')), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-options-tile')));
    await tester.pump();
    expect(find.byKey(const Key('in-game-options-section')), findsOneWidget);
    expect(find.textContaining('Volume global indisponible'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dialogue-text-speed-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rapide').last);
    await tester.pumpAndSettle();
    expect(options.dialogueTextSpeed, RuntimeDialogueTextSpeed.fast);

    await tester.tap(find.byKey(const Key('show-touch-controls-switch')));
    await tester.pump();
    expect(options.showTouchControls, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(closeCount, 1);
  });

  testWidgets('Quit requires confirmation and cancellation is non destructive',
      (tester) async {
    var quitCount = 0;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: InGameMenuPage(
          gameStateSnapshotBuilder: _buildGameState,
          pokedexLoader: () async => const <RuntimePokedexEntry>[],
          onSaveRequested: () async => const InGameMenuActionResult(),
          onLoadRequested: () async => const InGameMenuActionResult(),
          playerOptions: const RuntimePlayerOptions(),
          supportsTouchControls: false,
          onOptionsChanged: (_) {},
          onQuitRequested: () => quitCount += 1,
          onCloseRequested: () {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('menu-quit-tile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quit-confirmation-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('quit-cancel-button')));
    await tester.pumpAndSettle();
    expect(quitCount, 0);

    await tester.tap(find.byKey(const Key('menu-quit-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quit-confirm-button')));
    await tester.pumpAndSettle();
    expect(quitCount, 1);
  });

  testWidgets('Pokédex privacy updates live from unknown to seen and caught',
      (tester) async {
    var gameState = _buildGameState().copyWith(
      progression: const PlayerProgression(),
    );
    late StateSetter rebuildHost;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuildHost = setState;
            return InGameMenuPage(
              gameStateSnapshotBuilder: () => gameState,
              pokedexLoader: () async => const <RuntimePokedexEntry>[
                RuntimePokedexEntry(
                  id: 'bulbasaur',
                  nationalDex: 1,
                  primaryName: 'Bulbasaur',
                  types: ['grass', 'poison'],
                  isEnabledInProject: true,
                  flavorText: 'Seed Pokemon',
                ),
              ],
              onSaveRequested: () async => const InGameMenuActionResult(),
              onLoadRequested: () async => const InGameMenuActionResult(),
              playerOptions: const RuntimePlayerOptions(),
              supportsTouchControls: false,
              onOptionsChanged: (_) {},
              onQuitRequested: () {},
              onCloseRequested: () {},
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('???'), findsWidgets);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Seed Pokemon'), findsNothing);
    expect(
      find.byKey(const Key('pokedex-knowledge-bulbasaur-unknown')),
      findsOneWidget,
    );

    rebuildHost(() {
      gameState = gameState.copyWith(
        progression: const PlayerProgression(
          seenSpeciesIds: ['bulbasaur'],
        ),
      );
    });
    await tester.pump();

    expect(find.text('Bulbasaur'), findsWidgets);
    expect(find.text('Seed Pokemon'), findsNothing);
    expect(
      find.byKey(const Key('pokedex-knowledge-bulbasaur-seen')),
      findsOneWidget,
    );

    rebuildHost(() {
      gameState = gameState.copyWith(
        progression: const PlayerProgression(
          caughtSpeciesIds: ['bulbasaur'],
        ),
      );
    });
    await tester.pump();

    expect(find.text('Seed Pokemon'), findsOneWidget);
    expect(
      find.byKey(const Key('pokedex-knowledge-bulbasaur-caught')),
      findsOneWidget,
    );
  });
}

// Snapshot minimal utilisé par les écrans Sac et Dresseur.
// Il reste volontairement petit pour que le test cible la présentation.
GameState _buildGameState() {
  return const GameState(
    saveId: 'save-1',
    party: PlayerParty(
      members: [
        PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: ['tackle', 'vine-whip'],
          currentHp: 31,
          heldItemId: 'miracle-seed',
        ),
      ],
    ),
    trainerProfile: TrainerProfile(
      name: 'Leaf',
      badgeIds: ['cascade', 'thunder'],
      money: 4200,
      playtimeSeconds: 3723,
    ),
    bag: Bag(
      entries: [
        BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
        BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
      ],
    ),
    progression: PlayerProgression(
      caughtSpeciesIds: ['bulbasaur', 'ivysaur'],
    ),
  );
}
