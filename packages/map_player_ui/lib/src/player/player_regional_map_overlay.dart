import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_control_profile.dart';
import 'runtime_player_actions.dart';
import 'runtime_player_region_map.dart';

class PlayerRegionalMapOverlay extends StatelessWidget {
  const PlayerRegionalMapOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;

  @override
  Widget build(BuildContext context) {
    final content = snapshot.content;
    final detail = content is RuntimeRegionalMapServiceContent
        ? content.detail
        : null;
    return RuntimePlayerActions(
      includeDefaultKeyboardShortcuts: false,
      onBack: () => _emit(RuntimeWorldServiceAction.cancel),
      onMenu: () {},
      onInputSourceChanged: (_) {},
      child: RuntimePlayerInputBindings(
        controlProfile: controlProfile,
        hardwareGamepadEnabled: hardwareGamepadEnabled,
        child: ColoredBox(
          color: context.playerColors.scrim,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(PlayerSpacing.sm),
              child: PlayerPanel(
                surfaceRole: ProjectPresentationSurfaceRole.map,
                elevated: true,
                padding: const EdgeInsets.all(PlayerSpacing.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            detail?.title ?? context.playerL10n.map,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        PlayerActionButton(
                          key: const ValueKey('regional-map-close'),
                          label: context.playerL10n.close,
                          icon: Icons.close,
                          expandWidth: false,
                          expandContent: false,
                          secondary: true,
                          onPressed:
                              snapshot.isActionEnabled(
                                RuntimeWorldServiceAction.close,
                              )
                              ? () => _emit(RuntimeWorldServiceAction.close)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: PlayerSpacing.sm),
                    Expanded(
                      child: PlayerMenuThemeScope(
                        role: ProjectPresentationSurfaceRole.map,
                        child: detail == null
                            ? PlayerEmptyState(
                                icon: Icons.map_outlined,
                                title: context.playerL10n.map,
                                message:
                                    context.playerL10n.noPlayerDetailAvailable,
                              )
                            : RuntimePlayerRegionMap(
                                detail: detail,
                                controlProfile: controlProfile,
                                hardwareGamepadEnabled: hardwareGamepadEnabled,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _emit(RuntimeWorldServiceAction action) {
    if (snapshot.isActionEnabled(action)) {
      onCommand(
        RuntimeWorldServiceCommand(
          action: action,
          snapshotRevision: snapshot.revision,
        ),
      );
    }
  }
}
