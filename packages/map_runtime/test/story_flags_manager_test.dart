import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('StoryFlagsManager', () {
    const manager = StoryFlagsManager();

    test('set and isSet use normalized flag names', () {
      const initial = GameState(saveId: 'save');

      final updated = manager.set(initial, ' professor_met ');

      expect(manager.isSet(updated, 'professor_met'), isTrue);
      expect(manager.isSet(updated, ' professor_met '), isTrue);
      expect(manager.isSet(initial, 'professor_met'), isFalse);
    });

    test('clear removes an active flag', () {
      const initial = GameState(
        saveId: 'save',
        storyFlags: StoryFlags(activeFlags: {'professor_met'}),
      );

      final updated = manager.clear(initial, 'professor_met');

      expect(manager.isUnset(updated, 'professor_met'), isTrue);
    });

    test('trainer helpers keep trainer_defeated naming convention', () {
      expect(
        manager.trainerDefeatedFlag('gym_1'),
        equals('trainer_defeated:gym_1'),
      );
      expect(manager.trainerDefeatedFlag('  '), isEmpty);
    });

    test('markTrainerDefeated and isTrainerDefeated are consistent', () {
      const initial = GameState(saveId: 'save');

      final updated = manager.markTrainerDefeated(initial, 'trainer_007');

      expect(manager.isTrainerDefeated(updated, 'trainer_007'), isTrue);
      expect(manager.isTrainerDefeated(updated, 'trainer_404'), isFalse);
    });
  });
}
