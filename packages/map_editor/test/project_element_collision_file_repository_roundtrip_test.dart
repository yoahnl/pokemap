import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FileProjectRepository collision roundtrip', () {
    test('load normalizes legacy cells after Collision-6 normalizer in memory',
        () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_repo_roundtrip_legacy_load_',
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
      final beforeLoad = await file.readAsString();

      final repo = FileProjectRepository();
      final loaded = await repo.loadProject(manifestPath);
      final loadedProfile = loaded.elements.single.collisionProfile!;
      final afterLoad = await file.readAsString();

      expect(loadedProfile.cells, _houseShapeCells);
      expect(loadedProfile.shapeCells, isEmpty);
      expect(loadedProfile.manualAddedCells, _houseShapeCells);
      expect(loadedProfile.manualRemovedCells, isEmpty);
      expect(afterLoad, beforeLoad);
    });

    test(
        'normalizer contract migrates broken manual profile and save persists '
        'corrected cells', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_repo_roundtrip_legacy_save_',
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
      expect(loadedProfile.shapeCells, isEmpty);
      expect(loadedProfile.manualAddedCells, _houseShapeCells);
      expect(loadedProfile.manualRemovedCells, isEmpty);

      await repo.saveProject(loaded, manifestPath);

      final rawSaved =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedProfile = (((rawSaved['elements'] as List).single
          as Map<String, dynamic>)['collisionProfile'] as Map<String, dynamic>);

      expect(savedProfile['cells'], _houseShapeCellsJson());
      expect(savedProfile['shapeCells'], isEmpty);
      expect(savedProfile['manualAddedCells'], _houseShapeCellsJson());
      expect(savedProfile['manualRemovedCells'], isEmpty);

      final reloaded = await repo.loadProject(manifestPath);
      expect(
          reloaded.elements.single.collisionProfile!.cells, _houseShapeCells);
    });

    test(
        'load projects collisionMask into cells using project settings tile size',
        () async {
      final collisionMask = _maskJson(
        widthPx: 16,
        heightPx: 16,
        solidPoints: const [GridPos(x: 8, y: 0)],
      );
      final visualMask = _maskJson(
        widthPx: 4,
        heightPx: 4,
        solidPoints: const [GridPos(x: 0, y: 0)],
      );
      final occlusionMask = _maskJson(
        widthPx: 2,
        heightPx: 2,
        solidPoints: const [GridPos(x: 1, y: 1)],
      );
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_repo_roundtrip_mask_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final manifestPath = p.join(tempDir.path, 'project.json');
      final file = File(manifestPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(
          _projectJson(
            tileWidth: 8,
            tileHeight: 8,
            collisionProfile: <String, dynamic>{
              'source': 'manual',
              'pixelMask': collisionMask,
              'visualMask': visualMask,
              'occlusionMask': occlusionMask,
              'cells': <dynamic>[
                <String, dynamic>{'x': 0, 'y': 0},
              ],
              'shapeCells': <dynamic>[],
              'manualAddedCells': <dynamic>[],
              'manualRemovedCells': <dynamic>[],
            },
          ),
        ),
      );

      final repo = FileProjectRepository();
      final loaded = await repo.loadProject(manifestPath);
      final loadedProfile = loaded.elements.single.collisionProfile!;

      expect(loadedProfile.cells, const [GridPos(x: 1, y: 0)]);
      expect(loadedProfile.collisionMask, isNotNull);
      expect(
          loadedProfile.collisionMask!.dataBase64, collisionMask['dataBase64']);
      expect(loadedProfile.visualMask, isNotNull);
      expect(loadedProfile.visualMask!.dataBase64, visualMask['dataBase64']);
      expect(loadedProfile.occlusionMask, isNotNull);
      expect(
          loadedProfile.occlusionMask!.dataBase64, occlusionMask['dataBase64']);
    });

    test('load leaves elements without collisionProfile unchanged', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_repo_roundtrip_no_profile_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final manifestPath = p.join(tempDir.path, 'project.json');
      final file = File(manifestPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(
          _projectJson(collisionProfile: null),
        ),
      );

      final repo = FileProjectRepository();
      final loaded = await repo.loadProject(manifestPath);

      expect(loaded.elements.single.collisionProfile, isNull);
      expect(loaded.elements.single.id, 'petite_maison_toit_bleu');
      expect(loaded.settings.tileWidth, 16);
    });
  });
}

Map<String, dynamic> _legacyBrokenProjectJson() {
  return _projectJson(collisionProfile: _legacyBrokenCollisionProfileJson());
}

Map<String, dynamic> _projectJson({
  required Map<String, dynamic>? collisionProfile,
  int tileWidth = 16,
  int tileHeight = 16,
}) {
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
      'tileWidth': tileWidth,
      'tileHeight': tileHeight,
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
        if (collisionProfile != null) 'collisionProfile': collisionProfile,
      },
    ],
  };
}

Map<String, dynamic> _legacyBrokenCollisionProfileJson() {
  return <String, dynamic>{
    'source': 'manual',
    'padding': const <String, dynamic>{
      'top': 0,
      'right': 0,
      'bottom': 0,
      'left': 0,
    },
    'shapeCells': <dynamic>[],
    'cells': _legacyFullCellsJson(),
    'manualAddedCells': _houseShapeCellsJson(),
    'manualRemovedCells': <dynamic>[],
  };
}

List<Map<String, dynamic>> _legacyFullCellsJson() {
  return <Map<String, dynamic>>[
    for (var y = 0; y < 7; y++)
      for (var x = 0; x < 6; x++) <String, dynamic>{'x': x, 'y': y},
  ];
}

List<Map<String, dynamic>> _houseShapeCellsJson() {
  return _houseShapeCells
      .map((cell) => <String, dynamic>{'x': cell.x, 'y': cell.y})
      .toList(growable: false);
}

Map<String, dynamic> _maskJson({
  required int widthPx,
  required int heightPx,
  required List<GridPos> solidPoints,
}) {
  final pixels = List<bool>.filled(widthPx * heightPx, false);
  for (final point in solidPoints) {
    pixels[point.y * widthPx + point.x] = true;
  }
  return <String, dynamic>{
    'widthPx': widthPx,
    'heightPx': heightPx,
    'encoding': 'packed_bits_v1',
    'dataBase64': ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: pixels,
    ),
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
