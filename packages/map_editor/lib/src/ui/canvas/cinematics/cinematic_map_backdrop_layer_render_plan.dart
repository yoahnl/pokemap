import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import '../../../features/surface_painter/surface_tile_preview_resolver.dart';
import 'cinematic_map_backdrop_render_pass.dart';
import 'cinematic_map_backdrop_tile_plan_loader.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';

final class CinematicMapBackdropLayerBitmapInstruction {
  const CinematicMapBackdropLayerBitmapInstruction({
    required this.id,
    required this.layerId,
    required this.layerLabel,
    required this.layerKind,
    required this.renderPass,
    required this.zOrder,
    required this.tilesetId,
    required this.sourceRect,
    required this.destinationRect,
    required this.opacity,
    required this.sourceFamily,
    required this.sourceId,
    required this.elementBottomY,
    required this.elementX,
    required this.layerIndex,
    this.tileId,
  });

  final String id;
  final String layerId;
  final String layerLabel;
  final CinematicMapBackdropLayerKind layerKind;
  final CinematicMapBackdropRenderPass renderPass;
  final int zOrder;
  final String tilesetId;
  final ui.Rect sourceRect;
  final ui.Rect destinationRect;
  final double opacity;
  final String sourceFamily;
  final String sourceId;
  final double elementBottomY;
  final double elementX;
  final int layerIndex;
  final int? tileId;
}

final class CinematicMapBackdropLayerRenderPlan {
  const CinematicMapBackdropLayerRenderPlan({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.tilesets,
    required this.instructions,
    required this.diagnostics,
  });

  final int mapWidth;
  final int mapHeight;
  final int tileWidth;
  final int tileHeight;
  final Map<String, CinematicResolvedTilesetAsset> tilesets;
  final List<CinematicMapBackdropLayerBitmapInstruction> instructions;
  final List<CinematicMapBackdropTileDiagnostic> diagnostics;

  bool get hasBitmapInstructions => instructions.isNotEmpty;
  bool get hasForegroundInstructions => instructions.any(
        (instruction) => instruction.renderPass.paintsAfterActorOverlay,
      );
  double get pixelWidth => mapWidth * tileWidth.toDouble();
  double get pixelHeight => mapHeight * tileHeight.toDouble();
}

