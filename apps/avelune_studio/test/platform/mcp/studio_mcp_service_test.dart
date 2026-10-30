import 'dart:async';

import 'package:avelune_studio/platform/mcp/studio_mcp_process.dart';
import 'package:avelune_studio/platform/mcp/studio_mcp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'starts once, waits for readiness, and synchronizes a narrow root',
    () async {
      final process = FakeStudioMcpProcess();
      var launches = 0;
      final service = StudioMcpService(
        launch: () async {
          launches++;
          return process;
        },
      );
      addTearDown(service.dispose);
      await service.setProjectRoot('/projects/Jeu émeraude');
      final starting = service.start();
      final duplicate = service.start();
      await flush();
      expect(service.state, StudioMcpState.starting);
      expect(service.connection, isNull);
      process.ready();
      await Future.wait([starting, duplicate]);
      expect(launches, 1);
      expect(service.state, StudioMcpState.ready);
      expect(process.commands.single['roots'], ['/projects/Jeu émeraude']);
      expect(
        service.connection!.clientConfiguration,
        contains('Bearer secret'),
      );
      await service.stop();
      expect(process.shutdowns, 1);
      expect(service.state, StudioMcpState.stopped);
    },
  );

  test(
    'crash clears connection and only an explicit retry launches again',
    () async {
      final processes = <FakeStudioMcpProcess>[];
      final service = StudioMcpService(
        launch: () async {
          final process = FakeStudioMcpProcess();
          processes.add(process);
          return process;
        },
      );
      addTearDown(service.dispose);
      final starting = service.start();
      await flush();
      processes.single.ready();
      await starting;
      processes.single.exit.complete(1);
      await flush();
      expect(service.state, StudioMcpState.failed);
      expect(service.connection, isNull);
      expect(service.error, isNot(contains('secret')));
      expect(processes, hasLength(1));
      final retrying = service.retry();
      await flush();
      processes.last.ready();
      await retrying;
      expect(processes, hasLength(2));
      expect(service.state, StudioMcpState.ready);
      await service.stop();
    },
  );

  test(
    'stop during spawn shuts down the late owned process without readiness',
    () async {
      final spawned = Completer<StudioMcpProcess>();
      final process = FakeStudioMcpProcess();
      final service = StudioMcpService(launch: () => spawned.future);
      addTearDown(service.dispose);
      final starting = service.start();
      final stopping = service.stop();
      spawned.complete(process);
      await Future.wait([starting, stopping]);
      expect(process.shutdowns, 1);
      expect(service.state, StudioMcpState.stopped);
      expect(service.connection, isNull);
    },
  );

  test(
    'invalid handshake fails safely and stops only the owned process',
    () async {
      final process = FakeStudioMcpProcess();
      final service = StudioMcpService(launch: () async => process);
      addTearDown(service.dispose);
      final starting = service.start();
      await flush();
      process.eventsController.add({
        'type': 'ready',
        'controlVersion': 1,
        'url': 'http://192.168.1.4:8080/mcp',
        'token': 'secret',
        'protocolVersions': ['2025-11-25'],
      });
      await starting;
      expect(service.state, StudioMcpState.failed);
      expect(service.connection, isNull);
      expect(process.shutdowns, 1);
    },
  );

  test(
    'root revocation suppresses old mutations and is acknowledged',
    () async {
      final process = FakeStudioMcpProcess();
      final service = StudioMcpService(launch: () async => process);
      addTearDown(service.dispose);
      final received = <StudioMcpMutation>[];
      final subscription = service.mutations.listen(received.add);
      addTearDown(subscription.cancel);
      await service.setProjectRoot('/projects/A');
      final starting = service.start();
      await flush();
      process.ready();
      await starting;
      process.mutation('/projects/A');
      await flush();
      expect(received.single.resources.single.id, 'map-a');
      await service.setProjectRoot(null);
      expect(process.commands.last['roots'], isEmpty);
      process.mutation('/projects/A');
      await flush();
      expect(received, hasLength(1));
      await service.stop();
    },
  );

  test(
    'missing acknowledgement surfaces access failure without losing Studio',
    () async {
      final process = FakeStudioMcpProcess()..acknowledge = false;
      final service = StudioMcpService(
        launch: () async => process,
        commandTimeout: const Duration(milliseconds: 10),
      );
      addTearDown(service.dispose);
      final starting = service.start();
      await flush();
      process.ready();
      await starting;
      expect(service.state, StudioMcpState.failed);
      expect(service.connection, isNull);
      expect(process.shutdowns, 1);
    },
  );
  test(
    'a timed out launcher releases its late process without waiting for ready',
    () async {
      final spawned = Completer<StudioMcpProcess>();
      final process = FakeStudioMcpProcess();
      final service = StudioMcpService(
        launch: () => spawned.future,
        startTimeout: const Duration(milliseconds: 10),
      );
      addTearDown(service.dispose);
      await service.start();
      expect(service.state, StudioMcpState.failed);
      await service.stop();
      spawned.complete(process);
      await flush();
      expect(process.shutdowns, 1);
      expect(service.state, StudioMcpState.stopped);
    },
  );

  test(
    'a failed shutdown retains ownership until a successful retry',
    () async {
      final process = FakeStudioMcpProcess();
      var launches = 0;
      final service = StudioMcpService(
        launch: () async {
          launches++;
          return process;
        },
      );
      addTearDown(service.dispose);
      final starting = service.start();
      await flush();
      process.ready();
      await starting;
      process.failShutdown = true;
      await service.stop();
      expect(service.state, StudioMcpState.failed);
      await service.start();
      expect(launches, 1);
      process.failShutdown = false;
      await service.stop();
      expect(process.shutdowns, 2);
      expect(service.state, StudioMcpState.stopped);
    },
  );

  test(
    'project bookmarks travel only in the private root command before ready',
    () async {
      final process = FakeStudioMcpProcess();
      final service = StudioMcpService(
        launch: () async => process,
        projectBookmark: (root) async => 'private-bookmark',
      );
      addTearDown(service.dispose);
      await service.setProjectRoot('/projects/owned');
      final starting = service.start();
      await flush();
      process.ready();
      await starting;
      expect(process.commands.single['grants'], [
        {'root': '/projects/owned', 'bookmark': 'private-bookmark'},
      ]);
      expect(
        service.connection!.clientConfiguration,
        isNot(contains('private-bookmark')),
      );
      await service.stop();
    },
  );
  test('missing project bookmark fails with a safe diagnostic', () async {
    final process = FakeStudioMcpProcess();
    final service = StudioMcpService(
      launch: () async => process,
      projectBookmark: (_) async => null,
    );
    addTearDown(service.dispose);
    await service.setProjectRoot('/projects/owned');
    final starting = service.start();
    await flush();
    process.ready();
    await starting;
    expect(service.state, StudioMcpState.failed);
    expect(service.diagnosticCode, 'permission.bookmark_unavailable');
    expect(process.commands, isEmpty);
    expect(process.shutdowns, 1);
  });
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

