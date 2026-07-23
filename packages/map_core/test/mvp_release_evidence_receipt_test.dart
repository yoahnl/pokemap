import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MvpReleaseEvidenceReceipt', () {
    test('round-trips validated execution metadata and observations', () {
      final receipt = _receipt();
      final decoded = MvpReleaseEvidenceReceipt.fromJson(receipt.toJson());

      expect(decoded.schemaVersion, 2);
      expect(decoded.command, receipt.command);
      expect(decoded.workingDirectory, '/workspace/pokemonProject');
      expect(decoded.durationMilliseconds, 4200);
      expect(decoded.releaseCandidateCommit, 'a' * 40);
      expect(decoded.projectTreeHashSha256, 'b' * 64);
      expect(decoded.packageSha256, 'c' * 64);
      expect(decoded.capturedAtUtc, DateTime.utc(2026, 7, 23, 12));
      expect(decoded.sources, hasLength(2));
      expect(decoded.criteria, hasLength(19));
      expect(
        decoded.technicalCriteria,
        hasLength(MvpReleaseGateCriterion.values.length),
      );
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
        () => _receipt(packageSha: 'invalid'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _receipt(durationMilliseconds: -1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _receipt(sources: const ['same', 'same']),
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
      final futureSchema = _receipt().toJson()..['schemaVersion'] = 3;

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
      expect(
        _receipt(
          technicalCriteria: _technicalCriteria()
              .where(
                (item) =>
                    item.criterion !=
                    MvpReleaseGateCriterion.criticalPackageTests,
              )
              .toList(growable: false),
        ).isReleaseSuccessful,
        isFalse,
      );
    });

    test('round-trips embedded technical execution receipts strictly', () {
      final json = _receipt().toJson();
      final technical = json['technicalCriteria'] as List<dynamic>;
      final first = (technical.first as Map).cast<String, dynamic>();

      expect(
        MvpReleaseGateExecutionReceipt.fromJson(first).toJson(),
        first,
      );

      first['criterion'] = 'unknown';
      expect(
        () => MvpReleaseEvidenceReceipt.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

MvpReleaseEvidenceReceipt _receipt({
  String source = 'test/selbrume_player_journey_e2e_test.dart',
  String commit = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  String treeHash =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  String packageSha =
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
  DateTime? capturedAtUtc,
  int durationMilliseconds = 4200,
  int exitCode = 0,
  List<String>? sources,
  List<MvpProductCriterionEvidence>? criteria,
  List<MvpReleaseGateExecutionReceipt>? technicalCriteria,
}) {
  return MvpReleaseEvidenceReceipt.validated(
    command: 'flutter test test/selbrume_player_journey_e2e_test.dart',
    workingDirectory: '/workspace/pokemonProject',
    durationMilliseconds: durationMilliseconds,
    exitCode: exitCode,
    releaseCandidateCommit: commit,
    capturedAtUtc: capturedAtUtc ?? DateTime.utc(2026, 7, 23, 12),
    source: source,
    projectTreeHashSha256: treeHash,
    packageSha256: packageSha,
    sources: sources ?? const ['journey', 'release-matrix'],
    criteria: criteria ?? _criteria(),
    technicalCriteria: technicalCriteria ?? _technicalCriteria(),
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

List<MvpReleaseGateExecutionReceipt> _technicalCriteria() =>
    MvpReleaseGateCriterion.values
        .map(
          (criterion) => MvpReleaseGateExecutionReceipt.validated(
            criterion: criterion,
            summary: '${criterion.name} executed.',
            source: 'release:${criterion.name}',
            releaseCandidateCommit: 'a' * 40,
            command: 'flutter test ${criterion.name}',
            exitCode: 0,
            outputDigestSha256: 'd' * 64,
          ),
        )
        .toList(growable: false);
