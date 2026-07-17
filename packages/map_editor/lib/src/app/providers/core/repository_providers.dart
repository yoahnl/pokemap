import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/ports/narrative_event_registry_persistence_gateway.dart';
import '../../../application/ports/narrative_event_migration_persistence_gateway.dart';
import '../../../application/ports/narrative_event_spatial_source_creation_gateway.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../../../infrastructure/repositories/file_repositories.dart';
import '../../../infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import '../../../infrastructure/repositories/narrative_event_migration_persistence_repository.dart';

part 'repository_providers.g.dart';

final fileProjectRepositoryProvider = Provider<FileProjectRepository>((ref) {
  return FileProjectRepository();
});

final narrativeEventRegistryPersistenceGatewayProvider =
    Provider<NarrativeEventRegistryPersistenceGateway>((ref) {
  return ref.watch(fileProjectRepositoryProvider);
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
