import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';

typedef BorderCanonicalGalleryFrame = ({
  Uint8List bytes,
  BorderVisualFrameSnapshot metadata,
});

/// Neutral, editor-only rendering of one resolved canonical Border sample.
///
/// It displays the immutable snapshot bytes prepared for publication. It does
/// not solve, persist, or mutate a map, and it has no runtime dependency.
class BorderCanonicalGalleryCanvas extends StatefulWidget {
  const BorderCanonicalGalleryCanvas({
    super.key,
    required this.semanticsLabel,
    required this.mapSize,
    required this.geometry,
    required this.tileSizePx,
    required this.materialization,
    required this.catalog,
    required this.framesBySnapshotId,
  });

  final String semanticsLabel;
  final GridSize mapSize;
  final BorderFeatureGeometry geometry;
  final GridSize tileSizePx;
  final BorderMaterialization? materialization;
  final ProjectBorderCatalog catalog;

  /// Every immutable candidate frame, in authored playback order.
  final Map<String, List<BorderCanonicalGalleryFrame>> framesBySnapshotId;

  @override
  State<BorderCanonicalGalleryCanvas> createState() =>
      _BorderCanonicalGalleryCanvasState();
}

class _BorderCanonicalGalleryCanvasState
    extends State<BorderCanonicalGalleryCanvas> {
  Timer? _animationTimer;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNextFrame();
  }

  @override
  void didUpdateWidget(BorderCanonicalGalleryCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.materialization != widget.materialization ||
        oldWidget.catalog != widget.catalog ||
        !identical(oldWidget.framesBySnapshotId, widget.framesBySnapshotId)) {
      _animationTimer?.cancel();
      _elapsedMs = 0;
      _scheduleNextFrame();
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.materialization;
    if (resolved == null) {
      return const PokeMapEmptyState(
        title: 'Ce cas ne peut pas encore être généré.',
        description: 'Corrigez les diagnostics puis régénérez la galerie.',
        icon: Icon(CupertinoIcons.exclamationmark_triangle),
      );
    }
    final worldWidth = widget.mapSize.width * widget.tileSizePx.width;
    final worldHeight = widget.mapSize.height * widget.tileSizePx.height;
    final colors = context.pokeMapColors;
    return Semantics(
      label: widget.semanticsLabel,
      image: true,
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: colors.surfaceSubtle,
          child: AspectRatio(
            aspectRatio: worldWidth / worldHeight,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: worldWidth.toDouble(),
                height: worldHeight.toDouble(),
                child: ClipRect(
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: <Widget>[
                      Positioned.fill(
                        child: CustomPaint(
                          key: ValueKey<String>(
                            widget.geometry is BorderStrokeGeometry
                                ? 'border-gallery-stroke-guide'
                                : 'border-gallery-region-guide',
                          ),
                          painter: _GalleryGeometryPainter(
                            mapSize: widget.mapSize,
                            geometry: widget.geometry,
                            tileSizePx: widget.tileSizePx,
                            backgroundColor: colors.surfaceSubtle,
                            landColor: colors.brandPrimarySoft,
                            gridColor: colors.borderSubtle,
                          ),
                        ),
                      ),
                      for (final ground in resolved.ground)
                        if (_snapshotImage(ground.visualSnapshotId)
                            case final image?)
                          Positioned(
                            key: ValueKey<String>(
                              'border-gallery-ground-${ground.x}-${ground.y}',
                            ),
                            left:
                                (ground.x * widget.tileSizePx.width).toDouble(),
                            top: (ground.y * widget.tileSizePx.height)
                                .toDouble(),
                            width: widget.tileSizePx.width.toDouble(),
                            height: widget.tileSizePx.height.toDouble(),
                            child: Image.memory(
                              image.bytes,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.none,
                              gaplessPlayback: true,
                            ),
                          ),
                      for (final placement in resolved.placements)
                        if (_snapshotImage(placement.visualSnapshotId)
                            case final image?)
                          _placement(image, placement),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderCanonicalGalleryFrame? _snapshotImage(
    String snapshotId,
  ) {
    final snapshot = widget.catalog.visualSnapshotById(snapshotId);
    final frames = widget.framesBySnapshotId[snapshotId];
    if (snapshot == null ||
        frames == null ||
        frames.length != snapshot.frames.length ||
        frames.isEmpty) {
      return null;
    }
    return frames[_frameIndexAt(frames, _elapsedMs)];
  }

  Widget _placement(
    BorderCanonicalGalleryFrame image,
    BorderResolvedPlacement placement,
  ) {
    final source = image.metadata.sourceRectPx;
    Widget raster = Image.memory(
      image.bytes,
      width: source.width.toDouble(),
      height: source.height.toDouble(),
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
    );
    if (placement.transform.flipX) {
      raster = Transform.flip(
        key: ValueKey<String>('border-gallery-flip-${placement.id}'),
        flipX: true,
        child: raster,
      );
    }
    raster = RotatedBox(
      quarterTurns: placement.transform.quarterTurns,
      child: raster,
    );
    final swapsDimensions = placement.transform.quarterTurns.isOdd;
    return Positioned(
      key: ValueKey<String>('border-gallery-placement-${placement.id}'),
      left: placement.topLeftWorldPx.x.toDouble(),
      top: placement.topLeftWorldPx.y.toDouble(),
      width: (swapsDimensions ? source.height : source.width).toDouble(),
      height: (swapsDimensions ? source.width : source.height).toDouble(),
      child: raster,
    );
  }

  void _scheduleNextFrame() {
    final delays = <int>[];
    for (final snapshotId in _referencedSnapshotIds()) {
      final frames = widget.framesBySnapshotId[snapshotId];
      if (frames == null || frames.length < 2) continue;
      delays.add(_millisecondsUntilNextFrame(frames, _elapsedMs));
    }
    if (delays.isEmpty) return;
    final delayMs = delays.reduce((left, right) => left < right ? left : right);
    _animationTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() => _elapsedMs += delayMs);
      _scheduleNextFrame();
    });
  }

  Set<String> _referencedSnapshotIds() {
    final resolved = widget.materialization;
    if (resolved == null) return const <String>{};
    return <String>{
      for (final ground in resolved.ground) ground.visualSnapshotId,
      for (final placement in resolved.placements) placement.visualSnapshotId,
    };
  }

  int _frameIndexAt(
    List<BorderCanonicalGalleryFrame> frames,
    int elapsedMs,
  ) {
    final totalDuration = frames.fold<int>(
      0,
      (sum, frame) => sum + frame.metadata.durationMs,
    );
    var remaining = elapsedMs % totalDuration;
    for (var index = 0; index < frames.length; index += 1) {
      final duration = frames[index].metadata.durationMs;
      if (remaining < duration) return index;
      remaining -= duration;
    }
    return 0;
  }

  int _millisecondsUntilNextFrame(
    List<BorderCanonicalGalleryFrame> frames,
    int elapsedMs,
  ) {
    final totalDuration = frames.fold<int>(
      0,
      (sum, frame) => sum + frame.metadata.durationMs,
    );
    var remaining = elapsedMs % totalDuration;
    for (final frame in frames) {
      if (remaining < frame.metadata.durationMs) {
        return frame.metadata.durationMs - remaining;
      }
      remaining -= frame.metadata.durationMs;
    }
    return frames.first.metadata.durationMs;
  }
}

final class _GalleryGeometryPainter extends CustomPainter {
  const _GalleryGeometryPainter({
    required this.mapSize,
    required this.geometry,
    required this.tileSizePx,
    required this.backgroundColor,
    required this.landColor,
    required this.gridColor,
  });

  final GridSize mapSize;
  final BorderFeatureGeometry geometry;
  final GridSize tileSizePx;
  final Color backgroundColor;
  final Color landColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    final landPaint = Paint()..color = landColor;
    switch (geometry) {
      case final BorderRegionGeometry region:
        _paintRegion(canvas, region, landPaint);
      case final BorderStrokeGeometry strokes:
        _paintStrokes(canvas, strokes, landPaint);
    }
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (var x = 0; x <= mapSize.width; x += 1) {
      final position = (x * tileSizePx.width).toDouble();
      canvas.drawLine(
        Offset(position, 0),
        Offset(position, size.height),
        gridPaint,
      );
    }
    for (var y = 0; y <= mapSize.height; y += 1) {
      final position = (y * tileSizePx.height).toDouble();
      canvas.drawLine(
          Offset(0, position), Offset(size.width, position), gridPaint);
    }
  }

  void _paintRegion(
    Canvas canvas,
    BorderRegionGeometry region,
    Paint landPaint,
  ) {
    for (var y = 0; y < region.height; y += 1) {
      for (var x = 0; x < region.width; x += 1) {
        if (!region.cells[y * region.width + x]) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (x * tileSizePx.width).toDouble(),
            (y * tileSizePx.height).toDouble(),
            tileSizePx.width.toDouble(),
            tileSizePx.height.toDouble(),
          ),
          landPaint,
        );
      }
    }
  }

  void _paintStrokes(
    Canvas canvas,
    BorderStrokeGeometry geometry,
    Paint landPaint,
  ) {
    final guidePaint = Paint()
      ..color = landPaint.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (tileSizePx.width < tileSizePx.height
              ? tileSizePx.width
              : tileSizePx.height) /
          5;
    for (final stroke in geometry.strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path();
      final first = _strokePoint(geometry, stroke.points.first);
      path.moveTo(first.dx, first.dy);
      for (final point in stroke.points.skip(1)) {
        final center = _strokePoint(geometry, point);
        path.lineTo(center.dx, center.dy);
      }
      if (stroke.closed) path.close();
      canvas.drawPath(path, guidePaint);
    }
  }

  Offset _cellCenter(GridPos point) => Offset(
        (point.x + 0.5) * tileSizePx.width,
        (point.y + 0.5) * tileSizePx.height,
      );

  Offset _strokePoint(BorderStrokeGeometry geometry, GridPos point) =>
      switch (geometry.alignment) {
        BorderStrokeAlignment.cellCenters => _cellCenter(point),
        BorderStrokeAlignment.gridEdges => Offset(
            point.x * tileSizePx.width.toDouble(),
            point.y * tileSizePx.height.toDouble(),
          ),
      };

  @override
  bool shouldRepaint(_GalleryGeometryPainter oldDelegate) =>
      mapSize != oldDelegate.mapSize ||
      geometry != oldDelegate.geometry ||
      tileSizePx != oldDelegate.tileSizePx ||
      backgroundColor != oldDelegate.backgroundColor ||
      landColor != oldDelegate.landColor ||
      gridColor != oldDelegate.gridColor;
}
