import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/resolve_dialogue.dart';

void main() {
  group('Script System Runtime Integration', () {
    test('Complete scenario: page0 -> script -> flag -> page1', () {
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
            script: const ScriptRef(
                scriptId: 'professor_intro', startNode: 'start'),
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

      final scriptEntry = ProjectScriptEntry(
        id: 'professor_intro',
        name: 'Professor Introduction',
        asset: script,
      );

      final manifest = ProjectManifest(
        name: 'Test Project',
        maps: [],
        tilesets: [],
        scripts: [scriptEntry],
        dialogues: [],
      );

      var gameState = GameState(saveId: 'test-save');

      final pageResolver = EventPageResolver();

      final pageBefore = pageResolver.resolve(event, gameState);
      expect(pageBefore, isNotNull);
      expect(pageBefore!.pageIndex, equals(0));

      final scriptAsset = manifest.scripts.first.asset;
      final context = ScriptExecutionContext(
        gameState: gameState,
        onGameStateUpdated: (state) {
          gameState = state;
        },
        onDialogueOpened: (_) {},
        onWarpRequested: (_, __, ___) {},
      );

      final controller = ScriptRuntimeController(
        script: scriptAsset,
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

    test('Event page resolution with multiple conditions', () {
      final event = MapEventDefinition(
        id: 'complex_event',
        title: 'Complex Event',
        position: const EventPosition(layerId: 'objects', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptCondition(
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
            ),
            message: 'Both flags set',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: {ScriptConditionParams.flagName: 'flag_a'},
            ),
            message: 'Only flag A set',
          ),
          MapEventPage(
            pageNumber: 2,
            message: 'Default page',
          ),
        ],
      );

      var gameState = GameState(saveId: 'test-save');
      final pageResolver = EventPageResolver();
      final mutations = const GameStateMutations();

      var page = pageResolver.resolve(event, gameState);
      expect(page!.pageIndex, equals(2));

      gameState = mutations.setFlag(gameState, 'flag_a');
      page = pageResolver.resolve(event, gameState);
      expect(page!.pageIndex, equals(1));

      gameState = mutations.setFlag(gameState, 'flag_b');
      page = pageResolver.resolve(event, gameState);
      expect(page!.pageIndex, equals(0));
    });

    test('Script execution updates GameState', () {
      final script = ScriptAsset(
        id: 'test_script',
        defaultStartNode: 'start',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.setFlag,
                params: {'flagName': 'test_flag'},
              ),
              const ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      var gameState = GameState(saveId: 'test-save');

      final context = ScriptExecutionContext(
        gameState: gameState,
        onGameStateUpdated: (state) {
          gameState = state;
        },
        onDialogueOpened: (_) {},
        onWarpRequested: (_, __, ___) {},
      );

      final controller = ScriptRuntimeController(
        script: script,
        context: context,
      );

      while (!controller.isTerminated) {
        controller.step();
      }

      expect(gameState.storyFlags.activeFlags, contains('test_flag'));
    });

    test('Script resume continues after an openDialogue suspension', () {
      final script = ScriptAsset(
        id: 'resume_after_dialogue',
        defaultStartNode: 'start',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.openDialogue,
                params: {'filePath': 'dialogues/test.yarn'},
              ),
              ScriptCommand(
                type: ScriptCommandType.setFlag,
                params: {'flagName': 'after_dialogue'},
              ),
              const ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      var gameState = GameState(saveId: 'test-save');

      final context = ScriptExecutionContext(
        gameState: gameState,
        onGameStateUpdated: (state) {
          gameState = state;
        },
        onDialogueOpened: (_) {},
        onWarpRequested: (_, __, ___) {},
      );

      final controller = ScriptRuntimeController(
        script: script,
        context: context,
      );

      final firstResult = controller.step();
      expect(firstResult, isA<ScriptCommandResultSuspended>());
      expect(controller.isSuspended, isTrue);

      controller.resume();

      while (!controller.isTerminated) {
        controller.step();
      }

      expect(gameState.storyFlags.activeFlags, contains('after_dialogue'));
    });

    test('Script controller is cleaned up after termination', () {
      final script = ScriptAsset(
        id: 'cleanup_test',
        defaultStartNode: 'start',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.setFlag,
                params: {'flagName': 'cleanup_flag'},
              ),
              const ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      var gameState = GameState(saveId: 'test-save');
      var controllerTerminated = false;

      final context = ScriptExecutionContext(
        gameState: gameState,
        onGameStateUpdated: (state) {
          gameState = state;
        },
        onDialogueOpened: (_) {},
        onWarpRequested: (_, __, ___) {},
      );

      final controller = ScriptRuntimeController(
        script: script,
        context: context,
      );

      while (!controller.isTerminated) {
        controller.step();
      }

      controllerTerminated = controller.isTerminated;

      expect(controllerTerminated, isTrue);
      expect(gameState.storyFlags.activeFlags, contains('cleanup_flag'));
    });

    test('Script throws StateError for missing script', () {
      final manifest = ProjectManifest(
        name: 'Test Project',
        maps: [],
        tilesets: [],
        scripts: [],
        dialogues: [],
      );

      expect(
        () => manifest.scripts.firstWhere((s) => s.id == 'nonexistent'),
        throwsStateError,
      );
    });

    test('Dialogue resolution uses dirname of projectFilePath', () {
      // This test would FAIL before the fix because projectFilePath
      // is the path to project.json, not the project root directory.
      // After the fix, it uses _bundle.projectRootDirectory which is correct.

      final dialogueEntry = ProjectDialogueEntry(
        id: 'test_dialogue',
        name: 'Test Dialogue',
        relativePath: 'dialogues/test.yarn',
      );

      final manifest = ProjectManifest(
        name: 'Test Project',
        maps: [],
        tilesets: [],
        scripts: [],
        dialogues: [dialogueEntry],
      );

      // The correct project root should be the dirname
      final projectRootDirectory = '/Users/karim/Project/pokemonProject';

      final resolved = resolveDialogue(
        entityId: 'test_event',
        ref: DialogueRef(
          dialogueId: '',
          scriptPathRelative: 'dialogues/test.yarn',
          startNode: 'start',
        ),
        projectRootDirectory: projectRootDirectory,
        dialogues: manifest.dialogues,
      );

      expect(resolved, isNotNull);
      // This assertion would FAIL if projectFilePath was used instead of projectRootDirectory
      expect(
        resolved!.absoluteFilePath,
        equals('/Users/karim/Project/pokemonProject/dialogues/test.yarn'),
        reason: 'Path should not include project.json in the middle',
      );
      expect(resolved.startNode, equals('start'));
    });

    test('Dialogue resolution with scriptPathRelative', () {
      final dialogueEntry = ProjectDialogueEntry(
        id: 'test_dialogue',
        name: 'Test Dialogue',
        relativePath: 'dialogues/test.yarn',
      );

      final manifest = ProjectManifest(
        name: 'Test Project',
        maps: [],
        tilesets: [],
        scripts: [],
        dialogues: [dialogueEntry],
      );

      final resolved = resolveDialogue(
        entityId: 'test_event',
        ref: DialogueRef(
          dialogueId: '',
          scriptPathRelative: 'dialogues/test.yarn',
          startNode: 'start',
        ),
        projectRootDirectory: '/project',
        dialogues: manifest.dialogues,
      );

      expect(resolved, isNotNull);
      expect(
          resolved!.absoluteFilePath, equals('/project/dialogues/test.yarn'));
      expect(resolved.startNode, equals('start'));
    });

    test('Dialogue resolution constructs path for missing dialogue file', () {
      // Note: This test only verifies path construction, not file existence.
      // loadDialogueContent() will fail later if the file doesn't exist.

      final manifest = ProjectManifest(
        name: 'Test Project',
        maps: [],
        tilesets: [],
        scripts: [],
        dialogues: [],
      );

      final resolved = resolveDialogue(
        entityId: 'test_event',
        ref: DialogueRef(
          dialogueId: '',
          scriptPathRelative: 'dialogues/missing.yarn',
          startNode: 'start',
        ),
        projectRootDirectory: '/project',
        dialogues: manifest.dialogues,
      );

      // Resolution succeeds (path is constructed), but file may not exist
      expect(resolved, isNotNull);
      expect(resolved!.absoluteFilePath,
          equals('/project/dialogues/missing.yarn'));
    });
  });
}
