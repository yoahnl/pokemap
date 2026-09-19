import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import 'studio_map_resources.dart';

class StudioResourceThumbnail extends StatefulWidget {
  const StudioResourceThumbnail({
    super.key,
    this.element,
    this.tile,
    required this.resources,
    required this.size,
  });
  final ProjectElementEntry? element;
  final TileLayerPaletteEntry? tile;
  final StudioMapResources resources;
  final double size;
  @override
  State<StudioResourceThumbnail> createState() =>
      _StudioResourceThumbnailState();
}

class _StudioResourceThumbnailState extends State<StudioResourceThumbnail> {
  final Object _owner = Object();
  Set<String> _ids = {};
  Map<String, RuntimeTilesetImage?> _observed = {};
  List<_ThumbnailSlice> _slices = [];
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _ids = widget.element != null
        ? widget.resources.elementResourceIds(widget.element!)
        : widget.resources.tileResourceIds(widget.tile!);
    widget.resources.retain(_owner, _ids);
    widget.resources.addListener(_changed);
    _project();
  }

  void _project() {
    _observed = {for (final id in _ids) id: widget.resources.images[id]};
    _slices = _resolveSlices(widget.resources, widget.element, widget.tile);
    _failed = widget.resources.hasFailure(_ids);
  }

  void _changed() {
    if (!mounted) return;
    final changed = _ids.any(
      (id) => !identical(_observed[id], widget.resources.images[id]),
    );
    if (changed) {
      setState(_project);
    } else if (_failed != widget.resources.hasFailure(_ids)) {
      setState(() => _failed = widget.resources.hasFailure(_ids));
    }
  }

  @override
  void didUpdateWidget(StudioResourceThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resources != widget.resources ||
        oldWidget.element != widget.element ||
        oldWidget.tile != widget.tile) {
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
    if (_slices.isEmpty) {
      return SizedBox.square(
        dimension: widget.size,
        child: Icon(
          _failed ? Icons.broken_image_outlined : Icons.hourglass_empty,
          size: 18,
          semanticLabel: _failed
              ? 'Ressource indisponible'
              : 'Ressource en attente',
        ),
      );
    }
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _ThumbnailPainter(
        _slices,
        widget.tile?.transform ?? const SmartTileSpriteTransform(),
      ),
    );
  }
}

List<_ThumbnailSlice> _resolveSlices(
  StudioMapResources resources,
  ProjectElementEntry? element,
  TileLayerPaletteEntry? tile,
) {
  final settings = resources.manifest.settings;
  if (element != null) {
    final frame = element.frames.firstOrNull;
    if (frame == null) return [];
    final id = frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId;
    final image = resources.images[id];
    final source = Rect.fromLTWH(
      (frame.source.x * settings.tileWidth).toDouble(),
      (frame.source.y * settings.tileHeight).toDouble(),
      (frame.source.width * settings.tileWidth).toDouble(),
      (frame.source.height * settings.tileHeight).toDouble(),
    );
    return image == null || !image.containsSourceRect(source)
        ? []
        : [_ThumbnailSlice(image, source, Offset.zero & source.size)];
  }
  final entry = tile!;
  final source = resources.tilesets[entry.tilesetId]?.source;
  if (source == null) {
    final image = resources.images[entry.tilesetId];
    if (image == null) return [];
    final columns = image.width ~/ settings.tileWidth;
    if (columns == 0 || entry.localTileId < 0) return [];
    final rect = Rect.fromLTWH(
      (entry.localTileId % columns * settings.tileWidth).toDouble(),
      (entry.localTileId ~/ columns * settings.tileHeight).toDouble(),
      settings.tileWidth.toDouble(),
      settings.tileHeight.toDouble(),
    );
    return image.containsSourceRect(rect)
        ? [_ThumbnailSlice(image, rect, Offset.zero & rect.size)]
        : [];
  }
  try {
    final selection = switch (source) {
      ProjectRegularAtlasTilesetSource atlas =>
        ProjectTilesetVisualSelection.regularAtlas(
          source: TilesetSourceRect(
            x: entry.localTileId % atlas.columns,
            y: entry.localTileId ~/ atlas.columns,
          ),
        ),
      ProjectImageCollectionTilesetSource() =>
        ProjectTilesetVisualSelection.imageCollection(
          tileId: entry.localTileId,
        ),
    };
    final visual = const ProjectTilesetVisualResolver().resolve(
      source: source,
      selection: selection,
      cellWidth: settings.tileWidth,
      cellHeight: settings.tileHeight,
    );
    final slices = <_ThumbnailSlice>[];
    for (final slice in visual.frames.first.slices) {
      final image =
          resources.images[slice.assetId] ?? resources.images[entry.tilesetId];
      final src = slice.sourceRect;
      final dst = slice.destinationRect;
      final rect = Rect.fromLTWH(
        src.x.toDouble(),
        src.y.toDouble(),
        src.width.toDouble(),
        src.height.toDouble(),
      );
      if (image == null || !image.containsSourceRect(rect)) return [];
      slices.add(
        _ThumbnailSlice(
          image,
          rect,
          Rect.fromLTWH(
            dst.x.toDouble(),
            dst.y.toDouble(),
            dst.width.toDouble(),
            dst.height.toDouble(),
          ),
        ),
      );
    }
    return slices;
  } on Object {
    return [];
  }
}

final class _ThumbnailSlice {
  const _ThumbnailSlice(this.image, this.source, this.destination);
  final RuntimeTilesetImage image;
  final Rect source;
  final Rect destination;
}

class _ThumbnailPainter extends CustomPainter {
  _ThumbnailPainter(this.slices, this.transform);
  final List<_ThumbnailSlice> slices;
  final SmartTileSpriteTransform transform;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = slices
        .map((slice) => slice.destination)
        .reduce((a, b) => a.expandToInclude(b));
    final rotated = transform.quarterTurns.isOdd;
    final width = rotated ? bounds.height : bounds.width;
    final height = rotated ? bounds.width : bounds.height;
    final scale = math.min(size.width / width, size.height / height);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.rotate(transform.quarterTurns * math.pi / 2);
    if (transform.flipX) canvas.scale(-1, 1);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    for (final slice in slices) {
      slice.image.drawImageRect(
        canvas,
        slice.source,
        slice.destination,
        Paint()..filterQuality = FilterQuality.none,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbnailPainter oldDelegate) =>
      slices != oldDelegate.slices || transform != oldDelegate.transform;
}
