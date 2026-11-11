import 'package:flutter/material.dart';
import 'package:avelune_design_system/presentation/shared/widgets/layout/studio_navigation_entry.dart';

import '../../../../features/shell/application/studio_primary_destinations.dart';
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
    final selectedDestination = studioSelectedDestination(active);
    const icons = {
      'home': Icons.home_outlined,
      'map': Icons.map_outlined,
      'regionalMap': Icons.public,
      'resources': Icons.grid_view_outlined,
      'story': Icons.menu_book_outlined,
      'pokemon': Icons.catching_pokemon_outlined,
      'projectSettings': Icons.tune,
      'test': Icons.play_circle_outline,
    };
    final items = [
      for (final destination in studioPrimaryDestinations)
        (destination.label, icons[destination.id]!, destination.id),
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
                          key: ValueKey('studio-navigation-${item.$1}'),
                          label: item.$1,
                          icon: item.$2,
                          compact: compact,
                          selected: item.$3 == selectedDestination,
                          unavailableReason: studioDestinationUnavailableReason(
                            item.$3,
                            busy: busy,
                            canTest: canTest,
                          ),
                          onTap:
                              studioDestinationUnavailableReason(
                                    item.$3,
                                    busy: busy,
                                    canTest: canTest,
                                  ) !=
                                  null
                              ? null
                              : item.$3 == active
                              ? () {}
                              : () => onDestination(item.$3),
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
