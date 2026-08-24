import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'authoring_mutation_adapter.dart';
import 'authoring_query_adapter.dart';
import 'editor_receipt_presenter.dart';

abstract interface class EncounterTablePersistenceGateway {
  Future<ProjectManifest> upsert({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required ProjectEncounterTable table,
  });

  Future<ProjectManifest> remove({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String tableId,
  });

  /// Le défaut de projet des transitions de combat — BETA-BAT-034.
  ///
  /// Une chaîne vide efface le défaut d'un côté et rend la main au défaut
  /// moteur ; un côté non fourni n'est pas touché.
  Future<ProjectManifest> updateBattleTransitionDefaults({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    String? wildTransitionId,
    String? trainerTransitionId,
  });
}

final class CanonicalEncounterTablePersistenceGateway
    implements EncounterTablePersistenceGateway {
  CanonicalEncounterTablePersistenceGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  }) : _mutations = mutations,
       _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;
  int _operationSequence = 0;

  @override
  Future<ProjectManifest> upsert({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required ProjectEncounterTable table,
  }) {
    return _apply(
      projectRootPath: projectRootPath,
      expectedProject: expectedProject,
      actionId: 'campaign.encounter_table.upsert',
      parameters: <String, Object?>{'value': table.toJson()},
      operationLabel: 'upsert_${table.id}',
      requiresConfirmation: false,
    );
  }

  @override
  Future<ProjectManifest> remove({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String tableId,
  }) {
    return _apply(
      projectRootPath: projectRootPath,
      expectedProject: expectedProject,
      actionId: 'campaign.encounter_table.delete',
      parameters: <String, Object?>{'id': tableId},
      operationLabel: 'delete_$tableId',
      requiresConfirmation: true,
    );
  }

  @override
  Future<ProjectManifest> updateBattleTransitionDefaults({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    String? wildTransitionId,
    String? trainerTransitionId,
  }) {
    return _apply(
      projectRootPath: projectRootPath,
      expectedProject: expectedProject,
      actionId: 'project.battle_transitions.update',
      parameters: <String, Object?>{
        'wildTransitionId': ?wildTransitionId,
        'trainerTransitionId': ?trainerTransitionId,
      },
      operationLabel: 'battle_transitions',
      requiresConfirmation: false,
    );
  }

  Future<ProjectManifest> _apply({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
    required bool requiresConfirmation,
  }) async {
    try {
      await _queries.invalidate(projectRootPath);
      final before = await _queries.open(projectRootPath);
      if (before.manifest != expectedProject) {
        throw const EditorConflictException(
          'The project changed outside Encounter Studio. Reload before saving.',
        );
      }
      final operationId = _nextOperationId(operationLabel);
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
      if (_isEncounterConflict(failure.code)) {
        throw EditorConflictException(
          'The project changed outside Encounter Studio. ${failure.message}',
        );
      }
      rethrow;
    }
  }

  String _nextOperationId(String label) {
    _operationSequence++;
    return 'editor_encounter_${label}_'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_'
        '$_operationSequence';
  }
}

bool _isEncounterConflict(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');
