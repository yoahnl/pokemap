import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_session_surfaces.dart';
import 'player_bag_strings.dart';

/// Maps runtime-owned pause detail snapshots to simple player surfaces.
class RuntimePlayerDetailRouter extends StatelessWidget {
  const RuntimePlayerDetailRouter({
    super.key,
    required this.snapshot,
    this.onPreferencesChanged,
    this.onPauseCommand,
  });

  final RuntimePlayerSnapshot snapshot;
  final ValueChanged<PlayerPreferencesSnapshot>? onPreferencesChanged;
  final ValueChanged<RuntimePlayerPauseCommand>? onPauseCommand;

  @override
  Widget build(BuildContext context) {
    final section = snapshot.pauseSection ?? RuntimePlayerPauseSection.root;
    if (section == RuntimePlayerPauseSection.root) {
      return PlayerEmptyState(
        key: const ValueKey<String>('runtime-player-detail-root'),
        icon: Icons.gamepad_rounded,
        title: context.playerL10n.pause,
        message: context.playerL10n.actionUnavailable,
      );
    }

    final unavailableReason =
        snapshot.unavailableReasonFor(_actionFor(section));
    if (unavailableReason != null) {
      return PlayerEmptyState(
        key: const ValueKey<String>('runtime-player-detail-unavailable'),
        icon: Icons.lock_outline_rounded,
        title: _label(context, section),
        message: unavailableReason,
      );
    }

    final preferences = snapshot.preferences;
    if (section == RuntimePlayerPauseSection.options && preferences != null) {
      return _RuntimePlayerOptions(
        preferences: preferences,
        onChanged:
            snapshot.isActionEnabled(RuntimePlayerAction.updatePreferences)
                ? onPreferencesChanged
                : null,
      );
    }

    final detail = snapshot.pauseDetailFor(section);
    if (detail == null || detail.entries.isEmpty) {
      return PlayerEmptyState(
        key: const ValueKey<String>('runtime-player-detail-empty'),
        icon: _icon(section),
        title: detail?.title ?? _label(context, section),
        message:
            detail?.emptyMessage ?? context.playerL10n.noPlayerDetailAvailable,
      );
    }

    if (section == RuntimePlayerPauseSection.bag) {
      return _RuntimePlayerBag(
        detail: detail,
        onCommand: onPauseCommand,
      );
    }

    if (section == RuntimePlayerPauseSection.map) {
      return _RuntimePlayerMap(detail: detail);
    }

    return Column(
      key: ValueKey<String>('runtime-player-detail-${section.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var index = 0; index < detail.entries.length; index++) ...<Widget>[
          PlayerDetailEntryCard(entry: detail.entries[index]),
          if (index != detail.entries.length - 1)
            const SizedBox(height: PlayerSpacing.sm),
        ],
      ],
    );
  }

  RuntimePlayerAction _actionFor(RuntimePlayerPauseSection section) =>
      switch (section) {
        RuntimePlayerPauseSection.party => RuntimePlayerAction.openParty,
        RuntimePlayerPauseSection.bag => RuntimePlayerAction.openBag,
        RuntimePlayerPauseSection.pokedex => RuntimePlayerAction.openPokedex,
        RuntimePlayerPauseSection.map => RuntimePlayerAction.openMap,
        RuntimePlayerPauseSection.options => RuntimePlayerAction.openOptions,
        RuntimePlayerPauseSection.root => throw StateError(
            'The pause root has no detail action.',
          ),
      };

  String _label(
    BuildContext context,
    RuntimePlayerPauseSection section,
  ) {
    final l10n = context.playerL10n;
    return switch (section) {
      RuntimePlayerPauseSection.root => l10n.pause,
      RuntimePlayerPauseSection.party => l10n.party,
      RuntimePlayerPauseSection.bag => l10n.bag,
      RuntimePlayerPauseSection.pokedex => l10n.pokedex,
      RuntimePlayerPauseSection.map => l10n.map,
      RuntimePlayerPauseSection.options => l10n.options,
    };
  }

  IconData _icon(RuntimePlayerPauseSection section) => switch (section) {
        RuntimePlayerPauseSection.root => Icons.gamepad_rounded,
        RuntimePlayerPauseSection.party => Icons.groups_rounded,
        RuntimePlayerPauseSection.bag => Icons.backpack_rounded,
        RuntimePlayerPauseSection.pokedex => Icons.menu_book_rounded,
        RuntimePlayerPauseSection.map => Icons.map_rounded,
        RuntimePlayerPauseSection.options => Icons.tune_rounded,
      };
}

class _RuntimePlayerMap extends StatelessWidget {
  const _RuntimePlayerMap({required this.detail});

  final RuntimePlayerPauseDetailSnapshot detail;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey<String>('runtime-player-detail-map'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (detail.message case final message?
              when message.trim().isNotEmpty) ...<Widget>[
            PlayerPanel(
              child: Text(
                message,
                key: const ValueKey<String>('runtime-player-map-message'),
              ),
            ),
            const SizedBox(height: PlayerSpacing.sm),
          ],
          for (var index = 0;
              index < detail.entries.length;
              index++) ...<Widget>[
            PlayerDetailEntryCard(entry: detail.entries[index]),
            if (index != detail.entries.length - 1)
              const SizedBox(height: PlayerSpacing.sm),
          ],
        ],
      );
}

class _RuntimePlayerBag extends StatelessWidget {
  const _RuntimePlayerBag({
    required this.detail,
    required this.onCommand,
  });

