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
import 'package:map_runtime/src/presentation/flame/runtime_trainer_battle_overrides.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('trainer-stats-export-');
  });

  tearDown(() => root.delete(recursive: true));

  test(
    'installed trainer stats reach the engine per member and survive reload independently of AI',
    () async {
      final playerBefore = jsonEncode(_gameState.toJson());
      final authoredMemberBefore = jsonEncode(_customMember);
      final statsByDifficulty = <int, List<List<int>>>{};

      for (final difficulty in [1, 10]) {
        final project = _project(difficulty);
        final authoredBefore = jsonEncode(project.toJson());
        final package = await _exportPackage(root, project, difficulty);
        final archiveBefore = await package.readAsBytes();

        for (final installation in ['first', 'reloaded']) {
          final bundle = await _installBundle(
            package,
            Directory(p.join(root.path, '$difficulty', installation)),
            project.version.name,
          );
          final installedBefore = jsonEncode(bundle.manifest.toJson());
          final trainer = bundle.manifest.trainers.single;
          final (setup, session) = await _trainerBattle(bundle);
          final setupParty = setup.partyForBank(psdkOpponentSlot.bank);
          final setupStats = setupParty.map(_setupStats).toList();

          expect(setupStats, _expectedTrainerStats);
          expect(
            session.state.psdkState
                .partyForBank(psdkOpponentSlot.bank)
                .map(_engineStats),
            _expectedTrainerStats,
          );
          expect(_setupStats(setup.player), [160, 105, 105, 105, 105, 105]);
          expect(
            _engineStats(session.state.battlerAt(psdkPlayerSlot)),
            [160, 105, 105, 105, 105, 105],
          );
          expect(session.opponentAi.level, difficulty == 1 ? 1 : 3);
          expect(session.opponentAi.canSwitch, difficulty == 10);
          expect(trainer.battleDifficulty, difficulty);
          expect(trainer.team.map((member) => member.speciesId), [
            'test_species',
            'test_species',
          ]);
          expect(trainer.team.map((member) => member.level), [50, 50]);
          expect(trainer.team.map((member) => member.moves), [
            ['test_strike'],
            ['test_strike'],
          ]);

          final standardJson = _jsonObject(trainer.team.first.toJson());
          for (final field in ['natureId', 'ivs', 'evs']) {
            expect(standardJson.containsKey(field), isFalse);
          }
          final customJson = _jsonObject(trainer.team.last.toJson());
          expect(customJson['natureId'], 'adamant');
          expect(customJson['ivs'], _customIvs);
          expect(customJson['evs'], _customEvs);

          final turnBefore = session.state.turnNumber;
          session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
          expect(session.state.turnNumber, greaterThan(turnBefore));
          expect(
            session.state.psdkState
                .partyForBank(psdkOpponentSlot.bank)
                .map(_engineStats),
            _expectedTrainerStats,
          );
          expect(
            session.state.battlerAt(psdkPlayerSlot).currentHp,
            lessThan(_gameState.party.members.single.currentHp),
          );
          expect(jsonEncode(bundle.manifest.toJson()), installedBefore);
          expect(jsonEncode(project.toJson()), authoredBefore);
          expect(jsonEncode(_customMember), authoredMemberBefore);
          expect(jsonEncode(_gameState.toJson()), playerBefore);
          expect(await package.readAsBytes(), archiveBefore);

          final previous = statsByDifficulty[difficulty];
          if (previous != null) {
            expect(setupStats, previous);
          }
          statsByDifficulty[difficulty] = setupStats;
        }
      }

      expect(statsByDifficulty[1], statsByDifficulty[10]);
      expect(
        statsByDifficulty[1]!.first,
        isNot(equals(statsByDifficulty[1]!.last)),
      );
    },
  );
}

const _customIvs = {
  'hp': 31,
  'attack': 31,
  'defense': 31,
  'specialAttack': 31,
  'specialDefense': 31,
  'speed': 31,
};

const _customEvs = {
  'hp': 252,
  'attack': 252,
  'defense': 0,
  'specialAttack': 0,
  'specialDefense': 0,
  'speed': 6,
};

const _customMember = {
  'speciesId': 'test_species',
  'level': 50,
  'moves': ['test_strike'],
  'natureId': 'adamant',
  'ivs': _customIvs,
  'evs': _customEvs,
};

const _expectedTrainerStats = [
  [167, 112, 112, 112, 112, 112],
  [207, 167, 120, 108, 120, 121],
];

