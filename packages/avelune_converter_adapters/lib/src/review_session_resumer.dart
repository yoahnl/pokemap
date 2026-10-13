import 'dart:math';

import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'converter_workflow.dart';
import 'literal_tile_composer.dart';
import 'local_review_session_store.dart';

final class ConverterReviewSessionResumer {
  static Future<PreparedStudy> resume({
    required StoredReviewSession stored,
    required ConverterWorkflow workflow,
    String? sourceRootPath,
    String? destinationParentPath,
    String? folderName,
    String? projectName,
  }) async {
    final session = stored.reviewSet;
    final saved = stored.resumeSettings;
    final snapshot = await workflow.scanSource(ConverterSourceSelection(
        rootPath: sourceRootPath ?? saved.sourceRootPath,
        logicalProjectNamespace: session.logicalProjectNamespace,
        policy: saved.sourceScanPolicy));
    if (snapshot.state != SourceScanState.complete ||
        snapshot.canonicalHash != session.sourceSnapshotHash) {
      throw const ConverterWorkflowFailure('workflow.resume.source_stale',
          'Reselect and review the exact saved source before resuming.');
    }
    final receipt = saved.profileAcknowledgement;
    if (receipt == null ||
        receipt.sourceSnapshotHash != snapshot.canonicalHash ||
        receipt.profileEvidenceHash != snapshot.profile.evidenceHash) {
      throw const ConverterWorkflowFailure('workflow.resume.profile_ack',
          'Review the current source profile before resuming this study.');
    }
    final acknowledgement = SourceStudyAcknowledgement(
        sourceSnapshotHash: receipt.sourceSnapshotHash,
        profileEvidenceHash: receipt.profileEvidenceHash,
        humanConfirmed: receipt.humanConfirmed,
        reason: receipt.reason);
    final remaining = saved.dependencyDecisions.toList();
    final decisions = <LiteralDependencyDecision>[];
    final maximumIterations = min(
        remaining.length + 1,
        min(saved.normalizationLimits.maxMaps + 1,
            saved.writeLimits.maxMutations + 1));
    for (var iteration = 0; iteration < maximumIterations; iteration++) {
      workflow.updateSettings(_settings(stored, acknowledgement, decisions,
          restoreReview: false,
          destinationParentPath: destinationParentPath,
          folderName: folderName,
          projectName: projectName));
      final preview = await workflow.prepareStudy();
      final selectionHash = literalSelectionHash(
          preview.normalizedSource, session.selectedSourceMapIds);
      if (preview.sourceSnapshotHash != session.sourceSnapshotHash) {
        throw const ConverterWorkflowFailure('workflow.resume.source_stale',
            'The saved source changed while resuming the study.');
      }
      final discovered = <LocalReviewDependencyDecision>[];
      for (final dependencyReceipt in remaining) {
        if (dependencyReceipt.sourceSnapshotHash !=
                preview.sourceSnapshotHash ||
            dependencyReceipt.selectionHash != selectionHash) {
          throw const ConverterWorkflowFailure(
              'workflow.resume.dependency_stale',
              'A saved passage decision belongs to another source or selection.');
        }
        final matches = preview.composition.dependencies
            .where((dependency) =>
                dependency.targetSourceMapId ==
                    dependencyReceipt.targetSourceMapId &&
                canonicalHashOf(dependency.locator.toJson()) ==
                    dependencyReceipt.locatorHash)
            .toList();
        if (matches.length > 1) {
          throw const ConverterWorkflowFailure(
              'workflow.resume.dependency_stale',
              'A saved passage decision does not identify one exact source passage.');
        }
        if (matches.isEmpty) continue;
        decisions.add(LiteralDependencyDecision(
            sourceSnapshotHash: preview.sourceSnapshotHash,
            selectionHash: selectionHash,
            locator: matches.single.locator,
            targetSourceMapId: dependencyReceipt.targetSourceMapId,
            decision: dependencyReceipt.decision));
        discovered.add(dependencyReceipt);
      }
      remaining.removeWhere(discovered.contains);
      if (remaining.isEmpty) {
        workflow.updateSettings(_settings(stored, acknowledgement, decisions,
            restoreReview: true,
            destinationParentPath: destinationParentPath,
            folderName: folderName,
            projectName: projectName));
        return workflow.prepareStudy();
      }
      if (discovered.isEmpty) break;
    }
    throw const ConverterWorkflowFailure('workflow.resume.dependency_stale',
        'A saved passage decision could not be found within the saved study scope.');
  }

  static ConverterStudySettings _settings(
      StoredReviewSession stored,
      SourceStudyAcknowledgement acknowledgement,
      List<LiteralDependencyDecision> decisions,
      {required bool restoreReview,
      String? destinationParentPath,
      String? folderName,
      String? projectName}) {
    final saved = stored.resumeSettings;
    final session = stored.reviewSet;
    return ConverterStudySettings(
        projectName: projectName ?? saved.projectName,
        parentPath: destinationParentPath ?? saved.destinationParentPath,
        folderName: folderName ?? saved.folderName,
        selectedSourceMapIds: session.selectedSourceMapIds,
        profileAcknowledgement: acknowledgement,
        dependencyDecisions: decisions,
        allowFirstFrameAutotiles: saved.allowFirstFrameAutotiles,
        assetOutputMode:
            restoreReview ? session.outputMode : session.seedOutputMode,
        reviewSet: restoreReview ? session : null,
        normalizationLimits: saved.normalizationLimits,
        writeLimits: saved.writeLimits);
  }
}
