import 'package:flutter/material.dart';

import '../../theme/studio_tokens.dart';

class PokemonMediaRoleCard extends StatelessWidget {
  const PokemonMediaRoleCard({
    super.key,
    required this.role,
    required this.path,
    required this.selected,
    required this.onTap,
  });

  final String role;
  final String? path;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: InkWell(
        key: ValueKey('media-role-$role'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(_icon(role), color: colors.onSurfaceVariant),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pokemonMediaRoleLabel(role),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      path?.isNotEmpty == true
                          ? 'Référence associée'
                          : 'Non associé',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.chevron_right, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

String pokemonMediaRoleLabel(String role) => switch (role) {
  'icon' => 'Icône',
  'party' => 'Image d’équipe',
  'portrait' => 'Portrait',
  'frontStatic' => 'Face avant',
  'backStatic' => 'Face arrière',
  'frontShinyStatic' => 'Face avant chromatique',
  'backShinyStatic' => 'Face arrière chromatique',
  'overworld' => 'Monde extérieur',
  'cry' => 'Cri',
  _ => role,
};

IconData _icon(String role) => switch (role) {
  'icon' => Icons.apps,
  'party' => Icons.people_outline,
  'portrait' => Icons.portrait,
  'frontStatic' || 'backStatic' => Icons.image_outlined,
  'frontShinyStatic' || 'backShinyStatic' => Icons.auto_awesome,
  'overworld' => Icons.map_outlined,
  'cry' => Icons.graphic_eq,
  _ => Icons.insert_drive_file_outlined,
};
