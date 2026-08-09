part of 'package:map_editor/src/ui/canvas/map_canvas.dart';

enum _EditorMapTileRenderPass {
  background,
  foreground,
}

final Expando<_EditorObjectVisualIndexCache> _editorObjectVisualIndexCache =
    Expando<_EditorObjectVisualIndexCache>('editorObjectVisualIndex');
final Expando<_EditorPatternOwnerIndexCache> _editorPatternOwnerIndexCache =
    Expando<_EditorPatternOwnerIndexCache>('editorPatternOwnerIndex');

final class _EditorObjectVisualIndexCache {
  const _EditorObjectVisualIndexCache({
    required this.project,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.index,
  });

  final ProjectManifest? project;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final double tileWidth;
  final double tileHeight;
  final MapPlacedTileVisualIndex index;
}

final class _EditorPatternOwnerIndexCache {
  const _EditorPatternOwnerIndexCache({
    required this.catalog,
    required this.mapWidth,
    required this.mapHeight,
    required this.index,
  });

  final ProjectSmartTileCatalog catalog;
  final int mapWidth;
  final int mapHeight;
  final SmartTilePatternOwnerIndex index;
}

/// Rejoue côté éditeur la même séparation "fond / avant-plan" que la runtime.
///
/// Pourquoi cette logique existe :
/// - certains éléments posés (table, arbre, façade, etc.) occupent plusieurs
///   cellules ;
/// - seules les cellules de collision représentent le "socle" gameplay ;
/// - les autres cellules servent d'overlay visuel et doivent pouvoir passer
///   devant un acteur.
///
/// Sans cette séparation, l'éditeur peint toute la tile layer en fond puis les
/// entités par-dessus, ce qui donne une preview trompeuse : une entité semble
/// au-dessus d'une table alors qu'en runtime la frange avant de la table doit
/// repasser devant elle.
///
/// On reste volontairement aligné sur la règle runtime existante :
/// - cellules en collision -> restent dans le fond ;
/// - cellules hors collision -> passent dans l'avant-plan.
@visibleForTesting
Map<String, Set<int>> buildEditorForegroundTileCellIndicesByLayerId({
  required MapData map,
  required ProjectManifest? project,
  Iterable<MapPlacedElement>? placedElements,
}) {
  if (project == null || map.placedElements.isEmpty) {
    return const <String, Set<int>>{};
  }

  final tileLayerById = <String, TileLayer>{
    for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
  };
  if (tileLayerById.isEmpty) {
    return const <String, Set<int>>{};
  }

  final elementById = <String, ProjectElementEntry>{
    for (final entry in project.elements) entry.id: entry,
  };
  final out = <String, Set<int>>{};
  final mapWidth = map.size.width;
  final mapHeight = map.size.height;

  for (final instance in placedElements ?? map.placedElements) {
    final layer = tileLayerById[instance.layerId];
    if (layer == null) {
      continue;
    }

    final entry = elementById[instance.elementId];
    if (entry == null || entry.frames.isEmpty) {
      continue;
    }

    final transform = resolveMapPlacedElementFootprint(
      instance: instance,
      element: entry,
    );
    final width = transform.sourceSize.width;
    final height = transform.sourceSize.height;
    if (width <= 1 && height <= 1) {
      continue;
    }

    final collisionCells = entry.collisionProfile?.cells;
    if (collisionCells == null || collisionCells.isEmpty) {
      continue;
    }

    final collisionSet = <int>{
      for (final cell in collisionCells) cell.y * width + cell.x,
    };
    final layerMask = out.putIfAbsent(layer.id, () => <int>{});

    for (var localY = 0; localY < height; localY++) {
      for (var localX = 0; localX < width; localX++) {
        final localIndex = localY * width + localX;
        if (collisionSet.contains(localIndex)) {
          // Les cellules de collision sont le "socle" gameplay. Elles restent
          // dans la passe de fond, comme en runtime.
          continue;
        }

        final destination = transform.sourceToDestination(
          GridPos(x: localX, y: localY),
        );
        final x = instance.pos.x + destination.x;
        final y = instance.pos.y + destination.y;
        if (x < 0 || y < 0 || x >= mapWidth || y >= mapHeight) {
          continue;
        }

        final globalIndex = y * mapWidth + x;
        if (resolveTileLayerCell(layer, globalIndex) == null) {
          continue;
        }

        layerMask.add(globalIndex);
      }
    }
  }

  return out;
}

@visibleForTesting
bool shouldPaintEditorTileCellInRenderPass({
  required bool explicitForeground,
  required bool isForegroundCell,
  required bool foregroundPass,
}) {
  if (foregroundPass) {
    return explicitForeground || isForegroundCell;
  }
  return explicitForeground ? false : !isForegroundCell;
}

@visibleForTesting
bool shouldPaintEditorEntityInForegroundPass(
  MapEntity entity, {
  required bool foregroundPass,
}) {
  final renderInForeground = entity.shouldRenderProjectElementInForeground;
  return foregroundPass ? renderInForeground : !renderInForeground;
}

bool _isExplicitForegroundTileLayerForEditor({
  required String layerId,
  required String layerName,
}) {
  final id = layerId.trim().toLowerCase();
  final name = layerName.trim().toLowerCase();
  const markers = <String>{
    'foreground',
    'fg',
    'above',
    'overlay',
    'front',
    'roof',
    'toit',
    'overhead',
    'occlusion',
  };

  bool containsMarker(String value) {
    for (final marker in markers) {
      if (value == marker ||
          value.startsWith('${marker}_') ||
          value.endsWith('_$marker') ||
          value.contains('_${marker}_')) {
        return true;
      }
    }
    return false;
  }

  return containsMarker(id) || containsMarker(name);
}

@visibleForTesting
final class EnvironmentMaskBrushCursorOverlay {
  const EnvironmentMaskBrushCursorOverlay({
    required this.center,
    required this.brushSize,
    required this.mode,
  });

  final GridPos center;
  final int brushSize;
  final EnvironmentMaskEditMode mode;

  @override
  bool operator ==(Object other) {
    return other is EnvironmentMaskBrushCursorOverlay &&
        other.center == center &&
        other.brushSize == brushSize &&
        other.mode == mode;
  }

  @override
  int get hashCode => Object.hash(center, brushSize, mode);
}

@visibleForTesting
@immutable
final class EditorMapVisibleCellBounds {
  const EditorMapVisibleCellBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => math.max(0, right - left);
  int get height => math.max(0, bottom - top);
  int get cellCount => width * height;

  bool intersectsCellArea({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0 || cellCount == 0) return false;
    return x < right && x + width > left && y < bottom && y + height > top;
  }
}

