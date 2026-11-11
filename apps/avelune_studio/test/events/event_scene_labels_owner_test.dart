import 'package:avelune_studio/features/events/application/event_scene_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('the scene count uses the singular only for one scene and shows the filtered share', () {
    expect(eventSceneCountLabel(visible: 0, total: 0, query: ''), '0 scène');
    expect(eventSceneCountLabel(visible: 1, total: 1, query: ''), '1 scène');
    expect(eventSceneCountLabel(visible: 2, total: 2, query: ''), '2 scènes');
    expect(eventSceneCountLabel(visible: 3, total: 3, query: '  '), '3 scènes');
    expect(eventSceneCountLabel(visible: 1, total: 4, query: 'labo'), '1 scène sur 4');
    expect(eventSceneCountLabel(visible: 2, total: 4, query: 'labo'), '2 scènes sur 4');
    expect(eventSceneCountLabel(visible: 0, total: 4, query: 'zzz'), '0 scène sur 4');
  });

  test('the empty message tells an empty project from an unmatched search', () {
    expect(eventSceneEmptyLabel(''), 'Aucune scène dans ce projet.');
    expect(eventSceneEmptyLabel('   '), 'Aucune scène dans ce projet.');
    expect(eventSceneEmptyLabel('  labo '), 'Aucune scène ne correspond à « labo ».');
  });

  test('a row states the block count, the save state and the link', () {
    final scene = _scene('s', 'Scène');
    expect(
      eventSceneRowStatus(scene, dirty: false, linked: false),
      '2 blocs · Enregistrée',
    );
    expect(
      eventSceneRowStatus(scene, dirty: true, linked: true),
      '2 blocs · Modifiée localement · Scène liée',
    );
  });

  test('the dialogue button names the dialogue and the start node, or the missing dialogue', () {
    final project = ProjectManifest(
      name: 'P',
      maps: const [],
      tilesets: const [],
      dialogues: const [
        ProjectDialogueEntry(id: 'welcome', name: 'Accueil', relativePath: 'dialogues/welcome.yarn'),
      ],
    );
    expect(
      eventSceneDialogueLabel(project, SceneYarnDialoguePayload(dialogueId: 'welcome')),
      'Ouvrir le dialogue Accueil',
    );
    expect(
      eventSceneDialogueLabel(
        project,
        SceneYarnDialoguePayload(dialogueId: 'welcome', yarnNodeName: 'Depart'),
      ),
      'Ouvrir le dialogue Accueil · Depart',
    );
    expect(
      eventSceneDialogueLabel(project, SceneYarnDialoguePayload(dialogueId: 'gone')),
      'Ouvrir le dialogue Dialogue introuvable : gone',
    );
  });
}

SceneAsset _scene(String id, String name) => SceneAsset(
  id: id,
  name: name,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);
