import 'dart:math' as math;
import 'dart:ui';

import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';
import 'battle_camera_subject_geometry.dart';
import 'battle_sdk_rmxp_animation_catalog.dart';

final class BattleCameraMotionEnvelope {
  const BattleCameraMotionEnvelope({
    this.nativeOffsets = Rect.zero,
    this.nativeScaleX = 1,
    this.nativeScaleY = 1,
    this.rmxpOffsets = Rect.zero,
    this.rmxpScale = 1,
  });

  final Rect nativeOffsets;
  final double nativeScaleX;
  final double nativeScaleY;
  final Rect rmxpOffsets;
  final double rmxpScale;

  Rect resolve(
    BattleCameraSubjectGeometry geometry, {
    required double rmxpSceneScale,
  }) {
    Rect transformed(
      Rect offsets,
      double scaleX,
      double scaleY,
      double offsetScale,
    ) {
      final bounds = geometry.bounds;
      final foot = geometry.foot;
      return Rect.fromLTRB(
        foot.dx + (bounds.left - foot.dx) * scaleX + offsets.left * offsetScale,
        foot.dy + (bounds.top - foot.dy) * scaleY + offsets.top * offsetScale,
        foot.dx +
            (bounds.right - foot.dx) * scaleX +
            offsets.right * offsetScale,
        foot.dy +
            (bounds.bottom - foot.dy) * scaleY +
            offsets.bottom * offsetScale,
      );
    }

    final offsets = nativeOffsets.expandToInclude(
      Rect.fromLTRB(
        rmxpOffsets.left * rmxpSceneScale,
        rmxpOffsets.top * rmxpSceneScale,
        rmxpOffsets.right * rmxpSceneScale,
        rmxpOffsets.bottom * rmxpSceneScale,
      ),
    );
    return geometry.framingBounds.expandToInclude(
      transformed(
        offsets,
        math.max(nativeScaleX, rmxpScale),
        math.max(nativeScaleY, rmxpScale),
        1,
      ),
    );
  }
}

Map<BattleSlotRef, BattleCameraMotionEnvelope>
compileBattleCameraMotionEnvelopes(BattleAnimationPlan plan) {
  final result = <BattleSlotRef, BattleCameraMotionEnvelope>{};
  void native(
    BattleSlotRef slot,
    Rect offsets, {
    double scaleX = 1,
    double scaleY = 1,
  }) {
    final previous = result[slot] ?? const BattleCameraMotionEnvelope();
    result[slot] = BattleCameraMotionEnvelope(
      nativeOffsets: previous.nativeOffsets.expandToInclude(offsets),
      nativeScaleX: math.max(previous.nativeScaleX, scaleX),
      nativeScaleY: math.max(previous.nativeScaleY, scaleY),
      rmxpOffsets: previous.rmxpOffsets,
      rmxpScale: previous.rmxpScale,
    );
  }

  for (final step in plan.flattenedSteps) {
    switch (step) {
      case CombatantMotionStep():
        final direction = step.side == BattleSideId.player ? 1.0 : -1.0;
        final distance = step.distancePx;
        if (step.motionKind == BattleCombatantMotionKind.lunge) {
          final dx = direction * distance;
          final dy = -direction * distance * .16;
          native(
            step.slot,
            Rect.fromLTRB(
              math.min(0, dx),
              math.min(0, dy),
              math.max(0, dx),
              math.max(0, dy),
            ),
          );
        } else if (step.motionKind == BattleCombatantMotionKind.fastDash) {
          final dx = direction * distance;
          final dy = -direction * distance * .08;
          native(
            step.slot,
            Rect.fromLTRB(
              math.min(dx * 1.16, -dx * .42),
              math.min(0, dy),
              math.max(dx * 1.16, -dx * .42),
              math.max(0, dy),
            ),
          );
        }
      case CombatantShakeStep():
        final amount = step.amplitudePx.abs();
        native(step.slot, Rect.fromLTRB(-amount, 0, amount, 0));
      case CombatantEllipseStep():
        native(
          step.slot,
          Rect.fromLTRB(
            -step.radiusX.abs(),
            -step.radiusY.abs(),
            step.radiusX.abs(),
            step.radiusY.abs(),
          ),
        );
      case CombatantCompressStep():
        native(
          step.slot,
          Rect.zero,
          scaleX: math.max(1, 1 + step.scaleX),
          scaleY: math.max(1, 1 + step.scaleY),
        );
      case PlayRmxpAnimationStep():
        final animation = BattleSdkRmxpAnimationCatalog.require(
          step.animationId,
        );
        final direction = step.reverse && !animation.forceNoReverse
            ? -1.0
            : 1.0;
        var offsets = Rect.zero;
        var scale = 1.0;
        for (final frame in animation.frames) {
          for (final cell in frame.cells) {
            if (cell.index != 15) continue;
            final point = Offset(
              direction * cell.x / 2,
              direction * cell.y / 2,
            );
            offsets = offsets.expandToInclude(point & Size.zero);
            scale = math.max(scale, (cell.zoom <= 0 ? 100 : cell.zoom) / 100);
          }
        }
        final previous =
            result[step.subjectSlot] ?? const BattleCameraMotionEnvelope();
        result[step.subjectSlot] = BattleCameraMotionEnvelope(
          nativeOffsets: previous.nativeOffsets,
          nativeScaleX: previous.nativeScaleX,
          nativeScaleY: previous.nativeScaleY,
          rmxpOffsets: previous.rmxpOffsets.expandToInclude(offsets),
          rmxpScale: math.max(previous.rmxpScale, scale),
        );
      default:
        break;
    }
  }
  return Map.unmodifiable(result);
}
