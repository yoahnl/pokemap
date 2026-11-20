import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

class StudioHomeNavigation extends StatelessWidget {
  const StudioHomeNavigation({
    super.key,
    required this.destinations,
    required this.projectName,
    required this.busy,
    this.compact = false,
    this.onClose,
  });
  final Map<String, VoidCallback> destinations;
  final String? projectName;
  final bool busy, compact;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      ('Accueil', Icons.home_outlined, 'home'),
      ('Carte', Icons.map_outlined, 'map'),
      ('Carte régionale', Icons.public, 'regionalMap'),
      ('Ressources', Icons.grid_view_outlined, 'resources'),
      ('Histoire', Icons.menu_book_outlined, 'story'),
      ('Pokémon', Icons.catching_pokemon_outlined, 'pokemon'),
      ('Réglages du projet', Icons.tune, 'projectSettings'),
      ('Test du jeu', Icons.play_circle_outline, 'test'),
    ];
    return SizedBox(
      width: compact ? 72 : 184,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border(right: BorderSide(color: colors.outlineVariant)),
        ),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final entries = <Widget>[
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: StudioNavigationEntry(
                          key: ValueKey('studio-rail-${item.$3}'),
                          label: item.$1,
                          icon: item.$2,
                          compact: compact,
                          selected: item.$3 == 'home',
                          onTap: busy || item.$3 == 'home'
                              ? null
                              : destinations[item.$3],
                        ),
                      ),
                  ];
                  final padding = const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 26,
                  );
                  final needed =
                      padding.vertical +
                      items.fold<double>(
                        0,
                        (total, item) =>
                            total +
                            8 +
                            StudioNavigationEntry.extentOf(
                              context,
                              label: item.$1,
                              width: bounds.maxWidth - padding.horizontal,
                              compact: compact,
                            ),
                      );
                  return MediaQuery.textScalerOf(context).scale(1) <= 1.25 &&
                          bounds.maxHeight >= needed
                      ? Padding(
                          padding: padding,
                          child: Column(children: entries),
                        )
                      : ListView(padding: padding, children: entries);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onClose != null && compact)
                    IconButton(
                      key: const ValueKey('studio-project-home-close'),
                      onPressed: busy ? null : onClose,
                      tooltip: 'Fermer le projet',
                      icon: const Icon(Icons.folder_off_outlined),
                    ),
                  if (onClose != null && !compact)
                    TextButton.icon(
                      key: const ValueKey('studio-project-home-close'),
                      onPressed: busy ? null : onClose,
                      icon: const Icon(Icons.folder_off_outlined),
                      label: const Text('Fermer le projet'),
                    ),
                  if (!compact) ...[
                    Text(
                      projectName ?? 'Avelune Studio',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: projectName != null
                            ? StudioColors.of(context).success
                            : colors.onSurfaceVariant,
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            projectName != null
                                ? 'Projet chargé'
                                : 'Aucun projet ouvert',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
