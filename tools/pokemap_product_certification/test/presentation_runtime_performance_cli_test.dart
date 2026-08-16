import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('certifies a complete macOS CIN-038 measurement payload', () async {
    final root = await Directory.systemTemp.createTemp('pokemap-cin-038-cli-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final repository = Directory(p.join(root.path, 'repository'))
      ..createSync(recursive: true);
    await _git(repository, <String>['init', '-q']);
    await _git(repository, <String>['config', 'user.email', 'cin038@test']);
    await _git(repository, <String>['config', 'user.name', 'CIN-038']);
    File(p.join(repository.path, 'tracked.txt')).writeAsStringSync('tracked\n');
    await _git(repository, <String>['add', 'tracked.txt']);
    await _git(repository, <String>['commit', '-q', '-m', 'fixture']);
    final measurements = File(p.join(root.path, 'measurements.json'))
      ..writeAsStringSync(jsonEncode(_validMeasurements()));
    final platformSupport = File(p.join(root.path, 'platform_support.json'))
      ..writeAsStringSync(jsonEncode(_platformSupport()));
    final output = File(p.join(root.path, 'receipt.json'));

    final result = await Process.run(
      'dart',
      <String>[
        'run',
        'bin/certify_presentation_runtime_performance.dart',
        '--repository-root',
        repository.path,
        '--measurements',
        measurements.path,
        '--platform-support',
        platformSupport.path,
        '--output',
        output.path,
      ],
      environment: <String, String>{
        ...Platform.environment,
        'FLUTTER_VERSION': '3.46.0-0.3.pre',
        'FLUTTER_REVISION': '677d472756f83c14371dd8cc624387065f3d32a7',
      },
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final receipt = jsonDecode(await output.readAsString());
    expect(receipt, isA<Map<String, Object?>>());
    final json = receipt! as Map<String, Object?>;
    expect(json['benchmark'], 'presentation_runtime_cin_038');
    expect(json['verdict'], 'passed');
    expect(json['supportedPlatforms'], <String>['macos']);
    expect(json['deferredPlatforms'], <String>['ios', 'android']);
    expect((json['provenance']! as Map<String, Object?>)['treeState'], 'clean');
    final provenance = json['provenance']! as Map<String, Object?>;
    expect(
      provenance['treeFingerprint'],
      isNot('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
    );
    expect(
      provenance['command'],
      containsAllInOrder(<String>[
        'dart',
        'run',
        'bin/certify_presentation_runtime_performance.dart',
        '--repository-root',
        repository.path,
      ]),
    );
  });

  test('rejects a dirty repository without writing a receipt', () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap-cin-038-cli-dirty-',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final repository = await _createRepository(root);
    File(p.join(repository.path, 'tracked.txt')).writeAsStringSync('dirty\n');
    final measurements = File(p.join(root.path, 'measurements.json'))
      ..writeAsStringSync(jsonEncode(_validMeasurements()));
    final platformSupport = File(p.join(root.path, 'platform_support.json'))
      ..writeAsStringSync(jsonEncode(_platformSupport()));
    final output = File(p.join(root.path, 'receipt.json'));

    final result = await _runCli(
      repository: repository,
      measurements: measurements,
      platformSupport: platformSupport,
      output: output,
    );

    expect(result.exitCode, 2);
    expect('${result.stderr}', contains('clean tree'));
    expect(output.existsSync(), isFalse);
  });

  test(
    'writes a failed receipt and exits one when a budget is missed',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap-cin-038-cli-budget-',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final repository = await _createRepository(root);
      final payload = _validMeasurements();
      (payload['samples']! as Map<String, Object?>)['skipUs'] =
          List<int>.filled(50, 100000);
      final measurements = File(p.join(root.path, 'measurements.json'))
        ..writeAsStringSync(jsonEncode(payload));
      final platformSupport = File(p.join(root.path, 'platform_support.json'))
        ..writeAsStringSync(jsonEncode(_platformSupport()));
      final output = File(p.join(root.path, 'receipt.json'));

      final result = await _runCli(
        repository: repository,
        measurements: measurements,
        platformSupport: platformSupport,
        output: output,
      );

      expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
      final receipt =
          jsonDecode(await output.readAsString()) as Map<String, Object?>;
      expect(receipt['verdict'], 'failed');
      expect(receipt['violations'], contains('skip.p95'));
    },
  );
}

