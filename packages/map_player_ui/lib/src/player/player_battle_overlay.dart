import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import 'player_battle_surface.dart';

export 'player_battle_surface.dart';

class PlayerBattleOverlay extends StatelessWidget {
  const PlayerBattleOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<BattlePresentationCommand> onCommand;
  final Widget Function(String assetPath)? itemIconBuilder;

  @override
  Widget build(BuildContext context) => PlayerBattleSurface(
        data: PlayerBattleViewData(
          revision: snapshot.revision,
          enemy: _hud(snapshot.enemyHud),
          player: _hud(snapshot.playerHud),
          battleLabel: snapshot.battleLabel,
          title: snapshot.title,
          prompt: snapshot.prompt,
          narrationLines: snapshot.narrationLines,
          commands: <PlayerBattleCommandViewData>[
            for (final entry in snapshot.entries)
              PlayerBattleCommandViewData(
                index: entry.index,
                primaryLabel: entry.primaryLabel,
                secondaryLabel: entry.secondaryLabel,
                tertiaryLabel: entry.tertiaryLabel,
                trailingLabel: entry.trailingLabel,
                statusLabel: entry.statusLabel,
                enabled: entry.enabled,
                selected: entry.selected,
                tone: _tone(entry.tone),
                iconAssetPath: entry.iconAssetPath,
              ),
          ],
          interactionsEnabled: snapshot.interactionsEnabled,
          canGoBack: snapshot.canGoBack,
          forcedReplacement: snapshot.forcedReplacement,
        ),
        onAction: (action) => onCommand(
          switch (action) {
            PlayerBattleBackAction() => BattleBackCommand(
                snapshotRevision: action.snapshotRevision,
                expectedMode: snapshot.mode,
              ),
            PlayerBattleSelectEntryAction(:final entryIndex) =>
              BattleSelectEntryCommand(
                snapshotRevision: action.snapshotRevision,
                expectedMode: snapshot.mode,
                entryIndex: entryIndex,
              ),
          },
        ),
        itemIconBuilder: itemIconBuilder,
      );
}

PlayerBattleHudViewData _hud(BattleCommandOverlayHudSnapshot snapshot) =>
    PlayerBattleHudViewData(
      ownerLabel: snapshot.ownerLabel,
      speciesLabel: snapshot.speciesLabel,
      level: snapshot.level,
      currentHp: snapshot.currentHp,
      maxHp: snapshot.maxHp,
      displayedHp: snapshot.displayedHp,
      targetDisplayedHp: snapshot.targetDisplayedHp,
      hpTweenDuration: snapshot.hpTweenDuration,
      hpTweenRevision: snapshot.hpTweenRevision,
      statusLabel: snapshot.statusLabel,
    );

PlayerBattleEntryTone _tone(BattleCommandOverlayEntryTone tone) =>
    switch (tone) {
      BattleCommandOverlayEntryTone.neutral => PlayerBattleEntryTone.neutral,
      BattleCommandOverlayEntryTone.attack => PlayerBattleEntryTone.attack,
      BattleCommandOverlayEntryTone.special => PlayerBattleEntryTone.special,
      BattleCommandOverlayEntryTone.support => PlayerBattleEntryTone.support,
      BattleCommandOverlayEntryTone.switching =>
        PlayerBattleEntryTone.switching,
      BattleCommandOverlayEntryTone.medicine => PlayerBattleEntryTone.medicine,
      BattleCommandOverlayEntryTone.capture => PlayerBattleEntryTone.capture,
      BattleCommandOverlayEntryTone.disabled => PlayerBattleEntryTone.disabled,
    };
