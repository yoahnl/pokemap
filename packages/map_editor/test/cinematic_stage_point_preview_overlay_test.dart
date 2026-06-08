import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart';

void main() {
  group('CinematicMapBackdropViewportTransform', () {
    test('previewToTile and tileToPreview transformations', () {
      final transform = CinematicMapBackdropViewportTransform(
        frame: const Rect.fromLTWH(50, 50, 400, 300),
        mapWidth: 20,
        mapHeight: 15,
      );

      expect(transform.isUsable, isTrue);

      // Top-left
      final tlPreview = transform.tileToPreview(0, 0);
      expect(tlPreview, const Offset(50, 50));

      final tlTile = transform.previewToTile(const Offset(50, 50));
      expect(tlTile, const Offset(0, 0));

      // Center of first tile (0.5, 0.5)
      final centerPreview = transform.tileToPreview(0.5, 0.5);
      expect(centerPreview, const Offset(50 + 10, 50 + 10)); // cell width = 20, cell height = 20

      // Map bottom-right
      final brPreview = transform.tileToPreview(20, 15);
      expect(brPreview, const Offset(450, 350));

      // Click inside map
      final tileCoord = transform.previewToTile(const Offset(150, 150));
      // x: (150 - 50) / 20 = 5.0
      // y: (150 - 50) / 20 = 5.0
      expect(tileCoord, const Offset(5.0, 5.0));

      // isTileInsideMap
      expect(transform.isTileInsideMap(5, 5), isTrue);
      expect(transform.isTileInsideMap(-1, 5), isFalse);
      expect(transform.isTileInsideMap(21, 5), isFalse);
    });

    test('handles pan and zoom correctly', () {
      // With pan and zoom frame adjustments
      final transform = CinematicMapBackdropViewportTransform(
        frame: const Rect.fromLTWH(0, 0, 800, 600),
        mapWidth: 40,
        mapHeight: 30,
      );

      final cellWidth = 800 / 40; // 20
      final cellHeight = 600 / 30; // 20

      expect(transform.tileToPreview(10, 10), Offset(10 * cellWidth, 10 * cellHeight));
      expect(transform.previewToTile(const Offset(200, 200)), const Offset(10, 10));
    });
  });

  group('CinematicStagePointPreviewOverlay Widget', () {
    testWidgets('renders stage points with custom labels', (tester) async {
      final points = [
        CinematicStagePoint(id: 'point_1', label: 'Start Point', x: 2.5, y: 3.5),
        CinematicStagePoint(id: 'point_2', label: 'End Point', x: 8.5, y: 10.5),
      ];

      final transform = CinematicMapBackdropViewportTransform(
        frame: const Rect.fromLTWH(0, 0, 800, 600),
        mapWidth: 40,
        mapHeight: 30,
      );

      String? selectedId;
      var updateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: CinematicStagePointPreviewOverlay(
                    stagePoints: points,
                    selectedStagePointId: selectedId,
                    onSelectStagePointId: (id) => selectedId = id,
                    onUpdateStagePoint: (_) => updateCalled = true,
                    transform: transform,
                    compact: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Start Point'), findsOneWidget);
      expect(find.text('End Point'), findsOneWidget);
      expect(find.byKey(const ValueKey('cinematic-stage-point-marker-point_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('cinematic-stage-point-marker-point_2')), findsOneWidget);
    });

    testWidgets('triggers select callback on tap', (tester) async {
      final points = [
        CinematicStagePoint(id: 'point_1', label: 'Start Point', x: 2.5, y: 3.5),
      ];

      final transform = CinematicMapBackdropViewportTransform(
        frame: const Rect.fromLTWH(0, 0, 800, 600),
        mapWidth: 40,
        mapHeight: 30,
      );

      String? selectedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: CinematicStagePointPreviewOverlay(
                    stagePoints: points,
                    selectedStagePointId: selectedId,
                    onSelectStagePointId: (id) => selectedId = id,
                    onUpdateStagePoint: (_) {},
                    transform: transform,
                    compact: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Point'));
      await tester.pump();

      expect(selectedId, equals('point_1'));
    });

    testWidgets('dragging triggers local update and snaps/commits on end', (tester) async {
      final points = [
        CinematicStagePoint(id: 'point_1', label: 'Start Point', x: 2.5, y: 3.5),
      ];

      final transform = CinematicMapBackdropViewportTransform(
        frame: const Rect.fromLTWH(0, 0, 800, 600), // cell is 20x20
        mapWidth: 40,
        mapHeight: 30,
      );

      CinematicStagePoint? updatedPoint;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: CinematicStagePointPreviewOverlay(
                    stagePoints: points,
                    selectedStagePointId: 'point_1',
                    onSelectStagePointId: (_) {},
                    onUpdateStagePoint: (p) => updatedPoint = p,
                    transform: transform,
                    compact: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Start Point')),
        kind: PointerDeviceKind.mouse,
      );
      // Drag by delta of 40 pixels (exactly 2 tiles right)
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();

      // Drag by delta of 20 pixels down (exactly 1 tile down)
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();

      // Release drag to snap and commit
      await gesture.up();
      await tester.pump();

      expect(updatedPoint, isNotNull);
      expect(updatedPoint!.id, equals('point_1'));
      // Original was 2.5, 3.5. We dragged +2.0 X, +1.0 Y.
      expect(updatedPoint!.x, equals(4.5));
      expect(updatedPoint!.y, equals(4.5));
    });
  });
}
