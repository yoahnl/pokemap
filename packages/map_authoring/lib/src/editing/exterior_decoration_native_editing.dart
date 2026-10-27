import 'dart:math' as math;
import 'package:map_core/map_core.dart';
import 'environment_editing.dart';
import 'native_terrain_brush.dart';
import '../domains/maps/border_actions.dart' show BorderActions;

final class ExteriorDecorationNativeEditing {
  const ExteriorDecorationNativeEditing();
  ExteriorDecorationSector paintTerrain(
      {required MapExteriorDecoration decoration,
      required ExteriorDecorationSector sector,
      required ProjectManifest manifest,
      required String presetId,
      required Iterable<GridPos> logicalCells,
      String? materialId,
      bool erase = false,
      Iterable<ExteriorDecorationRect> neighborBounds = const []}) {
    final cells = _localCells(decoration, sector, logicalCells, neighborBounds);
    final preset = manifest.smartTileCatalog.presets
        .where((v) => v.id == presetId)
        .firstOrNull;
    if (preset == null) {
      throw const FormatException('Unknown exterior Terrain or Path preset.');
    }
    final map = applyTerrainStroke(
        map: _map(decoration, sector),
        manifest: manifest,
        preset: preset,
        cells: cells,
        materialId: materialId,
        erase: erase);
    return _sector(sector, map);
  }

  ExteriorDecorationSector generateEnvironment(
      {required MapExteriorDecoration decoration,
      required ExteriorDecorationSector sector,
      required ProjectManifest manifest,
      required String presetId,
      required String areaId,
      required int seed,
      required Iterable<GridPos> logicalCells,
      required String projectRevision,
      String layerId = 'exterior_environment',
      bool erase = false,
      Iterable<ExteriorDecorationRect> neighborBounds = const []}) {
    final cells = _localCells(decoration, sector, logicalCells, neighborBounds);
    if (cells.isEmpty) return sector;
    const actions = EnvironmentEditing();
    var map = _map(decoration, sector);
    if (!map.layers.any((v) => v.id == layerId)) {
      map = addMapLayer(map,
          kind: MapLayerKind.environment, id: layerId, name: 'Environnements');
      map = actions.attachToSpatialTerrain(map, layerId: layerId);
    }
    final layer = map.layers
        .whereType<EnvironmentLayer>()
        .where((v) => v.id == layerId)
        .firstOrNull;
    if (layer == null) {
      throw const FormatException('Exterior environment layer kind mismatch.');
    }
    final area = layer.content.areas.where((v) => v.id == areaId).firstOrNull;
    if (area == null) {
      map = actions.createArea(map,
          manifest: manifest,
          layerId: layerId,
          areaId: areaId,
          name: 'Décor extérieur',
          presetId: presetId,
          seed: seed);
    } else if (area.presetId != presetId) {
      throw const FormatException('Exterior environment preset mismatch.');
    } else {
      map = actions.setSeed(map, layerId: layerId, areaId: areaId, seed: seed);
    }
    map = actions.paintCells(map,
        layerId: layerId, areaId: areaId, cells: cells, value: !erase);
    final left = cells.map((v) => v.x).reduce(math.min),
        top = cells.map((v) => v.y).reduce(math.min);
    final right = cells.map((v) => v.x).reduce(math.max),
        bottom = cells.map((v) => v.y).reduce(math.max);
    final preview = actions.previewGeneration(
        manifest: manifest,
        map: map,
        layerId: layerId,
        areaId: areaId,
        projectRevision: projectRevision,
        region: EnvironmentGenerationRegion(
            x: left,
            y: top,
            width: right - left + 1,
            height: bottom - top + 1));
    return _sector(
        sector,
        actions.applyGeneration(
            manifest: manifest,
            map: map,
            preview: preview,
            currentRevision: projectRevision));
  }

  ExteriorDecorationBorder prepareBorder(
      {required MapExteriorDecoration decoration,
      required ProjectManifest manifest,
      required String id,
      required String blueprintId,
      required Iterable<GridPos> logicalPoints,
      required BorderSignedInt64 seed,
      String? layerId,
      bool closed = false,
      ExteriorDecorationBorder? before}) {
    final owner = before == null
        ? decoration.outerBounds
        : ExteriorDecorationRect(
            x: before.originX,
            z: before.originZ,
            width: before.width,
            depth: before.depth);
    if (!decoration.outerBounds.containsRect(owner)) {
      throw const FormatException(
          'Existing Border owner bounds exceed the configured margins.');
    }
    final points = logicalPoints.toList(growable: false);
    if (points.length < 2 ||
        points.length > 4096 ||
        points.any((v) => !owner.contains(v.x, v.y))) {
      throw const FormatException(
          'The contour exceeds its persistent owner bounds; expanding an existing owner requires explicit migration.');
    }
    var steps = 0;
    for (var i = 1; i < points.length; i++) {
      steps += (points[i].x - points[i - 1].x).abs() +
          (points[i].y - points[i - 1].y).abs();
      if (steps > ExteriorDecorationBorder.maximumContourPoints) {
        throw const FormatException(
            'Exterior Border contour exceeds its rasterized point budget.');
      }
    }
    if (closed) {
      steps += (points.first.x - points.last.x).abs() +
          (points.first.y - points.last.y).abs();
      if (steps > ExteriorDecorationBorder.maximumContourPoints) {
        throw const FormatException(
            'Exterior Border contour exceeds its rasterized point budget.');
      }
    }
    final record = manifest.borderCatalog.records
        .where((v) => v.id == blueprintId)
        .firstOrNull;
    if (record == null || record.latestPublished == null) {
      throw const FormatException(
          'Native exterior Border blueprint is not published.');
    }
    final prior = before?.feature;
    return ExteriorDecorationBorder(
        id: id,
        layerId: layerId ?? before?.layerId ?? 'exterior_border',
        originX: owner.x,
        originZ: owner.z,
        width: owner.width,
        depth: owner.depth,
        feature: BorderFeature(
            id: id,
            name: prior?.name ?? record.latestPublished!.definition.name,
            blueprintId: blueprintId,
            seed: seed,
            geometry: BorderStrokeGeometry(strokes: [
              canonicalizeBorderStrokeV1(
                  id: 'contour',
                  sampledPoints: [
                    for (final point in points)
                      GridPos(x: point.x - owner.x, y: point.y - owner.z)
                  ],
                  closed: closed)
            ]),
            overrides: prior?.overrides ?? const [],
            keepOutRegions: prior?.keepOutRegions ?? const [],
            lineSide: prior?.lineSide ?? BorderLineSide.primary,
            spatialOffsetWorld: prior?.spatialOffsetWorld,
            paramsOverride: prior?.paramsOverride,
            materialization: prior?.materialization),
        instances: before?.instances ?? const []);
  }

