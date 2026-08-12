import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'personalization_capability_descriptor.dart';
import 'personalization_preview_context_source.dart';

abstract final class PersonalizationProjectPreviewProjection {
  static MapData? map(PersonalizationPreviewContextOption? context) {
    if (context?.kind != PersonalizationPreviewContextKind.map) return null;
    final source = context?.detail['map'];
    if (source is! Map) return null;
    try {
      return MapData.fromJson(Map<String, dynamic>.from(source));
    } on Object {
      return null;
    }
  }

  static PlayerDialogueViewData? dialogue(
    PersonalizationPreviewContextOption? context, {
    PersonalizationPreviewContextOption? portrait,
    required bool showChoices,
  }) {
    if (context?.kind == PersonalizationPreviewContextKind.dialogueScenario) {
      return _dialogueScenario(context!);
    }
    if (context?.kind != PersonalizationPreviewContextKind.dialogue) {
      return null;
    }
    final dialogue = context?.detail['dialogue'];
    if (dialogue is! Map) return null;
    final source = dialogue['source'];
    if (source is! Map || source['text'] is! String) return null;
    try {
      final document = const YarnDialogueCompiler().compile(
        source['text']! as String,
      );
      final steps = document.nodes.first.steps;
      final line = steps.whereType<RuntimeDialogueLine>().firstOrNull;
      final choices = steps.whereType<RuntimeDialogueChoiceBlock>().firstOrNull;
      if (showChoices && choices != null) {
        return PlayerDialogueViewData(
          revision: 2,
          mode: PlayerDialogueMode.choices,
          speaker: null,
          text: '',
          fullText: '',
          isCurrentLineFullyRevealed: true,
          isLastContent: false,
          choices: <PlayerDialogueChoiceViewData>[
            for (var index = 0; index < choices.choices.length; index++)
              PlayerDialogueChoiceViewData(
                index: index,
                label: choices.choices[index].text,
                selected: index == 0,
              ),
          ],
        );
      }
      if (line == null) return null;
      return PlayerDialogueViewData(
        revision: 1,
        mode: PlayerDialogueMode.line,
        speaker: _speakerName(line, portrait),
        text: line.text,
        fullText: line.text,
        isCurrentLineFullyRevealed: true,
        isLastContent: steps.last == line,
        choices: const <PlayerDialogueChoiceViewData>[],
      );
    } on Object {
      return null;
    }
  }

  static PlayerDialogueViewData? _dialogueScenario(
    PersonalizationPreviewContextOption context,
  ) {
    final kind = context.detail['scenarioKind'];
    final stepIndex = context.detail['stepIndex'];
    final revision = stepIndex is int ? stepIndex + 1 : 1;
    if (kind == 'choice') {
      final rawChoices = context.detail['choices'];
      if (rawChoices is! List || rawChoices.isEmpty) return null;
      final labels = <String>[];
      for (final raw in rawChoices) {
        if (raw is! Map || raw['label'] is! String) return null;
        labels.add(raw['label']! as String);
      }
      return PlayerDialogueViewData(
        revision: revision,
        mode: PlayerDialogueMode.choices,
        speaker: null,
        text: '',
        fullText: '',
        isCurrentLineFullyRevealed: true,
        isLastContent: false,
        choices: <PlayerDialogueChoiceViewData>[
          for (var index = 0; index < labels.length; index++)
            PlayerDialogueChoiceViewData(
              index: index,
              label: labels[index],
              selected: index == 0,
            ),
        ],
      );
    }
    if (kind != 'characterLine' && kind != 'textLine') return null;
    final text = context.detail['text'];
    if (text is! String || text.trim().isEmpty) return null;
    final characterName = context.detail['characterName'];
    final characterId = context.detail['characterId'];
    return PlayerDialogueViewData(
      revision: revision,
      mode: PlayerDialogueMode.line,
      speaker: characterName is String && characterName.trim().isNotEmpty
          ? characterName
          : characterId is String
          ? _displayId(characterId)
          : null,
      text: text,
      fullText: text,
      isCurrentLineFullyRevealed: true,
      isLastContent: true,
      choices: const <PlayerDialogueChoiceViewData>[],
    );
  }

