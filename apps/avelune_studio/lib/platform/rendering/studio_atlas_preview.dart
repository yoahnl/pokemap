import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import 'studio_thumbnail_resources.dart';

class StudioAtlasPreview extends StatefulWidget {
  const StudioAtlasPreview({
    super.key,
    required this.resources,
    required this.tilesetId,
    this.grid,
  });
  final StudioThumbnailResources resources;
  final String tilesetId;
  final ProjectRegularAtlasTilesetSource? grid;
  @override
  State<StudioAtlasPreview> createState() => _StudioAtlasPreviewState();
}

class _StudioAtlasPreviewState extends State<StudioAtlasPreview> {
  final Object _owner = Object();
  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    widget.resources.retain(_owner, {widget.tilesetId});
    widget.resources.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.resources.retain(_owner, {widget.tilesetId});
    });
  }

  @override
  void didUpdateWidget(StudioAtlasPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resources != widget.resources ||
        oldWidget.tilesetId != widget.tilesetId) {
      oldWidget.resources.removeListener(_changed);
      oldWidget.resources.release(_owner);
      _attach();
    }
  }

  @override
  void dispose() {
    widget.resources.removeListener(_changed);
    widget.resources.release(_owner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.resources.images[widget.tilesetId];
    if (image == null) {
      final failure = widget.resources.diagnostics
          .where((value) => value.resourceId == widget.tilesetId)
          .firstOrNull;
      final unavailable = widget.resources.hasFailure({widget.tilesetId});
      return Center(
        child: Text(
          failure?.message ??
              (unavailable
                  ? 'Aperçu indisponible'
                  : 'Chargement de la planche…'),
        ),
      );
    }
    final grid = widget.grid;
    final matchesImage =
        grid == null ||
        (grid.pixelWidth == image.width && grid.pixelHeight == image.height);
    final colors = Theme.of(context).colorScheme;
    final atlas = CustomPaint(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      painter: _AtlasPainter(
        image,
        matchesImage ? grid : null,
        colors.onSurface,
        colors.surface,
      ),
    );
    if (matchesImage) return atlas;
    return Column(
      children: [
        Expanded(child: atlas),
        Text(
          'Le fichier mesure ${image.width} × ${image.height} px. '
          'La grille enregistrée ne correspond pas à cette image.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AtlasPainter extends CustomPainter {
  _AtlasPainter(this.image, this.grid, this.line, this.contrast);

  final RuntimeTilesetImage image;
  final ProjectRegularAtlasTilesetSource? grid;
  final Color line;
  final Color contrast;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, source, size);
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    image.drawImageRect(
      canvas,
      Offset.zero & source,
      destination,
      Paint()..filterQuality = FilterQuality.none,
    );
    if (grid case final layout?) _drawGrid(canvas, destination, layout);
  }

  void _drawGrid(
    Canvas canvas,
    Rect bounds,
    ProjectRegularAtlasTilesetSource layout,
  ) {
    final scale = bounds.width / layout.pixelWidth;
    final width = layout.tileWidth * scale;
    final height = layout.tileHeight * scale;
    if (width < 2 || height < 2) return;
    final startX = bounds.left + layout.marginX * scale;
    final startY = bounds.top + layout.marginY * scale;
    final stepX = width + layout.spacingX * scale;
    final stepY = height + layout.spacingY * scale;
    final columns = layout.columns;
    final rows = layout.rows;
    final grid = Path();
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        grid.addRect(
          Rect.fromLTWH(
            startX + column * stepX,
            startY + row * stepY,
            width,
            height,
          ),
        );
      }
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = contrast;
    canvas.save();
    canvas.clipRect(bounds);
    canvas.drawPath(grid, stroke);
    canvas.drawPath(
      grid,
      stroke
        ..strokeWidth = 1
        ..color = line,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AtlasPainter oldDelegate) =>
      !identical(image, oldDelegate.image) ||
      grid != oldDelegate.grid ||
      line != oldDelegate.line ||
      contrast != oldDelegate.contrast;
}
