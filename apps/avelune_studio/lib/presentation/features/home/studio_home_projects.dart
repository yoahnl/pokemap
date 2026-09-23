import 'package:flutter/material.dart';
import '../../../features/home/domain/recent_studio_project.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../theme/studio_tokens.dart';

class StudioHomeRecentProjects extends StatelessWidget {
  const StudioHomeRecentProjects({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.onRemove,
    required this.busy,
    this.bounded = false,
  });
  final List<RecentStudioProject> entries;
  final ValueChanged<RecentStudioProject> onOpen, onRemove;
  final bool busy;
  final bool bounded;

  Widget _entry(BuildContext context, RecentStudioProject entry) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: busy ? null : () => onOpen(entry),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.folder_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.directoryPath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Ouvert le ${entry.lastOpenedAt.day.toString().padLeft(2, '0')}/${entry.lastOpenedAt.month.toString().padLeft(2, '0')}/${entry.lastOpenedAt.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Retirer ${entry.name} des récents',
          onPressed: busy ? null : () => onRemove(entry),
          icon: const Icon(Icons.close, size: 16),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Projets récents',
    compact: true,
    children: [
      if (entries.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('Les projets que vous ouvrez apparaîtront ici.'),
        ),
      if (bounded && entries.isNotEmpty)
        Expanded(
          child: ListView.builder(
            key: const ValueKey('home-recent-projects-list'),
            itemCount: entries.length,
            itemBuilder: (context, index) => _entry(context, entries[index]),
          ),
        )
      else
        for (final entry in entries) _entry(context, entry),
    ],
  );
}

class StudioHomeResume extends StatelessWidget {
  const StudioHomeResume({
    super.key,
    required this.maps,
    required this.onMap,
    required this.hasProject,
    required this.busy,
    this.onAllMaps,
    this.maxPreview = 4,
  });
  final List<({String id, String name})> maps;
  final ValueChanged<String> onMap;
  final bool hasProject, busy;
  final VoidCallback? onAllMaps;
  final int maxPreview;

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Cartes de votre projet',
    compact: true,
    children: [
      if (maps.length > maxPreview)
        Align(
          alignment: Alignment.centerRight,
          child: StudioButton(
            label: 'Voir toutes les cartes (${maps.length})',
            secondary: true,
            onPressed: busy ? null : onAllMaps,
          ),
        ),
      if (maps.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 26),
          child: Text(
            hasProject
                ? 'Aucune carte à afficher dans ce projet.'
                : 'Ouvrez un projet pour retrouver ses cartes.',
          ),
        ),
      LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth > 750
              ? 4
              : constraints.maxWidth > 420
              ? 2
              : 1;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final map in maps.take(maxPreview))
                SizedBox(
                  width: (constraints.maxWidth - (count - 1) * 10) / count,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 100,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                color: StudioColors.of(context).success,
                                size: 32,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Aperçu indisponible',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                map.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              StudioButton(
                                label: 'Ouvrir',
                                secondary: true,
                                onPressed: busy ? null : () => onMap(map.id),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
