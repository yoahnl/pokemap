import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';

const _npcCell = GridPos(x: 3, y: 3);
const _sceneIds = ['hide', 'show', 'explicit-absent', 'explicit-present'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final solid in [false, true]) {
    testWidgets('first connected destination instance projects temporary collision solid=$solid before commit', (tester) async {
      await tester.runAsync(() async {
        final game = await _mount(tester, presentationMode: solid ? 'connectionSolid' : 'connectionThrough');
        expect(game.gameStateSnapshot.mapInstanceWorldState.instanceRef('neighbor'), isNull);
        game.debugSetPlayerStateForTest(position: const GridPos(x: 7, y: 3), facing: Direction.east);
        game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.right));
        game.update(0);
        game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.right));
        for (var i = 0; i < 300; i++) {
          game.update(.02);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(game.gameStateSnapshot.currentMapId, solid ? 'main' : 'neighbor');
        expect(game.debugPlayerGridPosition, solid ? const GridPos(x: 7, y: 3) : const GridPos(x: 0, y: 3));
        expect(game.gameStateSnapshot.mapInstanceWorldState.instanceRef('neighbor'), solid ? isNull : isNotNull);
      });
    });
  }

  testWidgets('a custom presentation owner loses its actor when a World Rule hides it', (tester) async {
    await tester.runAsync(() async {
      final game = await _mount(tester, presentationMode: 'customOwner');
      _expectActor(game, 'main', present: true);
      await _execute(game, 'hide');
      _expectActor(game, 'main', present: false);
      await _expectCollision(game, blocked: false);
      await _execute(game, 'show');
      _expectActor(game, 'main', present: true);
      await _expectCollision(game, blocked: true);
    });
  });

  testWidgets('presentation changes remount the same owner and retain pose until declared facing changes', (tester) async {
    await tester.runAsync(() async {
      final game = await _mount(tester, presentationMode: 'variants');
      final original = _actors(game, 'main').single;
      expect(original.character.id, 'npc-main');
      original.restoreBase(EntityFacing.east);
      await _execute(game, 'show');
      expect(identical(_actors(game, 'main').single, original), isTrue);
      expect(original.facing, EntityFacing.east);
      await _execute(game, 'hide');
      final changed = _actors(game, 'main').single;
      expect(changed.character.id, 'alternate-main');
      expect(changed.gridPos, original.gridPos);
      expect(changed.facing, EntityFacing.west);
      await _expectCollision(game, blocked: false);
      await _execute(game, 'show');
      expect(_actors(game, 'main').single.character.id, 'npc-main');
      expect(_actors(game, 'main').single.facing, EntityFacing.south);
      await _expectCollision(game, blocked: true);
    });
  });

  testWidgets('no active presentation removes the actor and save reload restores its page', (tester) async {
    await tester.runAsync(() async {
      final game = await _mount(tester, presentationMode: 'presence');
      _expectActor(game, 'main', present: true);
      await _execute(game, 'hide');
      _expectActor(game, 'main', present: false);
      await _expectCollision(game, blocked: false);
      final saved = SaveData.fromJson(jsonDecode(jsonEncode(saveDataFromGameState(game.gameStateSnapshot))));
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = await _mount(tester, presentationMode: 'presence', saveData: saved);
      _expectActor(restored, 'main', present: false);
      await _execute(restored, 'show');
      _expectActor(restored, 'main', present: true);
      await _expectCollision(restored, blocked: true);
    });
  });

  testWidgets('World Rule cycles remount one actor and restore its collision', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester);
      _expectActor(game, 'main', present: true);
      await _expectCollision(game, blocked: true);
      for (var cycle = 0; cycle < 2; cycle++) {
        await _execute(game, 'hide');
        _expectActor(game, 'main', present: false);
        await _expectCollision(game, blocked: false);
        await _execute(game, 'show');
        _expectActor(game, 'main', present: true);
        await _expectCollision(game, blocked: true);
      }
    });
  });

  testWidgets('World Rule remounts NPCs on a loaded neighboring map', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester, initiallyHidden: true);
      expect(game.debugIsMapLoaded('neighbor'), isTrue);
      _expectActor(game, 'main', present: false);
      _expectActor(game, 'neighbor', present: false);
      await _execute(game, 'show');
      _expectActor(game, 'main', present: true);
      _expectActor(game, 'neighbor', present: true);
      final neighbor = _actors(game, 'neighbor').single;
      expect(neighbor.gridPos, _npcCell);
      expect(neighbor.position.x, 8 * 16 + 3 * 16 - 8);
      expect(neighbor.position.y, 3 * 16 - 16);
      await _execute(game, 'hide');
      _expectActor(game, 'neighbor', present: false);
      await _execute(game, 'show');
      _expectActor(game, 'neighbor', present: true);
      expect(identical(_actors(game, 'neighbor').single, neighbor), isFalse);
    });
  });

  testWidgets('serialized save reload and later changes keep NPCs coherent', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final first = await _mount(tester, initiallyHidden: true);
      await _execute(first, 'show');
      _expectActor(first, 'main', present: true);
      final saved = SaveData.fromJson(
        jsonDecode(jsonEncode(saveDataFromGameState(first.gameStateSnapshot))),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = await _mount(tester, saveData: saved);
      _expectActor(restored, 'main', present: true);
      _expectActor(restored, 'neighbor', present: true);
      await _expectCollision(restored, blocked: true);
      await _execute(restored, 'hide');
      _expectActor(restored, 'main', present: false);
      await _execute(restored, 'show');
      _expectActor(restored, 'main', present: true);
      await _expectCollision(restored, blocked: true);
    });
  });

  testWidgets('final presence preserves World Rule and Scene priorities', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester, initiallyHidden: true);
      _expectActor(game, 'main', present: false);
      await _execute(game, 'show');
      _expectActor(game, 'main', present: true);
      await _execute(game, 'explicit-absent');
      _expectActor(game, 'main', present: false);
      await _execute(game, 'hide');
      await _execute(game, 'show');
      _expectActor(game, 'main', present: false);
      await _execute(game, 'hide');
      await _execute(game, 'explicit-present');
      _expectActor(game, 'main', present: true);
      await _expectCollision(game, blocked: true);
      await _execute(game, 'hide');
      _expectActor(game, 'main', present: true);
    });
  });
}

