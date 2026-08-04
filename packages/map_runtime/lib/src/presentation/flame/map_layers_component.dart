import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_character_refs.dart';
import '../../application/runtime_map_bundle.dart';
import '../../border/border_runtime_asset_cache.dart';
import '../../border/border_runtime_draw_instruction.dart';
import '../../border/border_runtime_renderer.dart';
import '../../infrastructure/project_tileset_visual_resolution.dart';
import '../../infrastructure/runtime_tileset_image.dart';
import '../../shadow/shadow_runtime_collection_provider.dart';
import '../../shadow/shadow_runtime_renderer.dart';
import 'quarter_turn_pixel_renderer.dart';
import 'runtime_map_layer_paint_order.dart';

const int _kEntityFrameDurationFallbackMs = 200;

enum MapLayerRenderPass {
  background,
  foreground,
}

@visibleForTesting
bool shouldRenderProjectElementEntityInForegroundPass(
  MapEntity entity, {
  required MapLayerRenderPass renderPass,
}) {
  final renderInForeground = entity.shouldRenderProjectElementInForeground;
  return switch (renderPass) {
    MapLayerRenderPass.background => !renderInForeground,
    MapLayerRenderPass.foreground => renderInForeground,
  };
}

class MapLayersComponent extends PositionComponent {
  MapLayersComponent({
    required this.bundle,
    required this.tileImagesByTilesetId,
    this.renderPass = MapLayerRenderPass.background,
    this.showCollisionOverlay = false,
    this.npcMapPresencePredicate,
    this.mapEntityPresencePredicate,
    this.shadowCollectionProvider,
    this.shadowRenderer = const ShadowRuntimeRenderer(),
    this.borderAssets,
    this.borderRenderer = const BorderRuntimeRenderer(),
  })  : _runtimeLayerPaintOrder = buildRuntimeMapLayerPaintOrder(bundle.map),
        _foregroundTileCellIndicesByLayerId =
            _buildForegroundTileCellIndicesByLayerId(bundle),
        _animatedPlacedCellsByLayerId =
            _buildAnimatedPlacedCellsByLayerId(bundle),
        super(
          anchor: Anchor.topLeft,
          position: Vector2.zero(),
          size: Vector2(
            bundle.map.size.width * bundle.cellWidth,
            bundle.map.size.height * bundle.cellHeight,
          ),
        ) {
    _animatedInstanceById = _buildAnimatedPlacedInstanceById(
      _animatedPlacedCellsByLayerId,
    );
  }

  final RuntimeMapBundle bundle;
  final Map<String, RuntimeTilesetImage> tileImagesByTilesetId;
  final MapLayerRenderPass renderPass;
  bool showCollisionOverlay;

  /// Si non null, les PNJ pour lesquels ce filtre retourne `false` ne sont pas
  /// peints (sprites « élément projet » sans personnage dédié).
  NpcMapPresencePredicate? npcMapPresencePredicate;

  /// Si non null, les entités projet rejetées ne sont pas peintes. Ce filtre
  /// couvre aussi les objets et props pilotés par les World Rules.
  MapEntityPresencePredicate? mapEntityPresencePredicate;
  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
  final ShadowRuntimeRenderer shadowRenderer;
  final BorderRuntimeAssetBundle? borderAssets;
  final BorderRuntimeRenderer borderRenderer;
  final Map<String, Set<int>> _foregroundTileCellIndicesByLayerId;
  final Map<String, Map<int, _AnimatedPlacedCell>>
      _animatedPlacedCellsByLayerId;
  late final Map<String, _AnimatedPlacedInstanceSpec> _animatedInstanceById;
  final Map<String, bool> _animationEnabledOverrideByInstanceId =
      <String, bool>{};
  final Map<String, _ActiveOneShotAnimation> _activeOneShotByInstanceId =
      <String, _ActiveOneShotAnimation>{};

  late final Map<String, ProjectElementEntry> _elementById = {
    for (final e in bundle.manifest.elements) e.id: e,
  };
  late final Map<String, ProjectTilesetSource?> _tilesetSourceById =
      <String, ProjectTilesetSource?>{
    for (final tileset in bundle.manifest.tilesets) tileset.id: tileset.source,
  };
  final Map<(String, int), ProjectTilesetVisualResolution>
      _regularTileVisualCache =
      <(String, int), ProjectTilesetVisualResolution>{};

  double _animElapsed = 0.0;

  /// Rect visible dans l'espace local du composant (pixels monde relatifs à
  /// l'origine de la map). Mis à jour par le game chaque frame pour permettre
  /// le viewport culling. Si `null`, toute la carte est peinte (fallback).
  Rect? _visibleLocalRect;

  final MapVisualCompositionPlan _runtimeLayerPaintOrder;

  /// Met à jour le rectangle visible **en coordonnées locales** du composant.
  ///
  /// Le game doit appeler cette méthode chaque frame après la mise à jour
  /// de la caméra, en convertissant le viewport caméra vers l'espace local
  /// de ce composant (soustraction de l'origine monde du composant).
  void setVisibleLocalRect(Rect? rect) {
    _visibleLocalRect = rect;
  }

