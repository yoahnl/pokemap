import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/runtime_player_options.dart';

void main() {
  group('RuntimePlayerOptions', () {
    test('round-trips supported persisted player preferences', () {
      final options = RuntimePlayerOptions.fromJson(
        const <String, dynamic>{
          'dialogueTextSpeed': 'fast',
          'showTouchControls': false,
        },
      );

      expect(options.dialogueTextSpeed, RuntimeDialogueTextSpeed.fast);
      expect(options.showTouchControls, isFalse);
      expect(
        options.toJson(),
        const <String, dynamic>{
          'dialogueTextSpeed': 'fast',
          'showTouchControls': false,
        },
      );
    });

    test('falls back safely for legacy or malformed preferences', () {
      expect(
        RuntimePlayerOptions.fromJson(null),
        const RuntimePlayerOptions(),
      );
      expect(
        RuntimePlayerOptions.fromJson(
          const <String, dynamic>{
            'dialogueTextSpeed': 'impossible',
            'showTouchControls': 'yes',
          },
        ),
        const RuntimePlayerOptions(),
      );
    });

    test('copyWith changes one option without corrupting the other', () {
      const initial = RuntimePlayerOptions(
        dialogueTextSpeed: RuntimeDialogueTextSpeed.slow,
        showTouchControls: false,
      );

      expect(
        initial.copyWith(dialogueTextSpeed: RuntimeDialogueTextSpeed.fast),
        const RuntimePlayerOptions(
          dialogueTextSpeed: RuntimeDialogueTextSpeed.fast,
          showTouchControls: false,
        ),
      );
    });
  });
}
