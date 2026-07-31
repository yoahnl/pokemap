import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

/// Runtime-owned deterministic raster adapter for authoring map previews.
///
/// It deliberately renders from immutable typed data and never receives a
/// project path. Production asset-accurate screenshots can replace this
/// adapter without changing the revision-bound authoring port.
final class RuntimeAuthoringMapRenderAdapter implements MapRenderPort {
  const RuntimeAuthoringMapRenderAdapter();

  @override
  Future<MapRenderResult> render(MapRenderRequest request) async {
    final scale = request.cellPixelSize;
    final bitmap = img.Image(
      width: request.region.size.width * scale,
      height: request.region.size.height * scale,
      numChannels: 4,
    );
    _paintBackground(bitmap, request);
    final layers = _selectedLayers(request);
    for (final layer in layers) {
      _paintLayer(bitmap, request, layer);
    }
    final overlayCounts = <MapRenderOverlay, int>{};
    for (final overlay in request.overlays) {
      overlayCounts[overlay] = switch (overlay) {
        MapRenderOverlay.collision => _paintCollisionOverlay(bitmap, request),
        MapRenderOverlay.zones => _paintZoneOverlay(bitmap, request),
        MapRenderOverlay.warps => _paintWarpOverlay(bitmap, request),
        MapRenderOverlay.entities => _paintEntityOverlay(bitmap, request),
      };
    }
    return MapRenderResult(
      mimeType: 'image/png',
      bytes: img.encodePng(bitmap, level: 6),
      width: bitmap.width,
      height: bitmap.height,
      sourceRevision: request.revision,
      region: request.region,
      layerIds: [for (final layer in layers) layer.id],
      overlays: request.overlays,
      overlayCounts: overlayCounts,
    );
  }
}

List<MapLayer> _selectedLayers(MapRenderRequest request) {
  final selected = request.layerIds.toSet();
  final layers = request.map.layers.where(
    (layer) => selected.isEmpty ? layer.isVisible : selected.contains(layer.id),
  );
  return layers.toList(growable: false);
}

void _paintBackground(img.Image bitmap, MapRenderRequest request) {
  for (var y = 0; y < request.region.size.height; y++) {
    for (var x = 0; x < request.region.size.width; x++) {
      final even = (x + y).isEven;
      _paintCell(
        bitmap,
        request,
        request.region.pos.x + x,
        request.region.pos.y + y,
        even ? const (27, 32, 43, 255) : const (31, 37, 49, 255),
      );
    }
  }
}

void _paintLayer(
  img.Image bitmap,
  MapRenderRequest request,
  MapLayer layer,
) {
  for (var y = request.region.pos.y;
      y < request.region.pos.y + request.region.size.height;
      y++) {
    for (var x = request.region.pos.x;
        x < request.region.pos.x + request.region.size.width;
        x++) {
      final value = _layerCellValue(request.map, layer, x, y);
      if (value == 0) continue;
      final base = _layerColor(layer, value);
      final alpha = (base.$4 * layer.opacity.clamp(0.0, 1.0)).round();
      _paintCell(
        bitmap,
        request,
        x,
        y,
        (base.$1, base.$2, base.$3, alpha),
      );
    }
  }
}

int _layerCellValue(MapData map, MapLayer layer, int x, int y) {
  final index = y * map.size.width + x;
  return switch (layer) {
    TileLayer value => _intCell(value.tiles, index),
    CollisionLayer value => _boolCell(value.collisions, index) ? 1 : 0,
    TerrainLayer value =>
      index < value.terrains.length ? value.terrains[index].index : 0,
    PathLayer value => _boolCell(value.cells, index) ? 1 : 0,
    SurfaceLayer value => value.placements.any(
        (placement) => placement.x == x && placement.y == y,
      )
          ? 1
          : 0,
    SmartTileLayer value => _intCell(value.materialCells, index),
    ObjectLayer _ => 0,
    EnvironmentLayer _ => 0,
    BorderLayer _ => 0,
  };
}

(int, int, int, int) _layerColor(MapLayer layer, int value) {
  final int variation =
      (value.abs() * 37 + layer.id.codeUnits.fold<int>(0, (a, b) => a + b)) %
          72;
  return switch (layer) {
    TileLayer _ => (58 + variation, 100 + variation ~/ 2, 72, 230),
    CollisionLayer _ => (180, 52, 64, 120),
    TerrainLayer _ => (58, 118 + variation, 74, 170),
    PathLayer _ => (148 + variation, 112, 72, 190),
    SurfaceLayer _ => (48, 108 + variation, 154, 190),
    SmartTileLayer _ => (72, 138 + variation, 118, 200),
    ObjectLayer _ => (116, 116, 136, 160),
    EnvironmentLayer _ => (68, 136, 100, 140),
    BorderLayer _ => (128, 96, 68, 180),
  };
}

