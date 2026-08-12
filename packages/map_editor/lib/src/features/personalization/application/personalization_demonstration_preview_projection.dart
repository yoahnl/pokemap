import 'package:map_core/map_core.dart';
import 'package:map_player_ui/personalization_preview.dart';

import 'personalization_capability_descriptor.dart';

abstract final class PersonalizationDemonstrationPreviewProjection {
  static PlayerDialogueViewData dialogue({required bool showChoices}) {
    if (showChoices) {
      return const PlayerDialogueViewData(
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
            label: 'Premier choix',
            selected: true,
          ),
          PlayerDialogueChoiceViewData(
            index: 1,
            label: 'Deuxième choix',
            selected: false,
          ),
        ],
      );
    }
    return const PlayerDialogueViewData(
      revision: 1,
      mode: PlayerDialogueMode.line,
      speaker: 'Personnage',
      text: 'Voici comment votre dialogue apparaîtra dans le jeu.',
      fullText: 'Voici comment votre dialogue apparaîtra dans le jeu.',
      isCurrentLineFullyRevealed: true,
      isLastContent: true,
      choices: <PlayerDialogueChoiceViewData>[],
    );
  }

  static PlayerBattleViewData battle({
    required PersonalizationBattlePreviewState state,
    ProjectBattlePresentationProfile? presentation,
  }) => PlayerBattleViewData(
    revision: state.index + 1,
    enemy: const PlayerBattleHudViewData(
      ownerLabel: 'ADVERSAIRE',
      speciesLabel: 'Créature adverse',
      level: 7,
      currentHp: 26,
      maxHp: 38,
    ),
    player: const PlayerBattleHudViewData(
      ownerLabel: 'JOUEUR',
      speciesLabel: 'Partenaire',
      level: 8,
      currentHp: 30,
      maxHp: 42,
    ),
    battleLabel: 'Démonstration',
    title: switch (state) {
      PersonalizationBattlePreviewState.commands =>
        'Que doit faire votre partenaire ?',
      PersonalizationBattlePreviewState.moves => 'Choisissez une capacité',
      PersonalizationBattlePreviewState.target => 'Choisissez une cible',
      PersonalizationBattlePreviewState.message => 'Le combat continue',
    },
    prompt: switch (state) {
      PersonalizationBattlePreviewState.commands => 'Choisissez une action.',
      PersonalizationBattlePreviewState.moves => 'Choisissez une capacité.',
      PersonalizationBattlePreviewState.target =>
        'Qui doit recevoir cette capacité ?',
      PersonalizationBattlePreviewState.message =>
        'Le combat attend la prochaine commande.',
    },
    narrationLines: state == PersonalizationBattlePreviewState.message
        ? const <String>[
            'La créature adverse observe votre partenaire.',
            'Le combat attend la prochaine commande.',
          ]
        : const <String>[],
    commands: _battleCommands(state, presentation),
    interactionsEnabled: state != PersonalizationBattlePreviewState.message,
    canGoBack:
        state == PersonalizationBattlePreviewState.moves ||
        state == PersonalizationBattlePreviewState.target,
    panelKind: switch (state) {
      PersonalizationBattlePreviewState.commands =>
        PlayerBattlePanelKind.commands,
      PersonalizationBattlePreviewState.moves => PlayerBattlePanelKind.moves,
      PersonalizationBattlePreviewState.target => PlayerBattlePanelKind.target,
      PersonalizationBattlePreviewState.message =>
        PlayerBattlePanelKind.message,
    },
  );

  static List<PlayerBattleCommandViewData> _battleCommands(
    PersonalizationBattlePreviewState state,
    ProjectBattlePresentationProfile? presentation,
  ) => switch (state) {
    PersonalizationBattlePreviewState.commands => _commandEntries(presentation),
    PersonalizationBattlePreviewState.moves =>
      const <PlayerBattleCommandViewData>[
        PlayerBattleCommandViewData(
          index: 0,
          primaryLabel: 'Capacité rapide',
          secondaryLabel: 'Type démonstration',
          enabled: true,
          selected: true,
          tone: PlayerBattleEntryTone.attack,
        ),
        PlayerBattleCommandViewData(
          index: 1,
          primaryLabel: 'Capacité de soutien',
          secondaryLabel: 'Type démonstration',
          enabled: true,
          selected: false,
          tone: PlayerBattleEntryTone.support,
        ),
      ],
    PersonalizationBattlePreviewState.target =>
      const <PlayerBattleCommandViewData>[
        PlayerBattleCommandViewData(
          index: 0,
          primaryLabel: 'Créature adverse',
          secondaryLabel: 'Cible valide',
          enabled: true,
          selected: true,
          tone: PlayerBattleEntryTone.attack,
        ),
        PlayerBattleCommandViewData(
          index: 1,
          primaryLabel: 'Partenaire allié',
          secondaryLabel: 'Cible invalide',
          enabled: false,
          selected: false,
          tone: PlayerBattleEntryTone.disabled,
        ),
      ],
    PersonalizationBattlePreviewState.message =>
      const <PlayerBattleCommandViewData>[],
  };

  static List<PlayerBattleCommandViewData> _commandEntries(
    ProjectBattlePresentationProfile? presentation,
  ) {
    final commands =
        presentation?.effectiveCommands ?? defaultProjectBattleCommands;
    return <PlayerBattleCommandViewData>[
      for (var index = 0; index < commands.length; index++)
        _battleCommand(index, commands[index]),
    ];
  }

  static PlayerBattleCommandViewData _battleCommand(
    int index,
    ProjectBattleCommandProfile command,
  ) => PlayerBattleCommandViewData(
    index: index,
    primaryLabel: command.label ?? _battleCommandLabel(command.id),
    secondaryLabel: _battleCommandDescription(command.id),
    enabled: true,
    selected: index == 0,
    tone: switch (command.id) {
      ProjectBattleCommandId.fight => PlayerBattleEntryTone.attack,
      ProjectBattleCommandId.bag => PlayerBattleEntryTone.medicine,
      ProjectBattleCommandId.party => PlayerBattleEntryTone.switching,
      ProjectBattleCommandId.run => PlayerBattleEntryTone.neutral,
    },
    commandId: command.id,
    commandIcon: command.icon,
  );

  static String _battleCommandLabel(ProjectBattleCommandId id) => switch (id) {
    ProjectBattleCommandId.fight => 'ATTAQUER',
    ProjectBattleCommandId.bag => 'SAC',
    ProjectBattleCommandId.party => 'ÉQUIPE',
    ProjectBattleCommandId.run => 'FUITE',
  };

  static String _battleCommandDescription(ProjectBattleCommandId id) =>
      switch (id) {
        ProjectBattleCommandId.fight => 'Choisir une capacité',
        ProjectBattleCommandId.bag => 'Utiliser un objet',
        ProjectBattleCommandId.party => 'Changer de partenaire',
        ProjectBattleCommandId.run => 'Quitter le combat',
      };
}
