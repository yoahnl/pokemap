import 'package:map_player_ui/personalization_preview.dart';

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
}
