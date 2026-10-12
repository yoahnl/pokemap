import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  for (final view in SpatialEditorView.values) {
    testWidgets('right drag pans the ${view.name} editor without editing', (
      tester,
    ) async {
      final controller = SpatialSceneController()..setView(view);
      addTearDown(controller.dispose);
      var edits = 0;
      await mountScene(tester, controller, onEdit: () => edits++);
      final beforeYaw = controller.yaw;
      final beforePitch = controller.pitch;
      final pointer = TestPointer(71, PointerDeviceKind.mouse);
      final start = tester.getCenter(find.byType(SpatialSceneView));
      await tester.sendEventToBinding(
        pointer.down(start, buttons: kSecondaryMouseButton),
      );
      expect(controller.pan, Offset.zero);
      await tester.sendEventToBinding(
        pointer.move(
          start + const Offset(40, 30),
          buttons: kSecondaryMouseButton,
        ),
      );
      await tester.pump();
      expect(controller.pan.distance, greaterThan(0));
      final moved = controller.pan;
      await tester.sendEventToBinding(pointer.up());
      await tester.pump();
      await tester.sendEventToBinding(
        PointerHoverEvent(position: start + const Offset(80, 60)),
      );
      expect(controller.pan, moved);
      expect(controller.yaw, beforeYaw);
      expect(controller.pitch, beforePitch);
      expect(controller.zoom, 1);
      expect(edits, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('right drag follows the rotated camera axes', (tester) async {
    final controller = SpatialSceneController()
      ..setView(SpatialEditorView.orbit)
      ..yaw = math.pi / 2;
    addTearDown(controller.dispose);
    await mountScene(tester, controller);
    final pointer = TestPointer(72, PointerDeviceKind.mouse);
    final start = tester.getCenter(find.byType(SpatialSceneView));
    await tester.sendEventToBinding(
      pointer.down(start, buttons: kSecondaryMouseButton),
    );
    await tester.sendEventToBinding(
      pointer.move(start + const Offset(40, 0), buttons: kSecondaryMouseButton),
    );
    expect(controller.pan.dx, closeTo(0, .00001));
    expect(controller.pan.dy, closeTo(.5, .00001));
    await tester.sendEventToBinding(pointer.up());
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a cancelled right drag does not own the next primary gesture', (
    tester,
  ) async {
    final controller = SpatialSceneController()
      ..setView(SpatialEditorView.game);
    addTearDown(controller.dispose);
    await mountScene(tester, controller);
    final start = tester.getCenter(find.byType(SpatialSceneView));
    final pointer = TestPointer(73, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.down(start, buttons: kSecondaryMouseButton),
    );
    await tester.sendEventToBinding(
      pointer.move(start + const Offset(40, 0), buttons: kSecondaryMouseButton),
    );
    await tester.sendEventToBinding(pointer.cancel());
    final moved = controller.pan;
    await tester.sendEventToBinding(
      pointer.down(start, buttons: kPrimaryButton),
    );
    await tester.sendEventToBinding(pointer.move(start + const Offset(40, 30)));
    await tester.sendEventToBinding(pointer.up());
    expect(controller.pan, moved);
    expect(moved.distance, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a right click with pointer jitter does not move the view', (
    tester,
  ) async {
    final controller = SpatialSceneController();
    addTearDown(controller.dispose);
    await mountScene(tester, controller);
    final pointer = TestPointer(74, PointerDeviceKind.mouse);
    final start = tester.getCenter(find.byType(SpatialSceneView));
    await tester.sendEventToBinding(
      pointer.down(start, buttons: kSecondaryMouseButton),
    );
    await tester.sendEventToBinding(
      pointer.move(
        start + const Offset(.1, .1),
        buttons: kSecondaryMouseButton,
      ),
    );
    await tester.sendEventToBinding(pointer.up());
    expect(controller.pan, Offset.zero);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('holding both mouse buttons navigates without starting an edit', (
    tester,
  ) async {
    final controller = SpatialSceneController()
      ..setView(SpatialEditorView.game);
    addTearDown(controller.dispose);
    var edits = 0;
    await mountScene(tester, controller, onEdit: () => edits++);
    final pointer = TestPointer(75, PointerDeviceKind.mouse);
    final start = tester.getCenter(find.byType(SpatialSceneView));
    const buttons = kPrimaryButton | kSecondaryMouseButton;
    await tester.sendEventToBinding(pointer.down(start, buttons: buttons));
    await tester.sendEventToBinding(
      pointer.move(start + const Offset(40, 30), buttons: buttons),
    );
    await tester.sendEventToBinding(pointer.up());
    expect(controller.pan.distance, greaterThan(0));
    expect(edits, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the fixed runtime camera ignores right drag', (tester) async {
    final controller = SpatialSceneController()
      ..setView(SpatialEditorView.game);
    addTearDown(controller.dispose);
    await mountScene(tester, controller, editable: false);
    final pointer = TestPointer(76, PointerDeviceKind.mouse);
    final start = tester.getCenter(find.byType(SpatialSceneView));
    await tester.sendEventToBinding(
      pointer.down(start, buttons: kSecondaryMouseButton),
    );
    await tester.sendEventToBinding(
      pointer.move(
        start + const Offset(40, 30),
        buttons: kSecondaryMouseButton,
      ),
    );
    await tester.sendEventToBinding(pointer.up());
    expect(controller.pan, Offset.zero);
    expect(controller.zoom, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'releasing the right button stops navigation while left stays held',
    (tester) async {
      final controller = SpatialSceneController();
      addTearDown(controller.dispose);
      await mountScene(tester, controller);
      final pointer = TestPointer(77, PointerDeviceKind.mouse);
      final start = tester.getCenter(find.byType(SpatialSceneView));
      await tester.sendEventToBinding(
        pointer.down(start, buttons: kPrimaryButton | kSecondaryMouseButton),
      );
      await tester.sendEventToBinding(
        pointer.move(
          start + const Offset(40, 30),
          buttons: kPrimaryButton | kSecondaryMouseButton,
        ),
      );
      final moved = controller.pan;
      await tester.sendEventToBinding(
        pointer.move(start + const Offset(80, 60), buttons: kPrimaryButton),
      );
      await tester.sendEventToBinding(pointer.up());
      expect(controller.pan, moved);
      expect(moved.distance, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<void> mountScene(
  WidgetTester tester,
  SpatialSceneController controller, {
  VoidCallback? onEdit,
  bool editable = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: 800,
          height: 600,
          child: SpatialSceneView(
            scene: MapSpatialScene(width: 10, depth: 10),
            models: const [],
            loadModel: (_) async => Uint8List(0),
            controller: controller,
            onCell: (_, _) => onEdit?.call(),
            onContent: (_) => onEdit?.call(),
            onSurfaceTap: (_) => onEdit?.call(),
            onDragStart: editable
                ? (_, _, _) {
                    onEdit?.call();
                    return true;
                  }
                : null,
            background: Colors.black,
            ground: Colors.green,
            edge: Colors.grey,
            errorBuilder: (_, _) => const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
