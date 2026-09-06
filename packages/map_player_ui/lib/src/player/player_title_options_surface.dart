import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'runtime_player_detail_router.dart';
import 'runtime_player_actions.dart';
import 'player_control_profile.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';

/// Standalone options surface opened from the title screen.
///
/// It reuses the same persisted preference controls as the pause menu without
/// pretending that a gameplay session exists.
class PlayerTitleOptionsSurface extends StatelessWidget {
  const PlayerTitleOptionsSurface({
    super.key,
    required this.snapshot,
    required this.onReturnToTitle,
    this.onPreferencesChanged,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
    this.activeInputSource,
    this.onControlProfileChanged,
  });

  final RuntimePlayerSnapshot snapshot;
  final VoidCallback? onReturnToTitle;
  final FutureOr<void> Function(PlayerPreferencesSnapshot)?
      onPreferencesChanged;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;
  final PlayerInputSource? activeInputSource;
  final FutureOr<void> Function(PlayerControlProfile)? onControlProfileChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: RuntimePlayerActions(
            onBack: onReturnToTitle ?? () {},
            onMenu: () {},
            onInputSourceChanged: (_) {},
            child: RuntimePlayerInputBindings(
                controlProfile: controlProfile,
                hardwareGamepadEnabled: hardwareGamepadEnabled,
                child: PlayerMenuThemeScope(
                  child: PlayerMenuFrame(
                    key: const ValueKey<String>('runtime-player-title-options'),
                    scrollable: false,
                    header: Padding(
                      padding: const EdgeInsets.all(PlayerSpacing.lg),
                      child: Text(context.playerL10n.options,
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    footer: Padding(
                      padding: const EdgeInsets.all(PlayerSpacing.sm),
                      child: PlayerActionButton(
                        key: const ValueKey<String>(
                            'runtime-player-title-options-back'),
                        label: context.playerL10n.returnToTitle,
                        icon: Icons.arrow_back_rounded,
                        secondary: true,
                        labelMaxLines: 3,
                        onPressed: onReturnToTitle,
                      ),
                    ),
                    child: RuntimePlayerDetailRouter(
                      snapshot: snapshot,
                      onPreferencesChanged: onPreferencesChanged,
                      controlProfile: controlProfile,
                      hardwareGamepadEnabled: hardwareGamepadEnabled,
                      activeInputSource: activeInputSource,
                      onControlProfileChanged: onControlProfileChanged,
                    ),
                  ),
                ))),
      );
}