Future<Directory> _createRepository(Directory root) async {
  final repository = Directory(p.join(root.path, 'repository'))
    ..createSync(recursive: true);
  await _git(repository, <String>['init', '-q']);
  await _git(repository, <String>['config', 'user.email', 'cin038@test']);
  await _git(repository, <String>['config', 'user.name', 'CIN-038']);
  File(p.join(repository.path, 'tracked.txt')).writeAsStringSync('tracked\n');
  await _git(repository, <String>['add', 'tracked.txt']);
  await _git(repository, <String>['commit', '-q', '-m', 'fixture']);
  return repository;
}

Future<ProcessResult> _runCli({
  required Directory repository,
  required File measurements,
  required File platformSupport,
  required File output,
}) => Process.run(
  'dart',
  <String>[
    'run',
    'bin/certify_presentation_runtime_performance.dart',
    '--repository-root',
    repository.path,
    '--measurements',
    measurements.path,
    '--platform-support',
    platformSupport.path,
    '--output',
    output.path,
  ],
  environment: <String, String>{
    ...Platform.environment,
    'FLUTTER_VERSION': '3.46.0-0.3.pre',
    'FLUTTER_REVISION': '677d472756f83c14371dd8cc624387065f3d32a7',
  },
);

Future<void> _git(Directory repository, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: repository.path,
  );
  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
}

Map<String, Object?> _validMeasurements() => <String, Object?>{
  'schemaVersion': 1,
  'benchmark': 'presentation_runtime_cin_038',
  'target':
      'integration_test/presentation_runtime_performance_journey_test.dart',
  'executionMode': 'flutter-profile',
  'platform': 'macos',
  'fixture': <String, Object?>{
    'landscapeVideoAsset': 'assets/certification/intro_landscape_h264_aac.mp4',
    'landscapeVideoSha256':
        '5191da50cdedd4203edc1ccca5e1c3055d7f19c616fb570b0c8af992358fe591',
    'portraitVideoAsset': 'assets/certification/intro_portrait_h264_aac.mp4',
    'portraitVideoSha256':
        'a4759a929512ef967d8a58905f22923e6f15e86707fd7f9100f844880a3972de',
    'posterAsset': 'assets/avelune/artwork/fallback_moonlit_path.webp',
    'posterSha256':
        'd0d048a67dfc9b514d39ec9133ac5c547f5e89c83bde27ba73aa10c75d3a4e10',
  },
  'lifecycle': <String, Object?>{
    'cycles': 50,
    'maximumActiveDecoders': 1,
    'finalActiveDecoders': 0,
    'finalMediaHandles': 0,
    'terminalReceipts': 50,
    'skippedTerminals': 50,
    'rssCycle5Bytes': 1000000,
    'rssCycle50Bytes': 1050000,
  },
  'samples': <String, Object?>{
    'skipUs': List<int>.filled(50, 50000),
    'posterUs': List<int>.filled(50, 200000),
    'videoFirstFrameUs': List<int>.filled(50, 500000),
    'mainIsolateStallUs': List<int>.filled(100, 10000),
    'uiFrameTotalUs': <int>[...List<int>.filled(99, 10000), 20000],
  },
  'cycleEvidence': <Map<String, Object?>>[
    for (var cycle = 1; cycle <= 50; cycle += 1)
      <String, Object?>{
        'cycle': cycle,
        'orientation': cycle.isOdd ? 'landscape' : 'portrait',
        'replay': (cycle + 1) ~/ 2,
        'lifecycle': 'pause-resume',
        'activeDecoderAfterExit': 0,
        'rssAfterCooldownBytes': switch (cycle) {
          5 => 1000000,
          50 => 1050000,
          _ => 1000000,
        },
      },
  ],
};

Map<String, Object?> _platformSupport() => <String, Object?>{
  'schemaVersion': 1,
  'platforms': <String, Object?>{
    'macos': <String, Object?>{'status': 'supported'},
    'ios': <String, Object?>{'status': 'xcode-cloud-target'},
    'android': <String, Object?>{'status': 'build-target'},
    'windows': <String, Object?>{'status': 'build-and-launch-target'},
    'linux': <String, Object?>{'status': 'build-and-launch-target'},
  },
};
