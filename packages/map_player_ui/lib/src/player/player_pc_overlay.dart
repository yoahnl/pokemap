import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_pc_strings.dart';

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
    final strings = PlayerPcStrings.of(context);
    final content = snapshot.content;
    if (content is! RuntimePcServiceContent) {
      return _InvalidPcOverlay(
        strings: strings,
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
                              tooltip: strings.close,
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
                          isExpanded: true,
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
                                title: strings.party,
                                emptyMessage: strings.emptyParty,
                                emptyTitle: strings.emptyPokemon,
                                entries: content.party,
                                action: RuntimeWorldServiceAction.deposit,
                                actionLabel: strings.deposit,
                                actionIcon: Icons.move_to_inbox_outlined,
                                snapshot: snapshot,
                                onCommand: onCommand,
                              ),
                              const SizedBox(height: PlayerSpacing.md),
                              _PcRoster(
                                title: _selectedBoxLabel(content),
                                emptyMessage: strings.emptyBox,
                                emptyTitle: strings.emptyPokemon,
                                entries: content.stored,
                                action: RuntimeWorldServiceAction.withdraw,
                                actionLabel: strings.withdraw,
                                actionIcon: Icons.person_add_alt_1_outlined,
                                snapshot: snapshot,
                                onCommand: onCommand,
                                swapCandidates: content.party,
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _PcRoster(
                                  title: strings.party,
                                  emptyMessage: strings.emptyParty,
                                  emptyTitle: strings.emptyPokemon,
                                  entries: content.party,
                                  action: RuntimeWorldServiceAction.deposit,
                                  actionLabel: strings.deposit,
                                  actionIcon: Icons.move_to_inbox_outlined,
                                  snapshot: snapshot,
                                  onCommand: onCommand,
                                ),
                              ),
                              const SizedBox(width: PlayerSpacing.md),
                              Expanded(
                                child: _PcRoster(
                                  title: _selectedBoxLabel(content),
                                  emptyMessage: strings.emptyBox,
                                  emptyTitle: strings.emptyPokemon,
                                  entries: content.stored,
                                  action: RuntimeWorldServiceAction.withdraw,
                                  actionLabel: strings.withdraw,
                                  actionIcon: Icons.person_add_alt_1_outlined,
                                  snapshot: snapshot,
                                  onCommand: onCommand,
                                  swapCandidates: content.party,
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
    required this.emptyTitle,
    required this.entries,
    required this.action,
    required this.actionLabel,
    required this.actionIcon,
    required this.snapshot,
    required this.onCommand,
    this.swapCandidates = const <RuntimePcPokemonSnapshot>[],
  });

  final String title;
  final String emptyMessage;
  final String emptyTitle;
  final List<RuntimePcPokemonSnapshot> entries;
  final RuntimeWorldServiceAction action;
  final String actionLabel;
  final IconData actionIcon;
  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;
  final List<RuntimePcPokemonSnapshot> swapCandidates;

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
                title: emptyTitle,
                message: emptyMessage,
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: PlayerSpacing.xs),
                  child: PlayerPanel(
                    padding: const EdgeInsets.all(PlayerSpacing.sm),
                    child: _buildEntry(context, entry),
                  ),
                ),
          ],
        ),
      );

  Widget _buildEntry(
    BuildContext context,
    RuntimePcPokemonSnapshot entry,
  ) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          entry.label,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(PlayerPcStrings.of(context).levelValue(entry.level)),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          key: ValueKey<String>('pc-summary-${entry.targetId}'),
          tooltip: PlayerPcStrings.of(context).summaryTooltip,
          onPressed: () => _showSummary(context, entry),
          icon: const Icon(Icons.info_outline),
        ),
        if (swapCandidates.isNotEmpty)
          PopupMenuButton<String>(
            key: ValueKey<String>('pc-swap-${entry.targetId}'),
            tooltip: PlayerPcStrings.of(context).swapTooltip,
            enabled: snapshot.isActionEnabled(
              RuntimeWorldServiceAction.swap,
            ),
            onSelected: (partyTargetId) => onCommand(
              RuntimeWorldServiceCommand(
                action: RuntimeWorldServiceAction.swap,
                snapshotRevision: snapshot.revision,
                targetId: entry.targetId,
                secondaryTargetId: partyTargetId,
              ),
            ),
            itemBuilder: (context) => swapCandidates
                .map(
                  (candidate) => PopupMenuItem<String>(
                    key: ValueKey<String>(
                      'pc-swap-with-${candidate.targetId}',
                    ),
                    value: candidate.targetId,
                    child: Text(
                      PlayerPcStrings.of(context).swapWith(candidate.label),
                    ),
                  ),
                )
                .toList(growable: false),
            icon: const Icon(Icons.swap_horiz),
          ),
        IconButton.filledTonal(
          key: ValueKey<String>('pc-${action.name}-${entry.targetId}'),
          tooltip: entry.canTransfer ? actionLabel : entry.unavailableReason,
          onPressed: entry.canTransfer && snapshot.isActionEnabled(action)
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
    );
    final useVerticalLayout = MediaQuery.textScalerOf(context).scale(16) > 22;
    if (useVerticalLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          details,
          const SizedBox(height: PlayerSpacing.xs),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: details),
        const SizedBox(width: PlayerSpacing.xs),
        actions,
      ],
    );
  }

  void _showSummary(
    BuildContext context,
    RuntimePcPokemonSnapshot entry,
  ) {
    final strings = PlayerPcStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        final availableHeight = MediaQuery.sizeOf(context).height - 32;
        return Dialog(
          insetPadding: const EdgeInsets.all(PlayerSpacing.md),
          child: SizedBox(
            width: 520,
            height: availableHeight.clamp(240, 640).toDouble(),
            child: PlayerPanel(
              elevated: true,
              padding: const EdgeInsets.all(PlayerSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            strings.summaryTitle(entry.label),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: PlayerSpacing.md),
                          _SummaryLine(
                            label: strings.species,
                            value: _humanize(entry.speciesId),
                          ),
                          if (entry.nickname.isNotEmpty)
                            _SummaryLine(
                              label: strings.nickname,
                              value: entry.nickname,
                            ),
                          _SummaryLine(
                            label: strings.level,
                            value: '${entry.level}',
                          ),
                          _SummaryLine(
                            label: strings.currentHp,
                            value: '${entry.currentHp}',
                          ),
                          _SummaryLine(
                            label: strings.nature,
                            value: _humanize(entry.natureId),
                          ),
                          _SummaryLine(
                            label: strings.ability,
                            value: _humanize(entry.abilityId),
                          ),
                          if (entry.gender case final gender?)
                            _SummaryLine(
                              label: strings.gender,
                              value: _humanize(gender),
                            ),
                          _SummaryLine(
                            label: strings.status,
                            value: entry.statusId.isEmpty
                                ? strings.none
                                : _humanize(entry.statusId),
                          ),
                          _SummaryLine(
                            label: strings.shiny,
                            value: entry.isShiny ? strings.yes : strings.no,
                          ),
                          _SummaryLine(
                            label: strings.heldItem,
                            value: entry.heldItemId.isEmpty
                                ? strings.none
                                : _humanize(entry.heldItemId),
                          ),
                          _SummaryLine(
                            label: strings.moves,
                            value: entry.knownMoveIds.isEmpty
                                ? strings.none
                                : entry.knownMoveIds.map(_humanize).join(', '),
                          ),
                          _SummaryLine(
                            label: strings.friendship,
                            value: '${entry.friendship} / 255',
                          ),
                          _SummaryLine(
                            label: strings.origin,
                            value: strings.originLabel(entry.originKind),
                          ),
                          if (entry.metMapId.isNotEmpty)
                            _SummaryLine(
                              label: strings.metLocation,
                              value: _humanize(entry.metMapId),
                            ),
                          if (entry.metSourceId.isNotEmpty)
                            _SummaryLine(
                              label: strings.metSource,
                              value: _humanize(entry.metSourceId),
                            ),
                          if (entry.metLevel case final metLevel?)
                            _SummaryLine(
                              label: strings.metLevel,
                              value: '$metLevel',
                            ),
                          if (entry.ballItemId.isNotEmpty)
                            _SummaryLine(
                              label: strings.captureBall,
                              value: _humanize(entry.ballItemId),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: PlayerSpacing.md),
                  PlayerActionButton(
                    key: const ValueKey<String>('pc-summary-close'),
                    label: strings.close,
                    icon: Icons.close,
                    autofocus: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _humanize(String identifier) {
    final words = identifier
        .trim()
        .replaceAll(RegExp('[-_]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    return words
        .map(
          (word) => '${word.substring(0, 1).toUpperCase()}'
              '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: PlayerSpacing.xs),
        child: Text('$label : $value'),
      );
}

class _InvalidPcOverlay extends StatelessWidget {
  const _InvalidPcOverlay({
    required this.strings,
    required this.onClose,
  });

  final PlayerPcStrings strings;
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
                Text(strings.unavailable),
                const SizedBox(height: PlayerSpacing.md),
                PlayerActionButton(
                  label: strings.close,
                  icon: Icons.close,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      );
}
