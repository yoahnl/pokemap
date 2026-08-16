import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('committed CIN-045, CIN-046 and CIN-047 receipts aggregate cleanly', () {
    final repository = Directory.current.parent.parent;
    final supportFile = File(
      '${repository.path}/apps/pokemap_hub/tool/release/platform_support.json',
    );
    final evidenceFile = File(
      '${repository.path}/apps/pokemap_hub/tool/release/'
      'platform_certification_evidence.json',
    );
    final lockFile = File('${repository.path}/apps/pokemap_hub/pubspec.lock');
    final support =
        jsonDecode(supportFile.readAsStringSync()) as Map<String, Object?>;
    final evidence =
        jsonDecode(evidenceFile.readAsStringSync()) as Map<String, Object?>;
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
        'releaseCommit': 'a' * 40,
        'treeState': 'clean',
        'treeFingerprint': 'b' * 64,
        'platformSupportSha256': sha256
            .convert(supportFile.readAsBytesSync())
            .toString(),
        'pluginLockSha256': sha256
            .convert(lockFile.readAsBytesSync())
            .toString(),
        'bundleVersion': '1.0.1+3',
        'pluginVersions': <String, Object?>{
          'audioplayers': _version(lockFile, 'audioplayers'),
          'video_player': _version(lockFile, 'video_player'),
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

String _version(File lockFile, String package) {
  final match = RegExp(
    '^  $package:\\n(?:    .*\\n)*?    version: "?([^"\\n]+)"?',
    multiLine: true,
  ).firstMatch(lockFile.readAsStringSync());
  if (match == null) throw StateError('$package is absent from the lock.');
  return match.group(1)!;
}
