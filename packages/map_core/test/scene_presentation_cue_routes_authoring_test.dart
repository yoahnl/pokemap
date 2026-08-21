import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// L'authoring des branches d'un cue — BETA-CIN-079.
///
/// Les routes vivent sur le binding côté Scene et parlent des ports de
/// sortie du nœud awaitable lié : on ne peut pas en écrire avant la liaison,
/// ni viser un port que le nœud n'expose pas. Relier le MÊME cue au MÊME
/// nœud conserve les branches ; changer de cible les abandonne, parce
/// qu'elles parlaient des ports de l'ancienne.
void main() {
  ScenePreSessionInteractionSpec confirmation() =>
      ScenePreSessionInteractionSpec.confirmation(
        prompt: SceneInteractionPrompt(
          localizationKey: 'newGame.confirm',
          fallbackText: 'On garde ce nom ?',
        ),
      );

  ScenePreSessionInteractionSpec nameEntry() =>
      ScenePreSessionInteractionSpec.text(
        prompt: SceneInteractionPrompt(
          localizationKey: 'newGame.name',
          fallbackText: 'Ton nom ?',
        ),
        resultBinding: const ScenePreSessionResultBinding(
          field: ScenePreSessionDraftField.playerName,
        ),
      );

  SceneAsset scene({
    List<ScenePresentationCueOutcomeRoute> routes =
        const <ScenePresentationCueOutcomeRoute>[],
    String boundTo = 'confirm_name',
  }) =>
      SceneAsset(
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
                    markerId: 'cue_confirm',
                    awaitableNodeId: boundTo,
                    outcomeRoutes: routes,
                  ),
                ],
              ),
            ),
            SceneNode(
              id: 'ask_name',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.preSessionInteraction(nameEntry()),
            ),
            SceneNode(
              id: 'confirm_name',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.preSessionInteraction(confirmation()),
            ),
            SceneNode(
              id: 'talk',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(
                dialogueId: 'intro',
                expectedOutcomes: const ['heureux', 'triste'],
              ),
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
              id: 'presentation_end',
              fromNodeId: 'presentation',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.presentationCompleted,
            ),
          ],
        ),
      );

  ScenePresentationCueOutcomeRoute replayFromName() =>
      ScenePresentationCueOutcomeRoute(
        outputPortId: 'declined',
        outcome: PresentationInteractionOutcome.repeatFromMarker(
          markerId: 'cue_name',
        ),
      );

  List<ScenePresentationCueOutcomeRoute> routesOf(SceneAsset asset) =>
      (asset.graph.nodes
                  .singleWhere((node) => node.id == 'presentation')
                  .payload
              as ScenePresentationCinematicPayload)
          .interactionCueBindings
          .single
          .outcomeRoutes;

  group('BETA-CIN-079 authoring the routes', () {
    test('routes are stored on the binding and survive a reload', () {
      final updated = updateScenePresentationCueOutcomeRoutes(
        scene(),
        presentationNodeId: 'presentation',
        markerId: 'cue_confirm',
        routes: [replayFromName()],
      ).updatedScene;

      expect(routesOf(updated), [replayFromName()]);
      expect(SceneAsset.fromJson(updated.toJson()), updated);
    });

    test('an unlinked cue cannot carry branches', () {
      final unlinked = updateScenePresentationInteractionCueBinding(
        scene(),
        presentationNodeId: 'presentation',
        markerId: 'cue_confirm',
        awaitableNodeId: null,
      ).updatedScene;

      expect(
        () => updateScenePresentationCueOutcomeRoutes(
          unlinked,
          presentationNodeId: 'presentation',
          markerId: 'cue_confirm',
          routes: [replayFromName()],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('not linked'),
          ),
        ),
      );
    });

    test('a port the bound node never emits is refused', () {
      expect(
        () => updateScenePresentationCueOutcomeRoutes(
          scene(),
          presentationNodeId: 'presentation',
          markerId: 'cue_confirm',
          routes: [
            ScenePresentationCueOutcomeRoute(
              outputPortId: 'completed',
              outcome: const PresentationInteractionOutcome.stop(),
            ),
          ],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('is not an output of confirm_name'),
          ),
        ),
        reason: 'a confirmation emits confirmed or declined, never completed',
      );
    });

    test('one output port cannot carry two branches', () {
      expect(
        () => updateScenePresentationCueOutcomeRoutes(
          scene(),
          presentationNodeId: 'presentation',
          markerId: 'cue_confirm',
          routes: [
            replayFromName(),
            ScenePresentationCueOutcomeRoute(
              outputPortId: 'declined',
              outcome: const PresentationInteractionOutcome.stop(),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('BETA-CIN-079 re-linking a cue', () {
    test('the same target keeps the authored branches', () {
      final withRoutes = scene(routes: [replayFromName()]);
      final relinked = updateScenePresentationInteractionCueBinding(
        withRoutes,
        presentationNodeId: 'presentation',
        markerId: 'cue_confirm',
        awaitableNodeId: 'confirm_name',
      ).updatedScene;

      expect(
        routesOf(relinked),
        [replayFromName()],
        reason: 'touching the link of an unchanged pair must not silently '
            'erase the branches the author wrote',
      );
    });

    test('a different target abandons them', () {
      final withRoutes = scene(routes: [replayFromName()]);
      final moved = updateScenePresentationInteractionCueBinding(
        withRoutes,
        presentationNodeId: 'presentation',
        markerId: 'cue_confirm',
        awaitableNodeId: 'talk',
      ).updatedScene;

      expect(
        routesOf(moved),
        isEmpty,
        reason: 'the routes spoke about the previous node output ports; '
            'keeping them would point at ports that no longer exist',
      );
    });
  });

  group('BETA-CIN-079 the legal output ports of a target', () {
    test('a confirmation exposes its two typed outputs', () {
      expect(
        scenePresentationCueOutputPortIds(scene(), 'confirm_name'),
        const ['confirmed', 'declined'],
      );
    });

    test('a text entry exposes a single completion', () {
      expect(
        scenePresentationCueOutputPortIds(scene(), 'ask_name'),
        const ['completed'],
      );
    });

    test('a Yarn dialogue exposes its authored outcomes', () {
      expect(
        scenePresentationCueOutputPortIds(scene(), 'talk'),
        const ['heureux', 'triste'],
      );
    });

    test('a non-awaitable node exposes nothing at all', () {
      expect(scenePresentationCueOutputPortIds(scene(), 'end'), isEmpty);
      expect(scenePresentationCueOutputPortIds(scene(), 'ghost'), isEmpty);
    });
  });
}
