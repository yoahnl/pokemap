import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../application/use_cases/project_use_cases.dart';
import 'core_providers.dart';

part 'use_case_providers.g.dart';

@riverpod
CreateProjectUseCase createProjectUseCase(CreateProjectUseCaseRef ref) {
  return CreateProjectUseCase(ref.watch(projectRepositoryProvider));
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
