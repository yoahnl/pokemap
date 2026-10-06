import 'package:avelune_studio/presentation/features/resources/decor_collision_mask.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets(
    'a continuous stroke follows the image and excludes outside cells',
    (tester) async {
      final painted = <GridPos>[];
      var started = 0, ended = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 340,
              child: DecorCollisionMask(
                width: 5,
                height: 3,
                tileWidth: 16,
                tileHeight: 24,
                blocked: {},
                image: const SizedBox.expand(),
                onPaint: painted.add,
                onStrokeStart: () => started++,
                onStrokeEnd: () => ended++,
                onStrokeCancel: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final canvas = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('decor-collision-canvas')),
      );
      final drag = await tester.startGesture(
        canvas.localToGlobal(const Offset(4, 10)),
      );
      await drag.moveTo(canvas.localToGlobal(const Offset(68, 10)));
      await drag.up();
      await tester.pump();
      expect(painted.toSet(), {
        for (var x = 0; x < 5; x++) GridPos(x: x, y: 0),
      });
      expect(started, 1);
      expect(ended, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fine keyboard painting and pointer cancellation use real stroke boundaries',
    (tester) async {
      final painted = <GridPos>[];
      var cancelled = 0, started = 0, ended = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: DecorCollisionMask(
                width: 2,
                height: 2,
                tileWidth: 16,
                tileHeight: 24,
                fine: true,
                blocked: {},
                image: const SizedBox.expand(),
                onPaint: painted.add,
                onStrokeStart: () => started++,
                onStrokeEnd: () => ended++,
                onStrokeCancel: () => cancelled++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final canvas = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('decor-collision-canvas')),
      );
      await tester.tapAt(canvas.localToGlobal(const Offset(3.2, 4.8)));
      await tester.pump();
      expect(painted.last, const GridPos(x: 3, y: 4));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(painted.last, const GridPos(x: 4, y: 4));
      final gesture = await tester.startGesture(
        canvas.localToGlobal(const Offset(12, 6)),
      );
      await gesture.cancel();
      expect(cancelled, 1);
      expect(started, 3);
      expect(ended, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
