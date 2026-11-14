import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_steps.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderStoryLineField extends StatelessWidget {
  const MapBuilderStoryLineField({
    super.key,
    required this.binding,
    required this.element,
    required this.record,
    required this.editable,
    required this.scenePicker,
  });

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;
  final NarrativeEventRecord record;
  final bool editable;
  final Widget Function(String label) scenePicker;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final line = binding.lineOf(record);
    Widget field() => MapBuilderNameField(
      key: ValueKey('map-story-line-${record.id}'),
      value: line.text,
      label: binding.entityOf(element)?.npc != null
          ? l10n.storyLineSays
          : l10n.storyLineShows,
      enabled: editable,
      lines: 3,
      onCommit: (text) => binding.writeLine(element, record, text),
    );
    return Column(
      key: const ValueKey('map-story-alors'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (line.state) {
        MapStoryLineState.loading => [
          Text(
            l10n.storyLineLoading,
            key: const ValueKey('map-story-line-loading'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        MapStoryLineState.empty => [
          field(),
          const SizedBox(height: StudioSpacing.s),
          scenePicker(l10n.storyLineOrScene),
        ],
        MapStoryLineState.line => [field()],
        MapStoryLineState.shared => [
          StudioNotice(
            l10n.storyLineShared(line.sharedWith.join(', ')),
            key: const ValueKey('map-story-line-shared'),
          ),
          const SizedBox(height: StudioSpacing.s),
          Text(line.text, style: theme.textTheme.bodyMedium),
          const SizedBox(height: StudioSpacing.s),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('map-story-line-detach'),
              variant: StudioButtonVariant.quiet,
              icon: Icons.call_split,
              label: l10n.storyLineDetach,
              onPressed: editable ? () => binding.detachLine(record) : null,
            ),
          ),
        ],
        MapStoryLineState.unavailable => [
          StudioNotice(
            l10n.storyLineUnavailable(line.problem ?? ''),
            isError: true,
          ),
          const SizedBox(height: StudioSpacing.s),
          scenePicker(l10n.storyThenField),
        ],
        MapStoryLineState.scene => [
          scenePicker(l10n.storyThenField),
          if ((binding.openScene, record.sceneId) case (
            final open?,
            final sceneId?,
          )) ...[
            const SizedBox(height: StudioSpacing.s),
            Align(
              alignment: Alignment.centerLeft,
              child: StudioButton(
                key: const ValueKey('map-story-scene-open'),
                variant: StudioButtonVariant.quiet,
                icon: Icons.open_in_full,
                label: l10n.sceneFocusOpen,
                onPressed: () => open(sceneId, record.id),
              ),
            ),
          ],
          if (binding.maps.project case final project?)
            if (record.sceneId case final sceneId?)
              if (binding.sceneOf(sceneId) case final scene?) ...[
                const SizedBox(height: StudioSpacing.m),
                MapBuilderStorySteps(
                  key: ValueKey('map-story-steps-$sceneId'),
                  scene: scene,
                  project: project,
                  map: binding.map,
                  enabled: editable,
                  onChanged: (next) => binding.editScene(sceneId, next),
                ),
              ],
        ],
      },
    );
  }
}
