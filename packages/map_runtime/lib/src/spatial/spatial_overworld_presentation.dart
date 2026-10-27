import 'package:flutter/widgets.dart';

import 'spatial_battle_runtime.dart';

class SpatialOverworldPresentation extends StatelessWidget {
  const SpatialOverworldPresentation({
    super.key,
    this.battle,
    required this.child,
  });

  final SpatialBattleRuntime? battle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final battle = this.battle;
    return ListenableBuilder(
      listenable: Listenable.merge([battle]),
      child: child,
      builder: (_, child) => Offstage(
        offstage: battle?.coversOverworldPresentation ?? false,
        child: child,
      ),
    );
  }
}
