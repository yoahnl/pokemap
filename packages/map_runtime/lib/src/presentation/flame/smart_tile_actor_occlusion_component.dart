import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../application/runtime_map_bundle.dart';
import '../../infrastructure/runtime_tileset_image.dart';
import 'overworld_render_priority.dart';
import 'smart_tile_animation_activation_controller.dart';
import 'smart_tile_visual_renderer.dart';

@visibleForTesting
int smartTileActorOcclusionDepthPriority({
  required double mapOriginY,
  required int ownerRow,
  required double cellHeight,
}) =>
    overworldActorRenderPriority(
      mapOriginY + (ownerRow + 1) * cellHeight,
      tieBreaker: 1,
    );

final class SmartTileActorOcclusionLayerCollection {
  SmartTileActorOcclusionLayerCollection({
    required RuntimeMapBundle bundle,
    required Map<String, RuntimeTilesetImage> tileImagesByTilesetId,
    SmartTileAnimationActivationController? smartTileAnimationController,
  })  : _source = _SmartTileActorOcclusionRenderSource(
          bundle: bundle,
          tileImagesByTilesetId: tileImagesByTilesetId,
          smartTileAnimationController: smartTileAnimationController,
        ),
        _cellHeight = bundle.cellHeight,
        rows = <SmartTileActorOcclusionRowComponent>[] {
    if (_source.isEmpty) {
      return;
    }
    rows.addAll(
      List<SmartTileActorOcclusionRowComponent>.generate(
        bundle.map.size.height,
        (row) => SmartTileActorOcclusionRowComponent._(
          source: _source,
          ownerRow: row,
          size: Vector2(
            bundle.map.size.width * bundle.cellWidth,
            bundle.map.size.height * bundle.cellHeight,
          ),
        ),
        growable: false,
      ),
    );
    setMapOrigin(Vector2.zero());
  }

  final _SmartTileActorOcclusionRenderSource _source;
  final double _cellHeight;
  final List<SmartTileActorOcclusionRowComponent> rows;

  @visibleForTesting
  int get debugLastOwnerCellVisits => _source.debugLastOwnerCellVisits;

  void update(double dt) {
    _source.update(dt);
  }

  void setVisibleLocalRect(Rect? rect) {
    _source.setVisibleLocalRect(rect);
  }

  void setMapOrigin(Vector2 origin) {
    for (final row in rows) {
      row.position = origin.clone();
      row.priority = smartTileActorOcclusionDepthPriority(
        mapOriginY: origin.y,
        ownerRow: row.ownerRow,
        cellHeight: _cellHeight,
      );
    }
  }

  void removeFromParent() {
    for (final row in rows) {
      row.removeFromParent();
    }
  }
}

final class SmartTileActorOcclusionRowComponent extends PositionComponent {
  SmartTileActorOcclusionRowComponent._({
    required _SmartTileActorOcclusionRenderSource source,
    required this.ownerRow,
    required super.size,
  })  : _source = source,
        super(anchor: Anchor.topLeft);

  final _SmartTileActorOcclusionRenderSource _source;
  final int ownerRow;

  @override
  void render(Canvas canvas) {
    _source.renderRow(canvas, ownerRow);
  }
}

final class _SmartTileActorOcclusionRenderSource {
  _SmartTileActorOcclusionRenderSource({
    required this.bundle,
    required this.tileImagesByTilesetId,
    required this.smartTileAnimationController,
  }) : _layers = _buildLayers(bundle);

  final RuntimeMapBundle bundle;
  final Map<String, RuntimeTilesetImage> tileImagesByTilesetId;
  final SmartTileAnimationActivationController? smartTileAnimationController;
  final List<_ActorOcclusionLayerPlan> _layers;
  double _elapsedSeconds = 0;
  Rect? _visibleLocalRect;
  int _revision = 0;
  int _resolvedRevision = -1;
  Map<int, List<_ResolvedActorOcclusionVisual>> _visualsByOwnerRow =
      const <int, List<_ResolvedActorOcclusionVisual>>{};

  bool get isEmpty => _layers.isEmpty;

  @visibleForTesting
  int debugLastOwnerCellVisits = 0;

  void update(double dt) {
    _elapsedSeconds += dt;
    _revision += 1;
  }

  void setVisibleLocalRect(Rect? rect) {
    if (_visibleLocalRect == rect) {
      return;
    }
    _visibleLocalRect = rect;
    _revision += 1;
  }

  void renderRow(Canvas canvas, int ownerRow) {
    _resolveVisibleVisuals();
    final visuals = _visualsByOwnerRow[ownerRow];
    if (visuals == null) {
      return;
    }
    for (final resolved in visuals) {
      final image = tileImagesByTilesetId[resolved.visual.tilesetId];
      if (image == null) {
        continue;
      }
      drawRuntimeSmartTileVisual(
        canvas: canvas,
        image: image,
        visual: resolved.visual,
        paint: resolved.paint,
      );
    }
  }

