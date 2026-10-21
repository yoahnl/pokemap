import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'logical NPC pose has a typed bounded round trip and guided command',
    () {
      final pose = SceneConsequence.setNpcPose(
        mapId: ' lab ',
        entityId: ' rival ',
        x: 14,
        y: 4,
      );
      expect(pose.toJson(), {
        'kind': 'setNpcPose',
        'mapId': 'lab',
        'entityId': 'rival',
        'x': 14,
        'y': 4,
      });
      expect(SceneConsequence.fromJson(pose.toJson()), pose);
      final descriptor = NarrativeCommandCatalog.canonical().commands
          .singleWhere((c) => c.id == NarrativeCommandIds.setNpcPose);
      expect(
        descriptor.parameters.first.kind,
        NarrativeCommandParameterKind.mapEntityReference,
      );
      final payload =
          buildScenePayloadForNarrativeCommand(
                commandId: NarrativeCommandIds.setNpcPose,
                parameters: {
                  'npcRef': 'lab::rival',
                  'x': '14',
                  'y': '4',
                  'facing': 'west',
                },
              )
              as SceneActionPayload;
      expect(
        payload.consequence,
        SceneConsequence.setNpcPose(
          mapId: 'lab',
          entityId: 'rival',
          x: 14,
          y: 4,
          facing: EntityFacing.west,
        ),
      );
    },
  );
  for (final json in [
    {'kind': 'setNpcPose', 'mapId': ' ', 'entityId': 'rival', 'x': 1, 'y': 2},
    {'kind': 'setNpcPose', 'mapId': 'lab', 'entityId': ' ', 'x': 1, 'y': 2},
    {
      'kind': 'setNpcPose',
      'mapId': 'lab',
      'entityId': 'rival',
      'x': -1,
      'y': 2,
    },
    {
      'kind': 'setNpcPose',
      'mapId': 'lab',
      'entityId': 'rival',
      'x': 1,
      'y': 65536,
    },
    {
      'kind': 'setNpcPose',
      'mapId': 'lab',
      'entityId': 'rival',
      'x': 1,
      'y': 2,
      'facing': 'sideways',
    },
  ]) {
    test('logical NPC pose refuses malformed values $json', () {
      expect(
        () => SceneConsequence.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  }
}