CinematicMapBackdropLayerRenderPlan buildCinematicMapBackdropLayerRenderPlan({
  required MapData mapData,
  required ProjectManifest manifest,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
}) {
  final tileWidth = manifest.settings.tileWidth;
  final tileHeight = manifest.settings.tileHeight;
  final diagnostics = <CinematicMapBackdropTileDiagnostic>[];
  final instructions = <CinematicMapBackdropLayerBitmapInstruction>[];
  final manifestTilesetIds = {
    for (final tileset in manifest.tilesets) tileset.id.trim(),
  }..remove('');

  if (tileWidth <= 0 || tileHeight <= 0) {
    diagnostics.add(
      const CinematicMapBackdropTileDiagnostic(
        code: 'invalidTileSize',
        message: 'Taille de tuile du projet invalide.',
        severity: CinematicMapBackdropTileDiagnosticSeverity.error,
      ),
    );
    return CinematicMapBackdropLayerRenderPlan(
      mapWidth: mapData.size.width,
      mapHeight: mapData.size.height,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      tilesets: tilesets,
      instructions: const <CinematicMapBackdropLayerBitmapInstruction>[],
      diagnostics: diagnostics,
    );
  }

  var zOrder = 0;
  final foregroundTileCells = buildCinematicBackdropForegroundTileCellIndices(
    map: mapData,
    manifest: manifest,
  );
  final generatedPlacementIds =
      collectCinematicBackdropGeneratedPlacementIds(mapData);

  for (var i = 0; i < mapData.layers.length; i++) {
    final layer = mapData.layers[i];
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    switch (layer) {
      case TerrainLayer():
        zOrder = _appendTerrainInstructions(
          mapData: mapData,
          manifest: manifest,
          layer: layer,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          manifestTilesetIds: manifestTilesetIds,
          tilesets: tilesets,
          diagnostics: diagnostics,
          instructions: instructions,
          zOrder: zOrder,
          layerIndex: i,
        );
      case PathLayer():
        zOrder = _appendPathInstructions(
          mapData: mapData,
          manifest: manifest,
          layer: layer,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          manifestTilesetIds: manifestTilesetIds,
          tilesets: tilesets,
          diagnostics: diagnostics,
          instructions: instructions,
          zOrder: zOrder,
          layerIndex: i,
        );
      case TileLayer():
        zOrder = _appendTileInstructions(
          mapData: mapData,
          layer: layer,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          manifestTilesetIds: manifestTilesetIds,
          tilesets: tilesets,
          diagnostics: diagnostics,
          instructions: instructions,
          foregroundTileCells: foregroundTileCells[layer.id] ?? const <int>{},
          zOrder: zOrder,
          layerIndex: i,
        );
      case SurfaceLayer():
        zOrder = _appendSurfaceInstructions(
          manifest: manifest,
          layer: layer,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          tilesets: tilesets,
          diagnostics: diagnostics,
          instructions: instructions,
          zOrder: zOrder,
          layerIndex: i,
        );
      case CollisionLayer():
      case ObjectLayer():
      case EnvironmentLayer():
        break;
    }
  }

  zOrder = _appendPlacedElementInstructions(
    mapData: mapData,
    manifest: manifest,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    manifestTilesetIds: manifestTilesetIds,
    tilesets: tilesets,
    diagnostics: diagnostics,
    instructions: instructions,
    generatedPlacementIds: generatedPlacementIds,
    zOrder: zOrder,
  );

  instructions.sort((a, b) {
    final passCompare = a.renderPass.order.compareTo(b.renderPass.order);
    if (passCompare != 0) {
      return passCompare;
    }
    final yCompare = a.elementBottomY.compareTo(b.elementBottomY);
    if (yCompare != 0) {
      return yCompare;
    }
    final layerCompare = a.layerIndex.compareTo(b.layerIndex);
    if (layerCompare != 0) {
      return layerCompare;
    }
    final xCompare = a.elementX.compareTo(b.elementX);
    if (xCompare != 0) {
      return xCompare;
    }
    return a.zOrder.compareTo(b.zOrder);
  });

  if (instructions.isEmpty && diagnostics.isEmpty) {
    diagnostics.add(
      const CinematicMapBackdropTileDiagnostic(
        code: 'noBitmapInstructions',
        message: 'Aucune instruction bitmap etendue a rendre.',
        severity: CinematicMapBackdropTileDiagnosticSeverity.info,
      ),
    );
  }

  return CinematicMapBackdropLayerRenderPlan(
    mapWidth: mapData.size.width,
    mapHeight: mapData.size.height,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    tilesets: Map<String, CinematicResolvedTilesetAsset>.unmodifiable(tilesets),
    instructions: List<CinematicMapBackdropLayerBitmapInstruction>.unmodifiable(
      instructions,
    ),
    diagnostics:
        List<CinematicMapBackdropTileDiagnostic>.unmodifiable(diagnostics),
  );
}

Set<String> collectCinematicMapBackdropLayerTilesetIds({
  required MapData mapData,
  required ProjectManifest manifest,
}) {
  final ids = <String>{};
  ids.addAll(collectCinematicMapBackdropTileLayerTilesetIds(mapData));
  ids.addAll(
    collectSurfaceTilePreviewTilesetIds(
      map: mapData,
      catalog: manifest.surfaceCatalog,
    ),
  );
  for (final layer in mapData.layers) {
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    if (layer is TerrainLayer) {
      for (final terrain in layer.terrains.toSet()) {
        if (!terrain.isBackgroundPaintable) {
          continue;
        }
        final preset = _terrainPresetForType(manifest, terrain);
        final variant =
            preset?.variants.isEmpty ?? true ? null : preset!.variants.first;
        final frame = variant?.frames.isEmpty ?? true
            ? null
            : variant!.frames.primaryFrame;
        final tilesetId = _frameTilesetId(frame, preset?.tilesetId ?? '');
        if (tilesetId.isNotEmpty) {
          ids.add(tilesetId);
        }
      }
      continue;
    }
    if (layer is PathLayer) {
      final pathResolver = _resolvePathPreset(manifest, layer.presetId);
      if (pathResolver == null) {
        continue;
      }
      for (var index = 0; index < layer.cells.length; index += 1) {
        if (!layer.cells[index]) {
          continue;
        }
        final x = index % mapData.size.width;
        final y = index ~/ mapData.size.width;
        final frame = _pathFrameForCell(
          mapData: mapData,
          layer: layer,
          resolver: pathResolver,
          x: x,
          y: y,
        );
        final tilesetId = _frameTilesetId(
          frame,
          pathResolver.basePreset.tilesetId,
        );
        if (tilesetId.isNotEmpty) {
          ids.add(tilesetId);
        }
      }
    }
  }
  for (final placement in mapData.placedElements) {
    final element = _elementById(manifest, placement.elementId);
    final frame =
        element?.frames.isEmpty ?? true ? null : element!.frames.primaryFrame;
    final tilesetId = _frameTilesetId(frame, element?.tilesetId ?? '');
    if (tilesetId.isNotEmpty) {
      ids.add(tilesetId);
    }
  }
  ids.remove('');
  return Set<String>.unmodifiable(ids);
}

