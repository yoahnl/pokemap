import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:map_core/map_core.dart';
import 'ui06_scene_fixture.dart';

const ui09DialogueId = 'ui09_guichet';
const ui09WaitingFact = 'ui09_waiting';
const ui09Yarn = '''title: Accueil
---
Chef: Bonjour ! Souhaitez-vous préparer votre départ ?
-> Je pars maintenant
    Chef: Votre train vous attend sur le quai.
    <<outcome depart>>
-> Je préfère attendre
    Chef: Prenez votre temps dans la salle d’attente.
    <<outcome attente>>
===
''';

Future<Ui06SceneFixture> createUi09RuntimeFixture() async {
  final fixture = await Ui06SceneFixture.create();
  try {
    final base = await fixture.maps.loadMap(
      fixture.session,
      fixture.manifest.maps.first,
    );
    await LocalNarrativeAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    ).publish(
      NarrativePublication(
        base: base,
        current: base.map,
        expectedScenes: {Ui06SceneFixture.sceneId: fixture.scene},
        expectedDialogues: {ui09DialogueId: null},
        expectedFacts: {ui09WaitingFact: null},
        scenes: [ui09ConsumerScene()],
        facts: [
          NarrativeFactDefinition(
            id: ui09WaitingFact,
            label: 'Attente choisie',
          ),
        ],
        dialogues: [
          const NarrativeDialogueSource(
            entry: ProjectDialogueEntry(
              id: ui09DialogueId,
              name: 'Rencontre au guichet',
              relativePath: 'dialogues/ui09_guichet.yarn',
              defaultStartNode: 'Accueil',
              declaredOutcomes: [
                DialogueDeclaredOutcome(id: 'depart', label: 'Partir'),
                DialogueDeclaredOutcome(id: 'attente', label: 'Attendre'),
              ],
            ),
            source: ui09Yarn,
          ),
        ],
      ),
    );
    return fixture;
  } catch (_) {
    await fixture.dispose();
    rethrow;
  }
}

SceneAsset ui09ConsumerScene() => SceneAsset(
  id: Ui06SceneFixture.sceneId,
  name: 'Rencontre au guichet',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'conversation',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: ui09DialogueId,
          yarnNodeName: 'Accueil',
          expectedOutcomes: ['depart', 'attente'],
        ),
      ),
      for (final branch in ['depart', 'attente'])
        SceneNode(
          id: branch,
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: branch == 'depart'
                  ? Ui06SceneFixture.departureFactId
                  : ui09WaitingFact,
              value: true,
            ),
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start_conversation',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'conversation',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final branch in ['depart', 'attente']) ...[
        SceneEdge(
          id: 'choice_$branch',
          fromNodeId: 'conversation',
          fromPortId: branch,
          toNodeId: branch,
          kind: SceneEdgeKind.dialogueOutcome,
        ),
        SceneEdge(
          id: 'end_$branch',
          fromNodeId: branch,
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
      SceneEdge(
        id: 'complete',
        fromNodeId: 'conversation',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);
