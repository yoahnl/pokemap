import 'package:flutter/material.dart';

import 'player_battle_surface.dart';

class PlayerBattleScene extends StatelessWidget {
  const PlayerBattleScene({
    super.key,
    required this.data,
    required this.onAction,
    this.stage,
    this.itemIconBuilder,
    this.onPanelTargeted,
    this.onHudTargeted,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget? stage;
  final Widget Function(String assetPath)? itemIconBuilder;
  final ValueChanged<PlayerBattlePanelKind>? onPanelTargeted;
  final VoidCallback? onHudTargeted;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: stage ??
                const SizedBox.expand(
                  key: ValueKey<String>('player-battle-runtime-stage'),
                ),
          ),
          PlayerBattleSurface(
            data: data,
            onAction: onAction,
            itemIconBuilder: itemIconBuilder,
            paintBackground: false,
            onPanelTargeted: onPanelTargeted,
            onHudTargeted: onHudTargeted,
          ),
        ],
      );
}
