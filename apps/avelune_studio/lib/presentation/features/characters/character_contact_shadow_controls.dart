import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class CharacterContactShadowControls extends StatelessWidget {
  const CharacterContactShadowControls({
    super.key,
    required this.projectDefault,
    required this.value,
    required this.onChanged,
    this.busy = false,
  });

  final bool projectDefault;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StudioToggleRow(
        key: const ValueKey('character-contact-shadow'),
        label: 'Ombre sous les pieds',
        description: value == null
            ? 'Suit le projet · ${projectDefault ? 'activée' : 'désactivée'}. Petite ombre de contact en 3D, sans silhouette projetée.'
            : 'Réglage propre à ce personnage. Petite ombre de contact en 3D, sans silhouette projetée.',
        value: value ?? projectDefault,
        onChanged: busy ? null : onChanged,
      ),
      if (value != null) ...[
        const SizedBox(height: 8),
        StudioButton(
          key: const ValueKey('character-contact-shadow-inherit'),
          label: 'Suivre le réglage du projet',
          secondary: true,
          onPressed: busy ? null : () => onChanged(null),
        ),
      ],
    ],
  );
}
