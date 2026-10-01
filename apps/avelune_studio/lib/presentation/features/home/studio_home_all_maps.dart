import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_library_tree.dart';
import 'studio_home_projects.dart';

class StudioHomeAllMaps extends StatelessWidget {
  const StudioHomeAllMaps({
    super.key,
    required this.maps,
    required this.groups,
    required this.onMap,
    required this.onBack,
    required this.busy,
    this.previewBuilder,
    this.onCreateMap,
    this.query = '',
  });

  final List<ProjectMapEntry> maps;
  final List<ProjectMapGroup> groups;
  final ValueChanged<String> onMap;
  final VoidCallback onBack;
  final VoidCallback? onCreateMap;
  final bool busy;
  final Widget Function(String)? previewBuilder;
  final String query;

  @override
  Widget build(BuildContext context) {
    final rows = MapLibraryTree(groups: groups, maps: maps, query: query).rows;
    final sections = <_MapCardSection>[];
    final sectionsById = <String?, _MapCardSection>{};
    final groupIds = groups.map((group) => group.id).toSet();
    for (final row in rows) {
      if (row.isFolder) {
        final section = _MapCardSection(row.label, row.depth, []);
        sections.add(section);
        sectionsById[row.folderId] = section;
      } else {
        final map = row.map!;
        final folderId = groupIds.contains(map.groupId) ? map.groupId : null;
        sectionsById[folderId]!.maps.add(map);
      }
    }
    final visibleCount = sections.fold<int>(
      0,
      (total, section) => total + section.maps.length,
    );
    return ListView.builder(
      key: const ValueKey('home-all-maps-page'),
      padding: const EdgeInsets.all(16),
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StudioButton(
                  label: 'Retour à l’accueil',
                  icon: Icons.arrow_back,
                  secondary: true,
                  onPressed: onBack,
                ),
                Text(
                  'Toutes les cartes ($visibleCount)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                StudioButton(
                  key: const ValueKey('home-all-new-map'),
                  label: 'Nouvelle carte',
                  icon: Icons.add,
                  onPressed: busy ? null : onCreateMap,
                ),
                if (visibleCount == 0)
                  Text(
                    query.isEmpty
                        ? 'Aucune carte dans ce projet.'
                        : 'Aucune carte pour cette recherche.',
                  ),
              ],
            ),
          );
        }
        final section = sections[index - 1];
        if (section.maps.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              section.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(left: section.depth * 12.0, bottom: 12),
          child: StudioPanel(
            title: section.label,
            compact: true,
            children: [
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
                      for (final map in section.maps)
                        SizedBox(
                          width:
                              (constraints.maxWidth - (count - 1) * 10) / count,
                          child: StudioHomeMapCard(
                            map: (id: map.id, name: map.name),
                            onMap: onMap,
                            busy: busy,
                            previewBuilder: previewBuilder,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapCardSection {
  _MapCardSection(this.label, this.depth, this.maps);

  final String label;
  final int depth;
  final List<ProjectMapEntry> maps;
}
