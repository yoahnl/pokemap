import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_conditions.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_reuse.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviour_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'map_builder_name_field.dart';
import 'map_builder_story_binding.dart';
import 'map_builder_story_labels.dart';

class MapBuilderInteractionTriggerCard extends StatefulWidget {
  const MapBuilderInteractionTriggerCard({
    super.key,
    required this.binding,
    required this.record,
    required this.editable,
    this.handle,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;
  final bool editable;
  final Widget? handle;

  @override
  State<MapBuilderInteractionTriggerCard> createState() => _TriggerCardState();
}

class _TriggerCardState extends State<MapBuilderInteractionTriggerCard> {
  bool _renaming = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final binding = widget.binding;
    final record = widget.record;
    final scene = record.sceneId == null
        ? null
        : binding.sceneOf(record.sceneId!);
    final conditions = readBehaviourConditions(record);
    final after = readBehaviourAfter(record);
    final rearm = behaviourRearmOutcome(record);
    final outcome = rearm == null
        ? null
        : binding.behaviours
              .context(binding.project!, binding.map!)
              .catalog
              .outcomeSources
              .options
              .where((option) => option.outcome == rearm && option.selectable)
              .firstOrNull;
    final incomplete =
        record.draftOrNull != null ||
        record.source == null ||
        scene == null ||
        after == null ||
        (rearm != null && outcome == null);
    final project = binding.behaviours.project(binding.project!);
    final repeat = switch (after) {
      null => l10n.storyReuseUnset,
      BehaviourAfter.once => l10n.storyOnce,
      BehaviourAfter.eachTime => l10n.storyEachTime,
      BehaviourAfter.oncePerVisit => l10n.storyOncePerVisit,
      BehaviourAfter.onceUntilOutcome => l10n.storyOnceUntilOutcome,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.m),
      child: StudioPanel(
        key: ValueKey('map-interaction-trigger-${record.id}'),
        compact: true,
        children: [
          Row(
            children: [
              ?widget.handle,
              Expanded(
                child: Text(
                  record.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              StudioContextMenuButton(
                key: ValueKey('map-interaction-trigger-actions-${record.id}'),
                tooltip: l10n.interactionActions,
                items: () => [
                  StudioContextMenuEntry(
                    label: l10n.mapLibraryRename,
                    icon: Icons.edit_outlined,
                    onSelected: widget.editable
                        ? () => setState(() => _renaming = true)
                        : null,
                  ),
                  StudioContextMenuEntry(
                    label: l10n.interactionRemove,
                    icon: Icons.delete_outline,
                    destructive: true,
                    onSelected: widget.editable
                        ? () => binding.deleteBehaviour(record)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          if (_renaming) ...[
            const SizedBox(height: StudioSpacing.m),
            MapBuilderNameField(
              key: ValueKey('map-story-behaviour-name-${record.id}'),
              value: record.name,
              label: l10n.storyBehaviourNameField,
              enabled: widget.editable,
              onSubmit: (name) async {
                final renamed = binding.renameBehaviour(record, name);
                if (renamed && mounted) setState(() => _renaming = false);
                return renamed;
              },
            ),
            const SizedBox(height: StudioSpacing.s),
          ],
          Wrap(
            spacing: StudioSpacing.xs,
            runSpacing: StudioSpacing.xs,
            children: [
              StudioBadge(
                mapBuilderBehaviourState(record, l10n),
                tone: record.enabledOrNull == true
                    ? StudioTone.success
                    : StudioTone.neutral,
              ),
              if (incomplete)
                StudioBadge(l10n.triggersIncomplete, tone: StudioTone.warning),
            ],
          ),
          const SizedBox(height: StudioSpacing.s),
          Text(l10n.storyTrigger(record.source?.kind.name ?? 'none')),
          const SizedBox(height: StudioSpacing.xs),
          Text(
            conditions.fullyEditable
                ? l10n.behaviourConditions(
                    conditions,
                    (id) => project.facts
                        .where((fact) => fact.id == id)
                        .firstOrNull
                        ?.label,
                  )
                : l10n.interactionComplex,
          ),
          const SizedBox(height: StudioSpacing.s),
          StudioPanel(
            compact: true,
            children: [
              Text(
                l10n.storyThen,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                scene?.name ??
                    (record.sceneId == null
                        ? l10n.storySceneMissing
                        : l10n.interactionSceneUnavailable),
              ),
            ],
          ),
          const SizedBox(height: StudioSpacing.s),
          Text(repeat),
          if (rearm != null)
            Text(
              outcome == null
                  ? l10n.triggersOutcomeUnavailable
                  : '${outcome.producerLabel} · ${outcome.outcomeLabel}',
            ),
          const SizedBox(height: StudioSpacing.s),
          StudioButton(
            key: ValueKey('map-interaction-trigger-open-${record.id}'),
            label: incomplete ? l10n.interactionComplete : l10n.interactionEdit,
            icon: Icons.north_east,
            variant: StudioButtonVariant.secondary,
            onPressed: binding.openInStory == null
                ? null
                : () => unawaited(binding.openInStory!(record.id)),
          ),
        ],
      ),
    );
  }
}
