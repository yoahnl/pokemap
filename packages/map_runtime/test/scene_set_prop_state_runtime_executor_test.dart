import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  final command = SceneInteractiveCommand.setPropState(
    mapId: 'room',
    propIds: const ['left', 'right'],
    state: MovingPropState.open,
  );

  test(
    'prop dispatch awaits the dedicated consumer and preserves its group',
    () async {
      final completion = Completer<String>();
      var finished = false;
      final executor = SceneInteractiveCommandRuntimeExecutor(
        warp: (_) async => 'completed',
        setPropState: (received) {
          expect(received, same(command));
          return completion.future;
        },
      );
      final execution = executor
          .execute(
            SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
          )
          .then((output) {
            finished = true;
            return output;
          });
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      completion.complete('moved');
      expect(await execution, 'moved');
      expect(finished, isTrue);
    },
  );

  test('prop dispatch preserves a blocked result', () async {
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
      setPropState: (_) async => 'blocked',
    );
    expect(
      await executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
      ),
      'blocked',
    );
  });

  test(
    'prop dispatch refuses a missing consumer or an invalid result',
    () async {
      for (final executor in [
        SceneInteractiveCommandRuntimeExecutor(warp: (_) async => 'completed'),
        SceneInteractiveCommandRuntimeExecutor(
          warp: (_) async => 'completed',
          setPropState: (_) async => 'completed',
        ),
      ]) {
        await expectLater(
          executor.execute(
            SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
          ),
          throwsStateError,
        );
      }
    },
  );
}
