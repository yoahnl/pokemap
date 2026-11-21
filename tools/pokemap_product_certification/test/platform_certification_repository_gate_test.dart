import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('committed CIN-045, CIN-046 and CIN-047 receipts aggregate cleanly', () {
    final repository = Directory.current.parent.parent;
    const hub = 'apps/pokemap_hub';
    const evidencePath =
        '$hub/tool/release/platform_certification_evidence.json';
    final revision = _git(repository, [
      'log',
      '-1',
      '--format=%H',
      '--',
      evidencePath,
    ]).trim();
    expect(revision, matches(RegExp(r'^[0-9a-f]{40}$')));
    final supportJson = _git(repository, [
      'show',
      '$revision:$hub/tool/release/platform_support.json',
    ]);
    final lock = _git(repository, ['show', '$revision:$hub/pubspec.lock']);
    final tree = _git(repository, ['ls-tree', '-r', revision]);
    final support = jsonDecode(supportJson) as Map<String, Object?>;
    final evidence = jsonDecode(
      _git(repository, ['show', '$revision:$evidencePath']),
    ) as Map<String, Object?>;
    final sourceCommits = (evidence['platforms']! as List<Object?>)
        .map(
          (entry) =>
              (entry! as Map<String, Object?>)['sourceCommit']! as String,
        )
        .toSet();
    for (final commit in sourceCommits) {
      expect(
        Process.runSync('git', <String>[
          '-C',
          repository.path,
          'cat-file',
          '-e',
          '$commit^{commit}',
        ]).exitCode,
        0,
        reason: commit,
      );
    }

    final receipt = PlatformCertificationAggregateReceipt.fromInputs(
      platformSupport: support,
      platformEvidence: evidence,
      provenance: <String, Object?>{
        'releaseCommit': revision,
        'treeState': 'clean',
        'treeFingerprint': sha256.convert(utf8.encode(tree)).toString(),
        'platformSupportSha256': sha256
            .convert(utf8.encode(supportJson))
            .toString(),
        'pluginLockSha256': sha256.convert(utf8.encode(lock)).toString(),
        'bundleVersion': '1.0.1+3',
        'pluginVersions': <String, Object?>{
          'audioplayers': _version(lock, 'audioplayers'),
          'video_player': _version(lock, 'video_player'),
        },
      },
    );

    expect(receipt.passed, isTrue);
    expect(receipt.blockingPlatforms, isEmpty);
    final platforms = receipt.toJson()['platforms']! as List<Object?>;
    expect(platforms.map((entry) => (entry! as Map)['verdict']), <String>[
      'supported',
      'supported',
      'supported',
      'fallback-only',
      'fallback-only',
      'out-of-scope',
    ]);
  });
}

String _git(Directory repository, List<String> arguments) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: repository.path,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return result.stdout as String;
}

String _version(String lock, String package) {
  final match = RegExp(
    '^  $package:\\n(?:    .*\\n)*?    version: "?([^"\\n]+)"?',
    multiLine: true,
  ).firstMatch(lock);
  if (match == null) throw StateError('$package is absent from the lock.');
  return match.group(1)!;
}
