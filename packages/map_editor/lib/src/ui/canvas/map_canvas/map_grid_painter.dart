part of 'package:map_editor/src/ui/canvas/map_canvas.dart';

enum _EditorMapTileRenderPass {
  background,
  foreground,
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

  for (final instance in map.placedElements) {
    final layer = tileLayerById[instance.layerId];
    if (layer == null) {
      continue;
    }

    final entry = elementById[instance.elementId];
    if (entry == null || entry.frames.isEmpty) {
      continue;
    }

    final source = entry.frames.primarySource;
    final width = source.width <= 0 ? 1 : source.width;
    final height = source.height <= 0 ? 1 : source.height;
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

        final x = instance.pos.x + localX;
        final y = instance.pos.y + localY;
        if (x < 0 || y < 0 || x >= mapWidth || y >= mapHeight) {
          continue;
        }

        final globalIndex = y * mapWidth + x;
        if (globalIndex >= layer.tiles.length ||
            layer.tiles[globalIndex] <= 0) {
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

/// Painter massif extrait tel quel du shell `MapCanvas`.
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
  final Map<MapConnectionDirection, String> connectionLabelsByDirection;
  final PathAutotileSet? selectedPathAutotileSet;
  final Map<String, PathAutotileSet> pathAutotileSetsByPresetId;
  final Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType;
  final ProjectManifest? project;
  final int editorEntityAnimationMs;

  MapGridPainter({
    required this.map,
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
    required this.connectionLabelsByDirection,
    this.selectedPathAutotileSet,
    required this.pathAutotileSetsByPresetId,
    required this.terrainPresetsByType,
    this.project,
    this.editorEntityAnimationMs = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);

    final gridWidth = map.size.width * tileWidth;
    final gridHeight = map.size.height * tileHeight;

    final visibleLayers = map.layers.where((layer) => layer.isVisible).toList();
    final foregroundTileCellIndicesByLayerId =
        buildEditorForegroundTileCellIndicesByLayerId(
      map: map,
      project: project,
    );

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is TerrainLayer) {
        _paintTerrainLayer(canvas, layer);
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is PathLayer) {
        _paintPathLayer(canvas, layer);
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is TileLayer) {
        _paintTileLayer(
          canvas,
          layer,
          renderPass: _EditorMapTileRenderPass.background,
          foregroundTileCellIndicesByLayerId:
              foregroundTileCellIndicesByLayerId,
        );
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is SurfaceLayer) {
        paintSurfaceLayerAtlasTilePreview(
          canvas: canvas,
          layer: layer,
          mapSize: map.size,
          project: project,
          tilesetImagesById: tilesetImagesById,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          zoom: zoom,
          elapsedMs: editorEntityAnimationMs,
        );
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is CollisionLayer) {
        _paintCollisionLayer(canvas, layer,
            isActive: layer.id == activeLayerId);
      }
    }

    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0 / zoom
      ..style = PaintingStyle.stroke;

    for (int x = 0; x <= map.size.width; x++) {
      canvas.drawLine(
        Offset(x * tileWidth, 0),
        Offset(x * tileWidth, gridHeight),
        gridPaint,
      );
    }
    for (int y = 0; y <= map.size.height; y++) {
      canvas.drawLine(
        Offset(0, y * tileHeight),
        Offset(gridWidth, y * tileHeight),
        gridPaint,
      );
    }

    if (hoveredTile != null) {
      final hoverPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.3)
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
        ..color = Colors.cyanAccent
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
    _paintEntities(
      canvas,
      foregroundPass: false,
    );
    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is TileLayer) {
        _paintTileLayer(
          canvas,
          layer,
          renderPass: _EditorMapTileRenderPass.foreground,
          foregroundTileCellIndicesByLayerId:
              foregroundTileCellIndicesByLayerId,
        );
      }
    }
    _paintEntities(
      canvas,
      foregroundPass: true,
    );
    _paintSelectedPlacedElementInstance(canvas);
    _paintToolPreview(canvas);
    _paintMapEvents(canvas);
    _paintTriggers(canvas);
    _paintWarps(canvas);
    _paintConnections(canvas, gridWidth, gridHeight);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, gridWidth, gridHeight),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
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
                  ? Colors.orangeAccent
                  : Colors.cyanAccent)
              .withValues(alpha: isSelected ? 0.18 : 0.12)
          ..style = PaintingStyle.fill;
        final areaBorder = Paint()
          ..color = (warp.triggerMode == MapWarpTriggerMode.onBump
                  ? Colors.orangeAccent
                  : Colors.cyanAccent)
              .withValues(alpha: isSelected ? 0.75 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.8 / zoom : 1.2 / zoom;
        canvas.drawRect(activationRect, areaPaint);
        canvas.drawRect(activationRect, areaBorder);
      }
      final fillPaint = Paint()
        ..color = (isSelected
                ? (warp.triggerMode == MapWarpTriggerMode.onBump
                    ? Colors.orangeAccent
                    : Colors.cyanAccent)
                : Colors.purpleAccent)
            .withValues(alpha: isSelected ? 0.42 : 0.34)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.purpleAccent
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
          Paint()..color = isSelected ? Colors.white : Colors.purple.shade100,
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
          Paint()..color = isSelected ? Colors.white : Colors.orange.shade100,
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
      if (entry.id == selectedInstance.elementId) {
        source = entry.frames.primarySource;
        break;
      }
    }
    final width = source?.width ?? 1;
    final height = source?.height ?? 1;
    if (width <= 0 || height <= 0) {
      return;
    }
    final rect = Rect.fromLTWH(
      selectedInstance.pos.x * tileWidth,
      selectedInstance.pos.y * tileHeight,
      width * tileWidth,
      height * tileHeight,
    );
    final fill = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.17)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.yellowAccent
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
      ..color = (isSelected ? Colors.white : Colors.black)
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
        editorAnimationTimeMs: editorEntityAnimationMs,
      );
      if (resolved != null) {
        final shade = RRect.fromRectAndRadius(
          rect,
          Radius.circular(5 / zoom),
        );
        canvas.drawRRect(
          shade,
          Paint()
            ..color = Colors.black.withValues(alpha: isSelected ? 0.28 : 0.2)
            ..style = PaintingStyle.fill,
        );
        _paintEntityProjectElementFrame(
          canvas,
          resolved.image,
          resolved.srcRect,
          rect,
        );
      } else {
        _paintEntityFallbackBody(canvas, entity, rect, isSelected);
      }
      _paintEntitySelectionAndChrome(canvas, entity, rect, isSelected);
    }
  }

  void _paintMapEvents(Canvas canvas) {
    if (map.events.isEmpty) return;
    for (final event in map.events) {
      final x = event.position.x;
      final y = event.position.y;
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
        ..color = const Color(0xFF35E5D7).withValues(
          alpha: isSelected ? 0.4 : 0.26,
        )
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = isSelected
            ? Colors.white
            : const Color(0xFF35E5D7).withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.2 / zoom : 1.4 / zoom;
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);

      final center = rect.center;
      final radius = (tileWidth < tileHeight ? tileWidth : tileHeight) * 0.17;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = isSelected ? Colors.white : const Color(0xFF0A4955),
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
            color: Colors.white,
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
          color: Colors.white.withValues(alpha: 0.92),
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
        ..color = (isSelected ? Colors.white : color)
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
        ..color = Colors.black.withValues(alpha: isSelected ? 0.72 : 0.56)
        ..style = PaintingStyle.fill,
    );

    final badgeTextPainter = TextPainter(
      text: TextSpan(
        text: _entityShortLabel(entity.kind),
        style: TextStyle(
          color: Colors.white,
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
          color: Colors.white,
          fontSize: 10 / zoom,
          fontWeight: FontWeight.w600,
          shadows: const [
            Shadow(
              offset: Offset(0.5, 0.5),
              blurRadius: 2,
              color: Color(0xCC000000),
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
          ..color = isSelected ? Colors.white : color.withValues(alpha: 0.92)
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
            color: Colors.white,
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
        ..color = const Color(0xFF13212D).withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.75)
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
            color: Colors.white,
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

  void _paintPaintPreview(Canvas canvas, MapToolPreview preview) {
    final tiles = preview.tiles;
    final tilesetId = preview.tilesetId;
    if (tiles == null || tilesetId == null) return;
    final tilesetImage = tilesetImagesById[tilesetId];
    final tilesPerRow = tilesPerRowById[tilesetId] ?? 0;
    if (tilesetImage != null &&
        tilesPerRow > 0 &&
        sourceTileWidth > 0 &&
        sourceTileHeight > 0) {
      final alpha =
          preview.validity == MapToolPreviewValidity.valid ? 0.6 : 0.3;
      final tilePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
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
          final tileId = tiles[patternIndex];
          if (tileId <= 0) continue;
          final sourceIndex = tileId - 1;
          final sourceX = (sourceIndex % tilesPerRow) * sourceTileWidth;
          final sourceY = (sourceIndex ~/ tilesPerRow) * sourceTileHeight;
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
            mapX * tileWidth,
            mapY * tileHeight,
            tileWidth,
            tileHeight,
          );
          canvas.drawImageRect(tilesetImage, srcRect, dstRect, tilePaint);
        }
      }
    }

    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    if (preview.validity == MapToolPreviewValidity.invalid) {
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 / zoom,
      );
      return;
    }
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
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
        ..color = Colors.redAccent.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.redAccent
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
        ..color = Colors.orangeAccent.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.orangeAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintTerrainPaintPreview(Canvas canvas, MapToolPreview preview) {
    final terrainPresetPreviewPainted =
        _paintTerrainPresetPreview(canvas, preview);
    if (terrainPresetPreviewPainted) {
      return;
    }
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
    final pathPreviewPainted = _paintPathLayerPreview(canvas, preview);
    if (pathPreviewPainted) {
      return;
    }
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.tealAccent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.tealAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  bool _paintPathLayerPreview(Canvas canvas, MapToolPreview preview) {
    if (preview.size.width != 1 || preview.size.height != 1) {
      return false;
    }
    final origin = preview.origin;
    if (origin.x < 0 ||
        origin.y < 0 ||
        origin.x >= map.size.width ||
        origin.y >= map.size.height) {
      return false;
    }
    final activePathLayer = _resolveActivePathLayer();
    if (activePathLayer == null) {
      return false;
    }
    final autotileSet = _resolvePreviewPathAutotileSet(activePathLayer);
    if (autotileSet == null) {
      return false;
    }
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }

    final expectedLength = map.size.width * map.size.height;
    final simulatedCells = List<bool>.filled(
      expectedLength,
      false,
      growable: false,
    );
    final sourceCells = activePathLayer.cells;
    final copyLength = sourceCells.length < expectedLength
        ? sourceCells.length
        : expectedLength;
    for (var index = 0; index < copyLength; index++) {
      simulatedCells[index] = sourceCells[index];
    }
    final previewIndex = origin.y * map.size.width + origin.x;
    if (previewIndex < 0 || previewIndex >= simulatedCells.length) {
      return false;
    }
    simulatedCells[previewIndex] = true;

    final variant = resolvePathVariantAt(
      cells: simulatedCells,
      mapSize: map.size,
      pos: origin,
    );
    final dstRect = Rect.fromLTWH(
      origin.x * tileWidth,
      origin.y * tileHeight,
      tileWidth,
      tileHeight,
    );

    final elapsedMs = editorEntityAnimationMs.toDouble();

    final painted = _paintResolvedPathVariantCell(
      canvas,
      basePathPresetId: activePathLayer.presetId,
      legacyAutotileSet: autotileSet,
      variant: variant,
      mapX: origin.x,
      mapY: origin.y,
      dstRect: dstRect,
      alpha: 0.66,
      elapsedMs: elapsedMs,
    );
    if (!painted) {
      return false;
    }
    canvas.drawRect(
      dstRect,
      Paint()
        ..color = Colors.tealAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
    return true;
  }

  bool _paintTerrainPresetPreview(Canvas canvas, MapToolPreview preview) {
    final terrain = preview.terrain;
    if (terrain == null || terrain == TerrainType.none) {
      return false;
    }
    final preset = terrainPresetsByType[terrain];
    if (preset == null || preset.variants.isEmpty) {
      return false;
    }
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }
    var rendered = false;
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
        final resolved = _resolveTerrainPresetFrame(
          preset: preset,
          x: mapX,
          y: mapY,
          elapsedMs: editorEntityAnimationMs.toDouble(),
        );
        if (resolved == null) continue;
        final tilesetId = resolved.tilesetId.trim();
        if (tilesetId.isEmpty) {
          continue;
        }
        final tilesetImage = tilesetImagesById[tilesetId];
        if (tilesetImage == null) {
          continue;
        }
        final sourceX = resolved.source.x * sourceTileWidth;
        final sourceY = resolved.source.y * sourceTileHeight;
        if (sourceX < 0 ||
            sourceY < 0 ||
            sourceX + sourceTileWidth > tilesetImage.width ||
            sourceY + sourceTileHeight > tilesetImage.height) {
          continue;
        }
        canvas.drawImageRect(
          tilesetImage,
          Rect.fromLTWH(
            sourceX.toDouble(),
            sourceY.toDouble(),
            sourceTileWidth.toDouble(),
            sourceTileHeight.toDouble(),
          ),
          Rect.fromLTWH(
            mapX * tileWidth,
            mapY * tileHeight,
            tileWidth,
            tileHeight,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.62),
        );
        rendered = true;
      }
    }
    if (!rendered) return false;
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect != null) {
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 / zoom,
      );
    }
    return true;
  }

  void _paintTerrainErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.blueGrey.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.blueGrey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintPathErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.cyanAccent
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
        ..color = Colors.lightBlueAccent.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.lightBlueAccent
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
  }) {
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return;
    }
    final layerTilesetId = layer.tilesetId?.trim();
    if (layerTilesetId == null || layerTilesetId.isEmpty) {
      return;
    }
    final tilesetImage = tilesetImagesById[layerTilesetId];
    final tilesPerRow = tilesPerRowById[layerTilesetId] ?? 0;
    if (tilesetImage == null || tilesPerRow <= 0) {
      return;
    }

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

    final layerPaint = Paint();

    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final tileIndex = rowStart + x;
        if (tileIndex < 0 || tileIndex >= layer.tiles.length) continue;
        final tileId = layer.tiles[tileIndex];
        if (tileId <= 0) continue;
        final shouldDrawCell = shouldPaintEditorTileCellInRenderPass(
          explicitForeground: explicitForeground,
          isForegroundCell: foregroundCells?.contains(tileIndex) ?? false,
          foregroundPass: renderPass == _EditorMapTileRenderPass.foreground,
        );
        if (!shouldDrawCell) {
          continue;
        }

        final sourceIndex = tileId - 1;
        final sourceX = (sourceIndex % tilesPerRow) * sourceTileWidth;
        final sourceY = (sourceIndex ~/ tilesPerRow) * sourceTileHeight;

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
        canvas.drawImageRect(tilesetImage, srcRect, dstRect, layerPaint);
      }
    }
  }

  void _paintCollisionLayer(
    Canvas canvas,
    CollisionLayer layer, {
    required bool isActive,
  }) {
    if (layer.collisions.isEmpty) return;
    final fillAlpha = (isActive ? 0.34 : 0.24) * layer.opacity;
    final borderAlpha = (isActive ? 0.75 : 0.5) * layer.opacity;
    final fillPaint = Paint()
      ..color = Colors.deepOrange.withValues(alpha: fillAlpha)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.deepOrangeAccent.withValues(alpha: borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / zoom;

    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
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

  void _paintTerrainLayer(Canvas canvas, TerrainLayer layer) {
    if (layer.terrains.isEmpty) return;
    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final index = rowStart + x;
        if (index < 0 || index >= layer.terrains.length) continue;
        final terrain = layer.terrains[index];
        if (terrain == TerrainType.none) {
          continue;
        }
        final terrainPresetDrawn = _paintTerrainPresetCell(
          canvas,
          terrain,
          x: x,
          y: y,
          alpha: 1.0,
        );
        if (terrainPresetDrawn) {
          continue;
        }
        final fillColor = _terrainColor(terrain);
        final borderColor = _terrainBorderColor(terrain);
        final cell = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
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
            ..strokeWidth = 1.0 / zoom,
        );
      }
    }
  }

  void _paintPathLayer(Canvas canvas, PathLayer layer) {
    if (layer.cells.isEmpty) return;
    const pathCellAlpha = 1.0;
    final autotileSet = _resolvePathAutotileSetForLayer(layer);
    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final index = rowStart + x;
        if (index < 0 || index >= layer.cells.length) continue;
        if (!layer.cells[index]) continue;
        final cell = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        final pathDrawn = _paintPathLayerCell(
          canvas,
          layer,
          autotileSet: autotileSet,
          x: x,
          y: y,
          alpha: pathCellAlpha,
        );
        if (pathDrawn) {
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
            ..strokeWidth = 1.0 / zoom,
        );
      }
    }
  }

  bool _paintPathLayerCell(
    Canvas canvas,
    PathLayer layer, {
    required PathAutotileSet? autotileSet,
    required int x,
    required int y,
    required double alpha,
  }) {
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }

    final variant = resolvePathVariantAt(
      cells: layer.cells,
      mapSize: map.size,
      pos: GridPos(x: x, y: y),
    );
    final dstRect = Rect.fromLTWH(
      x * tileWidth,
      y * tileHeight,
      tileWidth,
      tileHeight,
    );

    final elapsedMs = editorEntityAnimationMs.toDouble();

    return _paintResolvedPathVariantCell(
      canvas,
      basePathPresetId: layer.presetId,
      legacyAutotileSet: autotileSet,
      variant: variant,
      mapX: x,
      mapY: y,
      dstRect: dstRect,
      alpha: alpha,
      elapsedMs: elapsedMs,
    );
  }

  bool _paintResolvedPathVariantCell(
    Canvas canvas, {
    required String basePathPresetId,
    required PathAutotileSet? legacyAutotileSet,
    required TerrainPathVariant variant,
    required int mapX,
    required int mapY,
    required Rect dstRect,
    required double alpha,
    required double elapsedMs,
  }) {
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }
    final resolved = resolvePathPatternEditorRenderResolution(
      project: project,
      basePathPresetId: basePathPresetId,
      variant: variant,
      mapX: mapX,
      mapY: mapY,
      elapsedMs: elapsedMs,
      legacyAutotileSet: legacyAutotileSet,
    );
    if (resolved == null) {
      return false;
    }
    final source = resolved.sourceRect;
    final tilesetId = resolved.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null) {
      return false;
    }

    final sourceX = source.x * sourceTileWidth;
    final sourceY = source.y * sourceTileHeight;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceX + sourceTileWidth > tilesetImage.width ||
        sourceY + sourceTileHeight > tilesetImage.height) {
      return false;
    }

    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      sourceTileWidth.toDouble(),
      sourceTileHeight.toDouble(),
    );
    canvas.drawImageRect(
      tilesetImage,
      srcRect,
      dstRect,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }

  bool _paintTerrainPresetCell(
    Canvas canvas,
    TerrainType terrain, {
    required int x,
    required int y,
    required double alpha,
  }) {
    final preset = terrainPresetsByType[terrain];
    if (preset == null || preset.variants.isEmpty) {
      return false;
    }
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }
    final resolved = _resolveTerrainPresetFrame(
      preset: preset,
      x: x,
      y: y,
      elapsedMs: editorEntityAnimationMs.toDouble(),
    );
    if (resolved == null) return false;
    final tilesetId = resolved.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null) {
      return false;
    }
    final sourceX = resolved.source.x * sourceTileWidth;
    final sourceY = resolved.source.y * sourceTileHeight;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceX + sourceTileWidth > tilesetImage.width ||
        sourceY + sourceTileHeight > tilesetImage.height) {
      return false;
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
    canvas.drawImageRect(
      tilesetImage,
      srcRect,
      dstRect,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }

  _ResolvedTerrainFrame? _resolveTerrainPresetFrame({
    required ProjectTerrainPreset preset,
    required int x,
    required int y,
    required double elapsedMs,
  }) {
    final variants = preset.variants;
    if (variants.isEmpty) return null;
    var totalWeight = 0;
    for (final variant in variants) {
      totalWeight += variant.weight <= 0 ? 1 : variant.weight;
    }
    if (totalWeight <= 0) return null;

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

    if (chosen.frames.isEmpty) {
      return null;
    }
    final frameIndex = resolvePlacedElementAnimationFrameIndex(
      frameDurationsMs: normalizeElementFrameDurationsMs(
        chosen.frames.map((frame) => frame.durationMs).toList(growable: false),
      ),
      elapsedMs: elapsedMs,
      animation: const MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
      ),
    );
    final resolvedFrame =
        chosen.frames[frameIndex.clamp(0, chosen.frames.length - 1)];
    final frameSource = resolvedFrame.source;
    final width = frameSource.width <= 0 ? 1 : frameSource.width;
    final height = frameSource.height <= 0 ? 1 : frameSource.height;
    final (offsetX, offsetY) = terrainPresetSubtileOffsetsForMapCell(
      x,
      y,
      frameWidthTiles: width,
      frameHeightTiles: height,
    );
    final frameTilesetId = resolvedFrame.tilesetId.trim();
    final resolvedTilesetId =
        frameTilesetId.isNotEmpty ? frameTilesetId : preset.tilesetId.trim();
    if (resolvedTilesetId.isEmpty) {
      return null;
    }
    return _ResolvedTerrainFrame(
      tilesetId: resolvedTilesetId,
      source: TilesetSourceRect(
        x: frameSource.x + offsetX,
        y: frameSource.y + offsetY,
      ),
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

  PathLayer? _resolveActivePathLayer() {
    final id = activeLayerId;
    if (id == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == id && layer is PathLayer) {
        return layer;
      }
    }
    return null;
  }

  PathAutotileSet? _resolvePathAutotileSetForLayer(PathLayer layer) {
    final presetId = layer.presetId.trim();
    if (presetId.isEmpty) {
      return null;
    }
    return pathAutotileSetsByPresetId[presetId];
  }

  PathAutotileSet? _resolvePreviewPathAutotileSet(PathLayer layer) {
    final assigned = _resolvePathAutotileSetForLayer(layer);
    if (assigned != null) {
      return assigned;
    }
    return selectedPathAutotileSet;
  }

  Color _terrainColor(TerrainType terrain) {
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
    switch (terrain) {
      case TerrainType.grass:
        return Colors.green.shade900;
      case TerrainType.dirt:
        return const Color(0xFF6D4524);
      case TerrainType.sand:
        return Colors.orange.shade900;
      case TerrainType.rock:
        return Colors.blueGrey.shade900;
      case TerrainType.stone:
        return Colors.grey.shade800;
      case TerrainType.indoor:
        return const Color(0xFF8D6E63);
      case TerrainType.none:
        return Colors.transparent;
    }
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
          ..color = const Color(0xFF66FF99).withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        draftRect,
        Paint()
          ..color = const Color(0xFF66FF99).withValues(alpha: 0.85)
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
          ..color = isSelected ? Colors.white : color.withValues(alpha: 0.85)
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
            color: Colors.white,
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
      GameplayZoneKind.encounter => const Color(0xFF66FF99),
      GameplayZoneKind.movement => const Color(0xFF66AAFF),
      GameplayZoneKind.movementEffect => const Color(0xFF66D9FF),
      GameplayZoneKind.hazard => const Color(0xFFFF6666),
      GameplayZoneKind.special => const Color(0xFFCC66FF),
      GameplayZoneKind.custom => const Color(0xFF66FFFF),
    };
  }

  Color _triggerColor(TriggerType type) {
    return switch (type) {
      TriggerType.warp => Colors.deepPurpleAccent,
      TriggerType.message => Colors.amberAccent,
      TriggerType.interaction => Colors.lightBlueAccent,
      TriggerType.event => Colors.orangeAccent,
      TriggerType.spawn => Colors.greenAccent,
      TriggerType.camera => Colors.pinkAccent,
      TriggerType.custom => Colors.cyanAccent,
    };
  }

  Color _entityColor(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => const Color(0xFF55D0FF),
      MapEntityKind.sign => const Color(0xFFFFC857),
      MapEntityKind.item => const Color(0xFF7CE38B),
      MapEntityKind.spawn => const Color(0xFFFF7B7B),
      MapEntityKind.custom => const Color(0xFFC18CFF),
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
        oldDelegate.gameplayZoneDraftArea != gameplayZoneDraftArea ||
        !listEquals(oldDelegate.warps, warps) ||
        !listEquals(oldDelegate.gameplayZones, gameplayZones) ||
        !_samePathAutotileSet(
          oldDelegate.selectedPathAutotileSet,
          selectedPathAutotileSet,
        ) ||
        !mapEquals(
          oldDelegate.connectionLabelsByDirection,
          connectionLabelsByDirection,
        ) ||
        !_samePathAutotileSetsByPresetId(
          oldDelegate.pathAutotileSetsByPresetId,
          pathAutotileSetsByPresetId,
        ) ||
        !mapEquals(oldDelegate.terrainPresetsByType, terrainPresetsByType) ||
        oldDelegate.project != project ||
        !mapEquals(oldDelegate.tilesetImagesById, tilesetImagesById) ||
        oldDelegate.sourceTileWidth != sourceTileWidth ||
        oldDelegate.sourceTileHeight != sourceTileHeight ||
        !mapEquals(oldDelegate.tilesPerRowById, tilesPerRowById) ||
        oldDelegate.editorEntityAnimationMs != editorEntityAnimationMs;
  }

  bool _sameToolPreview(MapToolPreview? previous, MapToolPreview? next) {
    if (identical(previous, next)) return true;
    if (previous == null || next == null) return previous == next;
    return previous.mode == next.mode &&
        previous.origin == next.origin &&
        previous.size == next.size &&
        previous.tilesetId == next.tilesetId &&
        previous.terrain == next.terrain &&
        previous.validity == next.validity &&
        previous.reason == next.reason &&
        listEquals(previous.tiles, next.tiles);
  }

  bool _samePathAutotileSet(PathAutotileSet? previous, PathAutotileSet? next) {
    if (identical(previous, next)) return true;
    if (previous == null || next == null) return previous == next;
    if (previous.id != next.id) return false;
    if (previous.tilesetId != next.tilesetId) return false;
    if (previous.variants.length != next.variants.length) return false;
    for (final entry in previous.variants.entries) {
      final other = next.variants[entry.key];
      if (other == null) return false;
      if (!listEquals(other, entry.value)) return false;
    }
    return true;
  }

  bool _samePathAutotileSetsByPresetId(
    Map<String, PathAutotileSet> previous,
    Map<String, PathAutotileSet> next,
  ) {
    if (previous.length != next.length) {
      return false;
    }
    for (final entry in previous.entries) {
      if (!_samePathAutotileSet(entry.value, next[entry.key])) {
        return false;
      }
    }
    return true;
  }
}
