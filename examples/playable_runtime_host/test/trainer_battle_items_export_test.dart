import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_setup_mapper.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/runtime_trainer_battle_overrides.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('trainer-items-export-');
  });

  tearDown(() => root.delete(recursive: true));

  test(
    'exported trainer consumes two catalogue items and reloads fresh stock',
    () async {
      final package = await _exportPackage(root);
      final archiveBytes = await package.readAsBytes();
      final bundle = await _installBundle(
        package,
        Directory(p.join(root.path, 'first')),
      );
      final catalog = await _loadItems(bundle);
      expect(bundle.manifest.trainers.single.battleItems, {'test_tonic': 2});
      expect(bundle.manifest.pokemon.catalogFiles['items'], _itemsPath);
      expect(catalog.definitionFor('test_tonic')?.displayName, 'Tonic Alpha');
      expect(
        await File(p.join(bundle.projectRootDirectory, _itemsPath))
            .readAsString(),
        jsonEncode(encodeProjectItemCatalog(_itemCatalog)),
      );

      const gameState = _gameState;
      final bagBefore = gameState.bag.toJson();
      final trainerBefore = bundle.manifest.trainers.single.toJson();
      final session = await _trainerSession(bundle, catalog, gameState);
      final firstTurns = _consumeTrainerStock(session);

      expect(firstTurns.map((turn) => _consumedItems(turn).length), [1, 1, 0]);
      expect(firstTurns.expand(_consumedItems).map((event) => event.itemId), [
        'test_tonic',
        'test_tonic',
      ]);
      expect(
        firstTurns
            .expand((turn) => turn.timeline.events)
            .whereType<BattleHealTimelineEvent>()
            .where((event) => event.moveId == 'item:test_tonic')
            .map((event) => event.amount),
        [1, 1],
      );
      expect(bundle.manifest.trainers.single.toJson(), trainerBefore);
      expect(gameState.bag.toJson(), bagBefore);
      expect(session.opponentAi.itemOptions.single.quantity, 2);
      expect(await package.readAsBytes(), archiveBytes);

      final reloadedBundle = await _installBundle(
        package,
        Directory(p.join(root.path, 'second')),
      );
      final reloadedCatalog = await _loadItems(reloadedBundle);
      expect(reloadedBundle.manifest.trainers.single.battleItems, {
        'test_tonic': 2,
      });
      expect(reloadedCatalog.catalog, catalog.catalog);
      final freshSession = await _trainerSession(
        reloadedBundle,
        reloadedCatalog,
        gameState,
      );
      expect(freshSession.opponentAi.itemOptions.single.quantity, 2);
      expect(
        _consumeTrainerStock(freshSession)
            .map((turn) => _consumedItems(turn).length),
        [1, 1, 0],
      );
      expect(gameState.bag.toJson(), bagBefore);
      expect(await package.readAsBytes(), archiveBytes);
    },
  );

  test('runtime refuses a corrupted installed custom item catalogue', () async {
    final package = await _exportPackage(root);
    final bundle = await _installBundle(
      package,
      Directory(p.join(root.path, 'installed')),
    );
    await File(p.join(bundle.projectRootDirectory, _itemsPath))
        .writeAsString('{"catalog":"items","entries":[]}');

    await expectLater(
      () => _loadItems(bundle),
      throwsA(isA<RuntimeBattleSetupException>()),
    );
    expect(bundle.manifest.trainers.single.battleItems, {'test_tonic': 2});
  });
}

const _itemsPath = 'custom/battle/catalogues/trainer_items.json';

const _itemCatalog = ProjectItemCatalog(
  schemaVersion: 1,
  entries: [
    ProjectItemDefinition(
      id: 'test_tonic',
      displayName: 'Tonic Alpha',
      pocketId: 'medicine',
      uses: [
        ProjectItemUseDefinition(
          contexts: {ProjectItemUseContext.battle},
          target: ProjectItemTargetKind.partyMember,
          consumption: ProjectItemConsumptionPolicy.onApplied,
          effect: ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.flat,
            amount: 1,
          ),
        ),
      ],
    ),
  ],
);

