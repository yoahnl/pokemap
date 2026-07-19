import '../models/narrative_authoring_transaction.dart';

/// Atomic project-manifest persistence boundary for Narrative Studio writes.
abstract interface class NarrativeAuthoringPersistenceGateway {
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  );
}