Map<String, Set<int>> buildCinematicBackdropForegroundTileCellIndices({
  required MapData map,
  required ProjectManifest manifest,
}) {
  final masks = <String, Set<int>>{};
  for (final placement in map.placedElements) {
    final element = _elementById(manifest, placement.elementId);
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    final source = element.frames.primarySource;
    if (source.width <= 1 && source.height <= 1) {
      continue;
    }
    final collisionCells =
        element.collisionProfile?.cells.toSet() ?? const <GridPos>{};
    if (collisionCells.isEmpty) {
      continue;
    }
    final layer = _layerById(map, placement.layerId);
    if (layer is! TileLayer || !layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    final layerMask = masks.putIfAbsent(placement.layerId, () => <int>{});
    for (var localY = 0; localY < source.height; localY += 1) {
      for (var localX = 0; localX < source.width; localX += 1) {
        if (collisionCells.contains(GridPos(x: localX, y: localY))) {
          continue;
        }
        final x = placement.pos.x + localX;
        final y = placement.pos.y + localY;
        if (!_containsCell(map, x, y)) {
          continue;
        }
        layerMask.add(y * map.size.width + x);
      }
    }
  }
  return Map<String, Set<int>>.unmodifiable({
    for (final entry in masks.entries)
      entry.key: Set<int>.unmodifiable(entry.value),
  });
}

Set<String> collectCinematicBackdropGeneratedPlacementIds(MapData mapData) {
  final generatedIds = <String>{};
  for (final layer in mapData.layers.whereType<EnvironmentLayer>()) {
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    generatedIds.addAll(layer.content.generatedPlacementIds);
  }
  return Set<String>.unmodifiable(generatedIds);
}

int _appendTerrainInstructions({
  required MapData mapData,
  required ProjectManifest manifest,
  required TerrainLayer layer,
  required int tileWidth,
  required int tileHeight,
  required Set<String> manifestTilesetIds,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
  required List<CinematicMapBackdropTileDiagnostic> diagnostics,
  required List<CinematicMapBackdropLayerBitmapInstruction> instructions,
  required int zOrder,
  required int layerIndex,
}) {
  var nextZ = zOrder;
  for (var index = 0; index < layer.terrains.length; index += 1) {
    final terrain = layer.terrains[index];
    if (!terrain.isBackgroundPaintable) {
      continue;
    }
    final x = index % mapData.size.width;
    final y = index ~/ mapData.size.width;
    if (!_containsCell(mapData, x, y)) {
      continue;
    }
    final preset = _terrainPresetForType(manifest, terrain);
    if (preset == null || preset.variants.isEmpty) {
      _addDiagnostic(
        diagnostics,
        code: 'missingTerrainPreset',
        message: 'Preset terrain indisponible pour ${terrain.name}.',
        layerId: layer.id,
      );
      continue;
    }
    final variant = preset.variants.first;
    if (variant.frames.isEmpty) {
      _addDiagnostic(
        diagnostics,
        code: 'missingTerrainFrame',
        message: 'Frame terrain indisponible pour ${preset.id}.',
        layerId: layer.id,
      );
      continue;
    }
    final frame = variant.frames.primaryFrame;
    final tilesetId = _frameTilesetId(frame, preset.tilesetId);
    final asset = _availableTilesetAsset(
      tilesetId: tilesetId,
      layer: layer,
      manifestTilesetIds: manifestTilesetIds,
      tilesets: tilesets,
      diagnostics: diagnostics,
    );
    if (asset == null) {
      continue;
    }
    final source = frame.source;
    final subtile = terrainPresetSubtileOffsetsForMapCell(
      x,
      y,
      frameWidthTiles: source.width,
      frameHeightTiles: source.height,
      layout: variant.multiTileLayout,
      subtileSalt: Object.hash(source.x, source.y),
    );
    final sourceRect = _tileSourceRect(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      x: source.x + subtile.$1,
      y: source.y + subtile.$2,
      width: 1,
      height: 1,
    );
    if (!_sourceRectFits(asset, sourceRect)) {
      _addDiagnostic(
        diagnostics,
        code: 'terrainSourceRectOutOfBounds',
        message: 'Terrain ${preset.id} hors atlas pour $tilesetId.',
        layerId: layer.id,
        tilesetId: tilesetId,
      );
      continue;
    }
    instructions.add(
      CinematicMapBackdropLayerBitmapInstruction(
        id: '${layer.id}:terrain:$index',
        layerId: layer.id,
        layerLabel: layer.name,
        layerKind: CinematicMapBackdropLayerKind.terrain,
        renderPass: CinematicMapBackdropRenderPass.terrain,
        zOrder: nextZ,
        tilesetId: tilesetId,
        sourceRect: sourceRect,
        destinationRect: _cellDestinationRect(x, y, tileWidth, tileHeight),
        opacity: _opacity(layer.opacity),
        sourceFamily: 'terrain',
        sourceId: preset.id,
        elementBottomY: y + 1.0,
        elementX: x.toDouble(),
        layerIndex: layerIndex,
      ),
    );
    nextZ += 1;
  }
  return nextZ;
}

int _appendPathInstructions({
  required MapData mapData,
  required ProjectManifest manifest,
  required PathLayer layer,
  required int tileWidth,
  required int tileHeight,
  required Set<String> manifestTilesetIds,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
  required List<CinematicMapBackdropTileDiagnostic> diagnostics,
  required List<CinematicMapBackdropLayerBitmapInstruction> instructions,
  required int zOrder,
  required int layerIndex,
}) {
  var nextZ = zOrder;
  final resolver = _resolvePathPreset(manifest, layer.presetId);
  if (resolver == null) {
    if (layer.cells.any((cell) => cell)) {
      _addDiagnostic(
        diagnostics,
        code: 'missingPathPreset',
        message: 'Preset chemin ${layer.presetId} indisponible.',
        layerId: layer.id,
      );
    }
    return nextZ;
  }
  for (var index = 0; index < layer.cells.length; index += 1) {
    if (!layer.cells[index]) {
      continue;
    }
    final x = index % mapData.size.width;
    final y = index ~/ mapData.size.width;
    if (!_containsCell(mapData, x, y)) {
      continue;
    }
    final frame = _pathFrameForCell(
      mapData: mapData,
      layer: layer,
      resolver: resolver,
      x: x,
      y: y,
    );
    if (frame == null) {
      _addDiagnostic(
        diagnostics,
        code: 'missingPathFrame',
        message: 'Frame chemin indisponible pour ${layer.presetId}.',
        layerId: layer.id,
      );
      continue;
    }
    final tilesetId = _frameTilesetId(frame, resolver.basePreset.tilesetId);
    final asset = _availableTilesetAsset(
      tilesetId: tilesetId,
      layer: layer,
      manifestTilesetIds: manifestTilesetIds,
      tilesets: tilesets,
      diagnostics: diagnostics,
    );
    if (asset == null) {
      continue;
    }
    final sourceRect = _tileSourceRect(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      x: frame.source.x,
      y: frame.source.y,
      width: 1,
      height: 1,
    );
    if (!_sourceRectFits(asset, sourceRect)) {
      _addDiagnostic(
        diagnostics,
        code: 'pathSourceRectOutOfBounds',
        message: 'Chemin ${layer.presetId} hors atlas pour $tilesetId.',
        layerId: layer.id,
        tilesetId: tilesetId,
      );
      continue;
    }
    instructions.add(
      CinematicMapBackdropLayerBitmapInstruction(
        id: '${layer.id}:path:$index',
        layerId: layer.id,
        layerLabel: layer.name,
        layerKind: CinematicMapBackdropLayerKind.path,
        renderPass: CinematicMapBackdropRenderPass.path,
        zOrder: nextZ,
        tilesetId: tilesetId,
        sourceRect: sourceRect,
        destinationRect: _cellDestinationRect(x, y, tileWidth, tileHeight),
        opacity: _opacity(layer.opacity),
        sourceFamily: 'path',
        sourceId: resolver.sourceId,
        elementBottomY: y + 1.0,
        elementX: x.toDouble(),
        layerIndex: layerIndex,
      ),
    );
    nextZ += 1;
  }
  return nextZ;
}

int _appendTileInstructions({
  required MapData mapData,
  required TileLayer layer,
  required int tileWidth,
  required int tileHeight,
  required Set<String> manifestTilesetIds,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
  required List<CinematicMapBackdropTileDiagnostic> diagnostics,
  required List<CinematicMapBackdropLayerBitmapInstruction> instructions,
  required Set<int> foregroundTileCells,
  required int zOrder,
  required int layerIndex,
}) {
  var nextZ = zOrder;
  final tilesetId = (layer.tilesetId ?? mapData.tilesetId).trim();
  final asset = _availableTilesetAsset(
    tilesetId: tilesetId,
    layer: layer,
    manifestTilesetIds: manifestTilesetIds,
    tilesets: tilesets,
    diagnostics: diagnostics,
  );
  if (asset == null) {
    return nextZ;
  }
  final explicitForeground = _isExplicitForegroundTileLayer(layer);
  for (var index = 0; index < layer.tiles.length; index += 1) {
    final tileId = layer.tiles[index];
    if (tileId <= 0) {
      continue;
    }
    final x = index % mapData.size.width;
    final y = index ~/ mapData.size.width;
    if (!_containsCell(mapData, x, y)) {
      continue;
    }
    final sourceIndex = tileId - 1;
    final sourceRect = ui.Rect.fromLTWH(
      (sourceIndex % asset.columns) * tileWidth.toDouble(),
      (sourceIndex ~/ asset.columns) * tileHeight.toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
    if (!_sourceRectFits(asset, sourceRect)) {
      _addDiagnostic(
        diagnostics,
        code: 'sourceRectOutOfBounds',
        message: 'Tuile $tileId hors atlas pour $tilesetId.',
        layerId: layer.id,
        tilesetId: tilesetId,
      );
      continue;
    }
    instructions.add(
      CinematicMapBackdropLayerBitmapInstruction(
        id: '${layer.id}:tile:$index',
        layerId: layer.id,
        layerLabel: layer.name,
        layerKind: CinematicMapBackdropLayerKind.tile,
        renderPass: explicitForeground || foregroundTileCells.contains(index)
            ? CinematicMapBackdropRenderPass.tileForeground
            : CinematicMapBackdropRenderPass.tileBackground,
        zOrder: nextZ,
        tilesetId: tilesetId,
        sourceRect: sourceRect,
        destinationRect: _cellDestinationRect(x, y, tileWidth, tileHeight),
        opacity: _opacity(layer.opacity),
        sourceFamily: 'tile',
        sourceId: layer.id,
        tileId: tileId,
        elementBottomY: y + 1.0,
        elementX: x.toDouble(),
        layerIndex: layerIndex,
      ),
    );
    nextZ += 1;
  }
  return nextZ;
}

int _appendSurfaceInstructions({
  required ProjectManifest manifest,
  required SurfaceLayer layer,
  required int tileWidth,
  required int tileHeight,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
  required List<CinematicMapBackdropTileDiagnostic> diagnostics,
  required List<CinematicMapBackdropLayerBitmapInstruction> instructions,
  required int zOrder,
  required int layerIndex,
}) {
  var nextZ = zOrder;
  final availableTilesetIds = {
    for (final entry in tilesets.entries)
      if (entry.value.isAvailable) entry.key,
  };
  for (final placement in layer.placements) {
    final resolved = resolveSurfaceTilePreviewInstruction(
      layer: layer,
      placement: placement,
      catalog: manifest.surfaceCatalog,
      availableTilesetIds: availableTilesetIds,
    );
    if (resolved == null) {
      _addDiagnostic(
        diagnostics,
        code: 'missingSurfaceVisual',
        message: 'Surface ${placement.surfacePresetId} indisponible.',
        layerId: layer.id,
      );
      continue;
    }
    final asset = tilesets[resolved.tilesetId];
    if (asset == null || !asset.isAvailable) {
      _addDiagnostic(
        diagnostics,
        code: asset?.status.name ?? 'missingResolvedTileset',
        message: asset?.diagnosticMessage ??
            'Image de tileset indisponible pour ${resolved.tilesetId}.',
        layerId: layer.id,
        tilesetId: resolved.tilesetId,
      );
      continue;
    }
    if (!_sourceRectFits(asset, resolved.sourceRect)) {
      _addDiagnostic(
        diagnostics,
        code: 'surfaceSourceRectOutOfBounds',
        message:
            'Surface ${placement.surfacePresetId} hors atlas pour ${resolved.tilesetId}.',
        layerId: layer.id,
        tilesetId: resolved.tilesetId,
      );
      continue;
    }
    instructions.add(
      CinematicMapBackdropLayerBitmapInstruction(
        id: '${layer.id}:surface:${placement.x}:${placement.y}',
        layerId: layer.id,
        layerLabel: layer.name,
        layerKind: CinematicMapBackdropLayerKind.surface,
        renderPass: CinematicMapBackdropRenderPass.surface,
        zOrder: nextZ,
        tilesetId: resolved.tilesetId,
        sourceRect: resolved.sourceRect,
        destinationRect: _cellDestinationRect(
          placement.x,
          placement.y,
          tileWidth,
          tileHeight,
        ),
        opacity: _opacity(layer.opacity),
        sourceFamily: 'surface',
        sourceId: placement.surfacePresetId,
        elementBottomY: placement.y + 1.0,
        elementX: placement.x.toDouble(),
        layerIndex: layerIndex,
      ),
    );
    nextZ += 1;
  }
  return nextZ;
}

bool _shouldElementRenderInForeground(
  MapPlacedElement placement,
  ProjectElementEntry element,
  MapLayer? layer,
) {
  if (layer != null) {
    final marker = '${layer.id} ${layer.name}'.toLowerCase();
    if (marker.contains('foreground') ||
        marker.contains(' fg') ||
        marker.endsWith('_fg') ||
        marker.endsWith('-fg') ||
        marker.contains(' above') ||
        marker.contains('overlay') ||
        marker.contains('front') ||
        marker.contains('roof') ||
        marker.contains('toit')) {
      return true;
    }
  }
  const keys = ['renderInForeground', 'foreground', 'above'];
  for (final key in keys) {
    final val = placement.properties[key]?.toLowerCase();
    if (val == 'true' || val == '1') {
      return true;
    }
  }
  for (final tag in element.tags) {
    final lowerTag = tag.toLowerCase();
    if (lowerTag == 'foreground' ||
        lowerTag == 'fg' ||
        lowerTag == 'above' ||
        lowerTag == 'roof' ||
        lowerTag == 'toit') {
      return true;
    }
  }
  return false;
}

int _appendPlacedElementInstructions({
  required MapData mapData,
  required ProjectManifest manifest,
  required int tileWidth,
  required int tileHeight,
  required Set<String> manifestTilesetIds,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
  required List<CinematicMapBackdropTileDiagnostic> diagnostics,
  required List<CinematicMapBackdropLayerBitmapInstruction> instructions,
  required Set<String> generatedPlacementIds,
  required int zOrder,
}) {
  var nextZ = zOrder;
  for (final placement in mapData.placedElements) {
    final layer = _layerById(mapData, placement.layerId);
    if (layer == null || !layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    final element = _elementById(manifest, placement.elementId);
    if (element == null || element.frames.isEmpty) {
      _addDiagnostic(
        diagnostics,
        code: 'missingPlacedElement',
        message: 'Element place ${placement.elementId} indisponible.',
        layerId: placement.layerId,
      );
      continue;
    }
    final frame = element.frames.primaryFrame;
    final tilesetId = _frameTilesetId(frame, element.tilesetId);
    final asset = _availableTilesetAsset(
      tilesetId: tilesetId,
      layer: layer,
      manifestTilesetIds: manifestTilesetIds,
      tilesets: tilesets,
      diagnostics: diagnostics,
    );
    if (asset == null) {
      continue;
    }
    final source = frame.source;
    final collisionCells = placement.applyCollision
        ? element.collisionProfile?.cells.toSet() ?? const <GridPos>{}
        : const <GridPos>{};
    final splitByCollision =
        collisionCells.isNotEmpty && (source.width > 1 || source.height > 1);
    final isForegroundElement =
        _shouldElementRenderInForeground(placement, element, layer);
    final layerIndex = mapData.layers.indexOf(layer);
    for (var localY = 0; localY < source.height; localY += 1) {
      for (var localX = 0; localX < source.width; localX += 1) {
        final x = placement.pos.x + localX;
        final y = placement.pos.y + localY;
        if (!_containsCell(mapData, x, y)) {
          continue;
        }
        final localPos = GridPos(x: localX, y: localY);
        final renderPass = isForegroundElement
            ? CinematicMapBackdropRenderPass.placedForeground
            : (splitByCollision && !collisionCells.contains(localPos)
                ? CinematicMapBackdropRenderPass.placedForeground
                : CinematicMapBackdropRenderPass.placedBackground);
        final sourceRect = _tileSourceRect(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          x: source.x + localX,
          y: source.y + localY,
          width: 1,
          height: 1,
        );
        if (!_sourceRectFits(asset, sourceRect)) {
          _addDiagnostic(
            diagnostics,
            code: 'placedElementSourceRectOutOfBounds',
            message: 'Element ${element.id} hors atlas pour $tilesetId.',
            layerId: placement.layerId,
            tilesetId: tilesetId,
          );
          continue;
        }
        final sourceFamily = generatedPlacementIds.contains(placement.id)
            ? 'environment'
            : 'placedElement';
        instructions.add(
          CinematicMapBackdropLayerBitmapInstruction(
            id: '${placement.id}:$localX:$localY',
            layerId: placement.layerId,
            layerLabel: layer.name,
            layerKind: CinematicMapBackdropLayerKind.object,
            renderPass: renderPass,
            zOrder: nextZ,
            tilesetId: tilesetId,
            sourceRect: sourceRect,
            destinationRect: _cellDestinationRect(x, y, tileWidth, tileHeight),
            opacity: _opacity(layer.opacity * placement.opacity),
            sourceFamily: sourceFamily,
            sourceId: placement.id,
            elementBottomY: placement.pos.y + source.height.toDouble(),
            elementX: placement.pos.x.toDouble(),
            layerIndex: layerIndex,
          ),
        );
        nextZ += 1;
      }
    }
  }
  return nextZ;
}

_ResolvedPathPreset? _resolvePathPreset(
  ProjectManifest manifest,
  String presetId,
) {
  final trimmed = presetId.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  for (final pattern in manifest.pathPatternPresets) {
    if (pattern.id == trimmed) {
      final base = _pathPresetById(manifest, pattern.basePathPresetId);
      return base == null
          ? null
          : _ResolvedPathPreset(
              sourceId: pattern.id,
              basePreset: base,
              patternPreset: pattern,
            );
    }
  }
  final base = _pathPresetById(manifest, trimmed);
  if (base == null) {
    return null;
  }
  ProjectPathPatternPreset? linkedPattern;
  var hasAmbiguousPattern = false;
  for (final pattern in manifest.pathPatternPresets) {
    if (pattern.basePathPresetId.trim() != trimmed) {
      continue;
    }
    if (linkedPattern != null) {
      hasAmbiguousPattern = true;
      break;
    }
    linkedPattern = pattern;
  }
  if (!hasAmbiguousPattern && linkedPattern != null) {
    return _ResolvedPathPreset(
      sourceId: linkedPattern.id,
      basePreset: base,
      patternPreset: linkedPattern,
    );
  }
  return _ResolvedPathPreset(sourceId: base.id, basePreset: base);
}

TilesetVisualFrame? _pathFrameForCell({
  required MapData mapData,
  required PathLayer layer,
  required _ResolvedPathPreset resolver,
  required int x,
  required int y,
}) {
  final variant = layer.cells.length == mapData.size.width * mapData.size.height
      ? resolvePathVariantAt(
          cells: layer.cells,
          mapSize: mapData.size,
          pos: GridPos(x: x, y: y),
        )
      : TerrainPathVariant.isolated;
  final pattern = resolver.patternPreset;
  if (pattern != null) {
    final resolution = resolvePathPatternVisual(
      pathPatternPreset: pattern,
      basePathPreset: resolver.basePreset,
      resolvedVariant: variant,
      mapX: x,
      mapY: y,
    );
    return resolution.frames.isEmpty ? null : resolution.frames.primaryFrame;
  }
  for (final mapping in resolver.basePreset.variants) {
    if (mapping.variant == variant && mapping.frames.isNotEmpty) {
      return mapping.frames.primaryFrame;
    }
  }
  return resolver.basePreset.variants.isEmpty ||
          resolver.basePreset.variants.first.frames.isEmpty
      ? null
      : resolver.basePreset.variants.first.frames.primaryFrame;
}

final class _ResolvedPathPreset {
  const _ResolvedPathPreset({
    required this.sourceId,
    required this.basePreset,
    this.patternPreset,
  });

  final String sourceId;
  final ProjectPathPreset basePreset;
  final ProjectPathPatternPreset? patternPreset;
}

CinematicResolvedTilesetAsset? _availableTilesetAsset({
  required String tilesetId,
  required MapLayer layer,
  required Set<String> manifestTilesetIds,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
  required List<CinematicMapBackdropTileDiagnostic> diagnostics,
}) {
  if (tilesetId.isEmpty) {
    _addDiagnostic(
      diagnostics,
      code: 'missingTilesetId',
      message: 'Le calque ${layer.name} n a pas de tileset.',
      layerId: layer.id,
    );
    return null;
  }
  if (!manifestTilesetIds.contains(tilesetId)) {
    _addDiagnostic(
      diagnostics,
      code: 'missingTilesetEntry',
      message: 'Tileset $tilesetId absent du manifeste.',
      layerId: layer.id,
      tilesetId: tilesetId,
    );
    return null;
  }
  final tileset = tilesets[tilesetId];
  if (tileset == null || !tileset.isAvailable) {
    _addDiagnostic(
      diagnostics,
      code: tileset?.status.name ?? 'missingResolvedTileset',
      message: tileset?.diagnosticMessage ??
          'Image de tileset indisponible pour $tilesetId.',
      layerId: layer.id,
      tilesetId: tilesetId,
    );
    return null;
  }
  return tileset;
}

void _addDiagnostic(
  List<CinematicMapBackdropTileDiagnostic> diagnostics, {
  required String code,
  required String message,
  String? layerId,
  String? tilesetId,
  CinematicMapBackdropTileDiagnosticSeverity severity =
      CinematicMapBackdropTileDiagnosticSeverity.warning,
}) {
  diagnostics.add(
    CinematicMapBackdropTileDiagnostic(
      code: code,
      message: message,
      severity: severity,
      layerId: layerId,
      tilesetId: tilesetId,
    ),
  );
}

ProjectTerrainPreset? _terrainPresetForType(
  ProjectManifest manifest,
  TerrainType terrain,
) {
  for (final preset in manifest.terrainPresets) {
    if (preset.terrainType == terrain) {
      return preset;
    }
  }
  return null;
}

ProjectPathPreset? _pathPresetById(ProjectManifest manifest, String id) {
  for (final preset in manifest.pathPresets) {
    if (preset.id == id) {
      return preset;
    }
  }
  return null;
}

ProjectElementEntry? _elementById(ProjectManifest manifest, String id) {
  for (final element in manifest.elements) {
    if (element.id == id) {
      return element;
    }
  }
  return null;
}

MapLayer? _layerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
  }
  return null;
}

String _frameTilesetId(TilesetVisualFrame? frame, String fallbackTilesetId) {
  final frameTilesetId = frame?.tilesetId.trim() ?? '';
  return frameTilesetId.isNotEmpty ? frameTilesetId : fallbackTilesetId.trim();
}

ui.Rect _tileSourceRect({
  required int tileWidth,
  required int tileHeight,
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  return ui.Rect.fromLTWH(
    x * tileWidth.toDouble(),
    y * tileHeight.toDouble(),
    width * tileWidth.toDouble(),
    height * tileHeight.toDouble(),
  );
}

ui.Rect _cellDestinationRect(int x, int y, int tileWidth, int tileHeight) {
  return ui.Rect.fromLTWH(
    x * tileWidth.toDouble(),
    y * tileHeight.toDouble(),
    tileWidth.toDouble(),
    tileHeight.toDouble(),
  );
}

bool _sourceRectFits(CinematicResolvedTilesetAsset asset, ui.Rect sourceRect) {
  final image = asset.image;
  return image != null &&
      sourceRect.left >= 0 &&
      sourceRect.top >= 0 &&
      sourceRect.right <= image.width &&
      sourceRect.bottom <= image.height;
}

bool _containsCell(MapData map, int x, int y) {
  return x >= 0 && y >= 0 && x < map.size.width && y < map.size.height;
}

double _opacity(double value) => value.clamp(0.0, 1.0).toDouble();

bool _isExplicitForegroundTileLayer(TileLayer layer) {
  final marker = '${layer.id} ${layer.name}'.toLowerCase();
  return marker.contains('foreground') ||
      marker.contains(' fg') ||
      marker.endsWith('_fg') ||
      marker.endsWith('-fg') ||
      marker.contains(' above') ||
      marker.contains('overlay') ||
      marker.contains('front') ||
      marker.contains('roof') ||
      marker.contains('toit');
}
