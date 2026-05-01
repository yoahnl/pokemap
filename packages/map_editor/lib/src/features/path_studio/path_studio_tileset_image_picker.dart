import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/services/tileset_transparent_color_processor.dart';
import 'path_studio_new_path_draft.dart';
import 'path_studio_theme.dart';

enum PathStudioTilesetImageStatus {
  missingProjectRoot,
  missingFile,
  invalidTileSize,
  invalidGrid,
  invalidImage,
  loaded,
}

final class PathStudioResolvedTilesetImage {
  const PathStudioResolvedTilesetImage({
    required this.absolutePath,
    required this.bytes,
    required this.imageWidthPx,
    required this.imageHeightPx,
    required this.tileWidthPx,
    required this.tileHeightPx,
    required this.columns,
    required this.rows,
  });

  final String absolutePath;
  final Uint8List bytes;
  final int imageWidthPx;
  final int imageHeightPx;
  final int tileWidthPx;
  final int tileHeightPx;
  final int columns;
  final int rows;
}

final class PathStudioTilesetImageLoadResult {
  const PathStudioTilesetImageLoadResult({
    required this.status,
    required this.message,
    this.image,
  });

  final PathStudioTilesetImageStatus status;
  final String message;
  final PathStudioResolvedTilesetImage? image;

  bool get hasImage =>
      status == PathStudioTilesetImageStatus.loaded && image != null;
}

Future<PathStudioTilesetImageLoadResult> loadPathStudioTilesetImage({
  required String? projectRootPath,
  required ProjectTilesetEntry tileset,
  required ProjectSettings settings,
}) async {
  final root = projectRootPath?.trim();
  if (root == null || root.isEmpty) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.missingProjectRoot,
      message: 'Racine projet indisponible',
    );
  }

  final tileWidth = settings.tileWidth;
  final tileHeight = settings.tileHeight;
  if (tileWidth <= 0 || tileHeight <= 0) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.invalidTileSize,
      message: 'Dimensions de tuile invalides',
    );
  }

  final absolutePath = p.normalize(p.join(root, tileset.relativePath));
  final file = File(absolutePath);
  if (!file.existsSync()) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.missingFile,
      message: 'Image du tileset introuvable',
    );
  }

  try {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const PathStudioTilesetImageLoadResult(
        status: PathStudioTilesetImageStatus.invalidImage,
        message: 'Image du tileset illisible',
      );
    }
    final columns = decoded.width ~/ tileWidth;
    final rows = decoded.height ~/ tileHeight;
    if (columns <= 0 || rows <= 0) {
      return const PathStudioTilesetImageLoadResult(
        status: PathStudioTilesetImageStatus.invalidGrid,
        message: 'Impossible de découper ce tileset',
      );
    }
    var displayBytes = bytes;
    if (tileset.transparentColor != null) {
      try {
        displayBytes = applyTilesetTransparentColorToPngBytes(
          imageBytes: bytes,
          transparentColor: tileset.transparentColor,
        );
      } catch (_) {
        displayBytes = bytes;
      }
    }
    return PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.loaded,
      message: 'Image du tileset chargée',
      image: PathStudioResolvedTilesetImage(
        absolutePath: absolutePath,
        bytes: displayBytes,
        imageWidthPx: decoded.width,
        imageHeightPx: decoded.height,
        tileWidthPx: tileWidth,
        tileHeightPx: tileHeight,
        columns: columns,
        rows: rows,
      ),
    );
  } catch (_) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.invalidImage,
      message: 'Image du tileset illisible',
    );
  }
}

TilesetSourceRect pathStudioTileSourceFromLocalPosition({
  required ui.Offset localPosition,
  required ui.Size displaySize,
  required int columns,
  required int rows,
}) {
  if (displaySize.width <= 0 || displaySize.height <= 0) {
    return const TilesetSourceRect(x: 0, y: 0);
  }
  final rawX = (localPosition.dx / displaySize.width * columns).floor();
  final rawY = (localPosition.dy / displaySize.height * rows).floor();
  return TilesetSourceRect(
    x: rawX.clamp(0, columns - 1).toInt(),
    y: rawY.clamp(0, rows - 1).toInt(),
  );
}

