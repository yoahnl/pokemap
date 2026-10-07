import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  testWidgets('fixed runtime camera ignores editor zoom gestures', (
    tester,
  ) async {
    final controller = SpatialSceneController()
      ..setView(SpatialEditorView.game);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SpatialSceneView(
          scene: MapSpatialScene(width: 2, depth: 2),
          models: const [],
          loadModel: (_) async => Uint8List(0),
          controller: controller,
          onCell: (_, _) {},
          background: Colors.black,
          ground: Colors.green,
          edge: Colors.grey,
          errorBuilder: (_, _) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    final position = tester.getCenter(find.byType(SpatialSceneView));
    tester.binding.handlePointerEvent(
      PointerScrollEvent(position: position, scrollDelta: const Offset(0, 120)),
    );
    final trackpad = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    await trackpad.panZoomStart(position);
    await trackpad.panZoomUpdate(position, pan: const Offset(0, -80), scale: 2);
    await trackpad.panZoomEnd();
    expect(controller.zoom, 1);
    expect(controller.pan, Offset.zero);
    expect(controller.yaw, .5);
    expect(controller.pitch, .5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('wheel and trackpad scroll zoom without dragging the scene', (
    tester,
  ) async {
    final controller = SpatialSceneController()
      ..setView(SpatialEditorView.game);
    addTearDown(controller.dispose);
    final deltas = <double>[];
    var drags = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SpatialSceneView(
          scene: MapSpatialScene(width: 2, depth: 2),
          models: const [],
          loadModel: (_) async => Uint8List(0),
          controller: controller,
          onCell: (_, _) {},
          onZoom: deltas.add,
          onDragStart: (_, _, _) {
            drags++;
            return true;
          },
          background: Colors.black,
          ground: Colors.green,
          edge: Colors.grey,
          errorBuilder: (_, _) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    final position = tester.getCenter(find.byType(SpatialSceneView));
    tester.binding.handlePointerEvent(
      PointerScrollEvent(position: position, scrollDelta: const Offset(0, 120)),
    );
    expect(deltas, [120]);
    final trackpad = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    await trackpad.panZoomStart(position);
    await trackpad.panZoomUpdate(position, pan: const Offset(0, -80));
    expect(deltas.last, 80);
    await trackpad.panZoomUpdate(position, pan: const Offset(0, -80), scale: 2);
    expect(deltas.last, closeTo(-693.147, .001));
    await trackpad.panZoomEnd();
    expect(drags, 0);
    expect(controller.pan, Offset.zero);
    expect(controller.view, SpatialEditorView.game);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('unavailable GPU reaches the scene error channel', (
    tester,
  ) async {
    final controller = SpatialSceneController();
    addTearDown(controller.dispose);
    Object? failure;
    var ready = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SpatialSceneView(
          scene: MapSpatialScene(width: 2, depth: 2),
          models: const [],
          loadModel: (_) async => Uint8List(0),
          controller: controller,
          onCell: (_, _) {},
          background: Colors.black,
          ground: Colors.green,
          edge: Colors.grey,
          onReady: () => ready = true,
          errorBuilder: (_, error) {
            failure = error;
            return const Text('GPU unavailable');
          },
        ),
      ),
    );
    await tester.pump();
    expect(failure, isNotNull);
    expect(ready, isFalse);
    expect(find.text('GPU unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
