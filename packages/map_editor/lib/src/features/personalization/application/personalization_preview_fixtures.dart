import 'package:flutter/widgets.dart';
import 'package:map_player_ui/map_player_ui.dart';

enum PersonalizationBattlePreviewState { commands, moves, target, message }

abstract final class PersonalizationPreviewFixtures {
  static PlayerTitleSurfaceData title(
    String projectName,
    RuntimePlayerPresentation presentation, {
    Widget? backgroundContent,
  }) => PlayerTitleSurfaceData(
    gameTitle: projectName,
    author: presentation.title.author,
    description: presentation.title.description,
    background: presentation.title.background,
    backgroundContent: backgroundContent,
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

  static PlayerDialogueViewData dialogueFor({
    required String speaker,
    required bool showChoices,
  }) => showChoices
      ? const PlayerDialogueViewData(
          revision: 2,
          mode: PlayerDialogueMode.choices,
          speaker: null,
          text: '',
          fullText: '',
          isCurrentLineFullyRevealed: true,
          isLastContent: false,
          choices: <PlayerDialogueChoiceViewData>[
            PlayerDialogueChoiceViewData(
              index: 0,
              label: 'Oui, allons-y !',
              selected: true,
            ),
            PlayerDialogueChoiceViewData(
              index: 1,
              label: 'Pas encore.',
              selected: false,
            ),
          ],
        )
      : PlayerDialogueViewData(
          revision: 1,
          mode: PlayerDialogueMode.line,
          speaker: speaker,
          text: 'Bienvenue dans le monde des Pokémon !',
          fullText: 'Bienvenue dans le monde des Pokémon !',
          isCurrentLineFullyRevealed: true,
          isLastContent: false,
          choices: const <PlayerDialogueChoiceViewData>[],
        );

  static const battle = _battleCommands;

  static PlayerBattleViewData battleFor(
    PersonalizationBattlePreviewState state,
  ) => switch (state) {
    PersonalizationBattlePreviewState.commands => _battleCommands,
    PersonalizationBattlePreviewState.moves => _battleMoves,
    PersonalizationBattlePreviewState.target => _battleTarget,
    PersonalizationBattlePreviewState.message => _battleMessage,
  };

  static const _enemy = PlayerBattleHudViewData(
    ownerLabel: 'DRESSEUR',
    speciesLabel: 'ROUCOOL',
    level: 7,
    currentHp: 31,
    maxHp: 31,
  );

  static const _player = PlayerBattleHudViewData(
    ownerLabel: 'JOUEUR',
    speciesLabel: 'BRINDIBOU',
    level: 8,
    currentHp: 42,
    maxHp: 55,
  );

  static const _battleCommands = PlayerBattleViewData(
    revision: 1,
    enemy: _enemy,
    player: _player,
    battleLabel: 'Combat sauvage',
    title: 'Que doit faire BRINDIBOU ?',
    prompt: 'Choisissez une action.',
    narrationLines: <String>[],
    commands: <PlayerBattleCommandViewData>[
      PlayerBattleCommandViewData(
        index: 0,
        primaryLabel: 'ATTAQUE',
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
        primaryLabel: 'POKÉMON',
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

  static const _battleMoves = PlayerBattleViewData(
    revision: 2,
    enemy: _enemy,
    player: _player,
    battleLabel: 'Combat sauvage',
    title: 'Capacités de BRINDIBOU',
    prompt: 'Choisissez une capacité.',
    narrationLines: <String>[],
    commands: <PlayerBattleCommandViewData>[
      PlayerBattleCommandViewData(
        index: 0,
        primaryLabel: 'Feuillage',
        secondaryLabel: 'PLANTE · PP 18/25',
        enabled: true,
        selected: true,
        tone: PlayerBattleEntryTone.attack,
      ),
      PlayerBattleCommandViewData(
        index: 1,
        primaryLabel: 'Charge',
        secondaryLabel: 'NORMAL · PP 30/35',
        enabled: true,
        selected: false,
        tone: PlayerBattleEntryTone.neutral,
      ),
      PlayerBattleCommandViewData(
        index: 2,
        primaryLabel: 'Éco-Sphère',
        secondaryLabel: 'PLANTE · PP 0/10',
        statusLabel: 'Indisponible',
        enabled: false,
        selected: false,
        tone: PlayerBattleEntryTone.disabled,
      ),
      PlayerBattleCommandViewData(
        index: 3,
        primaryLabel: 'Picpic',
        secondaryLabel: 'VOL · PP 20/20',
        enabled: true,
        selected: false,
        tone: PlayerBattleEntryTone.special,
      ),
    ],
    interactionsEnabled: true,
    canGoBack: true,
  );

  static const _battleTarget = PlayerBattleViewData(
    revision: 3,
    enemy: _enemy,
    player: _player,
    battleLabel: 'Combat sauvage',
    title: 'Choisissez une cible',
    prompt: 'Qui doit recevoir cette capacité ?',
    narrationLines: <String>[],
    commands: <PlayerBattleCommandViewData>[
      PlayerBattleCommandViewData(
        index: 0,
        primaryLabel: 'ROUCOOL adverse',
        secondaryLabel: 'Cible valide',
        enabled: true,
        selected: true,
        tone: PlayerBattleEntryTone.attack,
      ),
      PlayerBattleCommandViewData(
        index: 1,
        primaryLabel: 'BRINDIBOU allié',
        secondaryLabel: 'Cible invalide',
        enabled: false,
        selected: false,
        tone: PlayerBattleEntryTone.disabled,
      ),
    ],
    interactionsEnabled: true,
    canGoBack: true,
  );

  static const _battleMessage = PlayerBattleViewData(
    revision: 4,
    enemy: _enemy,
    player: _player,
    battleLabel: 'Combat sauvage',
    title: 'Le combat continue',
    prompt: 'Le vent se lève et traverse le champ de bataille.',
    narrationLines: <String>[
      'ROUCOOL prend de l’altitude tandis que BRINDIBOU reste concentré.',
      'Les commandes reviendront après la fin du message.',
    ],
    commands: <PlayerBattleCommandViewData>[],
    interactionsEnabled: false,
    canGoBack: false,
  );
}
