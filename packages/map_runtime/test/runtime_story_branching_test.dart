import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimeStoryBranching', () {
    const branching = RuntimeStoryBranching();

    test('resolveEventPage picks first page when trainer is not defeated', () {
      final event = MapEventDefinition(
        id: 'trainer_event',
        title: 'Trainer Event',
        position: const EventPosition(layerId: 'objects', x: 4, y: 7),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScenarioConditions.trainerNotDefeated('trainer_1'),
            message: 'Let us battle!',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScenarioConditions.trainerDefeated('trainer_1'),
            message: 'I already lost...',
          ),
        ],
      );

      const state = GameState(saveId: 'save');

      final page = branching.resolveEventPage(event, state);
      expect(page, isNotNull);
      expect(page!.pageIndex, equals(0));
      expect(page.page.message, equals('Let us battle!'));
    });

    test('resolveEventPage switches branch when trainer is defeated', () {
      final event = MapEventDefinition(
        id: 'trainer_event',
        title: 'Trainer Event',
        position: const EventPosition(layerId: 'objects', x: 4, y: 7),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScenarioConditions.trainerNotDefeated('trainer_1'),
            message: 'Let us battle!',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScenarioConditions.trainerDefeated('trainer_1'),
            message: 'I already lost...',
          ),
        ],
      );

      const state = GameState(
        saveId: 'save',
        storyFlags: StoryFlags(activeFlags: {'trainer_defeated:trainer_1'}),
      );

      final page = branching.resolveEventPage(event, state);
      expect(page, isNotNull);
      expect(page!.pageIndex, equals(1));
      expect(page.page.message, equals('I already lost...'));
    });

    test('canTriggerTrainerBattle uses scenario condition evaluation', () {
      const undefeatedState = GameState(saveId: 'save');
      const defeatedState = GameState(
        saveId: 'save',
        storyFlags: StoryFlags(activeFlags: {'trainer_defeated:trainer_9'}),
      );

      expect(
        branching.canTriggerTrainerBattle(undefeatedState, 'trainer_9'),
        isTrue,
      );
      expect(
        branching.canTriggerTrainerBattle(defeatedState, 'trainer_9'),
        isFalse,
      );
    });
  });
}
