import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_interactive_command_runtime_executor.dart';
import 'package:map_runtime/src/player/runtime_world_service_models.dart';

void main() {
  SceneRuntimePlanIntent intent() =>
      SceneRuntimePlanIntent.executeInteractiveCommand(
        command: SceneInteractiveCommand.fromJson({'kind': 'openPartyTrade'}),
      );
  test(
    'party trade awaits its dedicated service without falling through to PC',
    () async {
      final close = Completer<String>();
      var calls = 0;
      var advanced = false;
      final executor = SceneInteractiveCommandRuntimeExecutor(
        warp: (_) async => throw StateError('No warp requested'),
        openPc: (_) async => throw StateError('Party trade does not open PC'),
        openWorldService: (request) {
          expect(request, isA<OpenPartyTradeService>());
          expect(request.kind, RuntimeWorldServiceKind.partyTrade);
          expect(request.interactionId, 'scene.openPartyTrade');
          calls++;
          return close.future;
        },
      );
      final running = executor.execute(intent());
      running.then((_) => advanced = true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      expect(advanced, false);
      close.complete('cancelled');
      expect(await running, 'cancelled');
    },
  );
  test('an unsupported trade result cannot advance a scene output', () async {
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
      openWorldService: (_) async => 'unknown',
    );
    await expectLater(executor.execute(intent()), throwsStateError);
  });
  test(
    'a missing trade service cannot succeed using a generic fallback',
    () async {
      final executor = SceneInteractiveCommandRuntimeExecutor(
        warp: (_) async => 'completed',
        openPc: (_) async => 'completed',
      );
      await expectLater(executor.execute(intent()), throwsStateError);
    },
  );
}
