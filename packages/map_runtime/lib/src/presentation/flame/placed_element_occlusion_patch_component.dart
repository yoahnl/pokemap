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
    this.overlayPainter,
    this.overlayReplacesPatch = false,
    this.visualWorldRectProvider,
  })  : _currentDepthSortY = instruction.depthSortY,
        super(
          anchor: Anchor.topLeft,
          position: Vector2(instruction.worldLeft, instruction.worldTop),
          size: Vector2(instruction.visualWidth, instruction.visualHeight),
        ) {
    _maskPixels = _decodeMask(instruction.occlusionMask);
    _overlayClip = overlayPainter == null ? null : _buildOverlayClip();
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
    _renderPlan = null;
    _frameImage = image;
    _frameSourceRect = sourceRect;
    if (overlayReplacesPatch) return;
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
      final sourceSize = GridSize(
        width: instruction.sourceWidthPx,
        height: instruction.sourceHeightPx,
      );
      final destinationSize = GridSize(
        width: instruction.destinationWidthPx,
        height: instruction.destinationHeightPx,
      );
      final sourceWidth = sourceSize.width;
      final maskPixels = _maskPixels;
      _renderPlan = _plans.obtain(
        image: image,
        sourceRect: sourceRect,
        sourceSize: sourceSize,
        destinationSize: destinationSize,
        quarterTurns: instruction.quarterTurns,
        maskKey: instruction.occlusionMask,
        includeSourcePixel: (source) {
          final index = source.y * sourceWidth + source.x;
          return index >= 0 && index < maskPixels.length && maskPixels[index];
        },
      );
      _renderPlanPreparationCount += 1;
    } on ArgumentError {
      _renderPlan = null;
    }
    _drawRunCount = _renderPlan?.result.includedDestinationRunCount ?? 0;
  }

  StaticPlacedElementOcclusionPatchInstruction instruction;
  final RuntimeTilesetImage tilesetImage;
  final void Function(Canvas)? overlayPainter;
  final bool overlayReplacesPatch;
  Path? get localOcclusionPath => _overlayClip;
  Path? _overlayClip;
  final Rect Function()? visibleWorldRectProvider;
  final Rect? Function()? visualWorldRectProvider;
  final ({RuntimeTilesetImage image, Rect sourceRect})? Function()?
      frameProvider;
  late List<bool> _maskPixels;
  RuntimeTilesetImage? _frameImage;
  Rect? _frameSourceRect;
  QuarterTurnPixelDrawPlan? _renderPlan;
  final _plans =
      QuarterTurnPixelPlanCache(maxEntries: 4, maxBytes: 4 * 1024 * 1024);
  int _drawRunCount = 0;
  double _currentDepthSortY;
  int _lastQuarterTurnDrawRunCount = 0;
  int _lastIncludedDestinationPixelCount = 0;
  int _renderPlanPreparationCount = 0;
  int _renderPlanDrawCount = 0;
  int _culledRenderCount = 0;
  bool _didRemove = false;

  @override
  void update(double dt) {
    super.update(dt);
    final rect = visualWorldRectProvider?.call();
    if (rect == null) return;
    position.setValues(rect.left, rect.top);
    _currentDepthSortY = rect.bottom;
    priority = overworldActorRenderPriority(_currentDepthSortY);
  }

  void setInstruction(StaticPlacedElementOcclusionPatchInstruction next) {
    final previous = instruction;
    instruction = next;
    position.setValues(next.worldLeft, next.worldTop);
    size.setValues(next.visualWidth, next.visualHeight);
    _currentDepthSortY = next.depthSortY;
    priority = next.flamePriority;
    if (previous.visualWidth == next.visualWidth &&
        previous.visualHeight == next.visualHeight &&
        previous.destinationWidthPx == next.destinationWidthPx &&
        previous.destinationHeightPx == next.destinationHeightPx &&
        previous.quarterTurns == next.quarterTurns &&
        previous.occlusionMask == next.occlusionMask &&
        previous.opacity == next.opacity &&
        previous.sourceLeftPx == next.sourceLeftPx &&
        previous.sourceTopPx == next.sourceTopPx &&
        previous.sourceWidthPx == next.sourceWidthPx &&
        previous.sourceHeightPx == next.sourceHeightPx) {
      return;
    }
    if (previous.occlusionMask != next.occlusionMask) {
      _maskPixels = _decodeMask(next.occlusionMask);
    }
    _overlayClip = overlayPainter == null ? null : _buildOverlayClip();
    _prepareRenderPlan(
        _frameImage ?? tilesetImage,
        Rect.fromLTWH(next.sourceLeftPx.toDouble(), next.sourceTopPx.toDouble(),
            next.sourceWidthPx.toDouble(), next.sourceHeightPx.toDouble()));
  }

  Path _buildOverlayClip() {
    final sourceSize = GridSize(
        width: instruction.sourceWidthPx, height: instruction.sourceHeightPx);
    final destinationSize = GridSize(
        width: instruction.destinationWidthPx,
        height: instruction.destinationHeightPx);
    final transform = QuarterTurnPixelTransform(
        sourcePixelSize: sourceSize,
        destinationPixelSize: destinationSize,
        quarterTurns: instruction.quarterTurns);
    final dx = instruction.visualWidth / destinationSize.width;
    final dy = instruction.visualHeight / destinationSize.height;
    final path = Path();
    for (var y = 0; y < sourceSize.height; y++) {
      int? start;
      for (var x = 0; x <= sourceSize.width; x++) {
        var included = false;
        if (x < sourceSize.width) {
          final index = y * sourceSize.width + x;
          included =
              index >= 0 && index < _maskPixels.length && _maskPixels[index];
        }
        if (included) {
          start ??= x;
        } else if (start != null) {
          final rect = transform.sourcePixelRectToDestinationPixelRect(
              PixelRect(
                  leftPx: start, topPx: y, widthPx: x - start, heightPx: 1));
          if (rect.widthPx > 0 && rect.heightPx > 0) {
            path.addRect(Rect.fromLTWH(rect.leftPx * dx, rect.topPx * dy,
                rect.widthPx * dx, rect.heightPx * dy));
          }
          start = null;
        }
      }
    }
    return path;
  }

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
    if (overlayReplacesPatch) {
      final clip = _overlayClip;
      if (clip == null) return;
      canvas.save();
      if (visibleWorldRect != null) {
        canvas.clipRect(
            visibleWorldRect.shift(Offset(-position.x, -position.y)),
            doAntiAlias: false);
      }
      canvas.clipPath(clip, doAntiAlias: false);
      overlayPainter!(canvas);
      canvas.restore();
      return;
    }
    final plan = _renderPlan;
    if (plan == null ||
        plan.isDisposed ||
        (_drawRunCount == 0 && !plan.isTiled)) {
      return;
    }

    canvas.save();
    if (visibleWorldRect != null) {
      canvas.clipRect(visibleWorldRect.shift(Offset(-position.x, -position.y)),
          doAntiAlias: false);
    }
    canvas.scale(instruction.visualWidth / instruction.destinationWidthPx,
        instruction.visualHeight / instruction.destinationHeightPx);
    if (instruction.opacity < 1) {
      canvas.saveLayer(
          Rect.fromLTWH(0, 0, instruction.destinationWidthPx.toDouble(),
              instruction.destinationHeightPx.toDouble()),
          Paint()..color = Color.fromRGBO(255, 255, 255, instruction.opacity));
    }
    plan.draw(canvas);
    if (instruction.opacity < 1) canvas.restore();
    canvas.restore();
    final clip = _overlayClip;
    if (clip != null) {
      canvas.save();
      try {
        canvas.clipPath(clip, doAntiAlias: false);
        overlayPainter!(canvas);
      } finally {
        canvas.restore();
      }
    }
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
    _plans.dispose();
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