  ExteriorDecorationBorder? prepareBorderErase(
      {required MapExteriorDecoration decoration,
      required ProjectManifest manifest,
      required ExteriorDecorationBorder before,
      required Iterable<GridPos> logicalPoints,
      required MapData playableMap}) {
    final geometry = before.feature.geometry;
    if (geometry is! BorderStrokeGeometry) {
      throw const FormatException(
          'Native exterior erasure requires a linear contour.');
    }
    final points = [
      for (final point in logicalPoints)
        GridPos(x: point.x - before.originX, y: point.y - before.originZ)
    ];
    if (points.isEmpty ||
        points.length > 4096 ||
        points.any((v) =>
            v.x < 0 || v.y < 0 || v.x >= before.width || v.y >= before.depth)) {
      throw const FormatException(
          'Exterior erasure must stay inside its persistent owner.');
    }
    final definition = manifest.borderCatalog
        .recordById(before.feature.blueprintId)
        ?.latestPublished
        ?.definition;
    if (definition == null) {
      throw const FormatException(
          'Native exterior Border blueprint is not published.');
    }
    final erased = const BorderActions().editStroke(geometry,
        mode: BorderStrokeEditingMode.erase,
        sampledPoints: points,
        preserveTraversal: definition.sequenceLength == 1 ||
            definition.followContourDirection);
    if (erased.strokes.isEmpty) return null;
    final prior = before.feature;
    final next = ExteriorDecorationBorder(
        id: before.id,
        layerId: before.layerId,
        originX: before.originX,
        originZ: before.originZ,
        width: before.width,
        depth: before.depth,
        instances: before.instances,
        feature: BorderFeature(
            id: prior.id,
            name: prior.name,
            blueprintId: prior.blueprintId,
            seed: prior.seed,
            geometry: erased,
            overrides: prior.overrides,
            keepOutRegions: prior.keepOutRegions,
            lineSide: prior.lineSide,
            spatialOffsetWorld: prior.spatialOffsetWorld,
            paramsOverride: prior.paramsOverride,
            materialization: prior.materialization));
    return next;
  }

  ExteriorDecorationBorder? eraseBorder(
      {required MapExteriorDecoration decoration,
      required ProjectManifest manifest,
      required ExteriorDecorationBorder before,
      required Iterable<GridPos> logicalPoints,
      required MapData playableMap}) {
    final next = prepareBorderErase(
        decoration: decoration,
        manifest: manifest,
        before: before,
        logicalPoints: logicalPoints,
        playableMap: playableMap);
    return next == null
        ? null
        : resolveBorder(
            manifest: manifest,
            decoration: decoration,
            border: next,
            playableMap: playableMap);
  }

  ExteriorDecorationBorder resolveBorder(
          {required ProjectManifest manifest,
          required MapExteriorDecoration decoration,
          required ExteriorDecorationBorder border,
          required MapData playableMap}) =>
      applyExteriorDecorationBorderResolution(
          border,
          resolveExteriorDecorationBorder(
              manifest: manifest,
              decoration: decoration,
              border: border,
              playableMap: playableMap));
  MapData _map(
          MapExteriorDecoration decoration, ExteriorDecorationSector sector) =>
      sector
          .asVisualMap()
          .copyWith(id: decoration.mapId, name: decoration.mapId);
  ExteriorDecorationSector visualSector(
          {required ExteriorDecorationSector before, required MapData map}) =>
      ExteriorDecorationSector(
          id: before.id,
          originX: before.originX,
          originZ: before.originZ,
          scene: map.spatialScene!,
          layers: [
            for (final layer in map.layers)
              if (layer is SmartTileLayer)
                layer.copyWith(
                    animationActivation: SmartTileAnimationActivation.always)
              else
                layer
          ]);
  ExteriorDecorationSector _sector(
          ExteriorDecorationSector before, MapData map) =>
      visualSector(before: before, map: map);
  Set<GridPos> _localCells(
      MapExteriorDecoration decoration,
      ExteriorDecorationSector sector,
      Iterable<GridPos> input,
      Iterable<ExteriorDecorationRect> neighbors) {
    final cells = input.toSet();
    if (cells.length > 4096 ||
        !decoration.outerBounds.containsRect(sector.bounds) ||
        cells.any((v) =>
            !sector.bounds.contains(v.x, v.y) ||
            decoration.isExcluded(v.x, v.y, neighborBounds: neighbors))) {
      throw const FormatException(
          'Exterior brush cells must remain in their visual target outside playable maps.');
    }
    return {
      for (final v in cells)
        GridPos(x: v.x - sector.originX, y: v.y - sector.originZ)
    };
  }
}
