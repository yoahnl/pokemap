import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

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
    required this.quarterTurns,
    required this.destinationWidthPx,
    required this.destinationHeightPx,
    this.flipX = false,
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
  final int quarterTurns;
  final int destinationWidthPx;
  final int destinationHeightPx;
  final bool flipX;
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
  final generatedPlacementIds = collectCinematicBackdropGeneratedPlacementIds(
    mapData,
  );

  for (var i = 0; i < mapData.layers.length; i++) {
    final layer = mapData.layers[i];
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    switch (layer) {
      case TileLayer():
        zOrder = _appendTileInstructions(
          mapData: mapData,
          manifest: manifest,
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
      case SmartTileLayer():
        zOrder = _appendSmartTileInstructions(
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
      case CollisionLayer():
      case ObjectLayer():
      case EnvironmentLayer():
        break;
      case BorderLayer():
        // Border rendering is intentionally deferred. Keeping this branch
        // explicit prevents a Border layer from falling through another
        // layer family's renderer. The empty-plan diagnostic remains valid.
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
    int getGroup(CinematicMapBackdropRenderPass pass) {
      switch (pass) {
        case CinematicMapBackdropRenderPass.tileBackground:
          return 1;
        case CinematicMapBackdropRenderPass.smartTileBackground:
          return 0;
        case CinematicMapBackdropRenderPass.placedBackground:
          return 2;
        case CinematicMapBackdropRenderPass.tileForeground:
        case CinematicMapBackdropRenderPass.placedForeground:
          return 3;
      }
    }

    final groupA = getGroup(a.renderPass);
    final groupB = getGroup(b.renderPass);
    final groupCompare = groupA.compareTo(groupB);
    if (groupCompare != 0) {
      return groupCompare;
    }

    final layerCompare = b.layerIndex.compareTo(a.layerIndex);
    if (layerCompare != 0) {
      return layerCompare;
    }

    if (groupA == 3) {
      final subPassA =
          a.renderPass == CinematicMapBackdropRenderPass.tileForeground ? 0 : 1;
      final subPassB =
          b.renderPass == CinematicMapBackdropRenderPass.tileForeground ? 0 : 1;
      final subPassCompare = subPassA.compareTo(subPassB);
      if (subPassCompare != 0) {
        return subPassCompare;
      }
    }

    final yCompare = a.elementBottomY.compareTo(b.elementBottomY);
    if (yCompare != 0) {
      return yCompare;
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
    diagnostics: List<CinematicMapBackdropTileDiagnostic>.unmodifiable(
      diagnostics,
    ),
  );
}

Set<String> collectCinematicMapBackdropLayerTilesetIds({
  required MapData mapData,
  required ProjectManifest manifest,
}) {
  final ids = <String>{};
  ids.addAll(collectCinematicMapBackdropTileLayerTilesetIds(mapData));
  for (final layer in mapData.layers) {
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    if (layer is SmartTileLayer) {
      for (final pass in SmartTileVisualPass.values) {
        for (final visual in resolveSmartTileLayerVisuals(
          map: mapData,
          layer: layer,
          catalog: manifest.smartTileCatalog,
          pass: pass,
          destinationCellWidth: manifest.settings.tileWidth.toDouble(),
          destinationCellHeight: manifest.settings.tileHeight.toDouble(),
          sourceCellWidth: manifest.settings.tileWidth.toDouble(),
          sourceCellHeight: manifest.settings.tileHeight.toDouble(),
        )) {
          final tilesetId = visual.tilesetId.trim();
          if (tilesetId.isNotEmpty) ids.add(tilesetId);
        }
      }
    }
  }
  for (final placement in mapData.placedElements) {
    final element = _elementById(manifest, placement.elementId);
    final frame = element?.frames.isEmpty ?? true
        ? null
        : element!.frames.primaryFrame;
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
    final transform = QuarterTurnGridTransform(
      sourceSize: GridSize(width: source.width, height: source.height),
      quarterTurns: placement.quarterTurns,
    );
    for (var localY = 0; localY < source.height; localY += 1) {
      for (var localX = 0; localX < source.width; localX += 1) {
        if (collisionCells.contains(GridPos(x: localX, y: localY))) {
          continue;
        }
        final destination = transform.sourceToDestination(
          GridPos(x: localX, y: localY),
        );
        final x = placement.pos.x + destination.x;
        final y = placement.pos.y + destination.y;
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

int _appendTileInstructions({
  required MapData mapData,
  required ProjectManifest manifest,
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
  final explicitForeground = _isExplicitForegroundTileLayer(layer);
  for (var index = 0; index < layer.cells.length; index += 1) {
    final entry = resolveTileLayerCell(layer, index);
    if (entry == null) continue;
    final x = index % mapData.size.width;
    final y = index ~/ mapData.size.width;
    if (!_containsCell(mapData, x, y)) {
      continue;
    }
    if (!manifestTilesetIds.contains(entry.tilesetId)) {
      _addDiagnostic(
        diagnostics,
        code: 'missingTilesetEntry',
        message: 'Tileset ${entry.tilesetId} absent du manifeste.',
        layerId: layer.id,
        tilesetId: entry.tilesetId,
      );
      continue;
    }
    final manifestTileset = manifest.tilesets
        .where((candidate) => candidate.id == entry.tilesetId)
        .first;
    final source = manifestTileset.source;
    final slices =
        <({String assetId, ui.Rect sourceRect, ui.Rect destinationRect})>[];
    if (source == null) {
      final asset = _availableTilesetAsset(
        tilesetId: entry.tilesetId,
        layer: layer,
        manifestTilesetIds: manifestTilesetIds,
        tilesets: tilesets,
        diagnostics: diagnostics,
      );
      if (asset == null) continue;
      if (asset.tileWidth != tileWidth || asset.tileHeight != tileHeight) {
        _addDiagnostic(
          diagnostics,
          code: 'tileMetricMismatch',
          message:
              'Métriques de tileset incompatibles pour ${entry.tilesetId}.',
          layerId: layer.id,
          tilesetId: entry.tilesetId,
        );
        continue;
      }
      slices.add((
        assetId: entry.tilesetId,
        sourceRect: ui.Rect.fromLTWH(
          (entry.localTileId % asset.columns) * tileWidth.toDouble(),
          (entry.localTileId ~/ asset.columns) * tileHeight.toDouble(),
          tileWidth.toDouble(),
          tileHeight.toDouble(),
        ),
        destinationRect: _cellDestinationRect(x, y, tileWidth, tileHeight),
      ));
    } else {
      final selection = switch (source) {
        ProjectRegularAtlasTilesetSource atlas =>
          entry.localTileId < atlas.tileCount
              ? ProjectTilesetVisualSelection.regularAtlas(
                  source: TilesetSourceRect(
                    x: entry.localTileId % atlas.columns,
                    y: entry.localTileId ~/ atlas.columns,
                  ),
                )
              : null,
        ProjectImageCollectionTilesetSource() =>
          ProjectTilesetVisualSelection.imageCollection(
            tileId: entry.localTileId,
          ),
      };
      if (selection == null) {
        _addDiagnostic(
          diagnostics,
          code: 'sourceRectOutOfBounds',
          message:
              'Tuile ${entry.localTileId} hors atlas pour '
              '${entry.tilesetId}.',
          layerId: layer.id,
          tilesetId: entry.tilesetId,
        );
        continue;
      }
      ProjectTilesetVisualResolution visual;
      try {
        visual = const ProjectTilesetVisualResolver().resolve(
          source: source,
          selection: selection,
          cellWidth: tileWidth,
          cellHeight: tileHeight,
        );
      } on ProjectTilesetVisualResolutionException {
        _addDiagnostic(
          diagnostics,
          code: 'sourceRectOutOfBounds',
          message:
              'Tuile ${entry.localTileId} non résolue pour '
              '${entry.tilesetId}.',
          layerId: layer.id,
          tilesetId: entry.tilesetId,
        );
        continue;
      }
      for (final slice in visual.frames.first.slices) {
        slices.add((
          assetId: slice.assetId,
          sourceRect: ui.Rect.fromLTWH(
            slice.sourceRect.x.toDouble(),
            slice.sourceRect.y.toDouble(),
            slice.sourceRect.width.toDouble(),
            slice.sourceRect.height.toDouble(),
          ),
          destinationRect: ui.Rect.fromLTWH(
            x * tileWidth + slice.destinationRect.x.toDouble(),
            y * tileHeight + slice.destinationRect.y.toDouble(),
            slice.destinationRect.width.toDouble(),
            slice.destinationRect.height.toDouble(),
          ),
        ));
      }
    }
    for (final slice in slices) {
      final resolvedAssetId = tilesets.containsKey(slice.assetId)
          ? slice.assetId
          : entry.tilesetId;
      final asset = tilesets[resolvedAssetId];
      if (asset == null || !asset.isAvailable) {
        _addDiagnostic(
          diagnostics,
          code: asset?.status.name ?? 'missingResolvedTileset',
          message:
              asset?.diagnosticMessage ??
              'Image de tileset indisponible pour ${slice.assetId}.',
          layerId: layer.id,
          tilesetId: entry.tilesetId,
        );
        continue;
      }
      if (asset.tileWidth != tileWidth || asset.tileHeight != tileHeight) {
        _addDiagnostic(
          diagnostics,
          code: 'tileMetricMismatch',
          message:
              'Métriques de tileset incompatibles pour ${entry.tilesetId}.',
          layerId: layer.id,
          tilesetId: entry.tilesetId,
        );
        continue;
      }
      if (!_sourceRectFits(asset, slice.sourceRect)) {
        _addDiagnostic(
          diagnostics,
          code: 'sourceRectOutOfBounds',
          message:
              'Tuile ${entry.localTileId} hors atlas pour '
              '${entry.tilesetId}.',
          layerId: layer.id,
          tilesetId: entry.tilesetId,
        );
        continue;
      }
      instructions.add(
        CinematicMapBackdropLayerBitmapInstruction(
          id: '${layer.id}:tile:$index:${slice.assetId}',
          layerId: layer.id,
          layerLabel: layer.name,
          layerKind: CinematicMapBackdropLayerKind.tile,
          renderPass: explicitForeground || foregroundTileCells.contains(index)
              ? CinematicMapBackdropRenderPass.tileForeground
              : CinematicMapBackdropRenderPass.tileBackground,
          zOrder: nextZ++,
          tilesetId: resolvedAssetId,
          sourceRect: slice.sourceRect,
          destinationRect: slice.destinationRect,
          opacity: _opacity(layer.opacity),
          sourceFamily: 'tile',
          sourceId: layer.id,
          tileId: entry.localTileId,
          elementBottomY: y + 1.0,
          elementX: x.toDouble(),
          layerIndex: layerIndex,
          quarterTurns: entry.transform.quarterTurns,
          flipX: entry.transform.flipX,
          destinationWidthPx: slice.destinationRect.width.round(),
          destinationHeightPx: slice.destinationRect.height.round(),
        ),
      );
    }
  }
  return nextZ;
}

int _appendSmartTileInstructions({
  required MapData mapData,
  required ProjectManifest manifest,
  required SmartTileLayer layer,
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
  final presetExists = manifest.smartTileCatalog.presets.any(
    (preset) => preset.id == layer.presetId,
  );
  if (!presetExists) {
    final code = switch (layer.usage) {
      SmartTileUsage.terrain => 'missingTerrainPreset',
      SmartTileUsage.path => 'missingPathPreset',
      SmartTileUsage.forestSurface => 'missingSurfaceVisual',
    };
    _addDiagnostic(
      diagnostics,
      code: code,
      message:
          'Preset Smart Tile ${layer.presetId} introuvable pour '
          '${layer.name}.',
      layerId: layer.id,
    );
    return nextZ;
  }
  for (final pass in SmartTileVisualPass.values) {
    final visuals = resolveSmartTileLayerVisuals(
      map: mapData,
      layer: layer,
      catalog: manifest.smartTileCatalog,
      pass: pass,
      destinationCellWidth: tileWidth.toDouble(),
      destinationCellHeight: tileHeight.toDouble(),
      sourceCellWidth: tileWidth.toDouble(),
      sourceCellHeight: tileHeight.toDouble(),
    );
    for (final visual in visuals) {
      final asset = _availableTilesetAsset(
        tilesetId: visual.tilesetId,
        layer: layer,
        manifestTilesetIds: manifestTilesetIds,
        tilesets: tilesets,
        diagnostics: diagnostics,
      );
      if (asset == null) continue;
      final sourceRect = ui.Rect.fromLTWH(
        visual.sourceRect.x.toDouble(),
        visual.sourceRect.y.toDouble(),
        visual.sourceRect.width.toDouble(),
        visual.sourceRect.height.toDouble(),
      );
      if (!_sourceRectFits(asset, sourceRect)) {
        _addDiagnostic(
          diagnostics,
          code: 'smartTileSourceRectOutOfBounds',
          message:
              'Smart Tile ${layer.presetId} hors atlas pour '
              '${visual.tilesetId}.',
          layerId: layer.id,
          tilesetId: visual.tilesetId,
        );
        continue;
      }
      final bounds = visual.geometry.visualBounds;
      final destination = visual.geometry.destinationRect;
      final isForeground = switch (visual.channel) {
        SmartTileRenderChannel.canopy ||
        SmartTileRenderChannel.foreground ||
        SmartTileRenderChannel.actorOcclusion => true,
        SmartTileRenderChannel.ground ||
        SmartTileRenderChannel.understory ||
        SmartTileRenderChannel.shadow => false,
      };
      instructions.add(
        CinematicMapBackdropLayerBitmapInstruction(
          id:
              '${layer.id}:smartTile:${visual.cellX}:${visual.cellY}:'
              '${visual.ruleId}:${visual.candidateId}:'
              '${visual.channel.name}:$nextZ',
          layerId: layer.id,
          layerLabel: layer.name,
          layerKind: CinematicMapBackdropLayerKind.smartTile,
          renderPass: isForeground
              ? CinematicMapBackdropRenderPass.tileForeground
              : CinematicMapBackdropRenderPass.smartTileBackground,
          zOrder: nextZ,
          tilesetId: visual.tilesetId,
          sourceRect: sourceRect,
          destinationRect: ui.Rect.fromLTWH(
            bounds.left,
            bounds.top,
            bounds.width,
            bounds.height,
          ),
          opacity: _opacity(layer.opacity),
          sourceFamily: 'smartTile',
          sourceId: layer.presetId,
          elementBottomY: bounds.bottom / tileHeight,
          elementX: bounds.left / tileWidth,
          layerIndex: layerIndex,
          quarterTurns: visual.transform.quarterTurns,
          flipX: visual.transform.flipX,
          destinationWidthPx: destination.width.round(),
          destinationHeightPx: destination.height.round(),
        ),
      );
      nextZ += 1;
    }
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
    final isForegroundElement = _shouldElementRenderInForeground(
      placement,
      element,
      layer,
    );
    final layerIndex = mapData.layers.indexOf(layer);
    final transform = QuarterTurnGridTransform(
      sourceSize: GridSize(width: source.width, height: source.height),
      quarterTurns: placement.quarterTurns,
    );
    for (var localY = 0; localY < source.height; localY += 1) {
      for (var localX = 0; localX < source.width; localX += 1) {
        final localPos = GridPos(x: localX, y: localY);
        final destinationLocal = transform.sourceToDestination(localPos);
        final x = placement.pos.x + destinationLocal.x;
        final y = placement.pos.y + destinationLocal.y;
        if (!_containsCell(mapData, x, y)) {
          continue;
        }
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
            elementBottomY:
                placement.pos.y + transform.destinationSize.height.toDouble(),
            elementX: placement.pos.x.toDouble(),
            layerIndex: layerIndex,
            quarterTurns: placement.quarterTurns,
            destinationWidthPx: tileWidth,
            destinationHeightPx: tileHeight,
          ),
        );
        nextZ += 1;
      }
    }
  }
  return nextZ;
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
      message:
          tileset?.diagnosticMessage ??
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
  final duplicate = diagnostics.any(
    (diagnostic) =>
        diagnostic.code == code &&
        diagnostic.message == message &&
        diagnostic.layerId == layerId &&
        diagnostic.tilesetId == tilesetId,
  );
  if (duplicate) return;
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
