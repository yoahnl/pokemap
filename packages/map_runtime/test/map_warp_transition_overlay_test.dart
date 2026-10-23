import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  Future<List<int>> pixel(
    MapWarpTransitionType type,
    double coverage, {
    bool revealing = true,
    int y = 96,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 256, 192),
      Paint()..color = const Color(0xff0080ff),
    );
    paintMapWarpTransition(
      canvas,
      const Size(256, 192),
      MapWarpTransition(type: type),
      coverage,
      revealing: revealing,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(256, 192);
    final bytes = (await image.toByteData())!;
    final index = (y * 256 + 128) * 4;
    final value = [for (var i = 0; i < 4; i++) bytes.getUint8(index + i)];
    image.dispose();
    picture.dispose();
    return value;
  }

  test(
    'HGSS matches source band endpoints with continuous movement between them',
    () async {
      for (var step = 0; step <= 6; step++) {
        final coverage = 1 - step / 6;
        final top = 96 - 16 * step;
        if (top > 0) {
          expect(
            await pixel(MapWarpTransitionType.hgss, coverage, y: top - 1),
            [0, 0, 0, 255],
          );
        }
        if (step > 0) {
          expect(await pixel(MapWarpTransitionType.hgss, coverage, y: top), [
            0,
            128,
            255,
            255,
          ]);
          expect(
            await pixel(MapWarpTransitionType.hgss, coverage, y: 191 - top),
            [0, 128, 255, 255],
          );
        }
      }
      expect(await pixel(MapWarpTransitionType.hgss, .98), [0, 128, 255, 255]);
    },
  );

  test('HGSS departure and ordinary fade darken the whole scene', () async {
    final fade = await pixel(MapWarpTransitionType.fade, .5);
    expect(fade[1], closeTo(64, 1));
    expect(fade[2], closeTo(127, 1));
    expect(await pixel(MapWarpTransitionType.hgss, .5, revealing: false), fade);
    expect(await pixel(MapWarpTransitionType.none, 1), [0, 128, 255, 255]);
    expect(await pixel(MapWarpTransitionType.fade, 1), [0, 0, 0, 255]);
    expect(await pixel(MapWarpTransitionType.fade, 0), [0, 128, 255, 255]);
  });

  testWidgets('preview plays both phases and leaves its child unchanged', (
    tester,
  ) async {
    const transition = MapWarpTransition(
      type: MapWarpTransitionType.hgss,
      durationSeconds: .2,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 256,
          height: 192,
          child: MapWarpTransitionPreview(
            transition: transition,
            child: Text('Scene'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    var overlay = tester.widget<MapWarpTransitionOverlay>(
      find.byType(MapWarpTransitionOverlay),
    );
    expect(overlay.coverage, closeTo(.5, .01));
    expect(overlay.revealing, isFalse);
    await tester.pump(const Duration(milliseconds: 300));
    overlay = tester.widget<MapWarpTransitionOverlay>(
      find.byType(MapWarpTransitionOverlay),
    );
    expect(overlay.revealing, isTrue);
    expect(overlay.coverage, closeTo(.75, .01));
    await tester.pumpAndSettle();
    expect(find.text('Scene'), findsOneWidget);
    expect(
      tester
          .widget<MapWarpTransitionOverlay>(
            find.byType(MapWarpTransitionOverlay),
          )
          .coverage,
      0,
    );
  });
}