  void _resolveVisibleVisuals() {
    if (_resolvedRevision == _revision) {
      return;
    }
    final viewport = _visibleLocalRect;
    final geometryViewport = viewport == null
        ? null
        : SmartTileGeometryRect(
            left: viewport.left,
            top: viewport.top,
            width: viewport.width,
            height: viewport.height,
          );
    final byRow = <int, List<_ResolvedActorOcclusionVisual>>{};
    var ownerCellVisits = 0;
    for (final layer in _layers) {
      final batch = layer.plan.resolveBatch(
        elapsedMs: (_elapsedSeconds * 1000).toInt(),
        viewportBounds: geometryViewport,
        animationElapsedMsForCell: smartTileAnimationController == null
            ? null
            : ({
                required int cellX,
                required int cellY,
                required int elapsedMs,
              }) =>
                smartTileAnimationController!.elapsedMsForCell(
                  layerId: layer.layerId,
                  cellX: cellX,
                  cellY: cellY,
                  globalElapsedMs: elapsedMs,
                ),
      );
      ownerCellVisits += batch.work.ownerCellVisits;
      for (final visual in batch.visuals) {
        (byRow[visual.cellY] ??= <_ResolvedActorOcclusionVisual>[]).add(
          _ResolvedActorOcclusionVisual(
            visual: visual,
            paint: layer.paint,
          ),
        );
      }
    }
    debugLastOwnerCellVisits = ownerCellVisits;
    _visualsByOwnerRow = byRow;
    _resolvedRevision = _revision;
  }

  static List<_ActorOcclusionLayerPlan> _buildLayers(
    RuntimeMapBundle bundle,
  ) {
    final catalog = bundle.manifest.smartTileCatalog;
    if (catalog.isEmpty) {
      return const <_ActorOcclusionLayerPlan>[];
    }
    final presets = <String, ProjectSmartTilePreset>{
      for (final preset in catalog.presets) preset.id: preset,
    };
    final patterns = <String, ProjectSmartTilePattern>{
      for (final pattern in catalog.patterns) pattern.id: pattern,
    };
    final result = <_ActorOcclusionLayerPlan>[];
    for (final layer in bundle.map.layers.whereType<SmartTileLayer>()) {
      if (!layer.isVisible || layer.opacity <= 0) {
        continue;
      }
      final preset = presets[layer.presetId];
      final presetHasActorVisuals = preset?.rules.any(
            (rule) => rule.candidates.any(
              (candidate) => candidate.parts.any(_isActorOcclusionPart),
            ),
          ) ??
          false;
      final patternHasActorVisuals = layer.patternStrokes.any((stroke) {
        final pattern = patterns[stroke.patternId];
        return pattern != null &&
            pattern.cells.any(
              (cell) => cell.parts.any(_isActorOcclusionPart),
            );
      });
      if (!presetHasActorVisuals && !patternHasActorVisuals) {
        continue;
      }
      final patternOwnerIndex = SmartTilePatternOwnerIndex.build(
        map: bundle.map,
        layer: layer,
        catalog: catalog,
      );
      final sourceTileWidth = bundle.manifest.settings.tileWidth;
      final sourceTileHeight = bundle.manifest.settings.tileHeight;
      result.add(
        _ActorOcclusionLayerPlan(
          layerId: layer.id,
          plan: buildSmartTileLayerVisualPlan(
            map: bundle.map,
            layer: layer,
            catalog: catalog,
            pass: SmartTileVisualPass.actorOcclusion,
            destinationCellWidth: bundle.cellWidth,
            destinationCellHeight: bundle.cellHeight,
            sourceCellWidth: sourceTileWidth > 0
                ? sourceTileWidth.toDouble()
                : bundle.cellWidth,
            sourceCellHeight: sourceTileHeight > 0
                ? sourceTileHeight.toDouble()
                : bundle.cellHeight,
            patternOwnerIndex: patternOwnerIndex,
          ),
          paint: Paint()
            ..isAntiAlias = false
            ..filterQuality = FilterQuality.none
            ..color = const Color(0xFFFFFFFF).withValues(
              alpha: layer.opacity.clamp(0.0, 1.0),
            ),
        ),
      );
    }
    return List<_ActorOcclusionLayerPlan>.unmodifiable(result);
  }
}

bool _isActorOcclusionPart(SmartTileVisualPart part) =>
    part.channel == SmartTileRenderChannel.actorOcclusion;

final class _ActorOcclusionLayerPlan {
  const _ActorOcclusionLayerPlan({
    required this.layerId,
    required this.plan,
    required this.paint,
  });

  final String layerId;
  final SmartTileLayerVisualPlan plan;
  final Paint paint;
}

final class _ResolvedActorOcclusionVisual {
  const _ResolvedActorOcclusionVisual({
    required this.visual,
    required this.paint,
  });

  final SmartTileLayerVisual visual;
  final Paint paint;
}
