import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';
import 'spatial_terrain_geometry.dart';

typedef SpatialGroundVisual = ({
  SmartTileLayerVisual visual,
  double height,
  double opacity,
});

final class SpatialGroundPlan {
  SpatialGroundPlan(MapData map, ProjectManifest project)
    : scene = map.spatialScene {
    final catalog = project.smartTileCatalog;
    if (scene?.cliffFrame case final frame?) {
      _addFrame(frame, catalog);
      final atlas = catalog.atlases.firstWhere((a) => a.id == frame.atlasId);
      cliff = (
        tilesetId: atlas.tilesetId,
        sourceRect: atlas.sourceRectFor(
          column: frame.column,
          row: frame.row,
          columnSpan: frame.columnSpan,
          rowSpan: frame.rowSpan,
        ),
      );
    }
    final ordered = mapPaintsFirstLayerInFront(map)
        ? map.layers.reversed
        : map.layers;
    for (final layer in ordered.whereType<SmartTileLayer>().where(
      (layer) => layer.isVisible && layer.opacity > 0,
    )) {
      final preset = catalog.presets
          .where((preset) => preset.id == layer.presetId)
          .firstOrNull;
      if (preset == null)
        throw StateError('Terrain absent : ${layer.presetId}');
      _plans.add(
        buildSmartTileLayerVisualPlan(
          map: map,
          layer: layer,
          catalog: catalog,
          pass: SmartTileVisualPass.background,
          sourceCellWidth: project.settings.tileWidth.toDouble(),
          sourceCellHeight: project.settings.tileHeight.toDouble(),
        ),
      );
      _opacities.add(layer.opacity);
      for (final rule in preset.rules) {
        for (final candidate in rule.candidates) {
          for (final part in candidate.parts) {
            _addSource(part.source, catalog);
          }
        }
      }
      for (final stroke in layer.patternStrokes) {
        final pattern = catalog.patterns
            .where((pattern) => pattern.id == stroke.patternId)
            .firstOrNull;
        if (pattern == null)
          throw StateError('Motif de terrain absent : ${stroke.patternId}');
        for (final cell in pattern.cells) {
          for (final part in cell.parts) {
            _addSource(part.source, catalog);
          }
        }
      }
    }
  }

  final MapSpatialScene? scene;
  ({String tilesetId, SmartTileSourceRect sourceRect})? cliff;
  final _plans = <SmartTileLayerVisualPlan>[];
  final _opacities = <double>[];
  final imageIds = <String>{};
  bool animated = false;
  List<SpatialGroundVisual>? _static;

  void _addSource(
    SmartTileVisualSource source,
    ProjectSmartTileCatalog catalog,
  ) {
    source.map(
      frame: (source) => _addFrame(source.frame, catalog),
      animation: (source) {
        animated = true;
        final animation = catalog.animations
            .where((animation) => animation.id == source.animationId)
            .firstOrNull;
        if (animation == null)
          throw StateError(
            'Animation de terrain absente : ${source.animationId}',
          );
        for (final frame in animation.frames) {
          _addFrame(frame.frame, catalog);
        }
      },
    );
  }

  void _addFrame(SmartTileFrameRef frame, ProjectSmartTileCatalog catalog) {
    final atlas = catalog.atlases
        .where((atlas) => atlas.id == frame.atlasId)
        .firstOrNull;
    if (atlas == null)
      throw StateError('Atlas de terrain absent : ${frame.atlasId}');
    imageIds.add(atlas.tilesetId);
  }

  List<SpatialGroundVisual> resolve(int elapsedMs) {
    if (!animated && _static != null) return _static!;
    final result = <SpatialGroundVisual>[];
    for (var index = 0; index < _plans.length; index++) {
      final visuals = _plans[index].resolveBatch(elapsedMs: elapsedMs).visuals;
      final ranks = _groundPaintRanks(visuals);
      final maximum = ranks.fold(0, (a, b) => a > b ? a : b);
      for (var part = 0; part < visuals.length; part++) {
        result.add((
          visual: visuals[part],
          height: .001 * (index + 1 + ranks[part] / (maximum + 1)),
          opacity: _opacities[index],
        ));
      }
    }
    if (!animated) _static = result;
    return result;
  }
}

List<int> _groundPaintRanks(List<SmartTileLayerVisual> visuals) {
  final occupied = <(int, int), List<(SmartTileGeometryRect, int)>>{};
  final ranks = <int>[];
  for (final visual in visuals) {
    final bounds = visual.geometry.visualBounds;
    var rank = 0;
    final cells = <(int, int)>[
      for (var y = bounds.top.floor(); y < bounds.bottom.ceil(); y++)
        for (var x = bounds.left.floor(); x < bounds.right.ceil(); x++) (x, y),
    ];
    for (final cell in cells) {
      for (final previous
          in occupied[cell] ?? <(SmartTileGeometryRect, int)>[]) {
        final other = previous.$1;
        if (bounds.left < other.right &&
            bounds.right > other.left &&
            bounds.top < other.bottom &&
            bounds.bottom > other.top &&
            rank <= previous.$2) {
          rank = previous.$2 + 1;
        }
      }
    }
    ranks.add(rank);
    for (final cell in cells) {
      occupied.putIfAbsent(cell, () => []).add((bounds, rank));
    }
  }
  return ranks;
}

