import 'package:flutter_test/flutter_test.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/field_move_dialogue.dart';
import 'package:map_runtime/src/application/movement_feedback.dart';
import 'package:map_runtime/src/player/runtime_player_feedback.dart';

void main() {
  group('movement feedback', () {
    test('returns surf feedback for waterRequiresSurf reason', () {
      expect(
        runtimeMovementBlockedMessage(
          GameplayMovementBlockReason.waterRequiresSurf,
        ),
        waterRequiresSurfFeedbackMessage,
      );
    });

    test('returns null for generic solid and out-of-bounds reasons', () {
      expect(
        runtimeMovementBlockedMessage(GameplayMovementBlockReason.solid),
        isNull,
      );
      expect(
        runtimeMovementBlockedMessage(GameplayMovementBlockReason.outOfBounds),
        isNull,
      );
    });

    test('localizes the Surf dialogue without changing its choice order', () {
      final dialogue = loadSurfDialogueSession(
        'Yes_Surf',
        uiLocale: 'en',
        localizer: (locale, key, _) {
          expect(locale, 'en');
          return switch (key) {
            RuntimeOverworldFeedback.surfConfirm =>
              'Would you like to use Surf?',
            RuntimeOverworldFeedback.yes => 'Yes',
            RuntimeOverworldFeedback.no => 'No',
            _ => null,
          };
        },
      )!;
      expect(
        (dialogue.state as DialogueShowingLine).text,
        'Would you like to use Surf?',
      );
      final choices = dialogue.advance()!.state as DialogueWaitingForChoice;
      expect(choices.choices.map((choice) => choice.text), ['Yes', 'No']);
      expect(choices.selectedIndex, 0);
    });
  });
}
