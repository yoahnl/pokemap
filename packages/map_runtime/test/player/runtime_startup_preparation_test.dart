import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('short preparation waits for the injected minimum duration', () async {
    final clock = _ControlledStartupClock();
    final snapshots = <RuntimeStartupPreparationSnapshot>[];
    final preparation = RuntimeStartupPreparation(
      clock: clock,
      minimumDisplayDuration: const Duration(seconds: 7),
    );

    final resultFuture = preparation.run(
      operations: _completedOperations(),
      onChanged: snapshots.add,
    );
    var completed = false;
    resultFuture.then((_) => completed = true);
    await _flushEvents();

    expect(snapshots.last.isPreparationReady, isTrue);
    expect(snapshots.last.isMinimumElapsed, isFalse);
    expect(completed, isFalse);

    clock.elapseMinimum();
    final result = await resultFuture;

    expect(result.status, RuntimeStartupPreparationStatus.ready);
    expect(result.snapshot.progress, 1);
    expect(result.snapshot.isMinimumElapsed, isTrue);
  });

  test('long preparation waits for real work after the minimum elapsed',
      () async {
    final clock = _ControlledStartupClock()..elapseMinimum();
    final gate = Completer<void>();
    final operations = _completedOperations();
    operations[RuntimeStartupPreparationStage.introAndPoster] = () async {
      await gate.future;
      return const RuntimeStartupPreparationStepResult.completed();
    };
    final snapshots = <RuntimeStartupPreparationSnapshot>[];
    final preparation = RuntimeStartupPreparation(
      clock: clock,
      minimumDisplayDuration: const Duration(seconds: 7),
    );

    final resultFuture = preparation.run(
      operations: operations,
      onChanged: snapshots.add,
    );
    var completed = false;
    resultFuture.then((_) => completed = true);
    await _flushEvents();

    expect(snapshots.last.isMinimumElapsed, isTrue);
    expect(snapshots.last.isPreparationReady, isFalse);
    expect(snapshots.last.progress, closeTo(0.8, 0.0001));
    expect(completed, isFalse);

    gate.complete();
    final result = await resultFuture;

    expect(result.status, RuntimeStartupPreparationStatus.ready);
    expect(result.snapshot.progress, 1);
  });

  test('uses the seven signed weights and never regresses out of order',
      () async {
    final clock = _ControlledStartupClock()..elapseMinimum();
    final gates = <RuntimeStartupPreparationStage, Completer<void>>{
      for (final stage in RuntimeStartupPreparationStage.values)
        stage: Completer<void>(),
    };
    final snapshots = <RuntimeStartupPreparationSnapshot>[];
    final preparation = RuntimeStartupPreparation(
      clock: clock,
      minimumDisplayDuration: const Duration(seconds: 7),
    );
    final resultFuture = preparation.run(
      operations: <RuntimeStartupPreparationStage,
          RuntimeStartupPreparationOperation>{
        for (final entry in gates.entries)
          entry.key: () async {
            await entry.value.future;
            return const RuntimeStartupPreparationStepResult.completed();
          },
      },
      onChanged: snapshots.add,
    );

    gates[RuntimeStartupPreparationStage.titleMenuAndMusic]!.complete();
    await _flushEvents();
    expect(snapshots.last.progress, closeTo(0.2, 0.0001));
    expect(
      snapshots.last.currentStage,
      RuntimeStartupPreparationStage.manifestAndIdentity,
    );

    gates[RuntimeStartupPreparationStage.manifestAndIdentity]!.complete();
    await _flushEvents();
    expect(snapshots.last.progress, closeTo(0.35, 0.0001));
    expect(
      snapshots.last.currentStage,
      RuntimeStartupPreparationStage.playerPreferences,
    );

    for (final stage in RuntimeStartupPreparationStage.values) {
      if (!gates[stage]!.isCompleted) gates[stage]!.complete();
    }
    final result = await resultFuture;

    expect(result.snapshot.progress, 1);
    expect(
      snapshots.map((snapshot) => snapshot.progress),
      orderedEquals(
        [...snapshots.map((snapshot) => snapshot.progress)]..sort(),
      ),
    );
    expect(runtimeStartupPreparationWeights.values.reduce((a, b) => a + b), 1);
    expect(
      runtimeStartupPreparationWeights,
      const <RuntimeStartupPreparationStage, double>{
        RuntimeStartupPreparationStage.manifestAndIdentity: 0.15,
        RuntimeStartupPreparationStage.playerPreferences: 0.10,
        RuntimeStartupPreparationStage.saveDiscovery: 0.15,
        RuntimeStartupPreparationStage.presentationProfile: 0.10,
        RuntimeStartupPreparationStage.splashBranding: 0.10,
        RuntimeStartupPreparationStage.introAndPoster: 0.20,
        RuntimeStartupPreparationStage.titleMenuAndMusic: 0.20,
      },
    );
  });

  test('optional absence and non-blocking errors still reach ready', () async {
    final clock = _ControlledStartupClock()..elapseMinimum();
    final operations = _completedOperations();
    operations[RuntimeStartupPreparationStage.introAndPoster] =
        () async => const RuntimeStartupPreparationStepResult.absent();
    operations[RuntimeStartupPreparationStage.titleMenuAndMusic] = () async =>
        const RuntimeStartupPreparationStepResult.nonBlockingFailure(
          RuntimeStartupDiagnostic(
            code: 'titleMusicUnavailable',
            safeMessage: 'La musique du titre est indisponible.',
          ),
        );
    final preparation = RuntimeStartupPreparation(
      clock: clock,
      minimumDisplayDuration: const Duration(seconds: 7),
    );

    final result = await preparation.run(operations: operations);

    expect(result.status, RuntimeStartupPreparationStatus.ready);
    expect(result.snapshot.progress, 1);
    expect(result.snapshot.diagnostics, hasLength(1));
    expect(result.snapshot.failure, isNull);
  });

  test('blocking error returns immediately with a retry-safe diagnostic',
      () async {
    final clock = _ControlledStartupClock();
    final operations = _completedOperations();
    operations[RuntimeStartupPreparationStage.saveDiscovery] =
        () async => const RuntimeStartupPreparationStepResult.blockingFailure(
              RuntimeStartupFailure(
                code: 'saveDiscoveryFailed',
                safeMessage:
                    'Les sauvegardes ne peuvent pas être vérifiées pour le moment.',
              ),
            );
    final preparation = RuntimeStartupPreparation(
      clock: clock,
      minimumDisplayDuration: const Duration(seconds: 7),
    );

    final result = await preparation.run(operations: operations);

    expect(result.status, RuntimeStartupPreparationStatus.blocked);
    expect(result.snapshot.failure?.code, 'saveDiscoveryFailed');
    expect(result.snapshot.isMinimumElapsed, isFalse);
  });

  test('cancel completes without waiting for outstanding work', () async {
    final clock = _ControlledStartupClock();
    final gate = Completer<void>();
    final operations = _completedOperations();
    operations[RuntimeStartupPreparationStage.manifestAndIdentity] = () async {
      await gate.future;
      return const RuntimeStartupPreparationStepResult.completed();
    };
    final preparation = RuntimeStartupPreparation(
      clock: clock,
      minimumDisplayDuration: const Duration(seconds: 7),
    );

    final resultFuture = preparation.run(operations: operations);
    preparation.cancel();
    final result = await resultFuture;

    expect(result.status, RuntimeStartupPreparationStatus.cancelled);
    gate.complete();
  });
}

Map<RuntimeStartupPreparationStage, RuntimeStartupPreparationOperation>
    _completedOperations() =>
        <RuntimeStartupPreparationStage, RuntimeStartupPreparationOperation>{
          for (final stage in RuntimeStartupPreparationStage.values)
            stage: () async =>
                const RuntimeStartupPreparationStepResult.completed(),
        };

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _ControlledStartupClock implements RuntimeStartupClock {
  final Completer<void> _minimum = Completer<void>();

  void elapseMinimum() {
    if (!_minimum.isCompleted) _minimum.complete();
  }

  @override
  Future<void> delay(Duration duration) => _minimum.future;
}
