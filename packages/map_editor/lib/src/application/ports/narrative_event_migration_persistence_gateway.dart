import '../models/narrative_event_migration_persistence_models.dart';

abstract interface class NarrativeEventMigrationPersistenceGateway {
  Future<NarrativeEventMigrationInspection> inspect(String projectPath);

  Future<NarrativeEventMigrationPersistenceResult> commit(
    NarrativeEventMigrationCommitRequest request,
  );

  Future<NarrativeEventMigrationPersistenceResult> activateV2(
    NarrativeEventV2ModeActivationRequest request,
  );

  Future<NarrativeEventMigrationPersistenceResult> recover(
    String projectPath,
  );

  Future<NarrativeEventMigrationPersistenceResult> compensate(
    NarrativeEventMigrationCompensationRequest request,
  );
}
