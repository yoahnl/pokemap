import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'writes one passing six-platform receipt for the repository HEAD',
    () async {
      final fixture = await _createRepository();
      addTearDown(() => fixture.root.delete(recursive: true));
      final output = File(p.join(fixture.root.path, 'aggregate.json'));

      final result = await _runCli(fixture, output);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final receipt =
          jsonDecode(await output.readAsString()) as Map<String, Object?>;
      expect(receipt['releaseCommit'], fixture.head);
      expect(receipt['bundleVersion'], '1.0.1+3');
      expect(receipt['verdict'], 'passed');
      expect(receipt['blockingPlatforms'], isEmpty);
      expect(receipt['platforms'], hasLength(6));
      final plugins = receipt['pluginVersions']! as Map<String, Object?>;
      expect(plugins['video_player'], '2.13.0');
      expect(plugins['audioplayers'], '6.8.1');
    },
  );

  test('writes a failed receipt and exits one without masking a red', () async {
    final fixture = await _createRepository(redPlatform: 'android');
    addTearDown(() => fixture.root.delete(recursive: true));
    final output = File(p.join(fixture.root.path, 'aggregate.json'));

    final result = await _runCli(fixture, output);

    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    final receipt =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(receipt['verdict'], 'failed');
    expect(receipt['blockingPlatforms'], <String>['android']);
  });

  test('rejects a dirty repository without writing a receipt', () async {
    final fixture = await _createRepository();
    addTearDown(() => fixture.root.delete(recursive: true));
    final output = File(p.join(fixture.root.path, 'aggregate.json'));
    await File(
      p.join(fixture.root.path, 'tracked.txt'),
    ).writeAsString('dirty\n');

    final result = await _runCli(fixture, output);

    expect(result.exitCode, 2);
    expect(result.stderr, contains('clean tree'));
    expect(output.existsSync(), isFalse);
  });

  test('rejects certification inputs outside the repository', () async {
    final fixture = await _createRepository();
    addTearDown(() => fixture.root.delete(recursive: true));
    final externalRoot = await Directory.systemTemp.createTemp(
      'cin-028-external-',
    );
    addTearDown(() => externalRoot.delete(recursive: true));
    final externalSupport = File(
      p.join(externalRoot.path, 'platform_support.json'),
    );
    await fixture.platformSupport.copy(externalSupport.path);
    final output = File(p.join(fixture.root.path, 'aggregate.json'));

    final result = await _runCli(
      fixture,
      output,
      platformSupport: externalSupport,
    );

    expect(result.exitCode, 2);
    expect(result.stderr, contains('inside the repository'));
    expect(output.existsSync(), isFalse);
  });
}

Future<ProcessResult> _runCli(
  _RepositoryFixture fixture,
  File output, {
  File? platformSupport,
}) => Process.run('dart', <String>[
  'run',
  'bin/certify_platform_matrix.dart',
  '--repository-root',
  fixture.root.path,
  '--platform-support',
  (platformSupport ?? fixture.platformSupport).path,
  '--platform-evidence',
  fixture.platformEvidence.path,
  '--plugin-lock',
  fixture.pluginLock.path,
  '--app-pubspec',
  fixture.appPubspec.path,
  '--output',
  output.path,
], workingDirectory: Directory.current.path);

Future<_RepositoryFixture> _createRepository({String? redPlatform}) async {
  final root = await Directory.systemTemp.createTemp('cin-028-cli-');
  await _git(root, <String>['init', '-q']);
  await _git(root, <String>['config', 'user.email', 'cin028@test']);
  await _git(root, <String>['config', 'user.name', 'CIN-028']);
  await File(p.join(root.path, 'tracked.txt')).writeAsString('tracked\n');
  await _git(root, <String>['add', 'tracked.txt']);
  await _git(root, <String>['commit', '-q', '-m', 'source evidence']);
  final sourceCommit = await _git(root, const <String>['rev-parse', 'HEAD']);

  final support = File(p.join(root.path, 'platform_support.json'));
  final evidence = File(p.join(root.path, 'platform_evidence.json'));
  final pluginLock = File(p.join(root.path, 'pubspec.lock'));
  final appPubspec = File(p.join(root.path, 'pubspec.yaml'));
  await support.writeAsString(jsonEncode(_platformSupport()));
  await evidence.writeAsString(
    jsonEncode(
      _platformEvidence(sourceCommit: sourceCommit, redPlatform: redPlatform),
    ),
  );
  await pluginLock.writeAsString('''
packages:
  audioplayers:
    dependency: transitive
    version: "6.8.1"
  video_player:
    dependency: direct main
    version: "2.13.0"
''');
  await appPubspec.writeAsString('''
name: pokemap_hub
version: 1.0.1+3
''');
  await _git(root, <String>[
    'add',
    support.path,
    evidence.path,
    pluginLock.path,
    appPubspec.path,
  ]);
  await _git(root, <String>['commit', '-q', '-m', 'platform receipts']);
  final head = await _git(root, const <String>['rev-parse', 'HEAD']);
  return _RepositoryFixture(
    root: root,
    platformSupport: support,
    platformEvidence: evidence,
    pluginLock: pluginLock,
    appPubspec: appPubspec,
    head: head,
  );
}

