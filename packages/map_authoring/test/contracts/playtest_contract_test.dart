import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('PlaytestStartRequest', () {
    test('round-trips the frozen project, seed, scenario, and checkpoint', () {
      final request = PlaytestStartRequest(
        sessionId: 'session-070',
        projectId: 'selbrume',
        projectRevision: 'sha256:${'a' * 64}',
        scenarioId: 'golden.slice',
        seed: 42,
        checkpointId: 'before-arene',
      );

      expect(
        PlaytestStartRequest.fromJson(request.toJson()).toJson(),
        request.toJson(),
      );
      expect(request.seed, 42);
    });

    test('rejects a non-digest project revision', () {
      expect(
        () => PlaytestStartRequest(
          sessionId: 'session-070',
          projectId: 'selbrume',
          projectRevision: 'working-copy',
          scenarioId: 'golden.slice',
          seed: 42,
        ),
        throwsArgumentError,
      );
    });
  });

  test('commands and snapshots freeze caller-owned JSON', () {
    final arguments = <String, Object?>{
      'quantities': <String, Object?>{'potion': 2},
    };
    final command = PlaytestCommand(
      commandId: 'command-1',
      operation: 'probe.seedBag',
      arguments: arguments,
    );
    final state = <String, Object?>{
      'bag': <String, Object?>{'potion': 2},
    };
    final snapshot = PlaytestSnapshot(
      projectRevision: 'sha256:${'a' * 64}',
      sequence: 1,
      state: state,
    );

    (arguments['quantities'] as Map<String, Object?>)['potion'] = 99;
    (state['bag'] as Map<String, Object?>)['potion'] = 99;

    expect(
      (command.arguments['quantities'] as Map<String, Object?>)['potion'],
      2,
    );
    expect((snapshot.state['bag'] as Map<String, Object?>)['potion'], 2);
    expect(snapshot.stateDigest, startsWith('sha256:'));
  });

  test('receipt binds revision, seed, scenario, terminal state, and artifacts',
      () {
    final artifact = AuthoringArtifactRef(
      id: 'screenshot-final',
      mediaType: 'image/png',
      uri: 'artifact://sha256/${'b' * 64}',
      byteLength: 4,
      sha256: 'b' * 64,
    );
    final receipt = PlaytestReceipt(
      receiptId: 'playtest-receipt-070',
      sessionId: 'session-070',
      projectId: 'selbrume',
      projectRevision: 'sha256:${'a' * 64}',
      scenarioId: 'golden.slice',
      seed: 42,
      terminalState: PlaytestSessionState.stopped,
      startedAtUtc: '2026-07-31T10:00:00.000Z',
      finishedAtUtc: '2026-07-31T10:00:01.000Z',
      commandCount: 3,
      finalSnapshotDigest: 'sha256:${'c' * 64}',
      artifacts: <AuthoringArtifactRef>[artifact],
    );

    expect(
        PlaytestReceipt.fromJson(receipt.toJson()).toJson(), receipt.toJson());
    expect(receipt.artifacts.single.id, 'screenshot-final');
  });
}
