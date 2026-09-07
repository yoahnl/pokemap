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
    this.frameProvider,
  })  : _currentDepthSortY = instruction.depthSortY,
        super(
          anchor: Anchor.topLeft,
          position: Vector2(instruction.worldLeft, instruction.worldTop),
          size: Vector2(instruction.visualWidth, instruction.visualHeight),
        ) {
    _maskPixels = _decodeMask(instruction.occlusionMask);
    _prepareRenderPlan(
      tilesetImage,
      Rect.fromLTWH(
        instruction.sourceLeftPx.toDouble(),
        instruction.sourceTopPx.toDouble(),
        instruction.sourceWidthPx.toDouble(),
        instruction.sourceHeightPx.toDouble(),
      ),
    );
    priority = instruction.flamePriority;
  }

  void _prepareRenderPlan(RuntimeTilesetImage image, Rect sourceRect) {
    _renderPlan?.dispose();
    _renderPlan = null;
    _frameImage = image;
    _frameSourceRect = sourceRect;
    final mask = instruction.occlusionMask;
    final canPrepare = instruction.opacity > 0 &&
        instruction.visualWidth > 0 &&
        instruction.visualHeight > 0 &&
        mask.widthPx == instruction.sourceWidthPx &&
        mask.heightPx == instruction.sourceHeightPx &&
        sourceRect.width == mask.widthPx &&
        sourceRect.height == mask.heightPx;
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
        image: image,
        sourceRect: sourceRect,
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
          return index >= 0 && index < _maskPixels.length && _maskPixels[index];
        },
      );
      _renderPlanPreparationCount += 1;
    } on ArgumentError {
      _renderPlan = null;
    }
    _drawRunCount = _renderPlan?.result.includedDestinationRunCount ?? 0;
  }

  final StaticPlacedElementOcclusionPatchInstruction instruction;
  final RuntimeTilesetImage tilesetImage;
  final Rect Function()? visibleWorldRectProvider;
  final ({RuntimeTilesetImage image, Rect sourceRect})? Function()?
      frameProvider;
  late final List<bool> _maskPixels;
  RuntimeTilesetImage? _frameImage;
  Rect? _frameSourceRect;
  QuarterTurnPixelDrawPlan? _renderPlan;
  int _drawRunCount = 0;
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
    if (instruction.opacity <= 0 || _didRemove) {
      return;
    }
    final visibleWorldRect = visibleWorldRectProvider?.call();
    if (visibleWorldRect != null &&
        !toAbsoluteRect().inflate(1).overlaps(visibleWorldRect)) {
      _culledRenderCount += 1;
      return;
    }

    final provider = frameProvider;
    if (provider != null) {
      final frame = provider();
      if (frame == null) return;
      if (!identical(frame.image, _frameImage) ||
          frame.sourceRect != _frameSourceRect) {
        _prepareRenderPlan(frame.image, frame.sourceRect);
      }
    }
    final plan = _renderPlan;
    if (plan == null || plan.isDisposed || _drawRunCount == 0) return;

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
