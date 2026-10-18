import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
export 'package:pokemap_loader/src/evaluation/driver/evaluation_runtime_support.dart';

GameState gameStateFixture() => const GameState(
  saveId: 'evaluation-fixture',
  currentMapId: 'map_bourg_selbrume',
  playerPosition: GridPos(x: 4, y: 7),
  trainerProfile: TrainerProfile(name: 'Leaf', money: 1000),
);

PlayerServiceShopRequest shopRequestFixture() {
  final state = gameStateFixture();
  const shop = ShopDefinition(
    id: 'shop_port_supplies',
    label: 'Comptoir des Brisants',
    entries: <ShopEntryDefinition>[
      ShopEntryDefinition(itemId: 'potion', price: 300, stock: 3),
    ],
  );
  final resolved = const ShopStateResolver().resolve(
    shop: shop,
    gameState: state,
  );
  return PlayerServiceShopRequest(
    gameState: state,
    recoveryCaps: const RuntimePlayerServiceRecoveryCaps(
      maxHpByPartyIndex: <int, int>{},
    ),
    shop: shop,
    resolvedState: resolved,
    conditionContext: const ScriptEvaluationContext(),
    itemCatalog: ItemCatalogSnapshot.fromCatalog(
      const ProjectItemCatalog(
        schemaVersion: 1,
        entries: <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'potion',
            displayName: 'Potion',
            pocketId: 'medicine',
          ),
        ],
      ),
    ),
  );
}
