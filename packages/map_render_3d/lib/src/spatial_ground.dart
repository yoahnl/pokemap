import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';
import 'spatial_resource_admission.dart';
import 'spatial_terrain_geometry.dart';

typedef SpatialGroundVisual = ({
  SmartTileLayerVisual visual,
  double height,
  double opacity,
});

final class SpatialGroundPlan {
  SpatialGroundPlan(
    MapData map,
    ProjectManifest project, {
    bool Function(String layerId)? includeLayer,
  }) : scene = map.spatialScene {
    final catalog = project.smartTileCatalog;
    _borderMaskLayers.addAll(
      resolveSpatialBorderGroundMaskCellsByLayer(
        manifest: project,
        map: map,
        includeLayer: includeLayer,
      ),
    );
    _borderReplacementLayers.addAll(
      resolveSpatialBorderGroundReplacementsByLayer(
        manifest: project,
        map: map,
        includeLayer: includeLayer,
      ),
    );
    borderGroundReplacements = scene == null
        ? const {}
        : indexSpatialBorderGroundReplacements(
            scene: scene!,
            replacements: _borderReplacementLayers.values
                .expand((value) => value)
                .toList(),
          );
    final materials = {
      for (final material in catalog.materials) material.id: material,
    };
    final allReplacements = resolveSpatialSmartTileModelProjection(
      map: map,
      catalog: catalog,
      sourceCellWidth: project.settings.tileWidth,
      sourceCellHeight: project.settings.tileHeight,
    ).groundReplacements;
    final replacements = {
      for (final entry in allReplacements.entries)
        if (includeLayer?.call(entry.key) != false) entry.key: entry.value,
    };
    _modelReplacementLayers.addAll(replacements);
    final borderMaskCells = {
      for (final cells in _borderMaskLayers.values) ...cells,
    };
    groundReplacementCells = Set.unmodifiable({
      ...borderMaskCells,
      for (final cells in replacements.values) ...cells,
    });
    final bridgeCells = <(int, int)>{};
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
    final layerRanks = spatialSmartTileLayerPaintRanks(map);
    for (final layer in ordered.whereType<SmartTileLayer>().where(
      (layer) =>
          layer.isVisible &&
          layer.opacity > 0 &&
          includeLayer?.call(layer.id) != false,
    )) {
      final preset = catalog.presets
          .where((preset) => preset.id == layer.presetId)
          .firstOrNull;
      if (preset == null)
        throw StateError('Terrain absent : ${layer.presetId}');
      final spatial = scene;
      if (spatial != null && layer.usage == SmartTileUsage.path) {
        for (var z = 0; z < spatial.depth; z++) {
          for (var x = 0; x < spatial.width; x++) {
            final material =
                materials[smartTileMaterialIdAt(
                  layer,
                  mapSize: map.size,
                  x: x,
                  y: z,
                )];
            if (material == null || material.isEmpty) continue;
            _bridgeUpdates.putIfAbsent(layer.id, () => {})[(x, z)] =
                material.pathSurfaceKind == PathSurfaceKind.bridge;
            if (material.pathSurfaceKind == PathSurfaceKind.bridge) {
              bridgeCells.add((x, z));
            } else {
              bridgeCells.remove((x, z));
            }
          }
        }
      }
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
      _layerIds.add(layer.id);
      _planRanks.add(layerRanks[layer.id]! + 1);
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
    _addBorderSurfaces(map, project, includeLayer: includeLayer);
    this.bridgeCells = Set.unmodifiable(bridgeCells);
    final covered = <(int, int)>{...borderMaskCells};
    for (var index = _layerIds.length - 1; index >= 0; index--) {
      covered.addAll(replacements[_layerIds[index]] ?? const {});
      _layerExclusions.insert(0, Set<(int, int)>.unmodifiable(covered));
    }
    _visibleLayerIds.addAll({
      ..._layerIds,
      ..._flatPlans.map((entry) => entry.layerId),
      ..._modelReplacementLayers.keys,
      ..._borderMaskLayers.keys,
      ..._borderReplacementLayers.keys,
    });
  }

  SpatialGroundPlan._prepared(
    SpatialGroundPlan source,
    bool Function(String) includeLayer, {
    MapData? reorderedMap,
  }) : scene = reorderedMap?.spatialScene ?? source.scene {
    _source = reorderedMap == null ? source : null;
    _visibleLayerIds.addAll(source._visibleLayerIds.where(includeLayer));
    _modelReplacementLayers.addAll(source._modelReplacementLayers);
    _borderMaskLayers.addAll(source._borderMaskLayers);
    if (reorderedMap == null) {
      _borderReplacementLayers.addAll(source._borderReplacementLayers);
    } else {
      for (final layer in reorderedMap.layers) {
        final replacements = source._borderReplacementLayers[layer.id];
        if (replacements != null)
          _borderReplacementLayers[layer.id] = replacements;
      }
    }
    _bridgeUpdates.addAll(source._bridgeUpdates);
    final byId = {for (final (i, id) in source._layerIds.indexed) id: i};
    final orderedIds = reorderedMap == null
        ? source._layerIds
        : (mapPaintsFirstLayerInFront(reorderedMap)
                  ? reorderedMap.layers.reversed
                  : reorderedMap.layers)
              .map((layer) => layer.id);
    final ranks = reorderedMap == null
        ? null
        : spatialSmartTileLayerPaintRanks(reorderedMap);
    for (final id in orderedIds) {
      final i = byId[id];
      if (i == null) continue;
      if (!includeLayer(id)) continue;
      _layerIds.add(id);
      _plans.add(source._plans[i]);
      _opacities.add(source._opacities[i]);
      _planRanks.add(ranks == null ? source._planRanks[i] : ranks[id]! + 1);
    }
    final flatIndices = List.generate(
      source._flatPlans.length,
      (index) => index,
    );
    if (reorderedMap != null) {
      final order = {for (final (rank, id) in orderedIds.indexed) id: rank};
      flatIndices.sort((a, b) {
        final delta = order[source._flatPlans[a].layerId]!.compareTo(
          order[source._flatPlans[b].layerId]!,
        );
        return delta == 0 ? a.compareTo(b) : delta;
      });
    }
    for (final i in flatIndices) {
      if (!includeLayer(source._flatPlans[i].layerId)) continue;
      _flatPlans.add(source._flatPlans[i]);
      _flatRanks.add(
        reorderedMap == null ? source._flatRanks[i] : _flatPlans.length,
      );
    }
    cliff = source.cliff;
    animated = source.animated;
    _animationLookaheadMs = source._animationLookaheadMs;
    imageIds.addAll(source.imageIds);
    final borderMasks = {
      for (final entry in _borderMaskLayers.entries)
        if (includeLayer(entry.key)) ...entry.value,
    };
    final replacements = {
      for (final entry in _modelReplacementLayers.entries)
        if (includeLayer(entry.key)) entry.key: entry.value,
    };
    groundReplacementCells = Set.unmodifiable({
      ...borderMasks,
      for (final cells in replacements.values) ...cells,
    });
    borderGroundReplacements = scene == null
        ? const {}
        : indexSpatialBorderGroundReplacements(
            scene: scene!,
            replacements: [
              for (final entry in _borderReplacementLayers.entries)
                if (includeLayer(entry.key)) ...entry.value,
            ],
          );
    final bridges = <(int, int)>{};
    for (final id in _layerIds) {
      for (final update
          in (_bridgeUpdates[id] ?? const <(int, int), bool>{}).entries) {
        update.value ? bridges.add(update.key) : bridges.remove(update.key);
      }
    }
    bridgeCells = Set.unmodifiable(bridges);
    final covered = <(int, int)>{...borderMasks};
    for (var index = _layerIds.length - 1; index >= 0; index--) {
      covered.addAll(replacements[_layerIds[index]] ?? const {});
      _layerExclusions.insert(0, Set<(int, int)>.unmodifiable(covered));
    }
  }

  SpatialGroundPlan withLayerVisibility(bool Function(String) includeLayer) {
    final source = _source ?? this;
    return source._visibleLayerIds.every(includeLayer)
        ? source
        : SpatialGroundPlan._prepared(source, includeLayer);
  }

  SpatialGroundPlan reordered(MapData map) => SpatialGroundPlan._prepared(
    _source ?? this,
    (_) => true,
    reorderedMap: map,
  );

  bool layersMatchVisibility(
    SpatialGroundPlan other,
    bool Function(String) includeLayer,
  ) {
    final source = _source ?? this;
    return identical(source, other._source ?? other) &&
        source._visibleLayerIds.every(
          (id) => includeLayer(id) == other._visibleLayerIds.contains(id),
        );
  }

  final MapSpatialScene? scene;
  SpatialGroundPlan? _source;
  final _visibleLayerIds = <String>{};
  final _modelReplacementLayers = <String, Set<(int, int)>>{};
  final _borderMaskLayers = <String, Set<(int, int)>>{};
  final _borderReplacementLayers =
      <String, List<SpatialBorderGroundReplacement>>{};
  final _bridgeUpdates = <String, Map<(int, int), bool>>{};
  late final SpatialBorderGroundReplacementIndex borderGroundReplacements;
  late final Set<(int, int)> bridgeCells;
  late final Set<(int, int)> groundReplacementCells;
  ({String tilesetId, SmartTileSourceRect sourceRect})? cliff;
  final _plans = <SmartTileLayerVisualPlan>[];
  final _planRanks = <int>[];
  final _flatRanks = <int>[];
  final _flatPlans =
      <
        ({
          String layerId,
          SmartTileLayerVisualPlan plan,
          Map<(int, int), SpatialFlatGroundSurface> surfaces,
          double opacity,
        })
      >[];
  final _flatVisualSurfaces =
      <SmartTileLayerVisual, SpatialFlatGroundSurface>{};
  final _opacities = <double>[];
  final _layerIds = <String>[];
  final _layerExclusions = <Set<(int, int)>>[];
  final _visualExclusions = <SmartTileLayerVisual, Set<(int, int)>>{};
  final imageIds = <String>{};
  bool animated = false;
  int? _animationLookaheadMs;
  int get animationLookaheadMs => _animationLookaheadMs ?? 0;
  Set<String>? _staticImageIds;
  List<SpatialGroundVisual>? _static;
  List<List<SmartTileLayerVisual>>? _resolvedLayers;
  List<SpatialGroundVisual>? _resolvedVisuals;
  final _imageWindows =
      <({List<List<SmartTileLayerVisual>> layers, Set<String> images})>[];

  bool _sameLayers(
    List<List<SmartTileLayerVisual>> a,
    List<List<SmartTileLayerVisual>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  List<List<SmartTileLayerVisual>> _layerVisuals(
    int elapsedMs,
    int Function(String, int, int, int)? clock,
  ) => [
    for (final group in _flatPlans)
      group.plan.resolveBatch(elapsedMs: elapsedMs).visuals,
    for (var index = 0; index < _plans.length; index++)
      _plans[index]
          .resolveBatch(
            elapsedMs: elapsedMs,
            animationElapsedMsForCell: clock == null
                ? null
                : ({required cellX, required cellY, required elapsedMs}) =>
                      clock(_layerIds[index], cellX, cellY, elapsedMs),
          )
          .visuals,
  ];

  late final Set<(int, int)>? paintedCells = paintedCellsFor(resolve(0));

  Set<(int, int)>? paintedCellsFor(List<SpatialGroundVisual> visuals) =>
      scene == null || _plans.isEmpty
      ? null
      : Set.unmodifiable({
          for (final part in visuals)
            if (!_flatVisualSurfaces.containsKey(part.visual) &&
                part.visual.spatialFollowTerrain)
              for (
                var z = part.visual.geometry.visualBounds.top.floor();
                z < part.visual.geometry.visualBounds.bottom.ceil();
                z++
              )
                for (
                  var x = part.visual.geometry.visualBounds.left.floor();
                  x < part.visual.geometry.visualBounds.right.ceil();
                  x++
                )
                  if (x >= 0 &&
                      z >= 0 &&
                      x < scene!.width &&
                      z < scene!.depth &&
                      !excludedCellsFor(part.visual).contains((x, z)))
                    (x, z),
        });

  SpatialGroundUnderlayIndex underlaySupportsFor(
    List<SpatialGroundVisual> visuals,
  ) {
    final result = <(int, int), List<SpatialGroundUnderlay>>{};
    if (scene == null) return result;
    for (final item in visuals) {
      final visual = item.visual;
      if (_flatVisualSurfaces.containsKey(visual) ||
          !visual.spatialFollowTerrain)
        continue;
      final offset = visual.spatialHeightOffset;
      final vertices = spatialGroundVertices(
        visual.geometry,
        spatialClip: visual.spatialClip,
        scene: scene,
        excludedCells: excludedCellsFor(visual),
        groundReplacements: borderGroundReplacements,
      );
      for (var start = 0; start < vertices.length; start += 4) {
        var x = 0.0, z = 0.0;
        final points = <BorderGroundPoint>[];
        for (var corner = start; corner < start + 4; corner++) {
          final position = vertices[corner].position;
          x += position.x;
          z += position.z;
          final point = BorderGroundPoint(x: position.x, z: position.z);
          if (points.isEmpty || points.last != point) points.add(point);
        }
        if (points.length > 1 && points.first == points.last)
          points.removeLast();
        final cell = ((x / 4).floor(), (z / 4).floor());
        result.putIfAbsent(cell, () => []).add((
          footprint: List.unmodifiable(points),
          heightOffset: offset,
        ));
      }
    }
    return Map<(int, int), List<SpatialGroundUnderlay>>.unmodifiable({
      for (final entry in result.entries)
        entry.key: List<SpatialGroundUnderlay>.unmodifiable(entry.value),
    });
  }

  Set<(int, int)> excludedCellsFor(SmartTileLayerVisual visual) =>
      _visualExclusions[visual] ?? const {};

  SpatialFlatGroundSurface? flatSurfaceFor(SmartTileLayerVisual visual) =>
      _flatVisualSurfaces[visual];

  void _addBorderSurfaces(
    MapData map,
    ProjectManifest project, {
    bool Function(String layerId)? includeLayer,
  }) {
    if (scene == null) return;
    final planes =
        <
          (String, double, double, double),
          List<
            ({
              String preset,
              String material,
              double opacity,
              List<BorderGroundFootprint> footprints,
            })
          >
        >{};
    for (final surface in resolveSpatialBorderGroundSurfaces(
      manifest: project,
      map: map,
      includeLayer: includeLayer,
    )) {
      final groups = planes.putIfAbsent((
        surface.layerId,
        surface.height,
        surface.gradientX,
        surface.gradientZ,
      ), () => []);
      if (groups.isEmpty ||
          groups.last.preset != surface.sourceSmartTilePresetId ||
          groups.last.material != surface.materialId ||
          groups.last.opacity != surface.opacity) {
        groups.add((
          preset: surface.sourceSmartTilePresetId,
          material: surface.materialId,
          opacity: surface.opacity,
          footprints: <BorderGroundFootprint>[],
        ));
      }
      groups.last.footprints.addAll(surface.footprints);
    }
    for (final entry in [
      for (final plane in planes.entries)
        for (final group in plane.value)
          MapEntry((
            group.preset,
            group.material,
            plane.key.$2,
            group.opacity,
            plane.key.$3,
            plane.key.$4,
            plane.key.$1,
          ), group.footprints),
    ]) {
      final key = entry.key;
      final indexed = <(int, int), List<BorderGroundFootprint>>{};
      for (final footprint in entry.value) {
        final left = footprint.points
            .map((p) => p.x)
            .reduce(math.min)
            .floor()
            .clamp(0, scene!.width);
        final right = footprint.points
            .map((p) => p.x)
            .reduce(math.max)
            .ceil()
            .clamp(0, scene!.width);
        final top = footprint.points
            .map((p) => p.z)
            .reduce(math.min)
            .floor()
            .clamp(0, scene!.depth);
        final bottom = footprint.points
            .map((p) => p.z)
            .reduce(math.max)
            .ceil()
            .clamp(0, scene!.depth);
        for (var z = top; z < bottom; z++) {
          for (var x = left; x < right; x++) {
            indexed.putIfAbsent((x, z), () => []).add(footprint);
          }
        }
      }
      if (indexed.isEmpty) continue;
      final cells = List<int>.filled(map.size.width * map.size.height, 0);
      for (final cell in indexed.keys)
        cells[cell.$2 * map.size.width + cell.$1] = 1;
      final layer = MapLayer.smartTile(
        id: '_border-ground-${_flatPlans.length}',
        name: 'Border ground',
        presetId: key.$1,
        usage: SmartTileUsage.terrain,
        materialPalette: ['', key.$2],
        field: SmartTileField.cell(semanticCells: cells),
      ) as SmartTileLayer;
      _flatPlans.add((
        layerId: key.$7,
        plan: buildSmartTileLayerVisualPlan(
          map: map,
          layer: layer,
          catalog: project.smartTileCatalog,
          pass: SmartTileVisualPass.background,
          sourceCellWidth: project.settings.tileWidth.toDouble(),
          sourceCellHeight: project.settings.tileHeight.toDouble(),
        ),
        surfaces: {
          for (final item in indexed.entries)
            item.key: SpatialFlatGroundSurface(
              height: key.$3,
              gradientX: key.$5,
              gradientZ: key.$6,
              footprints: item.value,
            ),
        },
        opacity: key.$4,
      ));
      _flatRanks.add(_flatPlans.length);
      final preset = project.smartTileCatalog.presets.singleWhere(
        (p) => p.id == key.$1,
      );
      for (final rule in preset.rules) {
        for (final candidate in rule.candidates) {
          for (final part in candidate.parts)
            _addSource(part.source, project.smartTileCatalog);
        }
      }
    }
  }

  void _addSource(
    SmartTileVisualSource source,
    ProjectSmartTileCatalog catalog,
  ) {
    source.map(
      model3d: (_) {},
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
          if (frame.durationMs > 0 &&
              (_animationLookaheadMs == null ||
                  frame.durationMs < _animationLookaheadMs!)) {
            _animationLookaheadMs = frame.durationMs;
          }
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

  Set<String> imageIdsAt(
    int elapsedMs, {
    int Function(String layerId, int cellX, int cellY, int elapsedMs)?
    animationElapsedMsForCell,
  }) {
    if (!animated && _staticImageIds != null) return _staticImageIds!;
    final layers = _layerVisuals(elapsedMs, animationElapsedMsForCell);
    for (final window in _imageWindows) {
      if (_sameLayers(window.layers, layers)) return window.images;
    }
    final images = Set<String>.unmodifiable({
      if (cliff case final frame?) frame.tilesetId,
      for (final batch in layers)
        for (final visual in batch) visual.tilesetId,
    });
    if (!animated) _staticImageIds = images;
    if (_imageWindows.length == 2) _imageWindows.removeAt(0);
    _imageWindows.add((layers: layers, images: images));
    return images;
  }

  List<SpatialGroundVisual> resolve(
    int elapsedMs, {
    int Function(String layerId, int cellX, int cellY, int elapsedMs)?
    animationElapsedMsForCell,
  }) {
    if (!animated && _static != null) return _static!;
    final layers = _layerVisuals(elapsedMs, animationElapsedMsForCell);
    if (_resolvedLayers case final previous?
        when _sameLayers(previous, layers)) {
      return _resolvedVisuals!;
    }

    _visualExclusions.clear();
    _flatVisualSurfaces.clear();
    final result = <SpatialGroundVisual>[];
    for (var index = 0; index < _flatPlans.length; index++) {
      final group = _flatPlans[index];
      final visuals = layers[index];
      final ranks = _groundPaintRanks(visuals);
      final maximum = ranks.fold(0, (a, b) => a > b ? a : b);
      for (var part = 0; part < visuals.length; part++) {
        final visual = visuals[part];
        final surface = group.surfaces[(visual.cellX, visual.cellY)];
        if (surface == null) continue;
        _flatVisualSurfaces[visual] = surface;
        result.add((
          visual: visual,
          height:
              .0001 *
              (_flatRanks[index] + ranks[part] / (maximum + 1)) /
              ((_source?._flatPlans.length ?? _flatPlans.length) + 1),
          opacity: group.opacity,
        ));
      }
    }
    for (var index = 0; index < _plans.length; index++) {
      final visuals = layers[_flatPlans.length + index];
      final ranks = _groundPaintRanks(visuals);
      final maximum = ranks.fold(0, (a, b) => a > b ? a : b);
      for (var part = 0; part < visuals.length; part++) {
        _visualExclusions[visuals[part]] = _layerExclusions[index];
        result.add((
          visual: visuals[part],
          height:
              spatialSmartTileLayerPaintStep *
              (_planRanks[index] + ranks[part] / (maximum + 1)),
          opacity: _opacities[index],
        ));
      }
    }
    _resolvedLayers = layers;
    _resolvedVisuals = result;
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
  bool followTerrain = true,
  SmartTileSpatialClip? spatialClip,
  SpatialFlatGroundSurface? flatSurface,
  MapSpatialScene? scene,
  Set<(int, int)> excludedCells = const {},
  SpatialBorderGroundReplacementIndex groundReplacements = const {},
}) => _spatialGroundVertices(
  geometry,
  height: height,
  followTerrain: followTerrain,
  spatialClip: spatialClip,
  flatSurface: flatSurface,
  scene: scene,
  excludedCells: excludedCells,
  groundReplacements: groundReplacements,
);

List<Vertex> _spatialGroundVertices(
  SmartTileSpriteGeometry geometry, {
  double height = 0,
  bool followTerrain = true,
  SmartTileSpatialClip? spatialClip,
  SpatialFlatGroundSurface? flatSurface,
  MapSpatialScene? scene,
  ({SmartTileSourceRect sourceRect, Texture texture})? atlasFrame,
  Set<(int, int)> excludedCells = const {},
  SpatialBorderGroundReplacementIndex groundReplacements = const {},
}) {
  Vector2 textureUv(Vector2 uv) {
    final frame = atlasFrame;
    if (frame == null) return uv;
    return Vector2(
      (frame.sourceRect.x + uv.x * frame.sourceRect.width) /
          frame.texture.width,
      (frame.sourceRect.y + uv.y * frame.sourceRect.height) /
          frame.texture.height,
    );
  }

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
        texCoord: scene == null ? textureUv(uvs[index]) : uvs[index],
      ),
  ];
  if (scene == null) {
    if (spatialClip != null || !followTerrain) {
      throw StateError('Spatial raster ground requires a spatial scene');
    }
    return original;
  }
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

  Vector3 pointAt(double x, double z) => Vector3(
    origin.x + u.x * x + v.x * z,
    origin.y,
    origin.z + u.z * x + v.z * z,
  );
  var clipLeft = geometry.visualBounds.left;
  var clipTop = geometry.visualBounds.top;
  var clipRight = geometry.visualBounds.right;
  var clipBottom = geometry.visualBounds.bottom;
  final clip = spatialClip;
  if (clip != null) {
    final visible = [
      pointAt(clip.left, clip.top),
      pointAt(clip.left, clip.bottom),
      pointAt(clip.right, clip.bottom),
      pointAt(clip.right, clip.top),
    ];
    clipLeft = visible.map((point) => point.x).reduce((a, b) => a < b ? a : b);
    clipTop = visible.map((point) => point.z).reduce((a, b) => a < b ? a : b);
    clipRight = visible.map((point) => point.x).reduce((a, b) => a > b ? a : b);
    clipBottom = visible
        .map((point) => point.z)
        .reduce((a, b) => a > b ? a : b);
  }

  final plane =
      flatSurface ??
      (followTerrain
          ? null
          : SpatialFlatGroundSurface(
              height: 0,
              footprints: [
                BorderGroundFootprint(
                  points: [
                    BorderGroundPoint(x: clipLeft, z: clipTop),
                    BorderGroundPoint(x: clipRight, z: clipTop),
                    BorderGroundPoint(x: clipRight, z: clipBottom),
                    BorderGroundPoint(x: clipLeft, z: clipBottom),
                  ],
                ),
              ],
            ));
  return [
    for (final patch
        in plane == null
            ? spatialSurfacePatches(
                scene,
                left: clipLeft,
                top: clipTop,
                right: clipRight,
                bottom: clipBottom,
                groundReplacements: groundReplacements,
              )
            : spatialFlatGroundPatches(
                scene,
                surface: plane,
                left: clipLeft,
                top: clipTop,
                right: clipRight,
                bottom: clipBottom,
              ))
      if (!excludedCells.contains(patch.cell) &&
          patch.ramp?.surfaceInstanceId == null)
        for (final point in patch.corners)
          Vertex(
            position: point + Vector3(0, height, 0),
            texCoord: textureUv(uvAt(point)),
          ),
  ];
}

Iterable<Mesh> spatialGroundMeshes(
  List<SpatialGroundVisual> visuals,
  Map<String, Texture> textures, {
  MapSpatialScene? scene,
  Set<(int, int)> Function(SmartTileLayerVisual visual)? excludedCellsFor,
  SpatialFlatGroundSurface? Function(SmartTileLayerVisual visual)?
  flatSurfaceFor,
  SpatialBorderGroundReplacementIndex groundReplacements = const {},
}) sync* {
  var mesh = Mesh();
  (String, double)? previous;
  List<Vertex> vertices = [];
  List<int> indices = [];
  SpatialPixelMaterial? material;
  var vertexCount = 0;
  void flushSurface() {
    if (material != null && vertices.isNotEmpty) {
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
    final key = (visual.tilesetId, item.opacity);
    if (key != previous) {
      flushSurface();
      previous = key;
      material = SpatialPixelMaterial(
        texture,
        sourceMaterialName: 'ground:${visual.tilesetId}',
        groundDepthOnly: scene != null,
        lightingRole: SpatialPixelLightingRole.ground,
      )..albedoColor = ui.Color.fromRGBO(255, 255, 255, item.opacity);
    }
    final quads = _spatialGroundVertices(
      visual.geometry,
      height: scene == null ? item.height : visual.spatialHeightOffset,
      followTerrain: visual.spatialFollowTerrain,
      spatialClip: visual.spatialClip,
      flatSurface: flatSurfaceFor?.call(visual),
      scene: scene,
      atlasFrame: (sourceRect: rect, texture: texture),
      excludedCells: excludedCellsFor?.call(visual) ?? const {},
      groundReplacements: groundReplacements,
    );
    for (var offset = 0; offset < quads.length; offset += 4) {
      final base = vertices.length;
      for (var corner = offset; corner < offset + 4; corner++) {
        vertices.add(
          scene == null
              ? quads[corner]
              : quads[corner].copyWith(normal: Vector3(0, item.height, 0)),
        );
      }
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
        material = SpatialPixelMaterial(
          texture,
          sourceMaterialName: 'ground:${visual.tilesetId}',
          groundDepthOnly: scene != null,
          lightingRole: SpatialPixelLightingRole.ground,
        )..albedoColor = ui.Color.fromRGBO(255, 255, 255, item.opacity);
      }
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
  RuntimeResourceBudget? budget,
  RuntimeResourceReservation? reservation,
  bool Function()? isCurrent,
  void Function(RuntimeResourceReservation reservation)? onResident,
  Future<ui.Codec> Function(Uint8List bytes)? codecLoader,
}) async {
  final controller = budget ?? RuntimeResourceBudget();
  final lease = reservation ?? await controller.acquire(isCurrent: isCurrent);
  ui.Codec? codec;
  ui.Image? image;
  try {
    if (bytes.length > controller.profile.maximumEncodedBytes) {
      throw const RuntimeResourceAdmissionException('encoded_bytes');
    }
    lease.resize(residentBytes: 0, transientBytes: bytes.length * 2);
    final residentLimit = controller.profile.maximumResidentBytes ~/ 2;
    final transientLimit =
        (controller.profile.maximumTransientBytes - bytes.length * 2) ~/
        (transparentColor == null ? 1 : 3);
    final rgbaBytes = await spatialImageRgbaBytes(
      bytes,
      maximumBytes: residentLimit < transientLimit
          ? residentLimit
          : transientLimit,
    );
    lease.resize(
      residentBytes: rgbaBytes * 2,
      transientBytes:
          bytes.length * 2 + rgbaBytes * (transparentColor == null ? 1 : 3),
    );
    lease.ensureCurrent();
    codec = await (codecLoader ?? ui.instantiateImageCodec)(bytes);
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
    final texture = await ImageTexture.create(image);
    lease.ensureCurrent();
    lease.commit();
    if (onResident == null) {
      lease.release();
    } else {
      onResident(lease);
    }
    return texture;
  } catch (_) {
    lease.release();
    rethrow;
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}

Future<Texture> loadSpatialGroundTextureFromSource(
  Future<Uint8List> Function() read, {
  required RuntimeResourceBudget budget,
  TilesetTransparentColor? transparentColor,
  bool Function()? isCurrent,
  void Function(RuntimeResourceReservation reservation)? onResident,
  bool prefetch = false,
}) async {
  final lease = await budget.acquire(
    residentBytes: 8,
    transientBytes: budget.profile.maximumEncodedBytes,
    prefetch: prefetch,
    isCurrent: isCurrent,
  );
  try {
    lease.ensureCurrent();
    final bytes = await read();
    lease.ensureCurrent();
    return await loadSpatialGroundTexture(
      bytes,
      budget: budget,
      reservation: lease,
      transparentColor: transparentColor,
      isCurrent: isCurrent,
      onResident: onResident,
    );
  } catch (_) {
    lease.release();
    rethrow;
  }
}