List<OverworldActorComponent> _actors(PlayableMapGame game, String mapId) =>
    game.world.children
        .whereType<OverworldActorComponent>()
        .where((actor) => actor.character.id == 'npc-$mapId' || actor.character.id == 'alternate-$mapId')
        .toList();

void _expectActor(PlayableMapGame game, String mapId, {required bool present}) {
  expect(_actors(game, mapId), hasLength(present ? 1 : 0));
  if (present) {
    final actor = _actors(game, mapId).single;
    expect(actor.isMounted, isTrue);
    expect(actor.isGameplayPresent, isTrue);
    expect(actor.isVisible, isTrue);
    expect(actor.tileImages['actors']!.chunkCount, greaterThan(0));
  }
  if (mapId == 'main') {
    expect(game.debugIsNpcActorVisible('npc-main'), present ? isTrue : isNull);
  }
}

Future<void> _expectCollision(
  PlayableMapGame game, {
  required bool blocked,
}) async {
  game.debugSetPlayerStateForTest(
    position: const GridPos(x: 2, y: 3),
    facing: Direction.east,
  );
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    ),
    isTrue,
  );
  game.update(0);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.right),
  );
  await _settle(game);
  expect(
    game.debugPlayerGridPosition,
    blocked ? const GridPos(x: 2, y: 3) : _npcCell,
  );
  game.debugSetPlayerStateForTest(
    position: const GridPos(x: 1, y: 1),
    facing: Direction.south,
  );
}

Future<void> _execute(PlayableMapGame game, String sceneId) async {
  final y = _sceneIds.indexOf(sceneId) + 1;
  game.debugSetPlayerStateForTest(
    position: GridPos(x: 4, y: y),
    facing: Direction.east,
  );
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    ),
    isTrue,
  );
  game.update(0);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.right),
  );
  await _settle(game);
  expect(game.debugPlayerGridPosition, GridPos(x: 5, y: y));
  expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
  if (sceneId == 'hide' || sceneId == 'show') {
    expect(
      game
          .gameStateSnapshot
          .narrativeFactRuntimeState
          .overridesByFactId['hidden'],
      sceneId == 'hide',
    );
  }
}

