import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'runtime_player_party.dart';
import 'runtime_player_options.dart';
import 'player_control_profile.dart';
import 'runtime_player_bag.dart';
import 'runtime_player_pokedex.dart';
import 'runtime_player_region_map.dart';
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
    this.regionMapNavigation,
    this.onFavoriteChanged,
    this.onReturnToTitle,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
    this.activeInputSource,
    this.onControlProfileChanged,
  });

  final RuntimePlayerSnapshot snapshot;
  final FutureOr<void> Function(PlayerPreferencesSnapshot)?
      onPreferencesChanged;
  final FutureOr<void> Function(RuntimePlayerPauseCommand)? onPauseCommand;
  final RuntimePlayerPartyNavigation? partyNavigation;
  final RuntimePlayerBagNavigation? bagNavigation;
  final RuntimePlayerPokedexNavigation? pokedexNavigation;
  final RuntimePlayerRegionMapNavigation? regionMapNavigation;
  final Future<void> Function(String, bool)? onFavoriteChanged;
  final VoidCallback? onReturnToTitle;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;
  final PlayerInputSource? activeInputSource;
  final FutureOr<void> Function(PlayerControlProfile)? onControlProfileChanged;

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
      return PlayerMenuThemeScope(
          role: ProjectPresentationSurfaceRole.options,
          child: RuntimePlayerOptions(
            preferences: preferences,
            defaultPreferences: snapshot.defaultPreferences,
            onReturnToTitle: onReturnToTitle,
            controlProfile: controlProfile,
            hardwareGamepadEnabled: hardwareGamepadEnabled,
            onControlProfileChanged: onControlProfileChanged,
            activeInputSource: activeInputSource ??
                snapshot.activeInputSource ??
                PlayerInputSource.keyboard,
            onChanged:
                snapshot.isActionEnabled(RuntimePlayerAction.updatePreferences)
                    ? onPreferencesChanged
                    : null,
          ));
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
    if (section == RuntimePlayerPauseSection.map && detail != null) {
      return PlayerMenuThemeScope(
        role: ProjectPresentationSurfaceRole.map,
        child: RuntimePlayerRegionMap(
            detail: detail,
            navigation: regionMapNavigation,
            controlProfile: controlProfile,
            hardwareGamepadEnabled: hardwareGamepadEnabled),
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
