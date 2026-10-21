import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_npc_pose_consequence_buffer.dart';

void main() {
  final scope = MapInstanceRef(mapId: 'room', instanceId: 'visit');
  final original = MapInstanceNpcPose(
    position: const GridPos(x: 3, y: 2),
    facing: EntityFacing.east,
  );
  MapInstanceWorldState state(
    MapInstanceNpcPose? pose, {
    String instanceId = 'visit',
    bool marker = false,
  }) => MapInstanceWorldState(
    instancesByMapId: {
      'room': MapInstanceRuntimeState(
        instanceId: instanceId,
        npcPoses: {'actor': ?pose},
        eventBooleans: {
          'owner': {'marker': marker},
        },
      ),
    },
  );
  final route = SceneInteractiveCommand.actorRoute(
    target: SceneActorTarget.entity(mapId: 'room', entityId: 'actor'),
    steps: [SceneActorRouteStep.face(direction: EntityFacing.west)],
  );
  for (final absolute in [false, true]) {
    test(
      'published actor route retires only its earlier pose absolute=$absolute',
      () {
        final pending = <SceneConsequence>[
          SceneConsequence.setFact(factId: 'kept', value: true),
          SceneConsequence.setNpcPose(
            mapId: 'room',
            entityId: 'actor',
            x: absolute ? 3 : null,
            y: absolute ? 2 : null,
            facing: EntityFacing.east,
          ),
          SceneConsequence.setNpcPose(
            mapId: 'room',
            entityId: 'other',
            facing: EntityFacing.north,
          ),
        ];
        final pokemon = <String?>['first', null, 'last'];
        final rail = <String?>['rail_first', null, 'rail_last'];
        retireSceneNpcPosesPublishedByActorRoute(
          command: route,
          scope: scope,
          before: state(original),
          after: state(
            MapInstanceNpcPose(
              position: original.position,
              facing: EntityFacing.west,
            ),
          ),
          consequences: pending,
          pokemonGrantOperationIds: pokemon,
          railProgressionOperationIds: rail,
        );
        expect(pending, hasLength(2));
        expect(pending.first, isA<SceneSetFactConsequence>());
        expect((pending.last as SceneSetNpcPoseConsequence).entityId, 'other');
        expect(pokemon, ['first', 'last']);
        expect(rail, ['rail_first', 'rail_last']);
      },
    );
  }
  for (final change in [
    'same',
    'unrelated_boolean',
    'missing_pose',
    'stale_instance',
    'player',
    'other_actor',
  ]) {
    test(
      'route without publication of this owner preserves its pending pose $change',
      () {
        final pending = <SceneConsequence>[
          SceneConsequence.setNpcPose(
            mapId: 'room',
            entityId: 'actor',
            facing: EntityFacing.east,
          ),
        ];
        final before = state(original);
        final after = switch (change) {
          'unrelated_boolean' => state(original, marker: true),
          'missing_pose' => state(null),
          'stale_instance' => state(
            MapInstanceNpcPose(
              position: original.position,
              facing: EntityFacing.west,
            ),
            instanceId: 'other',
          ),
          _ => state(original),
        };
        final command = switch (change) {
          'player' => SceneInteractiveCommand.actorRoute(
            target: SceneActorTarget.player(mapId: 'room'),
            steps: [SceneActorRouteStep.face(direction: EntityFacing.west)],
          ),
          'other_actor' => SceneInteractiveCommand.actorRoute(
            target: SceneActorTarget.entity(mapId: 'room', entityId: 'other'),
            steps: [SceneActorRouteStep.face(direction: EntityFacing.west)],
          ),
          _ => route,
        };
        retireSceneNpcPosesPublishedByActorRoute(
          command: command,
          scope: scope,
          before: before,
          after: after,
          consequences: pending,
          pokemonGrantOperationIds: [null],
          railProgressionOperationIds: [null],
        );
        expect(pending, hasLength(1));
      },
    );
  }
  test('explicit publication with equal pose values still supersedes the earlier command', () {
    final pending = <SceneConsequence>[
      SceneConsequence.setNpcPose(
        mapId: 'room',
        entityId: 'actor',
        facing: EntityFacing.north,
      ),
    ];
    retireSceneNpcPosesPublishedByActorRoute(
      command: route,
      scope: scope,
      before: state(original),
      after: state(
        MapInstanceNpcPose(
          position: original.position,
          facing: original.facing,
        ),
      ),
      consequences: pending,
      pokemonGrantOperationIds: [null],
      railProgressionOperationIds: [null],
    );
    expect(pending, isEmpty);
  });
  test('malformed operation buffers fail before any removal', () {
    final pending = <SceneConsequence>[
      SceneConsequence.setNpcPose(
        mapId: 'room',
        entityId: 'actor',
        facing: EntityFacing.north,
      ),
    ];
    expect(
      () => retireSceneNpcPosesPublishedByActorRoute(
        command: route,
        scope: scope,
        before: state(original),
        after: state(
          MapInstanceNpcPose(
            position: original.position,
            facing: original.facing,
          ),
        ),
        consequences: pending,
        pokemonGrantOperationIds: [],
        railProgressionOperationIds: [null],
      ),
      throwsStateError,
    );
    expect(pending, hasLength(1));
  });
}
