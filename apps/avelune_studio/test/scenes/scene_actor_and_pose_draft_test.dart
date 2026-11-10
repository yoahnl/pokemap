import 'dart:async';

import 'package:avelune_studio/features/scenes/application/scene_actor_action_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_npc_pose_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'actor route draft keeps native steps and opaque payload metadata',
    () async {
      final original = SceneActionPayload.interactive(
        SceneInteractiveCommand.actorRoute(
          target: SceneActorTarget.player(mapId: 'a'),
          steps: [
            SceneActorRouteStep.face(
              direction: EntityFacing.north,
              durationMs: 0,
            ),
          ],
        ),
        actionKind: 'custom',
        parameters: const {'keep': 'annotation'},
      );
      final ready = Completer<void>();
      late SceneActorActionDraft draft;
      draft = SceneActorActionDraft(
        project: workspaceProject,
        commandId: NarrativeCommandIds.actorRoute,
        current: original,
        loadMap: (id) async => workspaceMap(id),
        changed: () {
          if (!draft.loading && !ready.isCompleted) ready.complete();
        },
      );
      addTearDown(draft.dispose);
      await ready.future;
      expect(draft.payload, original);
      draft.steps.single.durationText = '-1';
      expect(draft.valid, isFalse);
      expect(draft.payload, isNull);
      expect(draft.current, same(original));
    },
  );

  test(
    'actor movement drafts retain the initial collision owner and map identity',
    () {
      final original = SceneActorRouteStep.move(
        direction: EntityFacing.east,
        durationMs: 200,
        initialCollisionOwnerEntityId: 'guard',
      );
      final draft = SceneActorStepDraft.fromStep(3, original, mapId: 'room');
      expect(draft.id, 3);
      expect(draft.initialCollisionOwnerEntityId, 'guard');
      expect(draft.initialCollisionOwnerMapId, 'room');
      expect(draft.durationValid, isTrue);
      draft.durationText = '0';
      expect(draft.durationValid, isFalse);
    },
  );

  test(
    'NPC pose draft retains direction-only semantics and diagnoses bounds',
    () async {
      final original = SceneConsequence.setNpcPose(
        mapId: 'room',
        entityId: 'actor',
        facing: EntityFacing.north,
      );
      final draft = SceneNpcPoseDraft(
        project: _project(),
        current: SceneActionPayload.consequence(original),
        changed: () {},
        loadMap: (_) async => _map(),
      );
      addTearDown(draft.dispose);
      await draft.reloadMap();
      expect(draft.pose, original);
      draft.mode = 'position';
      draft.xText = '7';
      draft.yText = '7';
      expect(draft.pose, isNotNull);
      draft.xText = '8';
      expect(draft.pose, isNull);
      expect(draft.current!.consequence, original);
    },
  );

  test('a mismatched map cannot supply a NPC pose', () async {
    final draft = SceneNpcPoseDraft(
      project: _project(),
      current: SceneActionPayload.consequence(
        SceneConsequence.setNpcPose(
          mapId: 'room',
          entityId: 'actor',
          facing: EntityFacing.north,
        ),
      ),
      changed: () {},
      loadMap: (_) async => workspaceMap('other'),
    );
    addTearDown(draft.dispose);
    await draft.reloadMap();
    expect(draft.pose, isNull);
    expect(draft.error, contains('Carte indisponible'));
  });
}

ProjectManifest _project() => ProjectManifest(
  name: 'Pose',
  maps: const [
    ProjectMapEntry(id: 'room', name: 'Pièce', relativePath: 'room.json'),
  ],
  tilesets: [],
  characters: const [
    ProjectCharacterEntry(id: 'known', name: 'Personnage', tilesetId: 'actors'),
  ],
);

MapData _map() => MapData(
  id: 'room',
  name: 'Pièce',
  size: const GridSize(width: 8, height: 8),
  entities: [
    MapEntity(
      id: 'actor',
      name: 'PNJ',
      kind: MapEntityKind.custom,
      pos: const GridPos(x: 2, y: 2),
      presentation: MapEntityPresentation(
        variants: [
          MapEntityPresentationVariant(
            id: 'visible',
            characterId: 'known',
            condition: NarrativeEventConditionExpression.all(const []),
            blocksMovement: false,
          ),
        ],
      ),
    ),
  ],
);
