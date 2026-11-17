import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

typedef GameMemoryBehaviourLink = ({
  bool Function(String eventId) available,
  Future<bool> Function(String eventId) open,
});

typedef GameMemoryUsageLink = Future<bool> Function(
  NarrativeOwner owner,
  String factId,
);

class GameMemoryUsages extends StatelessWidget {
  const GameMemoryUsages({
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
    final error = memory.usageErrorFor(factId);
    final usages = memory.usages[factId];
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioNotice(
            error == 'narrativeUsages'
                ? '${l10n.memoryPreparationRequired}. ${l10n.memoryPreparationHint}'
                : l10n.memoryLoadFailed(error),
            isError: true,
          ),
          StudioButton(
            label: l10n.memoryRetry,
            onPressed: () => memory.retryFactUsages(factId),
          ),
        ],
      );
    }
    if (usages == null) {
      return StudioLoadingState(label: l10n.memoryUsagesLoading);
    }
    return Column(
      key: ValueKey('memory-usages-$factId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.memoryUsagesTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: StudioSpacing.s),
        Text(l10n.memoryUsageCount(usages.owners.length)),
        for (final (role, title, nobody) in [
          (
            NarrativeFactRole.write,
            l10n.memoryWrittenBy,
            l10n.memoryNobodyWrites,
          ),
          (NarrativeFactRole.read, l10n.memoryReadBy, l10n.memoryNobodyReads),
          (null, l10n.memoryCitedBy, ''),
        ]) ...[
          if (role != null || usages.owners.any((owner) => owner.role == null))
            StudioSection(
              title: title,
              children: [
                if (usages.owners.where((owner) => owner.role == role).isEmpty)
                  Text(nobody, style: Theme.of(context).textTheme.bodySmall)
                else
                  for (final owner in usages.owners.where(
                    (owner) => owner.role == role,
                  ))
                    _OwnerRow(
                      key: ValueKey(
                        'memory-owner-row-${owner.kind.name}-${owner.id}-${owner.role}',
                      ),
                      owner: owner,
                      memory: memory,
                      behaviours: behaviours,
                      openUsage: openUsage,
                      factId: factId,
                    ),
                if (role == null)
                  Text(
                    l10n.memoryCitedHint,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _OwnerRow extends StatefulWidget {
  const _OwnerRow({
    super.key,
    required this.owner,
    required this.memory,
    required this.behaviours,
    required this.factId,
    this.openUsage,
  });

  final NarrativeOwner owner;
  final GameMemoryController memory;
  final GameMemoryBehaviourLink behaviours;
  final String factId;
  final GameMemoryUsageLink? openUsage;

  @override
  State<_OwnerRow> createState() => _OwnerRowState();
}

class _OwnerRowState extends State<_OwnerRow> {
  bool _opening = false;
  bool _unavailable = false;

  Future<void> _open() async {
    setState(() {
      _opening = true;
      _unavailable = false;
    });
    var opened = false;
    try {
      opened = await widget.openUsage!(widget.owner, widget.factId);
    } on Object {
      opened = false;
    }
    if (mounted) {
      setState(() {
        _opening = false;
        _unavailable = !opened;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final owner = widget.owner;
    final memory = widget.memory;
    final behaviours = widget.behaviours;
    final name = memory.ownerName(owner);
    final VoidCallback? open = _opening
        ? null
        : widget.openUsage != null && owner.kind != NarrativeOwnerKind.cinematic
        ? () => unawaited(_open())
        : switch (owner.kind) {
            NarrativeOwnerKind.event when behaviours.available(owner.id) => () {
              unawaited(behaviours.open(owner.id));
            },
            NarrativeOwnerKind.worldRule => () => memory.rules.select(owner.id),
            _ => null,
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioChoice(
          key: ValueKey('memory-owner-${owner.kind.name}-${owner.id}'),
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
        ),
        if (_unavailable)
          StudioNotice(l10n.storyDestinationUnavailable, isError: true),
      ],
    );
  }
}
