import 'package:map_core/src/models/border_ground_footprint.dart';
import 'package:map_core/src/models/border_ground_surface.dart';
import 'package:map_core/src/operations/border_format_version.dart';
import 'package:map_core/src/operations/project_border_catalog_json_codec.dart';
import 'package:test/test.dart';

void main() {
  for (final version in [8, 9, 10]) {
    test('catalog $version preserves draft and published ground geometry', () {
      final raw = _catalog(version);
      final decoded = decodeProjectBorderCatalogJson(raw);
      expect(encodeProjectBorderCatalogJson(decoded), raw);
      expect(
        minimumBorderCatalogFormatVersionForRecord(decoded.records.single),
        version,
      );
    });
  }

  for (final (authored, declared) in [(8, 7), (9, 8), (10, 9)]) {
    test('catalog $declared rejects ground requiring version $authored', () {
      final raw = _catalog(authored)..['formatVersion'] = declared;
      expect(
        () => decodeProjectBorderCatalogJson(raw),
        throwsA(isA<FormatException>()),
      );
    });
  }

  test('a draft slope requires version ten even with a flat publication', () {
    final raw = _catalog(10);
    final record = (raw['records'] as List).single as Map;
    final published = (record['latestPublished'] as Map)['definition'] as Map;
    final primitive = (published['primitives'] as List).single as Map;
    final surface = (primitive['groundSurfaces'] as List).single as Map;
    surface.remove('gradientX');
    surface.remove('gradientZ');
    final decoded = decodeProjectBorderCatalogJson(raw);
    expect(
      minimumBorderCatalogFormatVersionForRecord(decoded.records.single),
      10,
    );
  });

  test('ground values reject invalid geometry and keep immutable polygons', () {
    final points = [
      BorderGroundPoint(x: -.5, z: -.5),
      BorderGroundPoint(x: .5, z: -.5),
      BorderGroundPoint(x: -.5, z: .5),
    ];
    final footprint = BorderGroundFootprint(points: points);
    points.clear();
    expect(footprint.points, hasLength(3));
    expect(() => footprint.points.clear(), throwsUnsupportedError);
    expect(
      () => BorderGroundSurface(
        sourceSmartTilePresetId: 'grass',
        materialId: 'grass',
        height: 0,
        gradientX: double.nan,
        footprints: [footprint],
      ),
      throwsException,
    );
    expect(
      () => BorderGroundFootprint(
        points: [
          BorderGroundPoint(x: 0, z: 0),
          BorderGroundPoint(x: 1, z: 0),
          BorderGroundPoint(x: 2, z: 0),
        ],
      ),
      throwsException,
    );
  });
}

Map<String, Object?> _catalog(int version) {
  final points = [
    {'x': -.5, 'z': -.5},
    {'x': .5, 'z': -.5},
    {'x': -.5, 'z': .5},
  ];
  Map<String, Object?> definition() => {
    'name': 'Reusable cliff',
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
        'groundFootprints': [points],
        if (version >= 9)
          'groundSurfaces': [
            {
              'sourceSmartTilePresetId': 'grass',
              'materialId': 'grass',
              'height': .5,
              if (version == 10) ...{'gradientX': .25, 'gradientZ': -.125},
              'footprints': [points],
            },
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
    'formatVersion': version,
    'records': [
      {
        'id': 'reusable-cliff',
        'draft': {'baseRevision': 1, 'definition': definition()},
        'latestPublished': {'revision': 1, 'definition': definition()},
      },
    ],
    'visualSnapshots': <Object?>[],
  };
}
