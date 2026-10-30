import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('installed AOT qualification', () {
    late Directory root;
    late File executable;

    setUpAll(() async {
      final home =
          Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME']!;
      final parent = Directory(
          p.join(home, 'Library/Caches/AveluneQA/mcp-studio-integration/i0'));
      await parent.create(recursive: true);
      root = await parent.createTemp('cli été ');
      executable = File(
          p.join(root.path, 'authoring${Platform.isWindows ? '.exe' : ''}'));
      final templates = base64Encode(
          await File('assets/project_templates.v1.json').readAsBytes());
      final compilation = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'exe',
        '-DPOKEMAP_AUTHORING_TEMPLATE_CATALOG_BASE64=$templates',
        'bin/pokemap_authoring.dart',
        '-o',
        executable.path,
      ]);
      expect(compilation.exitCode, 0, reason: '${compilation.stderr}');
    });

    tearDownAll(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('installed AOT discovery works without checkout, roots or SDK PATH',
        () async {
      final result = await _session(executable, root, [
        '--discovery-only'
      ], [
        {'id': 'describe', 'command': 'describe', 'args': <String, Object?>{}},
        {
          'id': 'outside',
          'command': 'open',
          'args': {'projectRoot': p.join(root.path, 'absent')},
        },
      ]);
      expect(result.exitCode, AuthoringCliExitCodes.success,
          reason: '${result.stderr}');
      expect(result.stderr, isEmpty);
      final responses = const LineSplitter()
          .convert(result.stdout as String)
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      expect(responses[0]['status'], 'success');
      expect(responses[1]['status'], 'failure');
      expect((responses[1]['error'] as Map)['code'], 'permission_denied');
      expect(((responses[1]['error'] as Map)['details'] as Map)['domainCode'],
          'workspace.path_outside_allowed_roots');
    });

    test('rootless CLI remains invalid without the explicit discovery flag',
        () async {
      final result = await _session(executable, root, [], []);
      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('--root'));
    });

    test('discovery rejects project, artifact and export root authorizations',
        () async {
      for (final flag in ['--root', '--artifact-root', '--export-root']) {
        final result = await _session(
            executable, root, ['--discovery-only', flag, root.path], []);
        expect(result.exitCode, AuthoringCliExitCodes.usage);
        expect(result.stdout, isEmpty);
        expect(result.stderr, contains('Discovery-only'));
      }
    });
  }, skip: Platform.environment['POKEMAP_RUN_DISTRIBUTION_QA'] != '1');
}

Future<ProcessResult> _session(File executable, Directory root,
    List<String> args, List<Map<String, Object?>> requests) async {
  final child = await Process.start(executable.path, args,
      workingDirectory: root.path,
      environment: {
        'PATH': '',
        if (Platform.isWindows)
          'SystemRoot': Platform.environment['SystemRoot']!
      },
      includeParentEnvironment: false);
  final output = child.stdout.transform(utf8.decoder).join();
  final errors = child.stderr.transform(utf8.decoder).join();
  try {
    for (final request in requests) {
      child.stdin.writeln(jsonEncode(request));
    }
    await child.stdin.close();
    final exitCode = await child.exitCode.timeout(const Duration(seconds: 15));
    return ProcessResult(child.pid, exitCode, await output, await errors);
  } finally {
    if (await child.exitCode
            .timeout(const Duration(seconds: 1), onTimeout: () => -999) ==
        -999) {
      child.kill();
      await child.exitCode.timeout(const Duration(seconds: 2));
    }
  }
}
