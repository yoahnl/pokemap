import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_conditions.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_conditions_picker.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderStoryConditions extends StatefulWidget {
  const MapBuilderStoryConditions({
    super.key,
    required this.binding,
    required this.record,
    required this.editable,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;
  final bool editable;

  @override
  State<MapBuilderStoryConditions> createState() =>
      _MapBuilderStoryConditionsState();
}

class _MapBuilderStoryConditionsState extends State<MapBuilderStoryConditions> {
  int? _picking;

  MapBuilderStoryBinding get _binding => widget.binding;

  NarrativeValueKind _kindOf(BehaviourEditableCondition condition) =>
      _binding.conditionFact(condition.factId)?.initialValue.kind ??
      (condition.test == BehaviourConditionTest.equalsNumber
          ? NarrativeValueKind.integer
          : NarrativeValueKind.boolean);

  BehaviourEditableCondition _on(
    NarrativeFactDefinition fact, [
    BehaviourEditableCondition? previous,
  ]) => switch (fact.initialValue.kind) {
    NarrativeValueKind.integer => BehaviourEditableCondition.equalsNumber(
      fact.id,
      previous?.number ?? 0,
    ),
    _ when previous?.test == BehaviourConditionTest.isFalse =>
      BehaviourEditableCondition.isFalse(fact.id),
    _ => BehaviourEditableCondition.isTrue(fact.id),
  };

  BehaviourEditableCondition _with(
    BehaviourEditableCondition condition,
    BehaviourConditionTest test, [
    int? number,
  ]) => switch (test) {
    BehaviourConditionTest.isTrue => BehaviourEditableCondition.isTrue(
      condition.factId,
    ),
    BehaviourConditionTest.isFalse => BehaviourEditableCondition.isFalse(
      condition.factId,
    ),
    BehaviourConditionTest.equalsNumber =>
      BehaviourEditableCondition.equalsNumber(
        condition.factId,
        number ?? condition.number ?? 0,
      ),
  };

  void _pick(BehaviourConditions conditions, NarrativeFactDefinition fact) {
    final index = _picking!;
    setState(() => _picking = null);
    if (index >= conditions.items.length) {
      _binding.setConditions(widget.record, conditions.adding(_on(fact)));
      return;
    }
    final previous = conditions.items[index] as BehaviourEditableCondition;
    _binding.setConditions(
      widget.record,
      conditions.replacing(index, _on(fact, previous)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final conditions = _binding.conditionsOf(widget.record);
    final editable = widget.editable;
    final picking = _picking;
    return Column(
      key: const ValueKey('map-story-if'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (conditions.items.isEmpty) Text(l10n.storyAlways, style: muted),
        for (final (index, item) in conditions.items.indexed) ...[
          if (index > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xxs),
              child: Text(l10n.storyConditionAnd, style: muted),
            ),
          switch (item) {
            final BehaviourEditableCondition condition => _Row(
              key: ValueKey('map-story-condition-$index'),
              condition: condition,
              fact: _binding.conditionFact(condition.factId),
              tests: behaviourConditionTests(_kindOf(condition)),
              enabled: editable,
              onFact: () => setState(() => _picking = index),
              onTest: (test) => _binding.setConditions(
                widget.record,
                conditions.replacing(index, _with(condition, test)),
              ),
              onNumber: (number) => _binding.setConditions(
                widget.record,
                conditions.replacing(
                  index,
                  _with(condition, BehaviourConditionTest.equalsNumber, number),
                ),
              ),
              onRemove: () => _binding.setConditions(
                widget.record,
                conditions.removing(index),
              ),
            ),
            BehaviourFixedCondition() => Text(
              l10n.storyConditionFixed,
              key: ValueKey('map-story-condition-fixed-$index'),
              style: theme.textTheme.bodyMedium,
            ),
          },
        ],
        const SizedBox(height: StudioSpacing.xs),
        if (picking != null)
          MapBuilderStoryFactPicker(
            facts: _binding.conditionFacts,
            onPick: (fact) => _pick(conditions, fact),
            onClose: () => setState(() => _picking = null),
            onCreate: picking < conditions.items.length
                ? null
                : (label, kind) {
                    setState(() => _picking = null);
                    _binding.addConditionOnNewFact(widget.record, label, kind);
                  },
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('map-story-condition-add'),
              variant: StudioButtonVariant.quiet,
              icon: Icons.add,
              label: l10n.storyConditionAdd,
              onPressed: editable
                  ? () => setState(() => _picking = conditions.items.length)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.condition,
    required this.fact,
    required this.tests,
    required this.enabled,
    required this.onFact,
    required this.onTest,
    required this.onNumber,
    required this.onRemove,
  });

  final BehaviourEditableCondition condition;
  final NarrativeFactDefinition? fact;
  final List<BehaviourConditionTest> tests;
  final bool enabled;
  final VoidCallback onFact;
  final ValueChanged<BehaviourConditionTest> onTest;
  final ValueChanged<int> onNumber;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final number = condition.number;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioChoice(
          key: const ValueKey('map-story-condition-fact'),
          dense: true,
          label: fact?.label ?? condition.factId,
          subtitle: l10n.storyConditionChooseFact,
          onTap: enabled ? onFact : null,
        ),
        Row(
          children: [
            Expanded(
              child: StudioSelect(
                key: const ValueKey('map-story-condition-test'),
                label: fact?.label ?? condition.factId,
                value: condition.test.name,
                options: {
                  for (final test in {...tests, condition.test})
                    test.name: l10n.storyConditionTest(test.name),
                },
                onChanged: enabled
                    ? (value) =>
                          onTest(BehaviourConditionTest.values.byName(value))
                    : null,
              ),
            ),
            if (number != null) ...[
              const SizedBox(width: StudioSpacing.s),
              SizedBox(
                width: 72,
                child: MapBuilderNameField(
                  key: const ValueKey('map-story-condition-number'),
                  value: '$number',
                  label: l10n.storyConditionNumber,
                  enabled: enabled,
                  onCommit: (text) => switch (int.tryParse(text.trim())) {
                    final value? => onNumber(value),
                    null => null,
                  },
                ),
              ),
            ],
            IconButton(
              key: const ValueKey('map-story-condition-remove'),
              tooltip: l10n.storyConditionRemove,
              icon: const Icon(Icons.close, size: 16),
              onPressed: enabled ? onRemove : null,
            ),
          ],
        ),
      ],
    );
  }
}
