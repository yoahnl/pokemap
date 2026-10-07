import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  testWidgets('unavailable GPU reaches the scene error channel', (tester) async {
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
