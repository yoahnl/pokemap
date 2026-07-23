import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/in_game_pc_page.dart';

void main() {
  testWidgets('deposits and withdraws through pure storage operations',
      (tester) async {
    var committed = GameState(
      saveId: 'pc-ui',
      party: PlayerParty(
        members: <PlayerPokemon>[_pokemon('lead'), _pokemon('reserve')],
      ),
      pokemonStorage: const PokemonStorage().normalized(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InGamePcPage(
          gameState: committed,
          onStateCommitted: (state) async => committed = state,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pc-deposit-party-1')));
    await tester.pumpAndSettle();

    expect(committed.party.members.single.speciesId, 'lead');
    expect(committed.pokemonStorage.boxes.first.pokemon.single.speciesId,
        'reserve');
    expect(find.textContaining('déposé'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pc-withdraw-box-01-0')));
    await tester.pumpAndSettle();

    expect(committed.party.members.last.speciesId, 'reserve');
    expect(committed.pokemonStorage.boxes.first.pokemon, isEmpty);
  });

  testWidgets('offers a party swap when the party is full', (tester) async {
    var committed = GameState(
      saveId: 'pc-swap-ui',
      party: PlayerParty(
        members: List<PlayerPokemon>.generate(
          maxPlayerPartySize,
          (index) => _pokemon('party-$index'),
        ),
      ),
      pokemonStorage: PokemonStorage(
        boxes: <PokemonBox>[
          PokemonBox(
            id: 'box-a',
            label: 'Box A',
            pokemon: <PlayerPokemon>[_pokemon('stored')],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InGamePcPage(
          gameState: committed,
          onStateCommitted: (state) async => committed = state,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pc-swap-box-a-0')));
    await tester.pumpAndSettle();

    expect(committed.party.members.first.speciesId, 'stored');
    expect(committed.pokemonStorage.boxes.first.pokemon.single.speciesId,
        'party-0');
  });
}

PlayerPokemon _pokemon(String speciesId) => PlayerPokemon(
      speciesId: speciesId,
      natureId: 'hardy',
      abilityId: 'pressure',
      currentHp: 10,
    );
