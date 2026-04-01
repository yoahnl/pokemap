import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimeStoryBranching', () {
    const branching = RuntimeStoryBranching();

    GameState runEventScriptToCompletion({
      required ScriptAsset script,
      required GameState initialState,
    }) {
      var currentState = initialState;
      final context = ScriptExecutionContext(
        gameState: currentState,
        onGameStateUpdated: (state) {
          currentState = state;
        },
      );
      final controller = ScriptRuntimeController(
        script: script,
        context: context,
      );
      while (!controller.isTerminated && !controller.isSuspended) {
        controller.step();
      }
      return currentState;
    }

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

    test('event page rebranches after script sets variable used by condition',
        () {
      final event = MapEventDefinition(
        id: 'variable_event',
        title: 'Variable Event',
        position: const EventPosition(layerId: 'objects', x: 3, y: 2),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScenarioConditions.variableEqualsInt('progress', 0),
            script: const ScriptRef(scriptId: 'progress_script'),
            message: 'Start',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScenarioConditions.variableGreaterThan('progress', 0),
            message: 'After Progress',
          ),
        ],
      );

      final script = ScriptAsset(
        id: 'progress_script',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.setVariable,
                params: {
                  'variableName': 'progress',
                  'value': '1',
                  'type': 'int',
                },
              ),
              const ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      const initialState = GameState(
        saveId: 'save',
        scriptVariables: ScriptVariables(
          values: {'progress': ScriptVariableValue.int(0)},
        ),
      );

      final pageBefore = branching.resolveEventPage(event, initialState);
      expect(pageBefore, isNotNull);
      expect(pageBefore!.pageIndex, equals(0));

      final updatedState = runEventScriptToCompletion(
        script: script,
        initialState: initialState,
      );

      final pageAfter = branching.resolveEventPage(event, updatedState);
      expect(pageAfter, isNotNull);
      expect(pageAfter!.pageIndex, equals(1));
    });

    test('event page rebranches after script marks event as consumed', () {
      final event = MapEventDefinition(
        id: 'consumable_event',
        title: 'Consumable Event',
        position: const EventPosition(layerId: 'objects', x: 1, y: 1),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScenarioConditions.eventIsConsumed('event:gift'),
            message: 'Already Collected',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScenarioConditions.not(
              ScenarioConditions.eventIsConsumed('event:gift'),
            ),
            script: const ScriptRef(scriptId: 'consume_script'),
            message: 'Collect Gift',
          ),
        ],
      );

      final script = ScriptAsset(
        id: 'consume_script',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.markEventConsumed,
                params: {'eventId': 'event:gift'},
              ),
              const ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      const initialState = GameState(saveId: 'save');

      final pageBefore = branching.resolveEventPage(event, initialState);
      expect(pageBefore, isNotNull);
      expect(pageBefore!.pageIndex, equals(1));

      final updatedState = runEventScriptToCompletion(
        script: script,
        initialState: initialState,
      );

      final pageAfter = branching.resolveEventPage(event, updatedState);
      expect(pageAfter, isNotNull);
      expect(pageAfter!.pageIndex, equals(0));
    });

    test('one-shot event has no active page after consumption', () {
      final event = MapEventDefinition(
        id: 'one_shot_event',
        title: 'One Shot Event',
        position: const EventPosition(layerId: 'objects', x: 2, y: 2),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScenarioConditions.not(
              ScenarioConditions.eventIsConsumed('event:one_shot'),
            ),
            script: const ScriptRef(scriptId: 'one_shot_script'),
            message: 'First Interaction',
          ),
        ],
      );

      final script = ScriptAsset(
        id: 'one_shot_script',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.markEventConsumed,
                params: {'eventId': 'event:one_shot'},
              ),
              const ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      const initialState = GameState(saveId: 'save');

      final pageBefore = branching.resolveEventPage(event, initialState);
      expect(pageBefore, isNotNull);
      expect(pageBefore!.pageIndex, equals(0));

      final updatedState = runEventScriptToCompletion(
        script: script,
        initialState: initialState,
      );

      final pageAfter = branching.resolveEventPage(event, updatedState);
      expect(pageAfter, isNull);
    });
  });
}