List<Vertex> spatialGroundVertices(
  SmartTileSpriteGeometry geometry, {
  double height = 0,
  MapSpatialScene? scene,
}) {
  final rect = geometry.destinationRect;
  final points =
      [
            SmartTileGeometryPoint(x: 0, y: 0),
            SmartTileGeometryPoint(x: 0, y: rect.height),
            SmartTileGeometryPoint(x: rect.width, y: rect.height),
            SmartTileGeometryPoint(x: rect.width, y: 0),
          ]
          .map((point) => transformSmartTileVector(point, geometry.transform))
          .toList();
  final left = points.map((p) => p.x).reduce((a, b) => a < b ? a : b);
  final top = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
  final uvs = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)];
  final original = [
    for (var index = 0; index < points.length; index++)
      Vertex(
        position: Vector3(
          geometry.visualBounds.left + points[index].x - left,
          height,
          geometry.visualBounds.top + points[index].y - top,
        ),
        texCoord: uvs[index],
      ),
  ];
  if (scene == null) return original;
  final origin = original[0].position;
  final u = original[3].position - origin;
  final v = original[1].position - origin;
  final determinant = u.x * v.z - u.z * v.x;
  Vector2 uvAt(Vector3 point) {
    final dx = point.x - origin.x, dz = point.z - origin.z;
    return Vector2(
      (dx * v.z - dz * v.x) / determinant,
      (u.x * dz - u.z * dx) / determinant,
    );
  }

  return [
    for (final patch in spatialSurfacePatches(
      scene,
      left: geometry.visualBounds.left,
      top: geometry.visualBounds.top,
      right: geometry.visualBounds.right,
      bottom: geometry.visualBounds.bottom,
    ))
      for (final point in patch.corners)
        Vertex(position: point + Vector3(0, height, 0), texCoord: uvAt(point)),
  ];
}

Iterable<Mesh> spatialGroundMeshes(
  List<SpatialGroundVisual> visuals,
  Map<String, Texture> textures, {
  MapSpatialScene? scene,
}) sync* {
  var mesh = Mesh();
  (String, SmartTileSourceRect, double)? previous;
  List<Vertex> vertices = [];
  List<int> indices = [];
  SpatialPixelMaterial? material;
  var vertexCount = 0;
  void flushSurface() {
    if (material != null) {
      mesh.addSurface(
        Surface(vertices: vertices, indices: indices, material: material!),
      );
    }
    vertices = [];
    indices = [];
    material = null;
    previous = null;
  }

  for (final item in visuals) {
    final visual = item.visual;
    final texture = textures[visual.tilesetId];
    if (texture == null)
      throw StateError('Image de terrain absente : ${visual.tilesetId}');
    final rect = visual.sourceRect;
    if (rect.x < 0 ||
        rect.y < 0 ||
        rect.width <= 0 ||
        rect.height <= 0 ||
        rect.x + rect.width > texture.width ||
        rect.y + rect.height > texture.height) {
      throw StateError(
        'Frame de terrain hors de son atlas : ${visual.tilesetId}',
      );
    }
    final key = (visual.tilesetId, rect, item.opacity);
    if (key != previous) {
      flushSurface();
      previous = key;
      material = SpatialPixelMaterial(texture)
        ..albedoColor = ui.Color.fromRGBO(255, 255, 255, item.opacity)
        ..uvRect.setValues(
          rect.x / texture.width,
          rect.y / texture.height,
          rect.width / texture.width,
          rect.height / texture.height,
        );
    }
    final quads = spatialGroundVertices(
      visual.geometry,
      height: item.height,
      scene: scene,
    );
    for (var offset = 0; offset < quads.length; offset += 4) {
      final base = vertices.length;
      vertices.addAll(quads.sublist(offset, offset + 4));
      indices.addAll([
        for (final index
            in scene == null && visual.transform.flipX
                ? [0, 2, 1, 0, 3, 2]
                : [0, 1, 2, 0, 2, 3])
          base + index,
      ]);
      vertexCount += 4;
      if (vertexCount >= 60000) {
        flushSurface();
        yield mesh;
        mesh = Mesh();
        vertexCount = 0;
        previous = key;
        material = SpatialPixelMaterial(texture)
          ..albedoColor = ui.Color.fromRGBO(255, 255, 255, item.opacity)
          ..uvRect.setValues(
            rect.x / texture.width,
            rect.y / texture.height,
            rect.width / texture.width,
            rect.height / texture.height,
          );
      }
    }
    if (vertexCount >= 60000) {
      flushSurface();
      yield mesh;
      mesh = Mesh();
      vertexCount = 0;
    }
  }
  if (vertexCount > 0) {
    flushSurface();
    yield mesh;
  }
}

void applySpatialGroundColorKey(Uint8List rgba, TilesetTransparentColor color) {
  for (var index = 0; index + 3 < rgba.length; index += 4) {
    if (color.matchesRgb(
      red: rgba[index],
      green: rgba[index + 1],
      blue: rgba[index + 2],
    )) {
      rgba.fillRange(index, index + 4, 0);
    }
  }
}

Future<Texture> loadSpatialGroundTexture(
  Uint8List bytes, {
  TilesetTransparentColor? transparentColor,
}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  ui.Image? image;
  try {
    image = (await codec.getNextFrame()).image;
    if (transparentColor != null) {
      final data = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (data == null)
        throw StateError('Impossible de décoder la transparence du terrain.');
      final rgba = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      applySpatialGroundColorKey(rgba, transparentColor);
      final decoded = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        rgba,
        image.width,
        image.height,
        ui.PixelFormat.rgba8888,
        decoded.complete,
      );
      final processed = await decoded.future;
      image.dispose();
      image = processed;
    }
    return await ImageTexture.create(image);
  } finally {
    image?.dispose();
    codec.dispose();
  }
}
