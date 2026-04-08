import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('legacy collision profile compat', () {
    test(
        'migrates broken manual house profile from full padding base to authored silhouette',
        () {
      final migrated = migrateProjectManifestJson(_legacyBrokenProjectJson());
      final manifest = ProjectManifest.fromJson(migrated);
      final profile = manifest.elements.single.collisionProfile!;

      expect(profile.source, ElementCollisionProfileSource.manual);
      expect(profile.shapeCells, _houseShapeCells);
      expect(profile.manualAddedCells, isEmpty);
      expect(profile.manualRemovedCells, isEmpty);
      expect(profile.cells, _houseShapeCells);
      expect(profile.cells.length, 14);
    });

    test('unknown legacy keys do not prevent manifest parsing', () {
      final raw = _legacyBrokenProjectJson();
      (((raw['elements'] as List).single
              as Map<String, dynamic>)['collisionProfile']
          as Map<String, dynamic>)['pixelMask'] = <int>[1, 0, 1];
      final migrated = migrateProjectManifestJson(raw);
      final manifest = ProjectManifest.fromJson(migrated);

      expect(manifest.elements.single.collisionProfile, isNotNull);
      expect(
          manifest.elements.single.collisionProfile!.cells, _houseShapeCells);
    });
  });
}

Map<String, dynamic> _legacyBrokenProjectJson() {
  return <String, dynamic>{
    'name': 'Legacy',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[
      <String, dynamic>{
        'id': 'house',
        'name': 'house',
        'relativePath': 'tilesets/house.png',
      },
    ],
    'elementCategories': <dynamic>[
      <String, dynamic>{'id': 'building', 'name': 'building'},
    ],
    'settings': <String, dynamic>{
      'tileWidth': 16,
      'tileHeight': 16,
    },
    'elements': <dynamic>[
      <String, dynamic>{
        'id': 'petite_maison_toit_bleu',
        'name': 'petite maison toit bleu',
        'tilesetId': 'house',
        'categoryId': 'building',
        'frames': <dynamic>[
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 341,
              'width': 6,
              'height': 7,
            },
          },
        ],
        'presetKind': 'building',
        'collisionProfile': <String, dynamic>{
          'source': 'manual',
          'padding': const <String, dynamic>{
            'top': 0,
            'right': 0,
            'bottom': 0,
            'left': 0,
          },
          'shapeCells': <dynamic>[],
          'cells': <dynamic>[
            for (var y = 0; y < 7; y++)
              for (var x = 0; x < 6; x++) <String, dynamic>{'x': x, 'y': y},
          ],
          'manualAddedCells': _houseShapeCells
              .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
              .toList(growable: false),
          'manualRemovedCells': <dynamic>[],
        },
      },
    ],
  };
}

const List<GridPos> _houseShapeCells = <GridPos>[
  GridPos(x: 0, y: 3),
  GridPos(x: 1, y: 3),
  GridPos(x: 2, y: 3),
  GridPos(x: 3, y: 3),
  GridPos(x: 4, y: 3),
  GridPos(x: 5, y: 3),
  GridPos(x: 1, y: 4),
  GridPos(x: 2, y: 4),
  GridPos(x: 3, y: 4),
  GridPos(x: 4, y: 4),
  GridPos(x: 1, y: 5),
  GridPos(x: 2, y: 5),
  GridPos(x: 3, y: 5),
  GridPos(x: 4, y: 5),
];
