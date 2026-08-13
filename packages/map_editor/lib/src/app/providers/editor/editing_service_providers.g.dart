// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editing_service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Providers orientés orchestration d'édition.
///
/// On regroupe ici les services/coordinators qui composent plusieurs use cases
/// déjà existants. Le but est de rendre la composition root lisible par thème,
/// pas d'ajouter une nouvelle couche abstraite.

@ProviderFor(editorMapSessionCoordinator)
final editorMapSessionCoordinatorProvider =
    EditorMapSessionCoordinatorProvider._();

/// Providers orientés orchestration d'édition.
///
/// On regroupe ici les services/coordinators qui composent plusieurs use cases
/// déjà existants. Le but est de rendre la composition root lisible par thème,
/// pas d'ajouter une nouvelle couche abstraite.

final class EditorMapSessionCoordinatorProvider
    extends
        $FunctionalProvider<
          EditorMapSessionCoordinator,
          EditorMapSessionCoordinator,
          EditorMapSessionCoordinator
        >
    with $Provider<EditorMapSessionCoordinator> {
  /// Providers orientés orchestration d'édition.
  ///
  /// On regroupe ici les services/coordinators qui composent plusieurs use cases
  /// déjà existants. Le but est de rendre la composition root lisible par thème,
  /// pas d'ajouter une nouvelle couche abstraite.
  EditorMapSessionCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editorMapSessionCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editorMapSessionCoordinatorHash();

  @$internal
  @override
  $ProviderElement<EditorMapSessionCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EditorMapSessionCoordinator create(Ref ref) {
    return editorMapSessionCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorMapSessionCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorMapSessionCoordinator>(value),
    );
  }
}

String _$editorMapSessionCoordinatorHash() =>
    r'36758252f8c1d423908ec39a0e70e5f0f3edc388';

@ProviderFor(mapHistoryCoordinator)
final mapHistoryCoordinatorProvider = MapHistoryCoordinatorProvider._();

final class MapHistoryCoordinatorProvider
    extends
        $FunctionalProvider<
          MapHistoryCoordinator,
          MapHistoryCoordinator,
          MapHistoryCoordinator
        >
    with $Provider<MapHistoryCoordinator> {
  MapHistoryCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapHistoryCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapHistoryCoordinatorHash();

  @$internal
  @override
  $ProviderElement<MapHistoryCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MapHistoryCoordinator create(Ref ref) {
    return mapHistoryCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapHistoryCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapHistoryCoordinator>(value),
    );
  }
}

String _$mapHistoryCoordinatorHash() =>
    r'dd82add82e5d2c14d47ee8629e51e10afb6be83e';

@ProviderFor(elementCollisionProfileGenerator)
final elementCollisionProfileGeneratorProvider =
    ElementCollisionProfileGeneratorProvider._();

final class ElementCollisionProfileGeneratorProvider
    extends
        $FunctionalProvider<
          ElementCollisionProfileGenerator,
          ElementCollisionProfileGenerator,
          ElementCollisionProfileGenerator
        >
    with $Provider<ElementCollisionProfileGenerator> {
  ElementCollisionProfileGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'elementCollisionProfileGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$elementCollisionProfileGeneratorHash();

  @$internal
  @override
  $ProviderElement<ElementCollisionProfileGenerator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ElementCollisionProfileGenerator create(Ref ref) {
    return elementCollisionProfileGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ElementCollisionProfileGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ElementCollisionProfileGenerator>(
        value,
      ),
    );
  }
}

String _$elementCollisionProfileGeneratorHash() =>
    r'eb949f8cdd12b3ed9c175b2a5936eee34817869c';

@ProviderFor(placedElementInstanceIndexer)
final placedElementInstanceIndexerProvider =
    PlacedElementInstanceIndexerProvider._();

final class PlacedElementInstanceIndexerProvider
    extends
        $FunctionalProvider<
          PlacedElementInstanceIndexer,
          PlacedElementInstanceIndexer,
          PlacedElementInstanceIndexer
        >
    with $Provider<PlacedElementInstanceIndexer> {
  PlacedElementInstanceIndexerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placedElementInstanceIndexerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placedElementInstanceIndexerHash();

  @$internal
  @override
  $ProviderElement<PlacedElementInstanceIndexer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlacedElementInstanceIndexer create(Ref ref) {
    return placedElementInstanceIndexer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlacedElementInstanceIndexer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlacedElementInstanceIndexer>(value),
    );
  }
}

