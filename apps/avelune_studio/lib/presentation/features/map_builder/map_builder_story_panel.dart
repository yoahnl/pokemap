import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_library.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

IconData mapBuilderStoryIcon(MapStoryElementKind kind) => switch (kind) {
  MapStoryElementKind.character => Icons.person_outline,
  MapStoryElementKind.interactive => Icons.chat_bubble_outline,
  MapStoryElementKind.zone => Icons.crop_square,
  MapStoryElementKind.map => Icons.outlined_flag,
};

String mapBuilderStoryKind(MapStoryElementKind kind, AppLocalizations l10n) =>
    switch (kind) {
      MapStoryElementKind.character => l10n.storyCharacters,
      MapStoryElementKind.interactive => l10n.storyInteractive,
      MapStoryElementKind.zone => l10n.storyZones,
      MapStoryElementKind.map => l10n.storyMapResults,
    };

String mapBuilderStoryName(MapStoryElement element, AppLocalizations l10n) =>
    element.kind == MapStoryElementKind.map
    ? l10n.storyMapArrival(element.name)
    : element.name;

String mapBuilderStoryState(MapStoryElement element, AppLocalizations l10n) =>
    element.behaviours.isNotEmpty
    ? l10n.storyBehaviours(element.behaviours.length)
    : element.configured
    ? l10n.storyConfigured
    : l10n.storyToConfigure;

class MapBuilderStoryPanel extends StatefulWidget {
  const MapBuilderStoryPanel({
    super.key,
    required this.outline,
    required this.binding,
  });

  final MapBuilderSpaceOutline outline;
  final MapBuilderStoryBinding binding;

  @override
  State<MapBuilderStoryPanel> createState() => _MapBuilderStoryPanelState();
}

class _MapBuilderStoryPanelState extends State<MapBuilderStoryPanel> {
  late final _search = TextEditingController(text: widget.binding.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final outline = widget.outline;
    final binding = widget.binding;
    final visible = binding.visible;
    final selected = binding.selected?.key;
    final pending = (binding.elements?.elements ?? const <MapStoryElement>[])
        .where(
          (element) =>
              element.kind != MapStoryElementKind.map && !element.configured,
        )
        .length;
    return Ink(
      key: const ValueKey('map-space-panel'),
      width: mapBuilderLibraryWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(StudioSpacing.l),
              children: [
                Text(
                  outline.eyebrow,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: StudioSpacing.xs),
                Text(
                  outline.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(outline.subtitle, style: muted),
                const SizedBox(height: StudioSpacing.l),
                TextField(
                  key: const ValueKey('map-story-search'),
                  controller: _search,
                  onChanged: binding.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: outline.searchHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                ),
                const SizedBox(height: StudioSpacing.m),
                StudioSelect(
                  key: const ValueKey('map-story-filter'),
                  label: l10n.storyShow,
                  value: binding.filter?.name ?? 'all',
                  options: {
                    'all': l10n.storyShowAll,
                    for (final kind in MapStoryElementKind.values)
                      kind.name: mapBuilderStoryKind(kind, l10n),
                  },
                  onChanged: (value) => binding.showKind(
                    MapStoryElementKind.values
                        .where((kind) => kind.name == value)
                        .firstOrNull,
                  ),
                ),
                const SizedBox(height: StudioSpacing.m),
                if (visible.isEmpty)
                  Text(
                    binding.query.trim().isEmpty
                        ? l10n.storyEmpty
                        : l10n.storyNoMatch,
                    key: const ValueKey('map-story-empty'),
                    style: muted,
                  ),
                for (final kind in MapStoryElementKind.values)
                  if (visible.any((element) => element.kind == kind)) ...[
                    _GroupHeader(
                      icon: mapBuilderStoryIcon(kind),
                      label: mapBuilderStoryKind(kind, l10n),
                      count: visible
                          .where((element) => element.kind == kind)
                          .length,
                    ),
                    for (final element in visible)
                      if (element.kind == kind)
                        StudioChoice(
                          key: ValueKey('map-story-element-${element.key}'),
                          leading: Icon(mapBuilderStoryIcon(kind), size: 16),
                          label: mapBuilderStoryName(element, l10n),
                          maxLines: 1,
                          subtitle: mapBuilderStoryState(element, l10n),
                          tone: element.configured ? null : StudioTone.warning,
                          selected: element.key == selected,
                          onTap: () => binding.select(element),
                        ),
                    const SizedBox(height: StudioSpacing.m),
                  ],
              ],
            ),
          ),
          if (pending > 0)
            Container(
              key: const ValueKey('map-story-pending'),
              padding: const EdgeInsets.all(StudioSpacing.l),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Text(l10n.storyPending(pending), style: muted),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: StudioSpacing.s),
          Expanded(child: Text(label, style: style)),
          Text('$count', style: style),
        ],
      ),
    );
  }
}