  static PlayerBattleViewData? battle(
    PersonalizationPreviewContextOption? context, {
    required PersonalizationBattlePreviewState state,
    ProjectBattlePresentationProfile? presentation,
    String? enemySpeciesId,
    String? playerSpeciesId,
  }) {
    if (context?.kind != PersonalizationPreviewContextKind.encounter) {
      return null;
    }
    final entries = context?.detail['entries'];
    final playerPokemonOptions = context?.detail['playerPokemonOptions'];
    final fallbackPlayerPokemon = context?.detail['playerPokemon'];
    if (entries is! List || entries.isEmpty) {
      return null;
    }
    final enemy = _battleOption(entries, enemySpeciesId);
    final playerPokemon =
        _battleOption(playerPokemonOptions, playerSpeciesId) ??
        (fallbackPlayerPokemon is Map ? fallbackPlayerPokemon : null);
    if (enemy == null || playerPokemon == null) return null;
    final resolvedEnemySpeciesId = enemy['speciesId'];
    final enemyLevel = enemy['minLevel'];
    final resolvedPlayerSpeciesId = playerPokemon['speciesId'];
    final playerLevel = playerPokemon['level'];
    if (resolvedEnemySpeciesId is! String ||
        enemyLevel is! int ||
        resolvedPlayerSpeciesId is! String ||
        playerLevel is! int) {
      return null;
    }
    final enemySpecies = enemy['displayName'] is String
        ? enemy['displayName']! as String
        : _displayId(resolvedEnemySpeciesId);
    final playerSpecies = playerPokemon['displayName'] is String
        ? playerPokemon['displayName']! as String
        : _displayId(resolvedPlayerSpeciesId);
    final playerCurrentHp = playerPokemon['currentHp'] is int
        ? playerPokemon['currentHp']! as int
        : playerLevel * 4 + 10;
    final knownMoves = switch (playerPokemon['knownMoveIds']) {
      final List values => values.whereType<String>().toList(growable: false),
      _ => const <String>[],
    };
    return PlayerBattleViewData(
      revision: state.index + 1,
      enemy: PlayerBattleHudViewData(
        ownerLabel: 'SAUVAGE',
        speciesLabel: enemySpecies,
        level: enemyLevel,
        currentHp: enemyLevel * 4 + 10,
        maxHp: enemyLevel * 4 + 10,
      ),
      player: PlayerBattleHudViewData(
        ownerLabel: 'JOUEUR',
        speciesLabel: playerSpecies,
        level: playerLevel,
        currentHp: playerCurrentHp,
        maxHp: playerCurrentHp,
      ),
      battleLabel: context!.label,
      title: _battleTitle(state, playerSpecies),
      prompt:
          state == PersonalizationBattlePreviewState.moves && knownMoves.isEmpty
          ? 'Aucune capacité n’est configurée pour ce Pokémon.'
          : _battlePrompt(state),
      narrationLines: state == PersonalizationBattlePreviewState.message
          ? <String>[
              '$enemySpecies observe $playerSpecies.',
              'Le combat attend la prochaine commande.',
            ]
          : const <String>[],
      commands: _battleCommands(
        state,
        presentation,
        knownMoves: knownMoves,
        enemySpecies: enemySpecies,
        playerSpecies: playerSpecies,
      ),
      interactionsEnabled:
          state != PersonalizationBattlePreviewState.message &&
          !(state == PersonalizationBattlePreviewState.moves &&
              knownMoves.isEmpty),
      canGoBack:
          state == PersonalizationBattlePreviewState.moves ||
          state == PersonalizationBattlePreviewState.target,
      panelKind: switch (state) {
        PersonalizationBattlePreviewState.commands =>
          PlayerBattlePanelKind.commands,
        PersonalizationBattlePreviewState.moves => PlayerBattlePanelKind.moves,
        PersonalizationBattlePreviewState.target =>
          PlayerBattlePanelKind.target,
        PersonalizationBattlePreviewState.message =>
          PlayerBattlePanelKind.message,
      },
    );
  }

  static ({String? enemy, String? player}) battleSpritePaths(
    PersonalizationPreviewContextOption? context, {
    String? enemySpeciesId,
    String? playerSpeciesId,
  }) {
    if (context?.kind != PersonalizationPreviewContextKind.encounter) {
      return (enemy: null, player: null);
    }
    final entries = context?.detail['entries'];
    final playerPokemonOptions = context?.detail['playerPokemonOptions'];
    final fallbackPlayerPokemon = context?.detail['playerPokemon'];
    final enemy =
        _battleOption(entries, enemySpeciesId)?['battleSpritePath'] as String?;
    final playerPokemon =
        _battleOption(playerPokemonOptions, playerSpeciesId) ??
        (fallbackPlayerPokemon is Map ? fallbackPlayerPokemon : null);
    final player = playerPokemon?['battleSpritePath'] as String?;
    return (enemy: enemy, player: player);
  }

  static Map<Object?, Object?>? _battleOption(
    Object? values,
    String? speciesId,
  ) {
    if (values is! List) return null;
    final options = values.whereType<Map>().toList(growable: false);
    if (options.isEmpty) return null;
    return options
            .where((option) => option['speciesId'] == speciesId)
            .firstOrNull ??
        options.first;
  }

