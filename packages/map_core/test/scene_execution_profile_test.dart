import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene execution profiles', () {
    test('keeps legacy scenes world-compatible and round-trips preSession', () {
      final world = SceneAsset.fromJson({
        'id': 'scene_world',
        'name': 'World scene',
        'graph': _graphJson(),
      });
      final preSession = SceneAsset.fromJson({
        'id': 'scene_pre_session',
        'name': 'Pre-session',
        'executionProfile': 'preSession',
        'graph': _graphJson(),
      });

      expect(world.executionProfile, SceneExecutionProfile.world);
      expect(world.toJson(), isNot(contains('executionProfile')));
      expect(preSession.executionProfile, SceneExecutionProfile.preSession);
      expect(preSession.toJson()['executionProfile'], 'preSession');
      expect(SceneAsset.fromJson(preSession.toJson()), preSession);
    });

    test('rejects an unknown execution profile at decode time', () {
      expect(
        () => SceneAsset.fromJson({
          'id': 'scene_future',
          'name': 'Future scene',
          'executionProfile': 'futureProfile',
          'graph': _graphJson(),
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('publishes the exact preSession V1 capability matrix', () {
      expect(
        sceneExecutionCapabilityMatrix.allowedCapabilities(
          SceneExecutionProfile.preSession,
        ),
        equals({
          SceneExecutionCapabilityIds.flowStart,
          SceneExecutionCapabilityIds.flowEnd,
          SceneExecutionCapabilityIds.draftLocalCondition,
          SceneExecutionCapabilityIds.flowBranch,
          SceneExecutionCapabilityIds.flowMerge,
          SceneExecutionCapabilityIds.presentationCinematic,
          SceneExecutionCapabilityIds.inputMessage,
          SceneExecutionCapabilityIds.inputChoice,
          SceneExecutionCapabilityIds.inputText,
          SceneExecutionCapabilityIds.inputConfirmation,
          SceneExecutionCapabilityIds.inputSelection,
          SceneExecutionCapabilityIds.draftAssign,
        }),
      );

      final forbidden = sceneExecutionCapabilityMatrix.evaluate(
        profile: SceneExecutionProfile.preSession,
        capabilityId: SceneExecutionCapabilityIds.worldBattle,
      );
      final unknown = sceneExecutionCapabilityMatrix.evaluate(
        profile: SceneExecutionProfile.preSession,
        capabilityId: 'future.capability',
      );

      expect(forbidden.isAllowed, isFalse);
      expect(
        forbidden.issueCode,
        SceneExecutionCapabilityIssueCode.forbiddenForProfile,
      );
      expect(
        forbidden.issueCode?.wireName,
        'scene.capability.forbiddenForProfile',
      );
      expect(unknown.isAllowed, isFalse);
      expect(
        unknown.issueCode,
        SceneExecutionCapabilityIssueCode.unknownCapability,
      );
      expect(unknown.issueCode?.wireName, 'scene.capability.unknown');
    });

    test('authoring mutations preserve the execution profile', () {
      final source = SceneAsset.fromJson({
        'id': 'scene_pre_session',
        'name': 'Pre-session',
        'executionProfile': 'preSession',
        'graph': _graphJson(),
      });

      final result = addSceneLinkedAssetNodeDraft(
        source,
        payload: ScenePresentationCinematicPayload(
          presentationCinematicId: 'presentation_intro',
        ),
      );

      expect(
        result.updatedScene.executionProfile,
        SceneExecutionProfile.preSession,
      );

      final world = SceneAsset.fromJson({
        'id': 'scene_world',
        'name': 'World',
        'graph': _graphJson(),
      });
      expect(
        addSceneLinkedAssetNodeDraft(
          world,
          payload: ScenePresentationCinematicPayload(
            presentationCinematicId: 'presentation_intro',
          ),
        ).updatedScene.executionProfile,
        SceneExecutionProfile.world,
      );
      expect(
        () => addSceneLinkedAssetNodeDraft(
          source,
          payload: SceneCinematicPayload(cinematicId: 'cinematic_world'),
        ),
        throwsArgumentError,
      );
    });

  });
}

Map<String, dynamic> _graphJson() => {
  'startNodeId': 'node_start',
  'nodes': [
    {'id': 'node_start', 'kind': 'start'},
    {'id': 'node_end', 'kind': 'end'},
  ],
  'edges': [
    {
      'id': 'edge_start_end',
      'fromNodeId': 'node_start',
      'fromPortId': 'completed',
      'toNodeId': 'node_end',
      'kind': 'default',
    },
  ],
};
