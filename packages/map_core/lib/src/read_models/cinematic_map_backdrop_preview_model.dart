import 'dart:math' as math;

import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_asset.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';

enum CinematicMapBackdropPreviewStatus {
  backdropDisabled,
  missingStageMap,
  stageMapUnknown,
  mapDataUnavailable,
  mapDataMismatch,
  tilesetUnavailable,
  available,
}

enum CinematicMapBackdropLayerKind {
  tile,
  terrain,
  path,
  surface,
  object,
  environment,
}

enum CinematicMapBackdropVisualPrimitiveKind {
  tileCell,
  terrainCell,
  pathCell,
  surfaceCell,
  objectAnchor,
  environmentAnchor,
  layerSummary,
  unsupportedLayer,
}

enum CinematicMapBackdropViewportMode {
  fitMap,
  centerMap,
  centerActor,
  centerTarget,
}

enum CinematicMapBackdropPreviewDiagnosticSeverity {
  info,
  warning,
  error,
}

enum CinematicMapBackdropPreviewDiagnosticCode {
  mapBackdropDisabled,
  mapBackdropRequiresStageMap,
  mapBackdropStageMapUnknown,
  mapBackdropMapDataUnavailable,
  mapBackdropMapDataMismatch,
  mapBackdropTilesetMissing,
  mapBackdropLayerUnsupported,
}

@immutable
final class CinematicMapBackdropPreviewDiagnostic {
  const CinematicMapBackdropPreviewDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.sourceId,
  });

  final CinematicMapBackdropPreviewDiagnosticCode code;
  final CinematicMapBackdropPreviewDiagnosticSeverity severity;
  final String message;
  final String? sourceId;
}

@immutable
final class CinematicMapBackdropLayerPreview {
  CinematicMapBackdropLayerPreview({
    required this.id,
    required this.label,
    required this.kind,
    required this.visible,
    required this.opacity,
    required this.summary,
    List<String> renderRefs = const <String>[],
    List<CinematicMapBackdropPreviewDiagnostic> diagnostics =
        const <CinematicMapBackdropPreviewDiagnostic>[],
  })  : renderRefs = List<String>.unmodifiable(renderRefs),
        diagnostics = List<CinematicMapBackdropPreviewDiagnostic>.unmodifiable(
          diagnostics,
        );

  final String id;
  final String label;
  final CinematicMapBackdropLayerKind kind;
  final bool visible;
  final double opacity;
  final String summary;
  final List<String> renderRefs;
  final List<CinematicMapBackdropPreviewDiagnostic> diagnostics;
}

@immutable
final class CinematicMapBackdropVisualPrimitive {
  const CinematicMapBackdropVisualPrimitive({
    required this.id,
    required this.layerId,
    required this.layerLabel,
    required this.layerKind,
    required this.kind,
    required this.layerIndex,
    required this.localOrder,
    required this.visible,
    required this.opacity,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    required this.summary,
    required this.source,
  });

  final String id;
  final String layerId;
  final String layerLabel;
  final CinematicMapBackdropLayerKind layerKind;
  final CinematicMapBackdropVisualPrimitiveKind kind;
  final int layerIndex;
  final int localOrder;
  final bool visible;
  final double opacity;
  final int x;
  final int y;
  final int width;
  final int height;
  final String label;
  final String summary;
  final String source;
}

