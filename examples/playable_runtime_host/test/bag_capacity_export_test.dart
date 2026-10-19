import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/driver/runtime_evaluation_driver.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'installed pocket limits govern atomic gifts and survive save and reload',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'bag-capacity-export-',
      );
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(
        name: 'Generic pocket capacity',
        maps: const [
          ProjectMapEntry(
            id: 'field',
            name: 'Field',
            relativePath: 'maps/field.json',
          ),
        ],
        tilesets: const [],
        pokemon: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          catalogFiles: {'items': 'catalogs/items.json'},
        ),
        bagCapacity: ProjectBagCapacity.fromJson(_capacity),
      );
      final sourceBefore = jsonEncode(project.toJson());
      final payload = <String, List<int>>{
        'project/project.json': utf8.encode(sourceBefore),
        'project/maps/field.json': utf8.encode(
          jsonEncode(
            const MapData(
              id: 'field',
              name: 'Field',
              size: GridSize(width: 3, height: 3),
            ).toJson(),
          ),
        ),
        'project/catalogs/items.json': utf8.encode(
          jsonEncode(_catalog.toJson()),
        ),
      };
      final built = const GamePackageBuilder().build(
        manifest: _packageManifest(project.version.name),
        payloadFiles: payload,
      );
      final package = File(p.join(root.path, 'capacity.avelunegame'));
      await package.writeAsBytes(built.packageBytes, flush: true);
      final archiveBefore = await package.readAsBytes();
      for (final installation in ['first', 'reload']) {
        final bundle = await _install(
          package,
          Directory(p.join(root.path, installation)),
          project.version.name,
        );
        final installedBefore = jsonEncode(bundle.manifest.toJson());
        expect(bundle.manifest.bagCapacity.toJson(), _capacity);
        final catalog = await const RuntimeItemCatalogLoader().loadSnapshot(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
        );
        const state = GameState(
          saveId: 'capacity-save',
          currentMapId: 'field',
          playerPosition: GridPos(x: 1, y: 1),
          bag: Bag(
            entries: [
              BagEntry(itemId: 'tonic', quantity: 98),
              BagEntry(itemId: 'salve', quantity: 1),
            ],
          ),
        );
        final before = jsonEncode(state.toJson());
        SceneItemGiftResult gift(GameState source, String id, int quantity) =>
            executeSceneItemGift(
              command: SceneGiveItemInteractiveCommand(
                itemId: id,
                quantity: quantity,
              ),
              gameState: source,
              bagCapacity: bundle.manifest.bagCapacity,
              itemCatalog: catalog,
            );
        final refusedStack = gift(state, 'tonic', 5);
        expect(refusedStack.outcome, SceneItemGiftOutcome.bagFull);
        expect(identical(refusedStack.gameState, state), isTrue);
        final refusedPocket = gift(state, 'antidote', 1);
        expect(refusedPocket.outcome, SceneItemGiftOutcome.bagFull);
        expect(jsonEncode(refusedPocket.gameState.toJson()), before);
        final merged = gift(state, 'tonic', 1);
        expect(merged.outcome, SceneItemGiftOutcome.received);
        expect(merged.gameState.bag.entries.length, 2);
        expect(
          const BagOperations().quantityOf(merged.gameState.bag, 'tonic'),
          99,
        );
        final removed = const BagOperations().take(
          BagTakeRequest(bag: state.bag, itemId: 'salve', quantity: 1),
        );
        expect(removed.isSuccess, isTrue);
        final retried = gift(state.copyWith(bag: removed.bag), 'antidote', 1);
        expect(retried.outcome, SceneItemGiftOutcome.received);
        expect(
          const BagOperations().quantityOf(retried.gameState.bag, 'antidote'),
          1,
        );
        final separatePocket = gift(retried.gameState, 'rope', 1);
        expect(separatePocket.outcome, SceneItemGiftOutcome.received);
        final save = File(p.join(root.path, 'save-$installation.json'));
        await save.writeAsString(
          jsonEncode(separatePocket.gameState.toJson()),
          flush: true,
        );
        final restored = GameState.fromJson(
          jsonDecode(await save.readAsString()) as Map<String, dynamic>,
        );
        expect(restored.bag, separatePocket.gameState.bag);
        expect(
          gift(restored, 'tonic', 2).outcome,
          SceneItemGiftOutcome.bagFull,
        );
        expect(jsonEncode(state.toJson()), before);
        expect(jsonEncode(bundle.manifest.toJson()), installedBefore);
        expect(jsonEncode(project.toJson()), sourceBefore);
        expect(await package.readAsBytes(), archiveBefore);
      }
    },
  );
  test(
    'the real Player evaluation driver cannot bypass pocket capacity',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'bag-capacity-player-',
      );
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(
        name: 'Capacity Player',
        maps: const [
          ProjectMapEntry(
            id: 'field',
            name: 'Field',
            relativePath: 'field.json',
          ),
        ],
        tilesets: const [],
        pokemon: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          catalogFiles: {'items': 'items.json'},
        ),
        bagCapacity: ProjectBagCapacity.fromJson(_capacity),
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'field',
          startSpawnId: 'start',
          startingMoney: 17,
          initialBag: [
            BagEntry(itemId: 'tonic', quantity: 98),
            BagEntry(itemId: 'salve', quantity: 1),
          ],
        ),
      );
      const map = MapData(
        id: 'field',
        name: 'Field',
        size: GridSize(width: 4, height: 4),
        entities: [
          MapEntity(
            id: 'start',
            name: 'Start',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            blocksMovement: false,
            spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
          ),
        ],
      );
      await File(p.join(root.path, 'project.json'))
          .writeAsString(jsonEncode(project.toJson()));
      await File(p.join(root.path, 'field.json'))
          .writeAsString(jsonEncode(map.toJson()));
      await File(p.join(root.path, 'items.json'))
          .writeAsString(jsonEncode(_catalog.toJson()));
      final driver = await RuntimeEvaluationDriver.start(projectRoot: root);
      addTearDown(driver.dispose);
      final before = jsonEncode(driver.state.toJson());
      await expectLater(
        driver.giveBagItem('tonic', 5),
        throwsA(isA<EvaluationDriverFailure>()),
      );
      expect(jsonEncode(driver.state.toJson()), before);
      await expectLater(
        driver.giveBagItem('antidote', 1),
        throwsA(isA<EvaluationDriverFailure>()),
      );
      expect(jsonEncode(driver.state.toJson()), before);
      await driver.giveBagItem('tonic', 1);
      expect(driver.snapshot().bag['tonic'], 99);
      await driver.consumeBagItem('salve', 1);
      await driver.giveBagItem('antidote', 1);
      expect(driver.snapshot().bag, {'tonic': 99, 'antidote': 1});
      expect(driver.state.trainerProfile.money, 17);
      await driver.giveBagItem('rope', 1);
      expect(driver.snapshot().bag['rope'], 1);
    },
  );
}

