import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_panel.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';

const mapBuilderInspectorWidth = 280.0;

class MapBuilderInspector extends StatelessWidget {
  const MapBuilderInspector({
    super.key,
    required this.entry,
    required this.projectName,
    this.space = MapBuilderSpace.construction,
    required this.armed,
    required this.toolLabel,
    required this.toolHint,
    required this.onRelease,
    required this.onCollapse,
    this.body,
  });

  final ProjectMapEntry? entry;
  final String projectName;
  final MapBuilderSpace space;
  final ResourceItem? armed;
  final String? toolLabel;
  final String? toolHint;
  final VoidCallback onRelease;
  final VoidCallback onCollapse;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entry = this.entry;
    return Ink(
      key: const ValueKey('map-inspector'),
      width: mapBuilderInspectorWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.only(left: StudioSpacing.xl),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Text(
                  context.l10n.inspectorTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.inspectorCollapse,
                  onPressed: onCollapse,
                  icon: const Icon(Icons.last_page, size: 18),
                ),
              ],
            ),
          ),
          if (entry != null)
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.activeMapEyebrow,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: StudioSpacing.m),
                  Text(
                    entry.name,
                    key: const ValueKey('map-inspector-name'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: StudioSpacing.xs),
                  Text(
                    context.l10n.roleWithProject(
                      context.l10n.mapRole(entry.role),
                      projectName,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(StudioSpacing.xl),
              child:
                  body ??
                  switch (mapBuilderSpaceOutline(space, context.l10n)) {
                    final outline? => MapBuilderSpaceInspectorBody(
                      outline: outline,
                    ),
                    null =>
                      armed == null
                          ? const _BuildGuide()
                          : _ActiveTool(
                              item: armed!,
                              toolLabel: toolLabel,
                              toolHint: toolHint,
                              onRelease: onRelease,
                            ),
                  },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTool extends StatelessWidget {
  const _ActiveTool({
    required this.item,
    required this.toolLabel,
    required this.toolHint,
    required this.onRelease,
  });

  final ResourceItem item;
  final String? toolLabel;
  final String? toolHint;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final toolLabel = this.toolLabel;
    final toolHint = this.toolHint;
    return Column(
      key: const ValueKey('map-inspector-active-tool'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.activeToolEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          item.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          toolLabel == null
              ? context.l10n.resourceType(item)
              : context.l10n.toolWithType(
                  toolLabel,
                  context.l10n.resourceType(item),
                ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (toolHint != null) ...[
          const SizedBox(height: StudioSpacing.l),
          Text(toolHint, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: StudioSpacing.l),
        StudioButton(
          key: const ValueKey('map-inspector-release'),
          label: context.l10n.backToSelection,
          icon: Icons.near_me_outlined,
          variant: StudioButtonVariant.secondary,
          onPressed: onRelease,
        ),
      ],
    );
  }
}

class _BuildGuide extends StatelessWidget {
  const _BuildGuide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final steps = [
      (l10n.buildGuideFindTitle, l10n.buildGuideFindBody),
      (l10n.buildGuidePreviewTitle, l10n.buildGuidePreviewBody),
      (l10n.buildGuideBuildTitle, l10n.buildGuideBuildBody),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.buildGuideTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: StudioSpacing.l),
        for (final (index, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: scheme.surfaceContainerHigh,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: StudioSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        step.$2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
