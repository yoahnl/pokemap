import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_registry_persistence_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';

final class PrepareNarrativeEventAuthoringSessionUseCase {
  const PrepareNarrativeEventAuthoringSessionUseCase();

  Future<NarrativeEventAuthoringSession> call(String projectPath) {
    return NarrativeEventAuthoringSession.prepare(projectPath);
  }
}

final class PersistNarrativeEventRegistryUseCase {
  const PersistNarrativeEventRegistryUseCase(this._gateway);

  final NarrativeEventRegistryPersistenceGateway _gateway;

  Future<NarrativeEventRegistryPersistenceResult> call(
    NarrativeEventRegistryWriteRequest request,
  ) {
    return _gateway.persist(request);
  }
}

final class InspectNarrativeEventRegistryRecoveryUseCase {
  const InspectNarrativeEventRegistryRecoveryUseCase(this._gateway);

  final NarrativeEventRegistryPersistenceGateway _gateway;

  Future<NarrativeEventRegistryRecoveryInspection> call(String projectPath) {
    return _gateway.inspectRecovery(projectPath);
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
