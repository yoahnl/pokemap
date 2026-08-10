import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';
import 'overworld_render_priority.dart';
import 'quarter_turn_pixel_renderer.dart';
import 'static_placed_element_occlusion_patch_resolution.dart';

class PlacedElementOcclusionPatchComponent extends PositionComponent {
  PlacedElementOcclusionPatchComponent({
    required this.instruction,
    required this.tilesetImage,
    this.visibleWorldRectProvider,
  })  : _currentDepthSortY = instruction.depthSortY,
        super(
          anchor: Anchor.topLeft,
          position: Vector2(instruction.worldLeft, instruction.worldTop),
          size: Vector2(instruction.visualWidth, instruction.visualHeight),
        ) {
    final maskPixels = _decodeMask(instruction.occlusionMask);
    final mask = instruction.occlusionMask;
    final canPrepare = instruction.opacity > 0 &&
        instruction.visualWidth > 0 &&
        instruction.visualHeight > 0 &&
        mask.widthPx == instruction.sourceWidthPx &&
        mask.heightPx == instruction.sourceHeightPx;
    try {
      if (!canPrepare) {
        throw ArgumentError('Occlusion patch cannot produce a render plan.');
      }
      final paint = Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none;
      if (instruction.opacity < 1) {
        paint.color = Color.fromRGBO(255, 255, 255, instruction.opacity);
      }
      final sourceSize = GridSize(
        width: instruction.sourceWidthPx,
        height: instruction.sourceHeightPx,
      );
      final destinationSize = GridSize(
        width: instruction.destinationWidthPx,
        height: instruction.destinationHeightPx,
      );
      final sourceWidth = sourceSize.width;
      _renderPlan = QuarterTurnPixelDrawPlan.record(
        image: tilesetImage,
        sourceRect: Rect.fromLTWH(
          instruction.sourceLeftPx.toDouble(),
          instruction.sourceTopPx.toDouble(),
          sourceSize.width.toDouble(),
          sourceSize.height.toDouble(),
        ),
        destinationRect: Rect.fromLTWH(
          0,
          0,
          instruction.visualWidth,
          instruction.visualHeight,
        ),
        sourcePixelSize: sourceSize,
        destinationPixelSize: destinationSize,
        quarterTurns: instruction.quarterTurns,
        paint: paint,
        includeSourcePixel: (source) {
          final index = source.y * sourceWidth + source.x;
          return index >= 0 && index < maskPixels.length && maskPixels[index];
        },
      );
      _renderPlanPreparationCount = 1;
    } on ArgumentError {
      _renderPlan = null;
    }
    _drawRunCount = _renderPlan?.result.includedDestinationRunCount ?? 0;
    priority = instruction.flamePriority;
  }

  final StaticPlacedElementOcclusionPatchInstruction instruction;
  final RuntimeTilesetImage tilesetImage;
  final Rect Function()? visibleWorldRectProvider;
  QuarterTurnPixelDrawPlan? _renderPlan;
  late final int _drawRunCount;
  double _currentDepthSortY;
  int _lastQuarterTurnDrawRunCount = 0;
  int _lastIncludedDestinationPixelCount = 0;
  int _renderPlanPreparationCount = 0;
  int _renderPlanDrawCount = 0;
  int _culledRenderCount = 0;
  bool _didRemove = false;

  @visibleForTesting
  int get debugDrawRunCount => _drawRunCount;

  @visibleForTesting
  int get debugQuarterTurnDrawRunCount => _lastQuarterTurnDrawRunCount;

  @visibleForTesting
  int get debugIncludedDestinationPixelCount =>
      _lastIncludedDestinationPixelCount;

  @visibleForTesting
  int get debugRenderPlanPreparationCount => _renderPlanPreparationCount;

  @visibleForTesting
  int get debugRenderPlanDrawCount => _renderPlanDrawCount;

  @visibleForTesting
  int get debugCulledRenderCount => _culledRenderCount;

  @visibleForTesting
  int get debugQuarterTurnResampleCount =>
      _renderPlan?.sourcePixelSampleCount ?? 0;

  @visibleForTesting
  bool get debugRenderPlanDisposed => _renderPlan?.isDisposed ?? true;

  @visibleForTesting
  int get debugRenderPlanApproximateBytesUsed =>
      _renderPlan?.approximateBytesUsed ?? 0;

  void translateByMapOriginDelta(Vector2 delta) {
    position = position + delta;
    _currentDepthSortY += delta.y;
    priority = overworldActorRenderPriority(_currentDepthSortY);
  }

  @override
  void render(Canvas canvas) {
    _lastQuarterTurnDrawRunCount = 0;
    _lastIncludedDestinationPixelCount = 0;
    final plan = _renderPlan;
    if (instruction.opacity <= 0 ||
        _drawRunCount == 0 ||
        plan == null ||
        plan.isDisposed) {
      return;
    }
    final visibleWorldRect = visibleWorldRectProvider?.call();
    if (visibleWorldRect != null &&
        !toAbsoluteRect().inflate(1).overlaps(visibleWorldRect)) {
      _culledRenderCount += 1;
      return;
    }

    plan.draw(canvas);
    _renderPlanDrawCount += 1;
    final result = plan.result;
    _lastQuarterTurnDrawRunCount = result.drawRunCount;
    _lastIncludedDestinationPixelCount = result.includedDestinationPixelCount;
  }

  /// A removed patch is terminal; Flame must construct a new component if the
  /// same instruction is mounted again.
  @override
  void onRemove() {
    if (_didRemove) return;
    _didRemove = true;
    _renderPlan?.dispose();
    super.onRemove();
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
