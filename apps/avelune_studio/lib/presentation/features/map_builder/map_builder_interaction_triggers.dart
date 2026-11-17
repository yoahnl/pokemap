import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'map_builder_interaction_trigger_card.dart';
import 'map_builder_name_field.dart';
import 'map_builder_story_binding.dart';
import 'map_builder_story_cases.dart';
import 'map_builder_story_errors.dart';
import 'map_builder_story_labels.dart';

class MapBuilderInteractionTriggers extends StatelessWidget {
  const MapBuilderInteractionTriggers({
    super.key,
    required this.binding,
    required this.element,
    required this.enabled,
  });

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;
  final bool enabled;

  Future<void> _add() async {
    await MapBuilderNameField.commitFocused();
    if (!binding.addBehaviour(element)) return;
    final id = binding.selectedBehaviour?.id;
    if (id != null) await binding.openInStory?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editable =
        enabled &&
        !binding.editingBlocked &&
        binding.ready &&
        binding.editing?.problem == null;
    return Column(
      key: const ValueKey('map-interaction-triggers'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (binding.error ?? binding.editing?.problem case final error?)
          StudioNotice(mapBuilderStoryError(error, l10n), isError: true),
        if (!binding.ready)
          StudioNotice(
            binding.preparing ? l10n.storyPreparing : l10n.storyNotPrepared,
          ),
        Text(
          l10n.interactionTriggersTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          l10n.interactionTriggersHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: StudioSpacing.m),
        if (element.behaviours.isEmpty) Text(l10n.storyNoBehaviour),
        MapBuilderStoryCaseList(
          binding: binding,
          element: element,
          current: binding.selectedBehaviour,
          editable: editable,
          state: mapBuilderBehaviourState,
          itemBuilder: (record, number, handle) =>
              MapBuilderInteractionTriggerCard(
                binding: binding,
                record: record,
                editable: editable,
                handle: handle,
              ),
        ),
        const SizedBox(height: StudioSpacing.s),
        StudioButton(
          key: const ValueKey('map-story-behaviour-add'),
          icon: Icons.add,
          variant: StudioButtonVariant.quiet,
          label: l10n.storyAddBehaviour,
          onPressed: editable && binding.openInStory != null
              ? () => unawaited(_add())
              : null,
        ),
      ],
    );
  }
}
