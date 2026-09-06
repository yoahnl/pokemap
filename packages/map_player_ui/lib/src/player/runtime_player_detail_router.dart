import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'runtime_player_party.dart';
import 'runtime_player_bag.dart';
import 'runtime_player_pokedex.dart';
import 'runtime_player_profile.dart';
import 'player_session_surfaces.dart';

/// Maps runtime-owned pause detail snapshots to simple player surfaces.
class RuntimePlayerDetailRouter extends StatelessWidget {
  const RuntimePlayerDetailRouter({
    super.key,
    required this.snapshot,
    this.onPreferencesChanged,
    this.onPauseCommand,
    this.partyNavigation,
    this.bagNavigation,
    this.pokedexNavigation,
    this.onFavoriteChanged,
  });

  final RuntimePlayerSnapshot snapshot;
  final ValueChanged<PlayerPreferencesSnapshot>? onPreferencesChanged;
  final FutureOr<void> Function(RuntimePlayerPauseCommand)? onPauseCommand;
  final RuntimePlayerPartyNavigation? partyNavigation;
  final RuntimePlayerBagNavigation? bagNavigation;
  final RuntimePlayerPokedexNavigation? pokedexNavigation;
  final Future<void> Function(String, bool)? onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    final section = snapshot.pauseSection ?? RuntimePlayerPauseSection.root;
    if (section == RuntimePlayerPauseSection.root) {
      return const SizedBox.shrink(
        key: ValueKey<String>('runtime-player-detail-root'),
      );
    }

    final unavailableReason =
        snapshot.unavailableReasonFor(_actionFor(section));
    if (unavailableReason != null ||
        snapshot.phase == RuntimePlayerPhase.paused &&
            !snapshot.isActionEnabled(_actionFor(section))) {
      return PlayerEmptyState(
        key: const ValueKey<String>('runtime-player-detail-unavailable'),
        icon: Icons.lock_outline_rounded,
        title: _label(context, section),
        message: unavailableReason ?? context.playerL10n.actionUnavailable,
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
    if (section == RuntimePlayerPauseSection.party && detail != null) {
      return PlayerMenuThemeScope(
          role: ProjectPresentationSurfaceRole.party,
          child: RuntimePlayerParty(
            navigation: partyNavigation,
            detail: detail,
            onCommand: onPauseCommand,
            canReorder:
                snapshot.isActionEnabled(RuntimePlayerAction.reorderParty),
          ));
    }
    if (section == RuntimePlayerPauseSection.bag && detail != null) {
      return PlayerMenuThemeScope(
          role: ProjectPresentationSurfaceRole.bag,
          child: RuntimePlayerBag(
              detail: detail,
              onCommand: onPauseCommand,
              navigation: bagNavigation,
              favoriteItemIds: snapshot.favoriteItemIds,
              onFavoriteChanged:
                  snapshot.bagFavoritesAvailable ? onFavoriteChanged : null));
    }
    if (section == RuntimePlayerPauseSection.pokedex && detail != null) {
      return PlayerMenuThemeScope(
        role: ProjectPresentationSurfaceRole.pokedex,
        child: RuntimePlayerPokedex(
          detail: detail,
          navigation: pokedexNavigation,
        ),
      );
    }
    if (section == RuntimePlayerPauseSection.profile &&
        detail?.profile != null) {
      return PlayerMenuThemeScope(
        role: ProjectPresentationSurfaceRole.pauseMenu,
        child: RuntimePlayerProfile(profile: detail!.profile!),
      );
    }
    if (detail == null || detail.entries.isEmpty) {
      return PlayerEmptyState(
        key: const ValueKey<String>('runtime-player-detail-empty'),
        icon: _icon(section),
        title: detail?.title ?? _label(context, section),
        message:
            detail?.emptyMessage ?? context.playerL10n.noPlayerDetailAvailable,
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
          PlayerDetailEntryCard(
            entry: detail.entries[index],
            surfaceRole: _surfaceRoleFor(section),
          ),
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
        RuntimePlayerPauseSection.quests => RuntimePlayerAction.openQuests,
        RuntimePlayerPauseSection.profile => RuntimePlayerAction.openProfile,
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
      RuntimePlayerPauseSection.quests => l10n.quests,
      RuntimePlayerPauseSection.profile => l10n.profile,
      RuntimePlayerPauseSection.options => l10n.options,
    };
  }

  IconData _icon(RuntimePlayerPauseSection section) => switch (section) {
        RuntimePlayerPauseSection.root => Icons.gamepad_rounded,
        RuntimePlayerPauseSection.party => Icons.groups_rounded,
        RuntimePlayerPauseSection.bag => Icons.backpack_rounded,
        RuntimePlayerPauseSection.pokedex => Icons.menu_book_rounded,
        RuntimePlayerPauseSection.map => Icons.map_rounded,
        RuntimePlayerPauseSection.quests => Icons.menu_book_rounded,
        RuntimePlayerPauseSection.profile => Icons.person_rounded,
        RuntimePlayerPauseSection.options => Icons.tune_rounded,
      };

  ProjectPresentationSurfaceRole _surfaceRoleFor(
    RuntimePlayerPauseSection section,
  ) =>
      switch (section) {
        RuntimePlayerPauseSection.party => ProjectPresentationSurfaceRole.party,
        RuntimePlayerPauseSection.bag => ProjectPresentationSurfaceRole.bag,
        RuntimePlayerPauseSection.pokedex =>
          ProjectPresentationSurfaceRole.pokedex,
        RuntimePlayerPauseSection.map => ProjectPresentationSurfaceRole.map,
        RuntimePlayerPauseSection.quests =>
          ProjectPresentationSurfaceRole.pauseMenu,
        RuntimePlayerPauseSection.profile =>
          ProjectPresentationSurfaceRole.pauseMenu,
        RuntimePlayerPauseSection.options =>
          ProjectPresentationSurfaceRole.options,
        RuntimePlayerPauseSection.root =>
          ProjectPresentationSurfaceRole.pauseMenu,
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
              surfaceRole: ProjectPresentationSurfaceRole.map,
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
            PlayerDetailEntryCard(
              entry: detail.entries[index],
              surfaceRole: ProjectPresentationSurfaceRole.map,
            ),
            if (index != detail.entries.length - 1)
              const SizedBox(height: PlayerSpacing.sm),
          ],
        ],
      );
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
  late double _textScale = widget.preferences.accessibility.textScale;

