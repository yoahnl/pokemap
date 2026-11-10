import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  for (final enabled in [false, true]) {
    test(
      'party recording toggles publish and cold reopen losslessly from $enabled',
      () async {
        final original = _finish(enabled);
        final scene = SceneAsset(
          id: 'finish',
          name: 'Victoire',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'finish',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(original),
              ),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                id: 'enter',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'finish',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'leave',
                fromNodeId: 'finish',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
            ],
          ),
        );
        final fixture = await CinematicAdapterFixture.create(scenes: [scene]);
        addTearDown(fixture.dispose);
        final beforeDisk = await fixture.file('project.json').readAsBytes();
        final project = await fixture.readManifest();
        final draft = SceneActionDraft(
          project: project,
          current: scene.graph.nodes[1].payload,
          changed: () {},
        );
        addTearDown(draft.dispose);
        expect(draft.values['recordParty'], '$enabled');
        draft.changeParameter('recordParty', '${!enabled}');
        expect(draft.valid, isTrue);
        final applied = draft.buildPayload() as SceneActionPayload;
        final expected = Map<String, dynamic>.from(original.toJson());
        if (enabled) {
          expected.remove('recordParty');
        } else {
          expected['recordParty'] = true;
        }
        expect(applied.consequence!.toJson(), expected);
        expect(await fixture.file('project.json').readAsBytes(), beforeDisk);
        final session = SceneEditSession(scene, base: scene);
        expect(session.replacePayload(scene.graph.nodes[1], applied), isTrue);
        expect(session.current.graph.edges, scene.graph.edges);
        expect(session.current.layout, scene.layout);
        expect(session.current.metadata, scene.metadata);
        final edited = session.current;
        await LocalSceneAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        ).publishScene(base: scene, current: edited);
        final reopened = await LocalMapWorkspaceAdapter().loadProject(
          fixture.session,
        );
        expect(reopened.scenes.single, edited);
        expect(
          (reopened.scenes.single.graph.nodes[1].payload as SceneActionPayload)
              .consequence!
              .toJson(),
          expected,
        );
        expect(original.recordParty, enabled);
      },
    );
  }

  test('battle recovery payload replacement preserves edges layout metadata and undo', () {
    final scene = _battleScene();
    final session = SceneEditSession(scene, base: scene);
    final node = scene.graph.nodes.singleWhere((node) => node.id == 'battle');
    final original = node.payload as SceneBattlePayload;
    expect(
      session.replacePayload(
        node,
        SceneBattlePayload.fromJson({
          ...original.toJson(),
          'defeatRecovery': 'returnToRecoveryPoint',
        }),
      ),
      isTrue,
    );
    expect(
      (session.current.graph.nodes
                  .singleWhere((node) => node.id == 'battle')
                  .payload
              as SceneBattlePayload)
          .defeatRecovery,
      SceneBattleDefeatRecovery.returnToRecoveryPoint,
    );
    expect(session.current.graph.edges, scene.graph.edges);
    expect(session.current.layout, scene.layout);
    expect(session.current.metadata, scene.metadata);
    expect(session.undoCount, 1);
    session.restore(redo: false);
    expect(session.current, scene);
  });
}

SceneFinishGameConsequence _finish(bool recordParty) =>
    SceneConsequence.fromJson({
      'kind': 'finishGame',
      'contractVersion': 1,
      'endingId': 'custom.ending:champion',
      'outcome': 'victory',
      'commitPolicy': 'persistBeforePresentation',
      'result': {
        'title': {
          'fallback': 'Victoire',
          'translations': {'en': 'Victory', 'de': 'Sieg'},
        },
        'summary': {'fallback': 'Parcours accompli'},
        'details': [
          {'fallback': 'Équipe gagnante'},
        ],
      },
      'credits': {
        'title': {
          'fallback': 'Crédits',
          'translations': {'de': 'Mitwirkende'},
        },
        'author': 'Auteur',
        'contributors': ['Une équipe'],
        'licenses': ['Une licence'],
        'endingLabel': {'fallback': 'Champion'},
        'skippable': false,
      },
      'postGamePolicy': 'continueGame',
      'label': 'Titre conservé',
      'notes': 'Notes conservées',
      if (recordParty) 'recordParty': true,
    }) as SceneFinishGameConsequence;

SceneAsset _battleScene() => SceneAsset(
  id: 'scene',
  name: 'Rival',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'battle',
        kind: SceneNodeKind.battle,
        payload: SceneBattlePayload(battleKind: 'trainer', trainerId: 'rival'),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'battle',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'win',
        fromNodeId: 'battle',
        fromPortId: 'victory',
        toNodeId: 'end',
        kind: SceneEdgeKind.battleVictory,
      ),
      SceneEdge(
        id: 'lose',
        fromNodeId: 'battle',
        fromPortId: 'defeat',
        toNodeId: 'end',
        kind: SceneEdgeKind.battleDefeat,
      ),
    ],
  ),
);
