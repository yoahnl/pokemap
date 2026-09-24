import 'package:flutter/material.dart';

import '../../shared/widgets/layout/studio_panel.dart';
import '../../theme/studio_tokens.dart';

class PokemonBaseStats extends StatelessWidget {
  const PokemonBaseStats({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    const labels = [
      ('hp', 'PV'),
      ('atk', 'Attaque'),
      ('def', 'Défense'),
      ('spa', 'Attaque spéciale'),
      ('spd', 'Défense spéciale'),
      ('spe', 'Vitesse'),
    ];
    final colors = Theme.of(context).colorScheme;
    final accents = [
      StudioColors.of(context).success,
      StudioColors.of(context).warning,
      colors.primary,
      StudioColors.of(context).featureAccent,
      StudioColors.of(context).canvasSelection,
      colors.tertiary,
    ];
    return StudioPanel(
      title: 'Statistiques de base',
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  child: Text(
                    labels[i].$2,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text('${stats[labels[i].$1] ?? '—'}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: stats[labels[i].$1] is num
                        ? ((stats[labels[i].$1] as num) / 255)
                              .clamp(0, 1)
                              .toDouble()
                        : 0,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(4),
                    color: accents[i],
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
        Text('Total : ${stats['bst'] ?? '—'}'),
        const SizedBox(height: 5),
        Text(
          'Barres comparées sur une échelle de 255 points.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
