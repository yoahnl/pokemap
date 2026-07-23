import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/in_game_shop_page.dart';

void main() {
  testWidgets('buys an authored item and shows money and remaining stock',
      (tester) async {
    var committed = _state(money: 1000);
    await tester.pumpWidget(
      MaterialApp(
        home: InGameShopPage(
          gameState: committed,
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
}

GameState _state({required int money}) => GameState(
      saveId: 'shop-ui',
      trainerProfile: TrainerProfile(name: 'Leaf', money: money),
    );
