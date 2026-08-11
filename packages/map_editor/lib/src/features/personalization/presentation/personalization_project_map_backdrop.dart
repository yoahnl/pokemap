import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../theme/pokemap_color_tokens.dart';
import '../../../ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart';
import '../../../ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart';
import '../../../ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart';
import '../../../ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart';

class PersonalizationProjectMapBackdrop extends StatefulWidget {
  const PersonalizationProjectMapBackdrop({
    super.key,
    required this.map,
    required this.colors,
    required this.projectRootPath,
    this.manifest,
    this.resolveTilesetPath,
  });

  final MapData map;
  final PokeMapColorTokens colors;
  final String projectRootPath;
  final ProjectManifest? manifest;
  final String? Function(String tilesetId)? resolveTilesetPath;

  @override
  State<PersonalizationProjectMapBackdrop> createState() =>
      _PersonalizationProjectMapBackdropState();
}

class _PersonalizationProjectMapBackdropState
    extends State<PersonalizationProjectMapBackdrop> {
  final CinematicMapBackdropLayerPlanLoader _loader =
      CinematicMapBackdropLayerPlanLoader();
  CinematicMapBackdropLayerRenderPlan? _plan;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant PersonalizationProjectMapBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.map != widget.map ||
        oldWidget.manifest != widget.manifest ||
        oldWidget.projectRootPath != widget.projectRootPath) {
      _reload();
    }
  }

  @override
  void dispose() {
    _loader.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      key: const ValueKey<String>('personalization-project-map-backdrop'),
      fit: StackFit.expand,
      children: <Widget>[
        if (_plan case final plan?)
          CustomPaint(
            key: const ValueKey<String>('personalization-project-map-renderer'),
            painter: CinematicMapBackdropLayerRenderPainter(
              plan: plan,
              palette: CinematicMapBackdropTileRenderPalette(
                background: widget.colors.surfaceSubtle,
                border: widget.colors.borderStrong,
                grid: widget.colors.borderSubtle,
              ),
            ),
          )
        else
          CustomPaint(
            key: const ValueKey<String>('personalization-project-map-fallback'),
            painter: _ProjectMapFallbackPainter(
              map: widget.map,
              colors: widget.colors,
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.colors.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.colors.borderStrong),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                widget.map.name,
                style: TextStyle(
                  color: widget.colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _reload() {
    final generation = ++_generation;
    _plan = null;
    final manifest = widget.manifest;
    if (manifest == null) return;
    final stageMap = manifest.maps
        .where((entry) => entry.id == widget.map.id)
        .firstOrNull;
    final asset = CinematicAsset(
      id: 'personalization-preview-${widget.map.id}',
      title: widget.map.name,
      mapId: widget.map.id,
      stageContext: CinematicStageContext(
        backdropMode: CinematicStageBackdropMode.projectMap,
      ),
      timeline: CinematicTimeline(),
    );
    final previewModel = buildCinematicMapBackdropPreviewModel(
      asset: asset,
      stageMap: stageMap,
      mapData: widget.map,
      availableTilesetIds: <String>{
        for (final tileset in manifest.tilesets) tileset.id,
      },
      smartTileCatalog: manifest.smartTileCatalog,
    );
    _loader
        .load(
          manifest: manifest,
          mapData: widget.map,
          previewModel: previewModel,
          resolveTilesetPath: _resolveTilesetPath,
        )
        .then((plan) {
          if (!mounted || generation != _generation) return;
          setState(() => _plan = plan);
        });
  }

  String? _resolveTilesetPath(String tilesetId) {
    final resolved = widget.resolveTilesetPath?.call(tilesetId);
    if (resolved != null && resolved.trim().isNotEmpty) return resolved;
    final manifest = widget.manifest;
    if (manifest == null) return null;
    final tileset = manifest.tilesets
        .where((entry) => entry.id == tilesetId)
        .firstOrNull;
    final relativePath = tileset?.relativePath.trim();
    if (relativePath == null || relativePath.isEmpty) return null;
    return p.isAbsolute(relativePath)
        ? relativePath
        : p.join(widget.projectRootPath, relativePath);
  }
}

class _ProjectMapFallbackPainter extends CustomPainter {
  const _ProjectMapFallbackPainter({required this.map, required this.colors});

  final MapData map;
  final PokeMapColorTokens colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colors.backgroundShell,
    );
    final cell = math.min(
      size.width / map.size.width,
      size.height / map.size.height,
    );
    final mapSize = Size(map.size.width * cell, map.size.height * cell);
    final origin = Offset(
      (size.width - mapSize.width) / 2,
      (size.height - mapSize.height) / 2,
    );
    final mapRect = origin & mapSize;
    canvas.drawRect(mapRect, Paint()..color = colors.surfaceSubtle);
    final grid = Paint()
      ..color = colors.borderSubtle
      ..strokeWidth = 1;
    for (var x = 0; x <= map.size.width; x++) {
      final dx = origin.dx + x * cell;
      canvas.drawLine(
        Offset(dx, origin.dy),
        Offset(dx, origin.dy + mapSize.height),
        grid,
      );
    }
    for (var y = 0; y <= map.size.height; y++) {
      final dy = origin.dy + y * cell;
      canvas.drawLine(
        Offset(origin.dx, dy),
        Offset(origin.dx + mapSize.width, dy),
        grid,
      );
    }
    for (final zone in map.gameplayZones) {
      canvas.drawRect(
        Rect.fromLTWH(
          origin.dx + zone.area.pos.x * cell,
          origin.dy + zone.area.pos.y * cell,
          zone.area.size.width * cell,
          zone.area.size.height * cell,
        ),
        Paint()..color = colors.mapAccent.withValues(alpha: 0.28),
      );
    }
    for (final entity in map.entities) {
      final center = Offset(
        origin.dx + (entity.pos.x + 0.5) * cell,
        origin.dy + (entity.pos.y + 0.5) * cell,
      );
      canvas.drawCircle(
        center,
        (cell * 0.28).clamp(3, 16),
        Paint()
          ..color = entity.kind == MapEntityKind.npc
              ? colors.dialogue
              : colors.brandPrimary,
      );
    }
    canvas.drawRect(
      mapRect,
      Paint()
        ..color = colors.borderStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ProjectMapFallbackPainter oldDelegate) =>
      oldDelegate.map != map || oldDelegate.colors != colors;
}
