import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_rules.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameMemoryConditionFields extends StatelessWidget {
  const GameMemoryConditionFields({
    super.key,
    required this.memory,
    required this.condition,
    required this.onChanged,
    required this.enabled,
  });

  final GameMemoryController memory;
  final GameMemoryRuleCondition? condition;
  final ValueChanged<GameMemoryRuleCondition> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final condition = this.condition;
    final fact = condition == null ? null : memory.current(condition.factId);
    if (condition != null && fact == null) memory.reveal(condition.factId);
    final kind = fact?.valueKind;
    final value = condition?.value;
    final fits = value != null && value.kind == kind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: const ValueKey('memory-rule-fact'),
          child: StudioSelect(
            label: l10n.memoryRuleFact,
            value: condition?.factId,
            options: {for (final row in memory.allFacts) row.id: row.label},
            onChanged: enabled
                ? (id) {
                    memory.reveal(id);
                    onChanged((
                      factId: id,
                      operator: NarrativeFactOperator.equals,
                      value:
                          memory.current(id)?.valueKind ==
                              NarrativeValueKind.integer
                          ? NarrativeValue.integer(0)
                          : const NarrativeValue.boolean(true),
                    ));
                  }
                : null,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        if (condition == null)
          const SizedBox.shrink()
        else if (kind == null)
          StudioLoadingState(label: l10n.memoryFactsLoading)
        else if (kind == NarrativeValueKind.integer)
          Row(
            children: [
              Expanded(
                child: KeyedSubtree(
                  key: const ValueKey('memory-rule-operator'),
                  child: StudioSelect(
                    label: l10n.memoryRuleComparison,
                    value: fits ? condition.operator.name : null,
                    options: {
                      for (final operator in NarrativeFactOperator.values)
                        operator.name: l10n.memoryOperator(operator.name),
                    },
                    onChanged: enabled
                        ? (name) => onChanged((
                            factId: condition.factId,
                            operator: NarrativeFactOperator.values.byName(name),
                            value: fits ? value : NarrativeValue.integer(0),
                          ))
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: StudioSpacing.m),
              SizedBox(
                width: 96,
                child: MapBuilderNameField(
                  key: const ValueKey('memory-rule-value'),
                  value: fits ? '${value.intValue}' : '0',
                  label: l10n.memoryRuleValue,
                  enabled: enabled,
                  onCommit: (text) => switch (int.tryParse(text.trim())) {
                    final number? => onChanged((
                      factId: condition.factId,
                      operator: fits
                          ? condition.operator
                          : NarrativeFactOperator.equals,
                      value: NarrativeValue.integer(number),
                    )),
                    null => null,
                  },
                ),
              ),
            ],
          )
        else
          KeyedSubtree(
            key: const ValueKey('memory-rule-boolean'),
            child: StudioSelect(
              label: l10n.memoryRuleComparison,
              value: fits
                  ? '${value.boolValue == (condition.operator == NarrativeFactOperator.equals)}'
                  : null,
              options: {
                for (final test in const ['true', 'false'])
                  test: l10n.memoryBooleanTest(test),
              },
              onChanged: enabled
                  ? (test) => onChanged((
                      factId: condition.factId,
                      operator: NarrativeFactOperator.equals,
                      value: NarrativeValue.boolean(test == 'true'),
                    ))
                  : null,
            ),
          ),
      ],
    );
  }
}