  static String? battleBackdropPath(
    MapData? map,
    PersonalizationPreviewContextOption? encounter,
  ) {
    if (map == null ||
        encounter?.kind != PersonalizationPreviewContextKind.encounter) {
      return null;
    }
    final declaredTableId = encounter?.detail['encounterTableId'];
    final tableId =
        declaredTableId is String && declaredTableId.trim().isNotEmpty
        ? declaredTableId
        : encounter?.sourceId;
    if (tableId == null) return null;
    for (final zone in map.gameplayZones) {
      final payload = zone.encounter;
      if (payload?.encounterTableId != tableId) continue;
      final path = payload?.battleBackgroundRelativePath?.trim();
      if (path != null && path.isNotEmpty) return path;
    }
    return null;
  }

  static String? _speakerName(
    RuntimeDialogueLine line,
    PersonalizationPreviewContextOption? portrait,
  ) {
    final characterName = portrait?.detail['characterName'];
    if (characterName is String && characterName.trim().isNotEmpty) {
      return characterName;
    }
    final characterId = line.characterId;
    return characterId == null ? null : _displayId(characterId);
  }

  static String _battleTitle(
    PersonalizationBattlePreviewState state,
    String playerSpecies,
  ) => switch (state) {
    PersonalizationBattlePreviewState.commands =>
      'Que doit faire $playerSpecies ?',
    PersonalizationBattlePreviewState.moves => 'Capacités de $playerSpecies',
    PersonalizationBattlePreviewState.target => 'Choisissez une cible',
    PersonalizationBattlePreviewState.message => 'Le combat continue',
  };

  static String _battlePrompt(PersonalizationBattlePreviewState state) =>
      switch (state) {
        PersonalizationBattlePreviewState.commands => 'Choisissez une action.',
        PersonalizationBattlePreviewState.moves => 'Choisissez une capacité.',
        PersonalizationBattlePreviewState.target =>
          'Qui doit recevoir cette capacité ?',
        PersonalizationBattlePreviewState.message =>
          'Le combat attend la prochaine commande.',
      };

  static List<PlayerBattleCommandViewData> _battleCommands(
    PersonalizationBattlePreviewState state,
    ProjectBattlePresentationProfile? presentation, {
    required List<String> knownMoves,
    required String enemySpecies,
    required String playerSpecies,
  }) => switch (state) {
    PersonalizationBattlePreviewState.moves => <PlayerBattleCommandViewData>[
      for (var index = 0; index < knownMoves.length; index++)
        PlayerBattleCommandViewData(
          index: index,
          primaryLabel: _displayId(knownMoves[index]),
          secondaryLabel: 'Capacité du projet',
          enabled: true,
          selected: index == 0,
          tone: PlayerBattleEntryTone.attack,
        ),
    ],
    PersonalizationBattlePreviewState.target => <PlayerBattleCommandViewData>[
      PlayerBattleCommandViewData(
        index: 0,
        primaryLabel: '$enemySpecies adverse',
        secondaryLabel: 'Cible valide',
        enabled: true,
        selected: true,
        tone: PlayerBattleEntryTone.attack,
      ),
      PlayerBattleCommandViewData(
        index: 1,
        primaryLabel: '$playerSpecies allié',
        secondaryLabel: 'Cible invalide',
        enabled: false,
        selected: false,
        tone: PlayerBattleEntryTone.disabled,
      ),
    ],
    PersonalizationBattlePreviewState.commands => _projectBattleCommands(
      presentation,
    ),
    PersonalizationBattlePreviewState.message =>
      const <PlayerBattleCommandViewData>[],
  };

  static List<PlayerBattleCommandViewData> _projectBattleCommands(
    ProjectBattlePresentationProfile? presentation,
  ) {
    final commands =
        presentation?.effectiveCommands ?? defaultProjectBattleCommands;
    return <PlayerBattleCommandViewData>[
      for (var index = 0; index < commands.length; index++)
        PlayerBattleCommandViewData(
          index: index,
          primaryLabel:
              commands[index].label ?? _battleCommandLabel(commands[index].id),
          secondaryLabel: _battleCommandDescription(commands[index].id),
          enabled: true,
          selected: index == 0,
          tone: switch (commands[index].id) {
            ProjectBattleCommandId.fight => PlayerBattleEntryTone.attack,
            ProjectBattleCommandId.bag => PlayerBattleEntryTone.medicine,
            ProjectBattleCommandId.party => PlayerBattleEntryTone.switching,
            ProjectBattleCommandId.run => PlayerBattleEntryTone.neutral,
          },
          commandId: commands[index].id,
          commandIcon: commands[index].icon,
        ),
    ];
  }

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
        ProjectBattleCommandId.party => 'Changer de Pokémon',
        ProjectBattleCommandId.run => 'Quitter le combat',
      };

  static String _displayId(String value) => value
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