typedef PathStudioTilesetFallbackBuilder = Widget Function(
  BuildContext context,
  PathStudioTilesetImageLoadResult result,
);

class PathStudioImageBackedTilesetPicker extends StatefulWidget {
  const PathStudioImageBackedTilesetPicker({
    super.key,
    required this.projectRootPath,
    required this.tileset,
    required this.settings,
    required this.activeCell,
    required this.onTileSelected,
    required this.fallbackBuilder,
  });

  final String? projectRootPath;
  final ProjectTilesetEntry tileset;
  final ProjectSettings settings;
  final PathStudioNewPathDraftCell activeCell;
  final ValueChanged<TilesetSourceRect> onTileSelected;
  final PathStudioTilesetFallbackBuilder fallbackBuilder;

  @override
  State<PathStudioImageBackedTilesetPicker> createState() =>
      _PathStudioImageBackedTilesetPickerState();
}

class _PathStudioImageBackedTilesetPickerState
    extends State<PathStudioImageBackedTilesetPicker> {
  late Future<PathStudioTilesetImageLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void didUpdateWidget(covariant PathStudioImageBackedTilesetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.tileset.id != widget.tileset.id ||
        oldWidget.tileset.relativePath != widget.tileset.relativePath ||
        oldWidget.settings.tileWidth != widget.settings.tileWidth ||
        oldWidget.settings.tileHeight != widget.settings.tileHeight) {
      _loadFuture = _load();
    }
  }

  Future<PathStudioTilesetImageLoadResult> _load() {
    return loadPathStudioTilesetImage(
      projectRootPath: widget.projectRootPath,
      tileset: widget.tileset,
      settings: widget.settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PathStudioTilesetImageLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _TilesetImageLoadingState();
        }
        final result = snapshot.requireData;
        final image = result.image;
        if (!result.hasImage || image == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TilesetImageFallbackNotice(message: result.message),
              const SizedBox(height: 12),
              widget.fallbackBuilder(context, result),
            ],
          );
        }
        return _LoadedTilesetImagePicker(
          image: image,
          activeCell: widget.activeCell,
          onTileSelected: widget.onTileSelected,
        );
      },
    );
  }
}

class PathStudioTileSpritePreview extends StatefulWidget {
  const PathStudioTileSpritePreview({
    super.key,
    required this.projectRootPath,
    required this.tilesets,
    required this.settings,
    required this.tile,
    required this.fallback,
  });

  final String? projectRootPath;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final PathStudioNewPathDraftTile tile;
  final Widget fallback;

  @override
  State<PathStudioTileSpritePreview> createState() =>
      _PathStudioTileSpritePreviewState();
}

class _PathStudioTileSpritePreviewState
    extends State<PathStudioTileSpritePreview> {
  late Future<PathStudioTilesetImageLoadResult>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void didUpdateWidget(covariant PathStudioTileSpritePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.tile.tilesetId != widget.tile.tilesetId ||
        _tilesetFingerprint(oldWidget.tilesets, oldWidget.tile.tilesetId) !=
            _tilesetFingerprint(widget.tilesets, widget.tile.tilesetId) ||
        oldWidget.settings.tileWidth != widget.settings.tileWidth ||
        oldWidget.settings.tileHeight != widget.settings.tileHeight) {
      _loadFuture = _load();
    }
  }

  Future<PathStudioTilesetImageLoadResult>? _load() {
    final tileset = _tilesetById(widget.tilesets, widget.tile.tilesetId);
    if (tileset == null) {
      return null;
    }
    return loadPathStudioTilesetImage(
      projectRootPath: widget.projectRootPath,
      tileset: tileset,
      settings: widget.settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadFuture = _loadFuture;
    if (loadFuture == null) {
      return widget.fallback;
    }
    return FutureBuilder<PathStudioTilesetImageLoadResult>(
      future: loadFuture,
      builder: (context, snapshot) {
        final image = snapshot.data?.image;
        if (image == null) {
          return widget.fallback;
        }
        if (widget.tile.sourceX >= image.columns ||
            widget.tile.sourceY >= image.rows) {
          return widget.fallback;
        }
        return _TileSpritePreview(
          key: const Key('path-studio-tile-preview-image'),
          image: image,
          tile: widget.tile,
        );
      },
    );
  }
}

