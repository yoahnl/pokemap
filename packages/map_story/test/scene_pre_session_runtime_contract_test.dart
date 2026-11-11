import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

void main() {
  group('Scene preSession authoring contract', () {

    test('builds typed interaction and draft-local condition intents', () {
      final interaction = ScenePreSessionInteractionSpec.choice(
        prompt: SceneInteractionPrompt(
          localizationKey: 'newGame.avatar.prompt',
        ),
        options: [
          SceneInteractionOption(
            id: 'avatar_a',
            label: SceneInteractionPrompt(localizationKey: 'avatar.a'),
          ),
        ],
        resultBinding: const ScenePreSessionResultBinding(
          field: ScenePreSessionDraftField.avatarCharacterId,
        ),
      );
      final actionPayload = SceneActionPayload.preSessionInteraction(
        interaction,
      );
      final interactionNode = SceneNode(
        id: 'choose_avatar',
        kind: SceneNodeKind.action,
        payload: actionPayload,
      );
      final conditionNode = SceneNode(
        id: 'has_avatar',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.newGameDraft,
            sourceId: 'avatarCharacterId',
            operator: SceneConditionOperator.isTrue,
          ),
        ),
      );
      final scene = SceneAsset(
        id: 'scene_pre_session',
        name: 'Pré-session',
        executionProfile: SceneExecutionProfile.preSession,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            interactionNode,
            conditionNode,
            SceneNode(id: 'end_ok', kind: SceneNodeKind.end),
            SceneNode(id: 'end_missing', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_interaction',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'choose_avatar',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'interaction_condition',
              fromNodeId: 'choose_avatar',
              fromPortId: 'avatar_a',
              toNodeId: 'has_avatar',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'condition_true',
              fromNodeId: 'has_avatar',
              fromPortId: 'true',
              toNodeId: 'end_ok',
              kind: SceneEdgeKind.conditionTrue,
            ),
            SceneEdge(
              id: 'condition_false',
              fromNodeId: 'has_avatar',
              fromPortId: 'false',
              toNodeId: 'end_missing',
              kind: SceneEdgeKind.conditionFalse,
            ),
          ],
        ),
      );

      expect(
        SceneActionPayload.fromJson(actionPayload.toJson()),
        actionPayload,
      );
      expect(
        sceneExecutionCapabilityForNode(
          SceneExecutionProfile.preSession,
          interactionNode,
        ),
        SceneExecutionCapabilityIds.inputChoice,
      );
      expect(
        sceneExecutionCapabilityForNode(
          SceneExecutionProfile.preSession,
          conditionNode,
        ),
        SceneExecutionCapabilityIds.draftLocalCondition,
      );

      final result = buildSceneRuntimePlan(scene);

      expect(result.diagnostics, isEmpty);
      expect(result.canBuild, isTrue);
      final interactionIntent = result.plan!.nodes
          .singleWhere((node) => node.id == 'choose_avatar')
          .intent;
      expect(
        interactionIntent.kind,
        SceneRuntimePlanIntentKind.requestStructuredInteraction,
      );
      expect(interactionIntent.preSessionInteraction, interaction);
      expect(interactionIntent.sourceNodeId, 'choose_avatar');
    });

    test('compiles Presentation cue bindings into the runtime intent', () {
      final interaction = ScenePreSessionInteractionSpec.message(
        prompt: SceneInteractionPrompt(
          localizationKey: 'newGame.intro.message',
          fallbackText: 'Bienvenue.',
        ),
      );
      final scene = SceneAsset(
        id: 'scene_pre_session',
        name: 'Pré-session',
        executionProfile: SceneExecutionProfile.preSession,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'presentation',
              kind: SceneNodeKind.presentationCinematic,
              payload: ScenePresentationCinematicPayload(
                presentationCinematicId: 'opening',
                interactionCueBindings: [
                  ScenePresentationInteractionCueBinding(
                    markerId: 'welcome',
                    awaitableNodeId: 'message',
                  ),
                ],
              ),
            ),
            SceneNode(
              id: 'message',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.preSessionInteraction(interaction),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_presentation',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'presentation',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'presentation_message',
              fromNodeId: 'presentation',
              fromPortId: 'completed',
              toNodeId: 'message',
              kind: SceneEdgeKind.presentationCompleted,
            ),
            SceneEdge(
              id: 'message_end',
              fromNodeId: 'message',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      );

      final plan = buildSceneRuntimePlan(scene).plan!;
      final presentationIntent = plan.nodes
          .singleWhere((node) => node.id == 'presentation')
          .intent;

      expect(presentationIntent.sourceNodeId, 'presentation');
      expect(
        presentationIntent.presentationAwaitableNodeIdsByMarkerId,
        const {'welcome': 'message'},
      );
    });

  });
}
