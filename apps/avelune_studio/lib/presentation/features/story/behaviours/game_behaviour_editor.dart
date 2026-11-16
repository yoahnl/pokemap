import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehaviourEditor extends StatefulWidget {
  const GameBehaviourEditor({
    super.key,
    required this.binding,
    required this.editable,
  });

  final MapBuilderStoryBinding binding;
  final bool editable;

  @override
  State<GameBehaviourEditor> createState() => _GameBehaviourEditorState();
}

class _GameBehaviourEditorState extends State<GameBehaviourEditor> {
  bool _contextOpen = false;

  MapBuilderStoryBinding get binding => widget.binding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = binding.selectedBehaviour;
    final element = binding.selected!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioPageHeader(
          title: record == null
              ? l10n.storyNoBehaviour
              : record.name.trim().isEmpty
              ? l10n.behavioursUnnamed
              : record.name,
          description: l10n.triggersEditorHint,
          compact: true,
          alignActionsToEnd: true,
          actions: [
            StudioButton(
              key: const ValueKey('story-trigger-context-toggle'),
              label: l10n.triggersContext,
              icon: _contextOpen ? Icons.info : Icons.info_outline,
              variant: StudioButtonVariant.quiet,
              onPressed: () => setState(() => _contextOpen = !_contextOpen),
            ),
          ],
        ),
        if (record != null && _contextOpen)
          StudioSection(
            key: ValueKey('story-trigger-context-${record.id}'),
            title: l10n.triggersContext,
            children: [
              Text(
                '${binding.map?.name ?? l10n.behavioursMissingMap} · ${mapBuilderStoryName(element, l10n)}',
              ),
              Text(l10n.triggersPriority(record.priority)),
            ],
          ),
        MapBuilderStoryBehaviourEditor(
          key: ValueKey('map-story-attempt-${binding.attempts}'),
          binding: binding,
          element: element,
          enabled: widget.editable,
          sectionBuilder: (section, content) => StudioPanel(
            key: ValueKey('story-trigger-block-$section'),
            compact: true,
            title: switch (section) {
              'when' => l10n.storyWhen,
              'if' => l10n.storyIf,
              'then' => l10n.storyThen,
              _ => l10n.triggersRepeat,
            },
            icon: switch (section) {
              'when' => Icons.bolt_outlined,
              'if' => Icons.call_split,
              'then' => Icons.account_tree_outlined,
              _ => Icons.repeat,
            },
            accent: switch (section) {
              'when' => StudioAccent.halo,
              'if' => StudioAccent.fog,
              'then' => StudioAccent.water,
              _ => StudioAccent.firefly,
            },
            children: [content],
          ),
        ),
      ],
    );
  }
}
