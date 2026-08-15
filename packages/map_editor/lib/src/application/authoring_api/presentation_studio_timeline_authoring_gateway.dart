import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'authoring_mutation_adapter.dart';
import 'authoring_query_adapter.dart';
import 'editor_receipt_presenter.dart';
import 'presentation_studio_timeline_command.dart';

final class PresentationTimelineAuthoringTransaction {
  const PresentationTimelineAuthoringTransaction({
    required this.manifest,
    required this.receiptId,
    required this.command,
  });

  final ProjectManifest manifest;
  final String receiptId;
  final PresentationTimelineClipCommand command;
}

abstract interface class PresentationStudioTimelineAuthoringGateway {
  Future<PresentationTimelineAuthoringTransaction> apply(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationTimelineClipCommand command,
  });

  Future<ProjectManifest> undo(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationTimelineAuthoringTransaction transaction,
  });

  Future<PresentationTimelineAuthoringTransaction> redo(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationTimelineAuthoringTransaction transaction,
  });
}

final class CanonicalPresentationStudioTimelineAuthoringGateway
    implements PresentationStudioTimelineAuthoringGateway {
  CanonicalPresentationStudioTimelineAuthoringGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  }) : _mutations = mutations,
       _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;
  int _operationSequence = 0;

  @override
  Future<PresentationTimelineAuthoringTransaction> apply(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationTimelineClipCommand command,
  }) async {
    final operationId = _nextOperationId('apply');
    try {
      final before = await _requireExpectedProject(
        projectRootPath,
        expectedProject,
      );
      final plan = await _mutations.plan(
        projectRootPath,
        actionId: command.actionId,
        parameters: command.parameters,
        idempotencyKey: operationId,
        requestId: operationId,
        expectedRevision: before.snapshotRevision,
      );
      final confirmationToken = _requiresConfirmation(command.actionId)
          ? await _mutations.confirm(plan)
          : null;
      final result = await _mutations.apply(
        plan,
        operationId: '${operationId}_commit',
        confirmationToken: confirmationToken,
      );
      return PresentationTimelineAuthoringTransaction(
        manifest: (await _queries.open(projectRootPath)).manifest,
        receiptId: result.receipt.receiptId,
        command: command,
      );
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isConflict(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      rethrow;
    }
  }

  @override
  Future<ProjectManifest> undo(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationTimelineAuthoringTransaction transaction,
  }) async {
    await _requireExpectedProject(projectRootPath, expectedProject);
    try {
      await _mutations.undo(
        projectRootPath,
        entryId: transaction.receiptId,
        idempotencyKey: _nextOperationId('undo'),
      );
      return (await _queries.open(projectRootPath)).manifest;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isConflict(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      rethrow;
    }
  }

  @override
  Future<PresentationTimelineAuthoringTransaction> redo(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationTimelineAuthoringTransaction transaction,
  }) => apply(
    projectRootPath,
    expectedProject: expectedProject,
    command: transaction.command,
  );

  Future<EditorAuthoringReadSession> _requireExpectedProject(
    String projectRootPath,
    ProjectManifest expectedProject,
  ) async {
    await _queries.invalidate(projectRootPath);
    final snapshot = await _queries.open(projectRootPath);
    if (snapshot.manifest != expectedProject) {
      throw const EditorConflictException(
        'Le projet a changé. Rechargez la cinématique avant de recommencer.',
      );
    }
    return snapshot;
  }

  String _nextOperationId(String kind) {
    _operationSequence += 1;
    return 'editor_presentation_timeline_${kind}_'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_'
        '$_operationSequence';
  }
}

bool _requiresConfirmation(String actionId) =>
    actionId.endsWith('.delete') || actionId.endsWith('.deleteBatch');

bool _isConflict(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');
