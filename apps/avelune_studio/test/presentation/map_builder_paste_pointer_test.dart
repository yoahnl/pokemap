import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'map_builder_selection_harness.dart';

Future<void> _command(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
}

void _hover(SelectionHost host, int x, int z) => host.scene.onHover!(
  SpatialSurfaceHit(
    cell: (x, z),
    position: Model3dVector3(x: x + .5, y: 0, z: z + .5),
  ),
);

void main() {
  testWidgets('⌘V in 3D pastes under the hovered cell of the canvas', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');
    await _command(tester, LogicalKeyboardKey.keyC);
    expect(host.maps.clipboard?.items, hasLength(1));
    expect(host.scene.onHover, isNotNull);

    _hover(host, 7, 6);
    await _command(tester, LogicalKeyboardKey.keyV);
    await host.settle();

    final oaks = host.instances.where((item) => item.modelId == 'oak');
    expect(oaks, hasLength(3));
    final pasted = oaks.where(
      (item) => item.id != 'oak_1' && item.id != 'oak_2',
    );
    expect(pasted.map((item) => (item.position.x, item.position.z)).single, (
      7.5,
      6.5,
    ));
  });

  testWidgets('leaving the 3D canvas forgets the hovered cell', (tester) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');
    await _command(tester, LogicalKeyboardKey.keyC);
    _hover(host, 7, 6);
    host.scene.onHover!(null);
    await _command(tester, LogicalKeyboardKey.keyV);
    await host.settle();

    final pasted = host.instances.where(
      (item) =>
          item.modelId == 'oak' && item.id != 'oak_1' && item.id != 'oak_2',
    );
    expect(pasted.map((item) => (item.position.x, item.position.z)).single, (
      3.5,
      3.5,
    ));
  });
}
