import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_harness.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('native viewport paints and erases exactly one collision cell', (
    tester,
  ) async {
    final h = MapSelectionHarness.of(workspaceProject);
    addTearDown(h.dispose);
    await h.pump(tester);
    final ground = h.document.current.layers.single;
    await h.use(tester, StudioMapTool.collisionPaint);
    await h.tapCell(tester, 2, 2);
    final index = 2 * h.document.current.size.width + 2;
    final painted = h.document.current.layers
        .whereType<CollisionLayer>()
        .single;
    expect(painted.collisions[index], isTrue);
    expect(painted.collisions.where((cell) => cell), hasLength(1));
    expect(h.document.current.layers.first, ground);
    expect(h.document.dirty, isTrue);
    await h.use(tester, StudioMapTool.collisionErase);
    await h.tapCell(tester, 2, 2);
    final erased = h.document.current.layers.whereType<CollisionLayer>().single;
    expect(erased.collisions[index], isFalse);
    expect(erased.collisions.where((cell) => cell), isEmpty);
    expect(h.document.current.layers.first, ground);
  });
}