  /// Returns the owner-cell range whose resolved tile visuals can intersect
  /// the viewport. Tileset offsets and oversized image-collection pages may
  /// move pixels several cells away from their logical owner, so the generic
  /// three-cell component margin is not sufficient for tile layers.
  ({int startX, int startY, int endX, int endY}) _visibleTileCellRange(
    TileLayer layer,
  ) {
    final rect = _visibleLocalRect;
    final width = bundle.map.size.width;
    final height = bundle.map.size.height;
    final cellWidth = bundle.cellWidth;
    final cellHeight = bundle.cellHeight;
    if (rect == null || cellWidth <= 0 || cellHeight <= 0) {
      return (startX: 0, startY: 0, endX: width, endY: height);
    }

    final sourceTileWidth = bundle.manifest.settings.tileWidth;
    final sourceTileHeight = bundle.manifest.settings.tileHeight;
    var minimumX = 0.0;
    var minimumY = 0.0;
    var maximumX = cellWidth;
    var maximumY = cellHeight;
    final scaleX = cellWidth / sourceTileWidth;
    final scaleY = cellHeight / sourceTileHeight;

    for (final entry in layer.palette) {
      final source = _tilesetSourceById[entry.tilesetId];
      if (source == null) continue;
      final visual = _resolveTileLayerVisual(
        entry: entry,
        source: source,
        tileWidth: sourceTileWidth,
        tileHeight: sourceTileHeight,
      );
      if (visual == null) continue;
      final bounds = visual.animationBounds;
      minimumX = math.min(minimumX, bounds.x * scaleX);
      minimumY = math.min(minimumY, bounds.y * scaleY);
      maximumX = math.max(maximumX, (bounds.x + bounds.width) * scaleX);
      maximumY = math.max(maximumY, (bounds.y + bounds.height) * scaleY);
    }

    return (
      startX: math.max(0, ((rect.left - maximumX) / cellWidth).floor()),
      startY: math.max(0, ((rect.top - maximumY) / cellHeight).floor()),
      endX: math.min(
        width,
        ((rect.right - minimumX) / cellWidth).ceil(),
      ),
      endY: math.min(
        height,
        ((rect.bottom - minimumY) / cellHeight).ceil(),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animElapsed += dt;
  }

  void setPlacedElementAnimationEnabledOverride({
    required String instanceId,
    required bool enabled,
  }) {
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    _animationEnabledOverrideByInstanceId[trimmedId] = enabled;
  }

  bool playPlacedElementAnimationOnce({
    required String instanceId,
  }) {
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return false;
    }
    final spec = _animatedInstanceById[trimmedId];
    if (spec == null || spec.frameDurationsMs.length < 2) {
      return false;
    }
    _activeOneShotByInstanceId[trimmedId] = _ActiveOneShotAnimation(
      startedAtMs: _animElapsed * 1000,
      frameDurationsMs: spec.frameDurationsMs,
      speed: spec.speed,
    );
    return true;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final step in _runtimeLayerPaintOrder.steps) {
      _renderVisualCompositionStep(canvas, step);
    }
  }

  void _renderVisualCompositionStep(
    Canvas canvas,
    MapVisualCompositionStep step,
  ) {
    switch (step.kind) {
      case MapVisualCompositionStepKind.smartTileLayer:
        _paintSmartTileLayer(canvas, step.layer! as SmartTileLayer);
      case MapVisualCompositionStepKind.tileBackgroundLayer:
        if (renderPass == MapLayerRenderPass.background) {
          final layer = step.layer! as TileLayer;
          _paintTileLayer(canvas, layer);
        }
      case MapVisualCompositionStepKind.borderLayer:
        if (renderPass == MapLayerRenderPass.background) {
          _paintBorderLayer(canvas, step.layer! as BorderLayer);
        }
      case MapVisualCompositionStepKind.objectNoop:
      case MapVisualCompositionStepKind.environmentNoop:
        break;
      case MapVisualCompositionStepKind.shadows:
        if (renderPass == MapLayerRenderPass.background) {
          _paintShadows(canvas);
        }
      case MapVisualCompositionStepKind.placedElements:
        if (renderPass == MapLayerRenderPass.background) {
          final layer = step.layer! as TileLayer;
          _paintPlacedElementsForLayer(
            canvas,
            layerId: layer.id,
            layerName: layer.name,
            opacity: layer.opacity,
          );
        }
      case MapVisualCompositionStepKind.backgroundEntities:
        if (renderPass == MapLayerRenderPass.background) {
          _paintEntities(canvas);
        }
      case MapVisualCompositionStepKind.foregroundTilesAndPlacedElements:
        if (renderPass == MapLayerRenderPass.foreground) {
          for (final layer
              in _runtimeLayerPaintOrder.visibleTileLayersInPaintOrder) {
            _paintTileLayerAndElements(canvas, layer);
          }
        }
      case MapVisualCompositionStepKind.foregroundEntities:
        if (renderPass == MapLayerRenderPass.foreground) {
          _paintEntities(canvas);
        }
      case MapVisualCompositionStepKind.collisionOverlay:
        if (renderPass == MapLayerRenderPass.background &&
            showCollisionOverlay) {
          _paintCollisionOverlays(
            canvas,
            _runtimeLayerPaintOrder.visibleCollisionLayersInPaintOrder,
          );
        }
    }
  }