@immutable
final class CinematicMapBackdropViewportSize {
  const CinematicMapBackdropViewportSize({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;
}

@immutable
final class CinematicMapBackdropViewportPoint {
  const CinematicMapBackdropViewportPoint({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;
}

@immutable
final class CinematicMapBackdropViewportRecommendation {
  const CinematicMapBackdropViewportRecommendation({
    required this.mode,
    required this.zoom,
    required this.center,
    required this.reason,
  });

  final CinematicMapBackdropViewportMode mode;
  final double zoom;
  final CinematicMapBackdropViewportPoint center;
  final String reason;
}

@immutable
final class CinematicMapBackdropPreviewModel {
  CinematicMapBackdropPreviewModel({
    required this.status,
    required this.mapId,
    required this.mapLabel,
    required this.mapRelativePath,
    required this.mapDataId,
    required this.sizeSummary,
    required this.mapWidth,
    required this.mapHeight,
    required this.viewportRecommendation,
    required List<CinematicMapBackdropLayerPreview> layers,
    List<CinematicMapBackdropVisualPrimitive> visualPrimitives =
        const <CinematicMapBackdropVisualPrimitive>[],
    required List<CinematicMapBackdropPreviewDiagnostic> diagnostics,
  })  : layers = List<CinematicMapBackdropLayerPreview>.unmodifiable(layers),
        visualPrimitives =
            List<CinematicMapBackdropVisualPrimitive>.unmodifiable(
          visualPrimitives,
        ),
        diagnostics = List<CinematicMapBackdropPreviewDiagnostic>.unmodifiable(
          diagnostics,
        );

  final CinematicMapBackdropPreviewStatus status;
  final String? mapId;
  final String? mapLabel;
  final String? mapRelativePath;
  final String? mapDataId;
  final String? sizeSummary;
  final int? mapWidth;
  final int? mapHeight;
  final CinematicMapBackdropViewportRecommendation viewportRecommendation;
  final List<CinematicMapBackdropLayerPreview> layers;
  final List<CinematicMapBackdropVisualPrimitive> visualPrimitives;
  final List<CinematicMapBackdropPreviewDiagnostic> diagnostics;

  bool get isAvailable => status == CinematicMapBackdropPreviewStatus.available;
}

CinematicMapBackdropPreviewModel buildCinematicMapBackdropPreviewModel({
  required CinematicAsset asset,
  required ProjectMapEntry? stageMap,
  required MapData? mapData,
  Set<String>? availableTilesetIds,
  CinematicMapBackdropViewportSize? viewportSize,
}) {
  final requestedMapId = asset.mapId?._trimmedOrNull;
  final stageMapId = stageMap?._normalizedId;
  final stageMapLabel = stageMap == null
      ? requestedMapId
      : _labelOrId(stageMap.name, stageMap._normalizedId);
  final stageMapRelativePath = stageMap?.relativePath.trim();
  final fallbackViewport = _viewportRecommendationFor(
    mapData: mapData,
    viewportSize: viewportSize,
  );

  if (asset.stageContext?.backdropMode !=
      CinematicStageBackdropMode.projectMap) {
    return CinematicMapBackdropPreviewModel(
      status: CinematicMapBackdropPreviewStatus.backdropDisabled,
      mapId: requestedMapId,
      mapLabel: stageMapLabel,
      mapRelativePath: stageMapRelativePath,
      mapDataId: mapData?._normalizedId,
      sizeSummary: mapData?._sizeSummary,
      mapWidth: mapData?.size.width,
      mapHeight: mapData?.size.height,
      viewportRecommendation: fallbackViewport,
      layers: const [],
      diagnostics: const [
        CinematicMapBackdropPreviewDiagnostic(
          code: CinematicMapBackdropPreviewDiagnosticCode.mapBackdropDisabled,
          severity: CinematicMapBackdropPreviewDiagnosticSeverity.info,
          message: 'Le decor de map est desactive pour cette cinematique.',
        ),
      ],
    );
  }

  if (requestedMapId == null) {
    return CinematicMapBackdropPreviewModel(
      status: CinematicMapBackdropPreviewStatus.missingStageMap,
      mapId: null,
      mapLabel: null,
      mapRelativePath: null,
      mapDataId: mapData?._normalizedId,
      sizeSummary: mapData?._sizeSummary,
      mapWidth: mapData?.size.width,
      mapHeight: mapData?.size.height,
      viewportRecommendation: fallbackViewport,
      layers: const [],
      diagnostics: const [
        CinematicMapBackdropPreviewDiagnostic(
          code: CinematicMapBackdropPreviewDiagnosticCode
              .mapBackdropRequiresStageMap,
          severity: CinematicMapBackdropPreviewDiagnosticSeverity.error,
          message: 'Le decor de map exige un CinematicAsset.mapId.',
        ),
      ],
    );
  }

  if (stageMap == null || stageMapId != requestedMapId) {
    return CinematicMapBackdropPreviewModel(
      status: CinematicMapBackdropPreviewStatus.stageMapUnknown,
      mapId: requestedMapId,
      mapLabel: stageMapLabel ?? requestedMapId,
      mapRelativePath: stageMapRelativePath,
      mapDataId: mapData?._normalizedId,
      sizeSummary: mapData?._sizeSummary,
      mapWidth: mapData?.size.width,
      mapHeight: mapData?.size.height,
      viewportRecommendation: fallbackViewport,
      layers: const [],
      diagnostics: [
        CinematicMapBackdropPreviewDiagnostic(
          code: CinematicMapBackdropPreviewDiagnosticCode
              .mapBackdropStageMapUnknown,
          severity: CinematicMapBackdropPreviewDiagnosticSeverity.error,
          message: 'La map "$requestedMapId" est absente du manifest projet.',
          sourceId: requestedMapId,
        ),
      ],
    );
  }

  if (mapData == null) {
    return CinematicMapBackdropPreviewModel(
      status: CinematicMapBackdropPreviewStatus.mapDataUnavailable,
      mapId: requestedMapId,
      mapLabel: stageMapLabel,
      mapRelativePath: stageMapRelativePath,
      mapDataId: null,
      sizeSummary: null,
      mapWidth: null,
      mapHeight: null,
      viewportRecommendation: fallbackViewport,
      layers: const [],
      diagnostics: [
        CinematicMapBackdropPreviewDiagnostic(
          code: CinematicMapBackdropPreviewDiagnosticCode
              .mapBackdropMapDataUnavailable,
          severity: CinematicMapBackdropPreviewDiagnosticSeverity.warning,
          message:
              'La MapData "$requestedMapId" doit etre fournie par l appelant.',
          sourceId: requestedMapId,
        ),
      ],
    );
  }

  final mapDataId = mapData._normalizedId;
  if (mapDataId != stageMapId) {
    return CinematicMapBackdropPreviewModel(
      status: CinematicMapBackdropPreviewStatus.mapDataMismatch,
      mapId: requestedMapId,
      mapLabel: stageMapLabel,
      mapRelativePath: stageMapRelativePath,
      mapDataId: mapDataId,
      sizeSummary: mapData._sizeSummary,
      mapWidth: mapData.size.width,
      mapHeight: mapData.size.height,
      viewportRecommendation: fallbackViewport,
      layers: const [],
      diagnostics: [
        CinematicMapBackdropPreviewDiagnostic(
          code: CinematicMapBackdropPreviewDiagnosticCode
              .mapBackdropMapDataMismatch,
          severity: CinematicMapBackdropPreviewDiagnosticSeverity.error,
          message:
              'La MapData "$mapDataId" ne correspond pas a la map "$stageMapId".',
          sourceId: mapDataId,
        ),
      ],
    );
  }

  final layers = _projectVisualLayers(mapData);
  final visualPrimitives = _projectVisualPrimitives(mapData);
  final diagnostics = <CinematicMapBackdropPreviewDiagnostic>[];
  final missingTilesetIds = _missingTilesetIds(
    mapData: mapData,
    availableTilesetIds: availableTilesetIds,
  );
  if (missingTilesetIds.isNotEmpty) {
    diagnostics.add(
      CinematicMapBackdropPreviewDiagnostic(
        code:
            CinematicMapBackdropPreviewDiagnosticCode.mapBackdropTilesetMissing,
        severity: CinematicMapBackdropPreviewDiagnosticSeverity.warning,
        message:
            'Tileset(s) indisponible(s) pour le decor: ${missingTilesetIds.join(', ')}.',
        sourceId: requestedMapId,
      ),
    );
  }

  return CinematicMapBackdropPreviewModel(
    status: missingTilesetIds.isEmpty
        ? CinematicMapBackdropPreviewStatus.available
        : CinematicMapBackdropPreviewStatus.tilesetUnavailable,
    mapId: requestedMapId,
    mapLabel: stageMapLabel,
    mapRelativePath: stageMapRelativePath,
    mapDataId: mapDataId,
    sizeSummary: mapData._sizeSummary,
    mapWidth: mapData.size.width,
    mapHeight: mapData.size.height,
    viewportRecommendation: _viewportRecommendationFor(
      mapData: mapData,
      viewportSize: viewportSize,
    ),
    layers: layers,
    visualPrimitives: visualPrimitives,
    diagnostics: diagnostics,
  );
}

List<CinematicMapBackdropVisualPrimitive> _projectVisualPrimitives(
  MapData mapData,
) {
  final primitives = <CinematicMapBackdropVisualPrimitive>[];

  for (var layerIndex = 0; layerIndex < mapData.layers.length; layerIndex++) {
    final layer = mapData.layers[layerIndex];
    if (layer is TileLayer) {
      var localOrder = 0;
      for (var index = 0; index < layer.tiles.length; index++) {
        final tileId = layer.tiles[index];
        if (tileId <= 0) {
          continue;
        }
        final x = index % mapData.size.width;
        final y = index ~/ mapData.size.width;
        if (!_isInsideMap(mapData, x, y)) {
          continue;
        }
        primitives.add(
          _primitive(
            layer: layer,
            layerIndex: layerIndex,
            localOrder: localOrder++,
            kind: CinematicMapBackdropVisualPrimitiveKind.tileCell,
            x: x,
            y: y,
            label: 'Tuile $tileId',
            summary: 'Tuile positionnee depuis MapData.',
            source: 'tile:$tileId',
          ),
        );
      }
      if (localOrder == 0) {
        primitives.add(_summaryPrimitive(layer, mapData, layerIndex));
      }
    } else if (layer is TerrainLayer) {
      var localOrder = 0;
      for (var index = 0; index < layer.terrains.length; index++) {
        final terrain = layer.terrains[index];
        final x = index % mapData.size.width;
        final y = index ~/ mapData.size.width;
        if (!_isInsideMap(mapData, x, y)) {
          continue;
        }
        primitives.add(
          _primitive(
            layer: layer,
            layerIndex: layerIndex,
            localOrder: localOrder++,
            kind: CinematicMapBackdropVisualPrimitiveKind.terrainCell,
            x: x,
            y: y,
            label: terrain.name,
            summary: 'Terrain ${terrain.name} depuis MapData.',
            source: 'terrain:${terrain.name}',
          ),
        );
      }
      if (localOrder == 0) {
        primitives.add(_summaryPrimitive(layer, mapData, layerIndex));
      }
    } else if (layer is PathLayer) {
      var localOrder = 0;
      final presetId = layer.presetId.trim();
      for (var index = 0; index < layer.cells.length; index++) {
        if (!layer.cells[index]) {
          continue;
        }
        final x = index % mapData.size.width;
        final y = index ~/ mapData.size.width;
        if (!_isInsideMap(mapData, x, y)) {
          continue;
        }
        primitives.add(
          _primitive(
            layer: layer,
            layerIndex: layerIndex,
            localOrder: localOrder++,
            kind: CinematicMapBackdropVisualPrimitiveKind.pathCell,
            x: x,
            y: y,
            label: presetId.isEmpty ? 'Chemin' : presetId,
            summary: 'Cellule de chemin depuis MapData.',
            source: presetId.isEmpty ? 'pathCell' : 'pathPreset:$presetId',
          ),
        );
      }
      if (localOrder == 0) {
        primitives.add(_summaryPrimitive(layer, mapData, layerIndex));
      }
    } else if (layer is SurfaceLayer) {
      var localOrder = 0;
      for (final placement in layer.placements) {
        if (!_isInsideMap(mapData, placement.x, placement.y)) {
          continue;
        }
        primitives.add(
          _primitive(
            layer: layer,
            layerIndex: layerIndex,
            localOrder: localOrder++,
            kind: CinematicMapBackdropVisualPrimitiveKind.surfaceCell,
            x: placement.x,
            y: placement.y,
            label: placement.surfacePresetId,
            summary: 'Placement surface depuis MapData.',
            source: 'surfacePreset:${placement.surfacePresetId}',
          ),
        );
      }
      if (localOrder == 0) {
        primitives.add(_summaryPrimitive(layer, mapData, layerIndex));
      }
    } else if (layer is ObjectLayer) {
      var localOrder = 0;
      for (final element in mapData.placedElements) {
        if (element.layerId.trim() != layer.id.trim() ||
            !_isInsideMap(mapData, element.pos.x, element.pos.y)) {
          continue;
        }
        primitives.add(
          CinematicMapBackdropVisualPrimitive(
            id: '${layer.id}:element:${element.id}:$localOrder',
            layerId: layer.id,
            layerLabel: _labelOrId(layer.name, layer.id),
            layerKind: CinematicMapBackdropLayerKind.object,
            kind: CinematicMapBackdropVisualPrimitiveKind.objectAnchor,
            layerIndex: layerIndex,
            localOrder: localOrder++,
            visible: layer.isVisible,
            opacity: layer.opacity * element.opacity,
            x: element.pos.x,
            y: element.pos.y,
            width: 1,
            height: 1,
            label: element.elementId,
            summary: 'Objet decoratif positionne depuis MapData.',
            source: 'element:${element.elementId}',
          ),
        );
      }
      if (localOrder == 0) {
        primitives.add(_summaryPrimitive(layer, mapData, layerIndex));
      }
    } else if (layer is EnvironmentLayer) {
      var localOrder = 0;
      for (final area in layer.content.areas) {
        for (var index = 0; index < area.mask.cells.length; index++) {
          if (!area.mask.cells[index]) {
            continue;
          }
          final x = index % area.mask.width;
          final y = index ~/ area.mask.width;
          if (!_isInsideMap(mapData, x, y)) {
            continue;
          }
          primitives.add(
            _primitive(
              layer: layer,
              layerIndex: layerIndex,
              localOrder: localOrder++,
              kind: CinematicMapBackdropVisualPrimitiveKind.environmentAnchor,
              x: x,
              y: y,
              label: area.name,
              summary: 'Masque environnement depuis MapData.',
              source: 'environmentArea:${area.id}',
            ),
          );
        }
      }
      if (localOrder == 0) {
        primitives.add(_summaryPrimitive(layer, mapData, layerIndex));
      }
    }
  }

  primitives.sort((a, b) {
    final layerCompare = a.layerIndex.compareTo(b.layerIndex);
    if (layerCompare != 0) {
      return layerCompare;
    }
    return a.localOrder.compareTo(b.localOrder);
  });
  return primitives;
}

CinematicMapBackdropVisualPrimitive _primitive({
  required MapLayer layer,
  required int layerIndex,
  required int localOrder,
  required CinematicMapBackdropVisualPrimitiveKind kind,
  required int x,
  required int y,
  required String label,
  required String summary,
  required String source,
}) {
  return CinematicMapBackdropVisualPrimitive(
    id: '${layer.id}:$source:$x:$y:$localOrder',
    layerId: layer.id,
    layerLabel: _labelOrId(layer.name, layer.id),
    layerKind: _layerKindFor(layer),
    kind: kind,
    layerIndex: layerIndex,
    localOrder: localOrder,
    visible: layer.isVisible,
    opacity: layer.opacity,
    x: x,
    y: y,
    width: 1,
    height: 1,
    label: label,
    summary: summary,
    source: source,
  );
}

CinematicMapBackdropVisualPrimitive _summaryPrimitive(
  MapLayer layer,
  MapData mapData,
  int layerIndex,
) {
  return CinematicMapBackdropVisualPrimitive(
    id: '${layer.id}:summary',
    layerId: layer.id,
    layerLabel: _labelOrId(layer.name, layer.id),
    layerKind: _layerKindFor(layer),
    kind: CinematicMapBackdropVisualPrimitiveKind.layerSummary,
    layerIndex: layerIndex,
    localOrder: 0,
    visible: layer.isVisible,
    opacity: layer.opacity,
    x: 0,
    y: 0,
    width: math.max(1, mapData.size.width),
    height: math.max(1, mapData.size.height),
    label: _labelOrId(layer.name, layer.id),
    summary: 'Resume de couche sans geometrie spatiale exploitable.',
    source: 'layerSummary',
  );
}

bool _isInsideMap(MapData mapData, int x, int y) {
  return x >= 0 && y >= 0 && x < mapData.size.width && y < mapData.size.height;
}

CinematicMapBackdropLayerKind _layerKindFor(MapLayer layer) {
  if (layer is TileLayer) {
    return CinematicMapBackdropLayerKind.tile;
  }
  if (layer is TerrainLayer) {
    return CinematicMapBackdropLayerKind.terrain;
  }
  if (layer is PathLayer) {
    return CinematicMapBackdropLayerKind.path;
  }
  if (layer is SurfaceLayer) {
    return CinematicMapBackdropLayerKind.surface;
  }
  if (layer is ObjectLayer) {
    return CinematicMapBackdropLayerKind.object;
  }
  return CinematicMapBackdropLayerKind.environment;
}

List<CinematicMapBackdropLayerPreview> _projectVisualLayers(MapData mapData) {
  final layers = <CinematicMapBackdropLayerPreview>[];

  for (final layer in mapData.layers) {
    if (layer is TileLayer) {
      final tilesetId =
          layer.tilesetId?._trimmedOrNull ?? mapData.tilesetId._trimmedOrNull;
      layers.add(
        CinematicMapBackdropLayerPreview(
          id: layer.id,
          label: _labelOrId(layer.name, layer.id),
          kind: CinematicMapBackdropLayerKind.tile,
          visible: layer.isVisible,
          opacity: layer.opacity,
          summary: '${layer.tiles.length} tuile(s)',
          renderRefs: [
            'tileCells:${layer.tiles.length}',
            if (tilesetId != null) 'tileset:$tilesetId',
          ],
        ),
      );
    } else if (layer is TerrainLayer) {
      layers.add(
        CinematicMapBackdropLayerPreview(
          id: layer.id,
          label: _labelOrId(layer.name, layer.id),
          kind: CinematicMapBackdropLayerKind.terrain,
          visible: layer.isVisible,
          opacity: layer.opacity,
          summary: '${layer.terrains.length} terrain(s)',
          renderRefs: ['terrainCells:${layer.terrains.length}'],
        ),
      );
    } else if (layer is PathLayer) {
      layers.add(
        CinematicMapBackdropLayerPreview(
          id: layer.id,
          label: _labelOrId(layer.name, layer.id),
          kind: CinematicMapBackdropLayerKind.path,
          visible: layer.isVisible,
          opacity: layer.opacity,
          summary: '${layer.cells.length} cellule(s) de chemin',
          renderRefs: [
            'pathCells:${layer.cells.length}',
            if (layer.presetId.trim().isNotEmpty)
              'pathPreset:${layer.presetId.trim()}',
          ],
        ),
      );
    } else if (layer is SurfaceLayer) {
      layers.add(
        CinematicMapBackdropLayerPreview(
          id: layer.id,
          label: _labelOrId(layer.name, layer.id),
          kind: CinematicMapBackdropLayerKind.surface,
          visible: layer.isVisible,
          opacity: layer.opacity,
          summary: '${layer.placements.length} placement(s) de surface',
          renderRefs: ['surfacePlacements:${layer.placements.length}'],
        ),
      );
    } else if (layer is ObjectLayer) {
      layers.add(
        CinematicMapBackdropLayerPreview(
          id: layer.id,
          label: _labelOrId(layer.name, layer.id),
          kind: CinematicMapBackdropLayerKind.object,
          visible: layer.isVisible,
          opacity: layer.opacity,
          summary: 'Couche objet',
        ),
      );
    } else if (layer is EnvironmentLayer) {
      layers.add(
        CinematicMapBackdropLayerPreview(
          id: layer.id,
          label: _labelOrId(layer.name, layer.id),
          kind: CinematicMapBackdropLayerKind.environment,
          visible: layer.isVisible,
          opacity: layer.opacity,
          summary: 'Source environnement',
          renderRefs: const ['environmentContent'],
        ),
      );
    }
  }

  return layers;
}

List<String> _missingTilesetIds({
  required MapData mapData,
  required Set<String>? availableTilesetIds,
}) {
  if (availableTilesetIds == null) {
    return const [];
  }

  final available = availableTilesetIds
      .map((tilesetId) => tilesetId.trim())
      .where((tilesetId) => tilesetId.isNotEmpty)
      .toSet();
  final required = <String>{};
  final mapTilesetId = mapData.tilesetId._trimmedOrNull;
  if (mapTilesetId != null) {
    required.add(mapTilesetId);
  }

  for (final layer in mapData.layers) {
    if (layer is TileLayer) {
      final tilesetId = layer.tilesetId?._trimmedOrNull ?? mapTilesetId;
      if (tilesetId != null) {
        required.add(tilesetId);
      }
    }
  }

  final missing = required.difference(available).toList()..sort();
  return missing;
}

CinematicMapBackdropViewportRecommendation _viewportRecommendationFor({
  required MapData? mapData,
  required CinematicMapBackdropViewportSize? viewportSize,
}) {
  if (mapData == null) {
    return const CinematicMapBackdropViewportRecommendation(
      mode: CinematicMapBackdropViewportMode.centerMap,
      zoom: 1,
      center: CinematicMapBackdropViewportPoint(x: 0, y: 0),
      reason: 'Aucune MapData disponible pour calculer le cadrage.',
    );
  }

  final center = CinematicMapBackdropViewportPoint(
    x: mapData.size.width / 2,
    y: mapData.size.height / 2,
  );

  if (viewportSize == null ||
      viewportSize.width <= 0 ||
      viewportSize.height <= 0 ||
      mapData.size.width <= 0 ||
      mapData.size.height <= 0) {
    return CinematicMapBackdropViewportRecommendation(
      mode: CinematicMapBackdropViewportMode.centerMap,
      zoom: 1,
      center: center,
      reason:
          'Cadrage centre sans taille de viewport precise fournie au read model.',
    );
  }

  final zoom = math
      .min(
        viewportSize.width / mapData.size.width,
        viewportSize.height / mapData.size.height,
      )
      .clamp(0.1, 4.0)
      .toDouble();

  return CinematicMapBackdropViewportRecommendation(
    mode: CinematicMapBackdropViewportMode.fitMap,
    zoom: zoom,
    center: center,
    reason: 'Cadrage fitMap calcule en unites de grille map_core.',
  );
}

String _labelOrId(String label, String id) {
  final trimmedLabel = label.trim();
  if (trimmedLabel.isNotEmpty) {
    return trimmedLabel;
  }
  return id.trim();
}

extension on String {
  String? get _trimmedOrNull {
    final value = trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }
}

extension on ProjectMapEntry {
  String get _normalizedId => id.trim();
}

extension on MapData {
  String get _normalizedId => id.trim();

  String get _sizeSummary => '${size.width} x ${size.height} tuiles';
}
