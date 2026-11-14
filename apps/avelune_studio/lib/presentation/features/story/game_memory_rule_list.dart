import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_rules.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameMemoryRuleList extends StatelessWidget {
  const GameMemoryRuleList({
    super.key,
    required this.memory,
    required this.onCreate,
  });

  final GameMemoryController memory;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rules = memory.rules;
    final create = StudioButton(
      key: const ValueKey('memory-new-rule'),
      label: l10n.memoryNewRule,
      icon: Icons.add,
      variant: StudioButtonVariant.secondary,
      onPressed: onCreate,
    );
    final state = gameMemoryResourceState(
      context,
      rules.saved,
      loading: l10n.memoryRulesLoading,
      onRetry: rules.retry,
    );
    final rows = rules.rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.l),
          child: Align(alignment: Alignment.centerLeft, child: create),
        ),
        Expanded(
          child:
              state ??
              (rows.isEmpty
                  ? StudioEmptyState(
                      key: const ValueKey('memory-rules-empty'),
                      icon: Icons.rule,
                      title: l10n.memoryRulesEmpty,
                      description: onCreate == null
                          ? l10n.memoryRuleNeedsFact
                          : l10n.memoryRulesEmptyHint,
                    )
                  : ListView.builder(
                      key: const ValueKey('memory-rule-list'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: StudioSpacing.l,
                      ),
                      itemCount: rows.length,
                      itemBuilder: (context, index) =>
                          _row(context, rows[index]),
                    )),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, GameMemoryRuleRow row) {
    final l10n = context.l10n;
    final rule = row.rule;
    return StudioChoice(
      key: ValueKey('memory-rule-${rule.id}'),
      label: rule.label,
      subtitle: l10n.memoryRuleText(memory.rules.sentence(rule)),
      selected: memory.rules.selected == rule.id,
      trailing: row.unsaved
          ? StudioBadge(l10n.memoryUnsaved)
          : rule.enabled
          ? null
          : StudioBadge(l10n.memoryRuleDisabled),
      onTap: () => memory.rules.select(rule.id),
    );
  }
}