String _$placedElementInstanceIndexerHash() =>
    r'f6b715a5967fdb2897fba6868e7d804bbb233da9';

@ProviderFor(editorMapMutationCoordinator)
final editorMapMutationCoordinatorProvider =
    EditorMapMutationCoordinatorProvider._();

final class EditorMapMutationCoordinatorProvider
    extends
        $FunctionalProvider<
          EditorMapMutationCoordinator,
          EditorMapMutationCoordinator,
          EditorMapMutationCoordinator
        >
    with $Provider<EditorMapMutationCoordinator> {
  EditorMapMutationCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editorMapMutationCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editorMapMutationCoordinatorHash();

  @$internal
  @override
  $ProviderElement<EditorMapMutationCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EditorMapMutationCoordinator create(Ref ref) {
    return editorMapMutationCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorMapMutationCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorMapMutationCoordinator>(value),
    );
  }
}

String _$editorMapMutationCoordinatorHash() =>
    r'f268918aeb5a98a3ad015aee2f8329acf4c23dd7';

@ProviderFor(warpEditingCoordinator)
final warpEditingCoordinatorProvider = WarpEditingCoordinatorProvider._();

final class WarpEditingCoordinatorProvider
    extends
        $FunctionalProvider<
          WarpEditingCoordinator,
          WarpEditingCoordinator,
          WarpEditingCoordinator
        >
    with $Provider<WarpEditingCoordinator> {
  WarpEditingCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'warpEditingCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$warpEditingCoordinatorHash();

  @$internal
  @override
  $ProviderElement<WarpEditingCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WarpEditingCoordinator create(Ref ref) {
    return warpEditingCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WarpEditingCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WarpEditingCoordinator>(value),
    );
  }
}

String _$warpEditingCoordinatorHash() =>
    r'3aa5d3dacdb278c657bb0d636b5d04e5453c77f1';

@ProviderFor(entityEditingCoordinator)
final entityEditingCoordinatorProvider = EntityEditingCoordinatorProvider._();

final class EntityEditingCoordinatorProvider
    extends
        $FunctionalProvider<
          EntityEditingCoordinator,
          EntityEditingCoordinator,
          EntityEditingCoordinator
        >
    with $Provider<EntityEditingCoordinator> {
  EntityEditingCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entityEditingCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entityEditingCoordinatorHash();

  @$internal
  @override
  $ProviderElement<EntityEditingCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EntityEditingCoordinator create(Ref ref) {
    return entityEditingCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntityEditingCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntityEditingCoordinator>(value),
    );
  }
}

String _$entityEditingCoordinatorHash() =>
    r'8125ee6c7ec14c91e32882a279bcb6364910f333';

@ProviderFor(triggerEditingCoordinator)
final triggerEditingCoordinatorProvider = TriggerEditingCoordinatorProvider._();

final class TriggerEditingCoordinatorProvider
    extends
        $FunctionalProvider<
          TriggerEditingCoordinator,
          TriggerEditingCoordinator,
          TriggerEditingCoordinator
        >
    with $Provider<TriggerEditingCoordinator> {
  TriggerEditingCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'triggerEditingCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$triggerEditingCoordinatorHash();

  @$internal
  @override
  $ProviderElement<TriggerEditingCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TriggerEditingCoordinator create(Ref ref) {
    return triggerEditingCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TriggerEditingCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TriggerEditingCoordinator>(value),
    );
  }
}

String _$triggerEditingCoordinatorHash() =>
    r'95cfee377531922696ad5b127a649daa15d45f3f';

@ProviderFor(warpEditingService)
final warpEditingServiceProvider = WarpEditingServiceProvider._();

final class WarpEditingServiceProvider
    extends
        $FunctionalProvider<
          WarpEditingService,
          WarpEditingService,
          WarpEditingService
        >
    with $Provider<WarpEditingService> {
  WarpEditingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'warpEditingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$warpEditingServiceHash();

  @$internal
  @override
  $ProviderElement<WarpEditingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WarpEditingService create(Ref ref) {
    return warpEditingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WarpEditingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WarpEditingService>(value),
    );
  }
}

