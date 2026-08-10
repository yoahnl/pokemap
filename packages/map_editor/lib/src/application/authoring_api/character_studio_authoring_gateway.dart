import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'authoring_mutation_adapter.dart';
import 'authoring_query_adapter.dart';
import 'editor_receipt_presenter.dart';

abstract interface class CharacterStudioAuthoringGateway {
  Future<ProjectManifest> apply({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
    bool requiresConfirmation = false,
  });

  Future<EditorAuthoringMutationPlan> preview({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
  });
}

final class CanonicalCharacterStudioAuthoringGateway
    implements CharacterStudioAuthoringGateway {
  CanonicalCharacterStudioAuthoringGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  }) : _mutations = mutations,
       _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;
  int _operationSequence = 0;

  @override
  Future<ProjectManifest> apply({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
    bool requiresConfirmation = false,
  }) async {
    final operationId = _nextOperationId(operationLabel);
    try {
      final before = await _requireExpectedProject(
        projectRootPath,
        expectedProject,
      );
      final plan = await _mutations.plan(
        projectRootPath,
        actionId: actionId,
        parameters: parameters,
        idempotencyKey: operationId,
        requestId: operationId,
        expectedRevision: before.snapshotRevision,
      );
      final confirmationToken = requiresConfirmation
          ? await _mutations.confirm(plan)
          : null;
      await _mutations.apply(
        plan,
        operationId: operationId,
        confirmationToken: confirmationToken,
      );
      return (await _queries.open(projectRootPath)).manifest;
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isCharacterStudioConflict(failure.code)) {
        throw EditorConflictException(
          'The project changed outside Character Studio. ${failure.message}',
        );
      }
      rethrow;
    }
  }

  @override
  Future<EditorAuthoringMutationPlan> preview({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
  }) async {
    final operationId = _nextOperationId(operationLabel);
    try {
      final before = await _requireExpectedProject(
        projectRootPath,
        expectedProject,
      );
      return await _mutations.plan(
        projectRootPath,
        actionId: actionId,
        parameters: parameters,
        idempotencyKey: operationId,
        requestId: operationId,
        expectedRevision: before.snapshotRevision,
        dryRun: true,
      );
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isCharacterStudioConflict(failure.code)) {
        throw EditorConflictException(
          'The project changed outside Character Studio. ${failure.message}',
        );
      }
      rethrow;
    }
  }

  Future<EditorAuthoringReadSession> _requireExpectedProject(
    String projectRootPath,
    ProjectManifest expectedProject,
  ) async {
    await _queries.invalidate(projectRootPath);
    final before = await _queries.open(projectRootPath);
    if (before.manifest != expectedProject) {
      throw const EditorConflictException(
        'The project changed outside Character Studio. Reload before saving.',
      );
    }
    return before;
  }

  String _nextOperationId(String label) {
    _operationSequence++;
    return 'editor_character_studio_${label}_'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_'
        '$_operationSequence';
  }
}

bool _isCharacterStudioConflict(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');
