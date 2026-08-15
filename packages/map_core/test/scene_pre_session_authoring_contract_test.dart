import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene preSession authoring contract', () {
    test('round-trips a typed text request with a draft binding', () {
      final interaction = ScenePreSessionInteractionSpec.text(
        prompt: SceneInteractionPrompt(
          localizationKey: 'newGame.playerName.prompt',
          fallbackText: 'Quel est ton nom ?',
        ),
        constraints: SceneTextInputConstraints(
          minGraphemes: 1,
          maxGraphemes: 24,
        ),
        resultBinding: const ScenePreSessionResultBinding(
          field: ScenePreSessionDraftField.playerName,
        ),
      );

      expect(
        ScenePreSessionInteractionSpec.fromJson(interaction.toJson()),
        interaction,
      );
      expect(interaction.outputPortIds, const ['completed']);
    });

    test('rejects a draft binding incompatible with the request kind', () {
      expect(
        () => ScenePreSessionInteractionSpec.confirmation(
          prompt: SceneInteractionPrompt(
            localizationKey: 'newGame.confirm.prompt',
          ),
          resultBinding: const ScenePreSessionResultBinding(
            field: ScenePreSessionDraftField.playerName,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => ScenePreSessionInteractionSpec.selection(
          prompt: SceneInteractionPrompt(
            localizationKey: 'newGame.starter.prompt',
          ),
          options: [
            SceneInteractionOption(
              id: 'starter_leaf',
              label: SceneInteractionPrompt(localizationKey: 'starter.leaf'),
            ),
          ],
          constraints: SceneSelectionConstraints(maxSelections: 2),
          resultBinding: const ScenePreSessionResultBinding(
            field: ScenePreSessionDraftField.starterOptionId,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('round-trips every structured request kind', () {
      final prompt = SceneInteractionPrompt(
        localizationKey: 'newGame.generic.prompt',
      );
      final option = SceneInteractionOption(
        id: 'option_a',
        label: SceneInteractionPrompt(
          localizationKey: 'newGame.generic.optionA',
        ),
      );
      final interactions = <ScenePreSessionInteractionSpec>[
        ScenePreSessionInteractionSpec.message(prompt: prompt),
        ScenePreSessionInteractionSpec.choice(
          prompt: prompt,
          options: [option],
        ),
        ScenePreSessionInteractionSpec.text(prompt: prompt),
        ScenePreSessionInteractionSpec.confirmation(prompt: prompt),
        ScenePreSessionInteractionSpec.selection(
          prompt: prompt,
          options: [option],
        ),
      ];

      expect(
        interactions.map((interaction) => interaction.kind),
        SceneInteractionRequestKind.values,
      );
      expect(
        interactions.map(
          (interaction) =>
              ScenePreSessionInteractionSpec.fromJson(interaction.toJson()),
        ),
        interactions,
      );
    });

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
              fromPortId: 'completed',
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
    });

    test('rejects preSession semantics from a world Scene fail-closed', () {
      final scene = SceneAsset(
        id: 'scene_world',
        name: 'Monde',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'message',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.preSessionInteraction(
                ScenePreSessionInteractionSpec.message(
                  prompt: SceneInteractionPrompt(
                    localizationKey: 'world.invalid.prompt',
                  ),
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_message',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'message',
              kind: SceneEdgeKind.defaultFlow,
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

      final diagnostic = diagnoseScene(
        scene,
      ).byCode(SceneDiagnosticCode.capabilityForbiddenForProfile).single;

      expect(
        diagnostic.capabilityIssueCode,
        SceneExecutionCapabilityIssueCode.forbiddenForProfile,
      );
      expect(buildSceneRuntimePlan(scene).canBuild, isFalse);
    });
  });
}
