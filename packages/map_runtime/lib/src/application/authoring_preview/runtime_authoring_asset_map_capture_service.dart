import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';
import '../../presentation/flame/map_layers_component.dart';
import '../../shadow/runtime_static_placed_element_shadow_sources.dart';
import '../runtime_map_bundle.dart';

final class RuntimeAuthoringAssetMapCaptureResult {
  RuntimeAuthoringAssetMapCaptureResult({
    required this.bytes,
    required this.width,
    required this.height,
    required Map<MapRenderOverlay, int> overlayCounts,
  }) : overlayCounts = Map.unmodifiable(overlayCounts);

  final Uint8List bytes;
  final int width;
  final int height;
  final Map<MapRenderOverlay, int> overlayCounts;
}

final class RuntimeAuthoringAssetMapCaptureService {
  const RuntimeAuthoringAssetMapCaptureService();

  Future<RuntimeAuthoringAssetMapCaptureResult> capture({
    required RuntimeMapBundle bundle,
    required Map<String, RuntimeTilesetImage> tileImagesByTilesetId,
    required MapRect region,
    required Iterable<String> layerIds,
    required Iterable<MapRenderOverlay> overlays,
    required int cellPixelSize,
  }) async {
    if (cellPixelSize <= 0) {
      throw ArgumentError.value(
        cellPixelSize,
        'cellPixelSize',
        'must be positive',
      );
    }
    _validateRegion(bundle.map, region);
    final selectedBundle = _selectLayers(bundle, layerIds);
    final background = MapLayersComponent(
      bundle: selectedBundle,
      tileImagesByTilesetId: tileImagesByTilesetId,
      shadowCollectionProvider: () =>
          buildRuntimeStaticPlacedElementShadowCollectionForBundle(
        bundle: selectedBundle,
      ),
    );
    final foreground = MapLayersComponent(
      bundle: selectedBundle,
      tileImagesByTilesetId: tileImagesByTilesetId,
      renderPass: MapLayerRenderPass.foreground,
    );
    background.update(0);
    foreground.update(0);

    final width = region.size.width * cellPixelSize;
    final height = region.size.height * cellPixelSize;
    final scale = cellPixelSize / selectedBundle.cellWidth;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.save();
    canvas.scale(scale, scale);
    canvas.translate(
      -region.pos.x * selectedBundle.cellWidth,
      -region.pos.y * selectedBundle.cellHeight,
    );
    background.render(canvas);
    foreground.render(canvas);
    final overlayCounts = _paintOverlays(
      canvas,
      bundle,
      region,
      overlays.toSet(),
      scale,
      cellPixelSize,
    );
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('Could not encode the runtime map capture as PNG.');
      }
      return RuntimeAuthoringAssetMapCaptureResult(
        bytes: data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        ),
        width: width,
        height: height,
        overlayCounts: overlayCounts,
      );
    } finally {
      image.dispose();
    }
  }
}

void _validateRegion(MapData map, MapRect region) {
  if (region.pos.x < 0 ||
      region.pos.y < 0 ||
      region.size.width <= 0 ||
      region.size.height <= 0 ||
      region.pos.x + region.size.width > map.size.width ||
      region.pos.y + region.size.height > map.size.height) {
    throw ArgumentError.value(region, 'region', 'must fit inside the map');
  }
}

RuntimeMapBundle _selectLayers(
  RuntimeMapBundle bundle,
  Iterable<String> layerIds,
) {
  final selected = layerIds.toSet();
  final layers = bundle.map.layers
      .where(
        (layer) =>
            selected.isEmpty ? layer.isVisible : selected.contains(layer.id),
      )
      .map(_visibleLayer)
      .toList(growable: false);
  return RuntimeMapBundle(
    manifest: bundle.manifest,
    map: bundle.map.copyWith(layers: layers),
    projectRootDirectory: bundle.projectRootDirectory,
    tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    characterAnimationAbsolutePathsByAssetId:
        bundle.characterAnimationAbsolutePathsByAssetId,
    borderRuntimePreparation: bundle.borderRuntimePreparation,
  );
}

MapLayer _visibleLayer(MapLayer layer) => switch (layer) {
      TileLayer value => value.copyWith(isVisible: true),
      CollisionLayer value => value.copyWith(isVisible: true),
      SmartTileLayer value => value.copyWith(isVisible: true),
      ObjectLayer value => value.copyWith(isVisible: true),
      EnvironmentLayer value => value.copyWith(isVisible: true),
      BorderLayer value => value.copyWith(isVisible: true),
    };

