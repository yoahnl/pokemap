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
      expect(interactions[0].outputPortIds, const ['completed']);
      expect(interactions[1].outputPortIds, const ['option_a']);
      expect(interactions[2].outputPortIds, const ['completed']);
      expect(interactions[3].outputPortIds, const ['confirmed', 'declined']);
      expect(interactions[4].outputPortIds, const ['completed']);
    });

    test('builds the exact runtime request used by previews and playback', () {
      final interaction = ScenePreSessionInteractionSpec.selection(
        prompt: SceneInteractionPrompt(
          localizationKey: 'newGame.starter.prompt',
          fallbackText: 'Choisis ton partenaire.',
        ),
        options: [
          SceneInteractionOption(
            id: 'starter_leaf',
            label: SceneInteractionPrompt(
              localizationKey: 'newGame.starter.leaf',
              fallbackText: 'Feuille',
            ),
          ),
        ],
        constraints: SceneSelectionConstraints(
          minSelections: 1,
          maxSelections: 1,
        ),
      );

      final request = interaction.buildRequest(
        requestId: 'preview:starter',
        revision: 4,
      );

      expect(request, isA<SceneSelectionInteractionRequest>());
      expect(request.requestId, 'preview:starter');
      expect(request.revision, 4);
      expect(request.prompt, interaction.prompt);
      expect(
        (request as SceneSelectionInteractionRequest).options,
        interaction.options,
      );
      expect(request.constraints, interaction.selectionConstraints);
    });

    test('round-trips Presentation cue bindings to interaction nodes', () {
      final payload = ScenePresentationCinematicPayload(
        presentationCinematicId: 'opening',
        interactionCueBindings: [
          ScenePresentationInteractionCueBinding(
            markerId: 'ask_name',
            awaitableNodeId: 'input_name',
          ),
        ],
      );

      expect(SceneNodePayload.fromJson(payload.toJson()), payload);
      expect(payload.interactionCueBindings.single.markerId, 'ask_name');
      expect(
        () => ScenePresentationCinematicPayload(
          presentationCinematicId: 'opening',
          interactionCueBindings: [
            ScenePresentationInteractionCueBinding(
              markerId: 'ask_name',
              awaitableNodeId: 'input_name',
            ),
            ScenePresentationInteractionCueBinding(
              markerId: 'ask_name',
              awaitableNodeId: 'input_other',
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects a bound interaction reached before its Presentation', () {
      final interaction = ScenePreSessionInteractionSpec.text(
        prompt: SceneInteractionPrompt(
          localizationKey: 'newGame.playerName.prompt',
          fallbackText: 'Quel est ton prénom ?',
        ),
        resultBinding: const ScenePreSessionResultBinding(
          field: ScenePreSessionDraftField.playerName,
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
              id: 'ask_name',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.preSessionInteraction(interaction),
            ),
            SceneNode(
              id: 'opening',
              kind: SceneNodeKind.presentationCinematic,
              payload: ScenePresentationCinematicPayload(
                presentationCinematicId: 'opening',
                interactionCueBindings: [
                  ScenePresentationInteractionCueBinding(
                    markerId: 'cue_player_name',
                    awaitableNodeId: 'ask_name',
                  ),
                ],
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_ask_name',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'ask_name',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'ask_name_opening',
              fromNodeId: 'ask_name',
              fromPortId: 'completed',
              toNodeId: 'opening',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'opening_end',
              fromNodeId: 'opening',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.presentationCompleted,
            ),
          ],
        ),
      );

      final diagnostics = diagnoseScene(scene).diagnostics
          .where(
            (diagnostic) =>
                diagnostic.code.name ==
                'presentationInteractionReachedBeforePresentation',
          )
          .toList(growable: false);

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.severity, SceneDiagnosticSeverity.error);
      expect(diagnostics.single.nodeId, 'ask_name');
      expect(checkSceneRuntimeCompilation(scene).canCompile, isFalse);
    });

    test('rejects cue bindings to missing or non-awaitable nodes', () {
      SceneAsset build(String awaitableNodeId) => SceneAsset(
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
                    markerId: 'ask_name',
                    awaitableNodeId: awaitableNodeId,
                  ),
                ],
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: const [],
        ),
      );

      expect(() => build('missing'), throwsA(isA<ValidationException>()));
      expect(() => build('end'), throwsA(isA<ValidationException>()));
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
      expect(checkSceneRuntimeCompilation(scene).canCompile, isFalse);
    });
  });
}
