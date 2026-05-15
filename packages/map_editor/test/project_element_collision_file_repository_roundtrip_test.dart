import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FileProjectRepository collision roundtrip', () {
    test('load currently preserves legacy cells before Collision-4 normalizer',
        () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_repo_roundtrip_current_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final manifestPath = p.join(tempDir.path, 'project.json');
      final file = File(manifestPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_legacyBrokenProjectJson()),
      );

      final repo = FileProjectRepository();
      final loaded = await repo.loadProject(manifestPath);
      final loadedProfile = loaded.elements.single.collisionProfile!;

      expect(loadedProfile.cells, _legacyFullCells());
      expect(loadedProfile.shapeCells, isEmpty);
      expect(loadedProfile.manualAddedCells, _houseShapeCells);
      expect(loadedProfile.manualRemovedCells, isEmpty);
    });

    test(
        'future normalizer contract migrates broken manual profile and save persists corrected cells',
        () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_repo_roundtrip_future_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final manifestPath = p.join(tempDir.path, 'project.json');
      final file = File(manifestPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_legacyBrokenProjectJson()),
      );

      final repo = FileProjectRepository();
      final loaded = await repo.loadProject(manifestPath);
      final loadedProfile = loaded.elements.single.collisionProfile!;

      expect(loadedProfile.cells, _houseShapeCells);
      expect(loadedProfile.shapeCells, _houseShapeCells);

      await repo.saveProject(loaded, manifestPath);

      final rawSaved =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedProfile = (((rawSaved['elements'] as List).single
          as Map<String, dynamic>)['collisionProfile'] as Map<String, dynamic>);

      expect((savedProfile['cells'] as List).length, _houseShapeCells.length);
      expect(
          (savedProfile['shapeCells'] as List).length, _houseShapeCells.length);
      expect(savedProfile['manualAddedCells'], isEmpty);
      expect(savedProfile['manualRemovedCells'], isEmpty);

      final reloaded = await repo.loadProject(manifestPath);
      expect(
          reloaded.elements.single.collisionProfile!.cells, _houseShapeCells);
    },
        skip:
            'Pending Collision-4/Collision-6: legacy collision profile normalizer is not implemented or wired into FileProjectRepository yet.');
  });
}

List<GridPos> _legacyFullCells() {
  return <GridPos>[
    for (var y = 0; y < 7; y++)
      for (var x = 0; x < 6; x++) GridPos(x: x, y: y),
  ];
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
