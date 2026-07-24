import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/evaluation/interactive/player_service_automation_port.dart';
import 'package:pokemap_loader/src/in_game_heal_flow.dart';
import 'package:pokemap_loader/src/in_game_pc_page.dart';
import 'package:pokemap_loader/src/in_game_shop_page.dart';

void main() {
  testWidgets('visible Shop registers typed buy actions', (tester) async {
    final port = PlayerServiceAutomationPort();
    var currentState = const GameState(
      saveId: 'interactive-shop',
      trainerProfile: TrainerProfile(name: 'Leaf', money: 1000),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InGameShopPage(
          gameState: currentState,
          shops: const <ShopDefinition>[
            ShopDefinition(
              id: 'mart',
              label: 'Boutique',
              entries: <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: 'potion', price: 300),
              ],
            ),
          ],
          onStateCommitted: (state) async => currentState = state,
          automationPort: port,
        ),
      ),
    );

    expect(port.activeService, PlayerServiceAutomationKind.shop);
    await port.buy('potion', 1);
    await tester.pump();

    expect(currentState.trainerProfile.money, 700);
    expect(currentState.bag.entries.single.itemId, 'potion');
    expect(currentState.bag.entries.single.quantity, 1);
    expect(
      port.lastShopSnapshot,
      containsPair(
        'catalogue',
        <String, int>{'potion': 300},
      ),
    );
  });

  testWidgets('automation unregisters when the overlay closes', (tester) async {
    final port = PlayerServiceAutomationPort();

    await tester.pumpWidget(
      MaterialApp(
        home: InGameShopPage(
          gameState: const GameState(saveId: 'interactive-shop-lifecycle'),
          shops: const <ShopDefinition>[],
          onStateCommitted: (_) async {},
          automationPort: port,
        ),
      ),
    );
    expect(port.activeService, PlayerServiceAutomationKind.shop);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(port.activeService, isNull);
  });

  testWidgets('Heal and PC expose only their typed mutations', (tester) async {
    final port = PlayerServiceAutomationPort();
    var healedState = const GameState(
      saveId: 'interactive-heal',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            currentHp: 1,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InGameHealFlow(
          gameState: healedState,
          recoveryCaps: const RuntimePlayerServiceRecoveryCaps(
            maxHpByPartyIndex: <int, int>{0: 25},
          ),
          onStateCommitted: (state) async => healedState = state,
          automationPort: port,
        ),
      ),
    );

    expect(port.activeService, PlayerServiceAutomationKind.heal);
    expect((await port.heal()).completed, isTrue);
    await tester.pump();
    expect(healedState.party.members.single.currentHp, 25);
    expect(
      (await port.buyItem(itemId: 'potion', quantity: 1)).failure,
      PlayerServiceAutomationFailure.wrongService,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    var pcState = const GameState(
      saveId: 'interactive-pc',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
          ),
        ],
      ),
      pokemonStorage: PokemonStorage(
        boxes: <PokemonBox>[
          PokemonBox(
            id: 'box-a',
            label: 'Box A',
            pokemon: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'magikarp',
                natureId: 'hardy',
                abilityId: 'swift-swim',
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InGamePcPage(
          gameState: pcState,
          onStateCommitted: (state) async => pcState = state,
          automationPort: port,
        ),
      ),
    );
    await tester.pump();

    expect(port.activeService, PlayerServiceAutomationKind.pc);
    expect((await port.withdraw(pokemonId: 'magikarp')).completed, isTrue);
    await tester.pump();
    expect(
      pcState.party.members.any((pokemon) => pokemon.speciesId == 'magikarp'),
      isTrue,
    );
    expect((await port.deposit(pokemonId: 'magikarp')).completed, isTrue);
    await tester.pump();
    expect(
      pcState.pokemonStorage.boxes
          .expand((box) => box.pokemon)
          .any((pokemon) => pokemon.speciesId == 'magikarp'),
      isTrue,
    );
  });
}
