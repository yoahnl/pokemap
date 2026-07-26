import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_session_surfaces.dart';

/// Maps runtime-owned pause detail snapshots to simple player surfaces.
class RuntimePlayerDetailRouter extends StatelessWidget {
  const RuntimePlayerDetailRouter({
    super.key,
    required this.snapshot,
    this.onPreferencesChanged,
  });

  final RuntimePlayerSnapshot snapshot;
  final ValueChanged<PlayerPreferencesSnapshot>? onPreferencesChanged;

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
