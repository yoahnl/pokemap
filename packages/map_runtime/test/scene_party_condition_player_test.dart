import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/scene_catalog_pokemon_gift_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fullParty = PlayerParty(
    members: [for (var index = 0; index < 6; index++) _pokemon('$index')],
  );
  final fullStorage = PokemonStorage(
    boxes: [
      PokemonBox(
        id: 'box',
        label: 'Box',
        capacity: 1,
        pokemon: [_pokemon('stored')],
      ),
    ],
  );
  final cases = [
    (
      name: 'reception with a free team slot',
      source: SceneConditionSource.partyCanReceivePokemon(),
      state: const GameState(saveId: 'party-condition'),
      expected: true,
    ),
    (
      name: 'reception with a free storage slot',
      source: SceneConditionSource.partyCanReceivePokemon(),
      state: GameState(
        saveId: 'party-condition',
        party: fullParty,
        pokemonStorage: const PokemonStorage(
          boxes: [PokemonBox(id: 'box', label: 'Box', capacity: 1)],
        ),
      ),
      expected: true,
    ),
    (
      name: 'reception with team and storage full',
      source: SceneConditionSource.partyCanReceivePokemon(),
      state: GameState(
        saveId: 'party-condition',
        party: fullParty,
        pokemonStorage: fullStorage,
      ),
      expected: false,
    ),
    (
      name: 'known move on a fainted member at zero PP',
      source: SceneConditionSource.partyKnowsMove(moveId: 'tick'),
      state: GameState(
        saveId: 'party-condition',
        party: PlayerParty(members: [_pokemon('member', hp: 0, pp: 0)]),
      ),
      expected: true,
    ),
    (
      name: 'known move only in storage',
      source: SceneConditionSource.partyKnowsMove(moveId: 'tick'),
      state: GameState(saveId: 'party-condition', pokemonStorage: fullStorage),
      expected: false,
    ),
    for (final pp in [0, 1])
      (
        name: 'usable move at $pp PP',
        source: SceneConditionSource.partyHasUsableMove(moveId: 'tick'),
        state: GameState(
          saveId: 'party-condition',
          party: PlayerParty(members: [_pokemon('member', pp: pp)]),
        ),
        expected: pp > 0,
      ),
    (
      name: 'usable move on a fainted member',
      source: SceneConditionSource.partyHasUsableMove(moveId: 'tick'),
      state: GameState(
        saveId: 'party-condition',
        party: PlayerParty(members: [_pokemon('member', hp: 0)]),
      ),
      expected: false,
    ),
    for (final unlocked in [false, true])
      (
        name: 'terrain at zero PP when unlocked is $unlocked',
        source: SceneConditionSource.partyCanUseFieldAbility(
          ability: FieldAbility.surf,
        ),
        state: GameState(
          saveId: 'party-condition',
          party: PlayerParty(
            members: [_pokemon('member', moveId: 'surf', pp: 0)],
          ),
          progression: PlayerProgression(
            unlockedFieldAbilities: unlocked ? [FieldAbility.surf] : [],
          ),
        ),
        expected: unlocked,
      ),
    (
      name: 'inverted known move',
      source: SceneConditionSource.partyKnowsMove(
        moveId: 'tick',
        expected: false,
      ),
      state: GameState(
        saveId: 'party-condition',
        party: PlayerParty(members: [_pokemon('member')]),
      ),
      expected: false,
    ),
  ];
  for (final item in cases) {
    testWidgets('mounted Player ${item.name} after save reload', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp(
          'scene-party-player-',
        );
        addTearDown(() => root.delete(recursive: true));
        final config = await _catalog(root);
        final bundle = _bundle(root, config, item.source);
        final restored = GameState.fromJson(item.state.toJson());
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: '${root.path}/project.json',
          saveData: saveDataFromGameState(restored),
        );
        addTearDown(game.onRemove);
        game.onGameResize(Vector2(320, 240));
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(game: game),
          ),
        );
        await game.loaded;
        await tester.pump();
        await game.debugWaitForBattlePrewarm();
        for (
          var index = 0;
          index < 100 && game.debugIsMapActivationDispatchInFlight;
          index++
        ) {
          game.update(0);
          await Future<void>.value();
        }
        final initialMoney = game.gameStateSnapshot.trainerProfile.money;
        final result = await game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'party-event',
            sceneId: 'party-check',
            executionId: 'party-run',
            gameState: game.gameStateSnapshot,
          ),
        );
        expect(
          result,
          isA<NarrativeSceneExecutionCompleted>(),
          reason: result is NarrativeSceneExecutionFailed
              ? result.failure.toString()
              : null,
        );
        final completed = result as NarrativeSceneExecutionCompleted;
        expect(
          completed.updatedGameState.trainerProfile.money,
          initialMoney + (item.expected ? 1 : 2),
        );
        final reloaded = GameState.fromJson(
          completed.updatedGameState.toJson(),
        );
        expect(reloaded.toJson(), completed.updatedGameState.toJson());
        expect(
          evaluateScenePartyCondition(
            source: item.source,
            gameState: reloaded,
            context: ScenePartyConditionContext(
              availableMoveIds: {'tick', 'tock', 'surf'},
              supportedFieldAbilities: {FieldAbility.surf},
            ),
          ),
          item.expected,
        );
      });
    });
  }
  testWidgets('map-enter branch commits once and survives Player save reload', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('scene-party-save-');
      addTearDown(() => root.delete(recursive: true));
      final config = await _catalog(root);
      final base = _bundle(
        root,
        config,
        SceneConditionSource.partyHasUsableMove(moveId: 'tick'),
      );
      final bundle = base.copyWith(
        manifest: base.manifest.copyWith(
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            legacyClaims: const [],
            records: [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: 'evt_019abcde-1100-7000-8000-000000000001',
                  name: 'Party branch on entry',
                  source: NarrativeEventSourceRef.mapEnter('map'),
                  sceneId: 'party-check',
                  conditions: const [],
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: 0,
                ),
                enabled: true,
              ),
            ],
          ),
        ),
      );
      final initial = GameState(
        saveId: 'party-save',
        party: PlayerParty(members: [_pokemon('member')]),
      );
      final first = PlayableMapGame(
        bundle: bundle,
        projectFilePath: '${root.path}/project.json',
        saveData: saveDataFromGameState(initial),
      );
      addTearDown(first.onRemove);
      await _mount(tester, first);
      expect(
        first.gameStateSnapshot.trainerProfile.money,
        initial.trainerProfile.money + 1,
      );
      final save = File('${root.path}/save.json');
      await save.writeAsString(
        jsonEncode(saveDataFromGameState(first.gameStateSnapshot).toJson()),
      );
      final restored = SaveData.fromJson(
        jsonDecode(await save.readAsString()) as Map<String, dynamic>,
      );
      final second = PlayableMapGame(
        bundle: bundle,
        projectFilePath: '${root.path}/project.json',
        saveData: restored,
        initialMapActivationReason: MapActivationReason.saveRestore,
      );
      addTearDown(second.onRemove);
      await _mount(tester, second);
      expect(
        second.gameStateSnapshot.trainerProfile.money,
        initial.trainerProfile.money + 1,
      );
      expect(second.gameStateSnapshot.party.members.single.currentPpByMoveId, {
        'tick': 1,
      });
    });
  });
  testWidgets('removed Player rejects Scene preparation without a commit', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('scene-party-cancel-');
      addTearDown(() => root.delete(recursive: true));
      final config = await _catalog(root);
      final game = PlayableMapGame(
        bundle: _bundle(
          root,
          config,
          SceneConditionSource.partyKnowsMove(moveId: 'tick'),
        ),
        projectFilePath: '${root.path}/project.json',
        saveData: saveDataFromGameState(
          GameState(
            saveId: 'party-cancel',
            party: PlayerParty(members: [_pokemon('member')]),
          ),
        ),
      );
      game.onGameResize(Vector2(320, 240));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GameWidget(game: game),
        ),
      );
      await game.loaded;
      await tester.pump();
      await game.debugWaitForBattlePrewarm();
      final before = game.gameStateSnapshot.toJson();
      final execution = game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(
          eventId: 'party-event',
          sceneId: 'party-check',
          executionId: 'cancel-run',
          gameState: game.gameStateSnapshot,
        ),
      );
      game.onRemove();
      await expectLater(execution, throwsStateError);
      expect(game.gameStateSnapshot.toJson(), before);
    });
  });
}

