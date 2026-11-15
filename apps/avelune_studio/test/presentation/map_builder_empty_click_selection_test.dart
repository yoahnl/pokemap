import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'map_builder_selection_harness.dart';

Finder get _inspector => find.byKey(const ValueKey('selection-inspector'));

Future<void> _tapGround(
  SelectionHost host,
  int x,
  int z, {
  LogicalKeyboardKey? modifier,
}) async {
  if (modifier != null) await host.tester.sendKeyDownEvent(modifier);
  host.scene.onSurfaceTap!(
    SpatialSurfaceHit(
      cell: (x, z),
      position: Model3dVector3(x: x + .5, y: 0, z: z + .5),
    ),
  );
  if (modifier != null) await host.tester.sendKeyUpEvent(modifier);
  await host.settle();
}

void main() {
  testWidgets('a click on empty ground clears the 3D selection', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');
    expect(host.maps.active!.selectedId, 'oak_1');
    expect(_inspector, findsOneWidget);

    await _tapGround(host, 1, 8);

    expect(host.maps.active!.selectedId, isNull);
    expect(host.scene.selectedContent, isNull);
    expect(_inspector, findsNothing);
    expect(host.maps.active!.canUndo, isFalse);
  });

  testWidgets('a click in the sky clears the 3D selection too', (tester) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');

    host.scene.onEmptyTap!();
    await host.settle();

    expect(host.maps.active!.selectedId, isNull);
    expect(_inspector, findsNothing);
  });

  testWidgets('Shift or ⌘ on empty ground keeps a multi-selection', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');
    await host.click('oak_2', shift: true);
    expect(find.text('2 éléments sélectionnés'), findsOneWidget);

    await _tapGround(host, 1, 8, modifier: LogicalKeyboardKey.shiftLeft);
    await _tapGround(host, 1, 8, modifier: LogicalKeyboardKey.metaLeft);

    expect(find.text('2 éléments sélectionnés'), findsOneWidget);
  });

  testWidgets('dragging the camera from empty ground keeps the selection', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');

    host.scene.onDragStart!(1, 8, null);
    host.scene.onDragUpdate!((2, 8));
    host.scene.onDragEnd!();
    await host.settle();

    expect(host.maps.active!.selectedId, 'oak_1');
    expect(_inspector, findsOneWidget);
  });

  testWidgets('a click on a model anchor cell still selects that model', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');

    await _tapGround(host, 4, 2);

    expect(host.maps.active!.selectedId, 'oak_2');
  });
}