  void _paintBorderLayer(Canvas canvas, BorderLayer layer) {
    final collection = buildBorderRuntimeDrawInstructions(
      layer: layer,
      tileWidthPx: bundle.manifest.settings.tileWidth,
      tileHeightPx: bundle.manifest.settings.tileHeight,
    );
    if (collection.instructions.isEmpty || collection.opacity <= 0) {
      return;
    }
    final assets = borderAssets;
    if (assets == null) {
      throw AssetNotFoundException(
        'Border runtime assets were not supplied for visible layer: '
        '${layer.id}',
      );
    }
    borderRenderer.renderCollection(
      canvas,
      collection: collection,
      assets: assets,
      elapsedMs: (_animElapsed * 1000).toInt(),
      displayScale: bundle.manifest.settings.displayScale,
      viewport: _visibleLocalRect,
    );
  }

  void _paintTileLayerAndElements(Canvas canvas, TileLayer layer) {
    _paintTileLayer(canvas, layer);
    _paintPlacedElementsForLayer(
      canvas,
      layerId: layer.id,
      layerName: layer.name,
      opacity: layer.opacity,
    );
  }

  void _paintCollisionOverlays(
    Canvas canvas,
    Iterable<CollisionLayer> layers,
  ) {
    for (final layer in layers) {
      _paintCollisionLayer(canvas, layer.collisions, layer.opacity);
    }
    _paintPlacedElementsCollisionOverlay(canvas);
  }

  void _paintShadows(Canvas canvas) {
    final collection = shadowCollectionProvider?.call();
    if (collection == null || collection.isEmpty) {
      return;
    }
    shadowRenderer.renderCollectionPass(
      canvas,
      collection,
      ShadowRenderPass.groundStatic,
    );
    shadowRenderer.renderCollectionPass(
      canvas,
      collection,
      ShadowRenderPass.actorContact,
    );
  }

  void _paintSmartTileLayer(Canvas canvas, SmartTileLayer layer) {
    final catalog = bundle.manifest.smartTileCatalog;
    if (catalog.isEmpty || layer.opacity <= 0) return;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final sourceTileWidth = bundle.manifest.settings.tileWidth;
    final sourceTileHeight = bundle.manifest.settings.tileHeight;
    final visibleRect = _visibleLocalRect;
    final visuals = resolveSmartTileLayerVisuals(
      map: bundle.map,
      layer: layer,
      catalog: catalog,
      pass: switch (renderPass) {
        MapLayerRenderPass.background => SmartTileVisualPass.background,
        MapLayerRenderPass.foreground => SmartTileVisualPass.foreground,
      },
      elapsedMs: (_animElapsed * 1000).toInt(),
      destinationCellWidth: cw,
      destinationCellHeight: ch,
      sourceCellWidth: sourceTileWidth > 0 ? sourceTileWidth.toDouble() : cw,
      sourceCellHeight: sourceTileHeight > 0 ? sourceTileHeight.toDouble() : ch,
      viewportBounds: visibleRect == null
          ? null
          : SmartTileGeometryRect(
              left: visibleRect.left,
              top: visibleRect.top,
              width: visibleRect.width,
              height: visibleRect.height,
            ),
    );
    if (visuals.isEmpty) return;

    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..color = Colors.white.withValues(
        alpha: layer.opacity.clamp(0.0, 1.0),
      );

    for (final visual in visuals) {
      final image = tileImagesByTilesetId[visual.tilesetId];
      if (image == null) continue;
      final source = visual.sourceRect;
      final sourceRect = Rect.fromLTWH(
        source.x.toDouble(),
        source.y.toDouble(),
        source.width.toDouble(),
        source.height.toDouble(),
      );
      if (!image.containsSourceRect(sourceRect)) continue;
      _drawSmartTileImage(
        canvas: canvas,
        image: image,
        sourceRect: sourceRect,
        visual: visual,
        paint: paint,
      );
    }
  }

  void _drawSmartTileImage({
    required Canvas canvas,
    required RuntimeTilesetImage image,
    required Rect sourceRect,
    required SmartTileLayerVisual visual,
    required Paint paint,
  }) {
    final destination = visual.geometry.destinationRect;
    final transform = visual.transform;
    canvas.save();
    try {
      // Keep this transform sequence identical to the editor consumer. The
      // neutral Core plan is authoritative; runtime adds no Wang decisions.
      canvas.translate(destination.left, destination.top);
      switch (transform.quarterTurns) {
        case 0:
          break;
        case 1:
          canvas.translate(destination.height, 0);
          canvas.rotate(math.pi / 2);
        case 2:
          canvas.translate(destination.width, destination.height);
          canvas.rotate(math.pi);
        case 3:
          canvas.translate(0, destination.width);
          canvas.rotate(3 * math.pi / 2);
      }
      if (transform.flipX) {
        canvas.translate(destination.width, 0);
        canvas.scale(-1, 1);
      }
      image.drawImageRect(
        canvas,
        sourceRect,
        Rect.fromLTWH(0, 0, destination.width, destination.height),
        paint,
      );
    } finally {
      canvas.restore();
    }
  }

