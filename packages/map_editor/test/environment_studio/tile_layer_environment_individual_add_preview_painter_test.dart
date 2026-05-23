import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/application/services/environment_generated_placement_hover_resolver.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  group('TileLayer generated placement add ghost painter', () {
    test('MapGridPainter ne lève pas avec ghost preview valide', () async {
      final preview = _preview(isValid: true);

      await _paint(preview, images: {'nature': await _tilesetImage()});
    });

    test('MapGridPainter ne lève pas avec ghost preview invalide', () async {
      final preview = _preview(isValid: false);

      await _paint(preview, images: {'nature': await _tilesetImage()});
    });

    test('MapGridPainter ne lève pas si image tileset absente', () async {
      final preview = _preview(isValid: true);

      await _paint(preview, images: const <String, ui.Image?>{});
    });

    test('shouldRepaint change quand le ghost preview change', () {
      final first = _painter(_preview(pos: const GridPos(x: 0, y: 0)));
      final second = _painter(_preview(pos: const GridPos(x: 1, y: 0)));

      expect(second.shouldRepaint(first), isTrue);
    });

    test('overlay null ne lève pas', () async {
      await _paint(null, images: const <String, ui.Image?>{});
    });
  });
}

Future<void> _paint(
  EnvironmentGeneratedPlacementAddPreview? preview, {
  required Map<String, ui.Image?> images,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  _painter(preview, images: images).paint(canvas, const ui.Size(128, 128));
  final picture = recorder.endRecording();
  final image = await picture.toImage(128, 128);
  picture.dispose();
  image.dispose();
  for (final image in images.values) {
    image?.dispose();
  }
}

MapGridPainter _painter(
  EnvironmentGeneratedPlacementAddPreview? preview, {
  Map<String, ui.Image?> images = const <String, ui.Image?>{},
}) {
  return MapGridPainter(
    map: _map(),
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 32,
    tileHeight: 32,
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesetImagesById: images,
    tilesPerRowById: const {'nature': 4},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    project: _manifest(),
    environmentGeneratedAddPreview: preview,
  );
}

EnvironmentGeneratedPlacementAddPreview _preview({
  GridPos pos = const GridPos(x: 1, y: 1),
  bool isValid = true,
}) {
  return EnvironmentGeneratedPlacementAddPreview(
    placed: MapPlacedElement(
      id: 'preview',
      layerId: 'tiles',
      elementId: 'tree',
      pos: pos,
    ),
    element: const ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'nature',
      categoryId: 'trees',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
        ),
      ],
    ),
    footprint: const GridSize(width: 2, height: 2),
    isValid: isValid,
    invalidReason: isValid ? null : 'Position hors carte',
  );
}

MapData _map() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 4, height: 4),
    tilesetId: 'nature',
    layers: [
      TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
  );
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
          ),
        ],
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

Future<ui.Image> _tilesetImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 64, 64),
    ui.Paint()..color = const ui.Color(0xFF2FAF66),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(128, 128);
  picture.dispose();
  return image;
}
