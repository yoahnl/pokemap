import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'battle_animation_plan.dart';
import 'battle_rmxp_hue_filter.dart';
import 'battle_sdk_rmxp_animation_catalog.dart';

typedef RmxpCombatantTransformCallback = void Function(
  RmxpCombatantTransform transform,
);
typedef RmxpVoidCallback = void Function();
typedef RmxpFlashCallback = void Function(RmxpAnimationTimingSpec timing);
typedef RmxpVisibilityCallback = void Function(bool hidden);

final class RmxpCombatantTransform {
  const RmxpCombatantTransform({
    required this.offset,
    required this.scale,
  });

  final Offset offset;
  final double scale;
}

@visibleForTesting
final class RmxpRenderedCell {
  const RmxpRenderedCell({
    required this.cell,
    required this.sourceRect,
    required this.destinationRect,
    required this.opacity,
    required this.angleRadians,
    required this.mirror,
    required this.blendType,
    required this.blendMode,
    required this.colorFilter,
  });

  final RmxpAnimationCellSpec cell;
  final Rect sourceRect;
  final Rect destinationRect;
  final double opacity;
  final double angleRadians;
  final bool mirror;
  final int blendType;
  final BlendMode blendMode;
  final ColorFilter? colorFilter;
}

final class BattleRmxpAnimationComponent extends PositionComponent {
  BattleRmxpAnimationComponent({
    required this.image,
    required this.animation,
    required this.sourceAnchorPosition,
    required this.sceneSize,
    required this.reverse,
    this.placementSpec = const RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.subjectAttached,
      anchor: BattleVisualAnchor.attackerCenter,
    ),
    Vector2? placementAnchorPosition,
    Vector2? attackerAnchorPosition,
    Vector2? defenderAnchorPosition,
    Vector2? projectileSourceAnchorPosition,
    Vector2? projectileTargetAnchorPosition,
    Rect? stageRect,
    this.onCombatantTransform,
    this.onCombatantTransformCleared,
    this.onPokemonFlash,
    this.onSceneFlash,
    this.onVisibilityChanged,
  })  : attackerAnchorPosition = attackerAnchorPosition ?? sourceAnchorPosition,
        defenderAnchorPosition = defenderAnchorPosition ?? sourceAnchorPosition,
        placementAnchorPosition =
            placementAnchorPosition ?? sourceAnchorPosition,
        projectileSourceAnchorPosition =
            projectileSourceAnchorPosition ?? sourceAnchorPosition,
        projectileTargetAnchorPosition =
            projectileTargetAnchorPosition ?? sourceAnchorPosition,
        stageRect = stageRect ??
            Rect.fromLTWH(0, 0, sceneSize.x.toDouble(), sceneSize.y.toDouble()),
        super(
          size: sceneSize,
          anchor: Anchor.topLeft,
          priority: 18,
        );

  static const double cellSize = 192;
  static const int columns = 5;

  final ui.Image image;
  final RmxpAnimationSpec animation;
  final Vector2 sourceAnchorPosition;
  final Vector2 attackerAnchorPosition;
  final Vector2 defenderAnchorPosition;
  final Vector2 placementAnchorPosition;
  final Vector2 projectileSourceAnchorPosition;
  final Vector2 projectileTargetAnchorPosition;
  final RmxpPlacementSpec placementSpec;
  final Rect stageRect;
  final Vector2 sceneSize;
  final bool reverse;
  final RmxpCombatantTransformCallback? onCombatantTransform;
  final RmxpVoidCallback? onCombatantTransformCleared;
  final RmxpFlashCallback? onPokemonFlash;
  final RmxpFlashCallback? onSceneFlash;
  final RmxpVisibilityCallback? onVisibilityChanged;

  double _elapsed = 0;
  bool _isComplete = false;
  bool _combatantTransformActive = false;
  bool _visibilityHidden = false;
  int? _hiddenUntilFrame;
  final Set<int> _processedTimingIndexes = <int>{};

  int get currentFrameIndex {
    if (animation.frameMax <= 0) {
      return 0;
    }
    final index = (_elapsed / RmxpAnimationSpec.frameDurationSeconds).floor();
    return index.clamp(0, animation.frameMax - 1).toInt();
  }

  bool get isAnimationComplete => _isComplete;

  @visibleForTesting
  List<RmxpRenderedCell> get visibleCellsForTesting => _visibleCells();

  @override
  void update(double dt) {
    super.update(dt);
    if (_isComplete) {
      return;
    }
    if (dt > 0) {
      _elapsed += dt;
    }
    _restoreTimedVisibilityIfNeeded();
    _processTimingsForCurrentFrame();
    _applyCell15TransformForCurrentFrame();
    if (_elapsed + 0.000001 >= animation.durationSeconds) {
      _isComplete = true;
      _clearCombatantTransform();
      _setHidden(false);
    }
  }

  @override
  void onRemove() {
    _clearCombatantTransform();
    _setHidden(false);
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final renderedCell in _visibleCells()) {
      canvas.save();
      canvas.translate(
        renderedCell.destinationRect.center.dx,
        renderedCell.destinationRect.center.dy,
      );
      canvas.rotate(renderedCell.angleRadians);
      if (renderedCell.mirror) {
        canvas.scale(-1, 1);
      }
      final halfSize = Size(
            renderedCell.destinationRect.width,
            renderedCell.destinationRect.height,
          ) /
          2;
      final destination =
          Offset(-halfSize.width, -halfSize.height) & halfSize * 2;
      canvas.drawImageRect(
        image,
        renderedCell.sourceRect,
        destination,
        Paint()
          ..filterQuality = FilterQuality.none
          ..blendMode = renderedCell.blendMode
          ..colorFilter = renderedCell.colorFilter
          ..color = Color.fromRGBO(255, 255, 255, renderedCell.opacity),
      );
      canvas.restore();
    }
  }

  void _processTimingsForCurrentFrame() {
    for (var i = 0; i < animation.timings.length; i++) {
      final timing = animation.timings[i];
      if (_processedTimingIndexes.contains(i)) {
        continue;
      }
      if (timing.frame > currentFrameIndex) {
        continue;
      }
      _processedTimingIndexes.add(i);
      switch (timing.flashScope) {
        case 1:
          onPokemonFlash?.call(timing);
        case 2:
          onSceneFlash?.call(timing);
        case 3:
          _hiddenUntilFrame = currentFrameIndex +
              (timing.flashDuration <= 0 ? 1 : timing.flashDuration);
          _setHidden(true);
      }
    }
  }

  void _restoreTimedVisibilityIfNeeded() {
    final hiddenUntilFrame = _hiddenUntilFrame;
    if (hiddenUntilFrame == null || currentFrameIndex < hiddenUntilFrame) {
      return;
    }
    _hiddenUntilFrame = null;
    _setHidden(false);
  }

  void _applyCell15TransformForCurrentFrame() {
    final frame = _currentFrame();
    RmxpAnimationCellSpec? sourceCell;
    if (frame != null) {
      for (final cell in frame.cells) {
        if (cell.index == 15) {
          sourceCell = cell;
          break;
        }
      }
    }
    if (sourceCell == null) {
      _clearCombatantTransform();
      return;
    }
    _combatantTransformActive = true;
    onCombatantTransform?.call(
      RmxpCombatantTransform(
        offset: Offset(
          _signedX(sourceCell.x / 2.0) * _sceneScale,
          _signedY(sourceCell.y / 2.0) * _sceneScale,
        ),
        scale: (sourceCell.zoom <= 0 ? 100 : sourceCell.zoom) / 100.0,
      ),
    );
  }

  void _clearCombatantTransform() {
    if (!_combatantTransformActive) {
      return;
    }
    _combatantTransformActive = false;
    onCombatantTransformCleared?.call();
  }

  void _setHidden(bool hidden) {
    if (_visibilityHidden == hidden) {
      return;
    }
    _visibilityHidden = hidden;
    onVisibilityChanged?.call(hidden);
  }

  List<RmxpRenderedCell> _visibleCells() {
    final frame = _currentFrame();
    if (frame == null) {
      return const <RmxpRenderedCell>[];
    }
    final renderedCells = <RmxpRenderedCell>[];
    for (final cell in frame.cells) {
      if (cell.index == 15 || cell.pattern < 0 || cell.opacity <= 0) {
        continue;
      }
      final sourceRect = _sourceRectForPattern(cell.pattern);
      if (sourceRect.right > image.width || sourceRect.bottom > image.height) {
        continue;
      }
      renderedCells.add(
        RmxpRenderedCell(
          cell: cell,
          sourceRect: sourceRect,
          destinationRect: _destinationRect(cell),
          opacity: (cell.opacity / 255.0).clamp(0.0, 1.0),
          angleRadians: _angleRadians(cell),
          mirror: _isMirrored(cell),
          blendType: cell.blendType,
          blendMode: _blendMode(cell.blendType),
          colorFilter: RmxpHueFilter.colorFilterForHue(animation.animationHue),
        ),
      );
    }
    return renderedCells;
  }

  RmxpAnimationFrameSpec? _currentFrame() {
    if (animation.frames.isEmpty) {
      return null;
    }
    return animation.frames[
        currentFrameIndex.clamp(0, animation.frames.length - 1).toInt()];
  }

  Rect _sourceRectForPattern(int pattern) {
    final column = pattern % columns;
    final row = pattern ~/ columns;
    return Rect.fromLTWH(
      column * cellSize,
      row * cellSize,
      cellSize,
      cellSize,
    );
  }

  Rect _destinationRect(RmxpAnimationCellSpec cell) {
    final zoom = (cell.zoom <= 0 ? 100 : cell.zoom) / 200.0;
    final size = cellSize * zoom * _sceneScale;
    final center = _destinationCenter(cell);
    return Rect.fromCenter(center: center, width: size, height: size);
  }

  Offset _destinationCenter(RmxpAnimationCellSpec cell) {
    return switch (placementSpec.policy) {
      RmxpPlacementPolicy.sdkStage => _sdkStageCenter(cell),
      RmxpPlacementPolicy.screenGlobal => _screenGlobalCenter(cell),
      RmxpPlacementPolicy.projectileLine => _projectileLineCenter(cell),
      RmxpPlacementPolicy.targetImpact ||
      RmxpPlacementPolicy.attackerCast ||
      RmxpPlacementPolicy.subjectAttached =>
        _anchoredCenter(cell, placementAnchorPosition),
    };
  }

  Offset _anchoredCenter(RmxpAnimationCellSpec cell, Vector2 anchor) {
    return Offset(
      anchor.x + _signedX(cell.x / 2.0) * _sceneScale,
      anchor.y + _signedY(cell.y / 2.0) * _sceneScale,
    );
  }

  Offset _screenGlobalCenter(RmxpAnimationCellSpec cell) {
    return Offset(
      stageRect.center.dx + _signedX(cell.x / 2.0) * _sceneScale,
      stageRect.center.dy + _signedY(cell.y / 2.0) * _sceneScale,
    );
  }

  Offset _sdkStageCenter(RmxpAnimationCellSpec cell) {
    final virtualPoint = _sdkStageVirtualPoint(cell);
    final viewport = _sdkStageViewport;
    return Offset(
      viewport.left + (virtualPoint.dx * _sceneScale),
      viewport.top + (virtualPoint.dy * _sceneScale),
    );
  }

  Rect get _sdkStageViewport {
    final width = 320.0 * _sceneScale;
    final height = 240.0 * _sceneScale;
    return Rect.fromCenter(
      center: stageRect.center,
      width: width,
      height: height,
    );
  }

  Offset _sdkStageVirtualPoint(RmxpAnimationCellSpec cell) {
    var baseX = 160.0;
    var baseY = 160.0;
    if (reverse) {
      baseX = 320.0 - baseX;
      baseY = 220.0 - baseY;
    }
    return Offset(
      baseX + _signedX(cell.x / 2.0),
      baseY + _signedY(cell.y / 2.0) - 24.0,
    );
  }

  Offset _projectileLineCenter(RmxpAnimationCellSpec cell) {
    final source = Offset(
      projectileSourceAnchorPosition.x,
      projectileSourceAnchorPosition.y,
    );
    final target = Offset(
      projectileTargetAnchorPosition.x,
      projectileTargetAnchorPosition.y,
    );
    final actualVector = target - source;
    final actualDistance = actualVector.distance;
    if (actualDistance <= 0.001) {
      return _anchoredCenter(cell, projectileSourceAnchorPosition);
    }

    final raw = _signedCellOffset(cell);
    final canonical = _projectileCanonicalAxis;
    if (canonical == null) {
      return _anchoredCenter(cell, projectileSourceAnchorPosition);
    }

    final (:start, :axis, :axisLengthSquared) = canonical;
    if (axisLengthSquared <= 0.001) {
      return _anchoredCenter(cell, projectileSourceAnchorPosition);
    }
    final delta = raw - start;
    final progress =
        ((delta.dx * axis.dx + delta.dy * axis.dy) / axisLengthSquared)
            .clamp(0.0, 1.0);
    final axisLength = math.sqrt(axisLengthSquared);
    final perpendicular = Offset(-axis.dy / axisLength, axis.dx / axisLength);
    final lateral = delta.dx * perpendicular.dx + delta.dy * perpendicular.dy;
    final forward = actualVector / actualDistance;
    final actualRight = Offset(-forward.dy, forward.dx);

    return Offset.lerp(source, target, progress)! +
        (actualRight * (lateral * _sceneScale));
  }

  ({Offset start, Offset axis, double axisLengthSquared})?
      get _projectileCanonicalAxis {
    Offset? start;
    Offset? end;
    var maxDistanceSquared = -1.0;
    for (final frame in animation.frames) {
      for (final cell in frame.cells) {
        if (cell.index == 15 || cell.pattern < 0 || cell.opacity <= 0) {
          continue;
        }
        final offset = _signedCellOffset(cell);
        start ??= offset;
        final distanceSquared = _distanceSquared(start, offset);
        if (distanceSquared > maxDistanceSquared) {
          maxDistanceSquared = distanceSquared;
          end = offset;
        }
      }
    }
    if (start == null || end == null) {
      return null;
    }
    final axis = end - start;
    return (
      start: start,
      axis: axis,
      axisLengthSquared: axis.dx * axis.dx + axis.dy * axis.dy,
    );
  }

  double _distanceSquared(Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    return dx * dx + dy * dy;
  }

  Offset _signedCellOffset(RmxpAnimationCellSpec cell) {
    return Offset(
      _signedX(cell.x / 2.0),
      _signedY(cell.y / 2.0),
    );
  }

  double get _sceneScale =>
      math.min(stageRect.width / 320.0, stageRect.height / 240.0);

  double _signedX(double x) => reverse ? -x : x;

  double _signedY(double y) => reverse ? -y : y;

  double _angleRadians(RmxpAnimationCellSpec cell) {
    var angle = cell.angle.toDouble();
    if (reverse && animation.option == RmxpAnimationOption.rotateOnReverse) {
      angle += 180;
    }
    var radians = angle * math.pi / 180.0;
    if (placementSpec.policy == RmxpPlacementPolicy.projectileLine &&
        placementSpec.rotateToLine) {
      radians += _projectileLineRotationRadians;
    }
    return radians;
  }

  double get _projectileLineRotationRadians {
    final source = Offset(
      projectileSourceAnchorPosition.x,
      projectileSourceAnchorPosition.y,
    );
    final target = Offset(
      projectileTargetAnchorPosition.x,
      projectileTargetAnchorPosition.y,
    );
    final actualVector = target - source;
    final canonical = _projectileCanonicalAxis;
    if (actualVector.distance <= 0.001 || canonical == null) {
      return 0;
    }
    final actualAngle = math.atan2(actualVector.dy, actualVector.dx);
    final canonicalAngle = math.atan2(canonical.axis.dy, canonical.axis.dx);
    return actualAngle - canonicalAngle;
  }

  bool _isMirrored(RmxpAnimationCellSpec cell) {
    if (reverse && animation.option == RmxpAnimationOption.mirrorOnReverse) {
      return !cell.mirror;
    }
    return cell.mirror;
  }

  BlendMode _blendMode(int blendType) {
    return switch (blendType) {
      1 => BlendMode.plus,
      // RGSS blend type 2 is subtractive. Flutter's modulate darkens the
      // whole 192x192 transparent cell and creates visible black squares.
      // Keep alpha-safe normal composition until a custom subtract shader lands.
      2 => BlendMode.srcOver,
      _ => BlendMode.srcOver,
    };
  }
}
