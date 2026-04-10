// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectRepositoryHash() => r'4ae01cc29221b6d8ec84621fd925efe249fd6709';

/// Providers transverses de bas niveau pour la composition root.
///
/// Ce fichier reste volontairement petit :
/// - uniquement les frontières d'accès aux données / workspace ;
/// - aucune orchestration métier ;
/// - aucune dépendance à des thèmes UI.
///
/// Copied from [projectRepository].
@ProviderFor(projectRepository)
final projectRepositoryProvider =
    AutoDisposeProvider<ProjectRepository>.internal(
  projectRepository,
  name: r'projectRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProjectRepositoryRef = AutoDisposeProviderRef<ProjectRepository>;
String _$mapRepositoryHash() => r'ef51e6d036fddd1040671d1435c0ead4f96049e9';

/// See also [mapRepository].
@ProviderFor(mapRepository)
final mapRepositoryProvider = AutoDisposeProvider<MapRepository>.internal(
  mapRepository,
  name: r'mapRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mapRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MapRepositoryRef = AutoDisposeProviderRef<MapRepository>;
String _$tilesetRepositoryHash() => r'a0cb36cf26a2120cae9d7f507951364b091318bd';

/// See also [tilesetRepository].
@ProviderFor(tilesetRepository)
final tilesetRepositoryProvider =
    AutoDisposeProvider<TilesetRepository>.internal(
  tilesetRepository,
  name: r'tilesetRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tilesetRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TilesetRepositoryRef = AutoDisposeProviderRef<TilesetRepository>;
String _$projectWorkspaceFactoryHash() =>
    r'8ff147a8c52992ac7914d66b3a01c384f4543591';

/// See also [projectWorkspaceFactory].
@ProviderFor(projectWorkspaceFactory)
final projectWorkspaceFactoryProvider =
    AutoDisposeProvider<ProjectWorkspaceFactory>.internal(
  projectWorkspaceFactory,
  name: r'projectWorkspaceFactoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectWorkspaceFactoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProjectWorkspaceFactoryRef
    = AutoDisposeProviderRef<ProjectWorkspaceFactory>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
