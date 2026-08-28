import 'package:map_gameplay/map_gameplay.dart';

final class PlacedElementWarpTraversalPlan {
  const PlacedElementWarpTraversalPlan({
    required this.instanceId,
    required this.warp,
    required this.animationDurationMs,
  });

  final String instanceId;
  final TriggeredWarp warp;
  final double animationDurationMs;
}

final class PlacedElementWarpTraversalController {
  _ActivePlacedElementWarpTraversal? _active;

  bool get isActive => _active != null;

  bool tryStart(
    PlacedElementWarpTraversalPlan plan, {
    required double nowMs,
  }) {
    if (_active != null) {
      return false;
    }
    final durationMs =
        plan.animationDurationMs < 0 ? 0.0 : plan.animationDurationMs;
    _active = _ActivePlacedElementWarpTraversal(
      plan: plan,
      completesAtMs: nowMs + durationMs,
    );
    return true;
  }

  TriggeredWarp? takeCompleted({required double nowMs}) {
    final active = _active;
    if (active == null || nowMs < active.completesAtMs) {
      return null;
    }
    _active = null;
    return active.plan.warp;
  }

  void clear() {
    _active = null;
  }
}

final class _ActivePlacedElementWarpTraversal {
  const _ActivePlacedElementWarpTraversal({
    required this.plan,
    required this.completesAtMs,
  });

  final PlacedElementWarpTraversalPlan plan;
  final double completesAtMs;
}