  @override
  void didUpdateWidget(covariant _RuntimePlayerOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences.touchControlsOpacity !=
        widget.preferences.touchControlsOpacity) {
      _touchControlsOpacity = widget.preferences.touchControlsOpacity;
    }
    if (oldWidget.preferences.accessibility.textScale !=
        widget.preferences.accessibility.textScale) {
      _textScale = widget.preferences.accessibility.textScale;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlayerPanel(
      key: const ValueKey<String>('runtime-player-options'),
      surfaceRole: ProjectPresentationSurfaceRole.options,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.playerL10n.accessibility,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PlayerSpacing.xs),
          SwitchListTile.adaptive(
            key: const ValueKey<String>(
              'runtime-player-reduced-motion-toggle',
            ),
            contentPadding: EdgeInsets.zero,
            title: Text(context.playerL10n.reducedMotion),
            value: widget.preferences.accessibility.reducedMotion,
            onChanged: widget.onChanged == null
                ? null
                : (value) => widget.onChanged!(
                      widget.preferences.copyWith(
                        accessibility:
                            widget.preferences.accessibility.copyWith(
                          reducedMotion: value,
                        ),
                      ),
                    ),
          ),
          SwitchListTile.adaptive(
            key: const ValueKey<String>(
              'runtime-player-high-contrast-toggle',
            ),
            contentPadding: EdgeInsets.zero,
            title: Text(context.playerL10n.highContrast),
            value: widget.preferences.highContrast,
            onChanged: widget.onChanged == null
                ? null
                : (value) => widget.onChanged!(
                      widget.preferences.copyWith(highContrast: value),
                    ),
          ),
          SwitchListTile.adaptive(
            key: const ValueKey<String>('runtime-player-haptics-toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(context.playerL10n.haptics),
            value: widget.preferences.accessibility.hapticsEnabled,
            onChanged: widget.onChanged == null
                ? null
                : (value) => widget.onChanged!(
                      widget.preferences.copyWith(
                        accessibility:
                            widget.preferences.accessibility.copyWith(
                          hapticsEnabled: value,
                        ),
                      ),
                    ),
          ),
          SwitchListTile.adaptive(
            key: const ValueKey<String>('runtime-player-input-hints-toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(context.playerL10n.inputHints),
            value: widget.preferences.showInputHints,
            onChanged: widget.onChanged == null
                ? null
                : (value) => widget.onChanged!(
                      widget.preferences.copyWith(showInputHints: value),
                    ),
          ),
          Text(context.playerL10n.textSize),
          // La valeur vit ici, en continu. Le `label:` du Slider la repetait
          // dans une bulle qui se posait pile sur ce Text pendant le
          // glissement : deux fois la meme information, superposees.
          Text('${(_textScale * 100).round()} %'),
          Slider(
            key: const ValueKey<String>('runtime-player-text-scale-slider'),
            value: _textScale,
            min: 0.8,
            max: 1.6,
            divisions: 8,
            onChanged: widget.onChanged == null
                ? null
                : (value) => setState(() => _textScale = value),
            onChangeEnd: widget.onChanged == null
                ? null
                : (value) => widget.onChanged!(
                      widget.preferences.copyWith(
                        accessibility:
                            widget.preferences.accessibility.copyWith(
                          textScale: value,
                        ),
                      ),
                    ),
          ),
          const Divider(),
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
