import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';

class PokemonCombatDetailHeader extends StatelessWidget {
  const PokemonCombatDetailHeader({
    super.key,
    required this.title,
    required this.id,
    required this.dirty,
    required this.created,
    required this.saving,
    required this.onSave,
    required this.onDiscard,
    required this.onDelete,
    this.onBack,
  });

  final String title;
  final String id;
  final bool dirty;
  final bool created;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onDelete;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                tooltip: 'Retour à la liste',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
            Flexible(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(id, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StudioButton(
              label: 'Enregistrer',
              icon: Icons.save_outlined,
              onPressed: dirty && !saving ? onSave : null,
            ),
            StudioButton(
              label: 'Annuler les modifications',
              secondary: true,
              onPressed: dirty && !saving ? onDiscard : null,
            ),
            StudioButton(
              label: 'Supprimer',
              variant: StudioButtonVariant.destructive,
              onPressed: created || dirty || saving ? null : onDelete,
            ),
          ],
        ),
      ],
    ),
  );
}
