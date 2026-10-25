import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'runtime_player_detail_router.dart';
import 'runtime_player_options.dart';
import 'runtime_player_actions.dart';
import 'player_control_profile.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';

/// Standalone options surface opened from the title screen.
///
/// It reuses the same persisted preference controls as the pause menu without
/// pretending that a gameplay session exists.
class PlayerTitleOptionsSurface extends StatefulWidget {
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
  State<PlayerTitleOptionsSurface> createState() =>
      _PlayerTitleOptionsSurfaceState();
}

class _PlayerTitleOptionsSurfaceState extends State<PlayerTitleOptionsSurface> {
  final _navigation = RuntimePlayerOptionsNavigation();

  @override
  void dispose() {
    _navigation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: RuntimePlayerActions(
      onBack: () {
        if (!_navigation.back()) widget.onReturnToTitle?.call();
      },
      onMenu: () {},
      onInputSourceChanged: (_) {},
      child: RuntimePlayerInputBindings(
        controlProfile: widget.controlProfile,
        hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
        child: PlayerMenuThemeScope(
          child: ListenableBuilder(
            listenable: _navigation,
            child: RuntimePlayerDetailRouter(
              optionsNavigation: _navigation,
              snapshot: widget.snapshot,
              onPreferencesChanged: widget.onPreferencesChanged,
              controlProfile: widget.controlProfile,
              hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
              activeInputSource: widget.activeInputSource,
              onControlProfileChanged: widget.onControlProfileChanged,
            ),
            builder: (context, child) => RuntimePlayerTabActions(
              resetToken: _navigation.tabIdentity,
              onPreviousTab: _navigation.previousTab,
              onNextTab: _navigation.nextTab,
              child: Focus(
                autofocus: true,
                skipTraversal: true,
                child: PlayerMenuFrame(
                  key: const ValueKey<String>('runtime-player-title-options'),
                  scrollable: false,
                  header: Padding(
                    padding: const EdgeInsets.all(PlayerSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _navigation.activeTitle ??
                                context.playerL10n.options,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        _navigation.buildHeaderAction(context),
                      ],
                    ),
                  ),
                  footer: Padding(
                    padding: const EdgeInsets.all(PlayerSpacing.sm),
                    child: PlayerActionButton(
                      key: const ValueKey<String>(
                        'runtime-player-title-options-back',
                      ),
                      label: context.playerL10n.returnToTitle,
                      icon: Icons.arrow_back_rounded,
                      secondary: true,
                      labelMaxLines: 3,
                      onPressed: widget.onReturnToTitle,
                    ),
                  ),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
