import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// Le read model des cues pour l'authoring — BETA-CIN-079.
///
/// Il résout une fois le franchissement de frontière Presentation → Scene :
/// le nœud lié, son libellé humain, les ports légaux et les routes déjà
/// écrites. Un repère absent du résultat n'est simplement pas encore lié.
void main() {
  SceneAsset scene({
    required String id,
    String cinematicId = 'opening',
    String markerId = 'cue_confirm',
    String? awaitableTitle,
    List<ScenePresentationCueOutcomeRoute> routes =
        const <ScenePresentationCueOutcomeRoute>[],
  }) =>
      SceneAsset(
        id: id,
        name: 'Pré-session $id',
        executionProfile: SceneExecutionProfile.preSession,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'presentation',
              kind: SceneNodeKind.presentationCinematic,
              payload: ScenePresentationCinematicPayload(
                presentationCinematicId: cinematicId,
                interactionCueBindings: [
                  ScenePresentationInteractionCueBinding(
                    markerId: markerId,
                    awaitableNodeId: 'confirm_name',
                    outcomeRoutes: routes,
                  ),
                ],
              ),
            ),
            SceneNode(
              id: 'confirm_name',
              kind: SceneNodeKind.action,
              title: awaitableTitle,
              payload: SceneActionPayload.preSessionInteraction(
                ScenePreSessionInteractionSpec.confirmation(
                  prompt: SceneInteractionPrompt(
                    localizationKey: 'newGame.confirm',
                    fallbackText: 'On garde ce nom ?',
                  ),
                ),
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

  final replay = ScenePresentationCueOutcomeRoute(
    outputPortId: 'declined',
    outcome: PresentationInteractionOutcome.repeatFromMarker(
      markerId: 'cue_name',
    ),
  );

  test('resolves the bound node, its ports and its authored routes', () {
    final views = buildPresentationCueAuthoringViews(
      presentationCinematicId: 'opening',
      scenes: [scene(id: 'intro', awaitableTitle: 'Confirmer le nom', routes: [replay])],
    );

    final view = views['cue_confirm']!;
    expect(view.sceneId, 'intro');
    expect(view.presentationNodeId, 'presentation');
    expect(view.awaitableNodeId, 'confirm_name');
    expect(view.awaitableLabel, 'Confirmer le nom');
    expect(view.awaitableKind, SceneNodeKind.action);
    expect(view.outputPortIds, const ['confirmed', 'declined']);
    expect(view.routeFor('declined'), replay);
    expect(
      view.routeFor('confirmed'),
      isNull,
      reason: 'an unrouted port is left to the default continuation',
    );
  });

  test('falls back to the node id when no title is authored', () {
    final views = buildPresentationCueAuthoringViews(
      presentationCinematicId: 'opening',
      scenes: [scene(id: 'intro')],
    );
    expect(
      views['cue_confirm']!.awaitableLabel,
      'confirm_name',
      reason: 'the label is display-only; identity stays the node id',
    );
  });

  test('a cue of another cinematic is not in the view', () {
    final views = buildPresentationCueAuthoringViews(
      presentationCinematicId: 'opening',
      scenes: [scene(id: 'intro', cinematicId: 'ending')],
    );
    expect(views, isEmpty);
  });

  test('an unlinked marker is simply absent, never an empty binding', () {
    final views = buildPresentationCueAuthoringViews(
      presentationCinematicId: 'opening',
      scenes: [scene(id: 'intro')],
    );
    expect(views.containsKey('cue_name'), isFalse);
  });

  test('two scenes binding one marker resolve deterministically', () {
    final views = buildPresentationCueAuthoringViews(
      presentationCinematicId: 'opening',
      scenes: [
        scene(id: 'zulu', awaitableTitle: 'Depuis Zulu'),
        scene(id: 'alpha', awaitableTitle: 'Depuis Alpha'),
      ],
    );
    expect(
      views['cue_confirm']!.sceneId,
      'alpha',
      reason: 'iteration order of the project must never change what the '
          'panel shows',
    );
  });
}
