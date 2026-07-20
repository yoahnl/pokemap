import 'package:flutter/widgets.dart';

/// Render-neutral owner for the deterministic Cinematic timeline surface.
final class CinematicTimelinePanel extends StatelessWidget {
  const CinematicTimelinePanel({super.key, required this.child});

  static const surfaceKey = ValueKey<String>('cinematic-timeline-panel');

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: surfaceKey, child: child);
}
