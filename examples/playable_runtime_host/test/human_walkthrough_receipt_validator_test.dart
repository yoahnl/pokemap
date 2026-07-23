import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/human_walkthrough_receipt_validator.dart';

void main() {
  const requiredCheckpoints = ['new-game', 'capture', 'save-reload', 'ending'];

  test('round-trips a versioned valid human walkthrough receipt', () {
    final receipt = _receipt();
    final decoded = HumanWalkthroughReceipt.fromJson(receipt.toJson());
    final validation = const HumanWalkthroughReceiptValidator().validate(
      receipt: decoded,
      expectedReleaseCandidateCommit: 'a' * 40,
      expectedProjectTreeHashSha256: 'b' * 64,
      expectedPackageSha256: 'c' * 64,
      requiredCheckpointIds: requiredCheckpoints,
      nowUtc: DateTime.utc(2026, 7, 23, 13),
    );

    expect(decoded.schemaVersion, 1);
    expect(validation.isValid, isTrue);
    expect(validation.issues, isEmpty);
  });

  test('rejects stale, mismatched, duplicate, failed and P0/P1 receipts', () {
    const validator = HumanWalkthroughReceiptValidator();
    final receipt = _receipt(
      checkpoints: [
        ..._checkpoints(),
        const HumanWalkthroughCheckpoint(
          id: 'capture',
          passed: false,
          evidence: 'Duplicate and failed.',
        ),
      ],
      issues: const [
        HumanWalkthroughIssue(
          severity: HumanWalkthroughIssueSeverity.p1,
          summary: 'Save cannot be resumed.',
        ),
      ],
    );

    final validation = validator.validate(
      receipt: receipt,
      expectedReleaseCandidateCommit: 'd' * 40,
      expectedProjectTreeHashSha256: 'e' * 64,
      expectedPackageSha256: 'f' * 64,
      requiredCheckpointIds: requiredCheckpoints,
      nowUtc: DateTime.utc(2026, 7, 26),
    );

    expect(validation.isValid, isFalse);
    expect(validation.issues.join(' '), contains('commit'));
    expect(validation.issues.join(' '), contains('tree'));
    expect(validation.issues.join(' '), contains('package'));
    expect(validation.issues.join(' '), contains('stale'));
    expect(validation.issues.join(' '), contains('Duplicate'));
    expect(validation.issues.join(' '), contains('P0/P1'));
  });

  test('rejects malformed or unsupported JSON payloads', () {
    final malformed = _receipt().toJson()..remove('tester');
    final future = _receipt().toJson()..['schemaVersion'] = 2;

    expect(
      () => HumanWalkthroughReceipt.fromJson(malformed),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => HumanWalkthroughReceipt.fromJson(future),
      throwsA(isA<FormatException>()),
    );
  });
}

HumanWalkthroughReceipt _receipt({
  List<HumanWalkthroughCheckpoint>? checkpoints,
  List<HumanWalkthroughIssue> issues = const [],
}) =>
    HumanWalkthroughReceipt.validated(
      releaseCandidateCommit: 'a' * 40,
      capturedAtUtc: DateTime.utc(2026, 7, 23, 12),
      projectTreeHashSha256: 'b' * 64,
      packageSha256: 'c' * 64,
      tester: 'QA Selbrume',
      platform: 'macOS 15',
      checkpoints: checkpoints ?? _checkpoints(),
      issues: issues,
    );

List<HumanWalkthroughCheckpoint> _checkpoints() => const [
      HumanWalkthroughCheckpoint(
        id: 'new-game',
        passed: true,
        evidence: 'Starter selected.',
      ),
      HumanWalkthroughCheckpoint(
        id: 'capture',
        passed: true,
        evidence: 'Wild Pokémon captured.',
      ),
      HumanWalkthroughCheckpoint(
        id: 'save-reload',
        passed: true,
        evidence: 'Save restored after restart.',
      ),
      HumanWalkthroughCheckpoint(
        id: 'ending',
        passed: true,
        evidence: 'Port ending reached.',
      ),
    ];
