import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/application/shop_editor_controller.dart';
import 'package:map_editor/src/features/gameplay/presentation/shop_state_catalog_editor.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets(
    'guided entry editor preserves and edits imported bonus and ownership limits',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ShopCatalogEntryDraft? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: ShopStateCatalogEditor(
              title: 'Catalogue',
              entries: const [
                ShopEntryDefinition(
                  itemId: 'ball',
                  price: 200,
                  maximumOwnedQuantity: 999,
                  purchaseBonus: ShopPurchaseBonus(
                    itemId: 'premier',
                    everyQuantity: 10,
                    quantity: 1,
                    maximumOwnedQuantity: 999,
                  ),
                ),
              ],
              itemOptions: const [
                ShopEditorItemOption(
                  id: 'ball',
                  label: 'Ball',
                  definition: ProjectItemDefinition(
                    id: 'ball',
                    displayName: 'Ball',
                    pocketId: 'balls',
                  ),
                ),
                ShopEditorItemOption(
                  id: 'premier',
                  label: 'Premier',
                  definition: ProjectItemDefinition(
                    id: 'premier',
                    displayName: 'Premier',
                    pocketId: 'balls',
                  ),
                ),
              ],
              onSave: (draft) => saved = draft,
              onRemove: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('shop-state-entry-edit-ball')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('shop-price-field')), '250');
      await tester.enterText(
        find.byKey(const Key('shop-bonus-quantity-field')),
        '2',
      );
      await tester.ensureVisible(
        find.byKey(const Key('shop-add-entry-button')),
      );
      await tester.tap(find.byKey(const Key('shop-add-entry-button')));
      await tester.pump();
      expect(saved!.price, 250);
      expect(saved!.maximumOwnedQuantity, 999);
      expect(
        saved!.purchaseBonus,
        const ShopPurchaseBonus(
          itemId: 'premier',
          everyQuantity: 10,
          quantity: 2,
          maximumOwnedQuantity: 999,
        ),
      );
    },
  );
  test('controller persists policies for default and conditional catalogs', () {
    final controller = ShopEditorController(
      manifest: const ProjectManifest(name: 'Test', maps: [], tilesets: []),
      itemOptions: const [
        ShopEditorItemOption(id: 'ball', label: 'Ball'),
        ShopEditorItemOption(id: 'premier', label: 'Premier'),
      ],
    );
    final shop = controller.createShop(label: 'Mart');
    controller.setSellPolicy(shop.id, ShopSellPolicy.catalogPrices);
    controller.addEntry(
      shopId: shop.id,
      itemId: 'ball',
      price: 200,
      maximumOwnedQuantity: 999,
      purchaseBonus: const ShopPurchaseBonus(
        itemId: 'premier',
        everyQuantity: 10,
        quantity: 1,
        maximumOwnedQuantity: 999,
      ),
    );
    final restored = ProjectManifest.fromJson(controller.manifest.toJson());
    expect(restored.shops.single.sellPolicy, ShopSellPolicy.catalogPrices);
    expect(
      restored.shops.single.entries.single.purchaseBonus!.itemId,
      'premier',
    );
    expect(restored.shops.single.entries.single.maximumOwnedQuantity, 999);
  });
}
