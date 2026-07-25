import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PlayableMapGame installs shop and PC Scene command callbacks',
      () async {
    const initial = GameState(saveId: 'scene-services');
    final host = _PlayerServiceHost();
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/scene-services/project.json',
      saveData: saveDataFromGameState(initial),
    );
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => game.playerServiceGameStateSnapshot,
      host: host,
      commitAndSave: (_) async {},
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    game.setPlayerServiceRuntimeController(controller);

    final shopPort = await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.openShop(shopId: 'shop.port'),
    );
    final pcPort = await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.openPc(),
    );

    expect(shopPort, 'completed');
    expect(pcPort, 'cancelled');
    expect(host.shopCalls, 1);
    expect(host.pcCalls, 1);
  });

  test('PlayableMapGame maps missing services to declared Scene ports',
      () async {
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/scene-services/project.json',
    );

    expect(
      await game.debugExecuteSceneInteractiveCommand(
        SceneInteractiveCommand.openShop(shopId: 'shop.missing'),
      ),
      'cancelled',
    );
    expect(
      await game.debugExecuteSceneInteractiveCommand(
        SceneInteractiveCommand.openPc(),
      ),
      'cancelled',
    );
  });
}

final class _PlayerServiceHost implements PlayerServiceOverlayHost {
  int shopCalls = 0;
  int pcCalls = 0;

  @override
  Future<PlayerServiceHostResult> openShop(PlayerServiceShopRequest request) {
    shopCalls += 1;
    expect(request.worldRequest?.interactionId, 'scene.openShop:shop.port');
    expect(request.worldRequest?.shopId, 'shop.port');
    return Future<PlayerServiceHostResult>.value(
      PlayerServiceHostResult.completed(request.gameState),
    );
  }

  @override
  Future<PlayerServiceHostResult> openPc(PlayerServicePcRequest request) {
    pcCalls += 1;
    expect(request.worldRequest?.interactionId, 'scene.openPc:default');
    return Future<PlayerServiceHostResult>.value(
      const PlayerServiceHostResult.cancelled(),
    );
  }

  @override
  Future<PlayerServiceHostResult> openHealCenter(
    PlayerServiceHealRequest request,
  ) {
    return Future<PlayerServiceHostResult>.value(
      const PlayerServiceHostResult.cancelled(),
    );
  }
}

RuntimeMapBundle _bundle() => RuntimeMapBundle(
      manifest: const ProjectManifest(
        name: 'Scene services',
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[],
        shops: <ShopDefinition>[
          ShopDefinition(id: 'shop.port', label: 'Boutique du port'),
        ],
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
      ),
      map: const MapData(
        id: 'map.port',
        name: 'Port',
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          MapLayer.object(id: 'objects', name: 'Objects'),
        ],
      ),
      projectRootDirectory: '/tmp/scene-services',
      tilesetAbsolutePathsById: const <String, String>{},
    );
