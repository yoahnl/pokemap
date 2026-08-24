import 'package:map_core/map_core.dart';

import '../models/narrative_authoring_transaction.dart';

/// Atomic project-manifest persistence boundary for Narrative Studio writes.
abstract interface class NarrativeAuthoringPersistenceGateway {
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  );

  Future<NarrativeAuthoringPersistenceResult> persistProjectDocument({
    required String projectPath,
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
    String? expectedRevision,
  });
}
