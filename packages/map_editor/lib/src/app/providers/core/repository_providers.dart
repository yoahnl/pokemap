import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/ports/project_workspace.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../../../infrastructure/repositories/file_repositories.dart';

part 'repository_providers.g.dart';

/// Providers transverses de bas niveau pour la composition root.
///
/// Ce fichier reste volontairement petit :
/// - uniquement les frontières d'accès aux données / workspace ;
/// - aucune orchestration métier ;
/// - aucune dépendance à des thèmes UI.
@riverpod
ProjectRepository projectRepository(Ref ref) {
  return FileProjectRepository();
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
