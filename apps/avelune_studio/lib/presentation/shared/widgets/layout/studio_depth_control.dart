import 'package:flutter/material.dart';
import '../buttons/studio_button.dart';

class StudioDepthControl extends StatelessWidget {
  const StudioDepthControl({
    super.key,
    required this.onForward,
    required this.onBackward,
  });
  final VoidCallback? onForward, onBackward;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      Tooltip(
        message: 'Passer devant · ⌘↑ / Ctrl↑',
        child: StudioButton(
          key: const ValueKey('Passer devant'),
          label: 'Passer devant',
          icon: Icons.flip_to_front,
          secondary: true,
          onPressed: onForward,
        ),
      ),
      Tooltip(
        message: 'Passer derrière · ⌘↓ / Ctrl↓',
        child: StudioButton(
          key: const ValueKey('Passer derrière'),
          label: 'Passer derrière',
          icon: Icons.flip_to_back,
          secondary: true,
          onPressed: onBackward,
        ),
      ),
    ],
  );
}
