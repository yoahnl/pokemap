import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('tracked CIN-008 evidence passes with every dependency complete', () {
    final repository = Directory.current.parent.parent;
    final evidenceFile = File(
      '${repository.path}/tools/pokemap_product_certification/'
      'tool/cinematic_v2/cinematic_v2_final_evidence.json',
    );
    final input =
        jsonDecode(evidenceFile.readAsStringSync()) as Map<String, Object?>;
    final dependencies = (input['dependencies']! as List<Object?>)
        .map(
          (entry) => CinematicV2FinalDependency.fromJson(
            (entry! as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);
    final evidence = (input['evidence']! as List<Object?>)
        .map(
          (entry) => CinematicV2FinalEvidence.fromJson(
            (entry! as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);

    for (final entry in evidence) {
      final commit = Process.runSync('git', <String>[
        '-C',
        repository.path,
        'cat-file',
        'commit',
        entry.sourceCommit,
      ]);
      expect(commit.exitCode, 0, reason: entry.sourceCommit);
      if (entry.status != CinematicV2FinalEvidenceStatus.blocked) {
        expect(
          entry.resultSha256,
          sha256.convert(utf8.encode(commit.stdout! as String)).toString(),
          reason: entry.id.name,
        );
      }
      expect(
        Process.runSync('git', <String>[
          '-C',
          repository.path,
          'merge-base',
          '--is-ancestor',
          entry.sourceCommit,
          'HEAD',
        ]).exitCode,
        0,
        reason: entry.sourceCommit,
      );
    }

    final receipt = CinematicV2FinalCertificationReceipt(
      releaseCommit: 'a' * 40,
      treeFingerprint: 'b' * 64,
      evidenceSha256: sha256.convert(evidenceFile.readAsBytesSync()).toString(),
      dependencies: dependencies,
      evidence: evidence,
    );

    expect(receipt.passed, isTrue);
    expect(receipt.blockingDependencies, isEmpty);
    expect(receipt.blockingEvidence, isEmpty);
  });
}
