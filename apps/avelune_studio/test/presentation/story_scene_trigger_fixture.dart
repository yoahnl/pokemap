part of 'story_scene_trigger_round_trip_test.dart';

StoryDialogueSource _plainDialogue(String id, String name, String source) =>
    StoryDialogueSource(
      source: source,
      entry: ProjectDialogueEntry(
        id: id,
        name: name,
        relativePath: 'dialogues/$id.yarn',
        declaredOutcomes: [
          DialogueDeclaredOutcome(id: 'yes', label: 'Choix déclaré'),
        ],
      ),
    );

StoryDialogueSource _dialogue() {
  const source =
      'title: Start\n---\n'
      '-> Accepter la lettre\n    <<outcome yes>>\n'
      '-> Refuser la lettre\n    <<outcome no>>\n===\n';
  final parsed = readLocalizedDialogue(source: source, sourceLocale: 'fr');
  return StoryDialogueSource(
    source: source,
    entry: ProjectDialogueEntry(
      id: 'talk',
      name: 'La lettre',
      relativePath: 'dialogues/talk.yarn',
      declaredOutcomes: [
        DialogueDeclaredOutcome(id: 'yes', label: 'Accepter'),
        DialogueDeclaredOutcome(id: 'no', label: 'Refuser'),
      ],
      localization: parsed.localization.translate(
        parsed.localization.units.first.id,
        'en',
        'Accept the letter',
      ),
    ),
  );
}

SceneAsset _scene(String dialogueId) => SceneAsset(
  id: 'gate',
  name: 'Ouverture de la porte',
  graph: graphOf(
    [
      startNode(),
      SceneNode(
        id: 'ask',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: dialogueId,
          expectedOutcomes: ['yes', 'no'],
        ),
      ),
      endNode('accepted'),
      endNode('refused'),
    ],
    [
      link('start', 'ask'),
      link('ask', 'refused'),
      for (final (port, to) in [('yes', 'accepted'), ('no', 'refused')])
        SceneEdge(
          id: 'ask.$port',
          fromNodeId: 'ask',
          fromPortId: port,
          toNodeId: to,
          kind: SceneEdgeKind.dialogueOutcome,
        ),
    ],
  ),
);
