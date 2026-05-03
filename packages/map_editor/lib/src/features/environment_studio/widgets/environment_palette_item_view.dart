import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';

/// Carte d’un item de palette Environment (read-only).
class EnvironmentPaletteItemView extends StatelessWidget {
  const EnvironmentPaletteItemView({
    super.key,
    required this.item,
    required this.subtleColor,
  });

  final EnvironmentPaletteItem item;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);
    final tags = item.tags.toList()..sort();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        color: fill,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.elementId,
                    key: Key(
                        'environment-studio-palette-item-${item.elementId}'),
                    style: TextStyle(
                      color: label,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                _miniChip(
                  context,
                  label: 'Poids ${item.weight}',
                  key: Key(
                      'environment-studio-palette-weight-${item.elementId}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _collisionLabel(item.collisionMode),
              key: Key(
                'environment-studio-palette-collision-${item.elementId}',
              ),
              style: TextStyle(
                color: subtleColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in tags)
                    _miniChip(
                      context,
                      label: t,
                      key: Key(
                        'environment-studio-palette-tag-${item.elementId}-$t',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _collisionLabel(EnvironmentCollisionMode m) {
    return switch (m) {
      EnvironmentCollisionMode.useElementDefault => 'Défaut élément',
      EnvironmentCollisionMode.forceEnabled => 'Collision forcée',
      EnvironmentCollisionMode.forceDisabled => 'Collision désactivée',
    };
  }

  Widget _miniChip(
    BuildContext context, {
    required String label,
    Key? key,
  }) {
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: subtle,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
