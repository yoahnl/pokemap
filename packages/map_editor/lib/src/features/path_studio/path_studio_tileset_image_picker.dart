import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../app/providers/editor/editor_asset_cache_providers.dart';
import '../../application/services/tileset_transparent_color_processor.dart';
import '../../ui/assets/editor_image_cache.dart';
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
    required this.lease,
    required this.imageWidthPx,
    required this.imageHeightPx,
    required this.tileWidthPx,
    required this.tileHeightPx,
    required this.columns,
    required this.rows,
  });

  final String absolutePath;
  final EditorImageLoadResult lease;
  final int imageWidthPx;
  final int imageHeightPx;
  final int tileWidthPx;
  final int tileHeightPx;
  final int columns;
  final int rows;

  ui.Image get decodedImage => lease.image!;

  void dispose() => lease.dispose();
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

  void dispose() => image?.dispose();
}

Future<PathStudioTilesetImageLoadResult> loadPathStudioTilesetImage({
  required String? projectRootPath,
  required ProjectTilesetEntry tileset,
  required ProjectSettings settings,
  EditorImageCache? imageCache,
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
  final ownsCache = imageCache == null;
  final cache = imageCache ??
      EditorImageCache(
        sessionKey: root,
        retirementScheduler: (disposeImage) => disposeImage(),
      );
  final transparentColor = tileset.transparentColor;
  final lease = await cache.load(
    absolutePath,
    variantKey: transparentColor == null
        ? 'path-studio:original'
        : 'path-studio:transparent:${transparentColor.toHexRgb()}',
    transformBytes: transparentColor == null
        ? null
        : (bytes) => applyTilesetTransparentColorToPngBytes(
              imageBytes: bytes,
              transparentColor: transparentColor,
            ),
  );
  if (ownsCache) cache.dispose();
  final decoded = lease.image;
  if (decoded == null) {
    final failure = lease.failure;
    lease.dispose();
    return PathStudioTilesetImageLoadResult(
      status: failure?.kind == EditorImageFailureKind.missingFile
          ? PathStudioTilesetImageStatus.missingFile
          : PathStudioTilesetImageStatus.invalidImage,
      message: failure?.kind == EditorImageFailureKind.missingFile
          ? 'Image du tileset introuvable'
          : 'Image du tileset illisible',
    );
  }
  try {
    final columns = decoded.width ~/ tileWidth;
    final rows = decoded.height ~/ tileHeight;
    if (columns <= 0 || rows <= 0) {
      lease.dispose();
      return const PathStudioTilesetImageLoadResult(
        status: PathStudioTilesetImageStatus.invalidGrid,
        message: 'Impossible de découper ce tileset',
      );
    }
    return PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.loaded,
      message: 'Image du tileset chargée',
      image: PathStudioResolvedTilesetImage(
        absolutePath: absolutePath,
        lease: lease,
        imageWidthPx: decoded.width,
        imageHeightPx: decoded.height,
        tileWidthPx: tileWidth,
        tileHeightPx: tileHeight,
        columns: columns,
        rows: rows,
      ),
    );
  } on Object {
    lease.dispose();
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

class PathStudioImageBackedTilesetPicker extends ConsumerStatefulWidget {
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
  ConsumerState<PathStudioImageBackedTilesetPicker> createState() =>
      _PathStudioImageBackedTilesetPickerState();
}

class _PathStudioImageBackedTilesetPickerState
    extends ConsumerState<PathStudioImageBackedTilesetPicker> {
  late Future<PathStudioTilesetImageLoadResult> _loadFuture;
  PathStudioTilesetImageLoadResult? _ownedResult;
  var _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    _startLoad();
  }

  @override
  void didUpdateWidget(covariant PathStudioImageBackedTilesetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.tileset.id != widget.tileset.id ||
        oldWidget.tileset.relativePath != widget.tileset.relativePath ||
        oldWidget.settings.tileWidth != widget.settings.tileWidth ||
        oldWidget.settings.tileHeight != widget.settings.tileHeight) {
      _startLoad();
    }
  }

  Future<PathStudioTilesetImageLoadResult> _load() {
    final root = widget.projectRootPath?.trim();
    final cache = root == null || root.isEmpty
        ? null
        : ref.read(editorImageCacheProvider(root));
    return loadPathStudioTilesetImage(
      projectRootPath: widget.projectRootPath,
      tileset: widget.tileset,
      settings: widget.settings,
      imageCache: cache,
    );
  }

  void _startLoad() {
    final epoch = ++_loadEpoch;
    _loadFuture = _load().then((result) {
      if (!mounted || epoch != _loadEpoch) {
        result.dispose();
        return result;
      }
      _ownedResult?.dispose();
      _ownedResult = result;
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final root = widget.projectRootPath?.trim();
    if (root != null && root.isNotEmpty) {
      ref.watch(editorImageCacheProvider(root));
    }
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

  @override
  void dispose() {
    _loadEpoch++;
    _ownedResult?.dispose();
    super.dispose();
  }
}

class PathStudioTileSpritePreview extends ConsumerStatefulWidget {
  const PathStudioTileSpritePreview({
    super.key,
    required this.projectRootPath,
    required this.tilesets,
    required this.settings,
    required this.tile,
    required this.fallback,
    this.thumbnailKey,
  });

  final String? projectRootPath;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final PathStudioNewPathDraftTile tile;
  final Widget fallback;
  final Key? thumbnailKey;

  @override
  ConsumerState<PathStudioTileSpritePreview> createState() =>
      _PathStudioTileSpritePreviewState();
}

class _PathStudioTileSpritePreviewState
    extends ConsumerState<PathStudioTileSpritePreview> {
  late Future<PathStudioTilesetImageLoadResult>? _loadFuture;
  PathStudioTilesetImageLoadResult? _ownedResult;
  var _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    _startLoad();
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
      _startLoad();
    }
  }

  Future<PathStudioTilesetImageLoadResult>? _load() {
    final tileset = _tilesetById(widget.tilesets, widget.tile.tilesetId);
    if (tileset == null) {
      return null;
    }
    final root = widget.projectRootPath?.trim();
    final cache = root == null || root.isEmpty
        ? null
        : ref.read(editorImageCacheProvider(root));
    return loadPathStudioTilesetImage(
      projectRootPath: widget.projectRootPath,
      tileset: tileset,
      settings: widget.settings,
      imageCache: cache,
    );
  }

  void _startLoad() {
    final epoch = ++_loadEpoch;
    final load = _load();
    if (load == null) {
      _ownedResult?.dispose();
      _ownedResult = null;
      _loadFuture = null;
      return;
    }
    _loadFuture = load.then((result) {
      if (!mounted || epoch != _loadEpoch) {
        result.dispose();
        return result;
      }
      _ownedResult?.dispose();
      _ownedResult = result;
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final root = widget.projectRootPath?.trim();
    if (root != null && root.isNotEmpty) {
      ref.watch(editorImageCacheProvider(root));
    }
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
          key: widget.thumbnailKey,
          image: image,
          tile: widget.tile,
        );
      },
    );
  }

  @override
  void dispose() {
    _loadEpoch++;
    _ownedResult?.dispose();
    super.dispose();
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
    const previewSize = 46.0;
    return Container(
      width: previewSize,
      height: previewSize,
      decoration: BoxDecoration(
        color: PathStudioTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PathStudioTheme.success.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _TilePreviewCheckerboard(
            key: Key('path-studio-tile-preview-checkerboard'),
          ),
          CustomPaint(
            key: const Key('path-studio-tile-preview-image'),
            painter: _PathStudioTileImagePainter(
              image: image.decodedImage,
              sourceRect: ui.Rect.fromLTWH(
                (tile.sourceX * image.tileWidthPx).toDouble(),
                (tile.sourceY * image.tileHeightPx).toDouble(),
                image.tileWidthPx.toDouble(),
                image.tileHeightPx.toDouble(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathStudioTileImagePainter extends CustomPainter {
  const _PathStudioTileImagePainter({
    required this.image,
    required this.sourceRect,
  });

  final ui.Image image;
  final ui.Rect sourceRect;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawImageRect(
      image,
      sourceRect,
      ui.Offset.zero & size,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _PathStudioTileImagePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.sourceRect != sourceRect;
}

class _TilePreviewCheckerboard extends StatelessWidget {
  const _TilePreviewCheckerboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _TilePreviewCheckerboardPainter(),
    );
  }
}

class _TilePreviewCheckerboardPainter extends CustomPainter {
  const _TilePreviewCheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 6.0;
    final dark = Paint()..color = PathStudioTheme.backgroundAlt;
    final light = Paint()
      ..color = PathStudioTheme.borderStrong.withValues(alpha: 0.28);
    var y = 0.0;
    var row = 0;
    while (y < size.height) {
      var x = 0.0;
      var col = 0;
      while (x < size.width) {
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            y,
            cell <= size.width - x ? cell : size.width - x,
            cell <= size.height - y ? cell : size.height - y,
          ),
          (row + col).isEven ? dark : light,
        );
        x += cell;
        col += 1;
      }
      y += cell;
      row += 1;
    }
  }

  @override
  bool shouldRepaint(covariant _TilePreviewCheckerboardPainter oldDelegate) =>
      false;
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
                              child: RawImage(
                                image: image.decodedImage,
                                width: displayWidth,
                                height: displayHeight,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.none,
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
