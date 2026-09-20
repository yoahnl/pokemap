import 'cinematic_transport_listenable.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_preview_transport.dart';
import '../../shared/widgets/layout/studio_map_overlay_frame.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'cinematic_map_model.dart';
import 'cinematic_view_state.dart';
import 'cinematic_workspace_visuals.dart';
import 'cinematic_point_handle.dart';
import 'cinematic_actor_animation.dart';
import 'cinematic_path_painter.dart';

class CinematicMapOverlay extends StatelessWidget {
  const CinematicMapOverlay({
    super.key,
    required this.model,
    required this.visuals,
    required this.view,
    required this.transport,
    required this.cell,
    required this.changed,
    required this.onPointMove,
    required this.beforeSelect,
  });
  final CinematicMapModel model;
  final MapWorkspaceVisuals visuals;
  final CinematicViewState view;
  final CinematicPreviewTransport transport;
  final Size cell;
  final VoidCallback changed;
  final void Function(CinematicStagePoint, Offset) onPointMove;
  final bool Function() beforeSelect;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: CinematicTransportListenable(transport),
    builder: (context, _) {
      final frame = transport.frame;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (!transport.previewActive)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CinematicPathPainter(
                    model,
                    cell,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          for (final actor in model.actors.actors)
            if (frame?.actorPoses
                    .where((p) => p.actorId == actor.actorId)
                    .firstOrNull
                case final pose?) ...[
              if (pose.hasPosition)
                _actor(
                  context,
                  actor,
                  pose.x!,
                  pose.y!,
                  pose.facing,
                  pose.isInterpolated,
                ),
            ] else if (actor.position.isResolved)
              _actor(
                context,
                actor,
                actor.position.x!.toDouble(),
                actor.position.y!.toDouble(),
                actor.direction,
                false,
              ),
          if (!transport.previewActive)
            for (final point
                in model.asset.stageContext?.stagePoints ??
                    <CinematicStagePoint>[])
              Positioned(
                left: point.x * cell.width - 12,
                top: point.y * cell.height - 12,
                width: 24,
                height: 24,
                child: CinematicPointHandle(
                  point: point,
                  cell: cell,
                  enabled: view.mode == CinematicMapMode.select,
                  onMove: (value) => onPointMove(point, value),
                ),
              ),
          if (!transport.previewActive)
            if (frame?.cameraPose.geometry case final geometry?)
              if (geometry.isAvailable &&
                  geometry.centerX != null &&
                  geometry.centerY != null)
                Positioned(
                  left:
                      (geometry.centerX! -
                          cameraTiles(geometry.zoomPreset).width / 2) *
                      cell.width,
                  top:
                      (geometry.centerY! -
                          cameraTiles(geometry.zoomPreset).height / 2) *
                      cell.height,
                  width: cell.width * cameraTiles(geometry.zoomPreset).width,
                  height: cell.height * cameraTiles(geometry.zoomPreset).height,
                  child: IgnorePointer(
                    child: StudioMapOverlayFrame(
                      selected: true,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            'Cadre indicatif · ${geometry.targetLabel ?? 'Caméra'}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      );
    },
  );
  Size cameraTiles(CinematicCameraZoomPreset? preset) => switch (preset) {
    CinematicCameraZoomPreset.wide => const Size(7, 5),
    CinematicCameraZoomPreset.close => const Size(3, 2.25),
    _ => const Size(5, 3.5),
  };
  Widget _actor(
    BuildContext context,
    CinematicActorDisplayPreviewActor actor,
    double x,
    double y,
    CinematicActorPreviewDirection direction,
    bool moving,
  ) {
    final character = model.project.characters
        .where((c) => c.id == actor.appearance.characterId)
        .firstOrNull;
    final source = visuals;
    final playback = cinematicActorAnimation(
      model.asset,
      transport,
      actor.actorId,
      moving,
    );
    final facing =
        EntityFacing.values
            .where((f) => f.name == direction.name)
            .firstOrNull ??
        EntityFacing.south;
    final width = cell.width * math.max(2, character?.frameWidth ?? 2);
    final height = cell.height * math.max(2, character?.frameHeight ?? 2);
    final animation = transport.frame?.activeCharacterAnimations
        .where((a) => a.command.actorId == actor.actorId)
        .firstOrNull;
    final custom = character?.customAnimations
        .where(
          (a) =>
              a.definitionId == animation?.command.definitionId &&
              (a.direction == null ||
                  a.direction == (animation?.command.direction ?? facing)),
        )
        .firstOrNull;
    return Positioned(
      left: x * cell.width - width / 2,
      top: y * cell.height - height / 2,
      width: width,
      height: height,
      child: GestureDetector(
        key: ValueKey('cinematic-actor-${actor.actorId}'),
        onTap: view.mode == CinematicMapMode.select
            ? () {
                if (!beforeSelect()) return;
                view.actorId = actor.actorId;
                widgetSelect();
              }
            : null,
        child: Tooltip(
          message: actor.label,
          child: StudioMapOverlayFrame(
            selected: !transport.previewActive && view.actorId == actor.actorId,
            child: character != null && source is CinematicWorkspaceVisuals
                ? (source as CinematicWorkspaceVisuals).cinematicActor(
                    character,
                    size: math.max(width, height),
                    facing: facing,
                    animationState: playback.state,
                    elapsedMs: animation?.elapsedMs ?? playback.elapsedMs,
                    customAnimation: custom,
                  )
                : Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
          ),
        ),
      ),
    );
  }

  void widgetSelect() {
    view.selection.clear();
    view.inspectorTab = 'actors';
    changed();
  }
}
