import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/storyline/application/storyline_condition_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_view.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'game_memory_states.dart';
import 'trame_condition_summary.dart';

class TrameConditions extends StatelessWidget {
  const TrameConditions({super.key, required this.trame, required this.at});
  final StorylineTrameController trame;
  final StorylineMilestoneAt at;

  @override
  Widget build(BuildContext context) {
    if (!trame.saved.ready) scheduleMicrotask(trame.ensureStorylines);
    final l10n = context.l10n;
    final state = gameMemoryResourceState(
      context,
      trame.saved,
      loading: l10n.trameJournalLoading,
      onRetry: trame.ensureStorylines,
    );
    if (state != null) return state;
    final step = trame.fullMilestone(
      at.storyline.id,
      at.chapter.id,
      at.milestone.id,
    );
    if (step == null) return StudioNotice(l10n.storyDestinationUnavailable);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in [true, false])
          _TrameCondition(
            trame: trame,
            at: at,
            entry: entry,
            condition: entry ? step.entryCondition : step.completionCondition,
          ),
        Text(
          l10n.trameConditionScopeHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TrameCondition extends StatefulWidget {
  const _TrameCondition({
    required this.trame,
    required this.at,
    required this.entry,
    required this.condition,
  });
  final StorylineTrameController trame;
  final StorylineMilestoneAt at;
  final bool entry;
  final ScriptCondition? condition;

  @override
  State<_TrameCondition> createState() => _TrameConditionState();
}

class _TrameConditionState extends State<_TrameCondition> {
  var _editing = false;

  Future<bool> _set(String? id, {bool expected = true}) =>
      widget.trame.setSimpleCondition(
        widget.at.storyline.id,
        widget.at.chapter.id,
        widget.at.milestone.id,
        entry: widget.entry,
        factId: id,
        expected: expected,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final condition = widget.condition;
    final trame = widget.trame;
    final entry = widget.entry;
    final key = 'trame-condition-${entry ? 'entry' : 'completion'}';
    final factId = condition?.params[ScriptConditionParams.factId];
    final expected = condition?.params[ScriptConditionParams.value] != 'false';
    final editable = trame.staging.editable;
    final simple = editableStorylineCondition(condition);
    return StudioSection(
      key: ValueKey(key),
      title: entry ? l10n.trameEntryConditions : l10n.trameCompletionConditions,
      children: [
        if (condition != null)
          TrameConditionSummary(trame: trame, condition: condition)
        else
          Text(entry ? l10n.trameConditionAlways : l10n.trameConditionNotSet),
        const SizedBox(height: StudioSpacing.s),
        if (!simple)
          Text(
            l10n.trameConditionComplex,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          if (editable)
            StudioButton(
              key: ValueKey('$key-edit'),
              label: _editing
                  ? l10n.trameConditionDone
                  : l10n.trameConditionEdit,
              icon: _editing ? Icons.check : Icons.edit_outlined,
              variant: StudioButtonVariant.quiet,
              onPressed: () => setState(() => _editing = !_editing),
            ),
          if (_editing) ...[
            KeyedSubtree(
              key: ValueKey('$key-fact'),
              child: StudioSelect(
                label: l10n.trameConditionFact,
                value: factId,
                options: {
                  for (final fact in trame.booleanFacts) fact.id: fact.title,
                  if (factId != null &&
                      !trame.booleanFacts.any((fact) => fact.id == factId))
                    factId: l10n.memoryUnknownFact,
                },
                onChanged: editable
                    ? (id) => unawaited(_set(id, expected: expected))
                    : null,
              ),
            ),
            if (condition != null) ...[
              const SizedBox(height: StudioSpacing.s),
              KeyedSubtree(
                key: ValueKey('$key-value'),
                child: StudioSelect(
                  label: l10n.trameConditionExpected,
                  value: '$expected',
                  options: {
                    'true': l10n.trameConditionTrue,
                    'false': l10n.trameConditionFalse,
                  },
                  onChanged: editable
                      ? (value) =>
                            unawaited(_set(factId, expected: value == 'true'))
                      : null,
                ),
              ),
              StudioButton(
                key: ValueKey('$key-remove'),
                label: l10n.trameConditionRemove,
                icon: Icons.remove_circle_outline,
                variant: StudioButtonVariant.quiet,
                onPressed: editable ? () => unawaited(_set(null)) : null,
              ),
            ],
          ],
        ],
      ],
    );
  }
}
