import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/repositories.dart';
import '../../infrastructure/repositories/file_repositories.dart';

part 'core_providers.g.dart';

@riverpod
ProjectRepository projectRepository(ProjectRepositoryRef ref) {
  return FileProjectRepository();
}

@riverpod
MapRepository mapRepository(MapRepositoryRef ref) {
  return FileMapRepository();
}

@riverpod
TilesetRepository tilesetRepository(TilesetRepositoryRef ref) {
  return FileTilesetRepository();
}
