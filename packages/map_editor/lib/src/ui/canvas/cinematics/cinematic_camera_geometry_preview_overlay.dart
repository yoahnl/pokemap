import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';

class CinematicCameraGeometryPreviewOverlay extends StatelessWidget {
  const CinematicCameraGeometryPreviewOverlay({
    super.key,
    required this.cameraPose,
    required this.transform,
    required this.compact,
  });

  final CinematicCameraPlaybackPose cameraPose;
  final CinematicMapBackdropViewportTransform transform;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!cameraPose.isActive || !transform.isUsable) {
      return const SizedBox.shrink();
    }

    final geometry = cameraPose.geometry;
    if (geometry.isAvailable &&
        geometry.centerX != null &&
        geometry.centerY != null &&
        geometry.zoomPreset != null) {
      return _AvailableCameraGeometryOverlay(
        geometry: geometry,
        transform: transform,
        compact: compact,
      );
    }

    final diagnostics = geometry.diagnostics;
    if (geometry.targetKind == null && diagnostics.isEmpty) {
      return const SizedBox.shrink();
    }

    return _UnavailableCameraGeometryOverlay(
      diagnostics: diagnostics,
      compact: compact,
    );
  }
}

class _AvailableCameraGeometryOverlay extends StatelessWidget {
  const _AvailableCameraGeometryOverlay({
    required this.geometry,
    required this.transform,
    required this.compact,
  });

  final CinematicCameraPlaybackGeometry geometry;
  final CinematicMapBackdropViewportTransform transform;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = PokeMapTone.info.resolve(context);
    final center =
        transform.tileToPreview(geometry.centerX!, geometry.centerY!);
    final frameRect = _cameraFrameRectFor(
      center: center,
      transform: transform,
      zoomPreset: geometry.zoomPreset!,
    );
    final markerSize = compact ? 14.0 : 18.0;
    final labelMaxWidth = compact ? 210.0 : 280.0;
    final labelHeight = compact ? 62.0 : 72.0;
    final labelLeft = math.max(
      transform.frame.left + 6,
      math.min(transform.frame.right - labelMaxWidth - 6,
          frameRect.right - labelMaxWidth),
    );
    final labelTop = math.max(
      transform.frame.top + 6,
      math.min(transform.frame.bottom - labelHeight - 6,
          frameRect.bottom - labelHeight),
    );

