import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_migration_persistence_models.dart';
import '../ports/narrative_event_migration_persistence_gateway.dart';

/// Activates V2 only for a project with no legacy Event ownership to preserve.
///
/// The repository still rechecks the revision and current registry under the
/// shared project lock. This preflight supplies the product explanation and
/// verifies map/scenario sources that the single-file repository cannot see.
final class NarrativeEventV2ModeActivationUseCase {
  const NarrativeEventV2ModeActivationUseCase({required this.gateway});

  final NarrativeEventMigrationPersistenceGateway gateway;

  Future<NarrativeEventMigrationPersistenceResult> activate(
    String projectPath,
  ) async {
    late final NarrativeEventAuthoringSession session;
    try {
      session = await NarrativeEventAuthoringSession.prepare(projectPath);
    } on Object catch (error) {
      return _result(
        NarrativeEventMigrationPersistenceStatus.rejected,
        'activationPreflightRejected',
        'Le projet ne peut pas être vérifié avant activation: $error',
      );
    }

    final registry = session.manifest.eventRegistry;
    if (registry?.mode == EventSystemMode.v2Only ||
        registry?.mode == EventSystemMode.dualRead) {
      return _result(
        NarrativeEventMigrationPersistenceStatus.noOp,
        'eventV2AlreadyActive',
        'Event V2 est déjà le mode actif de ce projet.',
      );
    }
    final hasRegistryOwnership = registry?.records.isNotEmpty == true ||
        registry?.legacyClaims.isNotEmpty == true;
    final hasMapEvents = session.maps.any((map) => map.events.isNotEmpty);
    final hasScenarioSources = session.manifest.scenarios.any(
      (scenario) => scenario.nodes.any(isLegacyScenarioSourceNode),
    );
    final targetMode =
        hasRegistryOwnership || hasMapEvents || hasScenarioSources
            ? EventSystemMode.dualRead
            : EventSystemMode.v2Only;

    return gateway.activateV2(
      NarrativeEventV2ModeActivationRequest(
        projectPath: session.projectPath,
        expectedProjectRevision: session.projectRevision,
        targetMode: targetMode,
      ),
    );
  }
}

NarrativeEventMigrationPersistenceResult _result(
  NarrativeEventMigrationPersistenceStatus status,
  String code,
  String message,
) {
  return NarrativeEventMigrationPersistenceResult(
    status: status,
    code: code,
    message: message,
  );
}
