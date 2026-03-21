import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../application/use_cases/project_use_cases.dart';
import 'core_providers.dart';

part 'use_case_providers.g.dart';

@riverpod
CreateProjectUseCase createProjectUseCase(CreateProjectUseCaseRef ref) {
  return CreateProjectUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
LoadProjectUseCase loadProjectUseCase(LoadProjectUseCaseRef ref) {
  return LoadProjectUseCase(ref.watch(projectRepositoryProvider));
}

@riverpod
SaveMapUseCase saveMapUseCase(SaveMapUseCaseRef ref) {
  return SaveMapUseCase(ref.watch(mapRepositoryProvider));
}

@riverpod
CreateMapUseCase createMapUseCase(CreateMapUseCaseRef ref) {
  return CreateMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
LoadMapUseCase loadMapUseCase(LoadMapUseCaseRef ref) {
  return LoadMapUseCase(ref.watch(mapRepositoryProvider));
}

@riverpod
RenameMapUseCase renameMapUseCase(RenameMapUseCaseRef ref) {
  return RenameMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DeleteMapUseCase deleteMapUseCase(DeleteMapUseCaseRef ref) {
  return DeleteMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}

@riverpod
DuplicateMapUseCase duplicateMapUseCase(DuplicateMapUseCaseRef ref) {
  return DuplicateMapUseCase(
    ref.watch(mapRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
}
