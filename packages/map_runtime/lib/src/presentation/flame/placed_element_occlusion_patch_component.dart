import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';
import 'static_placed_element_occlusion_patch_resolution.dart';

class PlacedElementOcclusionPatchComponent extends PositionComponent {
  PlacedElementOcclusionPatchComponent({
    required this.instruction,
    required this.tilesetImage,
  })  : _drawRuns = _buildDrawRuns(instruction),
        _currentDepthSortY = instruction.depthSortY,
        super(
          anchor: Anchor.topLeft,
          position: Vector2(instruction.worldLeft, instruction.worldTop),
          size: Vector2(instruction.visualWidth, instruction.visualHeight),
        ) {
    priority = instruction.flamePriority;
  }

  final StaticPlacedElementOcclusionPatchInstruction instruction;
  final RuntimeTilesetImage tilesetImage;
  final List<_OcclusionPixelRun> _drawRuns;
  double _currentDepthSortY;

  @visibleForTesting
  int get debugDrawRunCount => _drawRuns.length;

  void translateByMapOriginDelta(Vector2 delta) {
    position = position + delta;
    _currentDepthSortY += delta.y;
    priority = (1000 + _currentDepthSortY).round();
  }

  @override
  void render(Canvas canvas) {
    if (instruction.opacity <= 0 || _drawRuns.isEmpty) {
      return;
    }
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    if (instruction.opacity < 1) {
      paint.color = Color.fromRGBO(255, 255, 255, instruction.opacity);
    }

    final scaleX = instruction.visualWidth / instruction.sourceWidthPx;
    final scaleY = instruction.visualHeight / instruction.sourceHeightPx;
    for (final run in _drawRuns) {
      final src = Rect.fromLTWH(
        (instruction.sourceLeftPx + run.x).toDouble(),
        (instruction.sourceTopPx + run.y).toDouble(),
        run.width.toDouble(),
        1,
      );
      final dst = Rect.fromLTWH(
        run.x * scaleX,
        run.y * scaleY,
        run.width * scaleX,
        scaleY,
      );
      tilesetImage.drawImageRect(canvas, src, dst, paint);
    }
  }

  static List<_OcclusionPixelRun> _buildDrawRuns(
    StaticPlacedElementOcclusionPatchInstruction instruction,
  ) {
    final mask = instruction.occlusionMask;
    if (mask.widthPx <= 0 ||
        mask.heightPx <= 0 ||
        instruction.sourceWidthPx <= 0 ||
        instruction.sourceHeightPx <= 0 ||
        instruction.visualWidth <= 0 ||
        instruction.visualHeight <= 0 ||
        mask.widthPx != instruction.sourceWidthPx ||
        mask.heightPx != instruction.sourceHeightPx) {
      return const [];
    }

    final pixels = _decodeMask(mask);
    if (pixels.isEmpty) {
      return const [];
    }

    final runs = <_OcclusionPixelRun>[];
    for (var y = 0; y < mask.heightPx; y++) {
      int? runStart;
      for (var x = 0; x <= mask.widthPx; x++) {
        final isSolid = x < mask.widthPx && pixels[y * mask.widthPx + x];
        if (isSolid && runStart == null) {
          runStart = x;
        } else if (!isSolid && runStart != null) {
          runs.add(_OcclusionPixelRun(x: runStart, y: y, width: x - runStart));
          runStart = null;
        }
      }
    }
    return List<_OcclusionPixelRun>.unmodifiable(runs);
  }

  static List<bool> _decodeMask(ElementCollisionPixelMask mask) {
    try {
      return ElementCollisionMaskCodec.decodePackedBits(
        widthPx: mask.widthPx,
        heightPx: mask.heightPx,
        dataBase64: mask.dataBase64,
      );
    } on FormatException {
      return const [];
    } on ArgumentError {
      return const [];
    }
  }
}

@immutable
final class _OcclusionPixelRun {
  const _OcclusionPixelRun({
    required this.x,
    required this.y,
    required this.width,
  });

  final int x;
  final int y;
  final int width;
}
