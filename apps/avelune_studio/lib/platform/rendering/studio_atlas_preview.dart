import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import 'studio_map_resources.dart';

class StudioAtlasPreview extends StatefulWidget {
  const StudioAtlasPreview({
    super.key,
    required this.resources,
    required this.tilesetId,
  });
  final StudioMapResources resources;
  final String tilesetId;
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
      return Center(
        child: Text(failure?.message ?? 'Chargement de la planche…'),
      );
    }
    return CustomPaint(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      painter: _AtlasPainter(image),
    );
  }
}

class _AtlasPainter extends CustomPainter {
  _AtlasPainter(this.image);
  final RuntimeTilesetImage image;
  @override
  void paint(Canvas canvas, Size size) {
    image.drawImageRect(
      canvas,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_AtlasPainter oldDelegate) =>
      !identical(image, oldDelegate.image);
}
