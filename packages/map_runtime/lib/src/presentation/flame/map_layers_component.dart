import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../application/runtime_character_refs.dart';
import '../../application/runtime_manifest_tilesets.dart';
import '../../application/runtime_map_bundle.dart';
import 'runtime_path_autotile.dart';

const int _kEntityFrameDurationFallbackMs = 200;

class MapLayersComponent extends PositionComponent {
  MapLayersComponent({
    required this.bundle,
    required this.tileImagesByTilesetId,
  })  : _terrainPresetsByType = runtimeTerrainPresetsByType(bundle.manifest),
        _pathAutotileByPresetId = {
          for (final p in bundle.manifest.pathPresets)
            p.id: RuntimePathAutotileSet.fromPreset(p),
        },
        super(
          anchor: Anchor.topLeft,
          position: Vector2.zero(),
          size: Vector2(
            bundle.map.size.width * bundle.cellWidth,
            bundle.map.size.height * bundle.cellHeight,
          ),
        );

  final RuntimeMapBundle bundle;
  final Map<String, ui.Image> tileImagesByTilesetId;
  final Map<TerrainType, ProjectTerrainPreset> _terrainPresetsByType;
  final Map<String, RuntimePathAutotileSet> _pathAutotileByPresetId;

  late final Map<String, ProjectElementEntry> _elementById = {
    for (final e in bundle.manifest.elements) e.id: e,
  };

