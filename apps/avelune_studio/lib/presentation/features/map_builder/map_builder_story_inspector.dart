import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_cases.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_conditions.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_errors.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_line_field.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_milestones.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_presence.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_simulation.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

export 'package:avelune_studio/presentation/features/map_builder/map_builder_story_errors.dart';

part 'map_builder_story_behaviours_tab.dart';
part 'map_builder_story_properties_tab.dart';

String mapBuilderBehaviourState(
  NarrativeEventRecord record,
  AppLocalizations l10n,
) => switch (record.enabledOrNull) {
  null => l10n.storyDraft,
  true => l10n.storyActive,
  false => l10n.storyDisabled,
};

class MapBuilderStoryInspector extends StatelessWidget {
  const MapBuilderStoryInspector({
    super.key,
    required this.binding,
    required this.element,
    this.enabled = true,
  });

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final position = element.position;
    final mapName = binding.map?.name ?? '';
    return Column(
      key: ValueKey('map-story-inspector-${element.key}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow(l10n.storyKindEyebrow(element.kind.name)),
        const SizedBox(height: StudioSpacing.xs),
        Row(
          children: [
            Icon(mapBuilderStoryIcon(element.kind), size: 18),
            const SizedBox(width: StudioSpacing.s),
            Expanded(
              child: Text(
                mapBuilderStoryName(element, l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Text(
          position == null
              ? mapName
              : '$mapName · ${l10n.storyPosition(position.x, position.y)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: muted,
        ),
        const SizedBox(height: StudioSpacing.l),
        SegmentedButton<MapStoryTab>(
          key: const ValueKey('map-story-tabs'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: MapStoryTab.behaviour,
              label: Text(l10n.storyTabBehaviour),
            ),
            ButtonSegment(
              value: MapStoryTab.properties,
              label: Text(l10n.storyTabProperties),
            ),
          ],
          selected: {binding.tab},
          onSelectionChanged: (value) => binding.openTab(value.single),
        ),
        const SizedBox(height: StudioSpacing.l),
        KeyedSubtree(
          key: ValueKey('map-story-attempt-${binding.attempts}'),
          child: binding.tab == MapStoryTab.behaviour
              ? _Behaviours(
                  binding: binding,
                  element: element,
                  enabled: enabled,
                )
              : _Properties(
                  binding: binding,
                  element: element,
                  enabled: enabled,
                ),
        ),
      ],
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: StudioSpacing.m),
    child: Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: StudioSpacing.m),
        Expanded(child: second),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Eyebrow(label),
          const SizedBox(height: StudioSpacing.xxs),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }
}
