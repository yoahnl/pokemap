import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:pokemap_loader/src/in_game_shop_page.dart';

final _itemCatalog = ItemCatalogSnapshot.fromCatalog(mvpItemCatalog);

void main() {
  testWidgets('buys an authored item and shows money and remaining stock',
      (tester) async {
    var committed = _state(money: 1000);
    await tester.pumpWidget(
      MaterialApp(
        home: InGameShopPage(
          gameState: committed,
          itemCatalog: _itemCatalog,
          shops: const <ShopDefinition>[
            ShopDefinition(
              id: 'mart',
              label: 'Boutique',
              entries: <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: 'potion', price: 300, stock: 2),
              ],
            ),
          ],
          onStateCommitted: (state) async => committed = state,
        ),
      ),
    );

    expect(find.textContaining('1 000'), findsOneWidget);
    expect(find.textContaining('Stock : 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-buy-potion')));
    await tester.pumpAndSettle();

    expect(committed.trainerProfile.money, 700);
    expect(committed.bag.entries.single.itemId, 'potion');
    expect(find.textContaining('Achat effectué'), findsOneWidget);
    expect(find.textContaining('Stock : 1'), findsOneWidget);
  });

  testWidgets('shows typed purchase failure without changing state',
      (tester) async {
    final initial = _state(money: 100);
    var committed = initial;
    await tester.pumpWidget(
      MaterialApp(
        home: InGameShopPage(
          gameState: initial,
          itemCatalog: _itemCatalog,
          shops: const <ShopDefinition>[
            ShopDefinition(
              id: 'mart',
              label: 'Boutique',
              entries: <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: 'potion', price: 300),
              ],
            ),
          ],
          onStateCommitted: (state) async => committed = state,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('shop-buy-potion')));
    await tester.pumpAndSettle();

    expect(committed, same(initial));
    expect(find.textContaining('Fonds insuffisants'), findsOneWidget);
  });

  testWidgets('renders the resolved dynamic catalogue and storefront message',
      (tester) async {
    final initial = _state(
      money: 1000,
      flags: const <String>{'lysa_defeated'},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InGameShopPage(
          gameState: initial,
          itemCatalog: _itemCatalog,
          shops: <ShopDefinition>[_dynamicShop()],
          onStateCommitted: (_) async {},
        ),
      ),
    );

    expect(find.text('Comptoir après Lysa'), findsOneWidget);
    expect(find.text('Les prix ont changé après la victoire.'), findsOneWidget);
    expect(find.text('Potion'), findsOneWidget);
    expect(find.textContaining('250'), findsOneWidget);
    expect(find.text('Super Potion'), findsOneWidget);
    expect(find.text('Poké Ball'), findsNothing);
  });

  testWidgets('renders a closed state without any buy control', (tester) async {
    final initial = _state(
      money: 1000,
      flags: const <String>{'lighthouse_danger'},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InGameShopPage(
          gameState: initial,
          itemCatalog: _itemCatalog,
          shops: <ShopDefinition>[_dynamicShop()],
          onStateCommitted: (_) async {},
        ),
      ),
    );

    expect(
      find.text('Le comptoir est fermé pendant l’alerte.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shop-buy-potion')), findsNothing);
    expect(find.text('Acheter'), findsNothing);
  });

  testWidgets('refreshes instead of committing a stale catalogue purchase',
      (tester) async {
    var latest = _state(
      money: 1000,
      flags: const <String>{'lysa_defeated'},
    );
    var commits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: InGameShopPage(
          gameState: latest,
          itemCatalog: _itemCatalog,
          currentGameState: () => latest,
          shops: <ShopDefinition>[_dynamicShop()],
          onStateCommitted: (_) async => commits += 1,
        ),
      ),
    );

    expect(find.text('Comptoir après Lysa'), findsOneWidget);
    latest = _state(
      money: 1000,
      flags: const <String>{'lysa_defeated', 'story_finished'},
    );
    await tester.tap(find.byKey(const Key('shop-buy-potion')));
    await tester.pumpAndSettle();

    expect(commits, 0);
    expect(latest.trainerProfile.money, 1000);
    expect(find.text('Grand Comptoir des Brisants'), findsOneWidget);
    expect(find.text('Hyper Potion'), findsOneWidget);
    expect(find.textContaining('catalogue a été actualisé'), findsOneWidget);
  });
}

GameState _state({
  required int money,
  Set<String> flags = const <String>{},
}) =>
    GameState(
      saveId: 'shop-ui',
      trainerProfile: TrainerProfile(name: 'Leaf', money: money),
      storyFlags: StoryFlags(activeFlags: flags),
    );

ShopDefinition _dynamicShop() => ShopDefinition(
      id: 'mart',
      label: 'Boutique',
      entries: const <ShopEntryDefinition>[
        ShopEntryDefinition(itemId: 'poke-ball', price: 200),
      ],
      states: <ShopStateDefinition>[
        ShopStateDefinition(
          id: 'after-lysa',
          label: 'Après Lysa',
          priority: 10,
          activation: ScriptConditionFactory.flagIsSet('lysa_defeated'),
          storefrontLabel: 'Comptoir après Lysa',
          welcomeMessage: 'Les prix ont changé après la victoire.',
          entries: const <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'potion', price: 250, stock: 2),
            ShopEntryDefinition(itemId: 'super-potion', price: 700),
          ],
        ),
        ShopStateDefinition(
          id: 'story-finished',
          label: 'Histoire terminée',
          priority: 30,
          activation: ScriptConditionFactory.flagIsSet('story_finished'),
          storefrontLabel: 'Grand Comptoir des Brisants',
          entries: const <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'potion', price: 200),
            ShopEntryDefinition(itemId: 'hyper-potion', price: 900),
          ],
        ),
        ShopStateDefinition(
          id: 'lighthouse-alert',
          label: 'Alerte au phare',
          priority: 40,
          activation: ScriptConditionFactory.flagIsSet('lighthouse_danger'),
          isOpen: false,
          closedMessage: 'Le comptoir est fermé pendant l’alerte.',
        ),
      ],
    );
