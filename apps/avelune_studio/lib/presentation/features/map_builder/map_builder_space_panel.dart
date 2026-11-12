import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_library.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderSpacePanel extends StatelessWidget {
  const MapBuilderSpacePanel({
    super.key,
    required this.outline,
    this.liveRubrics = const {},
    this.selectedRubric,
    this.onRubric,
  });

  final MapBuilderSpaceOutline outline;
  final Set<String> liveRubrics;
  final String? selectedRubric;
  final ValueChanged<String>? onRubric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
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
                for (final rubric in outline.rubrics)
                  if (liveRubrics.contains(rubric.id))
                    MapBuilderRubricTile(
                      rubric: rubric,
                      selected: rubric.id == selectedRubric,
                      onTap: onRubric == null
                          ? null
                          : () => onRubric!(rubric.id),
                    )
                  else
                    MapBuilderRubricTile(rubric: rubric),
                if (outline.searchHint case final hint?) ...[
                  const SizedBox(height: StudioSpacing.l),
                  TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: hint,
                      prefixIcon: const Icon(Icons.search, size: 18),
                    ),
                  ),
                ],
                if (outline.addLabel case final label?) ...[
                  const SizedBox(height: StudioSpacing.m),
                  Tooltip(
                    message: context.l10n.unavailableNewStudio,
                    child: StudioButton(
                      label: label,
                      icon: Icons.add,
                      onPressed: null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(StudioSpacing.l),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outline.note.$1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(outline.note.$2, style: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapBuilderRubricTile extends StatelessWidget {
  const MapBuilderRubricTile({
    super.key,
    required this.rubric,
    this.selected = false,
    this.onTap,
  });

  final MapBuilderRubric rubric;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (selected || onTap != null) {
      return Tooltip(
        message: rubric.detail,
        child: StudioChoice(
          key: ValueKey('map-space-rubric-${rubric.id}'),
          label: rubric.label,
          dense: true,
          leading: Icon(rubric.icon, size: 18),
          selected: selected,
          onTap: onTap ?? () {},
        ),
      );
    }
    final faded = theme.colorScheme.onSurfaceVariant.withValues(alpha: .5);
    return Tooltip(
      message: context.l10n.rubricUnavailable(
        rubric.detail,
        context.l10n.unavailableNewStudio,
      ),
      child: ListTile(
        key: ValueKey('map-space-rubric-${rubric.id}'),
        enabled: false,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: StudioSpacing.s),
        leading: Icon(rubric.icon, size: 20, color: faded),
        title: Text(rubric.label),
        visualDensity: VisualDensity.compact,
        trailing: Text(
          context.l10n.soon,
          style: theme.textTheme.labelSmall?.copyWith(color: faded),
        ),
      ),
    );
  }
}

class MapBuilderSpaceInspectorBody extends StatelessWidget {
  const MapBuilderSpaceInspectorBody({super.key, required this.outline});

  final MapBuilderSpaceOutline outline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      key: const ValueKey('map-space-inspector'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          outline.inspectorEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          outline.inspectorTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: StudioSpacing.s),
        Text(
          outline.inspectorHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StudioSpacing.l),
        Text(
          context.l10n.unavailableNewStudio,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
