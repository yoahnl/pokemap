import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneBattleRuntimeOutcomeAdapter', () {
    test('maps runtime victory to Scene port victory', () async {
      final requests = <SceneBattleRuntimeBattleRequest>[];
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: 'event_guard',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher((request) {
          requests.add(request);
          return const SceneBattleRuntimeOutcomeResult.completed(
            port: SceneBattleRuntimeOutcomePort.victory,
          );
        }),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.completed);
      expect(result.port, SceneBattleRuntimeOutcomePort.victory);
      expect(result.scenePortId, 'victory');
      expect(requests.single.trainerId, 'trainer_guard');
      expect(requests.single.npcEntityId, 'event_guard');
      expect(requests.single.requestId, 'scene:map:event:0:trainer_guard:1234');
    });

    test('maps runtime defeat to Scene port defeat', () async {
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: 'event_guard',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher(
          (_) => const SceneBattleRuntimeOutcomeResult.completed(
            port: SceneBattleRuntimeOutcomePort.defeat,
          ),
        ),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.completed);
      expect(result.port, SceneBattleRuntimeOutcomePort.defeat);
      expect(result.scenePortId, 'defeat');
    });

    test('fails clearly when intent has no trainerId', () async {
      final adapter = _adapterReturning(SceneBattleRuntimeOutcomePort.victory);

      final result = await adapter.startBattle(
        SceneRuntimePlanIntent.startBattle(battleKind: 'trainer'),
      );

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(result.errorCode,
          SceneBattleRuntimeOutcomeErrorCode.missingTrainerId);
      expect(result.scenePortId, isNull);
    });

    test('fails clearly when intent and default have no npcEntityId', () async {
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: '',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher(
          (_) => const SceneBattleRuntimeOutcomeResult.completed(
            port: SceneBattleRuntimeOutcomePort.victory,
          ),
        ),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(result.errorCode,
          SceneBattleRuntimeOutcomeErrorCode.missingNpcEntityId);
      expect(result.scenePortId, isNull);
    });

    test('fails clearly when battle kind is unsupported', () async {
      final adapter = _adapterReturning(SceneBattleRuntimeOutcomePort.victory);

      final result = await adapter.startBattle(
        SceneRuntimePlanIntent.startBattle(
          battleKind: 'wild',
          trainerId: 'trainer_guard',
        ),
      );

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(result.errorCode,
          SceneBattleRuntimeOutcomeErrorCode.unsupportedBattleKind);
    });

    test('fails clearly when launcher fails', () async {
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: 'event_guard',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher(
          (_) => const SceneBattleRuntimeOutcomeResult.failed(
            errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
            message: 'battle handoff failed',
          ),
        ),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(
          result.errorCode, SceneBattleRuntimeOutcomeErrorCode.launcherFailed);
      expect(result.message, 'battle handoff failed');
      expect(result.scenePortId, isNull);
    });

    test('does not invent victory when launcher throws', () async {
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: 'event_guard',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher((_) => throw StateError('runtime battle crashed')),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(
          result.errorCode, SceneBattleRuntimeOutcomeErrorCode.launcherFailed);
      expect(result.scenePortId, isNull);
      expect(result.message, contains('runtime battle crashed'));
    });

    test('does not mutate GameState or apply Scene consequences directly',
        () async {
      const state = GameState(saveId: 'save_scene_battle_adapter');
      final adapter = _adapterReturning(SceneBattleRuntimeOutcomePort.victory);

      await adapter.startBattle(_trainerIntent());

      expect(state.storyFlags.activeFlags, isEmpty);
      expect(state.consumedEventIds, isEmpty);
    });
  });
}

SceneRuntimePlanIntent _trainerIntent() {
  return SceneRuntimePlanIntent.startBattle(
    battleKind: 'trainer',
    trainerId: 'trainer_guard',
    declaredOutcomes: const ['victory', 'defeat'],
  );
}

SceneBattleRuntimeOutcomeAdapter _adapterReturning(
  SceneBattleRuntimeOutcomePort port,
) {
  return SceneBattleRuntimeOutcomeAdapter(
    runtimeSourceId: 'scene:map:event:0',
    defaultNpcEntityId: 'event_guard',
    createdAtEpochMs: () => 1234,
    launcher: _Launcher(
      (_) => SceneBattleRuntimeOutcomeResult.completed(port: port),
    ),
  );
}

final class _Launcher implements SceneBattleRuntimeLauncher {
  const _Launcher(this._handler);

  final FutureOr<SceneBattleRuntimeOutcomeResult> Function(
    SceneBattleRuntimeBattleRequest request,
  ) _handler;

  @override
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
    SceneBattleRuntimeBattleRequest request,
  ) async {
    return _handler(request);
  }
}
