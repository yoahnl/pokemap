import 'dart:convert';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('PersonalizationReleaseGateReceipt', () {
    test('round-trips one complete GO receipt', () {
      final receipt = _receipt();

      final decoded = PersonalizationReleaseGateReceipt.fromJson(
        jsonDecode(jsonEncode(receipt.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.toJson(), receipt.toJson());
      expect(decoded.isGo, isTrue);
      expect(decoded.blockers, isEmpty);
      expect(decoded.platformMatrixStatus,
          PersonalizationReleaseEvidenceStatus.passed);
    });

    test('rejects missing and duplicate behavioral criteria', () {
      expect(
        () => _receipt(
          criteria: _passedCriteria().where(
            (item) =>
                item.criterion != PersonalizationReleaseCriterion.safeFallbacks,
          ),
        ),
        throwsStateError,
      );
      expect(
        () => _receipt(
          criteria: <PersonalizationReleaseCriterionEvidence>[
            ..._passedCriteria(),
            _passedCriteria().first,
          ],
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate platform rows', () {
      const macos = PersonalizationPlatformCodecEvidence(
        platform: 'macos',
        videoCodec: 'h264',
        audioCodec: 'aac',
        buildExitCode: 0,
        launchExitCode: 0,
        source: 'build/phase-7b/macos.json',
      );

      expect(
        () => _receipt(platforms: const [macos, macos]),
        throwsArgumentError,
      );
    });

    test('failed or missing platform launch evidence forces NO-GO', () {
      final failed = _receipt(
        platforms: const <PersonalizationPlatformCodecEvidence>[
          PersonalizationPlatformCodecEvidence(
            platform: 'macos',
            videoCodec: 'h264',
            audioCodec: 'aac',
            buildExitCode: 0,
            launchExitCode: 134,
            source: 'build/phase-7b/macos.json',
          ),
        ],
      );
      final missing = _receipt(
        platforms: const <PersonalizationPlatformCodecEvidence>[
          PersonalizationPlatformCodecEvidence(
            platform: 'macos',
            videoCodec: 'h264',
            audioCodec: 'aac',
            buildExitCode: 0,
            source: 'build/phase-7b/macos.json',
          ),
        ],
      );

      expect(failed.isGo, isFalse);
      expect(
        failed.platformMatrixStatus,
        PersonalizationReleaseEvidenceStatus.failed,
      );
      expect(failed.blockers.single, contains('launch exit code 134'));
      expect(missing.isGo, isFalse);
      expect(
        missing.platformMatrixStatus,
        PersonalizationReleaseEvidenceStatus.notEvaluated,
      );
      expect(missing.blockers.single, contains('launch evidence is missing'));
    });

    test('failed behavioral evidence forces NO-GO', () {
      final criteria = _passedCriteria();
      final index = criteria.indexWhere(
        (item) =>
            item.criterion ==
            PersonalizationReleaseCriterion.previewRuntimeParity,
      );
      criteria[index] = const PersonalizationReleaseCriterionEvidence(
        criterion: PersonalizationReleaseCriterion.previewRuntimeParity,
        status: PersonalizationReleaseEvidenceStatus.failed,
        summary: 'Preview differs from the installed title.',
        source: 'build/phase-7b/preview-runtime.log',
      );

      final receipt = _receipt(criteria: criteria);

      expect(receipt.isGo, isFalse);
      expect(receipt.blockers.single, contains('previewRuntimeParity'));
    });

    test('rejects malformed hashes, local dates, and future schemas', () {
      expect(
        () => PersonalizationReleaseGateReceipt.validated(
          releaseCandidateCommit: 'short',
          capturedAtUtc: DateTime.utc(2026, 7, 27),
          contentTreeHashSha256: 'b' * 64,
          packageSha256: 'c' * 64,
          presentationSha256: 'd' * 64,
          criteria: _passedCriteria(),
          platforms: _passingPlatforms,
        ),
        throwsArgumentError,
      );
      expect(
        () => PersonalizationReleaseGateReceipt.validated(
          releaseCandidateCommit: 'a' * 40,
          capturedAtUtc: DateTime(2026, 7, 27),
          contentTreeHashSha256: 'b' * 64,
          packageSha256: 'c' * 64,
          presentationSha256: 'd' * 64,
          criteria: _passedCriteria(),
          platforms: _passingPlatforms,
        ),
        throwsArgumentError,
      );
      expect(
        () => PersonalizationReleaseGateReceipt.fromJson(
          <String, dynamic>{..._receipt().toJson(), 'schemaVersion': 2},
        ),
        throwsFormatException,
      );
    });

    final externalReceipt =
        Platform.environment['POKEMAP_PHASE7B_RELEASE_RECEIPT'];
    if (externalReceipt != null) {
      test('validates the external Phase 7B receipt', () async {
        final decoded = jsonDecode(
          await File(externalReceipt).readAsString(),
        );
        expect(decoded, isA<Map<String, dynamic>>());

        final receipt = PersonalizationReleaseGateReceipt.fromJson(
          decoded as Map<String, dynamic>,
        );

        expect(receipt.releaseCandidateCommit, hasLength(40));
        expect(receipt.packageSha256, hasLength(64));
        expect(receipt.presentationSha256, hasLength(64));
      });
    }
  });
}

PersonalizationReleaseGateReceipt _receipt({
  Iterable<PersonalizationReleaseCriterionEvidence>? criteria,
  Iterable<PersonalizationPlatformCodecEvidence>? platforms,
}) =>
    PersonalizationReleaseGateReceipt.validated(
      releaseCandidateCommit: 'a' * 40,
      capturedAtUtc: DateTime.utc(2026, 7, 27, 12),
      contentTreeHashSha256: 'b' * 64,
      packageSha256: 'c' * 64,
      presentationSha256: 'd' * 64,
      criteria: criteria ?? _passedCriteria(),
      platforms: platforms ?? _passingPlatforms,
    );

List<PersonalizationReleaseCriterionEvidence> _passedCriteria() => [
      for (final criterion in PersonalizationReleaseCriterion.values)
        PersonalizationReleaseCriterionEvidence(
          criterion: criterion,
          status: PersonalizationReleaseEvidenceStatus.passed,
          summary: '${criterion.name} passed.',
          source: 'build/phase-7b/${criterion.name}.log',
        ),
    ];

const _passingPlatforms = <PersonalizationPlatformCodecEvidence>[
  PersonalizationPlatformCodecEvidence(
    platform: 'macos',
    videoCodec: 'h264',
    audioCodec: 'aac',
    buildExitCode: 0,
    launchExitCode: 0,
    source: 'build/phase-7b/macos.json',
  ),
];
