import 'package:flutter/widgets.dart';

/// Render-neutral owner for the stage/preview surface extracted in NSC-61.
final class CinematicStagePanel extends StatelessWidget {
  const CinematicStagePanel({super.key, required this.child});

  static const surfaceKey = ValueKey<String>('cinematic-stage-panel');

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: surfaceKey, child: child);
}