String _$warpEditingServiceHash() =>
    r'9a709f48d72b119940539494136c3b08e0f434c5';

@ProviderFor(triggerEditingService)
final triggerEditingServiceProvider = TriggerEditingServiceProvider._();

final class TriggerEditingServiceProvider
    extends
        $FunctionalProvider<
          TriggerEditingService,
          TriggerEditingService,
          TriggerEditingService
        >
    with $Provider<TriggerEditingService> {
  TriggerEditingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'triggerEditingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$triggerEditingServiceHash();

  @$internal
  @override
  $ProviderElement<TriggerEditingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TriggerEditingService create(Ref ref) {
    return triggerEditingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TriggerEditingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TriggerEditingService>(value),
    );
  }
}

String _$triggerEditingServiceHash() =>
    r'0eb238b1d556ff5f829bfd92543341238fe393b0';

@ProviderFor(entityEditingService)
final entityEditingServiceProvider = EntityEditingServiceProvider._();

final class EntityEditingServiceProvider
    extends
        $FunctionalProvider<
          EntityEditingService,
          EntityEditingService,
          EntityEditingService
        >
    with $Provider<EntityEditingService> {
  EntityEditingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entityEditingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entityEditingServiceHash();

  @$internal
  @override
  $ProviderElement<EntityEditingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EntityEditingService create(Ref ref) {
    return entityEditingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntityEditingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntityEditingService>(value),
    );
  }
}

String _$entityEditingServiceHash() =>
    r'76dcd79b87d77aa6d190d8d658f111bbc71f87b5';

@ProviderFor(mapConnectionEditingService)
final mapConnectionEditingServiceProvider =
    MapConnectionEditingServiceProvider._();

final class MapConnectionEditingServiceProvider
    extends
        $FunctionalProvider<
          MapConnectionEditingService,
          MapConnectionEditingService,
          MapConnectionEditingService
        >
    with $Provider<MapConnectionEditingService> {
  MapConnectionEditingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapConnectionEditingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapConnectionEditingServiceHash();

  @$internal
  @override
  $ProviderElement<MapConnectionEditingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MapConnectionEditingService create(Ref ref) {
    return mapConnectionEditingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapConnectionEditingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapConnectionEditingService>(value),
    );
  }
}

String _$mapConnectionEditingServiceHash() =>
    r'a0c38a228f353ef06e236696cfc54b57be3a9983';

@ProviderFor(gameplayZoneEditingCoordinator)
final gameplayZoneEditingCoordinatorProvider =
    GameplayZoneEditingCoordinatorProvider._();

final class GameplayZoneEditingCoordinatorProvider
    extends
        $FunctionalProvider<
          GameplayZoneEditingCoordinator,
          GameplayZoneEditingCoordinator,
          GameplayZoneEditingCoordinator
        >
    with $Provider<GameplayZoneEditingCoordinator> {
  GameplayZoneEditingCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameplayZoneEditingCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameplayZoneEditingCoordinatorHash();

  @$internal
  @override
  $ProviderElement<GameplayZoneEditingCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GameplayZoneEditingCoordinator create(Ref ref) {
    return gameplayZoneEditingCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameplayZoneEditingCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameplayZoneEditingCoordinator>(
        value,
      ),
    );
  }
}

String _$gameplayZoneEditingCoordinatorHash() =>
    r'de7c7f3e76b629890609ce92731dd58b2783abb4';

@ProviderFor(gameplayZoneEditingService)
final gameplayZoneEditingServiceProvider =
    GameplayZoneEditingServiceProvider._();

final class GameplayZoneEditingServiceProvider
    extends
        $FunctionalProvider<
          GameplayZoneEditingService,
          GameplayZoneEditingService,
          GameplayZoneEditingService
        >
    with $Provider<GameplayZoneEditingService> {
  GameplayZoneEditingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameplayZoneEditingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameplayZoneEditingServiceHash();

  @$internal
  @override
  $ProviderElement<GameplayZoneEditingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GameplayZoneEditingService create(Ref ref) {
    return gameplayZoneEditingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameplayZoneEditingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameplayZoneEditingService>(value),
    );
  }
}

String _$gameplayZoneEditingServiceHash() =>
    r'36699eac7645de126ef7e8325f9f303dafc363c3';
