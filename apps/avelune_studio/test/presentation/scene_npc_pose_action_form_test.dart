import 'package:avelune_studio/features/scenes/application/scene_npc_pose_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final onlyFacing in [false, true]) {
    test('NPC pose owner edits both modes facingOnly=$onlyFacing', () async {
      final original = SceneConsequence.setNpcPose(
        mapId: 'room',
        entityId: 'actor',
        x: onlyFacing ? null : 3,
        y: onlyFacing ? null : 2,
        facing: EntityFacing.west,
      );
      final draft = SceneNpcPoseDraft(
        project: _project(),
        changed: () {},
        loadMap: (_) async => _map(),
        current: SceneActionPayload.consequence(original),
      );
      addTearDown(draft.dispose);
      await draft.reloadMap();
      expect(draft.actorOptions, {'actor': 'PNJ test'});
      draft.mode = onlyFacing ? 'position' : 'facing';
      if (onlyFacing) {
        draft.xText = '4';
        draft.yText = '3';
      }
      final result = draft.pose!;
      expect(result.mapId, 'room');
      expect(result.entityId, 'actor');
      expect(result.facing, EntityFacing.west);
      expect(result.x, onlyFacing ? 4 : null);
      expect(result.y, onlyFacing ? 3 : null);
      expect(draft.current!.consequence, original);
    });
  }
  test(
    'NPC pose refuses an unknown character without discarding its reference',
    () async {
      final current = SceneActionPayload.consequence(
        SceneConsequence.setNpcPose(
          mapId: 'room',
          entityId: 'actor',
          facing: EntityFacing.east,
        ),
      );
      final draft = SceneNpcPoseDraft(
        project: _project(),
        current: current,
        loadMap: (_) async => _map(character: 'missing'),
        changed: () {},
      );
      addTearDown(draft.dispose);
      await draft.reloadMap();
      expect(draft.actorOptions, isEmpty);
      expect(draft.pose, isNull);
      expect(draft.selectedEntityId, 'actor');
      expect(draft.current, same(current));
    },
  );
}

ProjectManifest _project() => ProjectManifest(
  name: 'Pose',
  maps: const [
    ProjectMapEntry(id: 'room', name: 'Pièce', relativePath: 'room.json'),
  ],
  tilesets: const [],
  characters: const [
    ProjectCharacterEntry(id: 'known', name: 'Personnage', tilesetId: 'actors'),
  ],
);

MapData _map({String character = 'known'}) => MapData(
  id: 'room',
  name: 'Pièce',
  size: const GridSize(width: 8, height: 8),
  entities: [
    MapEntity(
      id: 'actor',
      name: 'PNJ test',
      kind: MapEntityKind.custom,
      pos: const GridPos(x: 2, y: 2),
      presentation: MapEntityPresentation(
        variants: [
          MapEntityPresentationVariant(
            id: 'visible',
            characterId: character,
            condition: NarrativeEventConditionExpression.all(const []),
            blocksMovement: false,
          ),
        ],
      ),
    ),
  ],
);
