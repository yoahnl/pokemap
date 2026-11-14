import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_usages.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameMemoryFactDetail extends StatefulWidget {
  const GameMemoryFactDetail({
    super.key,
    required this.memory,
    required this.factId,
    required this.behaviours,
  });

  final GameMemoryController memory;
  final String factId;
  final GameMemoryBehaviourLink behaviours;

  @override
  State<GameMemoryFactDetail> createState() => _GameMemoryFactDetailState();
}

class _GameMemoryFactDetailState extends State<GameMemoryFactDetail> {
  var _deleteRefused = false;

  @override
  void didUpdateWidget(GameMemoryFactDetail old) {
    super.didUpdateWidget(old);
    if (old.factId != widget.factId) _deleteRefused = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final memory = widget.memory;
    final fact = memory.current(widget.factId);
    if (fact == null) {
      return memory.detailsError == null
          ? StudioLoadingState(label: l10n.memoryFactsLoading)
          : StudioNotice(
              l10n.memoryLoadFailed('${memory.detailsError}'),
              isError: true,
            );
    }
    final created =
        memory.staging.draft
            .entryOf(StoryDraftKind.fact, widget.factId)
            ?.creation ??
        false;
    final editable = memory.staging.editable;
    return ListView(
      key: ValueKey('memory-fact-detail-${widget.factId}'),
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        MapBuilderNameField(
          key: ValueKey('memory-fact-name-${widget.factId}'),
          value: fact.label,
          label: l10n.memoryFactName,
          enabled: editable,
          onCommit: (label) => memory.renameFact(widget.factId, label),
        ),
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
        const SizedBox(height: StudioSpacing.l),
        Align(
          alignment: Alignment.centerLeft,
          child: created
              ? StudioButton(
                  key: const ValueKey('memory-fact-discard'),
                  label: l10n.memoryDiscard,
                  icon: Icons.undo,
                  variant: StudioButtonVariant.secondary,
                  onPressed: editable
                      ? () => memory.discardCreated(widget.factId)
                      : null,
                )
              : StudioButton(
                  key: const ValueKey('memory-fact-delete'),
                  label: l10n.memoryDelete,
                  icon: Icons.delete_outline,
                  variant: StudioButtonVariant.destructive,
                  onPressed: () => setState(() => _deleteRefused = true),
                ),
        ),
        if (_deleteRefused) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(
            key: const ValueKey('memory-fact-delete-refused'),
            l10n.memoryDeleteRefused,
            isError: true,
          ),
        ],
        const SizedBox(height: StudioSpacing.l),
        if (created)
          Text(l10n.memoryCreatedUnused, style: theme.textTheme.bodySmall)
        else
          GameMemoryUsages(
            memory: memory,
            factId: widget.factId,
            behaviours: widget.behaviours,
          ),
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
