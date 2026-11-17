import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_usages.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameMemoryFactDetail extends StatelessWidget {
  const GameMemoryFactDetail({
    super.key,
    required this.memory,
    required this.factId,
    required this.behaviours,
    this.openUsage,
  });

  final GameMemoryController memory;
  final String factId;
  final GameMemoryBehaviourLink behaviours;
  final GameMemoryUsageLink? openUsage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fact = memory.current(factId);
    if (fact == null) {
      return memory.detailsError == null
          ? StudioLoadingState(label: l10n.memoryFactsLoading)
          : StudioNotice(
              l10n.memoryLoadFailed('${memory.detailsError}'),
              isError: true,
            );
    }
    final created =
        memory.staging.draft.entryOf(StoryDraftKind.fact, factId)?.creation ??
        false;
    final editable = memory.staging.editable;
    return ListView(
      key: ValueKey('memory-fact-detail-$factId'),
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        MapBuilderNameField(
          key: ValueKey('memory-fact-name-$factId'),
          value: fact.label,
          label: l10n.memoryFactName,
          enabled: editable && !created,
          onSubmit: (label) async => memory.renameFact(factId, label),
        ),
        if (created) ...[
          const SizedBox(height: StudioSpacing.s),
          Text(l10n.memoryCreatedNameLocked, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: StudioSpacing.l),
        Row(
          children: [
            Expanded(
              child: _Value(
                l10n.memoryFactKind,
                l10n.memoryKind(fact.valueKind),
              ),
            ),
            Expanded(
              child: _Value(
                l10n.memoryFactStart,
                l10n.memoryValue(fact.initialValue),
              ),
            ),
          ],
        ),
        Text(
          l10n.memoryKindLocked,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StudioSpacing.s),
        Text(l10n.memorySimulationHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: StudioSpacing.l),
        if (created)
          Text(l10n.memoryCreatedUnused, style: theme.textTheme.bodySmall),
        GameMemoryUsages(
          memory: memory,
          factId: factId,
          behaviours: behaviours,
          openUsage: openUsage,
        ),
        const SizedBox(height: StudioSpacing.l),
        Align(
          alignment: Alignment.centerLeft,
          child: created
              ? StudioButton(
                  key: const ValueKey('memory-fact-discard'),
                  label: l10n.memoryDiscard,
                  icon: Icons.undo,
                  variant: StudioButtonVariant.secondary,
                  onPressed: memory.canDiscardCreated(factId)
                      ? () => memory.discardCreated(factId)
                      : null,
                )
              : StudioButton(
                  key: const ValueKey('memory-fact-delete'),
                  label: l10n.memoryDelete,
                  icon: Icons.delete_outline,
                  variant: StudioButtonVariant.destructive,
                  onPressed: null,
                ),
        ),
        if (!created || !memory.canDiscardCreated(factId)) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(
            key: ValueKey(
              created
                  ? 'memory-fact-discard-refused'
                  : 'memory-fact-delete-refused',
            ),
            created ? l10n.memoryDiscardInUse : l10n.memoryDeleteRefused,
          ),
        ],
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StudioSpacing.xxs),
        Text(value, style: theme.textTheme.bodyMedium),
        const SizedBox(height: StudioSpacing.s),
      ],
    );
  }
}
