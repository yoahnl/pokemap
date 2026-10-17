import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'scaled ground footprints retain their convex shape and containment',
    () {
      for (final scale in [1.0, 5e-5, 1e4]) {
        final footprint = BorderGroundFootprint(
          points: [
            BorderGroundPoint(x: 0, z: 0),
            BorderGroundPoint(x: .1 * scale, z: 0),
            BorderGroundPoint(x: 0, z: .1 * scale),
          ],
        );
        final replacement = SpatialBorderGroundReplacement(
          left: 0,
          top: 0,
          right: scale,
          bottom: scale,
          lowerHeight: 0,
          upperHeight: 1,
          footprints: [footprint],
        );
        expect(replacement.contains(.02 * scale, .02 * scale), isTrue);
        expect(replacement.contains(.08 * scale, .08 * scale), isFalse);
      }
    },
  );

  test(
    'a reusable cliff keeps its authored ground polygon in both revisions',
    () {
      final raw = record();
      final decoded = decodeBorderBlueprintRecordJson(raw, formatVersion: 8);
      expect(encodeBorderBlueprintRecordJson(decoded, formatVersion: 8), raw);
    },
  );

  test('an empty triangle cannot become a ground footprint', () {
    final raw = record(
      points: [
        {'x': 0.0, 'z': 0.0},
        {'x': 0.5, 'z': 0.0},
        {'x': 1.0, 'z': 0.0},
      ],
    );
    expect(
      () => decodeBorderBlueprintRecordJson(raw, formatVersion: 8),
      throwsA(isA<FormatException>()),
    );
  });

  test('a concave ground region requires separate convex pieces', () {
    final raw = record(
      points: [
        {'x': 0.0, 'z': 0.0},
        {'x': 1.0, 'z': 0.0},
        {'x': 0.25, 'z': 0.25},
        {'x': 0.0, 'z': 1.0},
      ],
    );
    expect(
      () => decodeBorderBlueprintRecordJson(raw, formatVersion: 8),
      throwsA(isA<FormatException>()),
    );
  });

  test('precise ground footprints require a ground-replacing cliff', () {
    final raw = record();
    for (final key in ['draft', 'latestPublished']) {
      ((raw[key] as Map)['definition'] as Map).remove('replacesGround');
    }
    expect(
      () => decodeBorderBlueprintRecordJson(raw, formatVersion: 8),
      throwsA(isA<FormatException>()),
    );
  });

  test('older border wire versions reject precise ground footprints', () {
    expect(
      () => decodeBorderBlueprintRecordJson(record(), formatVersion: 7),
      throwsA(isA<FormatException>()),
    );
  });
}

Map<String, Object?> record({List<Map<String, double>>? points}) {
  Map<String, Object?> definition() => {
    'name': 'Falaise arrondie',
    'previewSeed': '19',
    'template': 'connectedLine',
    'replacesGround': true,
    'primitives': [
      {
        'id': 'corner',
        'sourceModelId': 'cliff-corner',
        'role': 'lineCorner',
        'authoredOrientation': 'west',
        'weight': 1,
        'transforms': {
          'allowFlipX': false,
          'allowedQuarterTurns': [0, 1, 2, 3],
        },
        'animationIndex': null,
        'animationLoop': true,
        'animationSpeed': 1.0,
        'blocksMovement': false,
        'groundFootprints': [
          points ??
              [
                {'x': -0.5, 'z': -0.5},
                {'x': 0.5, 'z': -0.5},
                {'x': -0.5, 'z': 0.5},
              ],
        ],
      },
    ],
    'defaults': {
      'irregularityPermille': 0,
      'detailDensityPermille': 0,
      'variationPermille': 0,
      'maxOverlapPx': 0,
      'gapTolerancePx': 0,
      'depthRows': 1,
    },
    'sortOrder': 0,
  };
  return {
    'id': 'reusable-cliff',
    'draft': {'baseRevision': 1, 'definition': definition()},
    'latestPublished': {'revision': 1, 'definition': definition()},
  };
}
