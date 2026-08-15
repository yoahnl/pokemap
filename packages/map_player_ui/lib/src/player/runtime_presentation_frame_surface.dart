import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../theme/pokemap_player_theme.dart';
import 'presentation_frame_renderer.dart';

@immutable
final class RuntimePresentationFrameSnapshot {
  RuntimePresentationFrameSnapshot({
    required this.assetRevision,
    required this.frame,
    required this.orientation,
    this.orientationOverrides = const PresentationFrameOrientationOverrides(),
    List<PresentationFrameMediaBinding> mediaBindings =
        const <PresentationFrameMediaBinding>[],
    this.reduceMotion,
    this.reduceFlashes = false,
    this.showCaptions = true,
  })  : assert(assetRevision != ''),
        mediaBindings = List<PresentationFrameMediaBinding>.unmodifiable(
          mediaBindings,
        );

  final String assetRevision;
  final PresentationFrame frame;
  final PresentationFrameOrientation orientation;
  final PresentationFrameOrientationOverrides orientationOverrides;
  final List<PresentationFrameMediaBinding> mediaBindings;
  final bool? reduceMotion;
  final bool reduceFlashes;
  final bool showCaptions;
}

class RuntimePresentationFrameSurface extends StatelessWidget {
  const RuntimePresentationFrameSurface({
    super.key,
    required this.snapshot,
    required this.contentPort,
  });

  final RuntimePresentationFrameSnapshot snapshot;
  final PresentationFrameContentPort contentPort;

  @override
  Widget build(BuildContext context) {
    final resolvedContentPort = snapshot.mediaBindings.isEmpty
        ? contentPort
        : PresentationResponsiveFrameContentPort(
            delegate: contentPort,
            bindings: snapshot.mediaBindings,
          );
    return ColoredBox(
      key: const ValueKey<String>('runtime-presentation-frame-surface'),
      color: context.playerColors.background,
      child: PresentationFrameRenderer(
        frame: snapshot.frame,
        orientation: snapshot.orientation,
        contentPort: resolvedContentPort,
        reduceMotion: snapshot.reduceMotion,
        reduceFlashes: snapshot.reduceFlashes,
        showCaptions: snapshot.showCaptions,
        orientationOverrides: snapshot.orientationOverrides,
      ),
    );
  }
}