Map<MapRenderOverlay, int> _paintOverlays(
  ui.Canvas canvas,
  RuntimeMapBundle bundle,
  MapRect region,
  Set<MapRenderOverlay> overlays,
  double scale,
  int cellPixelSize,
) {
  final counts = <MapRenderOverlay, int>{};
  for (final overlay in overlays) {
    counts[overlay] = switch (overlay) {
      MapRenderOverlay.collision => _paintCollision(
          canvas,
          bundle,
          region,
          scale,
          cellPixelSize,
        ),
      MapRenderOverlay.zones => _paintZones(
          canvas,
          bundle,
          region,
          scale,
          cellPixelSize,
        ),
      MapRenderOverlay.warps => _paintWarps(
          canvas,
          bundle,
          region,
          scale,
          cellPixelSize,
        ),
      MapRenderOverlay.entities => _paintEntities(
          canvas,
          bundle,
          region,
          scale,
          cellPixelSize,
        ),
    };
  }
  return counts;
}

int _paintCollision(
  ui.Canvas canvas,
  RuntimeMapBundle bundle,
  MapRect region,
  double scale,
  int cellPixelSize,
) {
  final collision = const EffectiveCollisionInspector().queryRegion(
    manifest: bundle.manifest,
    map: bundle.map,
    x: region.pos.x,
    y: region.pos.y,
    width: region.size.width,
    height: region.size.height,
  );
  var count = 0;
  for (final cell in collision.cells) {
    if (!cell.isBlocked) continue;
    count++;
    _paintCell(
      canvas,
      bundle,
      cell.pos.x,
      cell.pos.y,
      const ui.Color(0xDCE13844),
      scale,
      cellPixelSize,
    );
  }
  return count;
}

int _paintZones(
  ui.Canvas canvas,
  RuntimeMapBundle bundle,
  MapRect region,
  double scale,
  int cellPixelSize,
) {
  var count = 0;
  for (final zone in bundle.map.gameplayZones) {
    if (!_rectsIntersect(zone.area, region)) continue;
    count++;
    final left =
        zone.area.pos.x.clamp(region.pos.x, region.pos.x + region.size.width);
    final top =
        zone.area.pos.y.clamp(region.pos.y, region.pos.y + region.size.height);
    final right = (zone.area.pos.x + zone.area.size.width)
        .clamp(region.pos.x, region.pos.x + region.size.width);
    final bottom = (zone.area.pos.y + zone.area.size.height)
        .clamp(region.pos.y, region.pos.y + region.size.height);
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        _paintCell(
          canvas,
          bundle,
          x,
          y,
          const ui.Color(0xD2F4B530),
          scale,
          cellPixelSize,
        );
      }
    }
  }
  return count;
}

int _paintWarps(
  ui.Canvas canvas,
  RuntimeMapBundle bundle,
  MapRect region,
  double scale,
  int cellPixelSize,
) {
  var count = 0;
  for (final warp in bundle.map.warps) {
    if (!_contains(region, warp.pos)) continue;
    count++;
    _paintCell(
      canvas,
      bundle,
      warp.pos.x,
      warp.pos.y,
      const ui.Color(0xF5CC46D6),
      scale,
      cellPixelSize,
    );
  }
  return count;
}

int _paintEntities(
  ui.Canvas canvas,
  RuntimeMapBundle bundle,
  MapRect region,
  double scale,
  int cellPixelSize,
) {
  var count = 0;
  for (final entity in bundle.map.entities) {
    final area = MapRect(pos: entity.pos, size: entity.size);
    if (!_rectsIntersect(area, region)) continue;
    count++;
    for (var y = entity.pos.y; y < entity.pos.y + entity.size.height; y++) {
      for (var x = entity.pos.x; x < entity.pos.x + entity.size.width; x++) {
        if (!_contains(region, GridPos(x: x, y: y))) continue;
        _paintCell(
          canvas,
          bundle,
          x,
          y,
          const ui.Color(0xF52CC4D6),
          scale,
          cellPixelSize,
        );
      }
    }
  }
  return count;
}

void _paintCell(
  ui.Canvas canvas,
  RuntimeMapBundle bundle,
  int x,
  int y,
  ui.Color color,
  double scale,
  int cellPixelSize,
) {
  final inset = cellPixelSize >= 4 ? 1 / scale : 0.0;
  canvas.drawRect(
    ui.Rect.fromLTRB(
      x * bundle.cellWidth + inset,
      y * bundle.cellHeight + inset,
      (x + 1) * bundle.cellWidth - inset,
      (y + 1) * bundle.cellHeight - inset,
    ),
    ui.Paint()..color = color,
  );
}

bool _contains(MapRect rect, GridPos pos) =>
    pos.x >= rect.pos.x &&
    pos.y >= rect.pos.y &&
    pos.x < rect.pos.x + rect.size.width &&
    pos.y < rect.pos.y + rect.size.height;

bool _rectsIntersect(MapRect left, MapRect right) =>
    left.pos.x < right.pos.x + right.size.width &&
    right.pos.x < left.pos.x + left.size.width &&
    left.pos.y < right.pos.y + right.size.height &&
    right.pos.y < left.pos.y + left.size.height;
