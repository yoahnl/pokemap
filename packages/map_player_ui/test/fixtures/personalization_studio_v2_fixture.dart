import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';

abstract final class PersonalizationStudioV2Fixture {
  static const projectName = 'Le train de 17h42';

  static PlayerTitleSurfaceData title(
    RuntimePlayerPresentation presentation, {
    String projectName = PersonalizationStudioV2Fixture.projectName,
  }) =>
      PlayerTitleSurfaceData(
        gameTitle: projectName,
        author: 'POKÉMAP',
        description: 'Une aventure ferroviaire à travers Hanazuki.',
        background: presentation.title.background,
        logo: presentation.title.logo,
        accentColor: presentation.title.accentColor,
        layoutVariant: presentation.title.layoutVariant,
        actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
          for (final action in PlayerTitleMenuAction.values)
            action: PlayerActionAvailability.enabled,
        },
        initialSelection: PlayerTitleMenuAction.newGame,
      );

  static Map<PlayerPauseAction, PlayerActionAvailability> get pauseActions =>
      <PlayerPauseAction, PlayerActionAvailability>{
        for (final action in PlayerPauseAction.values)
          action: PlayerActionAvailability.enabled,
      };

  static const dialogue = PlayerDialogueViewData(
    revision: 1,
    mode: PlayerDialogueMode.line,
    speaker: 'Professeure Saule',
    text: 'Le monde est peuplé de créatures extraordinaires.',
    fullText: 'Le monde est peuplé de créatures extraordinaires.',
    isCurrentLineFullyRevealed: true,
    isLastContent: false,
    choices: <PlayerDialogueChoiceViewData>[],
  );

  static const battle = PlayerBattleViewData(
    revision: 1,
    enemy: PlayerBattleHudViewData(
      ownerLabel: 'DRESSEUR',
      speciesLabel: 'ROUCOOL',
      level: 7,
      currentHp: 31,
      maxHp: 31,
    ),
    player: PlayerBattleHudViewData(
      ownerLabel: 'JOUEUR',
      speciesLabel: 'BRINDIBOU',
      level: 8,
      currentHp: 42,
      maxHp: 55,
    ),
    battleLabel: 'Combat sauvage',
    title: 'Que doit faire BRINDIBOU ?',
    prompt: 'Choisissez une action.',
    narrationLines: <String>[],
    commands: <PlayerBattleCommandViewData>[
      PlayerBattleCommandViewData(
        index: 0,
        primaryLabel: 'ATTAQUER',
        secondaryLabel: 'Choisir une capacité',
        enabled: true,
        selected: true,
        tone: PlayerBattleEntryTone.attack,
      ),
      PlayerBattleCommandViewData(
        index: 1,
        primaryLabel: 'SAC',
        secondaryLabel: 'Utiliser un objet',
        enabled: true,
        selected: false,
        tone: PlayerBattleEntryTone.medicine,
      ),
      PlayerBattleCommandViewData(
        index: 2,
        primaryLabel: 'ÉQUIPE',
        secondaryLabel: 'Changer de Pokémon',
        enabled: true,
        selected: false,
        tone: PlayerBattleEntryTone.switching,
      ),
      PlayerBattleCommandViewData(
        index: 3,
        primaryLabel: 'FUITE',
        secondaryLabel: 'Quitter le combat',
        enabled: true,
        selected: false,
        tone: PlayerBattleEntryTone.neutral,
      ),
    ],
    interactionsEnabled: true,
    canGoBack: false,
  );

  static const introMedia = ColoredBox(
    color: Color(0xFFD9F4F6),
    child: Center(child: Icon(Icons.train_rounded, size: 96)),
  );
}