const _capacity = {
  'pockets': {
    'medicine': {'maxDistinctItems': 2, 'maxQuantityPerItem': 99},
    'supplies': {'maxDistinctItems': 1},
  },
};

const _catalog = ProjectItemCatalog(
  schemaVersion: 1,
  entries: [
    ProjectItemDefinition(
      id: 'tonic',
      displayName: 'Tonic',
      pocketId: 'medicine',
    ),
    ProjectItemDefinition(
      id: 'salve',
      displayName: 'Salve',
      pocketId: 'medicine',
    ),
    ProjectItemDefinition(
      id: 'antidote',
      displayName: 'Antidote',
      pocketId: 'medicine',
    ),
    ProjectItemDefinition(
      id: 'rope',
      displayName: 'Rope',
      pocketId: 'supplies',
    ),
  ],
);

GamePackageHostCompatibility _compatibility(String format) =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('1.2.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const {'map@1', 'catalog.partitioned@2'},
      supportedProjectFormats: {format},
      currentProjectFormat: format,
      supportedSaveFormats: const {1},
    );

Future<RuntimeMapBundle> _install(
  File package,
  Directory support,
  String format,
) async {
  final host = _compatibility(format);
  final installation = await GamePackageInstaller(
    supportRoot: support,
    inspector: GamePackageInspector(hostCompatibility: host),
    availableDiskBytes: (_) async => 1024 * 1024 * 1024,
    loadSmoke: (staged, _) async {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: p.join(staged.path, 'project', 'project.json'),
        mapId: 'field',
      );
      bundle.projectCatalog?.dispose();
    },
    prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
  ).install(package, source: GamePackageInstallSource.localExport);
  final launch = await InstalledGameLaunchResolver(
    supportRoot: support,
    hostCompatibility: host,
  ).resolve(installation.game);
  final projectFile = await launch.assets.resolveReference(launch.project);
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile.path,
    mapId: 'field',
  );
  addTearDown(() => bundle.projectCatalog?.dispose());
  return bundle;
}

GamePackageManifest _packageManifest(String format) => GamePackageManifest(
  packageFormat: 1,
  gameId: 'games.example.capacity',
  gameVersion: Version.parse('1.0.0'),
  title: 'Capacity fixture',
  author: const GamePackageParty(name: 'Test'),
  compatibility: GamePackageCompatibility(
    minHubVersion: Version.parse('0.1.0'),
    runtimeApiExpression: '>=1.0.0 <2.0.0',
    projectFormat: format,
    saveFormat: 1,
    compatibilityId: 'main',
    requiredCapabilities: const ['map@1'],
  ),
  locales: GamePackageLocales(defaultLocale: 'en', supported: const ['en']),
  presentation: const GamePackagePresentation(),
  content: GamePackageContent(
    fileCount: 0,
    totalBytes: 0,
    treeSha256: '0' * 64,
    files: const [],
  ),
);
