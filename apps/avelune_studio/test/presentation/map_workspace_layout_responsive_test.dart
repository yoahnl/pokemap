import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_harness.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'native collision strokes remain undoable without editing the ground',
    (tester) async {
      final h = MapSelectionHarness.of(workspaceProject);
      addTearDown(h.dispose);
      await h.pump(tester);
      final ground = h.document.current.layers;
      await h.use(tester, StudioMapTool.collisionPaint);
      await h.dragCells(tester, 2, 2, 3, 2);
      final collision = h.document.current.layers
          .whereType<CollisionLayer>()
          .single;
      expect(
        collision.collisions[2 * h.document.current.size.width + 2],
        isTrue,
      );
      expect(
        collision.collisions[2 * h.document.current.size.width + 3],
        isTrue,
      );
      expect(h.document.canUndo, isTrue);
      h.document.restore(redo: false);
      expect(h.document.current.layers, ground);
    },
  );
}
