import 'package:flutter/widgets.dart';

/// Stable extraction boundary for the Cinematic command palette.
///
/// NSC-61 keeps this wrapper render-neutral so the characterized golden and
/// layout remain unchanged while the surface gains an independent owner.
final class CinematicPalettePanel extends StatelessWidget {
  const CinematicPalettePanel({super.key, required this.child});

  static const surfaceKey = ValueKey<String>('cinematic-palette-panel');

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: surfaceKey, child: child);
}