  void _paintEntities(Canvas canvas) {
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final elapsedMs = (_animElapsed * 1000).toInt();
    final visibleRect = _visibleLocalRect;
    for (final entity in bundle.map.entities) {
      final entityPresence = mapEntityPresencePredicate;
      if (entityPresence != null && !entityPresence(bundle.map.id, entity)) {
        continue;
      }
      // On garde deux passes explicites :
      // - background: rendu normal des entités élément-projet ;
      // - foreground: props explicitement forcés devant le décor.
      //
      // Cela permet de poser un petit objet sur une table sans transformer ce
      // composant en système de z-index générique.
      if (!shouldRenderProjectElementEntityInForegroundPass(
        entity,
        renderPass: renderPass,
      )) {
        continue;
      }
      // Viewport culling pour les entités.
      if (visibleRect != null) {
        final eLeft = entity.pos.x * cw;
        final eTop = entity.pos.y * ch;
        final eRight = eLeft + entity.size.width * cw;
        final eBottom = eTop + entity.size.height * ch;
        if (eRight < visibleRect.left ||
            eLeft > visibleRect.right ||
            eBottom < visibleRect.top ||
            eTop > visibleRect.bottom) {
          continue;
        }
      }
      if (entity.kind == MapEntityKind.npc) {
        final presence = npcMapPresencePredicate;
        if (presence != null && !presence(bundle.map.id, entity)) {
          continue;
        }
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
      if (!image.containsSourceRect(srcRect)) {
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
    RuntimeTilesetImage image,
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
    image.drawImageRect(
      canvas,
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

  void _paintTileLayer(Canvas canvas, TileLayer layer) {
    final layerId = layer.id;
    final layerName = layer.name;
    final opacity = layer.opacity;
    final explicitForeground = _isExplicitForegroundTileLayer(
      layerId: layerId,
      layerName: layerName,
    );
    final foregroundCells = _foregroundTileCellIndicesByLayerId[layerId];
    final shouldRenderThisLayer = switch (renderPass) {
      MapLayerRenderPass.background => !explicitForeground ||
          (foregroundCells != null && foregroundCells.isNotEmpty),
      MapLayerRenderPass.foreground => explicitForeground ||
          (foregroundCells != null && foregroundCells.isNotEmpty),
    };
    if (!shouldRenderThisLayer) {
      return;
    }
    final map = bundle.map;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final w = map.size.width;
    if (tw <= 0 || th <= 0 || layer.palette.isEmpty) {
      return;
    }
    final paint = Paint()..isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    if (opacity < 1) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity);
    }
    final animatedCells = _animatedPlacedCellsByLayerId[layerId];
    final scaleX = cw / tw;
    final scaleY = ch / th;
    final (:startX, :startY, :endX, :endY) = _visibleTileCellRange(layer);
    final elapsedMs = (_animElapsed * 1000).toInt();
    for (var y = startY; y < endY; y++) {
      for (var x = startX; x < endX; x++) {
        final idx = y * w + x;
        final entry = resolveTileLayerCell(layer, idx);
        if (entry == null) {
          continue;
        }
        final isForegroundCell = foregroundCells?.contains(idx) ?? false;
        final shouldDrawCell = switch (renderPass) {
          MapLayerRenderPass.background =>
            explicitForeground ? false : !isForegroundCell,
          MapLayerRenderPass.foreground =>
            explicitForeground || isForegroundCell,
        };
        if (!shouldDrawCell) {
          continue;
        }
        if (animatedCells != null) {
          final animatedCell = animatedCells[idx];
          if (animatedCell != null) {
            final drewAnimated = _paintAnimatedPlacedCell(
              canvas,
              animatedCell: animatedCell,
              x: x,
              y: y,
              dstWidth: cw,
              dstHeight: ch,
              paint: paint,
            );
            if (drewAnimated) {
              continue;
            }
          }
        }
        final source = _tilesetSourceById[entry.tilesetId];
        if (source != null) {
          final visual = _resolveTileLayerVisual(
            entry: entry,
            source: source,
            tileWidth: tw,
            tileHeight: th,
          );
          if (visual == null) continue;
          for (final slice in visual.frameAt(elapsedMs).slices) {
            final image = tileImagesByTilesetId[slice.assetId] ??
                tileImagesByTilesetId[entry.tilesetId];
            if (image == null) continue;
            final source = slice.sourceRect;
            final destination = slice.destinationRect;
            final src = Rect.fromLTWH(
              source.x.toDouble(),
              source.y.toDouble(),
              source.width.toDouble(),
              source.height.toDouble(),
            );
            if (!image.containsSourceRect(src)) continue;
            final dst = Rect.fromLTWH(
              x * cw + destination.x * scaleX,
              y * ch + destination.y * scaleY,
              destination.width * scaleX,
              destination.height * scaleY,
            );
            _drawTileLayerImage(
              canvas: canvas,
              image: image,
              sourceRect: src,
              destinationRect: dst,
              transform: entry.transform,
              paint: paint,
            );
          }
          continue;
        }
        final image = tileImagesByTilesetId[entry.tilesetId];
        if (image == null) continue;
        final cols = image.width ~/ tw;
        if (cols <= 0) continue;
        final sourceIndex = entry.localTileId;
        final col = sourceIndex % cols;
        final row = sourceIndex ~/ cols;
        final src = Rect.fromLTWH(
          (col * tw).toDouble(),
          (row * th).toDouble(),
          tw.toDouble(),
          th.toDouble(),
        );
        if (!image.containsSourceRect(src)) continue;
        final dst = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        _drawTileLayerImage(
          canvas: canvas,
          image: image,
          sourceRect: src,
          destinationRect: dst,
          transform: entry.transform,
          paint: paint,
        );
      }
    }
  }

  ProjectTilesetVisualResolution? _resolveTileLayerVisual({
    required TileLayerPaletteEntry entry,
    required ProjectTilesetSource source,
    required int tileWidth,
    required int tileHeight,
  }) {
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
    return _regularTileVisualCache.putIfAbsent(
      (entry.tilesetId, entry.localTileId),
      () => resolveRuntimeProjectTilesetVisual(
        source: source,
        selection: selection,
        cellWidth: tileWidth,
        cellHeight: tileHeight,
      ),
    );
  }

  void _drawTileLayerImage({
    required Canvas canvas,
    required RuntimeTilesetImage image,
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
      image.drawImageRect(
        canvas,
        sourceRect,
        Rect.fromLTWH(0, 0, destinationRect.width, destinationRect.height),
        paint,
      );
    } finally {
      canvas.restore();
    }
  }

  void _paintPlacedElementsForLayer(
    Canvas canvas, {
    required String layerId,
    required String layerName,
    required double opacity,
  }) {
    if (bundle.map.placedElements.isEmpty || opacity <= 0) {
      return;
    }
    final explicitForeground = _isExplicitForegroundTileLayer(
      layerId: layerId,
      layerName: layerName,
    );
    if (explicitForeground && renderPass == MapLayerRenderPass.background) {
      return;
    }
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    if (tw <= 0 || th <= 0) {
      return;
    }
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final elapsedMs = (_animElapsed * 1000).toInt();
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    final visibleRect = _visibleLocalRect;

    for (final instance in bundle.map.placedElements) {
      if (instance.layerId.trim() != layerId) {
        continue;
      }
      final effectiveOpacity =
          (opacity * instance.opacity).clamp(0.0, 1.0).toDouble();
      if (effectiveOpacity <= 0) {
        continue;
      }
      paint.color = Color.fromRGBO(255, 255, 255, effectiveOpacity);
      final entry = _elementById[instance.elementId.trim()];
      if (entry == null || entry.frames.isEmpty) {
        continue;
      }
      final frame = _pickEntityFrame(entry.frames, elapsedMs);
      final source = frame.source;
      if (source.width <= 0 || source.height <= 0) {
        continue;
      }
      final gridTransform = QuarterTurnGridTransform(
        sourceSize: GridSize(width: source.width, height: source.height),
        quarterTurns: instance.quarterTurns,
      );
      final collisionCells =
          instance.applyCollision ? entry.collisionProfile?.cells : null;
      final hasForegroundSplit = !explicitForeground &&
          (source.width > 1 || source.height > 1) &&
          collisionCells != null &&
          collisionCells.isNotEmpty;
      if (!explicitForeground &&
          renderPass == MapLayerRenderPass.foreground &&
          !hasForegroundSplit) {
        continue;
      }
      final collisionCellIndices = hasForegroundSplit
          ? <int>{
              for (final cell in collisionCells) cell.y * source.width + cell.x,
            }
          : const <int>{};
      // Viewport culling pour les éléments placés.
      if (visibleRect != null) {
        final dstLeft = instance.pos.x * cw;
        final dstTop = instance.pos.y * ch;
        final dstRight = dstLeft + gridTransform.destinationSize.width * cw;
        final dstBottom = dstTop + gridTransform.destinationSize.height * ch;
        if (dstRight < visibleRect.left ||
            dstLeft > visibleRect.right ||
            dstBottom < visibleRect.top ||
            dstTop > visibleRect.bottom) {
          continue;
        }
      }
      final tilesetId = frame.tilesetId.trim().isNotEmpty
          ? frame.tilesetId.trim()
          : entry.tilesetId.trim();
      if (tilesetId.isEmpty) {
        continue;
      }
      final image = tileImagesByTilesetId[tilesetId];
      if (image == null) {
        continue;
      }
      final src = Rect.fromLTWH(
        (source.x * tw).toDouble(),
        (source.y * th).toDouble(),
        (source.width * tw).toDouble(),
        (source.height * th).toDouble(),
      );
      if (!image.containsSourceRect(src)) {
        continue;
      }
      final dst = Rect.fromLTWH(
        instance.pos.x * cw,
        instance.pos.y * ch,
        gridTransform.destinationSize.width * cw,
        gridTransform.destinationSize.height * ch,
      );
      final sourcePixelSize = GridSize(
        width: source.width * tw,
        height: source.height * th,
      );
      final destinationPixelSize = GridSize(
        width: gridTransform.destinationSize.width * tw,
        height: gridTransform.destinationSize.height * th,
      );
      drawQuarterTurnPixels(
        canvas,
        image: image,
        sourceRect: src,
        destinationRect: dst,
        sourcePixelSize: sourcePixelSize,
        destinationPixelSize: destinationPixelSize,
        quarterTurns: gridTransform.quarterTurns,
        paint: paint,
        includeSourcePixel: hasForegroundSplit
            ? (sourcePixel) {
                final cellIndex =
                    (sourcePixel.y ~/ th) * source.width + sourcePixel.x ~/ tw;
                final isCollisionCell =
                    collisionCellIndices.contains(cellIndex);
                return switch (renderPass) {
                  MapLayerRenderPass.background => isCollisionCell,
                  MapLayerRenderPass.foreground => !isCollisionCell,
                };
              }
            : null,
      );
    }
  }

  bool _isExplicitForegroundTileLayer({
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

  static Map<String, Set<int>> _buildForegroundTileCellIndicesByLayerId(
    RuntimeMapBundle bundle,
  ) {
    final map = bundle.map;
    final tileLayerById = <String, TileLayer>{
      for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
    };
    if (tileLayerById.isEmpty || map.placedElements.isEmpty) {
      return const <String, Set<int>>{};
    }
    final elementById = {
      for (final entry in bundle.manifest.elements) entry.id: entry,
    };
    final out = <String, Set<int>>{};
    final mapW = map.size.width;
    final mapH = map.size.height;

    for (final instance in map.placedElements) {
      final layer = tileLayerById[instance.layerId];
      if (layer == null) {
        continue;
      }
      final entry = elementById[instance.elementId];
      if (entry == null || entry.frames.isEmpty) {
        continue;
      }
      final source = entry.frames.primaryFrame.source;
      final width = source.width <= 0 ? 1 : source.width;
      final height = source.height <= 0 ? 1 : source.height;
      if (width <= 1 && height <= 1) {
        continue;
      }
      if (!instance.applyCollision) {
        continue;
      }
      final gridTransform = QuarterTurnGridTransform(
        sourceSize: GridSize(width: width, height: height),
        quarterTurns: instance.quarterTurns,
      );
      final collisionCells = entry.collisionProfile?.cells;
      if (collisionCells == null || collisionCells.isEmpty) {
        continue;
      }
      final collisionSet = <int>{
        for (final c in collisionCells) c.y * width + c.x,
      };
      final layerMask = out.putIfAbsent(layer.id, () => <int>{});
      for (var ly = 0; ly < height; ly++) {
        for (var lx = 0; lx < width; lx++) {
          final localIndex = ly * width + lx;
          if (collisionSet.contains(localIndex)) {
            continue;
          }
          final destination = gridTransform.sourceToDestination(
            GridPos(x: lx, y: ly),
          );
          final x = instance.pos.x + destination.x;
          final y = instance.pos.y + destination.y;
          if (x < 0 || y < 0 || x >= mapW || y >= mapH) {
            continue;
          }
          final globalIndex = y * mapW + x;
          if (resolveTileLayerCell(layer, globalIndex) == null) {
            continue;
          }
          layerMask.add(globalIndex);
        }
      }
    }

    return out;
  }

  static Map<String, Map<int, _AnimatedPlacedCell>>
      _buildAnimatedPlacedCellsByLayerId(
    RuntimeMapBundle bundle,
  ) {
    final map = bundle.map;
    final tileLayerById = <String, TileLayer>{
      for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
    };
    if (tileLayerById.isEmpty || map.placedElements.isEmpty) {
      return const <String, Map<int, _AnimatedPlacedCell>>{};
    }
    final elementById = {
      for (final entry in bundle.manifest.elements) entry.id: entry,
    };
    final out = <String, Map<int, _AnimatedPlacedCell>>{};
    final mapW = map.size.width;
    final mapH = map.size.height;
    for (final instance in map.placedElements) {
      final layer = tileLayerById[instance.layerId];
      if (layer == null) {
        continue;
      }
      final entry = elementById[instance.elementId];
      if (entry == null || entry.frames.length < 2) {
        continue;
      }
      final animation = instance.animation ?? const MapPlacedElementAnimation();
      final frames = <_RuntimeAnimationFrame>[];
      for (final frame in entry.frames) {
        final source = frame.source;
        if (source.width <= 0 || source.height <= 0) {
          continue;
        }
        final tilesetId = frame.tilesetId.trim().isNotEmpty
            ? frame.tilesetId.trim()
            : entry.tilesetId.trim();
        if (tilesetId.isEmpty) {
          continue;
        }
        frames.add(
          _RuntimeAnimationFrame(
            tilesetId: tilesetId,
            source: source,
            durationMs: frame.durationMs,
          ),
        );
      }
      if (frames.length < 2) {
        continue;
      }
      final frameDurationsMs = normalizeElementFrameDurationsMs(
        frames.map((frame) => frame.durationMs).toList(growable: false),
      );
      final baseSource = frames.first.source;
      final width = baseSource.width <= 0 ? 1 : baseSource.width;
      final height = baseSource.height <= 0 ? 1 : baseSource.height;
      final gridTransform = QuarterTurnGridTransform(
        sourceSize: GridSize(width: width, height: height),
        quarterTurns: instance.quarterTurns,
      );
      final seed = stableHash32(instance.id);
      final layerCells =
          out.putIfAbsent(instance.layerId, () => <int, _AnimatedPlacedCell>{});
      for (var ly = 0; ly < height; ly++) {
        for (var lx = 0; lx < width; lx++) {
          final destination = gridTransform.sourceToDestination(
            GridPos(x: lx, y: ly),
          );
          final x = instance.pos.x + destination.x;
          final y = instance.pos.y + destination.y;
          if (x < 0 || y < 0 || x >= mapW || y >= mapH) {
            continue;
          }
          final index = y * mapW + x;
          if (resolveTileLayerCell(layer, index) == null) {
            continue;
          }
          layerCells[index] = _AnimatedPlacedCell(
            instanceId: instance.id,
            localX: lx,
            localY: ly,
            frames: frames,
            frameDurationsMs: frameDurationsMs,
            animation: animation,
            deterministicSeed: seed,
            quarterTurns: gridTransform.quarterTurns,
          );
        }
      }
    }
    return out;
  }

  static Map<String, _AnimatedPlacedInstanceSpec>
      _buildAnimatedPlacedInstanceById(
    Map<String, Map<int, _AnimatedPlacedCell>> cellsByLayerId,
  ) {
    final out = <String, _AnimatedPlacedInstanceSpec>{};
    for (final cellsByIndex in cellsByLayerId.values) {
      for (final cell in cellsByIndex.values) {
        out.putIfAbsent(
          cell.instanceId,
          () => _AnimatedPlacedInstanceSpec(
            frameDurationsMs: cell.frameDurationsMs,
            speed: cell.animation.speed <= 0 ? 1.0 : cell.animation.speed,
          ),
        );
      }
    }
    return out;
  }

  bool _paintAnimatedPlacedCell(
    Canvas canvas, {
    required _AnimatedPlacedCell animatedCell,
    required int x,
    required int y,
    required double dstWidth,
    required double dstHeight,
    required Paint paint,
  }) {
    final oneShot = _activeOneShotByInstanceId[animatedCell.instanceId];
    int frameIndex;
    if (oneShot != null) {
      final resolution = resolvePlacedElementAnimationOneShotFrame(
        frameDurationsMs: oneShot.frameDurationsMs,
        elapsedMs: (_animElapsed * 1000) - oneShot.startedAtMs,
        speed: oneShot.speed,
      );
      frameIndex = resolution.frameIndex;
      if (resolution.completed) {
        _activeOneShotByInstanceId.remove(animatedCell.instanceId);
      }
    } else {
      final enabledOverride =
          _animationEnabledOverrideByInstanceId[animatedCell.instanceId];
      final effectiveAnimation = enabledOverride == null
          ? animatedCell.animation
          : animatedCell.animation.copyWith(enabled: enabledOverride);
      frameIndex = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: animatedCell.frameDurationsMs,
        elapsedMs: _animElapsed * 1000,
        animation: effectiveAnimation,
        deterministicSeed: animatedCell.deterministicSeed,
      );
    }
    if (frameIndex < 0 || frameIndex >= animatedCell.frames.length) {
      return false;
    }
    final frame = animatedCell.frames[frameIndex];
    final image = tileImagesByTilesetId[frame.tilesetId];
    if (image == null) {
      return false;
    }
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    if (tw <= 0 || th <= 0) {
      return false;
    }
    if (animatedCell.localX < 0 ||
        animatedCell.localY < 0 ||
        animatedCell.localX >= frame.source.width ||
        animatedCell.localY >= frame.source.height) {
      return false;
    }
    final sx = (frame.source.x + animatedCell.localX) * tw;
    final sy = (frame.source.y + animatedCell.localY) * th;
    final src = Rect.fromLTWH(
      sx.toDouble(),
      sy.toDouble(),
      tw.toDouble(),
      th.toDouble(),
    );
    if (!image.containsSourceRect(src)) {
      return false;
    }
    final dst = Rect.fromLTWH(x * dstWidth, y * dstHeight, dstWidth, dstHeight);
    final result = drawQuarterTurnPixels(
      canvas,
      image: image,
      sourceRect: src,
      destinationRect: dst,
      sourcePixelSize: GridSize(width: tw, height: th),
      destinationPixelSize: GridSize(width: tw, height: th),
      quarterTurns: animatedCell.quarterTurns,
      paint: paint,
    );
    return result.drawRunCount > 0;
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
    final paint = Paint()..color = Color.fromRGBO(255, 153, 0, 0.30 * opacity);
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

  void _paintPlacedElementsCollisionOverlay(Canvas canvas) {
    final w = bundle.map.size.width;
    final h = bundle.map.size.height;
    if (w <= 0 || h <= 0) {
      return;
    }
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final paint = Paint()..color = const Color.fromRGBO(255, 153, 0, 0.30);
    final elementById = _elementById;
    final tileWidth = bundle.manifest.settings.tileWidth;
    final tileHeight = bundle.manifest.settings.tileHeight;
    final pixelScaleX = tileWidth > 0 ? cw / tileWidth : 1.0;
    final pixelScaleY = tileHeight > 0 ? ch / tileHeight : 1.0;
    final mapWidthPx = w * cw;
    final mapHeightPx = h * ch;
    for (final instance in bundle.map.placedElements) {
      if (!instance.applyCollision) {
        continue;
      }
      final element = elementById[instance.elementId];
      final profile = element?.collisionProfile;
      if (element == null || element.frames.isEmpty || profile == null) {
        continue;
      }
      final footprint = resolveMapPlacedElementFootprint(
        instance: instance,
        element: element,
      );
      final worldLeftPx = instance.pos.x * cw;
      final worldTopPx = instance.pos.y * ch;
      // Overlay debug : masque **collision** (blocage), pas l’occlusion.
      final collisionMask = profile.collisionMask;
      if (collisionMask != null) {
        if (collisionMask.widthPx <= 0 || collisionMask.heightPx <= 0) {
          continue;
        }
        List<bool> maskPixels;
        try {
          maskPixels = ElementCollisionMaskCodec.decodePackedBits(
            widthPx: collisionMask.widthPx,
            heightPx: collisionMask.heightPx,
            dataBase64: collisionMask.dataBase64,
          );
        } catch (_) {
          continue;
        }
        final destinationPixelSize = GridSize(
          width: footprint.quarterTurns == 0
              ? collisionMask.widthPx
              : footprint.destinationSize.width * tileWidth,
          height: footprint.quarterTurns == 0
              ? collisionMask.heightPx
              : footprint.destinationSize.height * tileHeight,
        );
        final pixelTransform = QuarterTurnPixelTransform(
          sourcePixelSize: GridSize(
            width: collisionMask.widthPx,
            height: collisionMask.heightPx,
          ),
          destinationPixelSize: destinationPixelSize,
          quarterTurns: footprint.quarterTurns,
        );
        for (var py = 0; py < destinationPixelSize.height; py++) {
          for (var px = 0; px < destinationPixelSize.width; px++) {
            final source = pixelTransform.destinationPixelToSourcePixel(
              GridPos(x: px, y: py),
            );
            final idx = source.y * collisionMask.widthPx + source.x;
            if (idx < 0 || idx >= maskPixels.length || !maskPixels[idx]) {
              continue;
            }
            final dx = worldLeftPx + px * pixelScaleX;
            final dy = worldTopPx + py * pixelScaleY;
            if (dx + pixelScaleX <= 0 ||
                dy + pixelScaleY <= 0 ||
                dx >= mapWidthPx ||
                dy >= mapHeightPx) {
              continue;
            }
            canvas.drawRect(
              Rect.fromLTWH(dx, dy, pixelScaleX, pixelScaleY),
              paint,
            );
          }
        }
        continue;
      }

      // Fallback legacy: profils sans masque collision pixel.
      for (final local in profile.cells) {
        final destination = footprint.sourceToDestination(local);
        final x = instance.pos.x + destination.x;
        final y = instance.pos.y + destination.y;
        if (x < 0 || y < 0 || x >= w || y >= h) {
          continue;
        }
        canvas.drawRect(Rect.fromLTWH(x * cw, y * ch, cw, ch), paint);
      }
    }
  }
}

class _RuntimeAnimationFrame {
  const _RuntimeAnimationFrame({
    required this.tilesetId,
    required this.source,
    required this.durationMs,
  });

  final String tilesetId;
  final TilesetSourceRect source;
  final int? durationMs;
}

class _AnimatedPlacedCell {
  const _AnimatedPlacedCell({
    required this.instanceId,
    required this.localX,
    required this.localY,
    required this.frames,
    required this.frameDurationsMs,
    required this.animation,
    required this.deterministicSeed,
    required this.quarterTurns,
  });

  final String instanceId;
  final int localX;
  final int localY;
  final List<_RuntimeAnimationFrame> frames;
  final List<int> frameDurationsMs;
  final MapPlacedElementAnimation animation;
  final int deterministicSeed;
  final int quarterTurns;
}

class _AnimatedPlacedInstanceSpec {
  const _AnimatedPlacedInstanceSpec({
    required this.frameDurationsMs,
    required this.speed,
  });

  final List<int> frameDurationsMs;
  final double speed;
}

class _ActiveOneShotAnimation {
  const _ActiveOneShotAnimation({
    required this.startedAtMs,
    required this.frameDurationsMs,
    required this.speed,
  });

  final double startedAtMs;
  final List<int> frameDurationsMs;
  final double speed;
}
