import 'package:avelune_studio/features/scenes/application/scene_node_search.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_readable_summary.dart';
import 'package:avelune_studio/features/scenes/application/scene_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scene_graph_project_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test('node summaries resolve native document and outcome labels without mutation', () {
    final scene = Ui06SceneFixture.buildScene(withCinematic: true);
    final project = ProjectManifest(
      name: 'Libellés',
      maps: [],
      tilesets: [],
      dialogues: [
        for (final source in Ui06SceneFixture.buildDialogues()) source.entry,
      ],
      cinematics: [Ui06SceneFixture.buildCinematic()],
    );
    final before = scene.toJson();
    String summary(String id, [ProjectManifest? context]) => sceneNodeSummary(
      scene.graph.nodes.singleWhere((node) => node.id == id),
      context ?? project,
      scene,
    );
    expect(summary('welcome'), Ui06SceneFixture.names['station_welcome']);
    expect(summary('pass'), 'Laissez-passer obtenu');
    expect(summary('attente'), 'Attente');
    expect(summary('cinematic'), 'Un instant avant le départ');
    expect(summary('authorize'), 'Action');
    final missing = project.copyWith(dialogues: [], cinematics: []);
    expect(summary('welcome', missing), 'Dialogue introuvable');
    expect(summary('cinematic', missing), 'Cinématique introuvable');
    expect(scene.toJson(), before);
  });

  test('blocks are found by title or by kind', () {
    final scene = sceneCanvasFixture();
    expect(sceneNodeMatches(scene, 'autoriser').map((node) => node.id), [
      'action',
    ]);
    expect(sceneNodeMatches(scene, 'fin').map((node) => node.id), ['end']);
    expect(sceneNodeMatches(scene, ''), hasLength(3));
  });

  test('the readable summary follows the graph from the start', () {
    var scene = sceneCanvasFixture();
    for (final (from, to) in [('start', 'action'), ('action', 'end')]) {
      scene = addSceneEdgeDraft(
        scene,
        fromNodeId: from,
        fromPortId: 'completed',
        toNodeId: to,
      ).updatedScene;
    }
    final summary = sceneReadableSummary(
      scene,
      (node) => node.title ?? node.kind.name,
    );
    expect(summary.conditions, isEmpty);
    expect(summary.steps, ['Action · Autoriser le départ', 'Fin · end']);
    expect(summary.unreached, 0);
    final empty = sceneReadableSummary(
      sceneCanvasFixture(),
      (node) => node.kind.name,
    );
    expect(empty.steps, isEmpty);
    expect(empty.unreached, 2);
  });
  test('canonical linking makes the exact edge in one undo operation', () {
    final original = sceneCanvasFixture();
    final session = SceneEditSession(original, base: original);
    expect(session.connect('start', 'completed', 'action'), isTrue);
    final edge = session.current.graph.edges.single;
    expect(edge.fromNodeId, 'start');
    expect(edge.fromPortId, 'completed');
    expect(edge.toNodeId, 'action');
    expect(edge.kind, SceneEdgeKind.defaultFlow);
    expect(session.undoCount, 1);
    session.restore(redo: false);
    expect(session.current.graph.edges, isEmpty);
    expect(session.current, original);
  });
}