class _TileSpritePreview extends StatelessWidget {
  const _TileSpritePreview({
    super.key,
    required this.image,
    required this.tile,
  });

  final PathStudioResolvedTilesetImage image;
  final PathStudioNewPathDraftTile tile;

  @override
  Widget build(BuildContext context) {
    const previewWidth = 46.0;
    const previewHeight = 28.0;
    return Container(
      width: previewWidth,
      height: previewHeight,
      decoration: BoxDecoration(
        color: PathStudioTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PathStudioTheme.success.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(
            -tile.sourceX * previewWidth,
            -tile.sourceY * previewHeight,
          ),
          child: Image.memory(
            image.bytes,
            width: image.columns * previewWidth,
            height: image.rows * previewHeight,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

class _LoadedTilesetImagePicker extends StatefulWidget {
  const _LoadedTilesetImagePicker({
    required this.image,
    required this.activeCell,
    required this.onTileSelected,
  });

  final PathStudioResolvedTilesetImage image;
  final PathStudioNewPathDraftCell activeCell;
  final ValueChanged<TilesetSourceRect> onTileSelected;

  @override
  State<_LoadedTilesetImagePicker> createState() =>
      _LoadedTilesetImagePickerState();
}

class _LoadedTilesetImagePickerState extends State<_LoadedTilesetImagePicker> {
  static const double _minZoom = 0.5;
  static const double _maxZoom = 8.0;
  static const double _zoomStep = 1.25;

  double _zoom = 1.0;

  void _setZoom(double value) {
    setState(() {
      _zoom = double.parse(value.clamp(_minZoom, _maxZoom).toStringAsFixed(4));
    });
  }

  void _zoomIn() {
    _setZoom(_zoom * _zoomStep);
  }

  void _zoomOut() {
    _setZoom(_zoom / _zoomStep);
  }

  void _resetZoom() {
    _setZoom(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final selectedTile = widget.activeCell.tile;
    final zoomLabel = '${(_zoom * 100).round()}%';
    return Container(
      key: const Key('path-studio-image-backed-tileset-picker'),
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.surfaceStrong,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MacosIcon(
                CupertinoIcons.photo,
                color: PathStudioTheme.accentCyan,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Image du tileset chargée',
                style: TextStyle(
                  color: PathStudioTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Grille ${image.columns}×${image.rows}',
                style: const TextStyle(
                  color: PathStudioTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TilesetZoomButton(
                key: const Key('path-studio-tileset-zoom-out'),
                label: 'Zoom -',
                onPressed: _zoom > _minZoom ? _zoomOut : null,
              ),
              const SizedBox(width: 6),
              _TilesetZoomButton(
                key: const Key('path-studio-tileset-zoom-in'),
                label: 'Zoom +',
                onPressed: _zoom < _maxZoom ? _zoomIn : null,
              ),
              const SizedBox(width: 6),
              _TilesetZoomButton(
                key: const Key('path-studio-tileset-zoom-reset'),
                label: '100%',
                onPressed: _zoom == 1.0 ? null : _resetZoom,
              ),
              const SizedBox(width: 6),
              _TilesetZoomButton(
                key: const Key('path-studio-tileset-zoom-fit'),
                label: 'Ajuster',
                onPressed: _zoom == 1.0 ? null : _resetZoom,
              ),
              const Spacer(),
              Text(
                zoomLabel,
                key: const Key('path-studio-tileset-zoom-label'),
                style: const TextStyle(
                  color: PathStudioTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final naturalWidth = image.imageWidthPx.toDouble();
              final naturalHeight = image.imageHeightPx.toDouble();
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : naturalWidth;
              final baseWidth = math.min(
                maxWidth,
                math.max(naturalWidth, image.columns * 40.0),
              );
              final displayWidth = baseWidth * _zoom;
              final displayHeight = displayWidth * naturalHeight / naturalWidth;
              final displaySize = ui.Size(displayWidth, displayHeight);
              final viewportHeight = math.min(
                360.0,
                math.max(180.0, displayHeight),
              );
              return SizedBox(
                height: viewportHeight,
                child: SingleChildScrollView(
                  primary: false,
                  child: SingleChildScrollView(
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    child: GestureDetector(
                      onTapDown: (details) {
                        widget.onTileSelected(
                          pathStudioTileSourceFromLocalPosition(
                            localPosition: details.localPosition,
                            displaySize: displaySize,
                            columns: image.columns,
                            rows: image.rows,
                          ),
                        );
                      },
                      child: SizedBox(
                        key: const Key(
                            'path-studio-image-backed-tileset-canvas'),
                        width: displayWidth,
                        height: displayHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                image.bytes,
                                width: displayWidth,
                                height: displayHeight,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.none,
                                gaplessPlayback: true,
                              ),
                            ),
                            CustomPaint(
                              painter: _TilesetImageGridPainter(
                                image: image,
                                selectedSource: selectedTile?.tilesetId == null
                                    ? null
                                    : TilesetSourceRect(
                                        x: selectedTile!.sourceX,
                                        y: selectedTile.sourceY,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TilesetZoomButton extends StatelessWidget {
  const _TilesetZoomButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PushButton(
      controlSize: ControlSize.small,
      secondary: true,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _TilesetImageLoadingState extends StatelessWidget {
  const _TilesetImageLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: const Text(
        'Chargement du tileset…',
        style: TextStyle(
          color: PathStudioTheme.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TilesetImageFallbackNotice extends StatelessWidget {
  const _TilesetImageFallbackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.warning.withValues(alpha: 0.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MacosIcon(
            CupertinoIcons.exclamationmark_triangle,
            color: PathStudioTheme.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Utilisation du picker logique',
                  style: TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TilesetImageGridPainter extends CustomPainter {
  const _TilesetImageGridPainter({
    required this.image,
    required this.selectedSource,
  });

  final PathStudioResolvedTilesetImage image;
  final TilesetSourceRect? selectedSource;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final target = ui.Offset.zero & size;
    canvas.save();
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(target, const ui.Radius.circular(14)),
    );
    final cellWidth = size.width / image.columns;
    final cellHeight = size.height / image.rows;
    final gridPaint = ui.Paint()
      ..color = CupertinoColors.black.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var x = 1; x < image.columns; x += 1) {
      final dx = x * cellWidth;
      canvas.drawLine(ui.Offset(dx, 0), ui.Offset(dx, size.height), gridPaint);
    }
    for (var y = 1; y < image.rows; y += 1) {
      final dy = y * cellHeight;
      canvas.drawLine(ui.Offset(0, dy), ui.Offset(size.width, dy), gridPaint);
    }

    final selected = selectedSource;
    if (selected != null &&
        selected.x >= 0 &&
        selected.y >= 0 &&
        selected.x < image.columns &&
        selected.y < image.rows) {
      final rect = ui.Rect.fromLTWH(
        selected.x * cellWidth,
        selected.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(
        rect.deflate(1),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = PathStudioTheme.accentHover,
      );
      canvas.drawRect(
        rect.deflate(3),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = PathStudioTheme.accentCyan,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TilesetImageGridPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.selectedSource != selectedSource;
  }
}

ProjectTilesetEntry? _tilesetById(
  List<ProjectTilesetEntry> tilesets,
  String tilesetId,
) {
  for (final tileset in tilesets) {
    if (tileset.id == tilesetId) {
      return tileset;
    }
  }
  return null;
}

String? _tilesetFingerprint(
  List<ProjectTilesetEntry> tilesets,
  String tilesetId,
) {
  final tileset = _tilesetById(tilesets, tilesetId);
  if (tileset == null) {
    return null;
  }
  return '${tileset.id}|${tileset.relativePath}|${tileset.name}';
}
