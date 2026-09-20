import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_preview_transport.dart';
import 'cinematic_map_model.dart';
import 'cinematic_transport_listenable.dart';

class CinematicPlaybackViewport extends StatefulWidget {
  const CinematicPlaybackViewport({
    super.key,
    required this.model,
    required this.transport,
    required this.viewport,
    required this.cell,
    required this.child,
  });
  final CinematicMapModel model;
  final CinematicPreviewTransport transport;
  final Size viewport, cell;
  final Widget child;

  @override
  State<CinematicPlaybackViewport> createState() =>
      _CinematicPlaybackViewportState();
}

class _CinematicPlaybackViewportState extends State<CinematicPlaybackViewport> {
  CinematicPreviewPlaybackPlan? _plan;
  CinematicViewportProjection? _projection;
  CinematicMapModel? _model;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: CinematicTransportListenable(widget.transport),
    builder: (context, _) {
      final plan = widget.transport.plan;
      final model = widget.model;
      if (plan == null) return widget.child;
      if (_plan != plan || _model != model) {
        _plan = plan;
        _model = model;
        final player = model.actors.actors
            .where((a) => a.bindingKind == CinematicActorBindingKind.player)
            .firstOrNull;
        final origin = player?.position;
        _projection = CinematicViewportProjection(
          plan: plan,
          cellWidth: widget.cell.width,
          cellHeight: widget.cell.height,
          initialCamera: CinematicViewportCamera(
            centerX:
                (origin?.x ?? model.map.size.width / 2) * widget.cell.width,
            centerY:
                (origin?.y ?? model.map.size.height / 2) * widget.cell.height,
            visibleWidth:
                math.min(15, model.map.size.width) * widget.cell.width,
            visibleHeight:
                math.min(11, model.map.size.height) * widget.cell.height,
          ),
        );
      }
      final frame = _projection!.frameAt(widget.transport.timeMs);
      final camera = frame.camera;
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final zoom = resolvePixelPerfectCameraZoom(
        viewportWidth: widget.viewport.width,
        viewportHeight: widget.viewport.height,
        visibleWidth: camera.visibleWidth,
        visibleHeight: camera.visibleHeight,
        displayScale: model.project.settings.displayScale.toDouble(),
        devicePixelRatio: dpr,
      );
      final position = snapPixelPerfectCameraPosition(
        centerX: camera.centerX + frame.shakeOffsetX,
        centerY: camera.centerY,
        viewportWidth: widget.viewport.width,
        viewportHeight: widget.viewport.height,
        zoom: zoom,
        devicePixelRatio: dpr,
      );
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform(
                  key: const ValueKey('cinematic-runtime-transform'),
                  alignment: Alignment.topLeft,
                  transform: Matrix4.identity()
                    ..translateByDouble(
                      position.originX,
                      position.originY,
                      0,
                      1,
                    )
                    ..scaleByDouble(zoom, zoom, 1, 1),
                  child: IgnorePointer(child: widget.child),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  key: const ValueKey('cinematic-preview-fade'),
                  color: Theme.of(
                    context,
                  ).colorScheme.scrim.withValues(alpha: frame.fadeOpacity ?? 0),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
