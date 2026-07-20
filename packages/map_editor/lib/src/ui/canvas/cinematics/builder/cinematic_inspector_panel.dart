import 'package:flutter/widgets.dart';

/// Render-neutral owner for the Cinematic selection inspector.
final class CinematicInspectorPanel extends StatelessWidget {
  const CinematicInspectorPanel({super.key, required this.child});

  static const surfaceKey = ValueKey<String>('cinematic-inspector-panel');

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: surfaceKey, child: child);
}