Future<void> _settle(PlayableMapGame game) async {
  for (var i = 0; i < 30; i++) {
    game.update(.02);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<PlayableMapGame> _mount(
  WidgetTester tester, {
  bool initiallyHidden = false,
  SaveData? saveData,
  String? presentationMode,
}) async {
  RuntimeMapBundle load(String id) => _presentationBundle(id, presentationMode);
  final bundle = load('main');
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/world-rule-remount/project.json',
    saveData: saveData,
    initialGameState: saveData == null
        ? GameState(
            saveId: 'remount',
            currentMapId: 'main',
            playerPosition: const GridPos(x: 1, y: 1),
            narrativeFactRuntimeState: NarrativeFactRuntimeState(
              overridesByFactId: {'visible': true, 'hidden': initiallyHidden},
            ),
          )
        : null,
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => load(mapId),
    runtimeTilesetImageLoader:
        (paths, {transparentColorByTilesetId = const {}}) async {
          final recorder = ui.PictureRecorder();
          ui.Canvas(recorder).drawRect(
            const ui.Rect.fromLTWH(0, 0, 128, 128),
            ui.Paint()..color = const ui.Color(0xFF4060FF),
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(128, 128);
          picture.dispose();
          return {
            'actors': RuntimeTilesetImage(
              images: [image],
              chunks: const [
                RuntimeTilesetChunk(top: 0, height: 128, width: 128),
              ],
              width: 128,
              height: 128,
            ),
          };
        },
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
  addTearDown(game.onRemove);
  for (var i = 0; i < 500; i++) {
    if (!game.debugIsMapActivationDispatchInFlight &&
        game.debugIsMapLoaded('neighbor')) {
      break;
    }
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(game.debugIsMapActivationDispatchInFlight, isFalse);
  expect(game.debugIsMapLoaded('neighbor'), isTrue);
  await _settle(game);
  return game;
}

RuntimeMapBundle _presentationBundle(String id, String? mode) {
  final bundle = _bundle(id);
  if (mode == null) return bundle;
  final temporaryConnection = mode == 'connectionSolid' || mode == 'connectionThrough';
  final condition = NarrativeEventConditionExpression.leaf(NarrativeEventCondition.fact('hidden', true));
  return bundle.copyWith(manifest: bundle.manifest.copyWith(
    settings: temporaryConnection ? bundle.manifest.settings.copyWith(mapInstanceRetentionPolicy:
      MapInstanceRetentionPolicy(viewportWidthTiles: 1, viewportHeightTiles: 1, marginTiles: 0)) : bundle.manifest.settings,
    scenes: mode == 'customOwner' ? bundle.manifest.scenes.take(2).toList() : bundle.manifest.scenes,
    eventRegistry: mode == 'customOwner' ? NarrativeEventRegistry(schemaVersion: 1,
      mode: EventSystemMode.v2Only, records: bundle.manifest.eventRegistry!.records.take(2).toList(), legacyClaims: const []) : bundle.manifest.eventRegistry,
    worldRules: mode == 'customOwner' ? bundle.manifest.worldRules : [], characters: [
    ...bundle.manifest.characters,
    for (final mapId in ['main', 'neighbor'])
      ProjectCharacterEntry(id: 'alternate-$mapId', name: 'Alternate', tilesetId: 'actors'),
  ]),
    map: bundle.map.copyWith(entities: [for (final entity in bundle.map.entities)
      if (entity.kind != MapEntityKind.npc) entity else
        entity.copyWith(kind: mode == 'customOwner' ? MapEntityKind.custom : entity.kind,
          pos: temporaryConnection && id == 'neighbor' ? const GridPos(x: 0, y: 3) : entity.pos,
          npc: mode == 'customOwner' ? null : entity.npc,
          presentation: MapEntityPresentation(variants: [
          if (mode == 'variants') MapEntityPresentationVariant(id: 'changed', condition: condition,
            characterId: 'alternate-$id', blocksMovement: false, facing: EntityFacing.west),
          MapEntityPresentationVariant(id: 'base', condition: temporaryConnection && id == 'neighbor'
            ? NarrativeEventConditionExpression.leaf(NarrativeEventCondition.mapEventInstanceBoolean(
                mapId: id, eventId: entity.id, key: 'A', expectedValue: false)) : mode == 'customOwner'
            ? NarrativeEventConditionExpression.all([]) : NarrativeEventConditionExpression.not(condition),
            characterId: entity.npc!.characterId, blocksMovement: temporaryConnection && id == 'neighbor' ? mode == 'connectionSolid' : true),
        ])),
    ]));
}

RuntimeMapBundle _bundle(String mapId) => RuntimeMapBundle(
  projectRootDirectory: '/tmp/world-rule-remount',
  tilesetAbsolutePathsById: const {
    'actors': '/tmp/world-rule-remount/actors.png',
  },
  map: MapData(
    id: mapId,
    name: mapId,
    size: const GridSize(width: 8, height: 8),
    entities: [
      const MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        name: 'Spawn',
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
      MapEntity(
        id: 'npc-$mapId',
        kind: MapEntityKind.npc,
        name: 'NPC $mapId',
        pos: _npcCell,
        blocksMovement: true,
        npc: MapEntityNpcData(
          displayName: 'NPC $mapId',
          characterId: 'npc-$mapId',
        ),
      ),
    ],
    connections: [
      MapConnection(
        direction: mapId == 'main'
            ? MapConnectionDirection.east
            : MapConnectionDirection.west,
        targetMapId: mapId == 'main' ? 'neighbor' : 'main',
      ),
    ],
    triggers: [
      if (mapId == 'main')
        for (var i = 0; i < _sceneIds.length; i++)
          MapTrigger(
            id: _sceneIds[i],
            name: _sceneIds[i],
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 5, y: i + 1),
              size: const GridSize(width: 1, height: 1),
            ),
          ),
    ],
  ),
  manifest: ProjectManifest(
    name: 'World Rule remount',
    maps: [
      for (final id in ['main', 'neighbor'])
        ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'actors',
        name: 'Actors',
        relativePath: 'actors.png',
      ),
    ],
    settings: const ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 1,
      defaultPlayerCharacterId: 'player',
    ),
    characters: [
      for (final id in ['player', 'npc-main', 'npc-neighbor'])
        ProjectCharacterEntry(id: id, name: id, tilesetId: 'actors'),
    ],
    facts: [
      NarrativeFactDefinition(id: 'hidden', label: 'Hidden'),
      NarrativeFactDefinition(id: 'visible', label: 'Visible'),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        for (var i = 0; i < _sceneIds.length; i++)
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: 'evt_019abcde-7000-7000-8000-00000000000$i',
              name: _sceneIds[i],
              source: NarrativeEventSourceRef.triggerEnter(
                'main',
                _sceneIds[i],
              ),
              conditions: const [],
              sceneId: _sceneIds[i],
              reusePolicy: NarrativeEventReusePolicy.reusable,
              priority: 0,
              order: i,
            ),
            enabled: true,
          ),
      ],
      legacyClaims: const [],
    ),
    worldRules: [
      for (final id in ['main', 'neighbor']) ...[
        _rule(id, 'visible', WorldRuleEffectKind.entityVisible, 1),
        _rule(id, 'hidden', WorldRuleEffectKind.entityHidden, 2),
      ],
    ],
    scenes: [
      _scene('hide', SceneConsequence.setFact(factId: 'hidden', value: true)),
      _scene('show', SceneConsequence.setFact(factId: 'hidden', value: false)),
      for (final present in [false, true])
        _scene(
          present ? 'explicit-present' : 'explicit-absent',
          SceneConsequence.setNpcPresence(
            mapId: 'main',
            entityId: 'npc-main',
            present: present,
          ),
        ),
    ],
  ),
);

WorldRuleDefinition _rule(
  String mapId,
  String factId,
  WorldRuleEffectKind effect,
  int priority,
) => WorldRuleDefinition(
  id: '$mapId-$factId',
  label: '$mapId $factId',
  source: WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: factId,
    predicate: WorldRuleSourcePredicate.isTrue,
  ),
  target: WorldRuleTarget(
    kind: WorldRuleTargetKind.mapEntity,
    mapId: mapId,
    entityId: 'npc-$mapId',
  ),
  effect: WorldRuleEffect(kind: effect),
  priority: priority,
);

SceneAsset _scene(String id, SceneConsequence consequence) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'apply',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(consequence),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        kind: SceneEdgeKind.defaultFlow,
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'apply',
      ),
      SceneEdge(
        id: 'finish',
        kind: SceneEdgeKind.defaultFlow,
        fromNodeId: 'apply',
        fromPortId: 'completed',
        toNodeId: 'end',
      ),
    ],
  ),
);
