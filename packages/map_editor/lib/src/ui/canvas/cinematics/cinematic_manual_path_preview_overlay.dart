import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';

/// Renders the manual path overlay on the overworld canvas.
/// Draws a dashed path line and numbered badges for intermediate waypoints.
/// Part of NS-SCENES-V1-108-bis.
///
/// NOTE: This overlay is purely editor-only. Playback interpolation, pathfinding, and actual
/// runtime movements are explicitly out of scope for this lot.
class CinematicManualPathPreviewOverlay extends StatelessWidget {
  const CinematicManualPathPreviewOverlay({
    super.key,
    required this.asset,
    required this.selectedStep,
    this.actorDisplayPreviewModel,
    this.visualPrimitives = const [],
    required this.transform,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep selectedStep;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final List<CinematicMapBackdropVisualPrimitive> visualPrimitives;
  final CinematicMapBackdropViewportTransform transform;

  @override
  Widget build(BuildContext context) {
    if (!transform.isUsable) {
      return const SizedBox.shrink();
    }

    final pathMode = cinematicTimelineActorPathModeOf(selectedStep);
    if (pathMode != CinematicTimelineActorPathMode.manual) {
      return const SizedBox.shrink();
    }

    final stageContext = asset.stageContext;
    if (stageContext == null) {
      return const SizedBox.shrink();
    }

    // Resolves the manual path associated with the selected actorMove step.
    // Safe lookup: returns null if no manual path matches the selected step id,
    // avoiding illegal construction of dummy/sentinel CinematicManualPath instances.
    final path = stageContext.manualPaths.cast<CinematicManualPath?>().firstWhere(
      (p) => p?.ownerActorMoveStepId == selectedStep.id,
      orElse: () => null,
    );

    if (path == null) {
      return const SizedBox.shrink();
    }

    final colors = context.pokeMapColors;

    // 1. Resolve departure point
    Offset? departureOffset;
    final actorId = selectedStep.actorId;
    if (actorId != null && actorId.isNotEmpty) {
      final actor = actorDisplayPreviewModel?.actorById(actorId);
      if (actor != null && actor.position.isResolved) {
        departureOffset = Offset(
          actor.position.x!.toDouble(),
          actor.position.y!.toDouble(),
        );
      } else {
        // Fallback to initial placement in stageContext
        for (final placement in stageContext.initialPlacements) {
          if (placement.actorId == actorId) {
            if (placement.stagePointId != null) {
              final sp = stageContext.stagePoints.cast<CinematicStagePoint?>().firstWhere(
                (p) => p?.id == placement.stagePointId,
                orElse: () => null,
              );
              if (sp != null) {
                departureOffset = Offset(sp.x, sp.y);
              }
            } else if (placement.targetId != null) {
              departureOffset = _resolveTargetOffset(
                targetId: placement.targetId!,
                asset: asset,
                actorDisplayPreviewModel: actorDisplayPreviewModel,
                visualPrimitives: visualPrimitives,
              );
            }
            break;
          }
        }
      }
    }

    // 2. Resolve intermediate waypoints
    final waypointOffsets = <Offset>[];
    for (final waypointId in path.waypointStagePointIds) {
      final sp = stageContext.stagePoints.cast<CinematicStagePoint?>().firstWhere(
        (p) => p?.id == waypointId,
        orElse: () => null,
      );
      if (sp != null) {
        waypointOffsets.add(Offset(sp.x, sp.y));
      }
    }

    // 3. Resolve destination point
    Offset? destinationOffset;
    final targetId = selectedStep.targetId;
    if (targetId != null && targetId.isNotEmpty) {
      destinationOffset = _resolveTargetOffset(
        targetId: targetId,
        asset: asset,
        actorDisplayPreviewModel: actorDisplayPreviewModel,
        visualPrimitives: visualPrimitives,
      );
    }

    // Connect the full path in tile coordinates
    final fullPathTiles = <Offset>[];
    if (departureOffset != null) {
      fullPathTiles.add(departureOffset);
    }
    fullPathTiles.addAll(waypointOffsets);
    if (destinationOffset != null) {
      fullPathTiles.add(destinationOffset);
    }

    if (fullPathTiles.length < 2) {
      return const SizedBox.shrink();
    }

    // Convert to preview offsets
    final previewPoints = fullPathTiles
        .map((tileOffset) => transform.tileToPreview(tileOffset.dx, tileOffset.dy))
        .toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Path dashed line
        IgnorePointer(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _ManualPathLinePainter(
                points: previewPoints,
                color: colors.brandPrimary,
              ),
            ),
          ),
        ),
        // Waypoint badges (1, 2, 3...)
        for (int i = 0; i < waypointOffsets.length; i++) ...[
          _buildWaypointBadge(
            waypointOffsets[i],
            i + 1,
            colors,
          ),
        ],
      ],
    );
  }

  Widget _buildWaypointBadge(Offset tileOffset, int order, PokeMapColorTokens colors) {
    final previewOffset = transform.tileToPreview(tileOffset.dx, tileOffset.dy);
    const size = 18.0;
    return Positioned(
      left: previewOffset.dx - size / 2,
      top: previewOffset.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Semantics(
          label: 'Point de passage $order',
          child: Container(
            decoration: BoxDecoration(
              color: colors.brandPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surfaceBase, width: 1.5),
              boxShadow: [
                BoxShadow(
                  // Avoids hardcoded Colors.black. Uses design token textPrimary with values.
                  color: colors.textPrimary.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$order',
                style: TextStyle(
                  // Avoids hardcoded Colors.white. Uses design token textInverse.
                  color: colors.textInverse,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset? _resolveTargetOffset({
    required String targetId,
    required CinematicAsset asset,
    required CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
    required List<CinematicMapBackdropVisualPrimitive> visualPrimitives,
  }) {
    // 1. Resolve from actors if they are bound to this target
    if (actorDisplayPreviewModel != null) {
      for (final actor in actorDisplayPreviewModel.actors) {
        if (actor.position.isResolved &&
            actor.position.sourceKind ==
                CinematicActorPreviewPositionSourceKind.movementTarget &&
            actor.position.sourceId == targetId) {
          if (actor.position.x != null && actor.position.y != null) {
            return Offset(
              actor.position.x!.toDouble(),
              actor.position.y!.toDouble(),
            );
          }
        }
      }
    }

    final stageContext = asset.stageContext;
    if (stageContext == null) {
      return null;
    }

    // Find binding
    CinematicMovementTargetBinding? binding;
    for (final b in stageContext.movementTargetBindings) {
      if (b.targetId == targetId) {
        binding = b;
        break;
      }
    }

    if (binding == null) {
      return null;
    }

    if (binding.kind == CinematicMovementTargetBindingKind.stagePoint) {
      final sp = stageContext.stagePoints.cast<CinematicStagePoint?>().firstWhere(
        (p) => p?.id == binding!.sourceId,
        orElse: () => null,
      );
      if (sp != null) {
        return Offset(sp.x, sp.y);
      }
    } else if (binding.kind == CinematicMovementTargetBindingKind.mapEntity ||
        binding.kind == CinematicMovementTargetBindingKind.mapEvent) {
      final sourceId = binding.sourceId;
      for (final primitive in visualPrimitives) {
        if (primitive.id == sourceId || primitive.source == sourceId) {
          return Offset(primitive.x + 0.5, primitive.y + 0.5);
        }
      }
    }

    return null;
  }
}

class _ManualPathLinePainter extends CustomPainter {
  const _ManualPathLinePainter({
    required this.points,
    required this.color,
  });

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < points.length - 1; i++) {
      _drawDashedLine(canvas, points[i], points[i + 1], paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    final xStep = dx / distance;
    final yStep = dy / distance;
    for (int i = 0; i < dashCount; i++) {
      final startDistance = i * (dashWidth + dashSpace);
      final start = Offset(
        p1.dx + xStep * startDistance,
        p1.dy + yStep * startDistance,
      );
      final end = Offset(
        start.dx + xStep * dashWidth,
        start.dy + yStep * dashWidth,
      );
      canvas.drawLine(start, end, paint);
    }
    // Draw small line to the end point if there is left-over distance
    final remainder = distance - (dashCount * (dashWidth + dashSpace));
    if (remainder > dashWidth) {
      final startDistance = dashCount * (dashWidth + dashSpace);
      final start = Offset(
        p1.dx + xStep * startDistance,
        p1.dy + yStep * startDistance,
      );
      final end = Offset(
        start.dx + xStep * dashWidth,
        start.dy + yStep * dashWidth,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ManualPathLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.points.length != points.length ||
        !_listEquals(oldDelegate.points, points);
  }

  bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