  double _animElapsed = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _animElapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final visible = bundle.map.layers.where((l) => l.isVisible).toList();
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        terrain: (id, name, v, o, terrains) =>
            _paintTerrainLayer(canvas, terrains, o),
      );
    }
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        path: (id, name, v, o, presetId, cells, properties) =>
            _paintPathLayer(canvas, presetId, cells, o),
      );
    }
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        tile: (id, name, tilesetId, v, o, tiles) =>
            _paintTileLayer(canvas, tilesetId, tiles, o),
      );
    }
    _paintEntities(canvas);
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        collision: (id, name, v, o, collisions) =>
            _paintCollisionLayer(canvas, collisions, o),
      );
    }
  }

  void _paintEntities(Canvas canvas) {
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final elapsedMs = (_animElapsed * 1000).toInt();
    for (final entity in bundle.map.entities) {
      if (entity.kind == MapEntityKind.npc) {
        final charId = resolveNpcCharacterId(entity, bundle.manifest);
        if (charId != null && charId.isNotEmpty) continue;
      }
      final elementId = entity.resolvedProjectElementIdForEditor?.trim();
      if (elementId == null || elementId.isEmpty) continue;
      final entry = _elementById[elementId];
      if (entry == null || entry.frames.isEmpty) continue;
      final frame = _pickEntityFrame(entry.frames, elapsedMs);
      final tilesetId = frame.tilesetId.trim().isNotEmpty
          ? frame.tilesetId.trim()
          : entry.tilesetId.trim();
      if (tilesetId.isEmpty) continue;
      final image = tileImagesByTilesetId[tilesetId];
      if (image == null) continue;
      final src = frame.source;
      final srcW = (src.width <= 0 ? 1 : src.width) * tw;
      final srcH = (src.height <= 0 ? 1 : src.height) * th;
      final srcRect = Rect.fromLTWH(
        (src.x * tw).toDouble(),
        (src.y * th).toDouble(),
        srcW.toDouble(),
        srcH.toDouble(),
      );
      if (srcRect.right > image.width || srcRect.bottom > image.height) {
        continue;
      }
      final bounds = Rect.fromLTWH(
        entity.pos.x * cw,
        entity.pos.y * ch,
        entity.size.width * cw,
        entity.size.height * ch,
      );
      _paintEntityFrame(canvas, image, srcRect, bounds);
    }
  }

  void _paintEntityFrame(
    Canvas canvas,
    ui.Image image,
    Rect src,
    Rect bounds,
  ) {
    if (src.width <= 0 || src.height <= 0) return;
    final srcAr = src.width / src.height;
    final bAr = bounds.width / bounds.height;
    final Rect dst;
    if (srcAr > bAr) {
      final w = bounds.width;
      final h = w / srcAr;
      dst = Rect.fromCenter(center: bounds.center, width: w, height: h);
    } else {
      final h = bounds.height;
      final w = h * srcAr;
      dst = Rect.fromCenter(center: bounds.center, width: w, height: h);
    }
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  TilesetVisualFrame _pickEntityFrame(
    List<TilesetVisualFrame> frames,
    int elapsedMs,
  ) {
    if (frames.length == 1) return frames.first;
    var total = 0;
    for (final f in frames) {
      final d = f.durationMs;
      total += (d == null || d <= 0) ? _kEntityFrameDurationFallbackMs : d;
    }
    if (total <= 0) return frames.first;
    var t = elapsedMs % total;
    for (final f in frames) {
      final d = f.durationMs;
      final dur = (d == null || d <= 0) ? _kEntityFrameDurationFallbackMs : d;
      if (t < dur) return f;
      t -= dur;
    }
    return frames.last;
  }

  void _paintTileLayer(
    Canvas canvas,
    String? tilesetId,
    List<int> tiles,
    double opacity,
  ) {
    final map = bundle.map;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final w = map.size.width;
    final h = map.size.height;
    final resolvedId = _resolveTilesetId(map, tilesetId);
    if (resolvedId == null) {
      return;
    }
    final image = tileImagesByTilesetId[resolvedId];
    if (image == null || tw <= 0 || th <= 0) {
      return;
    }
    final cols = image.width ~/ tw;
    if (cols <= 0) {
      return;
    }
    final paint = Paint()..isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    if (opacity < 1) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity);
    }
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        if (idx >= tiles.length) {
          continue;
        }
        final tileId = tiles[idx];
        if (tileId <= 0) {
          continue;
        }
        final sourceIndex = tileId - 1;
        final col = sourceIndex % cols;
        final row = sourceIndex ~/ cols;
        final sx = col * tw;
        final sy = row * th;
        if (sx + tw > image.width || sy + th > image.height) {
          continue;
        }
        final src = Rect.fromLTWH(
          sx.toDouble(),
          sy.toDouble(),
          tw.toDouble(),
          th.toDouble(),
        );
        final dst = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        canvas.drawImageRect(image, src, dst, paint);
      }
    }
  }

  void _paintCollisionLayer(
    Canvas canvas,
    List<bool> collisions,
    double opacity,
  ) {
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final w = bundle.map.size.width;
    final h = bundle.map.size.height;
    final paint = Paint()..color = Color.fromRGBO(255, 0, 0, 0.28 * opacity);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        if (idx >= collisions.length || !collisions[idx]) {
          continue;
        }
        canvas.drawRect(Rect.fromLTWH(x * cw, y * ch, cw, ch), paint);
      }
    }
  }

  void _paintTerrainLayer(
    Canvas canvas,
    List<TerrainType> terrains,
    double opacity,
  ) {
    final map = bundle.map;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final w = map.size.width;
    final h = map.size.height;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        if (idx >= terrains.length) {
          continue;
        }
        final terrain = terrains[idx];
        if (terrain == TerrainType.none) {
          continue;
        }
        final cell = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        final drawn = _paintTerrainPresetCell(
          canvas,
          terrain,
          x: x,
          y: y,
          tw: tw,
          th: th,
          cell: cell,
          alpha: opacity,
        );
        if (drawn) {
          continue;
        }
        final fillColor = _terrainFillColor(terrain);
        final borderColor = _terrainBorderColor(terrain);
        canvas.drawRect(
          cell,
          Paint()
            ..color = fillColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  bool _paintTerrainPresetCell(
    Canvas canvas,
    TerrainType terrain, {
    required int x,
    required int y,
    required int tw,
    required int th,
    required Rect cell,
    required double alpha,
  }) {
    final preset = _terrainPresetsByType[terrain];
    if (preset == null || preset.variants.isEmpty) {
      return false;
    }
    final tilesetId = preset.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tileImagesByTilesetId[tilesetId];
    if (tilesetImage == null || tw <= 0 || th <= 0) {
      return false;
    }
    final sourceTile = _resolveTerrainPresetSourceTile(
      preset: preset,
      x: x,
      y: y,
    );
    if (sourceTile == null) {
      return false;
    }
    final sourceX = sourceTile.dx * tw;
    final sourceY = sourceTile.dy * th;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceX + tw > tilesetImage.width ||
        sourceY + th > tilesetImage.height) {
      return false;
    }
    final srcRect = Rect.fromLTWH(
      sourceX,
      sourceY,
      tw.toDouble(),
      th.toDouble(),
    );
    canvas.drawImageRect(
      tilesetImage,
      srcRect,
      cell,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }

  Offset? _resolveTerrainPresetSourceTile({
    required ProjectTerrainPreset preset,
    required int x,
    required int y,
  }) {
    final variants = preset.variants;
    if (variants.isEmpty) {
      return null;
    }
    var totalWeight = 0;
    for (final variant in variants) {
      totalWeight += variant.weight <= 0 ? 1 : variant.weight;
    }
    if (totalWeight <= 0) {
      return null;
    }
    final seed = _stableCellSeed(x: x, y: y, salt: preset.id.hashCode);
    var selectedWeight = seed % totalWeight;
    TerrainPresetVariant chosen = variants.first;
    for (final variant in variants) {
      final weight = variant.weight <= 0 ? 1 : variant.weight;
      if (selectedWeight < weight) {
        chosen = variant;
        break;
      }
      selectedWeight -= weight;
    }
    final primary = chosen.frames.primarySource;
    final width = primary.width <= 0 ? 1 : primary.width;
    final height = primary.height <= 0 ? 1 : primary.height;
    final cellSeed = _stableCellSeed(
      x: x,
      y: y,
      salt: primary.x * 73856093 + primary.y * 19349663,
    );
    final tileIndex = cellSeed % (width * height);
    final offsetX = tileIndex % width;
    final offsetY = tileIndex ~/ width;
    return Offset(
      (primary.x + offsetX).toDouble(),
      (primary.y + offsetY).toDouble(),
    );
  }

  int _stableCellSeed({
    required int x,
    required int y,
    required int salt,
  }) {
    final raw = ((x + 1) * 73856093) ^ ((y + 1) * 19349663) ^ salt;
    return raw & 0x7fffffff;
  }

  void _paintPathLayer(
    Canvas canvas,
    String presetId,
    List<bool> cells,
    double opacity,
  ) {
    final map = bundle.map;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final w = map.size.width;
    final h = map.size.height;
    final pid = presetId.trim();
    final autotileSet = pid.isEmpty ? null : _pathAutotileByPresetId[pid];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        if (idx >= cells.length || !cells[idx]) {
          continue;
        }
        final cell = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        final drawn = autotileSet != null &&
            _paintPathLayerCell(
              canvas,
              autotileSet: autotileSet,
              cells: cells,
              x: x,
              y: y,
              tw: tw,
              th: th,
              cell: cell,
              alpha: opacity,
            );
        if (drawn) {
          continue;
        }
        canvas.drawRect(
          cell,
          Paint()
            ..color = Colors.teal
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = Colors.tealAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  bool _paintPathLayerCell(
    Canvas canvas, {
    required RuntimePathAutotileSet autotileSet,
    required List<bool> cells,
    required int x,
    required int y,
    required int tw,
    required int th,
    required Rect cell,
    required double alpha,
  }) {
    final tilesetId = autotileSet.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tileImagesByTilesetId[tilesetId];
    if (tilesetImage == null || tw <= 0 || th <= 0) {
      return false;
    }
    final variant = resolvePathVariantAt(
      cells: cells,
      mapSize: bundle.map.size,
      pos: GridPos(x: x, y: y),
    );
    return _paintAutotileVariantCell(
      canvas,
      autotileSet: autotileSet,
      tilesetImage: tilesetImage,
      variant: variant,
      tw: tw,
      th: th,
      dstRect: cell,
      alpha: alpha,
    );
  }

  bool _paintAutotileVariantCell(
    Canvas canvas, {
    required RuntimePathAutotileSet autotileSet,
    required ui.Image tilesetImage,
    required TerrainPathVariant variant,
    required int tw,
    required int th,
    required Rect dstRect,
    required double alpha,
  }) {
    final source = autotileSet.sourceForVariant(variant);
    if (source == null) {
      return false;
    }
    final sourceX = source.x * tw;
    final sourceY = source.y * th;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceX + tw > tilesetImage.width ||
        sourceY + th > tilesetImage.height) {
      return false;
    }
    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      tw.toDouble(),
      th.toDouble(),
    );
    canvas.drawImageRect(
      tilesetImage,
      srcRect,
      dstRect,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }
}

String? _resolveTilesetId(MapData map, String? layerTilesetId) {
  final fromLayer = layerTilesetId?.trim() ?? '';
  if (fromLayer.isNotEmpty) {
    return fromLayer;
  }
  final fallback = map.tilesetId.trim();
  return fallback.isNotEmpty ? fallback : null;
}

Color _terrainFillColor(TerrainType terrain) {
  return switch (terrain) {
    TerrainType.none => Colors.transparent,
    TerrainType.grass => Colors.lightGreenAccent,
    TerrainType.dirt => const Color(0xFFA46E3D),
    TerrainType.sand => Colors.amberAccent,
    TerrainType.rock => Colors.blueGrey,
    TerrainType.stone => Colors.grey,
    TerrainType.indoor => const Color(0xFFD8C3A5),
  };
}

Color _terrainBorderColor(TerrainType terrain) {
  return switch (terrain) {
    TerrainType.grass => Colors.green.shade900,
    TerrainType.dirt => const Color(0xFF6D4524),
    TerrainType.sand => Colors.orange.shade900,
    TerrainType.rock => Colors.blueGrey.shade900,
    TerrainType.stone => Colors.grey.shade800,
    TerrainType.indoor => const Color(0xFF8D6E63),
    TerrainType.none => Colors.transparent,
  };
}
