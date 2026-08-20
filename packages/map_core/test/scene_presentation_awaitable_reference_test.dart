import 'package:map_core/map_core.dart';
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
    test('a cue may target a Yarn dialogue or a structured interaction', () {
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

      final reloaded = SceneAsset.fromJson(asset.toJson());
      expect(reloaded, asset);
      final payload = reloaded.graph.nodes
          .singleWhere((node) => node.id == 'presentation')
          .payload as ScenePresentationCinematicPayload;
      expect(
        {
          for (final binding in payload.interactionCueBindings)
            binding.markerId: binding.awaitableNodeId,
        },
        {'cue_dialogue': 'intro_dialogue', 'cue_name': 'ask_name'},
      );
    });

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

    test('a cue carries no copy of the dialogue, prompt or branches', () {
      final binding = ScenePresentationInteractionCueBinding(
        markerId: 'cue_name',
        awaitableNodeId: 'ask_name',
      );
      expect(
        binding.toJson().keys.toSet(),
        {'markerId', 'awaitableNodeId'},
        reason: 'the plain reference is the whole payload — any extra key '
            'would be a duplicated narrative source of truth',
      );
      final routed = ScenePresentationInteractionCueBinding(
        markerId: 'cue_confirm',
        awaitableNodeId: 'confirm_name',
        outcomeRoutes: [
          ScenePresentationCueOutcomeRoute(
            outputPortId: 'declined',
            outcome: PresentationInteractionOutcome.repeatFromMarker(
              markerId: 'cue_name',
            ),
          ),
        ],
      );
      final json = routed.toJson();
      expect(
        json.keys.toSet(),
        {'markerId', 'awaitableNodeId', 'outcomeRoutes'},
      );
      final route = (json['outcomeRoutes'] as List).single as Map;
      expect(
        route.keys.toSet(),
        {'outputPortId', 'outcome'},
        reason: 'routes reference ports and markers by id only — no '
            'dialogue text, prompt or branch content is ever copied',
      );
      expect(
        (route['outcome'] as Map).keys.toSet(),
        {'kind', 'markerId'},
      );
    });
  });

  group('BETA-CIN-069 the legacy schema is rejected without dual-reader', () {
    test('a binding still carrying interactionNodeId refuses to load', () {
      expect(
        () => ScenePresentationInteractionCueBinding.fromJson(const {
          'markerId': 'cue_name',
          'interactionNodeId': 'ask_name',
        }),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            allOf(contains('awaitableNodeId'), contains('BETA-CIN-069')),
          ),
        ),
      );
    });

    test('a whole Scene document in the obsolete shape refuses to load', () {
      final json = scene(
        bindings: [
          ScenePresentationInteractionCueBinding(
            markerId: 'cue_name',
            awaitableNodeId: 'ask_name',
          ),
        ],
      ).toJson();
      final encoded = json.toString();
      expect(encoded, contains('awaitableNodeId'));

      final nodes =
          ((json['graph'] as Map<String, dynamic>)['nodes'] as List<dynamic>);
      final presentation = nodes
          .cast<Map<String, dynamic>>()
          .singleWhere((node) => node['id'] == 'presentation');
      final payload = presentation['payload'] as Map<String, dynamic>;
      final binding =
          (payload['interactionCueBindings'] as List<dynamic>).single
              as Map<String, dynamic>;
      binding['interactionNodeId'] = binding.remove('awaitableNodeId');

      expect(() => SceneAsset.fromJson(json), throwsA(isA<ValidationException>()));
    });
  });

  group('BETA-CIN-069 fail-closed reference validation', () {
    test('an absent target refuses the whole Scene', () {
      expect(
        () => scene(
          bindings: [
            ScenePresentationInteractionCueBinding(
              markerId: 'cue_ghost',
              awaitableNodeId: 'ghost',
            ),
          ],
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('unknown Scene node: ghost'),
          ),
        ),
      );
    });

    test('a non-awaitable target refuses the whole Scene and names the kind',
        () {
      expect(
        () => scene(
          bindings: [
            ScenePresentationInteractionCueBinding(
              markerId: 'cue_merge',
              awaitableNodeId: 'join',
            ),
          ],
          extraNodes: [
            SceneNode(
              id: 'join',
              kind: SceneNodeKind.merge,
              payload: SceneMergePayload(),
            ),
          ],
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            allOf(contains('awaitable'), contains('merge')),
          ),
        ),
      );
    });

    test('an action without a structured interaction is not awaitable', () {
      expect(
        () => scene(
          bindings: [
            ScenePresentationInteractionCueBinding(
              markerId: 'cue_reward',
              awaitableNodeId: 'give_potion',
            ),
          ],
          extraNodes: [
            SceneNode(
              id: 'give_potion',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.giveItem(itemId: 'potion', quantity: 1),
              ),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a self-reference is rejected as cyclic', () {
      expect(
        () => scene(
          bindings: [
            ScenePresentationInteractionCueBinding(
              markerId: 'cue_self',
              awaitableNodeId: 'presentation',
            ),
          ],
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('cyclic'),
          ),
        ),
      );
    });

    test('one awaitable node cannot serve two cues of the same node', () {
      expect(
        () => scene(
          bindings: [
            ScenePresentationInteractionCueBinding(
              markerId: 'cue_one',
              awaitableNodeId: 'ask_name',
            ),
            ScenePresentationInteractionCueBinding(
              markerId: 'cue_two',
              awaitableNodeId: 'ask_name',
            ),
          ],
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('duplicate id: ask_name'),
          ),
        ),
      );
    });

    test('one awaitable node cannot serve cues of two Presentations', () {
      expect(
        () => scene(
          bindings: [
            ScenePresentationInteractionCueBinding(
              markerId: 'cue_one',
              awaitableNodeId: 'ask_name',
            ),
          ],
          extraNodes: [
            SceneNode(
              id: 'presentation_bis',
              kind: SceneNodeKind.presentationCinematic,
              payload: ScenePresentationCinematicPayload(
                presentationCinematicId: 'closing',
                interactionCueBindings: [
                  ScenePresentationInteractionCueBinding(
                    markerId: 'cue_two',
                    awaitableNodeId: 'ask_name',
                  ),
                ],
              ),
            ),
          ],
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('only one'),
          ),
        ),
      );
    });

    test('the awaitability predicate decides for every node kind', () {
      final representatives = <SceneNodeKind, SceneNode>{
        SceneNodeKind.start: SceneNode(id: 'n', kind: SceneNodeKind.start),
        SceneNodeKind.end: SceneNode(id: 'n', kind: SceneNodeKind.end),
        SceneNodeKind.yarnDialogue: SceneNode(
          id: 'n',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'd'),
        ),
        SceneNodeKind.condition: SceneNode(
          id: 'n',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(),
        ),
        SceneNodeKind.action: SceneNode(
          id: 'n',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.preSessionInteraction(interactionSpec()),
        ),
        SceneNodeKind.battle: SceneNode(
          id: 'n',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(battleKind: 'trainer'),
        ),
        SceneNodeKind.cinematic: SceneNode(
          id: 'n',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'c'),
        ),
        SceneNodeKind.presentationCinematic: SceneNode(
          id: 'n',
          kind: SceneNodeKind.presentationCinematic,
          payload: ScenePresentationCinematicPayload(
            presentationCinematicId: 'p',
          ),
        ),
        SceneNodeKind.branchByOutcome: SceneNode(
          id: 'n',
          kind: SceneNodeKind.branchByOutcome,
          payload: SceneBranchByOutcomePayload(),
        ),
        SceneNodeKind.merge: SceneNode(
          id: 'n',
          kind: SceneNodeKind.merge,
          payload: SceneMergePayload(),
        ),
      };
      expect(
        representatives.keys.toSet(),
        SceneNodeKind.values.toSet(),
        reason: 'every node kind must take a side — a new kind has to decide '
            'its awaitability here',
      );
      final awaitables = {
        for (final entry in representatives.entries)
          if (sceneNodeIsPresentationAwaitable(entry.value)) entry.key,
      };
      expect(
        awaitables,
        {SceneNodeKind.yarnDialogue, SceneNodeKind.action},
        reason: 'a cue suspends the timeline: only nodes able to produce an '
            'outcome may be referenced',
      );
    });
  });

  group('BETA-CIN-069 rename keeps identity, deletion is assisted', () {
    final bindings = [
      ScenePresentationInteractionCueBinding(
        markerId: 'cue_name',
        awaitableNodeId: 'ask_name',
      ),
    ];

    test('renaming the Scene or retitling the target keeps the reference', () {
      final before = scene(bindings: bindings);
      final after = scene(
        bindings: bindings,
        sceneName: 'Pré-session (renommée)',
        awaitableActionTitle: 'Saisie du nom (retitrée)',
      );
      ScenePresentationCinematicPayload payloadOf(SceneAsset asset) =>
          asset.graph.nodes
              .singleWhere((node) => node.id == 'presentation')
              .payload as ScenePresentationCinematicPayload;
      expect(
        payloadOf(after).interactionCueBindings,
        payloadOf(before).interactionCueBindings,
        reason: 'the reference targets the node id — names and titles are '
            'display concerns and can never break it',
      );
    });

    test('deleting a bound target is blocked with the exact usage list', () {
      final asset = scene(bindings: bindings);

      final usages = presentationCueUsagesOfSceneNode(asset.graph, 'ask_name');
      expect(
        usages,
        const [
          ScenePresentationCueUsage(
            presentationNodeId: 'presentation',
            markerId: 'cue_name',
          ),
        ],
      );

      expect(
        () => removeSceneNodeDraft(asset, 'ask_name'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('cue_name'),
              contains('presentation'),
              contains('Déliez'),
            ),
          ),
        ),
      );
    });

    test('unbinding first makes the deletion legal and leaves no dangling',
        () {
      final asset = scene(bindings: bindings);
      final unbound = updateScenePresentationInteractionCueBinding(
        asset,
        presentationNodeId: 'presentation',
        markerId: 'cue_name',
        awaitableNodeId: null,
      ).updatedScene;

      expect(
        presentationCueUsagesOfSceneNode(unbound.graph, 'ask_name'),
        isEmpty,
      );

      final removed = removeSceneNodeDraft(unbound, 'ask_name').updatedScene;
      expect(
        removed.graph.nodes.where((node) => node.id == 'ask_name'),
        isEmpty,
      );
      expect(SceneAsset.fromJson(removed.toJson()), removed);
    });

    test('an unrelated node still deletes without any cue ceremony', () {
      final asset = scene(bindings: bindings);
      final removed =
          removeSceneNodeDraft(asset, 'intro_dialogue').updatedScene;
      expect(
        removed.graph.nodes.where((node) => node.id == 'intro_dialogue'),
        isEmpty,
      );
    });
  });
}
