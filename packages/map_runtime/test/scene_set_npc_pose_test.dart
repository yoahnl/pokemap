import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  final hidden = NarrativeEventConditionExpression.leaf(
    NarrativeEventCondition.fact('hidden', true),
  );
  final map = MapData(
    id: 'lab',
    name: 'Lab',
    size: const GridSize(width: 20, height: 12),
    entities: [
      MapEntity(
        id: 'rival',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 7, y: 6),
        presentation: MapEntityPresentation(
          variants: [
            MapEntityPresentationVariant(
              id: 'hidden',
              condition: hidden,
              blocksMovement: false,
            ),
            MapEntityPresentationVariant(
              id: 'visible',
              condition: NarrativeEventConditionExpression.not(hidden),
              characterId: 'rival-sprite',
              facing: EntityFacing.south,
              blocksMovement: true,
            ),
          ],
        ),
      ),
    ],
  );
  final project = ProjectManifest(
    name: 'Pose',
    maps: const [
      ProjectMapEntry(id: 'lab', name: 'Lab', relativePath: 'maps/lab.json'),
    ],
    tilesets: const [],
    characters: const [
      ProjectCharacterEntry(
        id: 'rival-sprite',
        name: 'Rival',
        tilesetId: 'actors',
      ),
    ],
    facts: [NarrativeFactDefinition(id: 'hidden', label: 'Hidden')],
  );
  final instance = MapInstanceRef(mapId: 'lab', instanceId: 'visit');
  final initial = GameState(
    saveId: 'pose',
    currentMapId: 'lab',
    storyFlags: const StoryFlags(activeFlags: {'hidden'}),
    mapInstanceWorldState: MapInstanceWorldState(
      instancesByMapId: {'lab': MapInstanceRuntimeState(instanceId: 'visit')},
    ),
  );
  final pose = SceneConsequence.setNpcPose(
    mapId: 'lab',
    entityId: 'rival',
    x: 14,
    y: 4,
  );
  SceneConsequenceRuntimeWriter writer({
    MapData? target,
    MapInstanceRef? scope,
  }) => SceneConsequenceRuntimeWriter(
    project: project,
    mapsById: {'lab': target ?? map},
    mapInstanceScopes: {'lab': scope ?? instance},
  );
  test('hidden actor placement persists logically and restores visible position and facing', () {
    final result = writer().applyOne(initial, pose);
    expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
    final reopened = GameState.fromJson(result.gameState.toJson());
    final saved = reopened
        .mapInstanceWorldState
        .instancesByMapId['lab']!
        .npcPoses['rival']!;
    expect(saved.position, const GridPos(x: 14, y: 4));
    expect(saved.facing, EntityFacing.south);
    final hiddenWorld = GameplayWorldState.initial(
      map: map,
      project: project,
      gameState: reopened,
      playerPos: const GridPos(x: 0, y: 0),
    );
    final visible = hiddenWorld.withEntityPresentations(
      project: project,
      sourceMap: map,
      gameState: reopened.copyWith(storyFlags: const StoryFlags()),
    );
    expect(visible.map.entities.single.pos, saved.position);
    expect(visible.map.entities.single.npc!.facing, saved.facing);
    expect(
      writer().applyOne(reopened, pose).gameState.toJson(),
      reopened.toJson(),
    );
  });
  final absentMap = map.copyWith(
    entities: [
      map.entities.single.copyWith(
        presentation: MapEntityPresentation(
          variants: [map.entities.single.presentation!.variants.last],
        ),
      ),
    ],
  );
  test('a validated owner with no active presentation keeps its logical pose across cold state restoration', () {
    final result = writer(target: absentMap).applyOne(initial, pose);
    expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
    final reopened = GameState.fromJson(result.gameState.toJson());
    expect(
      reopened
          .mapInstanceWorldState
          .instancesByMapId['lab']!
          .npcPoses['rival']!
          .position,
      const GridPos(x: 14, y: 4),
    );
    final hiddenWorld = GameplayWorldState.initial(
      map: absentMap,
      project: project,
      gameState: reopened,
      playerPos: const GridPos(x: 0, y: 0),
    );
    expect(hiddenWorld.map.entities, isEmpty);
    final visible = hiddenWorld.withEntityPresentations(
      sourceMap: absentMap,
      project: project,
      gameState: reopened.copyWith(storyFlags: const StoryFlags()),
    );
    expect(visible.map.entities.single.pos, const GridPos(x: 14, y: 4));
    expect(visible.map.entities.single.npc!.facing, EntityFacing.south);
  });
  test('inactive placement refuses unavailable typed conditions and still checks bounds and scope atomically', () {
    final invalid = initial.copyWith(
      narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
        valuesByFactId: {'hidden': NarrativeValue.string('wrong type')},
      ),
    );
    final cases = [
      (writer(target: absentMap), invalid, pose),
      (
        writer(target: absentMap),
        initial,
        SceneConsequence.setNpcPose(
          mapId: 'lab',
          entityId: 'rival',
          x: 20,
          y: 4,
        ),
      ),
      (
        writer(
          target: absentMap,
          scope: MapInstanceRef(mapId: 'lab', instanceId: 'stale'),
        ),
        initial,
        pose,
      ),
    ];
    for (final (writer, before, command) in cases) {
      final result = writer.applyOne(before, command);
      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(identical(result.gameState, before), isTrue);
    }
  });
  test('pose preserves previously committed facing and unrelated poses', () {
    final withOther = initial.copyWith(
      mapInstanceWorldState: initial.mapInstanceWorldState.setNpcPoses(
        instance,
        {
          'rival': MapInstanceNpcPose(
            position: const GridPos(x: 3, y: 3),
            facing: EntityFacing.west,
          ),
          'other': MapInstanceNpcPose(
            position: const GridPos(x: 2, y: 2),
            facing: EntityFacing.north,
          ),
        },
      ),
    );
    final result = writer().applyOne(withOther, pose).gameState;
    expect(
      result
          .mapInstanceWorldState
          .instancesByMapId['lab']!
          .npcPoses['rival']!
          .facing,
      EntityFacing.west,
    );
    expect(
      result.mapInstanceWorldState.instancesByMapId['lab']!.npcPoses['other'],
      withOther
          .mapInstanceWorldState
          .instancesByMapId['lab']!
          .npcPoses['other'],
    );
  });
  test('visible actor, stale instance, missing actor and out of bounds refuse without mutations', () {
    final cases = [
      (writer(), initial.copyWith(storyFlags: const StoryFlags()), pose),
      (
        writer(
          scope: MapInstanceRef(mapId: 'lab', instanceId: 'stale'),
        ),
        initial,
        pose,
      ),
      (
        writer(),
        initial,
        SceneConsequence.setNpcPose(
          mapId: 'lab',
          entityId: 'missing',
          x: 1,
          y: 1,
        ),
      ),
      (
        writer(),
        initial,
        SceneConsequence.setNpcPose(
          mapId: 'lab',
          entityId: 'rival',
          x: 20,
          y: 4,
        ),
      ),
      (
        writer(
          target: map.copyWith(
            entities: [map.entities.single, map.entities.single],
          ),
        ),
        initial,
        pose,
      ),
    ];
    for (final (writer, before, command) in cases) {
      final result = writer.applyOne(before, command);
      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(identical(result.gameState, before), isTrue);
    }
  });
  test('a later invalid pose rolls back a batch including a valid pose', () {
    final result = writer().applyAll(initial, [
      pose,
      SceneConsequence.setNpcPose(
        mapId: 'lab',
        entityId: 'missing',
        x: 1,
        y: 1,
      ),
    ]);
    expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
    expect(identical(result.gameState, initial), isTrue);
  });
}