    return IgnorePointer(
      key: const ValueKey('cinematic-builder-camera-geometry-overlay'),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fromRect(
            rect: frameRect,
            child: DecoratedBox(
              key: const ValueKey('cinematic-builder-camera-geometry-frame'),
              decoration: BoxDecoration(
                color: tone.soft.withValues(alpha: 0.16),
                border: Border.all(
                  color: tone.border,
                  width: compact ? 1.5 : 2,
                ),
                borderRadius: BorderRadius.circular(compact ? 8 : 10),
              ),
            ),
          ),
          Positioned(
            left: center.dx - markerSize / 2,
            top: center.dy - markerSize / 2,
            width: markerSize,
            height: markerSize,
            child: DecoratedBox(
              key: const ValueKey(
                'cinematic-builder-camera-geometry-target-marker',
              ),
              decoration: BoxDecoration(
                color: colors.brandPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.textInverse, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: colors.brandPrimary.withValues(alpha: 0.34),
                    blurRadius: compact ? 8 : 12,
                    spreadRadius: compact ? 1 : 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: labelLeft,
            top: labelTop,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: labelMaxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceBase.withValues(alpha: 0.9),
                  border: Border.all(color: tone.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 6 : 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.viewfinder,
                        color: tone.icon,
                        size: compact ? 14 : 16,
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cadrage affiché, vue non pilotée.',
                              key: const ValueKey(
                                'cinematic-builder-camera-geometry-status',
                              ),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _cameraGeometryTargetLabel(geometry),
                              key: const ValueKey(
                                'cinematic-builder-camera-geometry-target-label',
                              ),
                              style: TextStyle(
                                color: tone.text,
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _cameraGeometryZoomLabel(geometry.zoomPreset!),
                              key: const ValueKey(
                                'cinematic-builder-camera-geometry-zoom-label',
                              ),
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: compact ? 9 : 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCameraGeometryOverlay extends StatelessWidget {
  const _UnavailableCameraGeometryOverlay({
    required this.diagnostics,
    required this.compact,
  });

  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = PokeMapTone.warning.resolve(context);

    return IgnorePointer(
      key: const ValueKey('cinematic-builder-camera-geometry-fallback'),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 220 : 300),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tone.soft,
                border: Border.all(color: tone.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 6 : 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: tone.icon,
                      size: compact ? 14 : 16,
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cadrage caméra incomplet.',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cameraGeometryFallbackLabel(diagnostics),
                            style: TextStyle(
                              color: tone.text,
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Rect _cameraFrameRectFor({
  required Offset center,
  required CinematicMapBackdropViewportTransform transform,
  required CinematicCameraZoomPreset zoomPreset,
}) {
  final tileSize = _cameraFrameTileSize(zoomPreset);
  final cellWidth = transform.frame.width / transform.mapWidth;
  final cellHeight = transform.frame.height / transform.mapHeight;
  return Rect.fromCenter(
    center: center,
    width: tileSize.width * cellWidth,
    height: tileSize.height * cellHeight,
  );
}

Size _cameraFrameTileSize(CinematicCameraZoomPreset zoomPreset) {
  return switch (zoomPreset) {
    CinematicCameraZoomPreset.wide => const Size(7, 5),
    CinematicCameraZoomPreset.medium => const Size(5, 3.5),
    CinematicCameraZoomPreset.close => const Size(3, 2.25),
  };
}

String _cameraGeometryTargetLabel(CinematicCameraPlaybackGeometry geometry) {
  final label = geometry.targetLabel?.trim();
  return switch (geometry.targetKind) {
    CinematicCameraTargetKind.sceneCenter => 'Centre de la scène',
    CinematicCameraTargetKind.actor =>
      'Acteur : ${label == null || label.isEmpty ? 'acteur ciblé' : label}',
    CinematicCameraTargetKind.stagePoint =>
      'Repère : ${label == null || label.isEmpty ? 'repère ciblé' : label}',
    null => 'Cible caméra',
  };
}

String _cameraGeometryZoomLabel(CinematicCameraZoomPreset zoomPreset) {
  return switch (zoomPreset) {
    CinematicCameraZoomPreset.wide => 'Plan large',
    CinematicCameraZoomPreset.medium => 'Plan moyen',
    CinematicCameraZoomPreset.close => 'Gros plan',
  };
}

String _cameraGeometryFallbackLabel(
  List<CinematicPreviewPlaybackDiagnostic> diagnostics,
) {
  for (final diagnostic in diagnostics) {
    final label = switch (diagnostic.code) {
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetStageMapMissing =>
        'Impossible de résoudre le centre de scène.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetActorMissing =>
        'Choisissez un acteur à cadrer.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetActorUnknown =>
        'L’acteur ciblé n’est plus disponible.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetActorWithoutPosition =>
        'L’acteur ciblé n’a pas de position dans la preview.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetStagePointMissing =>
        'Choisissez un repère à cadrer.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetStagePointUnknown =>
        'Ce repère n’existe plus dans la scène.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetStagePointOutOfMap =>
        'Ce repère est en dehors de la carte.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraZoomPresetMissing =>
        'Choisissez un plan de cadrage.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraZoomPresetUnsupported =>
        'Ce plan de cadrage n’est pas supporté.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetMissing =>
        'La cible caméra n’est pas disponible.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetKindUnsupported =>
        'Cette cible caméra n’est pas supportée.',
      _ => null,
    };
    if (label != null) {
      return label;
    }
  }
  return 'La cible caméra n’est pas disponible.';
}
