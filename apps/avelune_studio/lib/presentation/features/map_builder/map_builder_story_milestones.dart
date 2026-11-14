import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_conditions.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/story/trame_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

StorylineMilestoneAt? mapBuilderConditionMilestone(
  MapBuilderStoryBinding binding,
  BehaviourEditableCondition condition,
) => condition.test == BehaviourConditionTest.isTrue
    ? binding.trame?.view?.milestoneOfFact(condition.factId)
    : null;

class MapBuilderStoryMilestoneField extends StatefulWidget {
  const MapBuilderStoryMilestoneField({
    super.key,
    required this.binding,
    required this.record,
    required this.editable,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;
  final bool editable;

  @override
  State<MapBuilderStoryMilestoneField> createState() =>
      _MapBuilderStoryMilestoneFieldState();
}

class _MapBuilderStoryMilestoneFieldState
    extends State<MapBuilderStoryMilestoneField> {
  @override
  void initState() {
    super.initState();
    final trame = widget.binding.trame;
    if (trame != null) scheduleMicrotask(() => unawaited(trame.open()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final trame = widget.binding.trame;
    if (trame != null) scheduleMicrotask(trame.sync);
    final view = trame?.view;
    final sceneId = widget.record.sceneId;
    if (trame == null || view == null) return const SizedBox.shrink();
    final current = view.milestoneOfScene(sceneId);
    final shared = sceneId == null ? 0 : view.behavioursOfScene(sceneId).length;
    return Column(
      key: const ValueKey('map-story-milestone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: l10n.storyMilestoneField,
          value: current?.milestone.id ?? '',
          options: {
            '': l10n.trameOutside,
            for (final at in view.milestones)
              at.milestone.id: l10n.trameMilestoneOption(
                l10n.trameName(at.chapter.title, l10n.trameUnnamed),
                l10n.trameName(at.milestone.title, l10n.trameUnnamed),
              ),
          },
          onChanged: widget.editable && sceneId != null
              ? (id) {
                  final target = view.milestone(id);
                  unawaited(
                    target == null
                        ? trame.detachScene(
                            current!.storyline.id,
                            current.chapter.id,
                            current.milestone.id,
                            sceneId,
                          )
                        : trame.attachScene(
                            target.storyline.id,
                            target.chapter.id,
                            id,
                            sceneId,
                          ),
                  );
                }
              : null,
        ),
        Text(
          sceneId == null
              ? l10n.trameNeedsScene
              : shared > 1
              ? l10n.trameSharedScene(shared)
              : l10n.trameAttachWholeScene,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class MapBuilderStoryMilestonePicker extends StatelessWidget {
  const MapBuilderStoryMilestonePicker({
    super.key,
    required this.binding,
    required this.onPick,
    required this.onClose,
  });

  final MapBuilderStoryBinding binding;
  final ValueChanged<String> onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trame = binding.trame;
    if (trame != null) scheduleMicrotask(() => unawaited(trame.open()));
    final milestones = [
      for (final at
          in trame?.view?.milestones ?? const <StorylineMilestoneAt>[])
        if (at.milestone.completionFactId != null) at,
    ];
    return Column(
      key: const ValueKey('map-story-milestone-picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (milestones.isEmpty)
          Text(
            l10n.storyMilestoneNone,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (final at in milestones)
          StudioChoice(
            key: ValueKey('map-story-after-${at.milestone.id}'),
            dense: true,
            label: l10n.trameName(at.milestone.title, l10n.trameUnnamed),
            subtitle: l10n.trameName(at.chapter.title, l10n.trameUnnamed),
            onTap: () => onPick(at.milestone.completionFactId!),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: StudioButton(
            variant: StudioButtonVariant.quiet,
            label: l10n.storyFactClose,
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}

class MapBuilderStoryMilestoneCondition extends StatelessWidget {
  const MapBuilderStoryMilestoneCondition({
    super.key,
    required this.at,
    required this.onRemove,
  });

  final StorylineMilestoneAt at;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StudioChoice(
      dense: true,
      label: l10n.storyAfterMilestone(
        l10n.trameName(at.milestone.title, l10n.trameUnnamed),
      ),
      onTap: null,
      trailing: IconButton(
        key: const ValueKey('map-story-condition-remove'),
        tooltip: l10n.storyConditionRemove,
        icon: const Icon(Icons.close, size: 16),
        onPressed: onRemove,
      ),
    );
  }
}
