import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'support/scene_graph_project_fixture.dart';
import 'support/map_workspace_fixture.dart';

void main() {
  test('canonical connection keeps exact ports and one undo entry', () {
    final original = sceneCanvasFixture();
    final session = SceneEditSession(original, base: original);
    expect(session.connect('start', 'completed', 'action'), isTrue);
    expect(session.undoCount, 1);
    final connected = session.current;
    final edge = connected.graph.edges.single;
    expect(
      (edge.fromNodeId, edge.fromPortId, edge.toNodeId),
      ('start', 'completed', 'action'),
    );
    expect(edge.kind, SceneEdgeKind.defaultFlow);
    session.restore(redo: false);
    expect(session.current, same(original));
    expect(session.current.graph.edges, isEmpty);
    session.restore(redo: true);
    expect(session.current, same(connected));
  });

  test('invalid connection keeps the document and history intact', () {
    final original = sceneCanvasFixture();
    for (final connection in [
      ('start', 'completed', 'missing'),
      ('start', 'missing', 'action'),
      ('missing', 'completed', 'action'),
      ('action', 'completed', 'action'),
    ]) {
      final session = SceneEditSession(original, base: original);
      expect(
        session.connect(connection.$1, connection.$2, connection.$3),
        isFalse,
      );
      expect(session.current, same(original));
      expect(session.undoCount, 0);
      expect(session.canRedo, isFalse);
      expect(session.error, isNotNull);
    }
  });

  test(
    'canonical layout movement commits once and undo restores its position',
    () {
      final original = sceneCanvasFixture();
      var changes = 0;
      final session = SceneEditSession(
        original,
        base: original,
        onChanged: () => changes++,
      );
      expect(session.move('action', 400, 110), isTrue);
      final moved = session.current;
      final layout = moved.layout.nodeLayouts.singleWhere(
        (layout) => layout.nodeId == 'action',
      );
      expect((layout.x, layout.y), (400, 110));
      expect(session.undoCount, 1);
      expect(changes, 1);
      session.restore(redo: false);
      expect(session.current, same(original));
      session.restore(redo: true);
      expect(session.current, same(moved));
      expect(session.move('missing', 20, 30), isFalse);
      expect(session.current, same(moved));
      expect(session.undoCount, 1);
    },
  );

  test(
    'disconnect targets the exact edge and undo restores both connections',
    () {
      final original = sceneCanvasFixture();
      final session = SceneEditSession(original, base: original);
      expect(session.connect('start', 'completed', 'action'), isTrue);
      expect(session.connect('action', 'completed', 'end'), isTrue);
      final connected = session.current;
      final target = connected.graph.edges.first;
      final preserved = connected.graph.edges.last;
      expect(session.disconnect(target.id), isTrue);
      expect(session.current.graph.edges, [preserved]);
      session.restore(redo: false);
      expect(session.current, same(connected));
      session.restore(redo: true);
      expect(session.current.graph.edges, [preserved]);
    },
  );

  test(
    'external selection is validated without mutating a document or history',
    () {
      final original = sceneCanvasFixture();
      final session = SceneEditSession(original, base: original);
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(maps.dispose);
      final navigation = WorkspaceNavigationSession(
        controller: maps,
        isActive: () => true,
        changed: () {},
      );
      navigation.sceneNodes['other'] = 'kept';
      navigation.selectSceneNode(original, 'action');
      expect(navigation.sceneNodes[original.id], 'action');
      navigation.selectSceneNode(original, 'missing');
      expect(navigation.sceneNodes[original.id], 'action');
      expect(navigation.sceneNodes['other'], 'kept');
      expect(session.current, same(original));
      expect(session.undoCount, 0);
      expect(session.dirty, isFalse);
    },
  );

  test('read-only mutation and history guards remain enforced', () {
    final original = sceneCanvasFixture();
    String? problem;
    final session = SceneEditSession(
      original,
      base: original,
      canMutate: () => problem,
    );
    expect(session.connect('start', 'completed', 'action'), isTrue);
    final connected = session.current;
    problem = 'Lecture seule';
    expect(session.move('action', 420, 100), isFalse);
    expect(session.disconnect(connected.graph.edges.single.id), isFalse);
    expect(session.delete('action'), isFalse);
    session.restore(redo: false);
    expect(session.current, same(connected));
    expect(session.undoCount, 1);
    expect(session.error, 'Lecture seule');
    problem = null;
    session.restore(redo: false);
    expect(session.current, same(original));
  });
}
