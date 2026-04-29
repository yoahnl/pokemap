import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../surface_studio_design_tokens.dart';
import '../surface_studio_atlas_view_geometry.dart';
import '../surface_studio_role_assignment_draft.dart';

export '../surface_studio_atlas_view_geometry.dart'
    show surfaceStudioTileSourceRect;

class SurfaceStudioSurfacePreviewRenderer extends StatefulWidget {
  const SurfaceStudioSurfacePreviewRenderer({
    super.key,
    required this.atlasImageBytes,
    required this.assignmentDraft,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
    required this.frameCount,
    required this.frameIndex,
    required this.previewSize,
    required this.gridVisible,
  });

  final Uint8List atlasImageBytes;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
  final int frameCount;
  final int frameIndex;
  final int previewSize;
  final bool gridVisible;

  @override
  State<SurfaceStudioSurfacePreviewRenderer> createState() =>
      _SurfaceStudioSurfacePreviewRendererState();
}

class _SurfaceStudioSurfacePreviewRendererState
    extends State<SurfaceStudioSurfacePreviewRenderer> {
  ui.Image? _image;
  Object? _decodeToken;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(
      covariant SurfaceStudioSurfacePreviewRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atlasImageBytes != widget.atlasImageBytes) {
      _image?.dispose();
      _image = null;
      _decode();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _decode() {
    final token = Object();
    _decodeToken = token;
    ui.decodeImageFromList(widget.atlasImageBytes, (image) {
      if (!mounted || _decodeToken != token) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const Center(
        child: Text(
          'Préparation de la preview atlas...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SurfaceStudioDesignTokens.textMuted,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      );
    }
    return CustomPaint(
      key: const ValueKey('surfaceStudio.preview.tileCanvas'),
      painter: SurfaceStudioSurfacePreviewPainter(
        atlasImage: image,
        assignmentDraft: widget.assignmentDraft,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        columnCount: widget.columnCount,
        frameCount: widget.frameCount,
        frameIndex: widget.frameIndex,
        previewSize: widget.previewSize,
        gridVisible: widget.gridVisible,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class SurfaceStudioSurfacePreviewPainter extends CustomPainter {
  const SurfaceStudioSurfacePreviewPainter({
    required this.atlasImage,
    required this.assignmentDraft,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
    required this.frameCount,
    required this.frameIndex,
    required this.previewSize,
    required this.gridVisible,
  });

  final ui.Image atlasImage;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
  final int frameCount;
  final int frameIndex;
  final int previewSize;
  final bool gridVisible;

  @override
  void paint(Canvas canvas, Size size) {
    final centerColumns =
        assignmentDraft.columnsForRole(SurfaceVariantRole.isolated);
    if (centerColumns.isEmpty) {
      return;
    }
    final safeFrameCount = frameCount < 1 ? 1 : frameCount;
    final safeFrameIndex = frameIndex % safeFrameCount;
    final cellWidth = size.width / previewSize;
    final cellHeight = size.height / previewSize;
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (var y = 0; y < previewSize; y++) {
      for (var x = 0; x < previewSize; x++) {
        final tileColumn =
            centerColumns[(x + y + safeFrameIndex) % centerColumns.length];
        final source = surfaceStudioTileSourceRect(
          uiColumn: tileColumn,
          frameIndex: safeFrameIndex,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          columnCount: columnCount,
          frameCount: safeFrameCount,
        );
        canvas.drawImageRect(
          atlasImage,
          source,
          Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
          paint,
        );
      }
    }
    if (!gridVisible) {
      return;
    }
    final gridPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 0; i <= previewSize; i++) {
      final x = i * cellWidth;
      final y = i * cellHeight;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(
          covariant SurfaceStudioSurfacePreviewPainter oldDelegate) =>
      oldDelegate.atlasImage != atlasImage ||
      oldDelegate.assignmentDraft != assignmentDraft ||
      oldDelegate.tileWidth != tileWidth ||
      oldDelegate.tileHeight != tileHeight ||
      oldDelegate.columnCount != columnCount ||
      oldDelegate.frameCount != frameCount ||
      oldDelegate.frameIndex != frameIndex ||
      oldDelegate.previewSize != previewSize ||
      oldDelegate.gridVisible != gridVisible;
}
