import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_character_refs.dart';
import '../../application/runtime_manifest_tilesets.dart';
import '../../application/runtime_map_bundle.dart';
import '../../infrastructure/runtime_tileset_image.dart';
import '../../shadow/shadow_runtime_collection_provider.dart';
import '../../shadow/shadow_runtime_renderer.dart';
import '../../surface/surface_runtime_resolver.dart';
import 'path_pattern_runtime_render_resolution.dart';
import 'runtime_path_autotile.dart';

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
    this.shadowCollectionProvider,
    this.shadowRenderer = const ShadowRuntimeRenderer(),
  })  : _terrainPresetsByType = runtimeTerrainPresetsByType(bundle.manifest),
        _pathAutotileByPresetId = {
          for (final p in bundle.manifest.pathPresets)
            p.id: RuntimePathAutotileSet.fromPreset(p),
        },
        _pathRulesByLayerId = _buildPathRulesByLayerId(bundle),
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
  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
  final ShadowRuntimeRenderer shadowRenderer;
  final Map<TerrainType, ProjectTerrainPreset> _terrainPresetsByType;
  final Map<String, RuntimePathAutotileSet> _pathAutotileByPresetId;
  final Map<String, List<_PathRuleSpec>> _pathRulesByLayerId;
  final Map<String, Set<int>> _foregroundTileCellIndicesByLayerId;
  final Map<String, Map<int, _AnimatedPlacedCell>>
      _animatedPlacedCellsByLayerId;
  late final Map<String, _AnimatedPlacedInstanceSpec> _animatedInstanceById;
  final Map<String, bool> _animationEnabledOverrideByInstanceId =
      <String, bool>{};
  final Map<String, _ActiveOneShotAnimation> _activeOneShotByInstanceId =
      <String, _ActiveOneShotAnimation>{};
  final Map<_PathRuleKey, _ActivePathRuleOneShot> _activePathRuleOneShotByKey =
      <_PathRuleKey, _ActivePathRuleOneShot>{};
  final Map<_PathRuleKey, double> _activePathRuleLoopStartedAtMsByKey =
      <_PathRuleKey, double>{};
  final Map<_PathRuleCellKey, _ActivePathRuleOneShot>
      _activePathRuleCellOneShotByKey =
      <_PathRuleCellKey, _ActivePathRuleOneShot>{};
  final Map<_PathRuleCellKey, double> _activePathRuleCellLoopStartedAtMsByKey =
      <_PathRuleCellKey, double>{};

  late final Map<String, ProjectElementEntry> _elementById = {
    for (final e in bundle.manifest.elements) e.id: e,
  };

  double _animElapsed = 0.0;

  /// Rect visible dans l'espace local du composant (pixels monde relatifs à
  /// l'origine de la map). Mis à jour par le game chaque frame pour permettre
  /// le viewport culling. Si `null`, toute la carte est peinte (fallback).
  Rect? _visibleLocalRect;

  /// Cache de la liste des layers visibles — invalidé quand le bundle change.
  List<MapLayer>? _cachedVisibleLayers;

  /// Met à jour le rectangle visible **en coordonnées locales** du composant.
  ///
  /// Le game doit appeler cette méthode chaque frame après la mise à jour
  /// de la caméra, en convertissant le viewport caméra vers l'espace local
  /// de ce composant (soustraction de l'origine monde du composant).
  void setVisibleLocalRect(Rect? rect) {
    _visibleLocalRect = rect;
  }

  /// Retourne la plage de cellules visibles `(startX, startY, endX, endY)`
  /// en tenant compte du viewport. Si aucun viewport n'est connu, retourne
  /// la carte entière.
  ///
  /// La marge de 3 cellules compense les éléments multi-cellules (arbres,
  /// bâtiments) dont l'ancre est hors viewport mais dont le sprite dépasse
  /// dans la zone visible.
  ({int startX, int startY, int endX, int endY}) _visibleCellRange() {
    final w = bundle.map.size.width;
    final h = bundle.map.size.height;
    final rect = _visibleLocalRect;
    if (rect == null) {
      return (startX: 0, startY: 0, endX: w, endY: h);
    }
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    if (cw <= 0 || ch <= 0) {
      return (startX: 0, startY: 0, endX: w, endY: h);
    }
    const margin = 3;
    return (
      startX: math.max(0, (rect.left / cw).floor() - margin),
      startY: math.max(0, (rect.top / ch).floor() - margin),
      endX: math.min(w, (rect.right / cw).ceil() + margin),
      endY: math.min(h, (rect.bottom / ch).ceil() + margin),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animElapsed += dt;
    _pruneCompletedPathRuleOneShots();
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

  bool triggerPathAnimationRule({
    required String layerId,
    required String ruleId,
    required PathAnimationPlaybackMode mode,
    PathAnimationActivationScope scope =
        PathAnimationActivationScope.wholeLayer,
    int cellX = 0,
    int cellY = 0,
  }) {
    final trimmedLayerId = layerId.trim();
    final trimmedRuleId = ruleId.trim();
    if (trimmedLayerId.isEmpty || trimmedRuleId.isEmpty) {
      return false;
    }
    final key = _PathRuleKey(layerId: trimmedLayerId, ruleId: trimmedRuleId);
    final spec = _resolvePathRuleSpec(key);
    if (spec == null || !spec.hasAnimatedFrames) {
      return false;
    }
    if (scope == PathAnimationActivationScope.cellOnly) {
      final cellKey = _PathRuleCellKey(
          layerId: trimmedLayerId, ruleId: trimmedRuleId, x: cellX, y: cellY);
      switch (mode) {
        case PathAnimationPlaybackMode.playOnce:
          final existing = _activePathRuleCellOneShotByKey[cellKey];
          if (existing != null && !_isPathRuleOneShotCompleted(existing)) {
            return false;
          }
          _activePathRuleCellOneShotByKey[cellKey] = _ActivePathRuleOneShot(
            startedAtMs: _animElapsed * 1000,
            durationMs: spec.oneShotDurationMs,
          );
          return true;
        case PathAnimationPlaybackMode.restartOnTrigger:
          _activePathRuleCellOneShotByKey[cellKey] = _ActivePathRuleOneShot(
            startedAtMs: _animElapsed * 1000,
            durationMs: spec.oneShotDurationMs,
          );
          return true;
        case PathAnimationPlaybackMode.loopWhileActive:
          return false;
      }
    }
    switch (mode) {
      case PathAnimationPlaybackMode.playOnce:
        final existing = _activePathRuleOneShotByKey[key];
        if (existing != null && !_isPathRuleOneShotCompleted(existing)) {
          return false;
        }
        _activePathRuleOneShotByKey[key] = _ActivePathRuleOneShot(
          startedAtMs: _animElapsed * 1000,
          durationMs: spec.oneShotDurationMs,
        );
        return true;
      case PathAnimationPlaybackMode.restartOnTrigger:
        _activePathRuleOneShotByKey[key] = _ActivePathRuleOneShot(
          startedAtMs: _animElapsed * 1000,
          durationMs: spec.oneShotDurationMs,
        );
        return true;
      case PathAnimationPlaybackMode.loopWhileActive:
        return false;
    }
  }

  bool setPathAnimationRuleActive({
    required String layerId,
    required String ruleId,
    required bool active,
    PathAnimationActivationScope scope =
        PathAnimationActivationScope.wholeLayer,
    int cellX = 0,
    int cellY = 0,
  }) {
    final trimmedLayerId = layerId.trim();
    final trimmedRuleId = ruleId.trim();
    if (trimmedLayerId.isEmpty || trimmedRuleId.isEmpty) {
      return false;
    }
    final key = _PathRuleKey(layerId: trimmedLayerId, ruleId: trimmedRuleId);
    final spec = _resolvePathRuleSpec(key);
    if (spec == null || !spec.hasAnimatedFrames) {
      return false;
    }
    if (spec.rule.mode != PathAnimationPlaybackMode.loopWhileActive) {
      return false;
    }
    if (scope == PathAnimationActivationScope.cellOnly) {
      final cellKey = _PathRuleCellKey(
          layerId: trimmedLayerId, ruleId: trimmedRuleId, x: cellX, y: cellY);
      if (active) {
        _activePathRuleCellLoopStartedAtMsByKey.putIfAbsent(
            cellKey, () => _animElapsed * 1000);
      } else {
        _activePathRuleCellLoopStartedAtMsByKey.remove(cellKey);
      }
      return true;
    }
    if (active) {
      _activePathRuleLoopStartedAtMsByKey.putIfAbsent(
        key,
        () => _animElapsed * 1000,
      );
    } else {
      _activePathRuleLoopStartedAtMsByKey.remove(key);
    }
    return true;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final visible = _cachedVisibleLayers ??=
        bundle.map.layers.where((l) => l.isVisible).toList(growable: false);
    if (renderPass == MapLayerRenderPass.foreground) {
      for (var i = visible.length - 1; i >= 0; i--) {
        visible[i].whenOrNull(
          tile: (id, name, tilesetId, v, o, tiles) {
            _paintTileLayer(
              canvas,
              layerId: id,
              layerName: name,
              tilesetId: tilesetId,
              tiles: tiles,
              opacity: o,
            );
            _paintPlacedElementsForLayer(
              canvas,
              layerId: id,
              layerName: name,
              opacity: o,
            );
          },
        );
      }
      _paintEntities(canvas);
      return;
    }
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        terrain: (id, name, v, o, terrains) =>
            _paintTerrainLayer(canvas, terrains, o),
      );
    }
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        path: (id, name, v, o, presetId, cells, properties, animationMode,
                animationTriggers) =>
            _paintPathLayer(canvas, id, presetId, cells, o),
      );
    }
    for (var i = visible.length - 1; i >= 0; i--) {
      final layer = visible[i];
      if (layer is SurfaceLayer) {
        _paintSurfaceLayer(canvas, layer);
      }
    }
    _paintShadows(canvas);
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        tile: (id, name, tilesetId, v, o, tiles) {
          _paintTileLayer(
            canvas,
            layerId: id,
            layerName: name,
            tilesetId: tilesetId,
            tiles: tiles,
            opacity: o,
          );
          _paintPlacedElementsForLayer(
            canvas,
            layerId: id,
            layerName: name,
            opacity: o,
          );
        },
      );
    }
    _paintEntities(canvas);
    if (showCollisionOverlay) {
      for (var i = visible.length - 1; i >= 0; i--) {
        visible[i].whenOrNull(
          collision: (id, name, v, o, collisions) =>
              _paintCollisionLayer(canvas, collisions, o),
        );
      }
      _paintPlacedElementsCollisionOverlay(canvas);
    }
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

  void _paintSurfaceLayer(Canvas canvas, SurfaceLayer layer) {
    final instructions = resolveSurfaceRuntimeRenderInstructions(
      layer: layer,
      catalog: bundle.manifest.surfaceCatalog,
      elapsedMs: (_animElapsed * 1000).toInt(),
    );
    if (instructions.isEmpty) {
      return;
    }

    final alpha = layer.opacity.clamp(0.0, 1.0);
    if (alpha <= 0) {
      return;
    }

    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..color = Colors.white.withValues(alpha: alpha);
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final visibleRect = _visibleLocalRect;
    for (final instruction in instructions) {
      // Viewport culling pour les instructions surface.
      if (visibleRect != null) {
        final dstLeft = instruction.x * cw;
        final dstTop = instruction.y * ch;
        if (dstLeft + cw < visibleRect.left ||
            dstLeft > visibleRect.right ||
            dstTop + ch < visibleRect.top ||
            dstTop > visibleRect.bottom) {
          continue;
        }
      }
      final image = tileImagesByTilesetId[instruction.tilesetId];
      if (image == null) {
        continue;
      }
      final src = Rect.fromLTWH(
        instruction.sourceX.toDouble(),
        instruction.sourceY.toDouble(),
        instruction.sourceTileWidth.toDouble(),
        instruction.sourceTileHeight.toDouble(),
      );
      if (!image.containsSourceRect(src)) {
        continue;
      }
      final dst = Rect.fromLTWH(
        instruction.x * cw,
        instruction.y * ch,
        cw,
        ch,
      );
      image.drawImageRect(canvas, src, dst, paint);
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

  void _paintTileLayer(
    Canvas canvas, {
    required String layerId,
    required String layerName,
    required String? tilesetId,
    required List<int> tiles,
    required double opacity,
  }) {
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
    final animatedCells = _animatedPlacedCellsByLayerId[layerId];
    final (:startX, :startY, :endX, :endY) = _visibleCellRange();
    for (var y = startY; y < endY; y++) {
      for (var x = startX; x < endX; x++) {
        final idx = y * w + x;
        if (idx >= tiles.length) {
          continue;
        }
        final tileId = tiles[idx];
        if (tileId <= 0) {
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
        final sourceIndex = tileId - 1;
        final col = sourceIndex % cols;
        final row = sourceIndex ~/ cols;
        final sx = col * tw;
        final sy = row * th;
        final src = Rect.fromLTWH(
          sx.toDouble(),
          sy.toDouble(),
          tw.toDouble(),
          th.toDouble(),
        );
        if (!image.containsSourceRect(src)) {
          continue;
        }
        final dst = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        image.drawImageRect(canvas, src, dst, paint);
      }
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
    final shouldRenderThisLayer = switch (renderPass) {
      MapLayerRenderPass.background => !explicitForeground,
      MapLayerRenderPass.foreground => explicitForeground,
    };
    if (!shouldRenderThisLayer) {
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
    if (opacity < 1) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity);
    }
    final visibleRect = _visibleLocalRect;

    for (final instance in bundle.map.placedElements) {
      if (instance.layerId.trim() != layerId) {
        continue;
      }
      final entry = _elementById[instance.elementId.trim()];
      if (entry == null || entry.frames.isEmpty) {
        continue;
      }
      final frame = _pickEntityFrame(entry.frames, elapsedMs);
      final source = frame.source;
      if (source.width <= 0 || source.height <= 0) {
        continue;
      }
      // Viewport culling pour les éléments placés.
      if (visibleRect != null) {
        final dstLeft = instance.pos.x * cw;
        final dstTop = instance.pos.y * ch;
        final dstRight = dstLeft + source.width * cw;
        final dstBottom = dstTop + source.height * ch;
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
        source.width * cw,
        source.height * ch,
      );
      image.drawImageRect(canvas, src, dst, paint);
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
          final x = instance.pos.x + lx;
          final y = instance.pos.y + ly;
          if (x < 0 || y < 0 || x >= mapW || y >= mapH) {
            continue;
          }
          final globalIndex = y * mapW + x;
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
      final seed = stableHash32(instance.id);
      final layerCells =
          out.putIfAbsent(instance.layerId, () => <int, _AnimatedPlacedCell>{});
      for (var ly = 0; ly < height; ly++) {
        for (var lx = 0; lx < width; lx++) {
          final x = instance.pos.x + lx;
          final y = instance.pos.y + ly;
          if (x < 0 || y < 0 || x >= mapW || y >= mapH) {
            continue;
          }
          final index = y * mapW + x;
          if (index >= layer.tiles.length || layer.tiles[index] <= 0) {
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

  static Map<String, List<_PathRuleSpec>> _buildPathRulesByLayerId(
    RuntimeMapBundle bundle,
  ) {
    final pathPresetById = {
      for (final preset in bundle.manifest.pathPresets) preset.id: preset,
    };
    final out = <String, List<_PathRuleSpec>>{};
    for (final layer in bundle.map.layers.whereType<PathLayer>()) {
      if (layer.animationTriggers.isEmpty) {
        continue;
      }
      final preset = pathPresetById[layer.presetId.trim()];
      final hasAnimatedFrames =
          preset != null && _pathPresetHasAnimatedFrames(preset);
      final oneShotDurationMs =
          preset != null ? _pathPresetMaxOneShotDurationMs(preset) : 0;
      final specs = <_PathRuleSpec>[];
      for (var index = 0; index < layer.animationTriggers.length; index++) {
        final rule = layer.animationTriggers[index];
        if (!rule.enabled) {
          continue;
        }
        final ruleId = resolvePathAnimationTriggerRuleId(
          rule,
          index: index,
        );
        specs.add(
          _PathRuleSpec(
            ruleId: ruleId,
            rule: rule,
            scope: rule.scope,
            hasAnimatedFrames: hasAnimatedFrames,
            oneShotDurationMs: oneShotDurationMs,
          ),
        );
      }
      if (specs.isEmpty) {
        continue;
      }
      out[layer.id] = specs;
    }
    return out;
  }

  static bool _pathPresetHasAnimatedFrames(ProjectPathPreset preset) {
    for (final mapping in preset.variants) {
      if (mapping.frames.length >= 2) {
        return true;
      }
    }
    return false;
  }

  static int _pathPresetMaxOneShotDurationMs(ProjectPathPreset preset) {
    var maxDurationMs = 0;
    for (final mapping in preset.variants) {
      if (mapping.frames.length < 2) {
        continue;
      }
      final durations = normalizeElementFrameDurationsMs(
        mapping.frames.map((frame) => frame.durationMs).toList(growable: false),
      );
      var total = 0;
      for (final duration in durations) {
        total += duration;
      }
      if (total > maxDurationMs) {
        maxDurationMs = total;
      }
    }
    if (maxDurationMs <= 0) {
      return defaultPlacedElementAnimationFrameDurationMs;
    }
    return maxDurationMs;
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
    image.drawImageRect(canvas, src, dst, paint);
    return true;
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
      if (profile == null) {
        continue;
      }
      final worldLeftPx = instance.pos.x * cw;
      final worldTopPx = instance.pos.y * ch;
      // Overlay debug : masque **collision** (blocage), pas l’occlusion.
      final collisionMask = profile.collisionMask;
      if (collisionMask != null) {
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
        for (var py = 0; py < collisionMask.heightPx; py++) {
          for (var px = 0; px < collisionMask.widthPx; px++) {
            final idx = py * collisionMask.widthPx + px;
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
        final x = instance.pos.x + local.x;
        final y = instance.pos.y + local.y;
        if (x < 0 || y < 0 || x >= w || y >= h) {
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
    final (:startX, :startY, :endX, :endY) = _visibleCellRange();
    for (var y = startY; y < endY; y++) {
      for (var x = startX; x < endX; x++) {
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
    final resolved = _resolveTerrainPresetFrame(
      preset: preset,
      x: x,
      y: y,
      elapsedMs: _animElapsed * 1000,
    );
    if (resolved == null) {
      return false;
    }
    final tilesetId = resolved.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tileImagesByTilesetId[tilesetId];
    if (tilesetImage == null || tw <= 0 || th <= 0) {
      return false;
    }
    final sourceRect = resolved.source;
    final sourceX = sourceRect.x * tw;
    final sourceY = sourceRect.y * th;
    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      tw.toDouble(),
      th.toDouble(),
    );
    if (!tilesetImage.containsSourceRect(srcRect)) {
      return false;
    }
    tilesetImage.drawImageRect(
      canvas,
      srcRect,
      cell,
      Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none
        ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
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
    if (variants.isEmpty) {
      return null;
    }
    final chosen = pickTerrainPresetVariantForMapCell(
      variants: variants,
      mapX: x,
      mapY: y,
      phase: preset.id.hashCode,
    );
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
      layout: chosen.multiTileLayout,
      subtileSalt: frameSource.x * 73856093 + frameSource.y * 19349663,
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

  _PathLayerPlayback _resolvePathLayerPlayback({
    required String layerId,
    required String presetId,
  }) {
    // Check if the layer has alwaysActive mode
    final layer = bundle.map.layers.firstWhere(
      (l) => l.id == layerId,
      orElse: () => throw StateError('Layer not found: $layerId'),
    );

    if (layer is PathLayer &&
        layer.animationMode == PathAnimationMode.alwaysActive) {
      // Always active mode: loop animation continuously
      return const _PathLayerPlayback.alwaysLoop();
    }

    final allRules = _pathRulesByLayerId[layerId];
    if (allRules == null || allRules.isEmpty) {
      return const _PathLayerPlayback.staticFrame();
    }
    final wholeLayerRules = allRules
        .where((r) => r.scope == PathAnimationActivationScope.wholeLayer)
        .toList(growable: false);
    if (wholeLayerRules.isEmpty) {
      // Only cellOnly rules → layer stays static, cells animate individually.
      return const _PathLayerPlayback.staticFrame();
    }
    var hasActiveLoop = false;
    double? activeLoopStartedAtMs;
    for (final rule in wholeLayerRules) {
      final key = _PathRuleKey(layerId: layerId, ruleId: rule.ruleId);
      final oneShot = _activePathRuleOneShotByKey[key];
      if (oneShot != null) {
        if (_isPathRuleOneShotCompleted(oneShot)) {
          _activePathRuleOneShotByKey.remove(key);
        } else {
          return _PathLayerPlayback.oneShot(startedAtMs: oneShot.startedAtMs);
        }
      }
      final loopStartedAtMs = _activePathRuleLoopStartedAtMsByKey[key];
      if (loopStartedAtMs != null && !hasActiveLoop) {
        hasActiveLoop = true;
        activeLoopStartedAtMs = loopStartedAtMs;
      }
    }
    if (hasActiveLoop && activeLoopStartedAtMs != null) {
      return _PathLayerPlayback.loopFrom(startedAtMs: activeLoopStartedAtMs);
    }
    return const _PathLayerPlayback.staticFrame();
  }

  _PathLayerPlayback _resolvePathCellPlayback({
    required String layerId,
    required int x,
    required int y,
  }) {
    final rules = _pathRulesByLayerId[layerId];
    if (rules == null) return const _PathLayerPlayback.staticFrame();
    for (final rule in rules) {
      if (rule.scope != PathAnimationActivationScope.cellOnly) continue;
      final cellKey =
          _PathRuleCellKey(layerId: layerId, ruleId: rule.ruleId, x: x, y: y);
      final oneShot = _activePathRuleCellOneShotByKey[cellKey];
      if (oneShot != null) {
        if (_isPathRuleOneShotCompleted(oneShot)) {
          _activePathRuleCellOneShotByKey.remove(cellKey);
        } else {
          return _PathLayerPlayback.oneShot(startedAtMs: oneShot.startedAtMs);
        }
      }
      final loopStartedAtMs = _activePathRuleCellLoopStartedAtMsByKey[cellKey];
      if (loopStartedAtMs != null) {
        return _PathLayerPlayback.loopFrom(startedAtMs: loopStartedAtMs);
      }
    }
    return const _PathLayerPlayback.staticFrame();
  }

  bool _isPathRuleOneShotCompleted(_ActivePathRuleOneShot state) {
    final elapsed = (_animElapsed * 1000) - state.startedAtMs;
    return elapsed >= state.durationMs;
  }

  _PathRuleSpec? _resolvePathRuleSpec(_PathRuleKey key) {
    final rules = _pathRulesByLayerId[key.layerId];
    if (rules == null || rules.isEmpty) {
      return null;
    }
    for (final spec in rules) {
      if (spec.ruleId == key.ruleId) {
        return spec;
      }
    }
    return null;
  }

  void _pruneCompletedPathRuleOneShots() {
    if (_activePathRuleOneShotByKey.isEmpty) {
      return;
    }
    final completedKeys = <_PathRuleKey>[];
    for (final entry in _activePathRuleOneShotByKey.entries) {
      if (_isPathRuleOneShotCompleted(entry.value)) {
        completedKeys.add(entry.key);
      }
    }
    for (final key in completedKeys) {
      _activePathRuleOneShotByKey.remove(key);
    }
  }

  void _paintPathLayer(
    Canvas canvas,
    String layerId,
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
    final pid = presetId.trim();
    final autotileSet = pid.isEmpty ? null : _pathAutotileByPresetId[pid];
    final (:startX, :startY, :endX, :endY) = _visibleCellRange();
    for (var y = startY; y < endY; y++) {
      for (var x = startX; x < endX; x++) {
        final idx = y * w + x;
        if (idx >= cells.length || !cells[idx]) {
          continue;
        }
        final cell = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        final drawn = autotileSet != null &&
            _paintPathLayerCell(
              canvas,
              layerId: layerId,
              presetId: pid,
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
    required String layerId,
    required String presetId,
    required RuntimePathAutotileSet autotileSet,
    required List<bool> cells,
    required int x,
    required int y,
    required int tw,
    required int th,
    required Rect cell,
    required double alpha,
  }) {
    if (tw <= 0 || th <= 0) {
      return false;
    }
    final variant = resolvePathVariantAt(
      cells: cells,
      mapSize: bundle.map.size,
      pos: GridPos(x: x, y: y),
    );
    final cellPlayback = _resolvePathCellPlayback(layerId: layerId, x: x, y: y);
    final playback = cellPlayback.kind != _PathLayerPlaybackKind.staticFrame
        ? cellPlayback
        : _resolvePathLayerPlayback(layerId: layerId, presetId: presetId);
    return _paintAutotileVariantCell(
      canvas,
      presetId: presetId,
      autotileSet: autotileSet,
      playback: playback,
      variant: variant,
      mapX: x,
      mapY: y,
      tw: tw,
      th: th,
      dstRect: cell,
      alpha: alpha,
      elapsedMs: _animElapsed * 1000,
    );
  }

  bool _paintAutotileVariantCell(
    Canvas canvas, {
    required String presetId,
    required RuntimePathAutotileSet autotileSet,
    required _PathLayerPlayback playback,
    required TerrainPathVariant variant,
    required int mapX,
    required int mapY,
    required int tw,
    required int th,
    required Rect dstRect,
    required double alpha,
    required double elapsedMs,
  }) {
    final resolved = resolvePathPatternRuntimeRenderResolution(
      manifest: bundle.manifest,
      basePathPresetId: presetId,
      variant: variant,
      mapX: mapX,
      mapY: mapY,
      elapsedMs: elapsedMs,
      playback: _toRuntimePathPatternPlayback(playback),
      legacyAutotileSet: autotileSet,
    );
    if (resolved == null) {
      return false;
    }
    final source = resolved.sourceRect;
    final tilesetId = resolved.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tileImagesByTilesetId[tilesetId];
    if (tilesetImage == null) {
      return false;
    }
    final sourceX = source.x * tw;
    final sourceY = source.y * th;
    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      tw.toDouble(),
      th.toDouble(),
    );
    if (!tilesetImage.containsSourceRect(srcRect)) {
      return false;
    }
    tilesetImage.drawImageRect(
      canvas,
      srcRect,
      dstRect,
      Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none
        ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }

  PathPatternRuntimePlayback _toRuntimePathPatternPlayback(
    _PathLayerPlayback playback,
  ) {
    switch (playback.kind) {
      case _PathLayerPlaybackKind.alwaysLoop:
        return const PathPatternRuntimePlayback.alwaysLoop();
      case _PathLayerPlaybackKind.staticFrame:
        return const PathPatternRuntimePlayback.staticFrame();
      case _PathLayerPlaybackKind.loopFrom:
        return PathPatternRuntimePlayback.loopFrom(
          startedAtMs: playback.startedAtMs,
        );
      case _PathLayerPlaybackKind.oneShot:
        return PathPatternRuntimePlayback.oneShot(
          startedAtMs: playback.startedAtMs,
        );
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

class _ResolvedTerrainFrame {
  const _ResolvedTerrainFrame({
    required this.tilesetId,
    required this.source,
  });

  final String tilesetId;
  final TilesetSourceRect source;
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
  });

  final String instanceId;
  final int localX;
  final int localY;
  final List<_RuntimeAnimationFrame> frames;
  final List<int> frameDurationsMs;
  final MapPlacedElementAnimation animation;
  final int deterministicSeed;
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

class _PathRuleKey {
  const _PathRuleKey({
    required this.layerId,
    required this.ruleId,
  });

  final String layerId;
  final String ruleId;

  @override
  bool operator ==(Object other) {
    return other is _PathRuleKey &&
        other.layerId == layerId &&
        other.ruleId == ruleId;
  }

  @override
  int get hashCode => Object.hash(layerId, ruleId);
}

class _ActivePathRuleOneShot {
  const _ActivePathRuleOneShot({
    required this.startedAtMs,
    required this.durationMs,
  });

  final double startedAtMs;
  final int durationMs;
}

class _PathRuleSpec {
  const _PathRuleSpec({
    required this.ruleId,
    required this.rule,
    required this.scope,
    required this.hasAnimatedFrames,
    required this.oneShotDurationMs,
  });

  final String ruleId;
  final PathAnimationTriggerRule rule;
  final PathAnimationActivationScope scope;
  final bool hasAnimatedFrames;
  final int oneShotDurationMs;
}

class _PathRuleCellKey {
  const _PathRuleCellKey({
    required this.layerId,
    required this.ruleId,
    required this.x,
    required this.y,
  });

  final String layerId;
  final String ruleId;
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is _PathRuleCellKey &&
      other.layerId == layerId &&
      other.ruleId == ruleId &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(layerId, ruleId, x, y);
}

enum _PathLayerPlaybackKind {
  alwaysLoop,
  staticFrame,
  loopFrom,
  oneShot,
}

class _PathLayerPlayback {
  const _PathLayerPlayback._({
    required this.kind,
    required this.startedAtMs,
  });

  const _PathLayerPlayback.alwaysLoop()
      : this._(
          kind: _PathLayerPlaybackKind.alwaysLoop,
          startedAtMs: 0,
        );

  const _PathLayerPlayback.staticFrame()
      : this._(
          kind: _PathLayerPlaybackKind.staticFrame,
          startedAtMs: 0,
        );

  const _PathLayerPlayback.loopFrom({
    required double startedAtMs,
  }) : this._(
          kind: _PathLayerPlaybackKind.loopFrom,
          startedAtMs: startedAtMs,
        );

  const _PathLayerPlayback.oneShot({
    required double startedAtMs,
  }) : this._(
          kind: _PathLayerPlaybackKind.oneShot,
          startedAtMs: startedAtMs,
        );

  final _PathLayerPlaybackKind kind;
  final double startedAtMs;
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
