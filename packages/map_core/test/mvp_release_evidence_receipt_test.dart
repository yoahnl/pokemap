import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MvpReleaseEvidenceReceipt', () {
    test('round-trips validated execution metadata and observations', () {
      final receipt = _receipt();
      final decoded = MvpReleaseEvidenceReceipt.fromJson(receipt.toJson());

      expect(decoded.schemaVersion, 1);
      expect(decoded.command, receipt.command);
      expect(decoded.releaseCandidateCommit, 'a' * 40);
      expect(decoded.projectTreeHashSha256, 'b' * 64);
      expect(decoded.capturedAtUtc, DateTime.utc(2026, 7, 23, 12));
      expect(decoded.criteria, hasLength(19));
      expect(decoded.isSuccessful, isTrue);
    });

    test('rejects blank provenance, malformed digests and non-UTC timestamps',
        () {
      expect(
        () => _receipt(source: ' '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _receipt(commit: 'short'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _receipt(treeHash: 'invalid'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _receipt(capturedAtUtc: DateTime(2026, 7, 23)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fails strict JSON decoding on unknown criteria or schema', () {
      final unknownCriterion = _receipt().toJson();
      (unknownCriterion['criteria'] as List<dynamic>)[0] = <String, dynamic>{
        'criterion': 'MVP-99',
        'status': 'passed',
        'summary': 'Unknown.',
        'source': 'test',
      };
      final futureSchema = _receipt().toJson()..['schemaVersion'] = 2;

      expect(
        () => MvpReleaseEvidenceReceipt.fromJson(unknownCriterion),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => MvpReleaseEvidenceReceipt.fromJson(futureSchema),
        throwsA(isA<FormatException>()),
      );
    });

    test('derives success from the command and every observed criterion', () {
      expect(_receipt(exitCode: 1).isSuccessful, isFalse);
      final criteria = _criteria()
          .map(
            (item) => item.criterion == MvpProductCriterion.mvp08Capture
                ? const MvpProductCriterionEvidence(
                    criterion: MvpProductCriterion.mvp08Capture,
                    status: MvpProductCriterionStatus.failed,
                    summary: 'Capture failed.',
                    source: 'journey',
                  )
                : item,
          )
          .toList(growable: false);
      expect(_receipt(criteria: criteria).isSuccessful, isFalse);
    });
  });
}

MvpReleaseEvidenceReceipt _receipt({
  String source = 'test/selbrume_player_journey_e2e_test.dart',
  String commit = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  String treeHash =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  DateTime? capturedAtUtc,
  int exitCode = 0,
  List<MvpProductCriterionEvidence>? criteria,
}) {
  return MvpReleaseEvidenceReceipt.validated(
    command: 'flutter test test/selbrume_player_journey_e2e_test.dart',
    exitCode: exitCode,
    releaseCandidateCommit: commit,
    capturedAtUtc: capturedAtUtc ?? DateTime.utc(2026, 7, 23, 12),
    source: source,
    projectTreeHashSha256: treeHash,
    criteria: criteria ?? _criteria(),
  );
}

List<MvpProductCriterionEvidence> _criteria() => MvpProductCriterion.values
    .map(
      (criterion) => MvpProductCriterionEvidence(
        criterion: criterion,
        status: MvpProductCriterionStatus.passed,
        summary: '${criterion.id} observed.',
        source: 'journey:${criterion.id}',
      ),
    )
    .toList(growable: false);
