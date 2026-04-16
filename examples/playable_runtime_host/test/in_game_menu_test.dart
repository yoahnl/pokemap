import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:playable_runtime_host/src/in_game_menu.dart';
import 'package:playable_runtime_host/src/runtime_pokedex_loader.dart';

void main() {
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
  );
}
