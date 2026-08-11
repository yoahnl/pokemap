import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'personalization_preview_context_source.dart';
import 'personalization_preview_fixtures.dart';

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

  static PlayerBattleViewData? battle(
    PersonalizationPreviewContextOption? context, {
    required PersonalizationBattlePreviewState state,
  }) {
    if (context?.kind != PersonalizationPreviewContextKind.encounter) {
      return null;
    }
    final entries = context?.detail['entries'];
    final playerPokemon = context?.detail['playerPokemon'];
    if (entries is! List || entries.isEmpty || playerPokemon is! Map) {
      return null;
    }
    final enemy = entries.first;
    if (enemy is! Map) return null;
    final enemySpeciesId = enemy['speciesId'];
    final enemyLevel = enemy['minLevel'];
    final playerSpeciesId = playerPokemon['speciesId'];
    final playerLevel = playerPokemon['level'];
    if (enemySpeciesId is! String ||
        enemyLevel is! int ||
        playerSpeciesId is! String ||
        playerLevel is! int) {
      return null;
    }
    final enemySpecies = _displayId(enemySpeciesId);
    final playerSpecies = _displayId(playerSpeciesId);
    final playerCurrentHp = playerPokemon['currentHp'] is int
        ? playerPokemon['currentHp']! as int
        : playerLevel * 4 + 10;
    final knownMoves = switch (playerPokemon['knownMoveIds']) {
      final List values => values.whereType<String>().toList(growable: false),
      _ => const <String>[],
    };
    final template = PersonalizationPreviewFixtures.battleFor(state);
    return PlayerBattleViewData(
      revision: template.revision,
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
          : template.prompt,
      narrationLines: state == PersonalizationBattlePreviewState.message
          ? <String>[
              '$enemySpecies observe $playerSpecies.',
              'Le combat attend la prochaine commande.',
            ]
          : const <String>[],
      commands: _battleCommands(
        state,
        template.commands,
        knownMoves: knownMoves,
        enemySpecies: enemySpecies,
        playerSpecies: playerSpecies,
      ),
      interactionsEnabled:
          template.interactionsEnabled &&
          !(state == PersonalizationBattlePreviewState.moves &&
              knownMoves.isEmpty),
      canGoBack: template.canGoBack,
    );
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

  static List<PlayerBattleCommandViewData> _battleCommands(
    PersonalizationBattlePreviewState state,
    List<PlayerBattleCommandViewData> template, {
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
    _ => template,
  };

  static String _displayId(String value) => value
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
