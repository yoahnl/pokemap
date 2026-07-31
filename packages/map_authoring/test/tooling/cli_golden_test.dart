import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('pokemap_authoring CLI', () {
    test('runs the real read-only JSONL session with direct API parity',
        () async {
      expect(
        File('bin/pokemap_authoring.dart').existsSync(),
        isTrue,
        reason: 'The declared CLI executable must exist.',
      );
      final fixture = _fixture();
      final directApi = await _directApi(fixture);
      final directOpened = await directApi.open(fixture.path);
      final projectQuery = AuthoringQueryRequest(
        resourceKind: 'project',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.summary,
        ids: const ['project'],
      );
      final directQuery = await directApi.query(
        ProjectHandle(directOpened['projectHandle']! as String),
        projectQuery,
      );
      final session = await _CliSession.start(
        root: fixture.parent.path,
      );

      final malformed = await session.sendRaw('{');
      final described = await session.send(
        id: 'describe-cli',
        command: 'describe',
      );
      final opened = await session.send(
        id: 'open-cli',
        command: 'open',
        args: {'projectRoot': fixture.path},
      );
      final queried = await session.send(
        id: 'query-cli',
        command: 'query',
        args: {
          'projectHandle': opened.data['projectHandle'],
          'request': projectQuery.toJson(),
        },
      );
      final validated = await session.send(
        id: 'validate-cli',
        command: 'validate',
        args: {'projectHandle': opened.data['projectHandle']},
      );
      final closed = await session.send(
        id: 'close-cli',
        command: 'close',
        args: {'workspaceHandle': opened.data['workspaceHandle']},
      );
      final completed = await session.finish();

      expect(malformed.status, AuthoringResultStatus.failure);
      expect(malformed.error?.code, AuthoringErrorCode.invalidRequest);
      expect(described.status, AuthoringResultStatus.success);
      expect(opened.status, AuthoringResultStatus.success);
      expect(opened.data['readOnly'], isTrue);
      expect(queried.data, directQuery);
      expect(validated.status, AuthoringResultStatus.success);
      expect(validated.data['references'], isA<Map<String, Object?>>());
      expect(closed.data, {'closed': true});
      expect(completed.exitCode, AuthoringCliExitCodes.success);
      expect(completed.stderr, isEmpty);
      expect(
        completed.rawResponses.every((line) {
          if (line.contains('\n')) return false;
          return jsonDecode(line) is Map;
        }),
        isTrue,
      );
      expect(
        completed.rawResponses.join(),
        isNot(contains(fixture.parent.path)),
      );
    });

    test('requires at least one allowed root without polluting stdout',
        () async {
      expect(File('bin/pokemap_authoring.dart').existsSync(), isTrue);

      final result = await Process.run(
        Platform.resolvedExecutable,
        ['bin/pokemap_authoring.dart'],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('--root'));
    });

    test('rejects an option token used as a root value', () async {
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          'bin/pokemap_authoring.dart',
          '--root',
          '--timeout-ms',
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('--root requires a value'));
    });

    test('does not echo an unknown machine-local argument', () async {
      const secretArgument = '/Users/secret/project';
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          'bin/pokemap_authoring.dart',
          secretArgument,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isNot(contains(secretArgument)));
      expect(result.stderr, contains('Unknown command-line option'));
    });
  });
}

Directory _fixture() {
  return Directory(
    [
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'p3_narrative_smoke_slice',
    ].join(Platform.pathSeparator),
  );
}

Future<AuthoringReadApi> _directApi(Directory fixture) async {
  var token = 0;
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [fixture.parent.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore(
    clock: () => DateTime.utc(2026, 7, 31, 12),
    tokenFactory: (prefix) => '$prefix${token++}',
  );
  return AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ),
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
  );
}

final class _CliSession {
  _CliSession._({
    required Process process,
    required StreamIterator<String> stdoutLines,
    required Future<String> stderr,
  })  : _process = process,
        _stdoutLines = stdoutLines,
        _stderr = stderr;

  final Process _process;
  final StreamIterator<String> _stdoutLines;
  final Future<String> _stderr;
  final List<String> _rawResponses = [];

  static Future<_CliSession> start({required String root}) async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      [
        'bin/pokemap_authoring.dart',
        '--root',
        root,
        '--timeout-ms',
        '5000',
        '--max-input-bytes',
        '65536',
      ],
      workingDirectory: Directory.current.path,
    );
    return _CliSession._(
      process: process,
      stdoutLines: StreamIterator(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
      ),
      stderr: process.stderr.transform(utf8.decoder).join(),
    );
  }

  Future<AuthoringResult> send({
    required String id,
    required String command,
    Map<String, Object?> args = const {},
  }) {
    return sendRaw(
      jsonEncode({
        'id': id,
        'command': command,
        'args': args,
      }),
    );
  }

  Future<AuthoringResult> sendRaw(String line) async {
    _process.stdin.writeln(line);
    await _process.stdin.flush();
    final hasLine = await _stdoutLines.moveNext().timeout(
          const Duration(seconds: 10),
        );
    if (!hasLine) {
      throw StateError('CLI closed stdout before returning a response.');
    }
    final response = _stdoutLines.current;
    _rawResponses.add(response);
    return AuthoringResult.fromJson(
      Map<String, dynamic>.from(jsonDecode(response) as Map),
    );
  }

  Future<_CliCompletion> finish() async {
    await _process.stdin.close();
    final exitCode = await _process.exitCode.timeout(
      const Duration(seconds: 10),
    );
    await _stdoutLines.cancel();
    return _CliCompletion(
      exitCode: exitCode,
      stderr: await _stderr,
      rawResponses: List.unmodifiable(_rawResponses),
    );
  }
}

final class _CliCompletion {
  const _CliCompletion({
    required this.exitCode,
    required this.stderr,
    required this.rawResponses,
  });

  final int exitCode;
  final String stderr;
  final List<String> rawResponses;
}
