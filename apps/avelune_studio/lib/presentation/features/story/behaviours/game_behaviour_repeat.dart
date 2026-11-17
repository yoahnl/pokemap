import 'dart:convert';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_reuse.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehaviourRepeat extends StatefulWidget {
  const GameBehaviourRepeat({
    super.key,
    required this.binding,
    required this.record,
    required this.editable,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;
  final bool editable;

  @override
  State<GameBehaviourRepeat> createState() => _GameBehaviourRepeatState();
}

class _GameBehaviourRepeatState extends State<GameBehaviourRepeat> {
  bool _choosing = false;
  int _selectionRevision = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final binding = widget.binding;
    final record = widget.record;
    final current = readBehaviourAfter(record);
    final kept = behaviourRearmOutcome(record);
    final pending = binding.pendingAfter;
    final outcomes = binding.behaviours
        .context(binding.project!, binding.map!)
        .catalog
        .outcomeSources
        .selectableOptions;
    final options = {
      for (final option in outcomes)
        jsonEncode(option.outcome!.toJson()): option,
    };
    final keptKey = kept == null ? '' : jsonEncode(kept.toJson());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: ValueKey(_selectionRevision),
          child: StudioSelect(
            key: const ValueKey('map-story-after'),
            label: l10n.storyAfterField,
            value: current?.name ?? '',
            options: {
              if (current == null) '': l10n.storyReuseUnset,
              BehaviourAfter.once.name: l10n.storyOnce,
              BehaviourAfter.eachTime.name: l10n.storyEachTime,
              BehaviourAfter.oncePerVisit.name: l10n.storyOncePerVisit,
              BehaviourAfter.onceUntilOutcome.name: l10n.storyOnceUntilOutcome,
            },
            onChanged: !widget.editable
                ? null
                : (value) {
                    final after = BehaviourAfter.values.byName(value);
                    setState(() {
                      _selectionRevision++;
                      _choosing =
                          after == BehaviourAfter.onceUntilOutcome &&
                          kept == null;
                    });
                    if (!_choosing) binding.setAfter(record, after);
                  },
          ),
        ),
        if (_choosing || kept != null) ...[
          if (_choosing && kept == null)
            StudioNotice(l10n.triggersOutcomePending),
          const SizedBox(height: StudioSpacing.s),
          StudioSelect(
            key: const ValueKey('story-trigger-rearm-outcome'),
            label: l10n.triggersOutcome,
            value: keptKey,
            options: {
              '': l10n.triggersOutcomeChoose,
              if (kept != null && !options.containsKey(keptKey))
                keptKey: l10n.triggersUnavailable,
              for (final entry in options.entries)
                entry.key:
                    '${entry.value.producerLabel} · ${entry.value.outcomeLabel}',
            },
            onChanged: !widget.editable
                ? null
                : (value) {
                    final selected = options[value]?.outcome;
                    if (selected != null) {
                      binding.setAfter(
                        record,
                        BehaviourAfter.onceUntilOutcome,
                        outcome: selected,
                      );
                    }
                  },
          ),
          if (outcomes.isEmpty) StudioNotice(l10n.triggersNoOutcomes),
          if (kept != null && !options.containsKey(keptKey))
            StudioNotice(l10n.triggersOutcomeUnavailable, isError: true),
        ],
        if (record.parallelPolicy != null) StudioNotice(l10n.triggersParallel),
        if (pending != null)
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('map-story-after-replace'),
              variant: StudioButtonVariant.quiet,
              label: l10n.storyCaseAfterReplace,
              onPressed: widget.editable
                  ? () => binding.setAfter(
                      record,
                      pending,
                      dropOutcomeRearm: true,
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}
