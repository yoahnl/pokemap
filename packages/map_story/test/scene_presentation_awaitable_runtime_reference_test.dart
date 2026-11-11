import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

/// La référence canonique cue → nœud Scene awaitable — BETA-CIN-069.
///
/// Le binding porte `awaitableNodeId` côté SCENE, jamais côté clip
/// Presentation : il peut viser un dialogue Yarn paginé ou une interaction
/// structurée, et rien d'autre. L'ancienne forme `interactionNodeId` est une
/// rupture de schéma assumée : elle est rejetée sans dual-reader ni
/// migration. La suppression d'une cible utilisée est bloquée avec la liste
/// des usages ; aucun chemin ne peut produire une référence pendante.
void main() {
  ScenePreSessionInteractionSpec interactionSpec() =>
      ScenePreSessionInteractionSpec.text(
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

  SceneAsset scene({
    required List<ScenePresentationInteractionCueBinding> bindings,
    List<SceneNode> extraNodes = const [],
    String? awaitableActionTitle,
    String sceneName = 'Pré-session',
  }) {
    return SceneAsset(
      id: 'scene_pre_session',
      name: sceneName,
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
              interactionCueBindings: bindings,
            ),
          ),
          SceneNode(
            id: 'intro_dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: 'professor_intro'),
          ),
          SceneNode(
            id: 'ask_name',
            kind: SceneNodeKind.action,
            title: awaitableActionTitle,
            payload: SceneActionPayload.preSessionInteraction(
              interactionSpec(),
            ),
          ),
          ...extraNodes,
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
  }

  group('BETA-CIN-069 the canonical reference round-trips', () {

    test('the runtime plan transports the awaitable ids per marker', () {
      final asset = scene(
        bindings: [
          ScenePresentationInteractionCueBinding(
            markerId: 'cue_dialogue',
            awaitableNodeId: 'intro_dialogue',
          ),
          ScenePresentationInteractionCueBinding(
            markerId: 'cue_name',
            awaitableNodeId: 'ask_name',
          ),
        ],
      );
      final plan = buildSceneRuntimePlan(asset).plan!;
      final intent = plan.nodes
          .singleWhere((node) => node.id == 'presentation')
          .intent;
      expect(
        intent.presentationAwaitableNodeIdsByMarkerId,
        const {'cue_dialogue': 'intro_dialogue', 'cue_name': 'ask_name'},
      );
    });

  });

}
