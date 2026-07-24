import 'package:map_core/map_core.dart';

import '../contracts/evaluation_policy.dart';
import '../contracts/evaluation_receipt.dart';

final class EvaluationReleaseAdapter {
  const EvaluationReleaseAdapter();

  List<MvpProductCriterionEvidence> productCriteria(
    EvaluationReceipt receipt, {
    required String expectedCommit,
    required String expectedProjectTreeHash,
  }) {
    return _adapt(
      evidenceLevel: receipt.evidenceLevel.name,
      status: receipt.status.name,
      exitCode: receipt.exitCode,
      commit: receipt.commit,
      projectTreeHash: receipt.projectTreeHash,
      relativeReceiptPath: receipt.relativeReceiptPath,
      declaredCriterionIds: receipt.declaredCriterionIds,
      productCriteria: receipt.productCriteria,
      expectedCommit: expectedCommit,
      expectedProjectTreeHash: expectedProjectTreeHash,
    );
  }

  List<MvpProductCriterionEvidence> productCriteriaJson(
    Map<String, dynamic> json, {
    required String expectedCommit,
    required String expectedProjectTreeHash,
  }) {
    final declared = json['declaredCriterionIds'];
    final products = json['productCriteria'];
    if (declared is! List || products is! List) {
      throw const FormatException(
        'Evaluation receipt criteria must be JSON arrays.',
      );
    }
    return _adapt(
      evidenceLevel: json['evidenceLevel'] as String?,
      status: json['status'] as String?,
      exitCode: json['exitCode'] as int?,
      commit: json['commit'] as String?,
      projectTreeHash: json['projectTreeHash'] as String?,
      relativeReceiptPath: json['relativeReceiptPath'] as String?,
      declaredCriterionIds: declared.cast<String>(),
      productCriteria: products.map((item) {
        if (item is! Map) {
          throw const FormatException(
            'Evaluation product criteria must be JSON objects.',
          );
        }
        final value = Map<String, dynamic>.from(item);
        return EvaluationProductCriterionResult(
          id: value['id'] as String,
          summary: value['summary'] as String,
          passed: value['passed'] as bool,
        );
      }).toList(growable: false),
      expectedCommit: expectedCommit,
      expectedProjectTreeHash: expectedProjectTreeHash,
    );
  }

  List<MvpProductCriterionEvidence> _adapt({
    required String? evidenceLevel,
    required String? status,
    required int? exitCode,
    required String? commit,
    required String? projectTreeHash,
    required String? relativeReceiptPath,
    required List<String> declaredCriterionIds,
    required List<EvaluationProductCriterionResult> productCriteria,
    required String expectedCommit,
    required String expectedProjectTreeHash,
  }) {
    if (evidenceLevel != EvaluationEvidenceLevel.releaseEvidence.name ||
        status != EvaluationRunStatus.succeeded.name ||
        exitCode != 0) {
      throw ArgumentError('Receipt is not release eligible.');
    }
    if (commit?.toLowerCase() != expectedCommit.toLowerCase()) {
      throw ArgumentError('Receipt commit does not match the candidate.');
    }
    if (projectTreeHash?.toLowerCase() !=
        expectedProjectTreeHash.toLowerCase()) {
      throw ArgumentError('Receipt project tree does not match the candidate.');
    }
    if (relativeReceiptPath == null || relativeReceiptPath.trim().isEmpty) {
      throw ArgumentError('Receipt source path is missing.');
    }

    final expectedIds =
        MvpProductCriterion.values.map((criterion) => criterion.id).toSet();
    final declaredIds = declaredCriterionIds.toSet();
    final resultIds = productCriteria.map((criterion) => criterion.id).toSet();
    if (declaredCriterionIds.length != expectedIds.length ||
        productCriteria.length != expectedIds.length ||
        declaredIds.length != expectedIds.length ||
        resultIds.length != expectedIds.length ||
        !declaredIds.containsAll(expectedIds) ||
        !resultIds.containsAll(expectedIds) ||
        productCriteria.any((criterion) => !criterion.passed)) {
      throw StateError(
        'Release receipt does not contain exactly one passed result for every '
        'MVP criterion.',
      );
    }

    final byId = <String, EvaluationProductCriterionResult>{
      for (final criterion in productCriteria) criterion.id: criterion,
    };
    return <MvpProductCriterionEvidence>[
      for (final criterion in MvpProductCriterion.values)
        MvpProductCriterionEvidence(
          criterion: criterion,
          status: MvpProductCriterionStatus.passed,
          summary: byId[criterion.id]!.summary,
          source: '$relativeReceiptPath#${criterion.id}',
        ),
    ];
  }
}
