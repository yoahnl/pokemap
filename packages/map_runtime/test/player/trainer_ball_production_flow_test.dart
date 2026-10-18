import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_ball_throw_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    '2D Player binds each authored trainer Ball to its enemy lineup slot',
    () async {
      final fixture = await _fixture();
      final game = PlayableMapGame(
        bundle: fixture.bundle,
        projectFilePath: '${fixture.bundle.projectRootDirectory}/project.json',
        saveData: saveDataFromGameState(fixture.state),
      );
      addTearDown(game.onRemove);
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await game.debugOpenBattleForTest(_trainerRequest);
      await game.debugWaitForBattleOverlaySync();

      final overlay = game.debugBattleOverlayComponent;
      expect(overlay, isNotNull);
      expect(game.debugPsdkBattleSessionActive, isTrue);
      expect(
        overlay!.resolveCombatantBallItemId?.call(BattleSideId.enemy, 0),
        'first-orb',
      );
      expect(
        overlay.resolveCombatantBallItemId?.call(BattleSideId.enemy, 1),
        'reserve-orb',
      );
      expect(
        overlay.resolveCombatantBallItemId?.call(BattleSideId.enemy, 2),
        isNull,
      );
    },
  );

  test(
    '2D Player trainer intro renders its portrait then the authored Balls',
    () async {
      final fixture = await _fixture();
      final game = await _game(fixture);
      await _ticks(game, () => !game.debugIsMapActivationDispatchInFlight);
      game.debugStartBattleHandoffForTest(_trainerRequest);
      await _ticks(game, () => game.debugBattleOverlayMounted);
      final overlay = game.debugBattleOverlayComponent!;
      await _ticks(game, () => overlay.isLoaded);
      final trainer = overlay.debugIntroTrainerSprite;
      expect(trainer, isNotNull);
      expect(trainer!.image.width, 32);
      expect(await _redPixel(trainer.image), 180);
      expect(trainer.debugOffsetX, lessThan(0));
      expect(overlay.debugEnemySpriteOpacity, 0);
      expect(overlay.debugPlayerSpriteOpacity, 0);

      final observed = <BattleBallThrowComponent, int>{};
      await _ticks(
        game,
        () =>
            !game.debugBattleTransitionOverlayMounted &&
            !overlay.isTurnPresentationActive,
        observe: () => _observeBalls(overlay, observed),
        acknowledge: overlay,
      );
      expect(observed.values, [41, 11]);
      expect(overlay.debugIntroTrainerSprite, isNull);
      expect(overlay.debugEnemySpriteOpacity, 1);
      expect(overlay.debugPlayerSpriteOpacity, 1);

      overlay.onPlayerChoice(const PlayerBattleChoiceFight(0));
      await game.debugWaitForBattleOverlaySync();
      await _ticks(
        game,
        () =>
            game.debugBattleSessionSnapshot!.state.enemy.lineupIndex == 1 &&
            !game.debugIsBattleResolving &&
            !overlay.isTurnPresentationActive,
        observe: () => _observeBalls(overlay, observed),
        acknowledge: overlay,
      );
      expect(observed.values, [41, 11, 41, 99]);
      expect(observed.keys.last.kind, BattleBallSequenceKind.sendOutHeld);

      overlay.onPlayerChoice(const PlayerBattleChoiceFight(0));
      await game.debugWaitForBattleOverlaySync();
      await _ticks(
        game,
        () =>
            game.debugBattleSessionSnapshot!.state.enemy.lineupIndex == 2 &&
            !game.debugIsBattleResolving &&
            !overlay.isTurnPresentationActive,
        observe: () => _observeBalls(overlay, observed),
        acknowledge: overlay,
      );
      expect(observed.values, [41, 11, 41, 99, 99]);
      expect(
        observed.entries
            .where((entry) => entry.key.kind != BattleBallSequenceKind.recall)
            .map((entry) => entry.value),
        [41, 11, 99],
      );
      expect(overlay.debugEnemySpriteOpacity, 1);
    },
  );

  for (final request in <BattleStartRequest>[_wildRequest, _staticRequest]) {
    test('2D Player ${request.kind.name} never sends an enemy Ball', () async {
      final fixture = await _fixture();
      final game = await _game(fixture);
      await _ticks(game, () => !game.debugIsMapActivationDispatchInFlight);
      game.debugStartBattleHandoffForTest(request);
      await _ticks(game, () => game.debugBattleOverlayMounted);
      final overlay = game.debugBattleOverlayComponent!;
      await _ticks(game, () => overlay.isLoaded);
      expect(
        overlay.resolveCombatantBallItemId?.call(BattleSideId.player, 0),
        'player-orb',
      );
      for (final slot in [0, 1, 2]) {
        expect(
          overlay.resolveCombatantBallItemId?.call(BattleSideId.enemy, slot),
          isNull,
        );
      }
      expect(overlay.debugIntroTrainerSprite, isNull);
      final observed = <BattleBallThrowComponent, int>{};
      await _ticks(
        game,
        () =>
            !game.debugBattleTransitionOverlayMounted &&
            !overlay.isTurnPresentationActive,
        observe: () => _observeBalls(overlay, observed),
        acknowledge: overlay,
      );
      expect(observed.values, [11]);
      expect(overlay.debugEnemySpriteOpacity, 1);
    });
  }

  test(
    'spatial cancellation before mounting releases the trainer portrait',
    () async {
      final fixture = await _fixture();
      final budget = fixture.bundle.resourceBudget;
      final baseline = (budget.residentBytes, budget.transientBytes);
      final runtime = SpatialBattleRuntime(
        readGameState: () => fixture.state,
        commitGameState: (_, _) => true,
      );
      addTearDown(runtime.dispose);
      final completion = runtime.start(
        bundle: fixture.bundle,
        request: _trainerRequest,
      );
      for (
        var index = 0;
        index < 800 && runtime.battleOverlay == null;
        index++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(runtime.error, isNull);
      final overlay = runtime.battleOverlay;
      expect(overlay, isNotNull);
      expect(overlay!.parent, isNull);
      expect(overlay.isLoaded, isFalse);
      expect(budget.residentBytes, greaterThan(baseline.$1));

      runtime.cancel();

      expect(await completion, isFalse);
      expect((budget.residentBytes, budget.transientBytes), baseline);
    },
  );

  for (final characterPortrait in [false, true]) {
    testWidgets(
      'spatial Player trainer intro and replacement, characterPortrait=$characterPortrait',
      (tester) async {
        final fixture = (await tester.runAsync(
          () => _fixture(characterPortrait: characterPortrait),
        ))!;
        final runtime = SpatialBattleRuntime(
          readGameState: () => fixture.state,
          commitGameState: (_, _) => true,
        );
        addTearDown(runtime.dispose);
        late Future<bool> completion;
        await tester.runAsync(() async {
          completion = runtime.start(
            bundle: fixture.bundle,
            request: _trainerRequest,
          );
          for (
            var index = 0;
            index < 800 && runtime.battleOverlay == null;
            index++
          ) {
            await Future<void>.delayed(Duration.zero);
          }
        });
        expect(runtime.error, isNull);
        final overlay = runtime.battleOverlay;
        expect(overlay, isNotNull);
        await tester.pumpWidget(
          MaterialApp(home: SpatialBattleView(runtime: runtime)),
        );
        await _spatialTicks(
          tester,
          runtime,
          () => overlay!.isMounted,
          advanceTime: false,
        );
        final trainer = overlay!.debugIntroTrainerSprite;
        expect(trainer, isNotNull);
        expect(await tester.runAsync(() => _redPixel(trainer!.image)), 180);
        expect(overlay.debugEnemySpriteOpacity, 0);
        expect(
          overlay.resolveCombatantBallItemId?.call(BattleSideId.enemy, 0),
          'first-orb',
        );
        expect(
          overlay.resolveCombatantBallItemId?.call(BattleSideId.enemy, 1),
          'reserve-orb',
        );
        expect(
          overlay.resolveCombatantBallItemId?.call(BattleSideId.enemy, 2),
          isNull,
        );
        final observed = <BattleBallThrowComponent, int>{};
        await _spatialTicks(
          tester,
          runtime,
          () =>
              runtime.phase == SpatialBattlePhase.battle &&
              runtime.battlePresentationListenable.value?.interactionsEnabled ==
                  true,
          observed: observed,
        );
        expect(observed.values, [41, 11]);
        expect(overlay.debugIntroTrainerSprite, isNull);
        expect(overlay.debugEnemySpriteOpacity, 1);
        expect(overlay.debugPlayerSpriteOpacity, 1);
        var submitted = false;
        final turn = runtime.submitChoice(const PlayerBattleChoiceFight(0))
          ..then((value) => submitted = value);
        await _spatialTicks(
          tester,
          runtime,
          () =>
              submitted &&
              runtime.displaySession!.state.enemy.lineupIndex == 1 &&
              !overlay.isTurnPresentationActive,
          observed: observed,
        );
        expect(await turn, isTrue);
        expect(observed.values, [41, 11, 41, 99]);
        runtime.cancel();
        expect(await tester.runAsync(() => completion), isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

Future<void> _spatialTicks(
  WidgetTester tester,
  SpatialBattleRuntime runtime,
  bool Function() done, {
  bool advanceTime = true,
  Map<BattleBallThrowComponent, int>? observed,
}) async {
  for (var index = 0; index < 1200; index++) {
    if (done()) return;
    await tester.pump(advanceTime ? const Duration(milliseconds: 50) : null);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      if (observed != null) {
        await _observeBalls(runtime.battleOverlay!, observed);
      }
    });
    final overlay = runtime.battleOverlay;
    if (overlay?.isTurnPresentationActive == true &&
        overlay?.debugCurrentAnimationMessage != null) {
      overlay!.validateSelectedChoice();
    }
  }
  fail('Spatial Player did not reach the expected state: ${runtime.error}');
}

Future<PlayableMapGame> _game(
  ({RuntimeMapBundle bundle, GameState state}) fixture,
) async {
  final game = PlayableMapGame(
    bundle: fixture.bundle,
    projectFilePath: '${fixture.bundle.projectRootDirectory}/project.json',
    saveData: saveDataFromGameState(fixture.state),
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  return game;
}

Future<void> _ticks(
  PlayableMapGame game,
  bool Function() done, {
  Future<void> Function()? observe,
  BattleOverlayComponent? acknowledge,
}) async {
  for (var index = 0; index < 1600; index++) {
    if (done()) return;
    game.update(0.02);
    await Future<void>.delayed(Duration.zero);
    await observe?.call();
    if (acknowledge?.isTurnPresentationActive == true &&
        acknowledge?.debugCurrentAnimationMessage != null) {
      acknowledge!.validateSelectedChoice();
    }
  }
  fail('Player battle did not reach the expected presentation state.');
}

Future<void> _observeBalls(
  BattleOverlayComponent overlay,
  Map<BattleBallThrowComponent, int> observed,
) async {
  for (final ball in overlay.children.whereType<BattleBallThrowComponent>()) {
    observed.putIfAbsent(ball, () => -1);
    if (observed[ball] == -1) observed[ball] = await _redPixel(ball.sheet);
  }
}

Future<int> _redPixel(ui.Image sheet) async {
  final bytes = await sheet.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bytes!.getUint8(0);
}

const _returnContext = OverworldReturnContext(
  mapId: 'golden_field',
  playerPos: GridPos(x: 1, y: 1),
  playerFacing: Direction.east,
);

const _trainerRequest = TrainerBattleStartRequest(
  requestId: 'trainer-balls',
  createdAtEpochMs: 1,
  returnContext: _returnContext,
  trainerId: 'trainer_rookie',
  npcEntityId: 'trainer-npc',
  mapId: 'golden_field',
  playerPos: GridPos(x: 1, y: 1),
);

const _wildRequest = WildBattleStartRequest(
  requestId: 'wild-balls',
  createdAtEpochMs: 1,
  returnContext: _returnContext,
  mapId: 'golden_field',
  encounterSourceId: 'grass',
  encounterSourceKind: EncounterSourceKind.gameplayZone,
  tableId: 'golden_grass',
  encounterKind: EncounterKind.walk,
  speciesId: 'sparkitten',
  level: 2,
  minLevel: 2,
  maxLevel: 2,
  weight: 1,
  playerPos: GridPos(x: 1, y: 1),
);

const _staticRequest = StaticBattleStartRequest(
  requestId: 'static-balls',
  createdAtEpochMs: 1,
  returnContext: _returnContext,
  battleId: 'static-boss',
  opponentProfileId: 'trainer_rookie',
  entityId: 'boss',
  mapId: 'golden_field',
  playerPos: GridPos(x: 1, y: 1),
);

Future<({RuntimeMapBundle bundle, GameState state})> _fixture({
  bool characterPortrait = false,
}) async {
  final source = Directory(
    '${Directory.current.path}/../../examples/playable_runtime_host/golden_battle_slice',
  );
  final temporary = await Directory.systemTemp.createTemp('trainer-balls-');
  addTearDown(() => temporary.delete(recursive: true));
  for (final file in source.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final target = File(
      '${temporary.path}${file.path.substring(source.path.length)}',
    );
    await target.parent.create(recursive: true);
    await file.copy(target.path);
  }
  final manifestFile = File('${temporary.path}/project.json');
  final json =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final trainer = (json['trainers'] as List).single as Map<String, dynamic>;
  trainer['battleSpriteRelativePath'] = 'assets/trainer.png';
  trainer.remove('battleBackgroundRelativePath');
  trainer['team'] = [
    {
      'speciesId': 'sparkitten',
      'level': 2,
      'moves': ['tackle'],
      'ballItemId': 'first-orb',
    },
    {
      'speciesId': 'sparkitten',
      'level': 2,
      'moves': ['tackle'],
      'ballItemId': 'reserve-orb',
    },
    {
      'speciesId': 'sparkitten',
      'level': 2,
      'moves': ['tackle'],
    },
  ];
  (json['pokemon'] as Map<String, dynamic>)['catalogFiles'] = {
    'moves': 'data/pokemon/catalogs/moves.json',
    'items': 'items.json',
  };
  await File('${temporary.path}/items.json').writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'entries': [
        for (final item in ['first-orb', 'reserve-orb', 'player-orb'])
          {
            'id': item,
            'displayName': item,
            'pocketId': 'balls',
            'capture': {
              'rateNumerator': 1,
              'rateDenominator': 1,
              'allowedEncounterKinds': ['walk'],
              'animationSpritePath': 'assets/$item.png',
            },
          },
      ],
    }),
  );
  for (final asset in [
    (name: 'first-orb', red: 41, width: 64, height: 2048),
    (name: 'reserve-orb', red: 99, width: 64, height: 2048),
    (name: 'player-orb', red: 11, width: 64, height: 2048),
    (name: 'trainer', red: 180, width: 32, height: 48),
  ]) {
    final pixels = image.Image(width: asset.width, height: asset.height);
    image.fill(pixels, color: image.ColorRgba8(asset.red, 1, 2, 255));
    final file = File('${temporary.path}/assets/${asset.name}.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(image.encodePng(pixels));
  }
  if (characterPortrait) {
    trainer.remove('battleSpriteRelativePath');
    trainer['characterId'] = 'mira';
    json['characterStudioCatalog'] = const ProjectCharacterStudioCatalog(
      portraitStates: [
        CharacterPortraitStateDefinition(id: 'neutre', displayName: 'Neutre'),
      ],
    ).toJson();
    json['characters'] = [
      const ProjectCharacterEntry(
        id: 'mira',
        name: 'Mira',
        tilesetId: 'unused-overworld',
        portraits: [
          CharacterPortraitVariant(
            portraitStateId: 'neutre',
            assetId: 'mira-neutral',
          ),
        ],
      ).toJson(),
    ];
    final png = await File('${temporary.path}/assets/trainer.png')
        .readAsBytes();
    final artifact = ContentArtifactRef.fromBytes(png, mediaType: 'image/png');
    final catalog = AssetCatalog(
      records: [
        AssetRecord(
          id: 'mira-neutral',
          logicalPath: 'assets/trainer.png',
          artifact: artifact,
        ),
      ],
    );
    final catalogFile = File('${temporary.path}/$assetCatalogStorageKey');
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(jsonEncode(catalog.toJson()));
    final blob = File('${temporary.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(png);
  }
  await manifestFile.writeAsString(jsonEncode(json));
  final manifest = ProjectManifest.fromJson(json);
  final save = SaveData.fromJson(
    jsonDecode(
      await File('${temporary.path}/runtime_host_launch_save.json')
          .readAsString(),
    ) as Map<String, dynamic>,
  );
  return (
    bundle: RuntimeMapBundle(
      manifest: manifest,
      map: const MapData(
        id: 'golden_field',
        name: 'Trainer Balls',
        size: GridSize(width: 4, height: 4),
      ),
      projectRootDirectory: temporary.path,
      tilesetAbsolutePathsById: const {},
    ),
    state: gameStateFromSaveData(save).copyWith(
      party: const PlayerParty(
        members: [
          PlayerPokemon(
            individualId: 'trainer-ball-player',
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 50,
            currentHp: 100,
            knownMoveIds: ['tackle'],
            provenance: PlayerPokemonProvenance(ballItemId: 'player-orb'),
          ),
        ],
      ),
    ),
  );
}
