import 'package:map_core/map_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/ports/narrative_event_registry_persistence_gateway.dart';
import '../../../application/ports/narrative_event_migration_persistence_gateway.dart';
import '../../../application/ports/narrative_event_spatial_source_creation_gateway.dart';
import '../../../application/ports/narrative_authoring_persistence_gateway.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/services/narrative_document_session.dart';
import '../../../application/use_cases/execute_narrative_authoring_transaction.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../../../infrastructure/repositories/file_repositories.dart';
import '../../../infrastructure/repositories/file_narrative_document_recovery_store.dart';
import '../../../infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import '../../../infrastructure/repositories/narrative_event_migration_persistence_repository.dart';
import '../../../infrastructure/repositories/project_manifest_narrative_document_gateway.dart';

part 'repository_providers.g.dart';

final fileProjectRepositoryProvider = Provider<FileProjectRepository>((ref) {
  return FileProjectRepository();
});

final narrativeEventRegistryPersistenceGatewayProvider =
    Provider<NarrativeEventRegistryPersistenceGateway>((ref) {
  return ref.watch(fileProjectRepositoryProvider);
});

final narrativeAuthoringPersistenceGatewayProvider =
    Provider<NarrativeAuthoringPersistenceGateway>((ref) {
  return ref.watch(fileProjectRepositoryProvider).narrativeAuthoringPersistence;
});

final executeNarrativeAuthoringTransactionProvider =
    Provider<ExecuteNarrativeAuthoringTransaction>((ref) {
  return ExecuteNarrativeAuthoringTransaction(
    ref.watch(narrativeAuthoringPersistenceGatewayProvider),
  );
});

typedef NarrativeProjectDocumentSessionFactory
    = NarrativeDocumentSession<ProjectManifest> Function({
  required String projectPath,
  required ProjectManifest initialDocument,
});

/// Creates the crash-safe document session used by the Cinematics pilot.
///
/// Autosave is opt-in at product level. The journal still protects every local
/// edit immediately, independently of that preference.
final narrativeProjectDocumentSessionFactoryProvider =
    Provider<NarrativeProjectDocumentSessionFactory>((ref) {
  final persistence = ref.watch(narrativeAuthoringPersistenceGatewayProvider);
  return ({
    required String projectPath,
    required ProjectManifest initialDocument,
  }) {
    final journalPath = p.join(
      p.dirname(projectPath),
      '.pokemap',
      'recovery',
      'narrative-cinematics.json',
    );
    return NarrativeDocumentSession<ProjectManifest>(
      documentId: 'cinematics',
      initialDocument: initialDocument,
      gateway: ProjectManifestNarrativeDocumentGateway(
        projectPath: projectPath,
        persistence: persistence,
      ),
      recoveryStore: FileNarrativeDocumentRecoveryStore<ProjectManifest>(
        journalPath: journalPath,
        encodeDocument: (document) => document.toJson(),
        decodeDocument: _decodeRecoveryProjectManifest,
      ),
    );
  };
});

final narrativeEventSpatialSourceCreationGatewayProvider =
    Provider<NarrativeEventSpatialSourceCreationGateway>((ref) {
  return NarrativeEventSpatialLinkJournalRepository();
});

final narrativeEventMigrationPersistenceGatewayProvider =
    Provider<NarrativeEventMigrationPersistenceGateway>((ref) {
  return NarrativeEventMigrationPersistenceRepository();
});

/// Providers transverses de bas niveau pour la composition root.
///
/// Ce fichier reste volontairement petit :
/// - uniquement les frontières d'accès aux données / workspace ;
/// - aucune orchestration métier ;
/// - aucune dépendance à des thèmes UI.
@riverpod
ProjectRepository projectRepository(Ref ref) {
  return ref.watch(fileProjectRepositoryProvider);
}

@riverpod
MapRepository mapRepository(Ref ref) {
  return FileMapRepository();
}

@riverpod
TilesetRepository tilesetRepository(Ref ref) {
  return FileTilesetRepository();
}

@riverpod
ProjectWorkspaceFactory projectWorkspaceFactory(Ref ref) {
  return const FileProjectWorkspaceFactory();
}

ProjectManifest _decodeRecoveryProjectManifest(Object? value) {
  if (value is! Map) {
    throw const FormatException(
      'A recovery project manifest must be a JSON object.',
    );
  }
  final json = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException(
        'A recovery project manifest contains a non-string key.',
      );
    }
    json[entry.key as String] = entry.value;
  }
  final manifest = ProjectManifest.fromJson(json);
  ProjectValidator.validate(manifest);
  return manifest;
}
