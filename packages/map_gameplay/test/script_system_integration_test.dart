import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final evaluator = const ScriptConditionEvaluator();
  final pageResolver = const EventPageResolver();
  final mutations = const GameStateMutations();

  group('GameState Mutations', () {
    test('setFlag adds flag to activeFlags', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final newState = mutations.setFlag(initialState, 'professor_met');

      expect(newState.storyFlags.activeFlags, contains('professor_met'));
    });

    test('setFlag is idempotent', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'professor_met'}),
      );

      final newState = mutations.setFlag(initialState, 'professor_met');

      expect(newState.storyFlags.activeFlags.length, equals(1));
      expect(newState.storyFlags.activeFlags, contains('professor_met'));
    });

    test('clearFlag removes flag from activeFlags', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'professor_met', 'starter_received'}),
      );

      final newState = mutations.clearFlag(initialState, 'professor_met');

      expect(newState.storyFlags.activeFlags, isNot(contains('professor_met')));
      expect(newState.storyFlags.activeFlags, contains('starter_received'));
    });
  });

  group('ScriptConditionEvaluator', () {
    test('flagIsSet returns true when flag is active', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'professor_met'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.flagIsSet,
        params: {ScriptConditionParams.flagName: 'professor_met'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('flagIsSet returns false when flag is not active', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.flagIsSet,
        params: {ScriptConditionParams.flagName: 'professor_met'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });

    test('flagIsUnset returns true when flag is not active', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.flagIsUnset,
        params: {ScriptConditionParams.flagName: 'professor_met'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('flagIsUnset returns false when flag is active', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'professor_met'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.flagIsUnset,
        params: {ScriptConditionParams.flagName: 'professor_met'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });

    test('allOf returns true when all children are true', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'flag_a', 'flag_b'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.allOf,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_a'},
          ),
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_b'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('allOf returns false when any child is false', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'flag_a'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.allOf,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_a'},
          ),
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_b'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });

    test('anyOf returns true when any child is true', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'flag_a'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.anyOf,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_a'},
          ),
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_b'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('anyOf returns false when all children are false', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.anyOf,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_a'},
          ),
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_b'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });

    test('not inverts condition', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'professor_met'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.not,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'professor_met'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });
  });

  group('EventPageResolver - MVP Scenario', () {
    test('Page 1 active when flag is NOT set', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final event = MapEventDefinition(
        id: 'professor_event',
        title: 'Professor Oak',
        position: const EventPosition(layerId: 'objects', x: 5, y: 5),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsUnset,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Hello! I am Professor Oak!',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Good luck on your journey!',
          ),
        ],
      );

      final activePage = pageResolver.resolve(event, state);

      expect(activePage, isNotNull);
      expect(activePage!.pageIndex, equals(0));
      expect(activePage.page.message, equals('Hello! I am Professor Oak!'));
    });

    test('Page 2 active AFTER flag is set', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final stateWithFlag = mutations.setFlag(initialState, 'professor_met');

      final event = MapEventDefinition(
        id: 'professor_event',
        title: 'Professor Oak',
        position: const EventPosition(layerId: 'objects', x: 5, y: 5),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsUnset,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Hello! I am Professor Oak!',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Good luck on your journey!',
          ),
        ],
      );

      final activePage = pageResolver.resolve(event, stateWithFlag);

      expect(activePage, isNotNull);
      expect(activePage!.pageIndex, equals(1));
      expect(activePage.page.message, equals('Good luck on your journey!'));
    });

    test('Full MVP scenario: Page1 -> Script -> Flag -> Page2', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final event = MapEventDefinition(
        id: 'professor_event',
        title: 'Professor Oak',
        position: const EventPosition(layerId: 'objects', x: 5, y: 5),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsUnset,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            script: const ScriptRef(scriptId: 'professor_intro', startNode: 'start'),
            message: 'Hello! I am Professor Oak!',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Good luck on your journey!',
          ),
        ],
      );

      final script = ScriptAsset(
        id: 'professor_intro',
        defaultStartNode: 'start',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.setFlag,
                params: {'flagName': 'professor_met'},
              ),
              const ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      final activePageBefore = pageResolver.resolve(event, initialState);
      expect(activePageBefore, isNotNull);
      expect(activePageBefore!.pageIndex, equals(0));

      var currentState = initialState;
      for (final command in script.nodes.first.commands) {
        if (command.type == ScriptCommandType.setFlag) {
          currentState = mutations.setFlag(currentState, command.params['flagName']!);
        }
      }

      final activePageAfter = pageResolver.resolve(event, currentState);
      expect(activePageAfter, isNotNull);
      expect(activePageAfter!.pageIndex, equals(1));
      expect(activePageAfter.page.message, equals('Good luck on your journey!'));
    });
  });

  group('ScriptConditionEvaluator with FieldAbility', () {
    test('fieldAbilityUnlocked returns true when ability is unlocked', () {
      final state = GameState(
        saveId: 'test-save',
        progression: const PlayerProgression(unlockedFieldAbilities: [FieldAbility.surf]),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.fieldAbilityUnlocked,
        params: {ScriptConditionParams.ability: 'surf'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('fieldAbilityUnlocked returns false when ability is not unlocked', () {
      final state = GameState(
        saveId: 'test-save',
        progression: const PlayerProgression(unlockedFieldAbilities: []),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.fieldAbilityUnlocked,
        params: {ScriptConditionParams.ability: 'surf'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });
  });

  group('ScriptConditionEvaluator with Party Moves', () {
    test('partyHasUsableMove returns true when party has move', () {
      final state = GameState(
        saveId: 'test-save',
        party: PlayerParty(members: [
          const PlayerPokemon(
            id: 'pikachu_1',
            speciesId: 'pikachu',
            knownMoveIds: ['surf', 'thunderbolt'],
            isFainted: false,
          ),
        ]),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.partyHasUsableMove,
        params: {ScriptConditionParams.moveId: 'surf'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('partyHasUsableMove returns false when only fainted pokemon has move', () {
      final state = GameState(
        saveId: 'test-save',
        party: PlayerParty(members: [
          const PlayerPokemon(
            id: 'pikachu_1',
            speciesId: 'pikachu',
            knownMoveIds: ['surf', 'thunderbolt'],
            isFainted: true,
          ),
        ]),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.partyHasUsableMove,
        params: {ScriptConditionParams.moveId: 'surf'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });
  });
}
