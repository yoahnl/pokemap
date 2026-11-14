import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

typedef GameMemoryBehaviourLink = ({
  bool Function(String eventId) available,
  void Function(String eventId) open,
});

class GameMemoryUsages extends StatelessWidget {
  const GameMemoryUsages({
    super.key,
    required this.memory,
    required this.factId,
    required this.behaviours,
  });

  final GameMemoryController memory;
  final String factId;
  final GameMemoryBehaviourLink behaviours;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = memory.usagesError;
    final usages = memory.usages[factId];
    if (error != null) {
      return StudioNotice(
        error == 'narrativeUsages'
            ? '${l10n.memoryPreparationRequired}. ${l10n.memoryPreparationHint}'
            : l10n.memoryLoadFailed(error),
        isError: true,
      );
    }
    if (usages == null) {
      return StudioLoadingState(label: l10n.memoryUsagesLoading);
    }
    return Column(
      key: ValueKey('memory-usages-$factId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (role, title, nobody) in [
          (
            NarrativeFactRole.write,
            l10n.memoryWrittenBy,
            l10n.memoryNobodyWrites,
          ),
          (NarrativeFactRole.read, l10n.memoryReadBy, l10n.memoryNobodyReads),
        ]) ...[
          StudioSection(
            title: title,
            children: [
              if (usages.withRole(role).isEmpty)
                Text(nobody, style: Theme.of(context).textTheme.bodySmall)
              else
                for (final owner in usages.withRole(role))
                  _OwnerRow(
                    owner: owner,
                    memory: memory,
                    behaviours: behaviours,
                  ),
            ],
          ),
        ],
        if (usages.notCovered.isNotEmpty)
          StudioNotice(l10n.memoryCoverage(usages.notCovered)),
      ],
    );
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({
    required this.owner,
    required this.memory,
    required this.behaviours,
  });

  final NarrativeOwner owner;
  final GameMemoryController memory;
  final GameMemoryBehaviourLink behaviours;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = memory.names.name(owner.kind.titles, owner.id);
    final open = switch (owner.kind) {
      NarrativeOwnerKind.event when behaviours.available(owner.id) =>
        () => behaviours.open(owner.id),
      NarrativeOwnerKind.worldRule => () => memory.rules.select(owner.id),
      _ => null,
    };
    return StudioChoice(
      key: ValueKey('memory-owner-${owner.kind.name}-${owner.id}'),
      dense: true,
      label: l10n.memoryOwner(owner, name),
      subtitle: l10n.memoryOwnerKind(owner.kind.name),
      trailing: open == null
          ? null
          : IconButton(
              key: ValueKey('memory-open-${owner.kind.name}-${owner.id}'),
              tooltip: l10n.memoryOpen,
              iconSize: 16,
              onPressed: open,
              icon: const Icon(Icons.open_in_new),
            ),
      onTap: open,
    );
  }
}