class FakeStudioMcpProcess implements StudioMcpProcess {
  final eventsController = StreamController<Map<String, Object?>>();
  final exit = Completer<int>();
  final commands = <Map<String, Object?>>[];
  var shutdowns = 0;
  var failShutdown = false;
  var acknowledge = true;

  @override
  Stream<Map<String, Object?>> get events => eventsController.stream;
  @override
  Future<int> get exitCode => exit.future;

  void ready() => eventsController.add({
    'type': 'ready',
    'controlVersion': 1,
    'url': 'http://127.0.0.1:43210/mcp',
    'token': 'secret',
    'protocolVersions': ['2025-11-25'],
  });

  void mutation(String root) => eventsController.add({
    'type': 'mutation',
    'projectRoot': root,
    'resources': [
      {'kind': 'map', 'id': 'map-a'},
    ],
    'revision': 'durable-r1',
    'operationId': 'op-1',
  });

  @override
  Future<void> send(Map<String, Object?> command) async {
    commands.add(command);
    if (acknowledge) {
      eventsController.add({
        'type': 'response',
        'id': command['id'],
        'ok': true,
      });
    }
  }

  @override
  Future<void> shutdown() async {
    shutdowns++;
    if (failShutdown) throw StateError('shutdown failed');
    if (!exit.isCompleted) exit.complete(0);
    unawaited(eventsController.close());
  }
}
