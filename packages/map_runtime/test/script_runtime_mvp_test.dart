import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('Script Runtime MVP Tests', () {
    late List<String> executedCommands;
    late GameState lastGameState;

    setUp(() {
      executedCommands = [];
      lastGameState = const GameState(saveId: 'test-save');
    });

    ScriptExecutionContext createTestContext() {
      return ScriptExecutionContext(
        gameState: lastGameState,
        onGameStateUpdated: (state) {
          lastGameState = state;
        },
        onDialogueOpened: (dialogue) {
          executedCommands.add('dialogue:${dialogue.filePath}');
        },
        onWarpRequested: (mapId, x, y) {
          executedCommands.add('warp:$mapId:$x:$y');
        },
      );
    }

    group('ScriptCommandExecutor', () {
      test('setFlag command executes and updates state', () {
        final context = createTestContext();
        final executor = ScriptCommandExecutor(context: context);

        const command = ScriptCommand(
          type: ScriptCommandType.setFlag,
          params: {'flagName': 'professor_met'},
        );

        final result = executor.execute(command, context.gameState);

        expect(result, isA<ScriptCommandResultCompleted>());
        expect(lastGameState.storyFlags.activeFlags, contains('professor_met'));
      });

      test('goto command returns jump result', () {
        final context = createTestContext();
        final executor = ScriptCommandExecutor(context: context);

        const command = ScriptCommand(
          type: ScriptCommandType.goto,
          params: {'nodeId': 'node_2'},
        );

        final result = executor.execute(command, context.gameState);

        expect(result, isA<ScriptCommandResultJumpToNode>());
        expect(
            (result as ScriptCommandResultJumpToNode).nodeId, equals('node_2'));
      });

      test('end command returns terminated result', () {
        final context = createTestContext();
        final executor = ScriptCommandExecutor(context: context);

        const command = ScriptCommand(type: ScriptCommandType.end);
        final result = executor.execute(command, context.gameState);

        expect(result, isA<ScriptCommandResultTerminated>());
      });

      test('openDialogue command suspends with dialogue ref', () {
        final context = createTestContext();
        final executor = ScriptCommandExecutor(context: context);

        const command = ScriptCommand(
          type: ScriptCommandType.openDialogue,
          params: {
            'filePath': 'scripts/professor.yarn',
            'startNode': 'greeting'
          },
        );

        final result = executor.execute(command, context.gameState);

        expect(result, isA<ScriptCommandResultSuspended>());
        final suspended = result as ScriptCommandResultSuspended;
        expect(
            suspended.reason, equals(ScriptSuspendReason.waitingForDialogue));
        expect(suspended.dialogue?.filePath, equals('scripts/professor.yarn'));
        expect(suspended.dialogue?.startNode, equals('greeting'));
        expect(executedCommands, contains('dialogue:scripts/professor.yarn'));
      });

      test('warpPlayer command updates state and notifies', () {
        final context = createTestContext();
        final executor = ScriptCommandExecutor(context: context);

        const command = ScriptCommand(
          type: ScriptCommandType.warpPlayer,
          params: {
            'mapId': 'pallet_town',
            'x': '10',
            'y': '5',
            'facing': 'south'
          },
        );

        final result = executor.execute(command, context.gameState);

        expect(result, isA<ScriptCommandResultCompleted>());
        expect(lastGameState.currentMapId, equals('pallet_town'));
        expect(lastGameState.playerPosition.x, equals(10));
        expect(lastGameState.playerPosition.y, equals(5));
        expect(executedCommands, contains('warp:pallet_town:10:5'));
      });

      test('warpPlayer keeps state unchanged when runtime rejects handoff', () {
        lastGameState = const GameState(
          saveId: 'test-save',
          currentMapId: 'source_map',
          playerPosition: GridPos(x: 2, y: 3),
        );
        final context = ScriptExecutionContext(
          gameState: lastGameState,
          onGameStateUpdated: (state) => lastGameState = state,
          onWarpRequested: (_, __, ___) {
            throw StateError('warp queue already owned');
          },
        );
        final executor = ScriptCommandExecutor(context: context);
        const command = ScriptCommand(
          type: ScriptCommandType.warpPlayer,
          params: <String, String>{
            'mapId': 'rejected_target',
            'x': '8',
            'y': '9',
          },
        );

        expect(
          () => executor.execute(command, context.gameState),
          throwsStateError,
        );
        expect(lastGameState.currentMapId, 'source_map');
        expect(lastGameState.playerPosition, const GridPos(x: 2, y: 3));
      });

      test('giveItem rejects a non-positive quantity without committing', () {
        var updateCount = 0;
        final context = ScriptExecutionContext(
          gameState: lastGameState,
          onGameStateUpdated: (state) {
            updateCount += 1;
            lastGameState = state;
          },
        );
        final executor = ScriptCommandExecutor(context: context);
        const command = ScriptCommand(
          type: ScriptCommandType.giveItem,
          params: <String, String>{
            'itemId': 'custom-passive-thread',
            'quantity': '0',
          },
        );

        final result = executor.execute(command, context.gameState);

        expect(result, isA<ScriptCommandResultError>());
        expect(updateCount, 0);
        expect(lastGameState.bag.entries, isEmpty);
      });

      test('unlockFieldAbility command updates progression', () {
        final context = createTestContext();
        final executor = ScriptCommandExecutor(context: context);

        const command = ScriptCommand(
          type: ScriptCommandType.unlockFieldAbility,
          params: {'ability': 'surf'},
        );

        final result = executor.execute(command, context.gameState);

        expect(result, isA<ScriptCommandResultCompleted>());
        expect(lastGameState.progression.unlockedFieldAbilities,
            contains(FieldAbility.surf));
      });
    });

    group('ScriptRuntimeController - MVP Scenario', () {
      test('Full script execution: setFlag -> end', () {
        const script = ScriptAsset(
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
                ScriptCommand(type: ScriptCommandType.end),
              ],
            ),
          ],
        );

        final context = createTestContext();
        final controller = ScriptRuntimeController(
          script: script,
          context: context,
        );

        expect(controller.isTerminated, isFalse);
        expect(controller.isSuspended, isFalse);
        expect(controller.currentNodeId, equals('start'));

        var result = controller.step();
        expect(result, isA<ScriptCommandResultCompleted>());
        expect(lastGameState.storyFlags.activeFlags, contains('professor_met'));

        result = controller.step();
        expect(result, isA<ScriptCommandResultTerminated>());
        expect(controller.isTerminated, isTrue);
      });

      test('Script with dialogue suspension', () {
        const script = ScriptAsset(
          id: 'dialogue_test',
          defaultStartNode: 'start',
          nodes: [
            ScriptNode(
              id: 'start',
              commands: [
                ScriptCommand(
                  type: ScriptCommandType.openDialogue,
                  params: {'filePath': 'test.yarn'},
                ),
              ],
            ),
          ],
        );

        final context = createTestContext();
        final controller = ScriptRuntimeController(
          script: script,
          context: context,
        );

        final result = controller.step();
        expect(result, isA<ScriptCommandResultSuspended>());
        expect(controller.isSuspended, isTrue);
        expect(executedCommands, contains('dialogue:test.yarn'));
      });

      test('Script command chain uses latest GameState between steps', () {
        const script = ScriptAsset(
          id: 'state_chain_test',
          defaultStartNode: 'start',
          nodes: [
            ScriptNode(
              id: 'start',
              commands: [
                ScriptCommand(
                  type: ScriptCommandType.setVariable,
                  params: {
                    'variableName': 'wins',
                    'value': '1',
                    'type': 'int',
                  },
                ),
                ScriptCommand(
                  type: ScriptCommandType.incrementVariable,
                  params: {
                    'variableName': 'wins',
                    'delta': '1',
                  },
                ),
                ScriptCommand(type: ScriptCommandType.end),
              ],
            ),
          ],
        );

        final context = createTestContext();
        final controller = ScriptRuntimeController(
          script: script,
          context: context,
        );

        while (!controller.isTerminated) {
          controller.step();
        }

        final winsValue = lastGameState.scriptVariables.values['wins'];
        expect(winsValue, isA<ScriptVariableValueInt>());
        final winsInt = winsValue as ScriptVariableValueInt;
        expect(winsInt.value, equals(2));
      });

      test('Complete MVP scenario: Page1 -> Script -> Flag -> Page2', () {
        const event = MapEventDefinition(
          id: 'professor_event',
          title: 'Professor Oak',
          position: EventPosition(layerId: 'objects', x: 5, y: 5),
          pages: [
            MapEventPage(
              pageNumber: 0,
              condition: ScriptCondition(
                type: ScriptConditionType.flagIsUnset,
                params: {ScriptConditionParams.flagName: 'professor_met'},
              ),
              script:
                  ScriptRef(scriptId: 'professor_intro', startNode: 'start'),
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

        const script = ScriptAsset(
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
                ScriptCommand(type: ScriptCommandType.end),
              ],
            ),
          ],
        );

        const pageResolver = EventPageResolver();
        var gameState = const GameState(saveId: 'test-save');

        final pageBefore = pageResolver.resolve(event, gameState);
        expect(pageBefore, isNotNull);
        expect(pageBefore!.pageIndex, equals(0));

        final context = ScriptExecutionContext(
          gameState: gameState,
          onGameStateUpdated: (state) {
            gameState = state;
          },
        );

        final controller = ScriptRuntimeController(
          script: script,
          context: context,
        );

        while (!controller.isTerminated) {
          controller.step();
        }

        expect(gameState.storyFlags.activeFlags, contains('professor_met'));

        final pageAfter = pageResolver.resolve(event, gameState);
        expect(pageAfter, isNotNull);
        expect(pageAfter!.pageIndex, equals(1));
        expect(pageAfter.page.message, equals('Good luck on your journey!'));
      });
    });
  });
}
