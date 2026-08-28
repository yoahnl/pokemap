import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/compiled_dart_executable.dart';

void main() {
  late Future<CompiledDartExecutable> cli;

  setUpAll(() {
    cli = CompiledDartExecutable.build(
      entrypoint: 'bin/pokemap_authoring.dart',
      name: 'pokemap_authoring',
    );
  });

  tearDownAll(() async {
    await (await cli).dispose();
  });

  group('pokemap_authoring CLI', () {
    test('runs the real authoring JSONL session with read API parity',
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
        executable: await cli,
        root: fixture.parent.path,
      );
      addTearDown(session.dispose);

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
      expect(opened.data['readOnly'], isFalse);
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
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('requires at least one allowed root without polluting stdout',
        () async {
      expect(File('bin/pokemap_authoring.dart').existsSync(), isTrue);

      final result = await (await cli).run(const <String>[]);

      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('--root'));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('stages an artifact from a dedicated non-project root', () async {
      final fixture = _fixture();
      final artifactRoot = await Directory.systemTemp.createTemp(
        'pokemap-artifact-root-',
      );
      addTearDown(() => artifactRoot.delete(recursive: true));
      final artifact = File(
        '${artifactRoot.path}${Platform.pathSeparator}generated.txt',
      );
      await artifact.writeAsString('generated outside the project');
      final session = await _CliSession.start(
        executable: await cli,
        root: fixture.parent.path,
        artifactRoot: artifactRoot.path,
      );
      addTearDown(session.dispose);

      final staged = await session.send(
        id: 'stage-dedicated-artifact-root',
        command: 'stage_artifact',
        args: {
          'sourcePath': artifact.path,
          'declaredMediaType': 'text/plain',
        },
      );
      final completed = await session.finish();

      expect(staged.status, AuthoringResultStatus.success);
      expect(staged.data['artifactHandle'], startsWith('artifact://sha256/'));
      expect(completed.exitCode, AuthoringCliExitCodes.success);
      expect(completed.stderr, isEmpty);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('rejects an option token used as a root value', () async {
      final result = await (await cli).run(
        [
          '--root',
          '--timeout-ms',
        ],
      );

      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('--root requires a value'));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('does not echo an unknown machine-local argument', () async {
      const secretArgument = '/Users/secret/project';
      final result = await (await cli).run(
        [
          secretArgument,
        ],
      );

      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isNot(contains(secretArgument)));
      expect(result.stderr, contains('Unknown command-line option'));
    }, timeout: const Timeout(Duration(minutes: 3)));
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

  static Future<_CliSession> start({
    required CompiledDartExecutable executable,
    required String root,
    String? artifactRoot,
  }) async {
    final process = await executable.start(
      [
        '--root',
        root,
        if (artifactRoot != null) ...[
          '--artifact-root',
          artifactRoot,
        ],
        '--timeout-ms',
        '5000',
        '--max-input-bytes',
        '65536',
      ],
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
          const Duration(seconds: 30),
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
      const Duration(seconds: 30),
    );
    await _stdoutLines.cancel();
    _finished = true;
    return _CliCompletion(
      exitCode: exitCode,
      stderr: await _stderr,
      rawResponses: List.unmodifiable(_rawResponses),
    );
  }

  bool _finished = false;

  Future<void> dispose() async {
    if (_finished) return;
    await CompiledDartExecutable.terminate(_process);
    await _stdoutLines.cancel();
    await _stderr;
    _finished = true;
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