const _gameState = GameState(
  saveId: 'test_save',
  currentMapId: 'test_field',
  playerPosition: GridPos(x: 1, y: 1),
  bag: Bag(entries: [BagEntry(itemId: 'test_tonic', quantity: 7)]),
  party: PlayerParty(
    members: [
      PlayerPokemon(
        speciesId: 'test_species',
        natureId: 'hardy',
        abilityId: 'test_ability',
        level: 10,
        currentHp: 30,
        knownMoveIds: ['test_strike', 'splash'],
        currentPpByMoveId: {'test_strike': 40, 'splash': 40},
      ),
    ],
  ),
);

ProjectManifest _project() => const ProjectManifest(
  name: 'Trainer item export fixture',
  maps: [
    ProjectMapEntry(
      id: 'test_field',
      name: 'Test field',
      relativePath: 'maps/test_field.json',
    ),
  ],
  tilesets: [],
  pokemon: ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    dataRoot: 'custom/battle',
    speciesDir: 'custom/battle/species',
    catalogFiles: {
      'moves': 'custom/battle/catalogues/moves.json',
      'items': _itemsPath,
    },
  ),
  trainers: [
    ProjectTrainerEntry(
      id: 'trainer_alpha',
      name: 'Trainer Alpha',
      trainerClass: 'Trainer',
      battleDifficulty: 10,
      battleItems: {'test_tonic': 2},
      team: [
        ProjectTrainerPokemonEntry(
          speciesId: 'test_species',
          level: 10,
          moves: ['splash'],
        ),
      ],
    ),
  ],
);

const _map = MapData(
  id: 'test_field',
  name: 'Test field',
  size: GridSize(width: 4, height: 3),
  entities: [
    MapEntity(
      id: 'npc_alpha',
      name: 'Trainer Alpha',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 2, y: 1),
      npc: MapEntityNpcData(
        displayName: 'Trainer Alpha',
        trainerId: 'trainer_alpha',
      ),
    ),
  ],
);

Future<File> _exportPackage(Directory root) async {
  final project = _project();
  ProjectValidator.validate(project, itemCatalog: _itemCatalog);
  final payload = <String, List<int>>{
    'project/project.json': utf8.encode(jsonEncode(project.toJson())),
    'project/maps/test_field.json': utf8.encode(jsonEncode(_map.toJson())),
    'project/$_itemsPath': utf8.encode(
      jsonEncode(encodeProjectItemCatalog(_itemCatalog)),
    ),
    'project/custom/battle/species/test_species.json': utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'id': 'test_species',
        'slug': 'test_species',
        'nationalDex': 1,
        'names': {'en': 'Test Species'},
        'typing': {
          'types': ['normal'],
        },
        'baseStats': {
          'hp': 100,
          'atk': 100,
          'def': 100,
          'spa': 100,
          'spd': 100,
          'spe': 100,
          'bst': 600,
        },
        'abilities': {'primary': 'test_ability'},
        'progression': {
          'growthRateId': 'medium_fast',
          'baseExp': 10,
          'catchRate': 45,
        },
        'dexContent': {'heightM': 1, 'weightKg': 1},
      }),
    ),
    'project/custom/battle/catalogues/moves.json': utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'catalog': 'moves',
        'entries': [
          const PokemonMove(
            id: 'test_strike',
            name: 'Test strike',
            type: 'normal',
            category: PokemonMoveCategory.physical,
            basePower: 40,
            accuracy: PokemonMoveAccuracy.alwaysHits(),
            pp: 40,
            engineSupportLevel:
                PokemonMoveEngineSupportLevel.structuredSupported,
          ).toJson(),
          const PokemonMove(
            id: 'splash',
            name: 'Test wait',
            type: 'normal',
            category: PokemonMoveCategory.status,
            target: PokemonMoveTarget.self,
            accuracy: PokemonMoveAccuracy.alwaysHits(),
            pp: 40,
            engineSupportLevel:
                PokemonMoveEngineSupportLevel.structuredSupported,
          ).toJson(),
        ],
      }),
    ),
  };
  final built = const GamePackageBuilder().build(
    manifest: _packageManifest(project.version.name),
    payloadFiles: payload,
  );
  final file = File(p.join(root.path, 'trainer-items.avelunegame'));
  await file.writeAsBytes(built.packageBytes, flush: true);
  return file;
}

GamePackageHostCompatibility _hostCompatibility(String projectFormat) =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('1.2.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const {'map@1', 'catalog.partitioned@2'},
      supportedProjectFormats: {projectFormat},
      currentProjectFormat: projectFormat,
      supportedSaveFormats: const {1},
    );

