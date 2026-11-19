import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'resource_library_view_data.dart';

class ResourceLibraryHeading extends StatelessWidget {
  const ResourceLibraryHeading({
    super.key,
    this.onImport,
    this.onCreate,
    this.onRefresh,
  });

  final VoidCallback? onImport;
  final VoidCallback? onCreate;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: StudioSpacing.xl,
    runSpacing: StudioSpacing.l,
    children: [
      Text(
        'Ressources',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      Wrap(
        spacing: StudioSpacing.m,
        children: [
          if (onImport != null)
            StudioButton(
              label: 'Importer',
              secondary: true,
              icon: Icons.add,
              onPressed: onImport,
            ),
          if (onCreate != null)
            StudioButton(
              label: 'Créer',
              icon: Icons.auto_awesome_outlined,
              onPressed: onCreate,
            ),
          if (onRefresh != null)
            StudioTool(
              label: 'Actualiser la bibliothèque',
              icon: Icons.refresh,
              onPressed: onRefresh,
            ),
        ],
      ),
    ],
  );
}

class ResourceLibraryResultsHeading extends StatelessWidget {
  const ResourceLibraryResultsHeading({
    super.key,
    required this.category,
    required this.count,
    required this.toolbar,
    this.onCategory,
  });

  final ResourceLibraryCategory? category;
  final int count;
  final Widget toolbar;
  final ValueChanged<ResourceLibraryCategory?>? onCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final select = onCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (select != null) ...[
          StudioSelect(
            label: 'Catégorie',
            value: category?.name ?? '',
            options: {
              '': 'Toutes les ressources',
              for (final option in ResourceLibraryCategory.values)
                option.name: option.label,
            },
            onChanged: (value) => select(
              value.isEmpty
                  ? null
                  : ResourceLibraryCategory.values.byName(value),
            ),
          ),
          const SizedBox(height: StudioSpacing.l),
        ],
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: StudioSpacing.xl,
            runSpacing: StudioSpacing.l,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.label ?? 'Toutes les ressources',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: StudioSpacing.xs),
                  Text(
                    '$count ${count == 1 ? 'ressource' : 'ressources'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              toolbar,
            ],
          ),
        ),
      ],
    );
  }
}

class ResourceLibraryTabs extends StatelessWidget {
  const ResourceLibraryTabs({
    super.key,
    required this.section,
    required this.onSelected,
    required this.showWorkshops,
  });

  final ResourceLibrarySection section;
  final ValueChanged<ResourceLibrarySection> onSelected;
  final bool showWorkshops;

  @override
  Widget build(BuildContext context) => StudioTabBar(
    tabs: [
      const StudioTab(
        value: ResourceLibrarySection.library,
        label: 'Bibliothèque',
      ),
      if (showWorkshops)
        const StudioTab(
          value: ResourceLibrarySection.workshops,
          label: 'Ateliers',
        ),
    ],
    selected: section,
    onSelected: onSelected,
    fill: true,
  );
}

class ResourceLibrarySidebar extends StatelessWidget {
  const ResourceLibrarySidebar({
    super.key,
    required this.section,
    required this.onSection,
    required this.category,
    required this.categoryCounts,
    required this.onCategory,
    required this.total,
    required this.showWorkshops,
  });

  final ResourceLibrarySection section;
  final ValueChanged<ResourceLibrarySection> onSection;
  final ResourceLibraryCategory? category;
  final Map<ResourceLibraryCategory, int> categoryCounts;
  final ValueChanged<ResourceLibraryCategory?> onCategory;
  final int total;
  final bool showWorkshops;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResourceLibraryTabs(
            section: section,
            onSelected: onSection,
            showWorkshops: showWorkshops,
          ),
          if (section == ResourceLibrarySection.library)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(StudioSpacing.l),
                children: [
                  _categoryEntry(
                    'Toutes les ressources',
                    Icons.folder_open_outlined,
                    total,
                  ),
                  for (final media in [false, true])
                    if (categoryCounts.keys.any(
                      (category) => category.media == media,
                    )) ...[
                      const SizedBox(height: StudioSpacing.xl),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: StudioSpacing.l,
                          vertical: StudioSpacing.s,
                        ),
                        child: Text(
                          media ? 'MÉDIAS DU PROJET' : 'CONSTRUCTION DE CARTE',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: .75,
                          ),
                        ),
                      ),
                      for (final option in ResourceLibraryCategory.values)
                        if (option.media == media &&
                            categoryCounts.containsKey(option))
                          _categoryEntry(
                            option.label,
                            option.icon,
                            categoryCounts[option]!,
                            option,
                          ),
                    ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryEntry(
    String label,
    IconData icon,
    int count, [
    ResourceLibraryCategory? option,
  ]) => StudioNavigationEntry(
    label: label,
    icon: icon,
    marker: Text('$count'),
    markerLabel: '$count ${count == 1 ? 'ressource' : 'ressources'}',
    selected: category == option,
    onTap: () => onCategory(option),
  );
}

class ResourceLibraryScopePanel extends StatelessWidget {
  const ResourceLibraryScopePanel({
    super.key,
    required this.maps,
    required this.mapId,
    required this.onMap,
    required this.scope,
    required this.counts,
    required this.onScope,
  });

  final Map<String, String> maps;
  final String? mapId;
  final ValueChanged<String> onMap;
  final ResourceLibraryScope scope;
  final Map<ResourceLibraryScope, int> counts;
  final ValueChanged<ResourceLibraryScope> onScope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapName = maps[mapId] ?? 'cette carte';
    final explanation = switch (scope) {
      ResourceLibraryScope.project => 'Toutes les ressources du projet.',
      ResourceLibraryScope.used => 'Ressources utilisées sur $mapName.',
      ResourceLibraryScope.exclusive =>
        'Ressources utilisées uniquement sur $mapName, réutilisables ailleurs.',
    };
    return StudioPanel(
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: StudioSpacing.l,
            spacing: StudioSpacing.l,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PÉRIMÈTRE DES RESSOURCES',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: .75,
                    ),
                  ),
                  const SizedBox(height: StudioSpacing.s),
                  Text(
                    'Quelles ressources afficher ?',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              if (maps.isNotEmpty)
                SizedBox(
                  width: 190,
                  child: StudioSelect(
                    label: 'Carte de référence',
                    value: mapId,
                    options: maps,
                    onChanged: onMap,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: StudioSpacing.l),
        Wrap(
          spacing: StudioSpacing.m,
          runSpacing: StudioSpacing.xs,
          children: [
            for (final option in ResourceLibraryScope.values)
              StudioFilterChip(
                key: ValueKey('library-scope-${option.name}'),
                label: '${option.label} · ${counts[option] ?? 0}',
                selected: option == scope,
                onSelected:
                    mapId == null && option != ResourceLibraryScope.project
                    ? null
                    : (_) => onScope(option),
              ),
          ],
        ),
        const SizedBox(height: StudioSpacing.s),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16),
            const SizedBox(width: StudioSpacing.m),
            Expanded(
              child: Text(explanation, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ],
    );
  }
}
