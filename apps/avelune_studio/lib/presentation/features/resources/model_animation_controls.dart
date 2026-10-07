import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ModelAnimationControls extends StatelessWidget {
  const ModelAnimationControls({
    super.key,
    required this.clips,
    required this.animationIndex,
    required this.loop,
    required this.speed,
    required this.paused,
    required this.onClip,
    required this.onLoop,
    required this.onSpeed,
    required this.onPause,
    required this.onReplay,
  });

  final List<Model3dAnimation> clips;
  final int? animationIndex;
  final bool loop, paused;
  final double speed;
  final ValueChanged<int?> onClip;
  final ValueChanged<bool> onLoop;
  final ValueChanged<double> onSpeed;
  final VoidCallback onPause, onReplay;

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Animation',
    children: [
      StudioSelect(
        label: 'Animation du décor',
        value: animationIndex?.toString() ?? 'none',
        options: {
          'none': 'Pose de repos',
          for (final clip in clips)
            '${clip.index}':
                '${clip.name} · ${clip.durationSeconds.toStringAsFixed(2)} s',
        },
        onChanged: (value) => onClip(int.tryParse(value)),
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Lecture',
        value: loop ? 'loop' : 'once',
        options: const {
          'once': 'Une fois · garder la pose finale',
          'loop': 'En boucle',
        },
        onChanged: (value) => onLoop(value == 'loop'),
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Vitesse',
        value: '$speed',
        options: {
          for (final rate in <double>{.25, .5, 1, 2, speed}.toList()..sort())
            '$rate': '× $rate',
        },
        onChanged: (value) => onSpeed(double.parse(value)),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StudioButton(
            label: paused ? 'Reprendre l’aperçu' : 'Pause de l’aperçu',
            secondary: true,
            onPressed: animationIndex == null ? null : onPause,
          ),
          StudioButton(
            label: 'Rejouer',
            secondary: true,
            onPressed: animationIndex == null ? null : onReplay,
          ),
        ],
      ),
    ],
  );
}
