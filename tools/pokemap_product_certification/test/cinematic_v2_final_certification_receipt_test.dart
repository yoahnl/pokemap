import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('builds one deterministic passing CIN-008 receipt', () {
    final receipt = CinematicV2FinalCertificationReceipt(
      releaseCommit: 'a' * 40,
      treeFingerprint: 'b' * 64,
      evidenceSha256: 'c' * 64,
      dependencies: _dependencies(),
      evidence: _evidence(),
    );

    expect(receipt.passed, isTrue);
    expect(receipt.blockingDependencies, isEmpty);
    expect(receipt.blockingEvidence, isEmpty);
    expect(receipt.toJson()['verdict'], 'passed');
    final encoded = receipt.encodeCanonical();
    expect(
      CinematicV2FinalCertificationReceipt.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      ).encodeCanonical(),
      encoded,
    );
  });

  test('fails closed when review or technical evidence remains incomplete', () {
    final dependencies = _dependencies().toList();
    dependencies[4] = const CinematicV2FinalDependency(
      ticket: 'BETA-CIN-038',
      workflowStatus: CinematicV2DependencyWorkflowStatus.toReview,
      technicalVerdict: CinematicV2TechnicalVerdict.partial,
      sourceCommit: '68c00aae67f452523fc6d58600e7de0c10d92220',
    );
    final evidence = _evidence().toList();
    evidence[7] = CinematicV2FinalEvidence(
      id: CinematicV2FinalEvidenceId.runtimePerformance,
      sourceTicket: 'BETA-CIN-038',
      sourceCommit: '68c00aae67f452523fc6d58600e7de0c10d92220',
      status: CinematicV2FinalEvidenceStatus.blocked,
      summary: 'Exact-SHA device receipt is still pending.',
      command: null,
      resultSha256: null,
      limitations: <String>['exact-sha-device-receipt-pending'],
    );

    final receipt = CinematicV2FinalCertificationReceipt(
      releaseCommit: 'a' * 40,
      treeFingerprint: 'b' * 64,
      evidenceSha256: 'c' * 64,
      dependencies: dependencies,
      evidence: evidence,
    );

    expect(receipt.passed, isFalse);
    expect(receipt.blockingDependencies, <String>['BETA-CIN-038']);
    expect(receipt.blockingEvidence, <CinematicV2FinalEvidenceId>[
      CinematicV2FinalEvidenceId.runtimePerformance,
    ]);
    expect(receipt.toJson()['verdict'], 'failed');
  });

  test('rejects incomplete, forged or sensitive evidence', () {
    expect(
      () => CinematicV2FinalCertificationReceipt(
        releaseCommit: 'a' * 40,
        treeFingerprint: 'b' * 64,
        evidenceSha256: 'c' * 64,
        dependencies: _dependencies().take(6).toList(),
        evidence: _evidence(),
      ),
      throwsFormatException,
    );
    final evidence = _evidence().toList();
    evidence[0] = CinematicV2FinalEvidence(
      id: CinematicV2FinalEvidenceId.preSessionRails,
      sourceTicket: 'BETA-CIN-999',
      sourceCommit: 'd' * 40,
      status: CinematicV2FinalEvidenceStatus.passed,
      summary: 'Forged source ticket.',
      command: 'flutter test test/pre_session.dart',
      resultSha256: 'e' * 64,
      limitations: const <String>[],
    );
    expect(
      () => CinematicV2FinalCertificationReceipt(
        releaseCommit: 'a' * 40,
        treeFingerprint: 'b' * 64,
        evidenceSha256: 'c' * 64,
        dependencies: _dependencies(),
        evidence: evidence,
      ),
      throwsFormatException,
    );
    evidence[0] = CinematicV2FinalEvidence(
      id: CinematicV2FinalEvidenceId.preSessionRails,
      sourceTicket: 'BETA-LCH-001',
      sourceCommit: 'd' * 40,
      status: CinematicV2FinalEvidenceStatus.passed,
      summary: 'Leaked /Users/yoahn/project evidence.',
      command: 'flutter test test/pre_session.dart',
      resultSha256: 'e' * 64,
      limitations: const <String>[],
    );
    expect(
      () => CinematicV2FinalCertificationReceipt(
        releaseCommit: 'a' * 40,
        treeFingerprint: 'b' * 64,
        evidenceSha256: 'c' * 64,
        dependencies: _dependencies(),
        evidence: evidence,
      ),
      throwsFormatException,
    );
  });

  test('freezes evidence limitations against later mutation', () {
    final limitations = <String>[];
    final evidence = CinematicV2FinalEvidence(
      id: CinematicV2FinalEvidenceId.preSessionRails,
      sourceTicket: 'BETA-LCH-001',
      sourceCommit: 'd' * 40,
      status: CinematicV2FinalEvidenceStatus.passed,
      summary: 'Pre-session rails passed.',
      command: 'flutter test test/pre_session.dart',
      resultSha256: 'e' * 64,
      limitations: limitations,
    );

    limitations.add('tampered');

    expect(evidence.limitations, isEmpty);
  });
}

List<CinematicV2FinalDependency> _dependencies() =>
    CinematicV2FinalCertificationReceipt.requiredDependencyTickets
        .map(
          (ticket) => CinematicV2FinalDependency(
            ticket: ticket,
            workflowStatus: CinematicV2DependencyWorkflowStatus.done,
            technicalVerdict: CinematicV2TechnicalVerdict.pass,
            sourceCommit: 'd' * 40,
          ),
        )
        .toList(growable: false);

List<CinematicV2FinalEvidence> _evidence() => CinematicV2FinalEvidenceId.values
    .map(
      (id) => CinematicV2FinalEvidence(
        id: id,
        sourceTicket: CinematicV2FinalCertificationReceipt.expectedSourceTicket(
          id,
        ),
        sourceCommit: 'd' * 40,
        status: CinematicV2FinalEvidenceStatus.passed,
        summary: '${id.name} passed.',
        command: 'flutter test test/${id.name}.dart',
        resultSha256: 'e' * 64,
        limitations: const <String>[],
      ),
    )
    .toList(growable: false);
