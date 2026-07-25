import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';

/// Responsive PC surface driven by runtime-owned boxes and transfer targets.
class PlayerPcOverlay extends StatelessWidget {
  const PlayerPcOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final content = snapshot.content;
    if (content is! RuntimePcServiceContent) {
      return _InvalidPcOverlay(
        onClose: () => _emit(RuntimeWorldServiceAction.close),
      );
    }
    final applying = snapshot.stage == RuntimeWorldServiceStage.applying;
    final canSelect =
        snapshot.isActionEnabled(RuntimeWorldServiceAction.select);
    final canClose = snapshot.isActionEnabled(RuntimeWorldServiceAction.close);

    return ColoredBox(
      color: context.playerColors.scrim,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            return Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(PlayerSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: PlayerPanel(
                    elevated: true,
                    padding: const EdgeInsets.all(PlayerSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.dns_outlined,
                              color: context.playerColors.primary,
                            ),
                            const SizedBox(width: PlayerSpacing.sm),
                            Expanded(
                              child: Text(
                                content.title,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            IconButton(
                              key: const ValueKey<String>('pc-close'),
                              tooltip: 'Fermer',
                              onPressed: canClose
                                  ? () => _emit(
                                        RuntimeWorldServiceAction.close,
                                      )
                                  : null,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: PlayerSpacing.xs),
                        Text(content.message),
                        const SizedBox(height: PlayerSpacing.md),
                        DropdownButtonFormField<String>(
                          key: const ValueKey<String>('pc-box-picker'),
                          initialValue: content.selectedBoxId,
                          decoration: const InputDecoration(labelText: 'Box'),
                          items: content.boxes
                              .map(
                                (box) => DropdownMenuItem<String>(
                                  value: box.boxId,
                                  child: Text(
                                    '${box.label} · '
                                    '${box.count}/${box.capacity}',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: canSelect
                              ? (boxId) {
                                  if (boxId != null) {
                                    _emit(
                                      RuntimeWorldServiceAction.select,
                                      targetId: boxId,
                                    );
                                  }
                                }
                              : null,
                        ),
                        if (applying) ...<Widget>[
                          const SizedBox(height: PlayerSpacing.md),
                          const LinearProgressIndicator(),
                        ],
                        const SizedBox(height: PlayerSpacing.md),
                        if (compact)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _PcRoster(
                                title: 'Équipe',
                                emptyMessage: 'Votre équipe est vide.',
                                entries: content.party,
                                action: RuntimeWorldServiceAction.deposit,
                                actionLabel: 'Déposer',
                                actionIcon: Icons.move_to_inbox_outlined,
                                snapshot: snapshot,
                                onCommand: onCommand,
                              ),
                              const SizedBox(height: PlayerSpacing.md),
                              _PcRoster(
                                title: _selectedBoxLabel(content),
                                emptyMessage: 'Cette box est vide.',
                                entries: content.stored,
                                action: RuntimeWorldServiceAction.withdraw,
                                actionLabel: 'Retirer',
                                actionIcon: Icons.person_add_alt_1_outlined,
                                snapshot: snapshot,
                                onCommand: onCommand,
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _PcRoster(
                                  title: 'Équipe',
                                  emptyMessage: 'Votre équipe est vide.',
                                  entries: content.party,
                                  action: RuntimeWorldServiceAction.deposit,
                                  actionLabel: 'Déposer',
                                  actionIcon: Icons.move_to_inbox_outlined,
                                  snapshot: snapshot,
                                  onCommand: onCommand,
                                ),
                              ),
                              const SizedBox(width: PlayerSpacing.md),
                              Expanded(
                                child: _PcRoster(
                                  title: _selectedBoxLabel(content),
                                  emptyMessage: 'Cette box est vide.',
                                  entries: content.stored,
                                  action: RuntimeWorldServiceAction.withdraw,
                                  actionLabel: 'Retirer',
                                  actionIcon: Icons.person_add_alt_1_outlined,
                                  snapshot: snapshot,
                                  onCommand: onCommand,
                                ),
                              ),
                            ],
                          ),
                        if (snapshot.safeMessage case final message?
                            when message.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: PlayerSpacing.md),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _selectedBoxLabel(RuntimePcServiceContent content) {
    for (final box in content.boxes) {
      if (box.boxId == content.selectedBoxId) return box.label;
    }
    return 'Box';
  }

  void _emit(RuntimeWorldServiceAction action, {String? targetId}) {
    onCommand(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: snapshot.revision,
        targetId: targetId,
      ),
    );
  }
}

class _PcRoster extends StatelessWidget {
  const _PcRoster({
    required this.title,
    required this.emptyMessage,
    required this.entries,
    required this.action,
    required this.actionLabel,
    required this.actionIcon,
    required this.snapshot,
    required this.onCommand,
  });

  final String title;
  final String emptyMessage;
  final List<RuntimePcPokemonSnapshot> entries;
  final RuntimeWorldServiceAction action;
  final String actionLabel;
  final IconData actionIcon;
  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  Widget build(BuildContext context) => PlayerPanel(
        padding: const EdgeInsets.all(PlayerSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: PlayerSpacing.sm),
            if (entries.isEmpty)
              PlayerEmptyState(
                icon: Icons.catching_pokemon,
                title: 'Aucun Pokémon',
                message: emptyMessage,
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: PlayerSpacing.xs),
                  child: PlayerPanel(
                    padding: const EdgeInsets.all(PlayerSpacing.sm),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.label,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text('Niv. ${entry.level}'),
                            ],
                          ),
                        ),
                        const SizedBox(width: PlayerSpacing.xs),
                        IconButton.filledTonal(
                          key: ValueKey<String>(
                            'pc-${action.name}-${entry.targetId}',
                          ),
                          tooltip: entry.canTransfer
                              ? actionLabel
                              : entry.unavailableReason,
                          onPressed: entry.canTransfer &&
                                  snapshot.isActionEnabled(action)
                              ? () => onCommand(
                                    RuntimeWorldServiceCommand(
                                      action: action,
                                      snapshotRevision: snapshot.revision,
                                      targetId: entry.targetId,
                                    ),
                                  )
                              : null,
                          icon: Icon(actionIcon),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      );
}

class _InvalidPcOverlay extends StatelessWidget {
  const _InvalidPcOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.playerColors.scrim,
        child: Center(
          child: PlayerPanel(
            elevated: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Le PC ne peut pas être affiché.'),
                const SizedBox(height: PlayerSpacing.md),
                PlayerActionButton(
                  label: 'Fermer',
                  icon: Icons.close,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      );
}
