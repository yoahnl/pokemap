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

    test(
        'authors isolated conditional shop states through their full lifecycle',
        () {
      final controller = ShopEditorController(
        manifest: _manifest(
          shops: const <ShopDefinition>[
            ShopDefinition(
              id: 'port',
              label: 'Boutique du Port',
              entries: <ShopEntryDefinition>[
                ShopEntryDefinition(
                  itemId: 'potion',
                  price: 300,
                  stock: 4,
                ),
              ],
            ),
          ],
        ),
        itemOptions: const <ShopEditorItemOption>[
          ShopEditorItemOption(id: 'potion', label: 'Potion'),
          ShopEditorItemOption(id: 'antidote', label: 'Antidote'),
        ],
      );
      final activation = ScriptConditionFactory.stepCompleted('lysa');

      final copied = controller.createStateFromDefault(
        shopId: 'port',
        label: 'Après Lysa',
        activation: activation,
      );
      final empty = controller.createEmptyState(
        shopId: 'port',
        label: 'Boutique fermée',
        activation: ScriptConditionFactory.flagIsSet('port_closed'),
      );
      final duplicate = controller.duplicateState(
        shopId: 'port',
        stateId: copied.id,
      );

      expect(copied.id, 'apr-s-lysa');
      expect(copied.entries.single.price, 300);
      expect(empty.entries, isEmpty);
      expect(duplicate.id, 'apr-s-lysa-2');
      expect(duplicate.entries, copied.entries);

      controller.renameState(
        shopId: 'port',
        stateId: copied.id,
        label: '  Après la victoire contre Lysa  ',
      );
      controller.updateStateSettings(
        shopId: 'port',
        stateId: copied.id,
        priority: 20,
        isOpen: true,
        storefrontLabel: '  Comptoir du port  ',
        welcomeMessage: '  Bienvenue !  ',
        closedMessage: '',
      );
      controller.replaceStateActivation(
        shopId: 'port',
        stateId: copied.id,
        activation: ScriptConditionFactory.badgeOwned('brume'),
      );
      controller.updateStateEntry(
        shopId: 'port',
        stateId: copied.id,
        itemId: 'potion',
        price: 450,
        stock: 2,
      );
      controller.addStateEntry(
        shopId: 'port',
        stateId: copied.id,
        itemId: 'antidote',
        price: 120,
      );

      final updated = controller.stateById('port', copied.id);
      expect(updated.id, copied.id,
          reason: 'Un renommage conserve l’id stable.');
      expect(updated.label, 'Après la victoire contre Lysa');
      expect(updated.priority, 20);
      expect(updated.storefrontLabel, 'Comptoir du port');
      expect(updated.welcomeMessage, 'Bienvenue !');
      expect(updated.activation.type, ScriptConditionType.badgeOwned);
      expect(updated.entries, hasLength(2));
      expect(updated.entries.first.price, 450);
      expect(controller.shopById('port').entries.single.price, 300);

      controller.removeStateEntry(
        shopId: 'port',
        stateId: copied.id,
        itemId: 'antidote',
      );
      controller.deleteState(shopId: 'port', stateId: empty.id);
      expect(
        controller.shopById('port').states.map((state) => state.id),
        containsAll(<String>[copied.id, duplicate.id]),
      );
      expect(
        () => controller.deleteState(
          shopId: 'port',
          stateId: ShopEditorController.defaultStateId,
        ),
        throwsA(isA<ShopEditorValidationException>()),
      );

      final reloaded = ProjectManifest.fromJson(controller.manifest.toJson());
      expect(
        reloaded.shops.single.states
            .singleWhere((state) => state.id == copied.id)
            .entries
            .single
            .price,
        450,
      );
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
