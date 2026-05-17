import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  group('runtime manifest collision normalization', () {
    test('normalizes legacy element collision profiles on load', () async {
      final workspace = await Directory.systemTemp.createTemp(
        'runtime_collision_normalization_',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final projectFile = File(p.join(workspace.path, 'project.json'));
      await projectFile.writeAsString(jsonEncode(_legacyBuildingProjectJson()));

      final manifest = await loadProjectManifestFromFile(projectFile.path);
      final profile = manifest.elements.single.collisionProfile;

      expect(profile, isNotNull);
      expect(profile!.collisionMask, isNull);
      expect(profile.cells, _buildingBlockingCells);
      expect(profile.manualAddedCells, _buildingBlockingCells);
    });
  });
}

Map<String, dynamic> _legacyBuildingProjectJson() {
  return <String, dynamic>{
    'name': 'Runtime Collision Normalization',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[
      <String, dynamic>{
        'id': 'ts',
        'name': 'ts',
        'relativePath': 'ts.png',
      },
    ],
    'elementCategories': <dynamic>[
      <String, dynamic>{'id': 'cat', 'name': 'cat'},
    ],
    'settings': const <String, dynamic>{
      'tileWidth': _tileSize,
      'tileHeight': _tileSize,
    },
    'elements': <dynamic>[
      <String, dynamic>{
        'id': 'petite_maison_toit_bleu',
        'name': 'petite maison toit bleu',
        'tilesetId': 'ts',
        'categoryId': 'cat',
        'frames': const <Map<String, dynamic>>[
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 341,
              'width': _buildingWidthCells,
              'height': _buildingHeightCells,
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
          'cells': _legacyFullCellsJson(),
          'manualAddedCells': _buildingBlockingCellsJson(),
          'manualRemovedCells': <dynamic>[],
        },
      },
    ],
  };
}

List<GridPos> _legacyFullCells() {
  return [
    for (var y = 0; y < _buildingHeightCells; y++)
      for (var x = 0; x < _buildingWidthCells; x++) GridPos(x: x, y: y),
  ];
}

List<Map<String, dynamic>> _legacyFullCellsJson() {
  return _legacyFullCells()
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

List<Map<String, dynamic>> _buildingBlockingCellsJson() {
  return _buildingBlockingCells
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

const int _tileSize = 16;
const int _buildingWidthCells = 6;
const int _buildingHeightCells = 7;

const List<GridPos> _buildingBlockingCells = [
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
