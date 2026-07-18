import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneDialogueRuntimeAwaitableAdapter', () {
    test('maps launcher completion to Scene port completed', () async {
      final requests = <SceneDialogueRuntimeDialogueRequest>[];
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        createdAtEpochMs: () => 1234,
        launcher: _SceneTestDialogueLauncher((request) {
          requests.add(request);
          return const SceneDialogueRuntimeAwaitableResult.completed();
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
          yarnNodeName: 'Start',
        ),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.completed);
      expect(result.scenePortId, 'completed');
      expect(result.success, isTrue);
      expect(requests, hasLength(1));
      expect(requests.single.requestId,
          'scene:map_test:event_test:0:dialogue_test_intro:1234');
      expect(requests.single.createdAtEpochMs, 1234);
      expect(requests.single.dialogueId, 'dialogue_test_intro');
      expect(requests.single.yarnNodeName, 'Start');
      expect(requests.single.expectedOutcomes, isEmpty);
    });

    test('fails clearly when intent has no dialogueId', () async {
      var launched = false;
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          launched = true;
          return const SceneDialogueRuntimeAwaitableResult.completed();
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(dialogueId: '   '),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.failed);
      expect(
        result.errorCode,
        SceneDialogueRuntimeAwaitableErrorCode.missingDialogueId,
      );
      expect(result.scenePortId, isNull);
      expect(launched, isFalse);
    });

    test('fails clearly when launcher fails', () async {
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          return const SceneDialogueRuntimeAwaitableResult.failed(
            errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
            message: 'Dialogue was cancelled.',
          );
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
        ),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.failed);
      expect(
        result.errorCode,
        SceneDialogueRuntimeAwaitableErrorCode.cancelled,
      );
      expect(result.scenePortId, isNull);
    });

    test('wraps thrown launcher errors as launcher failure', () async {
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          throw StateError('dialogue overlay failed');
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
        ),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.failed);
      expect(
        result.errorCode,
        SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
      );
      expect(result.scenePortId, isNull);
      expect(result.message, contains('dialogue overlay failed'));
    });

    test('does not invent dialogue outcomes', () async {
      final unsupportedPorts = [
        'accepted',
        'refused',
        'choice_1',
        'success',
        'failure',
      ];
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          return const SceneDialogueRuntimeAwaitableResult.completed();
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
          expectedOutcomes: unsupportedPorts,
        ),
      );

      expect(result.scenePortId, 'completed');
      expect(unsupportedPorts, isNot(contains(result.scenePortId)));
    });

    test('propagates a declared launcher outcome to its Scene port', () async {
      final requests = <SceneDialogueRuntimeDialogueRequest>[];
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          requests.add(request);
          return const SceneDialogueRuntimeAwaitableResult.completed(
            outcomeId: 'accepted',
          );
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
          expectedOutcomes: const ['accepted', 'refused'],
        ),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.completed);
      expect(result.scenePortId, 'accepted');
      expect(result.outcomeId, 'accepted');
      expect(requests.single.expectedOutcomes, ['accepted', 'refused']);
    });

    test('rejects a launcher outcome not declared by the Scene intent',
        () async {
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          return const SceneDialogueRuntimeAwaitableResult.completed(
            outcomeId: 'unexpected',
          );
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
          expectedOutcomes: const ['accepted', 'refused'],
        ),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.failed);
      expect(
        result.errorCode,
        SceneDialogueRuntimeAwaitableErrorCode.unsupportedOutcome,
      );
      expect(result.scenePortId, isNull);
      expect(result.message, contains('unexpected'));
    });

    test('does not mutate GameState or apply Scene consequences directly',
        () async {
      const gameState = GameState(saveId: 'save_dialogue_adapter');
      final before = gameState.toJson();
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          return const SceneDialogueRuntimeAwaitableResult.completed();
        }),
      );

      await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
        ),
      );

      expect(gameState.toJson(), before);
      final adapterSource = File(
        'lib/src/application/scene_runtime/'
        'scene_dialogue_runtime_awaitable_adapter.dart',
      ).readAsStringSync();
      expect(adapterSource, isNot(contains('SceneConsequenceRuntimeWriter')));
      expect(adapterSource, isNot(contains('GameState')));
      expect(adapterSource, isNot(contains('setFact')));
      expect(adapterSource, isNot(contains('markEventConsumed')));
    });
  });
}

final class _SceneTestDialogueLauncher implements SceneDialogueRuntimeLauncher {
  const _SceneTestDialogueLauncher(this._handler);

  final FutureOr<SceneDialogueRuntimeAwaitableResult> Function(
    SceneDialogueRuntimeDialogueRequest request,
  ) _handler;

  @override
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneDialogueRuntimeDialogueRequest request,
  ) async {
    return _handler(request);
  }
}
