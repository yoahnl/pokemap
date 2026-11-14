import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_condition_fields.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

const gameMemoryEditableEffects = {
  WorldRuleEffectKind.entityVisible,
  WorldRuleEffectKind.entityHidden,
  WorldRuleEffectKind.eventEnabled,
  WorldRuleEffectKind.eventDisabled,
  WorldRuleEffectKind.eventHidden,
};

class GameMemoryRuleEditor extends StatelessWidget {
  const GameMemoryRuleEditor({
    super.key,
    required this.memory,
    required this.rule,
  });

  final GameMemoryController memory;
  final WorldRuleDefinition rule;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rules = memory.rules;
    final editable = memory.staging.editable;
    final source = rule.source;
    final effects = [
      for (final effect in gameMemoryEditableEffects)
        if (isWorldRuleEffectCompatibleWithTarget(rule.target.kind, effect))
          effect,
    ];
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ListView(
      key: ValueKey('memory-rule-editor-${rule.id}'),
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        MapBuilderNameField(
          key: ValueKey('memory-rule-name-${rule.id}'),
          value: rule.label,
          label: l10n.memoryRuleName,
          enabled: editable,
          onCommit: (label) => rules.update(rule.id, label: label),
        ),
        const SizedBox(height: StudioSpacing.l),
        Text(
          l10n.memoryRuleText(rules.sentence(rule)),
          key: const ValueKey('memory-rule-sentence'),
          style: theme.textTheme.titleSmall,
        ),
        StudioToggleRow(
          key: const ValueKey('memory-rule-enabled'),
          label: l10n.memoryRuleActive,
          value: rule.enabled,
          onChanged: editable
              ? (value) => rules.update(rule.id, enabled: value)
              : null,
        ),
        StudioSection(
          title: l10n.memoryRuleWhile,
          children: [
            if (source.kind == WorldRuleSourceKind.fact)
              GameMemoryConditionFields(
                key: ValueKey('memory-rule-condition-${rule.id}'),
                memory: memory,
                enabled: editable,
                condition: (
                  factId: source.sourceId,
                  operator: source.resolvedFactOperator,
                  value: source.resolvedExpectedFactValue,
                ),
                onChanged: (condition) =>
                    rules.update(rule.id, condition: condition),
              )
            else
              Text(l10n.memoryRuleConditionLocked, style: muted),
          ],
        ),
        StudioSection(
          title: l10n.memoryRuleThen,
          children: [
            if (effects.contains(rule.effect.kind))
              KeyedSubtree(
                key: const ValueKey('memory-rule-effect'),
                child: StudioSelect(
                  label: l10n.memoryRuleEffect,
                  value: rule.effect.kind.name,
                  options: {
                    for (final effect in effects)
                      effect.name: l10n.memoryEffectKind(effect.name),
                  },
                  onChanged: editable
                      ? (name) => rules.update(
                          rule.id,
                          effect: WorldRuleEffectKind.values.byName(name),
                        )
                      : null,
                ),
              ),
            const SizedBox(height: StudioSpacing.s),
            Text(l10n.memoryRuleTargetLocked, style: muted),
          ],
        ),
      ],
    );
  }
}
