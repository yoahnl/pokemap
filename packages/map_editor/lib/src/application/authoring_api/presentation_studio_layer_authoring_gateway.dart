import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'authoring_mutation_adapter.dart';
import 'authoring_query_adapter.dart';
import 'editor_receipt_presenter.dart';

abstract interface class PresentationStudioLayerAuthoringGateway {
  Future<ProjectManifest> apply(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
  });
}

final class CanonicalPresentationStudioLayerAuthoringGateway
    implements PresentationStudioLayerAuthoringGateway {
  CanonicalPresentationStudioLayerAuthoringGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  }) : _mutations = mutations,
       _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;
  int _operationSequence = 0;

  @override
  Future<ProjectManifest> apply(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    _operationSequence += 1;
    final operationId =
        'editor_presentation_layer_'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_'
        '$_operationSequence';
    try {
      await _queries.invalidate(projectRootPath);
      final before = await _queries.open(projectRootPath);
      if (before.manifest != expectedProject) {
        throw const EditorConflictException(
          'Le projet a changé. Rechargez la cinématique avant de recommencer.',
        );
      }
      final plan = await _mutations.plan(
        projectRootPath,
        actionId: actionId,
        parameters: parameters,
        idempotencyKey: operationId,
        requestId: operationId,
        expectedRevision: before.snapshotRevision,
      );
      final confirmationToken = actionId.endsWith('.delete')
          ? await _mutations.confirm(plan)
          : null;
      await _mutations.apply(
        plan,
        operationId: '${operationId}_apply',
        confirmationToken: confirmationToken,
      );
      return (await _queries.open(projectRootPath)).manifest;
    } on EditorConflictException {
      rethrow;
    } on EditorAuthoringMutationFailure catch (failure) {
      if (_isConflict(failure.code)) {
        throw EditorConflictException(failure.message);
      }
      rethrow;
    }
  }
}

bool _isConflict(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');
