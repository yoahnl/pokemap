import 'package:map_core/map_core.dart';

import 'border_directed_jump_binding.dart';
import 'direction.dart';

final class DirectedJumpPlan {
  const DirectedJumpPlan({
    required this.binding,
    required this.direction,
    required this.sourcePos,
    required this.viaPos,
    required this.landingPos,
    required this.sourcePositionPx,
    required this.landingPositionPx,
    required this.durationMs,
    required this.peakHeightPx,
  });

  final BorderDirectedJumpBinding binding;
  final Direction direction;
  final GridPos sourcePos;
  final GridPos viaPos;
  final GridPos landingPos;
  final PixelPosition sourcePositionPx;
  final PixelPosition landingPositionPx;
  final int durationMs;
  final int peakHeightPx;
}