const _gameState = GameState(
  saveId: 'test_save',
  currentMapId: 'test_field',
  playerPosition: GridPos(x: 1, y: 1),
  party: PlayerParty(
    members: [
      PlayerPokemon(
        speciesId: 'test_species',
        natureId: 'hardy',
        abilityId: 'test_ability',
        level: 50,
        ivs: PokemonStatSpread(),
        evs: PokemonStatSpread(),
        currentHp: 160,
        knownMoveIds: ['splash'],
        currentPpByMoveId: {'splash': 40},
      ),
    ],
  ),
);

ProjectManifest _project(int difficulty) => ProjectManifest(
  name: 'Trainer stat export fixture',
  maps: const [
    ProjectMapEntry(
      id: 'test_field',
      name: 'Test field',
      relativePath: 'maps/test_field.json',
    ),
  ],
  tilesets: const [],
  pokemon: const ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    dataRoot: 'custom/battle',
    speciesDir: 'custom/battle/species',
    catalogFiles: {'moves': 'custom/battle/catalogues/moves.json'},
  ),
  trainers: [
    ProjectTrainerEntry.fromJson({
      'id': 'generic_trainer_alpha',
      'name': 'Trainer Alpha',
      'trainerClass': 'Trainer',
      'battleDifficulty': difficulty,
      'team': [
        {
          'speciesId': 'test_species',
          'level': 50,
          'moves': ['test_strike'],
        },
        _customMember,
      ],
    }),
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
        trainerId: 'generic_trainer_alpha',
      ),
    ),
  ],
);

Future<File> _exportPackage(
  Directory root,
  ProjectManifest project,
  int difficulty,
) async {
  ProjectValidator.validate(project);
  final payload = <String, List<int>>{
    'project/project.json': utf8.encode(jsonEncode(project.toJson())),
    'project/maps/test_field.json': utf8.encode(jsonEncode(_map.toJson())),
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
  final file = File(p.join(root.path, 'trainer-stats-$difficulty.avelunegame'));
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
  String projectFormat,
) async {
  final host = _hostCompatibility(projectFormat);
  final installation = await GamePackageInstaller(
    supportRoot: supportRoot,
    inspector: GamePackageInspector(hostCompatibility: host),
    availableDiskBytes: (_) async => 1024 * 1024 * 1024,
    loadSmoke: (stagedVersion, _) async {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: p.join(stagedVersion.path, 'project', 'project.json'),
        mapId: 'test_field',
      );
      bundle.projectCatalog?.dispose();
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

Future<(PsdkBattleSetup, RuntimePsdkBattleSessionAdapter)> _trainerBattle(
  RuntimeMapBundle bundle,
) async {
  final world = GameplayWorldState.initial(
    map: bundle.map,
    project: bundle.manifest,
    playerPos: _gameState.playerPosition,
    playerFacing: Direction.east,
  );
  final request = buildTrainerBattleRequestFromNpc(
    entity: bundle.map.entities.single,
    manifest: bundle.manifest,
    world: world,
    createdAtEpochMs: 1,
  );
  expect(request?.trainerId, 'generic_trainer_alpha');
  final catalog = await const RuntimeItemCatalogLoader().loadSnapshot(
    projectRootDirectory: bundle.projectRootDirectory,
    pokemonConfig: bundle.manifest.pokemon,
  );
  final setup = await RuntimePsdkBattleSetupMapper().map(
    bundle: bundle,
    gameState: _gameState,
    request: request!,
    itemCatalog: catalog,
  );
  expect(setup.isTrainerBattle, isTrue);
  final ai = resolveRuntimeTrainerPsdkAi(
    request: request,
    manifest: bundle.manifest,
    itemCatalog: catalog,
  );
  return (
    setup,
    RuntimePsdkBattleSessionAdapter.fromSetup(setup, opponentAi: ai),
  );
}

List<int> _setupStats(PsdkBattleCombatantSetup combatant) => [
  combatant.maxHp,
  combatant.stats.attack,
  combatant.stats.defense,
  combatant.stats.specialAttack,
  combatant.stats.specialDefense,
  combatant.stats.speed,
];

List<int> _engineStats(PsdkBattleCombatant combatant) => [
  combatant.maxHp,
  combatant.stats.attack,
  combatant.stats.defense,
  combatant.stats.specialAttack,
  combatant.stats.specialDefense,
  combatant.stats.speed,
];

Map<String, dynamic> _jsonObject(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

GamePackageManifest _packageManifest(String projectFormat) =>
    GamePackageManifest(
      packageFormat: 1,
      gameId: 'games.example.trainer-stats',
      gameVersion: Version.parse('1.0.0'),
      title: 'Trainer stat fixture',
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
