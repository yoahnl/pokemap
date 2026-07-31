import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';

void main() {
  group('SmartTileGridDetector', () {
    test('detects the common 32 px grid without separators', () {
      final candidates = const SmartTileGridDetector().detect(
        const SmartTileGridDetectionInput(
          imageWidth: 160,
          imageHeight: 96,
        ),
      );

      expect(candidates.first.geometry.cellWidth, 32);
      expect(candidates.first.geometry.cellHeight, 32);
      expect(candidates.first.geometry.columns, 5);
      expect(candidates.first.geometry.rows, 3);
      expect(candidates.first.geometry.hasPartialCells, isFalse);
    });

    test('detects the user-owned ERW terrain atlas geometry', () {
      final geometry = const SmartTileGridDetector()
          .detect(
            const SmartTileGridDetectionInput(
              imageWidth: 1760,
              imageHeight: 2304,
            ),
          )
          .first
          .geometry;

      expect(geometry.cellWidth, 32);
      expect(geometry.cellHeight, 32);
      expect(geometry.columns, 55);
      expect(geometry.rows, 72);
      expect(geometry.hasPartialCells, isFalse);
    });

    test('detects margins and spacing from transparent scan lines', () {
      final axis = <double>[
        0,
        0,
        ...List<double>.filled(32, 1),
        0,
        0,
        ...List<double>.filled(32, 1),
        0,
        0,
      ];

      final candidates = const SmartTileGridDetector().detect(
        SmartTileGridDetectionInput(
          imageWidth: 70,
          imageHeight: 70,
          columnAlphaCoverage: axis,
          rowAlphaCoverage: axis,
        ),
      );

      expect(candidates.first.geometry.cellWidth, 32);
      expect(candidates.first.geometry.cellHeight, 32);
      expect(candidates.first.geometry.marginX, 2);
      expect(candidates.first.geometry.marginY, 2);
      expect(candidates.first.geometry.spacingX, 2);
      expect(candidates.first.geometry.spacingY, 2);
      expect(candidates.first.geometry.columns, 2);
      expect(candidates.first.geometry.rows, 2);
    });

    test('keeps every detected value editable and reports partial cells', () {
      final detected = const SmartTileGridDetector()
          .detect(
            const SmartTileGridDetectionInput(
              imageWidth: 100,
              imageHeight: 67,
            ),
          )
          .first
          .geometry;
      final corrected = detected.copyWith(
        cellWidth: 24,
        cellHeight: 24,
        originX: 2,
        originY: 3,
        marginX: 1,
        marginY: 1,
        spacingX: 2,
        spacingY: 2,
      );

      expect(corrected.cellWidth, 24);
      expect(corrected.cellHeight, 24);
      expect(corrected.originX, 2);
      expect(corrected.originY, 3);
      expect(corrected.hasPartialCells, isTrue);
      expect(corrected.usableWidth, 97);
      expect(corrected.usableHeight, 63);
    });

    test('rejects scan-line data with the wrong dimensions', () {
      expect(
        () => const SmartTileGridDetector().detect(
          const SmartTileGridDetectionInput(
            imageWidth: 32,
            imageHeight: 32,
            columnAlphaCoverage: <double>[1],
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
