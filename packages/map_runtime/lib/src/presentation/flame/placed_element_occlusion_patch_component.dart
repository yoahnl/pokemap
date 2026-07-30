import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';
import 'quarter_turn_pixel_renderer.dart';
import 'static_placed_element_occlusion_patch_resolution.dart';

class PlacedElementOcclusionPatchComponent extends PositionComponent {
  PlacedElementOcclusionPatchComponent({
    required this.instruction,
    required this.tilesetImage,
  })  : _currentDepthSortY = instruction.depthSortY,
        super(
          anchor: Anchor.topLeft,
          position: Vector2(instruction.worldLeft, instruction.worldTop),
          size: Vector2(instruction.visualWidth, instruction.visualHeight),
        ) {
    _pixelTransform = _resolvePixelTransform(instruction);
    _maskPixels = _decodeMask(instruction.occlusionMask);
    _drawRuns = _buildDrawRuns(
      instruction,
      pixelTransform: _pixelTransform,
      pixels: _maskPixels,
    );
    priority = instruction.flamePriority;
  }

  final StaticPlacedElementOcclusionPatchInstruction instruction;
  final RuntimeTilesetImage tilesetImage;
  late final QuarterTurnPixelTransform? _pixelTransform;
  late final List<bool> _maskPixels;
  late final List<_OcclusionPixelRun> _drawRuns;
  double _currentDepthSortY;
  int _lastQuarterTurnDrawRunCount = 0;
  int _lastIncludedDestinationPixelCount = 0;

  @visibleForTesting
  int get debugDrawRunCount => _drawRuns.length;

  @visibleForTesting
  int get debugQuarterTurnDrawRunCount => _lastQuarterTurnDrawRunCount;

  @visibleForTesting
  int get debugIncludedDestinationPixelCount =>
      _lastIncludedDestinationPixelCount;

  void translateByMapOriginDelta(Vector2 delta) {
    position = position + delta;
    _currentDepthSortY += delta.y;
    priority = (1000 + _currentDepthSortY).round();
  }

  @override
  void render(Canvas canvas) {
    _lastQuarterTurnDrawRunCount = 0;
    _lastIncludedDestinationPixelCount = 0;
    final transform = _pixelTransform;
    if (instruction.opacity <= 0 || _drawRuns.isEmpty || transform == null) {
      return;
    }
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    if (instruction.opacity < 1) {
      paint.color = Color.fromRGBO(255, 255, 255, instruction.opacity);
    }

    final sourceWidth = transform.sourcePixelSize.width;
    final result = drawQuarterTurnPixels(
      canvas,
      image: tilesetImage,
      sourceRect: Rect.fromLTWH(
        instruction.sourceLeftPx.toDouble(),
        instruction.sourceTopPx.toDouble(),
        transform.sourcePixelSize.width.toDouble(),
        transform.sourcePixelSize.height.toDouble(),
      ),
      destinationRect: Rect.fromLTWH(
        0,
        0,
        instruction.visualWidth,
        instruction.visualHeight,
      ),
      sourcePixelSize: transform.sourcePixelSize,
      destinationPixelSize: transform.destinationPixelSize,
      quarterTurns: transform.quarterTurns,
      paint: paint,
      includeSourcePixel: (source) {
        final index = source.y * sourceWidth + source.x;
        return index >= 0 && index < _maskPixels.length && _maskPixels[index];
      },
    );
    _lastQuarterTurnDrawRunCount = result.drawRunCount;
    _lastIncludedDestinationPixelCount = result.includedDestinationPixelCount;
  }

  static List<_OcclusionPixelRun> _buildDrawRuns(
    StaticPlacedElementOcclusionPatchInstruction instruction, {
    required QuarterTurnPixelTransform? pixelTransform,
    required List<bool> pixels,
  }) {
    final mask = instruction.occlusionMask;
    if (pixelTransform == null ||
        mask.widthPx <= 0 ||
        mask.heightPx <= 0 ||
        instruction.visualWidth <= 0 ||
        instruction.visualHeight <= 0 ||
        mask.widthPx != pixelTransform.sourcePixelSize.width ||
        mask.heightPx != pixelTransform.sourcePixelSize.height) {
      return const [];
    }

    if (pixels.isEmpty) {
      return const [];
    }

    final destinationSize = pixelTransform.destinationPixelSize;
    final sourceWidth = pixelTransform.sourcePixelSize.width;
    final runs = <_OcclusionPixelRun>[];
    for (var y = 0; y < destinationSize.height; y++) {
      int? runStart;
      for (var x = 0; x <= destinationSize.width; x++) {
        var isSolid = false;
        if (x < destinationSize.width) {
          final source = pixelTransform.destinationPixelToSourcePixel(
            GridPos(x: x, y: y),
          );
          isSolid = pixels[source.y * sourceWidth + source.x];
        }
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

  static QuarterTurnPixelTransform? _resolvePixelTransform(
    StaticPlacedElementOcclusionPatchInstruction instruction,
  ) {
    try {
      return QuarterTurnPixelTransform(
        sourcePixelSize: GridSize(
          width: instruction.sourceWidthPx,
          height: instruction.sourceHeightPx,
        ),
        destinationPixelSize: GridSize(
          width: instruction.destinationWidthPx,
          height: instruction.destinationHeightPx,
        ),
        quarterTurns: instruction.quarterTurns,
      );
    } on ArgumentError {
      return null;
    }
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
