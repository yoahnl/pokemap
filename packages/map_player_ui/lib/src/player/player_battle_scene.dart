import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../theme/pokemap_player_menu_theme.dart';

import 'player_battle_surface.dart';

class PlayerBattleScene extends StatelessWidget {
  const PlayerBattleScene({
    super.key,
    required this.data,
    required this.onAction,
    this.stage,
    this.display = PlayerBattleDisplay.full,
    this.itemIconBuilder,
    this.onPanelTargeted,
    this.onHudTargeted,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget? stage;
  final PlayerBattleDisplay display;
  final Widget Function(String assetPath)? itemIconBuilder;
  final ValueChanged<PlayerBattlePanelKind>? onPanelTargeted;
  final VoidCallback? onHudTargeted;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      Positioned.fill(
        child:
            stage ??
            (display == PlayerBattleDisplay.commandsOnly
                ? ColoredBox(
                    key: const ValueKey<String>(
                      'player-battle-companion-background',
                    ),
                    color: PokeMapPlayerMenuTheme.resolve(
                      context,
                      role: ProjectPresentationSurfaceRole.battleHud,
                    ).base,
                  )
                : const SizedBox.expand(
                    key: ValueKey<String>('player-battle-runtime-stage'),
                  )),
      ),
      PlayerBattleSurface(
        display: display,
        data: data,
        onAction: onAction,
        itemIconBuilder: itemIconBuilder,
        paintBackground: display == PlayerBattleDisplay.commandsOnly,
        onPanelTargeted: onPanelTargeted,
        onHudTargeted: onHudTargeted,
      ),
    ],
  );
}
