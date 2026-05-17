import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/element_collision_truth_summary.dart';
import 'package:map_editor/src/application/models/player_collision_hitbox_preview.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('building collision golden slice', () {
    test('load normalizes legacy building collision profile', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_building_golden_load_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final manifestPath = p.join(tempDir.path, 'project.json');
      final file = File(manifestPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ')
            .convert(_legacyBuildingProjectJson()),
      );
      final beforeLoad = await file.readAsString();

      final loaded = await FileProjectRepository().loadProject(manifestPath);
      final profile = loaded.elements.single.collisionProfile!;
      final afterLoad = await file.readAsString();

      expect(profile.cells, _buildingBlockingCells);
      expect(profile.manualAddedCells, _buildingBlockingCells);
      expect(profile.shapeCells, isEmpty);
      expect(profile.manualRemovedCells, isEmpty);
      expect(afterLoad, beforeLoad);
    });

    test('save persists normalized building cells', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'collision_building_golden_save_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final manifestPath = p.join(tempDir.path, 'project.json');
      final file = File(manifestPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ')
            .convert(_legacyBuildingProjectJson()),
      );

      final repository = FileProjectRepository();
      final loaded = await repository.loadProject(manifestPath);
      await repository.saveProject(loaded, manifestPath);

      final savedJson =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final savedProfile = (((savedJson['elements'] as List).single
          as Map<String, dynamic>)['collisionProfile'] as Map<String, dynamic>);

      expect(savedProfile['cells'], _buildingBlockingCellsJson());
      expect(savedProfile['manualAddedCells'], _buildingBlockingCellsJson());
      expect(savedProfile['shapeCells'], isEmpty);
      expect(savedProfile['manualRemovedCells'], isEmpty);
    });

    test('truth summary shows grid collision when no fine mask exists', () {
      final profile = normalizeElementCollisionProfile(
        ElementCollisionProfile(
          source: ElementCollisionProfileSource.manual,
          cells: _legacyFullCells(),
          manualAddedCells: _buildingBlockingCells,
        ),
        tileSize: _tileSize,
      );

      final summary = summarizeElementCollisionTruth(profile);

      expect(summary.mode, ElementCollisionTruthMode.legacyCells);
      expect(summary.title, 'Collision par grille');
      expect(summary.description, contains('fallback'));
      expect(summary.hasCollisionMask, isFalse);
      expect(summary.hasLegacyCells, isTrue);
    });

    test('truth summary shows fine collision when mask exists', () {
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        collisionMask: _maskFromCells(
          solidCells: const [GridPos(x: 2, y: 5)],
        ),
        cells: _legacyFullCells(),
      );

      final summary = summarizeElementCollisionTruth(profile);

      expect(summary.mode, ElementCollisionTruthMode.fineMask);
      expect(summary.title, 'Collision fine active');
      expect(summary.description, contains('masque de collision fin'));
      expect(summary.hasCollisionMask, isTrue);
    });

    test('player hitbox preview stays aligned with gameplay conventions', () {
      final preview = buildPlayerCollisionHitboxPreview();

      expect(preview.dimensionsLabel, '12 × 8 px');
      expect(
        preview.hitboxWidthPx,
        PlayerCollisionConventionsV1.playerHitboxWidthPx,
      );
      expect(
        preview.hitboxHeightPx,
        PlayerCollisionConventionsV1.playerHitboxHeightPx,
      );
      expect(preview.hitboxLeftPx, 10);
      expect(preview.hitboxTopPx, 24);
      expect(preview.description, contains('zone aux pieds'));
      expect(preview.positionLabel, contains('centrée en bas'));
    });
  });
}

Map<String, dynamic> _legacyBuildingProjectJson() {
  return <String, dynamic>{
    'name': 'Building Golden Slice',
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
    'settings': const <String, dynamic>{
      'tileWidth': _tileSize,
      'tileHeight': _tileSize,
    },
    'elements': <dynamic>[
      <String, dynamic>{
        'id': 'petite_maison_toit_bleu',
        'name': 'petite maison toit bleu',
        'tilesetId': 'house',
        'categoryId': 'building',
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

ElementCollisionPixelMask _maskFromCells({
  required List<GridPos> solidCells,
}) {
  const widthPx = _buildingWidthCells * _tileSize;
  const heightPx = _buildingHeightCells * _tileSize;
  final pixels = List<bool>.filled(widthPx * heightPx, false);
  for (final cell in solidCells) {
    for (var y = cell.y * _tileSize; y < (cell.y + 1) * _tileSize; y++) {
      for (var x = cell.x * _tileSize; x < (cell.x + 1) * _tileSize; x++) {
        pixels[y * widthPx + x] = true;
      }
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: pixels,
    ),
  );
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
