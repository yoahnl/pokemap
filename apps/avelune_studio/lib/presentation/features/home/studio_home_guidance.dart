import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';

class StudioHomeGuidance extends StatelessWidget {
  const StudioHomeGuidance({
    super.key,
    required this.hasProject,
    required this.busy,
    required this.onDestination,
  });
  final bool hasProject, busy;
  final ValueChanged<String> onDestination;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const Text('Premiers pas'),
    childrenPadding: const EdgeInsets.all(12),
    children: [
      Text(
        !hasProject
            ? 'Ouvrez un projet existant pour retrouver vos cartes, vos ressources et votre histoire.'
            : 'Reprenez une carte, enrichissez ses rencontres, puis testez le résultat dans le jeu.',
      ),
      for (final action in [
        ('Préparer les ressources', 'resources'),
        ('Composer une carte', 'map'),
        ('Écrire une rencontre', 'story'),
      ])
        StudioButton(
          label: action.$1,
          variant: StudioButtonVariant.quiet,
          icon: Icons.arrow_forward,
          onPressed: busy ? null : () => onDestination(action.$2),
        ),
    ],
  );
}
