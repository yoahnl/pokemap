import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/placed_element_collision_clip.dart';

void main() {
  group('placed element collision render clip', () {
    test('large footprint depends only on sparse collision cells', () {
      final background = buildPlacedElementCollisionClip(
        destinationRect: const Rect.fromLTWH(0, 0, 128, 128),
        sourceGridSize: const GridSize(width: 128, height: 128),
        quarterTurns: 0,
        collisionCells: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 127, y: 127),
        ],
        includeCollisionCells: true,
      );
      final foreground = buildPlacedElementCollisionClip(
        destinationRect: const Rect.fromLTWH(0, 0, 128, 128),
        sourceGridSize: const GridSize(width: 128, height: 128),
        quarterTurns: 0,
        collisionCells: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 127, y: 127),
        ],
        includeCollisionCells: false,
      );

      expect(background.sourceCellVisits, 2);
      expect(background.path.contains(const Offset(0.5, 0.5)), isTrue);
      expect(background.path.contains(const Offset(64.5, 64.5)), isFalse);
      expect(background.path.contains(const Offset(127.5, 127.5)), isTrue);
      expect(foreground.sourceCellVisits, 2);
      expect(foreground.path.contains(const Offset(0.5, 0.5)), isFalse);
      expect(foreground.path.contains(const Offset(64.5, 64.5)), isTrue);
      expect(foreground.path.contains(const Offset(127.5, 127.5)), isFalse);
    });

    test('moves and rotates sparse collision cells into destination space', () {
      const sourceSize = GridSize(width: 3, height: 2);
      const sourceCollision = GridPos(x: 2, y: 0);
      const destinationRect = Rect.fromLTWH(50, 70, 20, 30);
      final transform = QuarterTurnGridTransform(
        sourceSize: sourceSize,
        quarterTurns: 1,
      );
      final destination = transform.sourceToDestination(sourceCollision);
      final clip = buildPlacedElementCollisionClip(
        destinationRect: destinationRect,
        sourceGridSize: sourceSize,
        quarterTurns: 1,
        collisionCells: const <GridPos>[sourceCollision],
        includeCollisionCells: true,
      );
      final cellWidth = destinationRect.width / transform.destinationSize.width;
      final cellHeight =
          destinationRect.height / transform.destinationSize.height;
      final collisionCenter = Offset(
        destinationRect.left + (destination.x + 0.5) * cellWidth,
        destinationRect.top + (destination.y + 0.5) * cellHeight,
      );

      expect(clip.sourceCellVisits, 1);
      expect(clip.path.contains(collisionCenter), isTrue);
      expect(clip.path.contains(const Offset(55, 75)), isFalse);
    });

    test('ignores duplicate and out-of-footprint collision cells', () {
      final clip = buildPlacedElementCollisionClip(
        destinationRect: const Rect.fromLTWH(0, 0, 4, 4),
        sourceGridSize: const GridSize(width: 2, height: 2),
        quarterTurns: 0,
        collisionCells: const <GridPos>[
          GridPos(x: 1, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: -1, y: 0),
          GridPos(x: 2, y: 0),
        ],
        includeCollisionCells: false,
      );

      expect(clip.sourceCellVisits, 4);
      expect(clip.validCollisionCellCount, 1);
      expect(clip.path.contains(const Offset(3, 3)), isFalse);
      expect(clip.path.contains(const Offset(1, 1)), isTrue);
    });
  });
}
