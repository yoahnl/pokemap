import '../models/narrative_event_registry_persistence_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';

final class PersistNarrativeEventRegistryUseCase {
  const PersistNarrativeEventRegistryUseCase(this._gateway);

  final NarrativeEventRegistryPersistenceGateway _gateway;

  Future<NarrativeEventRegistryPersistenceResult> call(
    NarrativeEventRegistryWriteRequest request,
  ) {
    return _gateway.persist(request);
  }
}

final class RecoverNarrativeEventRegistryWritesUseCase {
  const RecoverNarrativeEventRegistryWritesUseCase(this._gateway);

  final NarrativeEventRegistryPersistenceGateway _gateway;

  Future<List<NarrativeEventRegistryPersistenceResult>> call(
    String projectPath,
  ) {
    return _gateway.recover(projectPath);
  }
}

final class UndoNarrativeEventRegistryWriteUseCase {
  const UndoNarrativeEventRegistryWriteUseCase(this._gateway);

  final NarrativeEventRegistryPersistenceGateway _gateway;

  Future<NarrativeEventRegistryPersistenceResult> call(String undoPath) {
    return _gateway.undo(undoPath);
  }
}