Future<void> _mount(WidgetTester tester, PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await game.loaded;
  await tester.pump();
  await game.debugWaitForBattlePrewarm();
  for (
    var index = 0;
    index < 500 && game.debugIsMapActivationDispatchInFlight;
    index++
  ) {
    game.update(0);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(game.debugIsMapActivationDispatchInFlight, isFalse);
}

Future<ProjectPokemonConfig> _catalog(Directory root) async {
  final config = await writeSceneCatalogPokemonGiftFixture(root);
  final file = File('${root.path}/custom/moves.json');
  final document =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  (document['entries'] as List<dynamic>).add(
    const PokemonMove(
      id: 'surf',
      name: 'Surf',
      type: 'water',
      category: PokemonMoveCategory.special,
      accuracy: PokemonMoveAccuracy.percent(value: 100),
      pp: 15,
    ).toJson(),
  );
  await file.writeAsString(jsonEncode(document));
  return config;
}

RuntimeMapBundle _bundle(
  Directory root,
  ProjectPokemonConfig config,
  SceneConditionSource source,
) => RuntimeMapBundle(
  projectRootDirectory: root.path,
  tilesetAbsolutePathsById: const {},
  map: const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 8, height: 8),
    layers: [],
  ),
  manifest: ProjectManifest(
    name: 'Party condition fixture',
    maps: [
      const ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: [],
    pokemon: config,
    scenes: [
      SceneAsset(
        id: 'party-check',
        name: 'Party check',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(conditionSource: source),
            ),
            for (final value in [true, false])
              SceneNode(
                id: '$value',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.giveMoney(amount: value ? 1 : 2),
                ),
              ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            _edge('enter', 'start', 'completed', 'condition'),
            for (final value in [true, false]) ...[
              _edge('branch-$value', 'condition', '$value', '$value'),
              _edge('finish-$value', '$value', 'completed', 'end'),
            ],
          ],
        ),
      ),
    ],
  ),
);

SceneEdge _edge(String id, String from, String port, String to) => SceneEdge(
  id: id,
  fromNodeId: from,
  fromPortId: port,
  toNodeId: to,
  kind: switch (port) {
    'true' => SceneEdgeKind.conditionTrue,
    'false' => SceneEdgeKind.conditionFalse,
    _ => SceneEdgeKind.defaultFlow,
  },
);

PlayerPokemon _pokemon(
  String id, {
  String moveId = 'tick',
  int hp = 10,
  int pp = 1,
}) => PlayerPokemon(
  individualId: id,
  speciesId: 'clockbird',
  formId: 'bronze',
  natureId: 'hardy',
  abilityId: 'clockwork',
  level: 7,
  currentHp: hp,
  knownMoveIds: [moveId],
  currentPpByMoveId: {moveId: pp},
);