Future<String> _git(Directory root, List<String> arguments) async {
  final result = await Process.run('git', <String>[
    '-C',
    root.path,
    ...arguments,
  ]);
  if (result.exitCode != 0) {
    throw StateError('${result.stdout}\n${result.stderr}');
  }
  return result.stdout.toString().trim();
}

final class _RepositoryFixture {
  const _RepositoryFixture({
    required this.root,
    required this.platformSupport,
    required this.platformEvidence,
    required this.pluginLock,
    required this.appPubspec,
    required this.head,
  });

  final Directory root;
  final File platformSupport;
  final File platformEvidence;
  final File pluginLock;
  final File appPubspec;
  final String head;
}

Map<String, Object?> _platformSupport() => <String, Object?>{
  'schemaVersion': 2,
  'platforms': <String, Object?>{
    'macos': _support('supported', 'supported'),
    'ios': _support('xcode-cloud-target', 'supported'),
    'android': _support('build-target', 'supported'),
    'windows': _support(
      'build-and-launch-target',
      'target',
      video: 'fallback-only',
    ),
    'linux': _support(
      'build-and-launch-target',
      'target',
      video: 'fallback-only',
    ),
    'web': _support('unsupported', 'unsupported'),
  },
};

Map<String, Object?> _support(
  String status,
  String capability, {
  String? video,
}) => <String, Object?>{
  'status': status,
  'capabilities': <String, Object?>{
    'image': capability,
    'audio': capability,
    'video': video ?? capability,
    'captions': capability,
  },
};

Map<String, Object?> _platformEvidence({
  required String sourceCommit,
  String? redPlatform,
}) => <String, Object?>{
  'schemaVersion': 1,
  'platforms': <Object?>[
    _evidence(
      platform: 'macos',
      verdict: 'supported',
      ticket: 'BETA-CIN-045',
      commit: sourceCommit,
      build: 'passed',
      smoke: 'passed',
      packageManager: 'spm-only',
      bundleId: 'app.pokemap.hub',
      redPlatform: redPlatform,
    ),
    _evidence(
      platform: 'ios',
      verdict: 'supported',
      ticket: 'BETA-CIN-046',
      commit: sourceCommit,
      build: 'passed',
      smoke: 'passed',
      packageManager: 'spm-only',
      bundleId: 'com.yoahnl.avelune.player',
      limitations: const <String>['physical-launch-deferred'],
      redPlatform: redPlatform,
    ),
    _evidence(
      platform: 'android',
      verdict: 'supported',
      ticket: 'BETA-CIN-046',
      commit: sourceCommit,
      build: 'passed',
      smoke: 'equivalent',
      packageManager: 'gradle',
      bundleId: 'com.yoahnl.avelune.player',
      limitations: const <String>['device-smoke-unavailable'],
      redPlatform: redPlatform,
    ),
    for (final platform in <String>['windows', 'linux'])
      _evidence(
        platform: platform,
        verdict: 'fallback-only',
        ticket: 'BETA-CIN-047',
        commit: sourceCommit,
        build: 'target',
        smoke: 'target',
        packageManager: 'native-runner',
        limitations: const <String>['video-poster-fallback-required'],
        redPlatform: redPlatform,
      ),
    _evidence(
      platform: 'web',
      verdict: 'out-of-scope',
      ticket: 'BETA-CIN-047',
      commit: sourceCommit,
      build: 'not-applicable',
      smoke: 'not-applicable',
      packageManager: 'none',
      limitations: const <String>['no-certified-runner'],
      redPlatform: redPlatform,
    ),
  ],
};

Map<String, Object?> _evidence({
  required String platform,
  required String verdict,
  required String ticket,
  required String commit,
  required String build,
  required String smoke,
  required String packageManager,
  required String? redPlatform,
  String? bundleId,
  List<String> limitations = const <String>[],
}) => <String, Object?>{
  'platform': platform,
  'verdict': verdict,
  'status': redPlatform == platform ? 'failed' : 'passed',
  'sourceTicket': ticket,
  'sourceCommit': commit,
  'build': build,
  'smoke': smoke,
  'policy': 'passed',
  'packageManager': packageManager,
  'bundleId': bundleId,
  'commands': <String>['flutter test test/release/platform_gate_test.dart'],
  'limitations': limitations,
};
