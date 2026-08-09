// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Providers transverses de bas niveau pour la composition root.
///
/// Ce fichier reste volontairement petit :
/// - uniquement les frontières d'accès aux données / workspace ;
/// - aucune orchestration métier ;
/// - aucune dépendance à des thèmes UI.

@ProviderFor(projectRepository)
final projectRepositoryProvider = ProjectRepositoryProvider._();

/// Providers transverses de bas niveau pour la composition root.
///
/// Ce fichier reste volontairement petit :
/// - uniquement les frontières d'accès aux données / workspace ;
/// - aucune orchestration métier ;
/// - aucune dépendance à des thèmes UI.

final class ProjectRepositoryProvider
    extends
        $FunctionalProvider<
          ProjectRepository,
          ProjectRepository,
          ProjectRepository
        >
    with $Provider<ProjectRepository> {
  /// Providers transverses de bas niveau pour la composition root.
  ///
  /// Ce fichier reste volontairement petit :
  /// - uniquement les frontières d'accès aux données / workspace ;
  /// - aucune orchestration métier ;
  /// - aucune dépendance à des thèmes UI.
  ProjectRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProjectRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProjectRepository create(Ref ref) {
    return projectRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectRepository>(value),
    );
  }
}

String _$projectRepositoryHash() => r'2f4ae3b0e7cfb962752dea40dc499d70a6b5ca97';

@ProviderFor(mapRepository)
final mapRepositoryProvider = MapRepositoryProvider._();

final class MapRepositoryProvider
    extends $FunctionalProvider<MapRepository, MapRepository, MapRepository>
    with $Provider<MapRepository> {
  MapRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapRepositoryHash();

  @$internal
  @override
  $ProviderElement<MapRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MapRepository create(Ref ref) {
    return mapRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapRepository>(value),
    );
  }
}

String _$mapRepositoryHash() => r'e625ba5fda8e74867afa15b3365cf1d58bd5829f';

@ProviderFor(tilesetRepository)
final tilesetRepositoryProvider = TilesetRepositoryProvider._();

final class TilesetRepositoryProvider
    extends
        $FunctionalProvider<
          TilesetRepository,
          TilesetRepository,
          TilesetRepository
        >
    with $Provider<TilesetRepository> {
  TilesetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tilesetRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tilesetRepositoryHash();

  @$internal
  @override
  $ProviderElement<TilesetRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TilesetRepository create(Ref ref) {
    return tilesetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TilesetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TilesetRepository>(value),
    );
  }
}

String _$tilesetRepositoryHash() => r'a0cb36cf26a2120cae9d7f507951364b091318bd';

@ProviderFor(projectWorkspaceFactory)
final projectWorkspaceFactoryProvider = ProjectWorkspaceFactoryProvider._();

final class ProjectWorkspaceFactoryProvider
    extends
        $FunctionalProvider<
          ProjectWorkspaceFactory,
          ProjectWorkspaceFactory,
          ProjectWorkspaceFactory
        >
    with $Provider<ProjectWorkspaceFactory> {
  ProjectWorkspaceFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectWorkspaceFactoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectWorkspaceFactoryHash();

  @$internal
  @override
  $ProviderElement<ProjectWorkspaceFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProjectWorkspaceFactory create(Ref ref) {
    return projectWorkspaceFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectWorkspaceFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectWorkspaceFactory>(value),
    );
  }
}

String _$projectWorkspaceFactoryHash() =>
    r'8ff147a8c52992ac7914d66b3a01c384f4543591';