Future<RuntimeMapBundle> _installBundle(
  File package,
  Directory supportRoot,
) async {
  final host = _hostCompatibility(_project().version.name);
  final inspector = GamePackageInspector(hostCompatibility: host);
  final installation = await GamePackageInstaller(
    supportRoot: supportRoot,
    inspector: inspector,
    availableDiskBytes: (_) async => 1024 * 1024 * 1024,
    loadSmoke: (stagedVersion, _) async {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: p.join(stagedVersion.path, 'project', 'project.json'),
        mapId: 'test_field',
      );
      try {
        await _loadItems(bundle);
      } finally {
        bundle.projectCatalog?.dispose();
      }
    },
    prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
  ).install(package, source: GamePackageInstallSource.localExport);
  final launch = await InstalledGameLaunchResolver(
    supportRoot: supportRoot,
    hostCompatibility: host,
  ).resolve(installation.game);
  final projectFile = await launch.assets.resolveReference(launch.project);
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile.path,
    mapId: 'test_field',
  );
  addTearDown(() => bundle.projectCatalog?.dispose());
  return bundle;
}

Future<ItemCatalogSnapshot> _loadItems(RuntimeMapBundle bundle) =>
    const RuntimeItemCatalogLoader().loadSnapshot(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );

Future<RuntimePsdkBattleSessionAdapter> _trainerSession(
  RuntimeMapBundle bundle,
  ItemCatalogSnapshot catalog,
  GameState gameState,
) async {
  final world = GameplayWorldState.initial(
    map: bundle.map,
    project: bundle.manifest,
    playerPos: gameState.playerPosition,
    playerFacing: Direction.east,
  );
  final request = buildTrainerBattleRequestFromNpc(
    entity: bundle.map.entities.single,
    manifest: bundle.manifest,
    world: world,
    createdAtEpochMs: 1,
  );
  expect(request?.trainerId, 'trainer_alpha');
  final setup = await RuntimePsdkBattleSetupMapper().map(
    bundle: bundle,
    gameState: gameState,
    request: request!,
    itemCatalog: catalog,
  );
  expect(setup.isTrainerBattle, isTrue);
  expect(setup.opponent.speciesId, 'test_species');
  final ai = resolveRuntimeTrainerPsdkAi(
    request: request,
    manifest: bundle.manifest,
    itemCatalog: catalog,
  );
  expect(ai.canUseItem, isTrue);
  expect(ai.itemOptions.single.quantity, 2);
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    setup,
    opponentAi: ai,
    itemDisplayNames: {
      for (final item in catalog.definitions) item.id: item.displayName,
    },
  );
}

List<BattleEngineTurnResult> _consumeTrainerStock(
  RuntimePsdkBattleSessionAdapter session,
) {
  final setupTurn = session.submitPlayerChoice(
    const PlayerBattleChoiceFight(0),
  );
  expect(_consumedItems(setupTurn), isEmpty);
  final damaged = session.state.battlerAt(psdkOpponentSlot);
  expect(damaged.maxHp - damaged.currentHp, greaterThanOrEqualTo(2));
  final turns = <BattleEngineTurnResult>[];
  for (var turn = 0; turn < 3; turn++) {
    turns.add(session.submitPlayerChoice(const PlayerBattleChoiceFight(1)));
    if (turn < 2) {
      final display = session.createLegacyDisplaySession(isTrainerBattle: true);
      expect(
        buildBattleTurnLinesForOverlay(display.state.currentTurn!).join('\n'),
        contains('Tonic Alpha'),
      );
    }
  }
  return turns;
}

List<BattleItemTimelineEvent> _consumedItems(BattleEngineTurnResult turn) =>
    turn.timeline.events
        .whereType<BattleItemTimelineEvent>()
        .where((event) => event.kind == 'item_consumed' && event.user.bank == 1)
        .toList(growable: false);

GamePackageManifest _packageManifest(String projectFormat) =>
    GamePackageManifest(
      packageFormat: 1,
      gameId: 'games.example.trainer-items',
      gameVersion: Version.parse('1.0.0'),
      title: 'Trainer item fixture',
      author: const GamePackageParty(name: 'Test'),
      compatibility: GamePackageCompatibility(
        minHubVersion: Version.parse('0.1.0'),
        runtimeApiExpression: '>=1.0.0 <2.0.0',
        projectFormat: projectFormat,
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
