import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_cases.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehaviourCases extends StatelessWidget {
  const GameBehaviourCases({
    super.key,
    required this.binding,
    required this.element,
    required this.record,
    required this.editable,
  });

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;
  final NarrativeEventRecord? record;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StudioSection(
      title: l10n.storyBehavioursTitle(element.behaviours.length),
      collapsible: record != null,
      initiallyExpanded: record == null,
      children: [
        Text(
          l10n.triggersCasesHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        MapBuilderStoryCaseList(
          binding: binding,
          element: element,
          current: record,
          editable: editable,
          state: mapBuilderBehaviourState,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: StudioButton(
            key: const ValueKey('map-story-behaviour-add'),
            variant: StudioButtonVariant.quiet,
            icon: Icons.add,
            label: l10n.storyAddBehaviour,
            onPressed: editable ? () => binding.addBehaviour(element) : null,
          ),
        ),
      ],
    );
  }
}
