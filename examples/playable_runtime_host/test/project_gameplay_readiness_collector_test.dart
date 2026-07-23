import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/project_gameplay_readiness_collector.dart';
import 'package:path/path.dart' as p;

void main() {
  late ProjectManifest selbrume;

  setUpAll(() async {
    final file = File(p.join(
      Directory.current.path,
      '..',
      '..',
      'selbrume',
      'project.json',
    ));
    selbrume = ProjectManifest.fromJson(
      (jsonDecode(await file.readAsString()) as Map).cast<String, dynamic>(),
    );
  });

  test('collects executable product and structural project readiness', () {
    final result = const ProjectGameplayReadinessCollector().collect(
      project: selbrume,
      receipt: _receipt(),
      expectedCommit: 'a' * 40,
      actualProjectTreeHashSha256: 'b' * 64,
    );

    expect(result.isReady, isTrue);
    expect(result.issues, isEmpty);
    expect(result.report.isPlayable, isTrue);
    expect(result.report.infos, hasLength(11));
  });

  test('rejects stale commit and changed project tree', () {
    final result = const ProjectGameplayReadinessCollector().collect(
      project: selbrume,
      receipt: _receipt(),
      expectedCommit: 'c' * 40,
      actualProjectTreeHashSha256: 'd' * 64,
    );

    expect(result.isReady, isFalse);
    expect(result.issues, hasLength(2));
    expect(result.issues.join(' '), contains('commit'));
    expect(result.issues.join(' '), contains('tree hash'));
  });

  test('rejects missing, duplicate or failed product observations', () {
    final missingCriteria = _criteria()
        .where(
          (item) => item.criterion != MvpProductCriterion.mvp09PcOverflow,
        )
        .toList(growable: false);
    final duplicateCriteria = <MvpProductCriterionEvidence>[
      ..._criteria(),
      const MvpProductCriterionEvidence(
        criterion: MvpProductCriterion.mvp16Shop,
        status: MvpProductCriterionStatus.passed,
        summary: 'Duplicate.',
        source: 'duplicate',
      ),
    ];
    final failedCriteria = _criteria()
        .map(
          (item) => item.criterion == MvpProductCriterion.mvp18SaveLoad
              ? const MvpProductCriterionEvidence(
                  criterion: MvpProductCriterion.mvp18SaveLoad,
                  status: MvpProductCriterionStatus.failed,
                  summary: 'Reload failed.',
                  source: 'journey',
                )
              : item,
        )
        .toList(growable: false);

    for (final criteria in <List<MvpProductCriterionEvidence>>[
      missingCriteria,
      duplicateCriteria,
      failedCriteria,
    ]) {
      final result = const ProjectGameplayReadinessCollector().collect(
        project: selbrume,
        receipt: _receipt(criteria: criteria),
        expectedCommit: 'a' * 40,
        actualProjectTreeHashSha256: 'b' * 64,
      );
      expect(result.isReady, isFalse);
    }
  });

  test('a non-zero journey execution fails every derived check closed', () {
    final result = const ProjectGameplayReadinessCollector().collect(
      project: selbrume,
      receipt: _receipt(exitCode: 1),
      expectedCommit: 'a' * 40,
      actualProjectTreeHashSha256: 'b' * 64,
    );

    expect(result.isReady, isFalse);
    expect(result.issues.join(' '), contains('exit code 1'));
    expect(result.report.errors, isNotEmpty);
  });
}

MvpReleaseEvidenceReceipt _receipt({
  int exitCode = 0,
  List<MvpProductCriterionEvidence>? criteria,
}) =>
    MvpReleaseEvidenceReceipt.validated(
      command: 'flutter test test/selbrume_player_journey_e2e_test.dart',
      exitCode: exitCode,
      releaseCandidateCommit: 'a' * 40,
      capturedAtUtc: DateTime.utc(2026, 7, 23),
      source: 'test/selbrume_player_journey_e2e_test.dart',
      projectTreeHashSha256: 'b' * 64,
      criteria: criteria ?? _criteria(),
    );

List<MvpProductCriterionEvidence> _criteria() => MvpProductCriterion.values
    .map(
      (criterion) => MvpProductCriterionEvidence(
        criterion: criterion,
        status: MvpProductCriterionStatus.passed,
        summary: '${criterion.id} observed in the product journey.',
        source: 'journey:${criterion.id}',
      ),
    )
    .toList(growable: false);
