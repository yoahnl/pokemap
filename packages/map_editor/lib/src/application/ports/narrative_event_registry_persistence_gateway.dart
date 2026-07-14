import '../models/narrative_event_registry_persistence_models.dart';

abstract interface class NarrativeEventRegistryPersistenceGateway {
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  );

  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  );

  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath);
}