@visibleForTesting
EditorMapVisibleCellBounds resolveEditorMapVisibleCellBounds({
  required Size viewportSize,
  required GridSize mapSize,
  required double zoom,
  required Offset offset,
  required double tileWidth,
  required double tileHeight,
  int marginCells = 1,
}) {
  if (!viewportSize.width.isFinite ||
      !viewportSize.height.isFinite ||
      viewportSize.isEmpty ||
      mapSize.width <= 0 ||
      mapSize.height <= 0 ||
      !zoom.isFinite ||
      zoom <= 0 ||
      !offset.dx.isFinite ||
      !offset.dy.isFinite ||
      !tileWidth.isFinite ||
      tileWidth <= 0 ||
      !tileHeight.isFinite ||
      tileHeight <= 0) {
    return const EditorMapVisibleCellBounds(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
    );
  }
  final margin = math.max(0, marginCells);
  final worldLeft = -offset.dx / zoom;
  final worldTop = -offset.dy / zoom;
  final worldRight = (viewportSize.width - offset.dx) / zoom;
  final worldBottom = (viewportSize.height - offset.dy) / zoom;
  final left = ((worldLeft / tileWidth).floor() - margin)
      .clamp(0, mapSize.width)
      .toInt();
  final top = ((worldTop / tileHeight).floor() - margin)
      .clamp(0, mapSize.height)
      .toInt();
  final right = ((worldRight / tileWidth).ceil() + margin)
      .clamp(0, mapSize.width)
      .toInt();
  final bottom = ((worldBottom / tileHeight).ceil() + margin)
      .clamp(0, mapSize.height)
      .toInt();
  return EditorMapVisibleCellBounds(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
}

@visibleForTesting
@immutable
final class MapGridCullingDebugSnapshot {
  MapGridCullingDebugSnapshot({
    required this.visibleBounds,
    required this.totalMapCellCount,
    required this.tileCellVisits,
    required this.collisionCellVisits,
    required this.smartTileVisualVisits,
    required this.smartTileOwnerCellVisits,
    required this.smartTilePatternStrokeCellVisits,
    required this.smartTilePatternIndexEntries,
    required this.objectTileCandidateVisits,
    required this.objectTileSourceCount,
    required this.objectVisualDefinitionCacheSize,
    required this.objectSpatialBucketCount,
    required this.gridLineVisits,
    required this.staticShadowInstructionVisits,
    required this.projectedBuildingShadowInstructionVisits,
    required Set<String> placedElementIds,
    required this.placedElementPassVisits,
  }) : placedElementIds = Set<String>.unmodifiable(placedElementIds);

  final EditorMapVisibleCellBounds visibleBounds;
  final int totalMapCellCount;
  final int tileCellVisits;
  final int collisionCellVisits;
  final int smartTileVisualVisits;
  final int smartTileOwnerCellVisits;
  final int smartTilePatternStrokeCellVisits;
  final int smartTilePatternIndexEntries;
  final int objectTileCandidateVisits;
  final int objectTileSourceCount;
  final int objectVisualDefinitionCacheSize;
  final int objectSpatialBucketCount;
  final int gridLineVisits;
  final int staticShadowInstructionVisits;
  final int projectedBuildingShadowInstructionVisits;
  final Set<String> placedElementIds;
  final int placedElementPassVisits;
}

typedef MapGridCullingDebugObserver = void Function(
  MapGridCullingDebugSnapshot snapshot,
);

final class _MapGridCullingDebugCounter {
  int tileCellVisits = 0;
  int collisionCellVisits = 0;
  int smartTileVisualVisits = 0;
  int smartTileOwnerCellVisits = 0;
  int smartTilePatternStrokeCellVisits = 0;
  int objectTileCandidateVisits = 0;
  int gridLineVisits = 0;
  final Set<SmartTilePatternOwnerIndex> patternIndices = {};
  final Set<MapPlacedTileVisualIndex> objectIndices = {};
  int staticShadowInstructionVisits = 0;
  int projectedBuildingShadowInstructionVisits = 0;
  int placedElementPassVisits = 0;
}

/// Painter massif extrait tel quel du shell `MapCanvas`.
typedef MapGridPaintObserver = void Function();

///
/// Cette extraction est volontairement mécanique : on ne change pas la
/// responsabilité ni le comportement du painter dans ce lot, on réduit
/// seulement le blast radius du fichier widget principal.
class MapGridPainter extends CustomPainter {
  final MapData map;
  final double zoom;
  final Offset offset;
  final GridPos? hoveredTile;
  final String? activeLayerId;
  final double tileWidth;
  final double tileHeight;
  final Map<String, ui.Image?> tilesetImagesById;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final Map<String, int> tilesPerRowById;
  final MapToolPreview? toolPreview;
  final List<MapWarp> warps;
  final List<MapGameplayZone> gameplayZones;
  final MapRect? gameplayZoneDraftArea;
  final String? selectedEntityId;
  final String? selectedMapEventId;
  final String? selectedWarpId;
  final String? selectedTriggerId;
  final String? selectedGameplayZoneId;
  final String? selectedPlacedElementInstanceId;
  final MapPlacedElementRotationPlan? placedElementRotationPreview;
  final NarrativeEditorFocusTarget? narrativeEventFocusTarget;
  final NarrativeEventCreatedSourceProposal? narrativeEventSourceProposal;
  final Color? narrativeEventHighlightColor;
  final Color? rotationPreviewAcceptedColor;
  final Color? rotationPreviewRejectedColor;
  final Map<MapConnectionDirection, String> connectionLabelsByDirection;
  final ProjectManifest? project;
  final EditorShadowLightPreviewPreset? shadowLightPreviewPreset;
  final EditorCanvasRepaintClock? _animationClock;
  final int _staticAnimationMs;
  final MapGridPaintObserver? debugOnPaint;
  final MapGridCullingDebugObserver? debugOnCulling;
  final bool showGrid;
  final bool showEntityEditorChrome;
  final bool showEditorOverlays;
  final EditorShadowPreviewProjectionOwner _shadowProjectionOwner;

  /// Lot Environment-22 : surcouche semi-transparente des cellules masque actives.
  final EnvironmentAreaMask? environmentMaskOverlay;
  final EnvironmentMaskBrushCursorOverlay? environmentBrushCursorOverlay;
  final EnvironmentGeneratedPlacementAddPreview? environmentGeneratedAddPreview;
  final String? environmentGeneratedDeletePreviewId;
  final BorderPreviewTransaction? borderPreview;
  final EditorBorderDiagnosticOverlayPalette? borderDiagnosticOverlayPalette;

  MapGridPainter({
    required this.map,
    EditorShadowPreviewProjectionOwner? shadowProjectionOwner,
    required this.zoom,
    required this.offset,
    this.hoveredTile,
    this.activeLayerId,
    required this.tileWidth,
    required this.tileHeight,
    required this.tilesetImagesById,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.tilesPerRowById,
    this.toolPreview,
    required this.warps,
    required this.gameplayZones,
    this.gameplayZoneDraftArea,
    this.selectedEntityId,
    this.selectedMapEventId,
    this.selectedWarpId,
    this.selectedTriggerId,
    this.selectedGameplayZoneId,
    this.selectedPlacedElementInstanceId,
    this.placedElementRotationPreview,
    this.narrativeEventFocusTarget,
    this.narrativeEventSourceProposal,
    this.narrativeEventHighlightColor,
    this.rotationPreviewAcceptedColor,
    this.rotationPreviewRejectedColor,
    required this.connectionLabelsByDirection,
    this.project,
    this.shadowLightPreviewPreset,
    EditorCanvasRepaintClock? animationClock,
    int editorEntityAnimationMs = 0,
    this.debugOnPaint,
    this.debugOnCulling,
    this.showGrid = true,
    this.showEntityEditorChrome = true,
    this.showEditorOverlays = true,
    this.environmentMaskOverlay,
    this.environmentBrushCursorOverlay,
    this.environmentGeneratedAddPreview,
    this.environmentGeneratedDeletePreviewId,
    this.borderPreview,
    this.borderDiagnosticOverlayPalette,
  })  : _shadowProjectionOwner =
            shadowProjectionOwner ?? EditorShadowPreviewProjectionOwner(),
        _animationClock = animationClock,
        _staticAnimationMs = editorEntityAnimationMs,
        super(repaint: animationClock);

  int get effectiveAnimationMs =>
      _animationClock?.elapsedMs ?? _staticAnimationMs;

  @override
  void paint(Canvas canvas, Size size) {
    assert(() {
      debugOnPaint?.call();
      return true;
    }());
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);

    final gridWidth = map.size.width * tileWidth;
    final gridHeight = map.size.height * tileHeight;
    final visibleBounds = resolveEditorMapVisibleCellBounds(
      viewportSize: size,
      mapSize: map.size,
      zoom: zoom,
      offset: offset,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    final cullingObserver = debugOnCulling;
    final cullingCounter =
        cullingObserver == null ? null : _MapGridCullingDebugCounter();
    final projectContext = project;
    final shadowProjection = projectContext == null
        ? null
        : _shadowProjectionOwner.projectionFor(
            manifest: projectContext,
            map: map,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            lightPreviewPreset: shadowLightPreviewPreset,
          );
    final visiblePlacedElements = shadowProjection?.placedElementsIn(
          EditorShadowPreviewCellViewport(
            left: visibleBounds.left,
            top: visibleBounds.top,
            right: visibleBounds.right,
            bottom: visibleBounds.bottom,
          ),
        ) ??
        const <MapPlacedElement>[];

    // Cell-backed layers and placed-element footprints use cell bounds. Shadow
    // projections use their cached exact world-pixel geometry because their
    // visual extents can escape the placed element anchor.

    final layerPaintOrderResult = buildEditorMapLayerPaintOrderResult(map);
    final layerPaintOrder = layerPaintOrderResult.order;
    if (layerPaintOrder == null) {
      canvas.restore();
      return;
    }
    final compositionPlan = layerPaintOrder.compositionPlan;
    final tileLayersInPaintOrder =
        compositionPlan.visibleTileLayersInPaintOrder;
    final foregroundTileCellIndicesByLayerId =
        buildEditorForegroundTileCellIndicesByLayerId(
      map: map,
      project: project,
      placedElements: visiblePlacedElements,
    );
    final shadowViewport = EditorShadowPreviewViewport(
      left: visibleBounds.left * tileWidth,
      top: visibleBounds.top * tileHeight,
      right: visibleBounds.right * tileWidth,
      bottom: visibleBounds.bottom * tileHeight,
    );
    final projectedBuildingShadowPreviewInstructions =
        shadowProjection?.projectedBuildingInstructionsIn(shadowViewport) ??
            const <EditorStaticShadowPreviewInstruction>[];
    final staticShadowPreviewInstructions =
        shadowProjection?.staticInstructionsIn(shadowViewport) ??
            const <EditorStaticShadowPreviewInstruction>[];
    if (cullingCounter != null) {
      cullingCounter.projectedBuildingShadowInstructionVisits +=
          projectedBuildingShadowPreviewInstructions.length;
      cullingCounter.staticShadowInstructionVisits +=
          staticShadowPreviewInstructions.length;
    }

    final borderCatalog = project?.borderCatalog;
    for (final step in compositionPlan.steps) {
      switch (step.kind) {
        case MapVisualCompositionStepKind.smartTileLayer:
          _paintSmartTileLayer(
            canvas,
            step.layer! as SmartTileLayer,
            pass: SmartTileVisualPass.background,
            visibleBounds: visibleBounds,
            cullingCounter: cullingCounter,
          );
        case MapVisualCompositionStepKind.tileBackgroundLayer:
          _paintTileLayer(
            canvas,
            step.layer! as TileLayer,
            renderPass: _EditorMapTileRenderPass.background,
            foregroundTileCellIndicesByLayerId:
                foregroundTileCellIndicesByLayerId,
            visibleBounds: visibleBounds,
            visiblePlacedElements: visiblePlacedElements,
            cullingCounter: cullingCounter,
          );
        case MapVisualCompositionStepKind.borderLayer:
          if (borderCatalog != null) {
            const BorderPreviewPainter().paintLayer(
              canvas,
              map: map,
              layer: step.layer! as BorderLayer,
              catalog: borderCatalog,
              frameImagesByKey: tilesetImagesById,
              sourceTileWidth: sourceTileWidth,
              sourceTileHeight: sourceTileHeight,
              displayScale:
                  sourceTileWidth <= 0 ? 1 : tileWidth / sourceTileWidth,
              elapsedMs: effectiveAnimationMs,
              preview: borderPreview,
            );
          }
        case MapVisualCompositionStepKind.shadows:
          paintEditorStaticShadowPreviewInstructions(
            canvas,
            projectedBuildingShadowPreviewInstructions,
          );
          paintEditorStaticShadowPreviewInstructions(
            canvas,
            staticShadowPreviewInstructions,
          );
        case MapVisualCompositionStepKind.placedElements:
          _paintPlacedElementsForLayer(
            canvas,
            step.layer! as TileLayer,
            renderPass: _EditorMapTileRenderPass.background,
            visiblePlacedElements: visiblePlacedElements,
            cullingCounter: cullingCounter,
          );
        case MapVisualCompositionStepKind.backgroundEntities:
          _paintEntities(
            canvas,
            foregroundPass: false,
          );
          for (final smartLayer in map.layers
              .where((layer) => layer.isVisible)
              .whereType<SmartTileLayer>()) {
            _paintSmartTileLayer(
              canvas,
              smartLayer,
              pass: SmartTileVisualPass.actorOcclusion,
              visibleBounds: visibleBounds,
              cullingCounter: cullingCounter,
            );
          }
        case MapVisualCompositionStepKind.foregroundTilesAndPlacedElements:
          for (final layer in tileLayersInPaintOrder) {
            _paintTileLayer(
              canvas,
              layer,
              renderPass: _EditorMapTileRenderPass.foreground,
              foregroundTileCellIndicesByLayerId:
                  foregroundTileCellIndicesByLayerId,
              visibleBounds: visibleBounds,
              visiblePlacedElements: visiblePlacedElements,
              cullingCounter: cullingCounter,
            );
            _paintPlacedElementsForLayer(
              canvas,
              layer,
              renderPass: _EditorMapTileRenderPass.foreground,
              visiblePlacedElements: visiblePlacedElements,
              cullingCounter: cullingCounter,
            );
          }
          for (final smartLayer in map.layers
              .where((layer) => layer.isVisible)
              .whereType<SmartTileLayer>()) {
            _paintSmartTileLayer(
              canvas,
              smartLayer,
              pass: SmartTileVisualPass.foreground,
              visibleBounds: visibleBounds,
              cullingCounter: cullingCounter,
            );
          }
        case MapVisualCompositionStepKind.foregroundEntities:
          _paintEntities(
            canvas,
            foregroundPass: true,
          );
        case MapVisualCompositionStepKind.collisionOverlay:
          for (final layer
              in compositionPlan.visibleCollisionLayersInPaintOrder) {
            _paintCollisionLayer(
              canvas,
              layer,
              isActive: layer.id == activeLayerId,
              visibleBounds: visibleBounds,
              cullingCounter: cullingCounter,
            );
          }
        case MapVisualCompositionStepKind.objectLayer:
          _paintObjectLayer(
            canvas,
            step.layer! as ObjectLayer,
            visibleBounds: visibleBounds,
            cullingCounter: cullingCounter,
          );
        case MapVisualCompositionStepKind.environmentNoop:
          break;
      }
    }

    if (showGrid) {
      final gridPaint = Paint()
        ..color = PokeMapLegacyColors.white10
        ..strokeWidth = 1.0 / zoom
        ..style = PaintingStyle.stroke;

      for (var x = visibleBounds.left; x <= visibleBounds.right; x++) {
        cullingCounter?.gridLineVisits += 1;
        canvas.drawLine(
          Offset(x * tileWidth, visibleBounds.top * tileHeight),
          Offset(x * tileWidth, visibleBounds.bottom * tileHeight),
          gridPaint,
        );
      }
      for (var y = visibleBounds.top; y <= visibleBounds.bottom; y++) {
        cullingCounter?.gridLineVisits += 1;
        canvas.drawLine(
          Offset(visibleBounds.left * tileWidth, y * tileHeight),
          Offset(visibleBounds.right * tileWidth, y * tileHeight),
          gridPaint,
        );
      }
    }

    if (showEditorOverlays) {
      if (hoveredTile != null) {
        final hoverPaint = Paint()
          ..color = PokeMapLegacyColors.cyanAccent.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            hoveredTile!.x * tileWidth,
            hoveredTile!.y * tileHeight,
            tileWidth,
            tileHeight,
          ),
          hoverPaint,
        );

        final cursorBorder = Paint()
          ..color = PokeMapLegacyColors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 / zoom;

        canvas.drawRect(
          Rect.fromLTWH(
            hoveredTile!.x * tileWidth,
            hoveredTile!.y * tileHeight,
            tileWidth,
            tileHeight,
          ),
          cursorBorder,
        );
      }

      _paintGameplayZones(canvas);
      _paintSelectedPlacedElementInstance(canvas);
      _paintPlacedElementRotationPreview(canvas);
      _paintToolPreview(canvas);
      _paintEnvironmentGeneratedAddPreview(canvas);
      _paintEnvironmentMaskOverlay(canvas);
      _paintEnvironmentBrushCursorOverlay(canvas);
      _paintBorderDiagnosticOverlay(canvas);
      _paintMapEvents(canvas);
      _paintTriggers(canvas);
      _paintWarps(canvas);
      _paintConnections(canvas, gridWidth, gridHeight);
      _paintNarrativeEventBridgeHighlight(canvas, gridWidth, gridHeight);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, gridWidth, gridHeight),
        Paint()
          ..color = PokeMapLegacyColors.white
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.restore();
    if (cullingObserver != null && cullingCounter != null) {
      cullingObserver(
        MapGridCullingDebugSnapshot(
          visibleBounds: visibleBounds,
          totalMapCellCount: map.size.width * map.size.height,
          tileCellVisits: cullingCounter.tileCellVisits,
          collisionCellVisits: cullingCounter.collisionCellVisits,
          smartTileVisualVisits: cullingCounter.smartTileVisualVisits,
          smartTileOwnerCellVisits: cullingCounter.smartTileOwnerCellVisits,
          smartTilePatternStrokeCellVisits:
              cullingCounter.smartTilePatternStrokeCellVisits,
          smartTilePatternIndexEntries: cullingCounter.patternIndices.fold<int>(
            0,
            (total, index) => total + index.entryCount,
          ),
          objectTileCandidateVisits: cullingCounter.objectTileCandidateVisits,
          objectTileSourceCount: cullingCounter.objectIndices.fold<int>(
            0,
            (total, index) => total + index.sourceObjectCount,
          ),
          objectVisualDefinitionCacheSize:
              cullingCounter.objectIndices.fold<int>(
            0,
            (total, index) => total + index.cachedVisualDefinitionCount,
          ),
          objectSpatialBucketCount: cullingCounter.objectIndices.fold<int>(
            0,
            (total, index) => total + index.spatialBucketCount,
          ),
          gridLineVisits: cullingCounter.gridLineVisits,
          staticShadowInstructionVisits:
              cullingCounter.staticShadowInstructionVisits,
          projectedBuildingShadowInstructionVisits:
              cullingCounter.projectedBuildingShadowInstructionVisits,
          placedElementIds: {
            for (final instance in visiblePlacedElements) instance.id,
          },
          placedElementPassVisits: cullingCounter.placedElementPassVisits,
        ),
      );
    }
  }

  void _paintNarrativeEventBridgeHighlight(
    Canvas canvas,
    double gridWidth,
    double gridHeight,
  ) {
    final focus = narrativeEventFocusTarget;
    final proposal = narrativeEventSourceProposal;
    final color = narrativeEventHighlightColor;
    if (color == null) return;
    if (focus != null && focus.mapId == map.id) {
      final bounds = focus.bounds;
      final rect = bounds == null
          ? Rect.fromLTWH(0, 0, gridWidth, gridHeight)
          : _narrativeEventMapRect(bounds);
      _paintNarrativeEventRect(canvas, rect, color, preview: false);
    }
    if (proposal != null && proposal.afterMap.id == map.id) {
      _paintNarrativeEventRect(
        canvas,
        _narrativeEventMapRect(proposal.bounds),
        color,
        preview: true,
      );
    }
  }

  Rect _narrativeEventMapRect(MapRect bounds) {
    return Rect.fromLTWH(
      bounds.pos.x * tileWidth,
      bounds.pos.y * tileHeight,
      bounds.size.width * tileWidth,
      bounds.size.height * tileHeight,
    );
  }

  void _paintNarrativeEventRect(
    Canvas canvas,
    Rect rect,
    Color color, {
    required bool preview,
  }) {
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: preview ? 0.2 : 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect.deflate(2 / zoom),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = (preview ? 2 : 3) / zoom,
    );
    canvas.drawRect(
      rect.inflate(3 / zoom),
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / zoom,
    );
  }

  void _paintBorderDiagnosticOverlay(Canvas canvas) {
    final palette = borderDiagnosticOverlayPalette;
    final diagnostics = editorBorderPreviewDiagnosticsForMap(
      map: map,
      preview: borderPreview,
    );
    if (palette == null || diagnostics.isEmpty) return;
    paintEditorBorderDiagnosticOverlay(
      canvas,
      marks: buildEditorBorderDiagnosticOverlayMarks(diagnostics),
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      zoom: zoom,
      palette: palette,
    );
  }

  void _paintEnvironmentMaskOverlay(Canvas canvas) {
    final mask = environmentMaskOverlay;
    if (mask == null) return;
    final expected = mask.width * mask.height;
    if (mask.cells.length != expected) return;

    final fill = Paint()
      ..color = PokeMapLegacyColors.collisionAllowedFill
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = PokeMapLegacyColors.collisionAllowedStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / zoom;

    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        final i = y * mask.width + x;
        if (i >= mask.cells.length || !mask.cells[i]) continue;
        final rect = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, border);
      }
    }
  }

  void _paintEnvironmentBrushCursorOverlay(Canvas canvas) {
    final overlay = environmentBrushCursorOverlay;
    if (overlay == null) return;

    final footprint = resolveEnvironmentMaskBrushFootprint(
      mapSize: map.size,
      center: overlay.center,
      brushSize: overlay.brushSize,
    );
    if (footprint.isEmpty) return;

    final isErase = overlay.mode == EnvironmentMaskEditMode.erase;
    final fill = Paint()
      ..color = (isErase
          ? PokeMapLegacyColors.maskEraseFill
          : PokeMapLegacyColors.maskPaintFill)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = isErase
          ? PokeMapLegacyColors.maskEraseStroke
          : PokeMapLegacyColors.maskPaintStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / zoom;

    for (final cell in footprint.cells) {
      final rect = Rect.fromLTWH(
        cell.x * tileWidth,
        cell.y * tileHeight,
        tileWidth,
        tileHeight,
      );
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);
    }
  }

  void _paintWarps(Canvas canvas) {
    if (warps.isEmpty) return;
    for (final warp in warps) {
      if (warp.pos.x < 0 ||
          warp.pos.y < 0 ||
          warp.pos.x >= map.size.width ||
          warp.pos.y >= map.size.height) {
        continue;
      }
      final isSelected = warp.id == selectedWarpId;
      final rect = Rect.fromLTWH(
        warp.pos.x * tileWidth,
        warp.pos.y * tileHeight,
        tileWidth,
        tileHeight,
      );
      final activationRect = _warpActivationRect(warp);
      if (activationRect != rect) {
        final areaPaint = Paint()
          ..color = (warp.triggerMode == MapWarpTriggerMode.onBump
                  ? PokeMapLegacyColors.orangeAccent
                  : PokeMapLegacyColors.cyanAccent)
              .withValues(alpha: isSelected ? 0.18 : 0.12)
          ..style = PaintingStyle.fill;
        final areaBorder = Paint()
          ..color = (warp.triggerMode == MapWarpTriggerMode.onBump
                  ? PokeMapLegacyColors.orangeAccent
                  : PokeMapLegacyColors.cyanAccent)
              .withValues(alpha: isSelected ? 0.75 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.8 / zoom : 1.2 / zoom;
        canvas.drawRect(activationRect, areaPaint);
        canvas.drawRect(activationRect, areaBorder);
      }
      final fillPaint = Paint()
        ..color = (isSelected
                ? (warp.triggerMode == MapWarpTriggerMode.onBump
                    ? PokeMapLegacyColors.orangeAccent
                    : PokeMapLegacyColors.cyanAccent)
                : PokeMapLegacyColors.purpleAccent)
            .withValues(alpha: isSelected ? 0.42 : 0.34)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = isSelected
            ? PokeMapLegacyColors.white
            : PokeMapLegacyColors.purpleAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.2 / zoom : 1.4 / zoom;
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
      _paintWarpApproachMarkers(
        canvas,
        activationRect: activationRect,
        allowedApproachFacings: warp.allowedApproachFacings,
        isSelected: isSelected,
      );
      final center = Offset(rect.center.dx, rect.center.dy);
      if (warp.triggerMode == MapWarpTriggerMode.onEnter) {
        canvas.drawCircle(
          center,
          (tileWidth < tileHeight ? tileWidth : tileHeight) * 0.14,
          Paint()
            ..color = isSelected
                ? PokeMapLegacyColors.white
                : PokeMapLegacyColors.purpleShade100,
        );
      } else {
        final symbolSize =
            (tileWidth < tileHeight ? tileWidth : tileHeight) * 0.24;
        final symbolRect = Rect.fromCenter(
          center: center,
          width: symbolSize,
          height: symbolSize,
        );
        canvas.drawRect(
          symbolRect,
          Paint()
            ..color = isSelected
                ? PokeMapLegacyColors.white
                : PokeMapLegacyColors.orangeShade100,
        );
      }
    }
  }

  void _paintSelectedPlacedElementInstance(Canvas canvas) {
    final selectedId = selectedPlacedElementInstanceId?.trim();
    if (selectedId == null || selectedId.isEmpty) {
      return;
    }
    MapPlacedElement? selectedInstance;
    for (final instance in map.placedElements) {
      if (instance.id != selectedId) {
        continue;
      }
      selectedInstance = instance;
      break;
    }
    if (selectedInstance == null) {
      return;
    }
    TileLayer? selectedLayer;
    for (final layer in map.layers.whereType<TileLayer>()) {
      if (layer.id == selectedInstance.layerId) {
        selectedLayer = layer;
        break;
      }
    }
    if (selectedLayer == null ||
        !selectedLayer.isVisible ||
        selectedLayer.opacity <= 0 ||
        selectedInstance.opacity <= 0) {
      return;
    }
    if (selectedInstance.pos.x < 0 || selectedInstance.pos.y < 0) {
      return;
    }
    if (selectedInstance.pos.x >= map.size.width ||
        selectedInstance.pos.y >= map.size.height) {
      return;
    }
    final projectContext = project;
    if (projectContext == null) {
      return;
    }
    TilesetSourceRect? source;
    for (final entry in projectContext.elements) {
      if (entry.id == selectedInstance.elementId && entry.frames.isNotEmpty) {
        source = entityEditorPickFrame(
          entry.frames,
          effectiveAnimationMs,
        ).source;
        break;
      }
    }
    final width = source?.width ?? 1;
    final height = source?.height ?? 1;
    if (width <= 0 || height <= 0) {
      return;
    }
    final persistedTransform = QuarterTurnGridTransform(
      sourceSize: GridSize(width: width, height: height),
      quarterTurns: selectedInstance.quarterTurns,
    );
    final preview = placedElementRotationPreview;
    final destinationSize = preview?.instance?.id == selectedInstance.id &&
            preview?.previewFootprint != null
        ? preview!.previewFootprint!.destinationSize
        : persistedTransform.destinationSize;
    final rect = Rect.fromLTWH(
      selectedInstance.pos.x * tileWidth,
      selectedInstance.pos.y * tileHeight,
      destinationSize.width * tileWidth,
      destinationSize.height * tileHeight,
    );
    final fill = Paint()
      ..color = PokeMapLegacyColors.yellowAccent.withValues(alpha: 0.17)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = PokeMapLegacyColors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / zoom;
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  Rect _warpActivationRect(MapWarp warp) {
    final scaleX = sourceTileWidth > 0 ? tileWidth / sourceTileWidth : 1.0;
    final scaleY = sourceTileHeight > 0 ? tileHeight / sourceTileHeight : 1.0;
    final padding = warp.triggerPadding;
    final left = warp.pos.x * tileWidth - padding.left * scaleX;
    final top = warp.pos.y * tileHeight - padding.top * scaleY;
    final width = tileWidth + (padding.left + padding.right) * scaleX;
    final height = tileHeight + (padding.top + padding.bottom) * scaleY;
    return Rect.fromLTWH(left, top, width, height);
  }

  void _paintWarpApproachMarkers(
    Canvas canvas, {
    required Rect activationRect,
    required List<EntityFacing> allowedApproachFacings,
    required bool isSelected,
  }) {
    if (allowedApproachFacings.isEmpty) {
      return;
    }
    final markerPaint = Paint()
      ..color =
          (isSelected ? PokeMapLegacyColors.white : PokeMapLegacyColors.black)
              .withValues(alpha: isSelected ? 0.95 : 0.7)
      ..style = PaintingStyle.fill;
    final markerThickness = (1.8 / zoom).clamp(1.0, 3.0);
    final markerLength =
        ((tileWidth < tileHeight ? tileWidth : tileHeight) * 0.45)
            .clamp(6.0, 22.0);
    for (final facing in allowedApproachFacings) {
      Rect markerRect;
      switch (facing) {
        case EntityFacing.north:
          markerRect = Rect.fromCenter(
            center: Offset(activationRect.center.dx, activationRect.top),
            width: markerLength,
            height: markerThickness,
          );
          break;
        case EntityFacing.south:
          markerRect = Rect.fromCenter(
            center: Offset(activationRect.center.dx, activationRect.bottom),
            width: markerLength,
            height: markerThickness,
          );
          break;
        case EntityFacing.east:
          markerRect = Rect.fromCenter(
            center: Offset(activationRect.right, activationRect.center.dy),
            width: markerThickness,
            height: markerLength,
          );
          break;
        case EntityFacing.west:
          markerRect = Rect.fromCenter(
            center: Offset(activationRect.left, activationRect.center.dy),
            width: markerThickness,
            height: markerLength,
          );
          break;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          markerRect,
          Radius.circular(markerThickness),
        ),
        markerPaint,
      );
    }
  }

  void _paintEntities(
    Canvas canvas, {
    required bool foregroundPass,
  }) {
    if (map.entities.isEmpty) return;
    for (final entity in map.entities) {
      // Les entités "normales" restent entre fond et décor avant-plan.
      // Les props explicitement marqués "devant le décor" sont repeints après
      // la passe foreground pour coller au rendu runtime.
      if (!shouldPaintEditorEntityInForegroundPass(
        entity,
        foregroundPass: foregroundPass,
      )) {
        continue;
      }
      if (entity.pos.x < 0 ||
          entity.pos.y < 0 ||
          entity.pos.x >= map.size.width ||
          entity.pos.y >= map.size.height) {
        continue;
      }
      final isSelected = entity.id == selectedEntityId;
      final rect = Rect.fromLTWH(
        entity.pos.x * tileWidth,
        entity.pos.y * tileHeight,
        entity.size.width * tileWidth,
        entity.size.height * tileHeight,
      );
      final resolved = resolveEntityElementVisualForEditor(
        entity: entity,
        project: project,
        tilesetImagesById: tilesetImagesById,
        sourceTileWidth: sourceTileWidth,
        sourceTileHeight: sourceTileHeight,
        editorAnimationTimeMs: effectiveAnimationMs,
      );
      if (resolved != null) {
        if (showEntityEditorChrome) {
          final shade = RRect.fromRectAndRadius(
            rect,
            Radius.circular(5 / zoom),
          );
          canvas.drawRRect(
            shade,
            Paint()
              ..color = PokeMapLegacyColors.black
                  .withValues(alpha: isSelected ? 0.28 : 0.2)
              ..style = PaintingStyle.fill,
          );
        }
        _paintEntityProjectElementFrame(
          canvas,
          resolved.image,
          resolved.srcRect,
          rect,
        );
      } else {
        _paintEntityFallbackBody(canvas, entity, rect, isSelected);
      }
      if (showEntityEditorChrome) {
        _paintEntitySelectionAndChrome(canvas, entity, rect, isSelected);
      }
    }
  }

  void _paintMapEvents(Canvas canvas) {
    if (map.events.isEmpty) return;
    final layerVisibility = <String, bool>{
      for (final layer in map.layers) layer.id: layer.isVisible,
    };
    for (final event in map.events) {
      final x = event.position.x;
      final y = event.position.y;
      if (layerVisibility[event.position.layerId.trim()] != true) {
        continue;
      }
      if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
        continue;
      }
      final isSelected = event.id == selectedMapEventId;
      final rect = Rect.fromLTWH(
        x * tileWidth,
        y * tileHeight,
        tileWidth,
        tileHeight,
      );
      final fill = Paint()
        ..color = PokeMapLegacyColors.cyanTag.withValues(
          alpha: isSelected ? 0.4 : 0.26,
        )
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = isSelected
            ? PokeMapLegacyColors.white
            : PokeMapLegacyColors.cyanTag.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.2 / zoom : 1.4 / zoom;
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);

      final center = rect.center;
      final radius = (tileWidth < tileHeight ? tileWidth : tileHeight) * 0.17;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = isSelected
              ? PokeMapLegacyColors.white
              : PokeMapLegacyColors.deepCyanText,
      );

      if (rect.width < (34 / zoom) || rect.height < (20 / zoom)) {
        continue;
      }
      final title = event.title.trim();
      final label = title.isNotEmpty ? title : event.id;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: PokeMapLegacyColors.white,
            fontSize: 10 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: rect.width - (8 / zoom));
      if (textPainter.width <= 0 || textPainter.height <= 0) {
        continue;
      }
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (4 / zoom),
          rect.top + (3 / zoom),
        ),
      );
    }
  }

  void _paintEntityProjectElementFrame(
    Canvas canvas,
    ui.Image image,
    Rect src,
    Rect bounds,
  ) {
    if (src.width <= 0 || src.height <= 0) {
      return;
    }
    final srcAr = src.width / src.height;
    final bAr = bounds.width / bounds.height;
    late Rect dst;
    if (srcAr > bAr) {
      final w = bounds.width;
      final h = w / srcAr;
      dst = Rect.fromCenter(center: bounds.center, width: w, height: h);
    } else {
      final h = bounds.height;
      final w = h * srcAr;
      dst = Rect.fromCenter(center: bounds.center, width: w, height: h);
    }
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(5 / zoom)),
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  void _paintEntityFallbackBody(
    Canvas canvas,
    MapEntity entity,
    Rect rect,
    bool isSelected,
  ) {
    final color = _entityColor(entity.kind);
    final r = RRect.fromRectAndRadius(rect, Radius.circular(6 / zoom));
    canvas.drawRRect(
      r,
      Paint()
        ..color = color.withValues(alpha: isSelected ? 0.32 : 0.2)
        ..style = PaintingStyle.fill,
    );
    final letter = _entityFallbackGlyph(entity.kind);
    final fontSize = math.min(rect.width, rect.height) * 0.38;
    if (fontSize < 4 / zoom) {
      return;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: PokeMapLegacyColors.white.withValues(alpha: 0.92),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        rect.center.dx - tp.width / 2,
        rect.center.dy - tp.height / 2,
      ),
    );
  }

  String _entityFallbackGlyph(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'N',
      MapEntityKind.sign => 'S',
      MapEntityKind.item => 'I',
      MapEntityKind.spawn => 'P',
      MapEntityKind.custom => '+',
    };
  }

  void _paintEntitySelectionAndChrome(
    Canvas canvas,
    MapEntity entity,
    Rect rect,
    bool isSelected,
  ) {
    final color = _entityColor(entity.kind);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(5 / zoom)),
      Paint()
        ..color = (isSelected ? PokeMapLegacyColors.white : color)
            .withValues(alpha: isSelected ? 0.95 : 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.4 / zoom : 1.5 / zoom,
    );

    if (rect.width < (18 / zoom) || rect.height < (16 / zoom)) {
      return;
    }

    final badgeWidth = math.min(rect.width - (6 / zoom), 42 / zoom);
    final badgeRect = Rect.fromLTWH(
      rect.left + (3 / zoom),
      rect.top + (3 / zoom),
      badgeWidth,
      math.min(rect.height - (6 / zoom), 16 / zoom),
    );
    if (badgeRect.width <= 0 || badgeRect.height <= 0) {
      return;
    }

    final badge = RRect.fromRectAndRadius(
      badgeRect,
      Radius.circular(4 / zoom),
    );
    canvas.drawRRect(
      badge,
      Paint()
        ..color = PokeMapLegacyColors.black
            .withValues(alpha: isSelected ? 0.72 : 0.56)
        ..style = PaintingStyle.fill,
    );

    final badgeTextPainter = TextPainter(
      text: TextSpan(
        text: _entityShortLabel(entity.kind),
        style: TextStyle(
          color: PokeMapLegacyColors.white,
          fontSize: 9 / zoom,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: badgeRect.width - (6 / zoom));
    if (badgeTextPainter.width > 0 && badgeTextPainter.height > 0) {
      badgeTextPainter.paint(
        canvas,
        Offset(
          badgeRect.left + (3 / zoom),
          badgeRect.top + ((badgeRect.height - badgeTextPainter.height) / 2),
        ),
      );
    }

    if (rect.width < (44 / zoom) || rect.height < (28 / zoom)) {
      return;
    }

    final label = entity.inspectorHeadline;
    final labelTextPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: PokeMapLegacyColors.white,
          fontSize: 10 / zoom,
          fontWeight: FontWeight.w600,
          shadows: const [
            Shadow(
              offset: Offset(0.5, 0.5),
              blurRadius: 2,
              color: PokeMapLegacyColors.blackOverlayStrong,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: rect.width - (8 / zoom));
    if (labelTextPainter.width <= 0 || labelTextPainter.height <= 0) {
      return;
    }
    labelTextPainter.paint(
      canvas,
      Offset(
        rect.left + (4 / zoom),
        rect.bottom - labelTextPainter.height - (4 / zoom),
      ),
    );
  }

  void _paintTriggers(Canvas canvas) {
    if (map.triggers.isEmpty) return;
    for (final trigger in map.triggers) {
      final isSelected = trigger.id == selectedTriggerId;
      final left = trigger.area.pos.x * tileWidth;
      final top = trigger.area.pos.y * tileHeight;
      final width = trigger.area.size.width * tileWidth;
      final height = trigger.area.size.height * tileHeight;
      final rect = Rect.fromLTWH(left, top, width, height);
      final color = _triggerColor(trigger.type);

      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: isSelected ? 0.24 : 0.16)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = isSelected
              ? PokeMapLegacyColors.white
              : color.withValues(alpha: 0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 / zoom : 1.3 / zoom,
      );

      if (rect.width < (28 / zoom) || rect.height < (18 / zoom)) {
        continue;
      }
      final label = trigger.name.trim().isNotEmpty
          ? trigger.name.trim()
          : '${trigger.type.name}:${trigger.id}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: PokeMapLegacyColors.white,
            fontSize: 10 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: rect.width - (8 / zoom));
      if (textPainter.width <= 0 || textPainter.height <= 0) {
        continue;
      }
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (4 / zoom),
          rect.top + (3 / zoom),
        ),
      );
    }
  }

  void _paintConnections(
    Canvas canvas,
    double gridWidth,
    double gridHeight,
  ) {
    if (map.connections.isEmpty) {
      return;
    }
    for (final connection in map.connections) {
      final badgeRect = _connectionBadgeRect(
        connection.direction,
        gridWidth,
        gridHeight,
      );
      final fillPaint = Paint()
        ..color = PokeMapLegacyColors.darkLabelPlate.withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = PokeMapLegacyColors.cyanAccent.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 / zoom;
      final badge = RRect.fromRectAndRadius(
        badgeRect,
        Radius.circular(6 / zoom),
      );
      canvas.drawRRect(badge, fillPaint);
      canvas.drawRRect(badge, borderPaint);

      final label = connectionLabelsByDirection[connection.direction] ??
          connection.targetMapId;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${_directionShortLabel(connection.direction)}  $label',
          style: TextStyle(
            color: PokeMapLegacyColors.white,
            fontSize: 11 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: badgeRect.width - (12 / zoom));
      final textOffset = Offset(
        badgeRect.left + ((badgeRect.width - textPainter.width) / 2),
        badgeRect.top + ((badgeRect.height - textPainter.height) / 2),
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  Rect _connectionBadgeRect(
    MapConnectionDirection direction,
    double gridWidth,
    double gridHeight,
  ) {
    final inset = 8 / zoom;
    final shortSide = 22 / zoom;
    final badgeWidth = math.max(
      52 / zoom,
      math.min(gridWidth - (inset * 2), 168 / zoom),
    );
    return switch (direction) {
      MapConnectionDirection.north => Rect.fromLTWH(
          (gridWidth - badgeWidth) / 2,
          inset,
          badgeWidth,
          shortSide,
        ),
      MapConnectionDirection.south => Rect.fromLTWH(
          (gridWidth - badgeWidth) / 2,
          gridHeight - inset - shortSide,
          badgeWidth,
          shortSide,
        ),
      MapConnectionDirection.east => Rect.fromLTWH(
          gridWidth - inset - badgeWidth,
          (gridHeight / 2) - shortSide - (2 / zoom),
          badgeWidth,
          shortSide,
        ),
      MapConnectionDirection.west => Rect.fromLTWH(
          inset,
          (gridHeight / 2) - shortSide - (2 / zoom),
          badgeWidth,
          shortSide,
        ),
    };
  }

  String _directionShortLabel(MapConnectionDirection direction) {
    return switch (direction) {
      MapConnectionDirection.north => 'N',
      MapConnectionDirection.south => 'S',
      MapConnectionDirection.east => 'E',
      MapConnectionDirection.west => 'W',
    };
  }

  void _paintToolPreview(Canvas canvas) {
    final preview = toolPreview;
    if (preview == null) return;
    if (preview.mode == MapToolPreviewMode.paint) {
      _paintPaintPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.elementPlacement) {
      _paintElementPlacementPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.erase) {
      _paintErasePreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.terrainPaint) {
      _paintTerrainPaintPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.terrainErase) {
      _paintTerrainErasePreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.pathPaint) {
      _paintPathPaintPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.pathErase) {
      _paintPathErasePreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.collisionPaint) {
      _paintCollisionPaintPreview(canvas, preview);
      return;
    }
    _paintCollisionErasePreview(canvas, preview);
  }

  void _paintElementPlacementPreview(
    Canvas canvas,
    MapToolPreview preview,
  ) {
    final elementId = preview.elementId;
    final layerId = activeLayerId;
    final projectContext = project;
    if (elementId == null || layerId == null || projectContext == null) return;
    final elementById = <String, ProjectElementEntry>{
      for (final entry in projectContext.elements) entry.id: entry,
    };
    final placed = MapPlacedElement(
      id: '__placement_preview__',
      layerId: layerId,
      elementId: elementId,
      pos: preview.origin,
      applyCollision: false,
    );
    final isValid = preview.validity == MapToolPreviewValidity.valid;
    final previewColor =
        isValid ? rotationPreviewAcceptedColor : rotationPreviewRejectedColor;
    _paintPlacedElement(
      canvas,
      placed,
      elementById: elementById,
      renderPass: _EditorMapTileRenderPass.foreground,
      opacity: isValid ? 0.6 : 0.3,
      ignoreRenderPassSplit: true,
    );
    if (previewColor == null) return;
    _paintPlacedElementFootprintHint(
      canvas,
      placed,
      elementById: elementById,
      color: previewColor,
      fillAlpha: isValid ? 0.08 : 0.18,
      strokeAlpha: 0.95,
    );
  }

  void _paintPaintPreview(Canvas canvas, MapToolPreview preview) {
    final tiles = preview.tiles;
    if (tiles == null) return;
    if (sourceTileWidth > 0 && sourceTileHeight > 0) {
      final alpha =
          preview.validity == MapToolPreviewValidity.valid ? 0.6 : 0.3;
      final tilePaint = Paint()
        ..color = PokeMapLegacyColors.white.withValues(alpha: alpha);
      final sources = <String, ProjectTilesetSource?>{
        for (final tileset
            in project?.tilesets ?? const <ProjectTilesetEntry>[])
          tileset.id: tileset.source,
      };
      for (var y = 0; y < preview.size.height; y++) {
        for (var x = 0; x < preview.size.width; x++) {
          final mapX = preview.origin.x + x;
          final mapY = preview.origin.y + y;
          if (mapX < 0 ||
              mapY < 0 ||
              mapX >= map.size.width ||
              mapY >= map.size.height) {
            continue;
          }
          final patternIndex = y * preview.size.width + x;
          if (patternIndex < 0 || patternIndex >= tiles.length) continue;
          final entry = tiles[patternIndex];
          if (entry == null) continue;
          final source = sources[entry.tilesetId];
          if (source == null) {
            final image = tilesetImagesById[entry.tilesetId];
            final tilesPerRow = tilesPerRowById[entry.tilesetId] ?? 0;
            if (image == null || tilesPerRow <= 0) continue;
            final sourceX = (entry.localTileId % tilesPerRow) * sourceTileWidth;
            final sourceY =
                (entry.localTileId ~/ tilesPerRow) * sourceTileHeight;
            final sourceRect = Rect.fromLTWH(
              sourceX.toDouble(),
              sourceY.toDouble(),
              sourceTileWidth.toDouble(),
              sourceTileHeight.toDouble(),
            );
            if (!_editorImageContainsRect(image, sourceRect)) continue;
            _drawTileLayerImage(
              canvas: canvas,
              image: image,
              sourceRect: sourceRect,
              destinationRect: Rect.fromLTWH(
                mapX * tileWidth,
                mapY * tileHeight,
                tileWidth,
                tileHeight,
              ),
              transform: entry.transform,
              paint: tilePaint,
            );
            continue;
          }
          final visual = _resolveTileLayerVisual(entry, source);
          if (visual == null) continue;
          final scaleX = tileWidth / sourceTileWidth;
          final scaleY = tileHeight / sourceTileHeight;
          for (final slice in visual.frameAt(effectiveAnimationMs).slices) {
            final image = tilesetImagesById[slice.assetId] ??
                tilesetImagesById[entry.tilesetId];
            if (image == null) continue;
            final sourceRect = Rect.fromLTWH(
              slice.sourceRect.x.toDouble(),
              slice.sourceRect.y.toDouble(),
              slice.sourceRect.width.toDouble(),
              slice.sourceRect.height.toDouble(),
            );
            if (!_editorImageContainsRect(image, sourceRect)) continue;
            final destination = slice.destinationRect;
            _drawTileLayerImage(
              canvas: canvas,
              image: image,
              sourceRect: sourceRect,
              destinationRect: Rect.fromLTWH(
                mapX * tileWidth + destination.x * scaleX,
                mapY * tileHeight + destination.y * scaleY,
                destination.width * scaleX,
                destination.height * scaleY,
              ),
              transform: entry.transform,
              paint: tilePaint,
            );
          }
        }
      }
    }

    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    if (preview.validity == MapToolPreviewValidity.invalid) {
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = PokeMapLegacyColors.redAccent.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = PokeMapLegacyColors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 / zoom,
      );
      return;
    }
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / zoom,
    );
  }

  void _paintErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.redAccent.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.redAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintCollisionPaintPreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.orangeAccent.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.orangeAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintTerrainPaintPreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    final terrainColor = _terrainColor(preview.terrain ?? TerrainType.grass);
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = terrainColor.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = terrainColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintPathPaintPreview(Canvas canvas, MapToolPreview preview) {
    if (preview.cells case final cells? when cells.isNotEmpty) {
      for (final cell in cells) {
        _paintPathPaintPreview(
          canvas,
          MapToolPreview.pathPaint(
            origin: cell,
            size: const GridSize(width: 1, height: 1),
            validity: preview.validity,
          ),
        );
      }
      return;
    }
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.tealAccent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.tealAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintTerrainErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.blueGrey.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.blueGreyShade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintPathErasePreview(Canvas canvas, MapToolPreview preview) {
    if (preview.cells case final cells? when cells.isNotEmpty) {
      for (final cell in cells) {
        _paintPathErasePreview(
          canvas,
          MapToolPreview.pathErase(
            origin: cell,
            size: const GridSize(width: 1, height: 1),
            validity: preview.validity,
          ),
        );
      }
      return;
    }
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.cyanAccent.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintCollisionErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.lightBlueAccent.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = PokeMapLegacyColors.lightBlueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  Rect? _computePreviewRect(GridPos origin, GridSize size) {
    final left = origin.x.clamp(0, map.size.width);
    final top = origin.y.clamp(0, map.size.height);
    final right = (origin.x + size.width).clamp(0, map.size.width);
    final bottom = (origin.y + size.height).clamp(0, map.size.height);
    if (right <= left || bottom <= top) return null;
    return Rect.fromLTWH(
      left * tileWidth,
      top * tileHeight,
      (right - left) * tileWidth,
      (bottom - top) * tileHeight,
    );
  }

  void _paintTileLayer(
    Canvas canvas,
    TileLayer layer, {
    required _EditorMapTileRenderPass renderPass,
    required Map<String, Set<int>> foregroundTileCellIndicesByLayerId,
    required EditorMapVisibleCellBounds visibleBounds,
    required List<MapPlacedElement> visiblePlacedElements,
    required _MapGridCullingDebugCounter? cullingCounter,
  }) {
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return;
    }
    final placedElementTileMask = _matchingPlacedElementTileIndicesForLayer(
      layer: layer,
      placedElements: visiblePlacedElements,
    );
    final sources = <String, ProjectTilesetSource?>{
      for (final tileset in project?.tilesets ?? const <ProjectTilesetEntry>[])
        tileset.id: tileset.source,
    };
    final visualByEntry =
        <TileLayerPaletteEntry, ProjectTilesetVisualResolution?>{};

    final explicitForeground = _isExplicitForegroundTileLayerForEditor(
      layerId: layer.id,
      layerName: layer.name,
    );
    final foregroundCells = foregroundTileCellIndicesByLayerId[layer.id];
    final shouldRenderThisLayer =
        renderPass == _EditorMapTileRenderPass.background
            ? !explicitForeground ||
                (foregroundCells != null && foregroundCells.isNotEmpty)
            : explicitForeground ||
                (foregroundCells != null && foregroundCells.isNotEmpty);
    if (!shouldRenderThisLayer) {
      return;
    }

    final layerPaint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    if (layer.opacity < 1) {
      layerPaint.color = PokeMapLegacyColors.white.withValues(
        alpha: layer.opacity.clamp(0.0, 1.0),
      );
    }

    cullingCounter?.tileCellVisits += visibleBounds.cellCount;
    for (var y = visibleBounds.top; y < visibleBounds.bottom; y++) {
      final rowStart = y * map.size.width;
      for (var x = visibleBounds.left; x < visibleBounds.right; x++) {
        final tileIndex = rowStart + x;
        final entry = resolveTileLayerCell(layer, tileIndex);
        if (entry == null) continue;
        if (placedElementTileMask.contains(tileIndex)) continue;
        final shouldDrawCell = shouldPaintEditorTileCellInRenderPass(
          explicitForeground: explicitForeground,
          isForegroundCell: foregroundCells?.contains(tileIndex) ?? false,
          foregroundPass: renderPass == _EditorMapTileRenderPass.foreground,
        );
        if (!shouldDrawCell) {
          continue;
        }

        final source = sources[entry.tilesetId];
        if (source == null) {
          final image = tilesetImagesById[entry.tilesetId];
          final tilesPerRow = tilesPerRowById[entry.tilesetId] ?? 0;
          if (image == null || tilesPerRow <= 0) continue;
          final sourceX = (entry.localTileId % tilesPerRow) * sourceTileWidth;
          final sourceY = (entry.localTileId ~/ tilesPerRow) * sourceTileHeight;
          final srcRect = Rect.fromLTWH(
            sourceX.toDouble(),
            sourceY.toDouble(),
            sourceTileWidth.toDouble(),
            sourceTileHeight.toDouble(),
          );
          if (!_editorImageContainsRect(image, srcRect)) continue;
          _drawTileLayerImage(
            canvas: canvas,
            image: image,
            sourceRect: srcRect,
            destinationRect: Rect.fromLTWH(
              x * tileWidth,
              y * tileHeight,
              tileWidth,
              tileHeight,
            ),
            transform: entry.transform,
            paint: layerPaint,
          );
          continue;
        }
        final visual = visualByEntry.putIfAbsent(
          entry,
          () => _resolveTileLayerVisual(entry, source),
        );
        if (visual == null) continue;
        final scaleX = tileWidth / sourceTileWidth;
        final scaleY = tileHeight / sourceTileHeight;
        for (final slice in visual.frameAt(effectiveAnimationMs).slices) {
          final image = tilesetImagesById[slice.assetId] ??
              tilesetImagesById[entry.tilesetId];
          if (image == null) continue;
          final sourceRect = Rect.fromLTWH(
            slice.sourceRect.x.toDouble(),
            slice.sourceRect.y.toDouble(),
            slice.sourceRect.width.toDouble(),
            slice.sourceRect.height.toDouble(),
          );
          if (!_editorImageContainsRect(image, sourceRect)) continue;
          final destination = slice.destinationRect;
          _drawTileLayerImage(
            canvas: canvas,
            image: image,
            sourceRect: sourceRect,
            destinationRect: Rect.fromLTWH(
              x * tileWidth + destination.x * scaleX,
              y * tileHeight + destination.y * scaleY,
              destination.width * scaleX,
              destination.height * scaleY,
            ),
            transform: entry.transform,
            paint: layerPaint,
          );
        }
      }
    }
  }

  void _paintObjectLayer(
    Canvas canvas,
    ObjectLayer layer, {
    required EditorMapVisibleCellBounds visibleBounds,
    required _MapGridCullingDebugCounter? cullingCounter,
  }) {
    final sources = <String, ProjectTilesetSource>{
      for (final tileset in project?.tilesets ?? const <ProjectTilesetEntry>[])
        if (tileset.source case final source?) tileset.id: source,
    };
    late final MapPlacedTileVisualIndex index;
    try {
      final cached = _editorObjectVisualIndexCache[layer];
      if (cached != null &&
          identical(cached.project, project) &&
          cached.sourceTileWidth == sourceTileWidth &&
          cached.sourceTileHeight == sourceTileHeight &&
          cached.tileWidth == tileWidth &&
          cached.tileHeight == tileHeight) {
        index = cached.index;
      } else {
        index = MapPlacedTileVisualIndex.build(
          layer: layer,
          tilesetsById: sources,
          sourceCellWidth: sourceTileWidth,
          sourceCellHeight: sourceTileHeight,
          destinationCellWidth: tileWidth,
          destinationCellHeight: tileHeight,
        );
        _editorObjectVisualIndexCache[layer] = _EditorObjectVisualIndexCache(
          project: project,
          sourceTileWidth: sourceTileWidth,
          sourceTileHeight: sourceTileHeight,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          index: index,
        );
      }
    } on MapPlacedTileVisualResolutionException {
      return;
    }
    final batch = index.resolve(
      elapsedMs: effectiveAnimationMs,
      viewport: SmartTileGeometryRect(
        left: visibleBounds.left * tileWidth,
        top: visibleBounds.top * tileHeight,
        width: visibleBounds.width * tileWidth,
        height: visibleBounds.height * tileHeight,
      ),
    );
    final visuals = batch.visuals;
    cullingCounter
      ?..objectTileCandidateVisits += batch.work.candidateObjectVisits
      ..objectIndices.add(index);
    for (final visual in visuals) {
      final image = tilesetImagesById[visual.assetId] ??
          tilesetImagesById[visual.tilesetId];
      if (image == null) continue;
      final source = visual.sourceRect;
      final sourceRect = Rect.fromLTWH(
        source.x.toDouble(),
        source.y.toDouble(),
        source.width.toDouble(),
        source.height.toDouble(),
      );
      if (!_editorImageContainsRect(image, sourceRect)) continue;
      final destination = visual.destinationRect;
      _drawTileLayerImage(
        canvas: canvas,
        image: image,
        sourceRect: sourceRect,
        destinationRect: Rect.fromLTWH(
          destination.left,
          destination.top,
          destination.width,
          destination.height,
        ),
        transform: visual.transform,
        paint: Paint()
          ..isAntiAlias = false
          ..filterQuality = FilterQuality.none
          ..color = PokeMapLegacyColors.white.withValues(alpha: visual.opacity),
      );
    }
  }

  ProjectTilesetVisualResolution? _resolveTileLayerVisual(
    TileLayerPaletteEntry entry,
    ProjectTilesetSource source,
  ) {
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
    if (selection == null) return null;
    try {
      return const ProjectTilesetVisualResolver().resolve(
        source: source,
        selection: selection,
        cellWidth: sourceTileWidth,
        cellHeight: sourceTileHeight,
      );
    } on ProjectTilesetVisualResolutionException {
      return null;
    }
  }

  bool _editorImageContainsRect(ui.Image image, Rect rect) =>
      rect.left >= 0 &&
      rect.top >= 0 &&
      rect.width > 0 &&
      rect.height > 0 &&
      rect.right <= image.width &&
      rect.bottom <= image.height;

  void _drawTileLayerImage({
    required Canvas canvas,
    required ui.Image image,
    required Rect sourceRect,
    required Rect destinationRect,
    required SmartTileSpriteTransform transform,
    required Paint paint,
  }) {
    canvas.save();
    try {
      canvas.translate(destinationRect.left, destinationRect.top);
      switch (transform.quarterTurns) {
        case 0:
          break;
        case 1:
          canvas.translate(destinationRect.height, 0);
          canvas.rotate(math.pi / 2);
        case 2:
          canvas.translate(destinationRect.width, destinationRect.height);
          canvas.rotate(math.pi);
        case 3:
          canvas.translate(0, destinationRect.width);
          canvas.rotate(3 * math.pi / 2);
      }
      if (transform.flipX) {
        canvas.translate(destinationRect.width, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(
        image,
        sourceRect,
        Rect.fromLTWH(0, 0, destinationRect.width, destinationRect.height),
        paint,
      );
    } finally {
      canvas.restore();
    }
  }

  Set<int> _matchingPlacedElementTileIndicesForLayer({
    required TileLayer layer,
    required List<MapPlacedElement> placedElements,
  }) {
    final projectContext = project;
    if (projectContext == null || map.placedElements.isEmpty) {
      return const <int>{};
    }
    final elementById = <String, ProjectElementEntry>{
      for (final entry in projectContext.elements) entry.id: entry,
    };
    if (elementById.isEmpty) {
      return const <int>{};
    }
    final layerId = layer.id.trim();
    final out = <int>{};
    for (final instance in placedElements) {
      if (instance.layerId.trim() != layerId) {
        continue;
      }
      final entry = elementById[instance.elementId.trim()];
      if (entry == null || entry.frames.isEmpty) {
        continue;
      }
      final frame = entityEditorPickFrame(
        entry.frames,
        effectiveAnimationMs,
      );
      final tilesetId = frame.tilesetId.trim().isNotEmpty
          ? frame.tilesetId.trim()
          : entry.tilesetId.trim();
      final tilesPerRow = tilesPerRowById[tilesetId] ?? 0;
      if (tilesPerRow <= 0) continue;
      final source = frame.source;
      final width = source.width <= 0 ? 1 : source.width;
      final height = source.height <= 0 ? 1 : source.height;
      final transform = QuarterTurnGridTransform(
        sourceSize: GridSize(width: width, height: height),
        quarterTurns: instance.quarterTurns,
      );
      for (var localY = 0; localY < height; localY++) {
        for (var localX = 0; localX < width; localX++) {
          final destination = transform.sourceToDestination(
            GridPos(x: localX, y: localY),
          );
          final x = instance.pos.x + destination.x;
          final y = instance.pos.y + destination.y;
          if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
            continue;
          }
          final tileIndex = y * map.size.width + x;
          final tile = resolveTileLayerCell(layer, tileIndex);
          if (tile == null || tile.tilesetId != tilesetId) continue;
          final sourceTileId =
              (source.y + localY) * tilesPerRow + source.x + localX;
          if (tile.localTileId == sourceTileId) {
            out.add(tileIndex);
          }
        }
      }
    }
    return out;
  }

  void _paintPlacedElementsForLayer(
    Canvas canvas,
    TileLayer layer, {
    required _EditorMapTileRenderPass renderPass,
    required List<MapPlacedElement> visiblePlacedElements,
    required _MapGridCullingDebugCounter? cullingCounter,
  }) {
    final projectContext = project;
    if (projectContext == null || map.placedElements.isEmpty) {
      return;
    }
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return;
    }
    final elementById = <String, ProjectElementEntry>{
      for (final entry in projectContext.elements) entry.id: entry,
    };
    if (elementById.isEmpty) {
      return;
    }
    final explicitForeground = _isExplicitForegroundTileLayerForEditor(
      layerId: layer.id,
      layerName: layer.name,
    );
    if (explicitForeground &&
        renderPass == _EditorMapTileRenderPass.background) {
      return;
    }
    final layerId = layer.id.trim();
    for (final instance in visiblePlacedElements) {
      if (instance.layerId.trim() != layerId) {
        continue;
      }
      cullingCounter?.placedElementPassVisits += 1;
      _paintPlacedElement(
        canvas,
        instance,
        elementById: elementById,
        renderPass: renderPass,
        opacity: layer.opacity,
        highlight: instance.id == environmentGeneratedDeletePreviewId,
        // Une couche explicitement au premier plan possède tout le visuel de
        // ses instances. Les autres couches conservent le split historique
        // collision/facade, indispensable aux tables et arbres multi-cellules.
        ignoreRenderPassSplit: explicitForeground,
      );
    }
  }

  void _paintPlacedElement(
    Canvas canvas,
    MapPlacedElement instance, {
    required Map<String, ProjectElementEntry> elementById,
    required _EditorMapTileRenderPass renderPass,
    double opacity = 1,
    bool highlight = false,
    bool ignoreRenderPassSplit = false,
  }) {
    final entry = elementById[instance.elementId.trim()];
    if (entry == null || entry.frames.isEmpty) {
      return;
    }
    final frame = entityEditorPickFrame(
      entry.frames,
      effectiveAnimationMs,
    );
    final tilesetId = frame.tilesetId.trim().isNotEmpty
        ? frame.tilesetId.trim()
        : entry.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return;
    }
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null) {
      return;
    }

    final source = frame.source;
    final width = source.width <= 0 ? 1 : source.width;
    final height = source.height <= 0 ? 1 : source.height;
    final transform = QuarterTurnGridTransform(
      sourceSize: GridSize(width: width, height: height),
      quarterTurns: instance.quarterTurns,
    );
    final resolvedOpacity =
        (opacity * instance.opacity).clamp(0.0, 1.0).toDouble();

    for (var localY = 0; localY < height; localY++) {
      for (var localX = 0; localX < width; localX++) {
        if (!ignoreRenderPassSplit &&
            !_shouldPaintPlacedElementCellInRenderPass(
              instance: instance,
              entry: entry,
              localX: localX,
              localY: localY,
              foregroundPass: renderPass == _EditorMapTileRenderPass.foreground,
            )) {
          continue;
        }

        final destination = transform.sourceToDestination(
          GridPos(x: localX, y: localY),
        );
        final x = instance.pos.x + destination.x;
        final y = instance.pos.y + destination.y;
        if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
          continue;
        }

        final sourceX = (source.x + localX) * sourceTileWidth;
        final sourceY = (source.y + localY) * sourceTileHeight;
        if (sourceX < 0 ||
            sourceY < 0 ||
            sourceX + sourceTileWidth > tilesetImage.width ||
            sourceY + sourceTileHeight > tilesetImage.height) {
          continue;
        }

        final srcRect = Rect.fromLTWH(
          sourceX.toDouble(),
          sourceY.toDouble(),
          sourceTileWidth.toDouble(),
          sourceTileHeight.toDouble(),
        );
        final dstRect = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        _drawPlacedElementImageRect(
          canvas,
          tilesetImage,
          srcRect,
          dstRect,
          opacity: resolvedOpacity,
          highlight: highlight,
          quarterTurns: transform.quarterTurns,
        );
      }
    }
  }

  void _drawPlacedElementImageRect(
    Canvas canvas,
    ui.Image image,
    Rect srcRect,
    Rect dstRect, {
    required double opacity,
    bool highlight = false,
    required int quarterTurns,
  }) {
    if (opacity >= 1) {
      _drawQuarterTurnImageRect(
        canvas,
        image,
        srcRect,
        dstRect,
        quarterTurns: quarterTurns,
        paint: Paint(),
      );
      if (highlight) {
        _drawQuarterTurnImageRect(
          canvas,
          image,
          srcRect,
          dstRect,
          quarterTurns: quarterTurns,
          paint: Paint()
            ..colorFilter = ui.ColorFilter.mode(
              PokeMapLegacyColors.white.withValues(alpha: 0.45),
              ui.BlendMode.srcATop,
            ),
        );
      }
      return;
    }
    canvas.saveLayer(
      dstRect,
      Paint()..color = PokeMapLegacyColors.white.withValues(alpha: opacity),
    );
    _drawQuarterTurnImageRect(
      canvas,
      image,
      srcRect,
      dstRect,
      quarterTurns: quarterTurns,
      paint: Paint(),
    );
    if (highlight) {
      _drawQuarterTurnImageRect(
        canvas,
        image,
        srcRect,
        dstRect,
        quarterTurns: quarterTurns,
        paint: Paint()
          ..colorFilter = ui.ColorFilter.mode(
            PokeMapLegacyColors.white.withValues(alpha: 0.45),
            ui.BlendMode.srcATop,
          ),
      );
    }
    canvas.restore();
  }

  void _drawQuarterTurnImageRect(
    Canvas canvas,
    ui.Image image,
    Rect srcRect,
    Rect dstRect, {
    required int quarterTurns,
    required Paint paint,
  }) {
    paint
      ..isAntiAlias = false
      ..filterQuality = ui.FilterQuality.none;
    if (quarterTurns == 0) {
      canvas.drawImageRect(image, srcRect, dstRect, paint);
      return;
    }
    canvas.save();
    canvas.clipRect(dstRect);
    canvas.translate(dstRect.center.dx, dstRect.center.dy);
    canvas.rotate(quarterTurns * math.pi / 2);
    final normalizedDestination = Rect.fromCenter(
      center: Offset.zero,
      width: quarterTurns.isOdd ? dstRect.height : dstRect.width,
      height: quarterTurns.isOdd ? dstRect.width : dstRect.height,
    );
    canvas.drawImageRect(image, srcRect, normalizedDestination, paint);
    canvas.restore();
  }

  void _paintEnvironmentGeneratedAddPreview(Canvas canvas) {
    final preview = environmentGeneratedAddPreview;
    final projectContext = project;
    if (preview == null || projectContext == null) return;
    final placed = preview.placed;
    final elementById = <String, ProjectElementEntry>{
      for (final entry in projectContext.elements) entry.id: entry,
    };
    _paintPlacedElement(
      canvas,
      placed,
      elementById: elementById,
      renderPass: _EditorMapTileRenderPass.foreground,
      opacity: preview.isValid ? 0.52 : 0.34,
      ignoreRenderPassSplit: true,
    );
    _paintPlacedElementFootprintHint(
      canvas,
      placed,
      elementById: elementById,
      color: preview.isValid
          ? PokeMapLegacyColors.cyanAccent
          : PokeMapLegacyColors.deepOrangeAccent,
      fillAlpha: preview.isValid ? 0.08 : 0.14,
      strokeAlpha: 0.95,
    );
  }

  void _paintPlacedElementRotationPreview(Canvas canvas) {
    final preview = placedElementRotationPreview;
    final instance = preview?.instance;
    final footprint = preview?.previewFootprint;
    final projectContext = project;
    if (preview == null ||
        instance == null ||
        footprint == null ||
        projectContext == null) {
      return;
    }
    final elementById = <String, ProjectElementEntry>{
      for (final entry in projectContext.elements) entry.id: entry,
    };
    final projected = instance.copyWith(
      quarterTurns: footprint.quarterTurns,
    );
    final previewColor = preview.rejection == null
        ? rotationPreviewAcceptedColor
        : rotationPreviewRejectedColor;
    _paintPlacedElement(
      canvas,
      projected,
      elementById: elementById,
      renderPass: _EditorMapTileRenderPass.foreground,
      opacity: preview.rejection == null ? 0.52 : 0.34,
      ignoreRenderPassSplit: true,
    );
    if (previewColor == null) return;
    _paintPlacedElementFootprintHint(
      canvas,
      projected,
      elementById: elementById,
      color: previewColor,
      fillAlpha: preview.rejection == null ? 0.08 : 0.14,
      strokeAlpha: 0.95,
    );
  }

  void _paintPlacedElementFootprintHint(
    Canvas canvas,
    MapPlacedElement instance, {
    required Map<String, ProjectElementEntry> elementById,
    required Color color,
    required double fillAlpha,
    required double strokeAlpha,
  }) {
    final entry = elementById[instance.elementId.trim()];
    final destinationSize = entry == null
        ? const GridSize(width: 1, height: 1)
        : resolveMapPlacedElementFootprint(
            instance: instance,
            element: entry,
          ).destinationSize;
    final rect = Rect.fromLTWH(
      instance.pos.x * tileWidth,
      instance.pos.y * tileHeight,
      destinationSize.width * tileWidth,
      destinationSize.height * tileHeight,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: fillAlpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: strokeAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  bool _shouldPaintPlacedElementCellInRenderPass({
    required MapPlacedElement instance,
    required ProjectElementEntry entry,
    required int localX,
    required int localY,
    required bool foregroundPass,
  }) {
    final collisionCells =
        instance.applyCollision ? entry.collisionProfile?.cells : null;
    if (collisionCells == null || collisionCells.isEmpty) {
      return !foregroundPass;
    }
    var isCollisionCell = false;
    for (final cell in collisionCells) {
      if (cell.x == localX && cell.y == localY) {
        isCollisionCell = true;
        break;
      }
    }
    return foregroundPass ? !isCollisionCell : isCollisionCell;
  }

  void _paintCollisionLayer(
    Canvas canvas,
    CollisionLayer layer, {
    required bool isActive,
    required EditorMapVisibleCellBounds visibleBounds,
    required _MapGridCullingDebugCounter? cullingCounter,
  }) {
    if (layer.collisions.isEmpty) return;
    final fillAlpha = (isActive ? 0.34 : 0.24) * layer.opacity;
    final borderAlpha = (isActive ? 0.75 : 0.5) * layer.opacity;
    final fillPaint = Paint()
      ..color = PokeMapLegacyColors.deepOrange.withValues(alpha: fillAlpha)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color =
          PokeMapLegacyColors.deepOrangeAccent.withValues(alpha: borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / zoom;

    cullingCounter?.collisionCellVisits += visibleBounds.cellCount;
    for (var y = visibleBounds.top; y < visibleBounds.bottom; y++) {
      final rowStart = y * map.size.width;
      for (var x = visibleBounds.left; x < visibleBounds.right; x++) {
        final index = rowStart + x;
        if (index < 0 || index >= layer.collisions.length) continue;
        if (!layer.collisions[index]) continue;
        final cell = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.drawRect(cell, fillPaint);
        canvas.drawRect(cell, borderPaint);
      }
    }
  }

  void _paintSmartTileLayer(
    Canvas canvas,
    SmartTileLayer layer, {
    required SmartTileVisualPass pass,
    required EditorMapVisibleCellBounds visibleBounds,
    _MapGridCullingDebugCounter? cullingCounter,
  }) {
    final catalog = project?.smartTileCatalog;
    if (catalog == null || catalog.isEmpty) return;
    final cachedIndex = _editorPatternOwnerIndexCache[layer];
    final patternIndex = cachedIndex != null &&
            identical(cachedIndex.catalog, catalog) &&
            cachedIndex.mapWidth == map.size.width &&
            cachedIndex.mapHeight == map.size.height
        ? cachedIndex.index
        : SmartTilePatternOwnerIndex.build(
            map: map,
            layer: layer,
            catalog: catalog,
          );
    if (!identical(patternIndex, cachedIndex?.index)) {
      _editorPatternOwnerIndexCache[layer] = _EditorPatternOwnerIndexCache(
        catalog: catalog,
        mapWidth: map.size.width,
        mapHeight: map.size.height,
        index: patternIndex,
      );
    }
    final batch = resolveSmartTileLayerVisualBatch(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: pass,
      elapsedMs: effectiveAnimationMs,
      startX: visibleBounds.left,
      startY: visibleBounds.top,
      endX: visibleBounds.right,
      endY: visibleBounds.bottom,
      destinationCellWidth: tileWidth,
      destinationCellHeight: tileHeight,
      sourceCellWidth:
          sourceTileWidth > 0 ? sourceTileWidth.toDouble() : tileWidth,
      sourceCellHeight:
          sourceTileHeight > 0 ? sourceTileHeight.toDouble() : tileHeight,
      patternOwnerIndex: patternIndex,
    );
    final visuals = batch.visuals;
    cullingCounter?.smartTileVisualVisits += visuals.length;
    cullingCounter?.smartTileOwnerCellVisits += batch.work.ownerCellVisits;
    cullingCounter?.smartTilePatternStrokeCellVisits +=
        batch.work.patternStrokeCellVisits;
    cullingCounter?.patternIndices.add(patternIndex);
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..color = PokeMapLegacyColors.white.withValues(
        alpha: layer.opacity.clamp(0.0, 1.0),
      );
    paintSmartTileVisuals(
      canvas,
      visuals: visuals,
      tilesetImagesById: tilesetImagesById,
      paint: paint,
    );
  }

  Color _terrainColor(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.none => PokeMapLegacyColors.transparent,
      TerrainType.grass => PokeMapLegacyColors.lightGreenAccent,
      TerrainType.dirt => PokeMapLegacyColors.terrainDirt,
      TerrainType.sand => PokeMapLegacyColors.amberAccent,
      TerrainType.rock => PokeMapLegacyColors.blueGrey,
      TerrainType.stone => PokeMapLegacyColors.grey,
      TerrainType.indoor => PokeMapLegacyColors.terrainIndoor,
    };
  }

  void _paintGameplayZones(Canvas canvas) {
    // Fantôme de tracé en cours
    final draft = gameplayZoneDraftArea;
    if (draft != null) {
      final draftRect = Rect.fromLTWH(
        draft.pos.x * tileWidth,
        draft.pos.y * tileHeight,
        draft.size.width * tileWidth,
        draft.size.height * tileHeight,
      );
      canvas.drawRect(
        draftRect,
        Paint()
          ..color =
              PokeMapLegacyColors.gameplayEncounter.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        draftRect,
        Paint()
          ..color =
              PokeMapLegacyColors.gameplayEncounter.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 / zoom
          ..strokeCap = StrokeCap.round,
      );
    }

    if (gameplayZones.isEmpty) return;
    for (final zone in gameplayZones) {
      final isSelected = zone.id == selectedGameplayZoneId;
      final left = zone.area.pos.x * tileWidth;
      final top = zone.area.pos.y * tileHeight;
      final width = zone.area.size.width * tileWidth;
      final height = zone.area.size.height * tileHeight;
      final rect = Rect.fromLTWH(left, top, width, height);
      final color = _gameplayZoneColor(zone.kind);

      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: isSelected ? 0.20 : 0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = isSelected
              ? PokeMapLegacyColors.white
              : color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 / zoom : 1.3 / zoom,
      );

      if (rect.width < (28 / zoom) || rect.height < (18 / zoom)) {
        continue;
      }
      final label = zone.name.trim().isNotEmpty
          ? zone.name.trim()
          : '${zone.kind.name}:${zone.id}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: PokeMapLegacyColors.white,
            fontSize: 10 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: rect.width - (8 / zoom));
      if (textPainter.width <= 0 || textPainter.height <= 0) {
        continue;
      }
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (4 / zoom),
          rect.top + (3 / zoom),
        ),
      );
    }
  }

  Color _gameplayZoneColor(GameplayZoneKind kind) {
    return switch (kind) {
      GameplayZoneKind.encounter => PokeMapLegacyColors.gameplayEncounter,
      GameplayZoneKind.movement => PokeMapLegacyColors.gameplayMovement,
      GameplayZoneKind.movementEffect =>
        PokeMapLegacyColors.gameplayMovementEffect,
      GameplayZoneKind.hazard => PokeMapLegacyColors.gameplayHazard,
      GameplayZoneKind.special => PokeMapLegacyColors.gameplaySpecial,
      GameplayZoneKind.custom => PokeMapLegacyColors.gameplayCustom,
    };
  }

  Color _triggerColor(TriggerType type) {
    return switch (type) {
      TriggerType.warp => PokeMapLegacyColors.deepPurpleAccent,
      TriggerType.message => PokeMapLegacyColors.amberAccent,
      TriggerType.interaction => PokeMapLegacyColors.lightBlueAccent,
      TriggerType.event => PokeMapLegacyColors.orangeAccent,
      TriggerType.spawn => PokeMapLegacyColors.greenAccent,
      TriggerType.camera => PokeMapLegacyColors.pinkAccent,
      TriggerType.custom => PokeMapLegacyColors.cyanAccent,
    };
  }

  Color _entityColor(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => PokeMapLegacyColors.entityNpc,
      MapEntityKind.sign => PokeMapLegacyColors.entitySign,
      MapEntityKind.item => PokeMapLegacyColors.entityItem,
      MapEntityKind.spawn => PokeMapLegacyColors.entitySpawn,
      MapEntityKind.custom => PokeMapLegacyColors.entityCustom,
    };
  }

  String _entityShortLabel(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'NPC',
      MapEntityKind.sign => 'SIGN',
      MapEntityKind.item => 'ITEM',
      MapEntityKind.spawn => 'SPAWN',
      MapEntityKind.custom => 'CUSTOM',
    };
  }

  @override
  bool shouldRepaint(covariant MapGridPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset ||
        oldDelegate.hoveredTile != hoveredTile ||
        oldDelegate.activeLayerId != activeLayerId ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        !_sameToolPreview(oldDelegate.toolPreview, toolPreview) ||
        oldDelegate.selectedEntityId != selectedEntityId ||
        oldDelegate.selectedMapEventId != selectedMapEventId ||
        oldDelegate.selectedWarpId != selectedWarpId ||
        oldDelegate.selectedTriggerId != selectedTriggerId ||
        oldDelegate.selectedGameplayZoneId != selectedGameplayZoneId ||
        oldDelegate.selectedPlacedElementInstanceId !=
            selectedPlacedElementInstanceId ||
        oldDelegate.placedElementRotationPreview !=
            placedElementRotationPreview ||
        oldDelegate.narrativeEventFocusTarget != narrativeEventFocusTarget ||
        oldDelegate.narrativeEventSourceProposal !=
            narrativeEventSourceProposal ||
        oldDelegate.narrativeEventHighlightColor !=
            narrativeEventHighlightColor ||
        oldDelegate.rotationPreviewAcceptedColor !=
            rotationPreviewAcceptedColor ||
        oldDelegate.rotationPreviewRejectedColor !=
            rotationPreviewRejectedColor ||
        oldDelegate.gameplayZoneDraftArea != gameplayZoneDraftArea ||
        !listEquals(oldDelegate.warps, warps) ||
        !listEquals(oldDelegate.gameplayZones, gameplayZones) ||
        !mapEquals(
          oldDelegate.connectionLabelsByDirection,
          connectionLabelsByDirection,
        ) ||
        oldDelegate.project != project ||
        oldDelegate.shadowLightPreviewPreset != shadowLightPreviewPreset ||
        !mapEquals(oldDelegate.tilesetImagesById, tilesetImagesById) ||
        oldDelegate.sourceTileWidth != sourceTileWidth ||
        oldDelegate.sourceTileHeight != sourceTileHeight ||
        !mapEquals(oldDelegate.tilesPerRowById, tilesPerRowById) ||
        oldDelegate._animationClock != _animationClock ||
        (_animationClock == null &&
            oldDelegate._animationClock == null &&
            oldDelegate._staticAnimationMs != _staticAnimationMs) ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showEntityEditorChrome != showEntityEditorChrome ||
        oldDelegate.showEditorOverlays != showEditorOverlays ||
        oldDelegate.environmentGeneratedAddPreview !=
            environmentGeneratedAddPreview ||
        oldDelegate.environmentGeneratedDeletePreviewId !=
            environmentGeneratedDeletePreviewId ||
        !identical(oldDelegate.borderPreview, borderPreview) ||
        oldDelegate.borderDiagnosticOverlayPalette !=
            borderDiagnosticOverlayPalette ||
        oldDelegate.environmentBrushCursorOverlay !=
            environmentBrushCursorOverlay ||
        !_sameEnvironmentMaskOverlay(
          oldDelegate.environmentMaskOverlay,
          environmentMaskOverlay,
        );
  }

  bool _sameEnvironmentMaskOverlay(
    EnvironmentAreaMask? previous,
    EnvironmentAreaMask? next,
  ) {
    if (identical(previous, next)) return true;
    if (previous == null || next == null) return previous == next;
    if (previous.width != next.width || previous.height != next.height) {
      return false;
    }
    return listEquals(previous.cells, next.cells);
  }

  bool _sameToolPreview(MapToolPreview? previous, MapToolPreview? next) {
    if (identical(previous, next)) return true;
    if (previous == null || next == null) return previous == next;
    return previous.mode == next.mode &&
        previous.origin == next.origin &&
        previous.size == next.size &&
        previous.tilesetId == next.tilesetId &&
        previous.elementId == next.elementId &&
        previous.terrain == next.terrain &&
        previous.validity == next.validity &&
        previous.reason == next.reason &&
        listEquals(previous.tiles, next.tiles);
  }
}
