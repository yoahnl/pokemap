import 'package:flutter/material.dart';
import '../../../theme/studio_tokens.dart';

class StudioPrimaryNavigation extends StatelessWidget {
  const StudioPrimaryNavigation({
    super.key,
    required this.onDestination,
    required this.projectName,
    required this.busy,
    required this.canTest,
    this.compact = false,
    this.active = 'home',
    this.onClose,
  });
  final ValueChanged<String> onDestination;
  final String? projectName;
  final bool busy, compact, canTest;
  final String active;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedDestination = active == 'gameExport'
        ? 'home'
        : active == 'scene' ||
              active == 'progression' ||
              active == 'events' ||
              active == 'dialogue' ||
              active == 'cinematic'
        ? 'story'
        : active;
    final items = [
      ('Accueil', Icons.home_outlined, 'home'),
      ('Carte', Icons.map_outlined, 'map'),
      ('Ressources', Icons.grid_view_outlined, 'resources'),
      ('Histoire', Icons.menu_book_outlined, 'story'),
      ('Pokémon', Icons.catching_pokemon_outlined, 'pokemon'),
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
                        child: Tooltip(
                          message: item.$1,
                          child: Material(
                            color: item.$3 == selectedDestination
                                ? colors.primaryContainer
                                : colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap:
                                  item.$3 != active &&
                                      (item.$3 != 'test' || canTest) &&
                                      !busy
                                  ? () => onDestination(item.$3)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 13,
                                ),
                                child: Row(
                                  children: [
                                    Icon(item.$2, size: 22),
                                    if (!compact) ...[
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          item.$1,
                                          style: TextStyle(
                                            fontWeight:
                                                item.$3 == selectedDestination
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ];
                  final padding = const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 26,
                  );
                  return MediaQuery.textScalerOf(context).scale(1) <= 1.25 &&
                          bounds.maxHeight >= items.length * 64 + 52
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
                      key: const ValueKey('Fermer le projet'),
                      onPressed: onClose,
                      tooltip: 'Fermer le projet',
                      icon: const Icon(Icons.folder_off_outlined),
                    ),
                  if (onClose != null && !compact)
                    TextButton.icon(
                      key: const ValueKey('Fermer le projet'),
                      onPressed: onClose,
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
