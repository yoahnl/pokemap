import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('session orders events, supports pause/resume, and disposes once',
      () async {
    final driver = _FakeRuntimePlaytestDriver(
      projectRevision: 'sha256:${'a' * 64}',
    );
    final clock = _Clock(<DateTime>[
      DateTime.utc(2026, 7, 31, 10),
      DateTime.utc(2026, 7, 31, 10, 0, 1),
    ]);
    final port = RuntimePlaytestPort(
      driverFactory: (_) async => driver,
      pokemonCatalogPreflight: _readyPokemonCatalog,
      clock: clock.call,
    );
    final session = await port.start(_request());
    final events = <PlaytestEvent>[];
    final subscription = session.events.listen(events.add);

    final execution = await session.execute(
      PlaytestCommand(
        commandId: 'money',
        operation: 'probe.setMoney',
        arguments: const <String, Object?>{'value': 750},
      ),
    );
    await session.pause();
    await expectLater(
      session.execute(
        PlaytestCommand(
          commandId: 'blocked',
          operation: 'save.write',
        ),
      ),
      throwsStateError,
    );
    await session.resume();
    final artifact = await session.captureScreenshot('final');
    final receipt = await session.stop();
    await subscription.cancel();

    expect(execution.diff.changes.single.path, 'trainer.money');
    expect(
        execution.snapshot.state['trainer'], <String, Object?>{'money': 750});
    expect(artifact.mediaType, 'image/png');
    expect(receipt.artifacts.single.id, artifact.id);
    expect(receipt.commandCount, 1);
    expect(driver.disposeCount, 1);
    expect(session.state, PlaytestSessionState.stopped);
    expect(
      events.map((event) => event.sequence),
      orderedEquals(List<int>.generate(events.length, (index) => index + 1)),
    );
    expect(
        events.map((event) => event.type),
        containsAll(<String>[
          'session.started',
          'command.started',
          'state.changed',
          'command.finished',
          'session.paused',
          'session.resumed',
          'artifact.created',
          'session.stopped',
        ]));

    expect((await session.stop()).toJson(), receipt.toJson());
    expect(driver.disposeCount, 1);
  });

  test('start rejects revision drift and cleans the rejected driver', () async {
    final driver = _FakeRuntimePlaytestDriver(
      projectRevision: 'sha256:${'b' * 64}',
    );
    final port = RuntimePlaytestPort(
      driverFactory: (_) async => driver,
      pokemonCatalogPreflight: _readyPokemonCatalog,
    );

    await expectLater(port.start(_request()), throwsStateError);
    expect(driver.disposeCount, 1);
  });

  test('revision drift during a command fails and releases the session',
      () async {
    final driver = _FakeRuntimePlaytestDriver(
      projectRevision: 'sha256:${'a' * 64}',
    );
    final port = RuntimePlaytestPort(
      driverFactory: (_) async => driver,
      pokemonCatalogPreflight: _readyPokemonCatalog,
    );
    final session = await port.start(_request());
    driver.projectRevision = 'sha256:${'b' * 64}';

    await expectLater(
      session.execute(
        PlaytestCommand(
          commandId: 'drifted',
          operation: 'probe.setMoney',
          arguments: const <String, Object?>{'value': 500},
        ),
      ),
      throwsStateError,
    );

    expect(session.state, PlaytestSessionState.failed);
    expect(driver.disposeCount, 1);
  });

  test('start blocks Pokemon catalog errors before creating a driver', () async {
    var driverCreated = false;
    final report = PokemonCatalogCoherenceReport(const [
      PokemonCatalogDiagnostic(
        code: 'species.id_empty',
        severity: PokemonCatalogDiagnosticSeverity.error,
        path: 'species/invalid.json.id',
        message: 'Species id cannot be empty.',
        recommendedAction: 'Assign a stable species id.',
      ),
    ]);
    final port = RuntimePlaytestPort(
      driverFactory: (_) async {
        driverCreated = true;
        return _FakeRuntimePlaytestDriver(
          projectRevision: 'sha256:${'a' * 64}',
        );
      },
      pokemonCatalogPreflight: (_) async => report,
    );

    await expectLater(
      port.start(_request()),
      throwsA(isA<RuntimePlaytestReadinessException>()),
    );
    expect(driverCreated, isFalse);
  });
}

Future<PokemonCatalogCoherenceReport> _readyPokemonCatalog(
  PlaytestStartRequest _,
) async => PokemonCatalogCoherenceReport(const []);

PlaytestStartRequest _request() => PlaytestStartRequest(
      sessionId: 'session-070',
      projectId: 'selbrume',
      projectRevision: 'sha256:${'a' * 64}',
      scenarioId: 'golden.slice',
      seed: 42,
    );

final class _FakeRuntimePlaytestDriver implements RuntimePlaytestDriver {
  _FakeRuntimePlaytestDriver({required this.projectRevision});

  String projectRevision;
  var money = 1000;
  var disposeCount = 0;

  @override
  Map<String, Object?> snapshot() => <String, Object?>{
        'trainer': <String, Object?>{'money': money},
      };

  @override
  Future<String> readProjectRevision() async => projectRevision;

  @override
  Future<void> execute(PlaytestCommand command) async {
    money = command.arguments['value']! as int;
  }

  @override
  Future<AuthoringArtifactRef> captureScreenshot(String name) async {
    return AuthoringArtifactRef(
      id: 'screenshot-$name',
      mediaType: 'image/png',
      uri: 'artifact://sha256/${'d' * 64}',
      byteLength: 4,
      sha256: 'd' * 64,
    );
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}

final class _Clock {
  _Clock(this.values);

  final List<DateTime> values;

  DateTime call() => values.removeAt(0);
}