int _paintCollisionOverlay(img.Image bitmap, MapRenderRequest request) {
  final collision = const EffectiveCollisionInspector().queryRegion(
    manifest: request.manifest,
    map: request.map,
    x: request.region.pos.x,
    y: request.region.pos.y,
    width: request.region.size.width,
    height: request.region.size.height,
  );
  var count = 0;
  for (final cell in collision.cells) {
    if (!cell.isBlocked) continue;
    count++;
    _paintMarker(
      bitmap,
      request,
      cell.pos.x,
      cell.pos.y,
      const (225, 56, 68, 220),
    );
  }
  return count;
}

int _paintZoneOverlay(img.Image bitmap, MapRenderRequest request) {
  var count = 0;
  for (final zone in request.map.gameplayZones) {
    if (!_rectsIntersect(zone.area, request.region)) continue;
    count++;
    final left = zone.area.pos.x.clamp(
      request.region.pos.x,
      request.region.pos.x + request.region.size.width,
    );
    final top = zone.area.pos.y.clamp(
      request.region.pos.y,
      request.region.pos.y + request.region.size.height,
    );
    final right = (zone.area.pos.x + zone.area.size.width).clamp(
      request.region.pos.x,
      request.region.pos.x + request.region.size.width,
    );
    final bottom = (zone.area.pos.y + zone.area.size.height).clamp(
      request.region.pos.y,
      request.region.pos.y + request.region.size.height,
    );
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        _paintMarker(
          bitmap,
          request,
          x,
          y,
          const (244, 181, 48, 210),
        );
      }
    }
  }
  return count;
}

int _paintWarpOverlay(img.Image bitmap, MapRenderRequest request) {
  var count = 0;
  for (final warp in request.map.warps) {
    if (!_contains(request.region, warp.pos)) continue;
    count++;
    _paintMarker(
      bitmap,
      request,
      warp.pos.x,
      warp.pos.y,
      const (204, 70, 214, 245),
    );
  }
  return count;
}

int _paintEntityOverlay(img.Image bitmap, MapRenderRequest request) {
  var count = 0;
  for (final entity in request.map.entities) {
    final area = MapRect(pos: entity.pos, size: entity.size);
    if (!_rectsIntersect(area, request.region)) continue;
    count++;
    for (var y = entity.pos.y; y < entity.pos.y + entity.size.height; y++) {
      for (var x = entity.pos.x; x < entity.pos.x + entity.size.width; x++) {
        if (!_contains(request.region, GridPos(x: x, y: y))) continue;
        _paintMarker(
          bitmap,
          request,
          x,
          y,
          const (44, 196, 214, 245),
        );
      }
    }
  }
  return count;
}

void _paintMarker(
  img.Image bitmap,
  MapRenderRequest request,
  int mapX,
  int mapY,
  (int, int, int, int) color,
) {
  final inset = request.cellPixelSize >= 4 ? 1 : 0;
  _paintCell(
    bitmap,
    request,
    mapX,
    mapY,
    color,
    inset: inset,
  );
}

void _paintCell(
  img.Image bitmap,
  MapRenderRequest request,
  int mapX,
  int mapY,
  (int, int, int, int) color, {
  int inset = 0,
}) {
  if (!_contains(request.region, GridPos(x: mapX, y: mapY))) return;
  final left = (mapX - request.region.pos.x) * request.cellPixelSize + inset;
  final top = (mapY - request.region.pos.y) * request.cellPixelSize + inset;
  final right =
      (mapX - request.region.pos.x + 1) * request.cellPixelSize - inset;
  final bottom =
      (mapY - request.region.pos.y + 1) * request.cellPixelSize - inset;
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      _blendPixel(bitmap, x, y, color);
    }
  }
}

void _blendPixel(
  img.Image bitmap,
  int x,
  int y,
  (int, int, int, int) color,
) {
  final alpha = color.$4 / 255.0;
  final previous = bitmap.getPixel(x, y);
  final red = (color.$1 * alpha + previous.r * (1 - alpha)).round();
  final green = (color.$2 * alpha + previous.g * (1 - alpha)).round();
  final blue = (color.$3 * alpha + previous.b * (1 - alpha)).round();
  bitmap.setPixelRgba(x, y, red, green, blue, 255);
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

int _intCell(List<int> values, int index) =>
    index >= 0 && index < values.length ? values[index] : 0;

bool _boolCell(List<bool> values, int index) =>
    index >= 0 && index < values.length && values[index];
