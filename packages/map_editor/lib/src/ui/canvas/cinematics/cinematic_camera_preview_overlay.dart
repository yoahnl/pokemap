import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class CinematicCameraPreviewOverlay extends StatelessWidget {
  const CinematicCameraPreviewOverlay({
    super.key,
    required this.cameraPose,
    required this.compact,
  });

  final CinematicCameraPlaybackPose cameraPose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!cameraPose.isActive) {
      return const SizedBox.shrink();
    }

    final hasGeometryPreview = cameraPose.geometry.isAvailable;
    final tone = cameraPose.isSupported || hasGeometryPreview
        ? PokeMapTone.info.resolve(context)
        : PokeMapTone.warning.resolve(context);
    final colors = context.pokeMapColors;
    final statusLabel = _cameraPreviewStatusLabel(cameraPose);
    final frameInset = compact ? 10.0 : 16.0;

    return IgnorePointer(
      key: const ValueKey('cinematic-builder-camera-preview-overlay'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(frameInset),
              child: DecoratedBox(
                key: const ValueKey('cinematic-builder-camera-preview-frame'),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tone.border,
                    width: compact ? 1.5 : 2,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                ),
              ),
            ),
          ),
          Positioned(
            left: frameInset + 2,
            top: frameInset + (compact ? 34 : 42),
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
                        CupertinoIcons.video_camera,
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
                              'Caméra active',
                              key: const ValueKey(
                                'cinematic-builder-camera-preview-label',
                              ),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: compact ? 11 : 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel,
                              key: const ValueKey(
                                'cinematic-builder-camera-preview-status',
                              ),
                              style: TextStyle(
                                color: cameraPose.isSupported
                                    ? tone.text
                                    : colors.textPrimary,
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
        ],
      ),
    );
  }
}

String _cameraPreviewStatusLabel(CinematicCameraPlaybackPose cameraPose) {
  if (cameraPose.geometry.isAvailable) {
    return 'Cadrage visible dans la preview.';
  }
  if (cameraPose.isSupported) {
    return 'Cadrage caméra prêt';
  }
  for (final diagnostic in cameraPose.diagnostics) {
    final message = diagnostic.message.trim();
    if (message.isNotEmpty) {
      return message;
    }
  }
  return 'Prévisualisation caméra partielle';
}
