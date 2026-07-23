import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/application/shop_editor_controller.dart';

void main() {
  group('ShopEditorController', () {
    test('creates stable ids and validates catalogue entries', () {
      final controller = ShopEditorController(
        manifest: _manifest(),
        itemOptions: const <ShopEditorItemOption>[
          ShopEditorItemOption(id: 'potion', label: 'Potion'),
          ShopEditorItemOption(id: 'antidote', label: 'Antidote'),
        ],
      );

      final first = controller.createShop(label: 'Boutique du Port');
      final second = controller.createShop(label: 'Boutique du Port');
      controller.addEntry(
        shopId: first.id,
        itemId: 'potion',
        price: 300,
        stock: 5,
      );

      expect(first.id, 'boutique-du-port');
      expect(second.id, 'boutique-du-port-2');
      expect(controller.shopById(first.id).entries.single.price, 300);
      expect(
        () => controller.addEntry(
          shopId: first.id,
          itemId: 'missing',
          price: 100,
        ),
        throwsA(isA<ShopEditorValidationException>()),
      );
      expect(
        () => controller.addEntry(
          shopId: first.id,
          itemId: 'potion',
          price: -1,
        ),
        throwsA(isA<ShopEditorValidationException>()),
      );
      expect(
        () => controller.addEntry(
          shopId: first.id,
          itemId: 'potion',
          price: 100,
        ),
        throwsA(isA<ShopEditorValidationException>()),
      );
    });

    test('guards Scene references and can repair them explicitly', () {
      final controller = ShopEditorController(
        manifest: _manifest(
          shops: const <ShopDefinition>[
            ShopDefinition(id: 'port', label: 'Port'),
            ShopDefinition(id: 'forest', label: 'Forêt'),
          ],
          scenes: <SceneAsset>[_shopScene('port')],
        ),
        itemOptions: const <ShopEditorItemOption>[],
      );

      final blocked = controller.deleteShop('port');
      expect(blocked.deleted, isFalse);
      expect(blocked.references.single.sceneId, 'scene-shop');
      expect(controller.shops, hasLength(2));

      final repaired = controller.deleteShop(
        'port',
        replacementShopId: 'forest',
      );
      expect(repaired.deleted, isTrue);
      expect(controller.shops.single.id, 'forest');
      final command = (controller.manifest.scenes.single.graph.nodes
              .singleWhere((node) => node.id == 'shop-action')
              .payload as SceneActionPayload)
          .interactiveCommand as SceneOpenShopInteractiveCommand;
      expect(command.shopId, 'forest');
    });

    test('round-trips authored stock and prices through the manifest', () {
      final controller = ShopEditorController(
        manifest: _manifest(),
        itemOptions: const <ShopEditorItemOption>[
          ShopEditorItemOption(id: 'potion', label: 'Potion'),
        ],
      );
      final shop = controller.createShop(label: 'Herboriste');
      controller.addEntry(
        shopId: shop.id,
        itemId: 'potion',
        price: 450,
        stock: 3,
      );
      controller.renameShop(shop.id, 'Herboriste du Marais');

      final reloaded = ProjectManifest.fromJson(controller.manifest.toJson());
      expect(reloaded.shops.single.label, 'Herboriste du Marais');
      expect(reloaded.shops.single.entries.single.price, 450);
      expect(reloaded.shops.single.entries.single.stock, 3);
    });
  });
}

ProjectManifest _manifest({
  List<ShopDefinition> shops = const <ShopDefinition>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
}) =>
    ProjectManifest(
      name: 'Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      shops: shops,
      scenes: scenes,
    );

SceneAsset _shopScene(String shopId) => SceneAsset(
      id: 'scene-shop',
      name: 'Scène boutique',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'shop-action',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.openShop(shopId: shopId),
            ),
          ),
        ],
        edges: const <SceneEdge>[],
      ),
    );
