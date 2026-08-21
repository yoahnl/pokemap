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
  group('BETA-CIN-079 the branch arcs drawn on the marker track', () {
    PresentationCueAuthoringView viewWith(
      List<ScenePresentationCueOutcomeRoute> routes,
    ) =>
        PresentationCueAuthoringView(
          markerId: 'cue_confirm',
          sceneId: 'intro',
          presentationNodeId: 'presentation',
          awaitableNodeId: 'confirm_name',
          awaitableLabel: 'Confirmer le nom',
          awaitableKind: SceneNodeKind.action,
          outputPortIds: const <String>['confirmed', 'declined'],
          routes: routes,
        );

    const markers = <String, int>{
      'cue_name': 4000000,
      'cue_confirm': 12000000,
    };

    test('a replay draws a backwards arc between the two cues', () {
      final arcs = presentationCueBranchArcs(
        view: viewWith([replay]),
        markerStartUsById: markers,
      );
      expect(arcs, const [
        PresentationCueBranchArc(
          outputPortId: 'declined',
          fromUs: 12000000,
          toUs: 4000000,
        ),
      ]);
      expect(
        arcs.single.isBackwards,
        isTrue,
        reason: 'the loop an author most needs to see',
      );
    });

    test('destination-less outcomes draw nothing', () {
      final arcs = presentationCueBranchArcs(
        view: viewWith([
          ScenePresentationCueOutcomeRoute(
            outputPortId: 'confirmed',
            outcome: const PresentationInteractionOutcome.stop(),
          ),
        ]),
        markerStartUsById: markers,
      );
      expect(arcs, isEmpty);
    });

    test('a destination the cinematic lost is skipped, never drawn at zero',
        () {
      final arcs = presentationCueBranchArcs(
        view: viewWith([replay]),
        markerStartUsById: const <String, int>{'cue_confirm': 12000000},
      );
      expect(
        arcs,
        isEmpty,
        reason: 'drawing an arc to 00:00 would invent a branch the author '
            'never wrote',
      );
    });

    test('an unplaced cue draws nothing at all', () {
      final arcs = presentationCueBranchArcs(
        view: viewWith([replay]),
        markerStartUsById: const <String, int>{'cue_name': 4000000},
      );
      expect(arcs, isEmpty);
    });
  });

}