  final RuntimePlayerPauseDetailSnapshot detail;
  final ValueChanged<RuntimePlayerPauseCommand>? onCommand;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey<String>('runtime-player-detail-bag'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (detail.message case final message?
              when message.trim().isNotEmpty) ...<Widget>[
            PlayerPanel(
              child: Text(
                message,
                key: const ValueKey<String>('runtime-player-bag-message'),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: PlayerSpacing.sm),
          ],
          for (var index = 0;
              index < detail.entries.length;
              index++) ...<Widget>[
            PlayerDetailEntryCard(entry: detail.entries[index]),
            if (detail.entries[index].bagAction case final action?) ...<Widget>[
              const SizedBox(height: PlayerSpacing.xs),
              PlayerActionButton(
                key: ValueKey<String>(
                  'runtime-player-bag-use-${action.itemTargetId}',
                ),
                label: PlayerBagStrings.of(context).use,
                icon: Icons.healing_rounded,
                secondary: true,
                onPressed: action.isEnabled && onCommand != null
                    ? () => _showTargets(
                          context,
                          action: action,
                        )
                    : null,
                disabledReason: action.unavailableReason,
              ),
            ],
            if (index != detail.entries.length - 1)
              const SizedBox(height: PlayerSpacing.sm),
          ],
        ],
      );

  void _showTargets(
    BuildContext context, {
    required RuntimePlayerBagItemActionSnapshot action,
  }) {
    final strings = PlayerBagStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        final availableHeight = MediaQuery.sizeOf(context).height - 32;
        final buttons = <Widget>[];
        for (final target in detail.bagTargets) {
          if (action.targetKind == RuntimePlayerBagUseTargetKind.partyMember ||
              (action.targetKind ==
                      RuntimePlayerBagUseTargetKind.partyMoveReplacement &&
                  target.moves.length < 4)) {
            final teachesMove = action.targetKind ==
                RuntimePlayerBagUseTargetKind.partyMoveReplacement;
            buttons.add(
              PlayerActionButton(
                key: ValueKey<String>(
                  'runtime-player-bag-target-${target.targetId}',
                ),
                label: teachesMove
                    ? strings.teachTo(target.label)
                    : strings.useOn(target.label),
                icon:
                    teachesMove ? Icons.school_rounded : Icons.catching_pokemon,
                onPressed: () {
                  Navigator.of(context).pop();
                  onCommand!(
                    RuntimePlayerPauseCommand.useBagItem(
                      itemTargetId: action.itemTargetId,
                      partyTargetId: target.targetId,
                    ),
                  );
                },
              ),
            );
          } else {
            final teachesMove = action.targetKind ==
                RuntimePlayerBagUseTargetKind.partyMoveReplacement;
            for (final move in target.moves) {
              buttons.add(
                PlayerActionButton(
                  key: ValueKey<String>(
                    'runtime-player-bag-target-'
                    '${target.targetId}-${move.targetId}',
                  ),
                  label: teachesMove
                      ? strings.teachReplacing(target.label, move.label)
                      : strings.useOnMove(target.label, move.label),
                  icon: Icons.flash_on_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCommand!(
                      RuntimePlayerPauseCommand.useBagItem(
                        itemTargetId: action.itemTargetId,
                        partyTargetId: target.targetId,
                        moveTargetId: move.targetId,
                      ),
                    );
                  },
                ),
              );
            }
          }
        }
        return Dialog(
          insetPadding: const EdgeInsets.all(PlayerSpacing.md),
          child: SizedBox(
            width: 520,
            height: availableHeight.clamp(240, 640).toDouble(),
            child: PlayerPanel(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    strings.chooseTarget,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: PlayerSpacing.md),
                  Expanded(
                    child: ListView.separated(
                      itemCount: buttons.length,
                      itemBuilder: (_, index) => buttons[index],
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: PlayerSpacing.xs),
                    ),
                  ),
                  const SizedBox(height: PlayerSpacing.sm),
                  PlayerActionButton(
                    key: const ValueKey<String>(
                      'runtime-player-bag-target-close',
                    ),
                    label: strings.close,
                    icon: Icons.close,
                    secondary: true,
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
}

class _RuntimePlayerOptions extends StatefulWidget {
  const _RuntimePlayerOptions({
    required this.preferences,
    required this.onChanged,
  });

  final PlayerPreferencesSnapshot preferences;
  final ValueChanged<PlayerPreferencesSnapshot>? onChanged;

  @override
  State<_RuntimePlayerOptions> createState() => _RuntimePlayerOptionsState();
}

class _RuntimePlayerOptionsState extends State<_RuntimePlayerOptions> {
  late double _touchControlsOpacity = widget.preferences.touchControlsOpacity;

  @override
  void didUpdateWidget(covariant _RuntimePlayerOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences.touchControlsOpacity !=
        widget.preferences.touchControlsOpacity) {
      _touchControlsOpacity = widget.preferences.touchControlsOpacity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlayerPanel(
      key: const ValueKey<String>('runtime-player-options'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.playerL10n.touchControlsOpacity,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PlayerSpacing.xs),
          Text('${(_touchControlsOpacity * 100).round()} %'),
          Slider(
            key: const ValueKey<String>(
              'touch-controls-opacity-slider',
            ),
            value: _touchControlsOpacity,
            min: 0.3,
            max: 1,
            divisions: 14,
            label: '${(_touchControlsOpacity * 100).round()} %',
            onChanged: widget.onChanged == null
                ? null
                : (value) => setState(
                      () => _touchControlsOpacity = value,
                    ),
            onChangeEnd: widget.onChanged == null
                ? null
                : (value) => widget.onChanged!(
                      widget.preferences.copyWith(
                        touchControlsOpacity: value,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
