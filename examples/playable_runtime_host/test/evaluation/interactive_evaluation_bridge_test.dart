import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_state_snapshot.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/interactive/interactive_evaluation_bridge.dart';
import 'package:pokemap_loader/src/evaluation/interactive/interactive_evaluation_config.dart';

const _token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('bridge authenticates before announcing runtime readiness', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final serverSide = _acceptBridge(
      server,
      response: const <String, Object?>{
        'type': 'bridge.accepted',
        'protocolVersion': 1,
      },
    );
    final bridge = InteractiveEvaluationBridge(
      config: _config(server.port),
      driver: _FakeEvaluationDriver(),
    );
    addTearDown(bridge.dispose);

    await bridge.connect();
    final connection = await serverSide;

    expect(connection.hello['type'], 'bridge.hello');
    expect(connection.hello['token'], _token);
    expect(connection.hello['target'], 'interactive');
    expect(connection.ready['type'], 'bridge.ready');
    await connection.close();
  });

  test('bridge stops when the orchestrator rejects authentication', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final serverSide = _acceptBridge(
      server,
      response: const <String, Object?>{
        'type': 'bridge.rejected',
        'reason': 'invalid token',
      },
      expectReady: false,
    );
    final bridge = InteractiveEvaluationBridge(
      config: _config(server.port),
      driver: _FakeEvaluationDriver(),
    );
    addTearDown(bridge.dispose);

    await expectLater(
      bridge.connect(),
      throwsA(isA<InteractiveEvaluationAuthenticationException>()),
    );
    await (await serverSide).close();
  });

  test('bridge revalidates policy inside the runtime', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final serverSide = _acceptBridge(
      server,
      response: const <String, Object?>{
        'type': 'bridge.accepted',
        'protocolVersion': 1,
      },
    );
    final bridge = InteractiveEvaluationBridge(
      config: _config(server.port),
      driver: _FakeEvaluationDriver(),
    );
    addTearDown(bridge.dispose);

    await bridge.connect();
    final connection = await serverSide;
    connection.socket.writeln(
      jsonEncode(<String, Object?>{
        'type': 'run',
        'requestId': 'request-1',
        'runId': 'run-policy',
        'scenario': jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'id': 'selbrume.interactive-policy',
          'title': 'Interactive policy',
          'projectId': 'selbrume',
          'policy': 'certify',
          'start': <String, Object?>{'newGame': true},
          'steps': <Map<String, Object?>>[
            <String, Object?>{
              'id': 'forbidden',
              'command': 'probe.goto',
              'mapId': 'map_port_brisants',
              'x': 12,
              'y': 8,
            },
          ],
        }),
      }),
    );

    final result = await connection.nextJson();
    expect(result['type'], 'bridge.result');
    expect(result['status'], 'policyViolation');
    expect(result['exitCode'], 4);
    expect(result['requestId'], 'request-1');
    expect(result['runId'], 'run-policy');
    await connection.close();
  });
}

InteractiveEvaluationConfig _config(int port) =>
    InteractiveEvaluationConfig.resolve(
      isReleaseMode: false,
      enabledDefine: true,
      hostDefine: '127.0.0.1',
      portDefine: '$port',
      tokenDefine: _token,
      projectDefine: 'selbrume/project.json',
    );

Future<_BridgeConnection> _acceptBridge(
  ServerSocket server, {
  required Map<String, Object?> response,
  bool expectReady = true,
}) async {
  final socket = await server.first;
  final lines = StreamIterator<String>(
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter()),
  );
  final hello = await _nextJson(lines);
  socket.writeln(jsonEncode(response));
  final ready =
      expectReady ? await _nextJson(lines) : const <String, Object?>{};
  return _BridgeConnection(
    socket: socket,
    lines: lines,
    hello: hello,
    ready: ready,
  );
}

Future<Map<String, Object?>> _nextJson(StreamIterator<String> lines) async {
  if (!await lines.moveNext()) {
    throw const FormatException('Bridge socket closed before a JSONL message.');
  }
  final decoded = jsonDecode(lines.current);
  if (decoded is! Map) {
    throw const FormatException('Bridge message must be a JSON object.');
  }
  return Map<String, Object?>.from(decoded);
}

final class _BridgeConnection {
  const _BridgeConnection({
    required this.socket,
    required this.lines,
    required this.hello,
    required this.ready,
  });

  final Socket socket;
  final StreamIterator<String> lines;
  final Map<String, Object?> hello;
  final Map<String, Object?> ready;

  Future<Map<String, Object?>> nextJson() => _nextJson(lines);

  Future<void> close() async {
    await lines.cancel();
    await socket.close();
  }
}

final class _FakeEvaluationDriver implements EvaluationDriver {
  @override
  EvaluationStateSnapshot snapshot() => EvaluationStateSnapshot(
        projectId: 'selbrume',
        runId: 'interactive-test',
        mapId: 'map_port_brisants',
        x: 12,
        y: 8,
        movementMode: 'walk',
        money: 1000,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
