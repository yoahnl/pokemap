import 'package:avelune_studio/platform/mcp/studio_mcp_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'studio_mcp_service_test.dart' show FakeStudioMcpProcess, flush;

void main() {
  test(
    'ready configuration is copied without rendering its private key',
    () async {
      final process = FakeStudioMcpProcess();
      final service = StudioMcpService(launch: () async => process);
      addTearDown(service.dispose);
      expect(service.readyClientConfiguration, isNull);
      final starting = service.start();
      await flush();
      expect(service.state, StudioMcpState.starting);
      expect(service.readyClientConfiguration, isNull);
      process.ready();
      await starting;
      expect(service.state, StudioMcpState.ready);
      final copied = service.readyClientConfiguration!;
      expect(copied, contains('Bearer secret'));
      expect(copied, contains('http://127.0.0.1:43210/mcp'));
      expect(copied, service.connection!.clientConfiguration);
      expect(service.error, isNull);
      expect(service.diagnosticCode, isNull);
      expect(service.error ?? '', isNot(contains('secret')));
      expect(service.connection.toString(), isNot(contains('secret')));
      expect(service.connection!.url.toString(), isNot(contains('secret')));
      await service.stop();
      expect(service.state, StudioMcpState.stopped);
      expect(service.readyClientConfiguration, isNull);
    },
  );

  test(
    'a configuration is never copyable once the service has failed',
    () async {
      final process = FakeStudioMcpProcess();
      final service = StudioMcpService(launch: () async => process);
      addTearDown(service.dispose);
      final starting = service.start();
      await flush();
      process.ready();
      await starting;
      expect(service.readyClientConfiguration, isNotNull);
      process.exit.complete(1);
      await flush();
      expect(service.state, StudioMcpState.failed);
      expect(service.readyClientConfiguration, isNull);
      expect(service.connection, isNull);
    },
  );

  test('failed service remains actionable and a retry is explicit', () async {
    var attempts = 0;
    final process = FakeStudioMcpProcess();
    final service = StudioMcpService(
      launch: () async {
        attempts++;
        if (attempts == 1) throw StateError('private detail secret');
        return process;
      },
    );
    addTearDown(service.dispose);
    await service.start();
    expect(service.state, StudioMcpState.failed);
    expect(service.readyClientConfiguration, isNull);
    expect(service.connection, isNull);
    expect(service.error, isNotNull);
    expect(service.error, isNot(contains('secret')));
    expect(service.error, isNot(contains('private detail')));
    expect(service.diagnosticCode, isNot(contains('secret')));
    expect(service.diagnosticCode, isNot(contains('private detail')));
    expect(attempts, 1);
    await flush();
    expect(attempts, 1);
    final retrying = service.retry();
    await flush();
    expect(attempts, 2);
    expect(service.state, StudioMcpState.starting);
    expect(service.readyClientConfiguration, isNull);
    process.ready();
    await retrying;
    expect(service.state, StudioMcpState.ready);
    expect(service.error, isNull);
    expect(service.readyClientConfiguration, contains('Bearer secret'));
    await service.stop();
  });

  test('retry does nothing while the service is ready or starting', () async {
    var attempts = 0;
    final process = FakeStudioMcpProcess();
    final service = StudioMcpService(
      launch: () async {
        attempts++;
        return process;
      },
    );
    addTearDown(service.dispose);
    final starting = service.start();
    await flush();
    await service.retry();
    expect(attempts, 1);
    process.ready();
    await starting;
    await service.retry();
    expect(attempts, 1);
    expect(service.state, StudioMcpState.ready);
    await service.stop();
  });
}
