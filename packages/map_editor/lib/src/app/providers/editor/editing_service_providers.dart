import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/services/editor_map_mutation_coordinator.dart';
import '../../../application/services/editor_map_session_coordinator.dart';
import '../../../application/services/element_collision_profile_generator.dart';
import '../../../application/services/entity_editing_coordinator.dart';
import '../../../application/services/entity_editing_service.dart';
import '../../../application/services/gameplay_zone_editing_coordinator.dart';
import '../../../application/services/gameplay_zone_editing_service.dart';
import '../../../application/services/map_connection_editing_service.dart';
import '../../../application/services/map_history_coordinator.dart';
import '../../../application/services/path_autotile_resolver.dart';
import '../../../application/services/path_layer_editing_coordinator.dart';
import '../../../application/services/placed_element_instance_indexer.dart';
import '../../../application/services/terrain_painting_coordinator.dart';
import '../../../application/services/terrain_preset_resolver.dart';
import '../../../application/services/terrain_preset_selection_coordinator.dart';
import '../../../application/services/trigger_editing_coordinator.dart';
import '../../../application/services/trigger_editing_service.dart';
import '../../../application/services/warp_editing_coordinator.dart';
import '../../../application/services/warp_editing_service.dart';
import 'map_use_case_providers.dart';

part 'editing_service_providers.g.dart';

/// Providers orientés orchestration d'édition.
///
/// On regroupe ici les services/coordinators qui composent plusieurs use cases
/// déjà existants. Le but est de rendre la composition root lisible par thème,
/// pas d'ajouter une nouvelle couche abstraite.
@riverpod
TerrainPresetResolver terrainPresetResolver(Ref ref) {
  return const TerrainPresetResolver();
}

@riverpod
TerrainPresetSelectionCoordinator terrainPresetSelectionCoordinator(
    Ref ref) {
  return TerrainPresetSelectionCoordinator(
    resolver: ref.watch(terrainPresetResolverProvider),
  );
}

@riverpod
PathAutotileResolver pathAutotileResolver(Ref ref) {
  return const PathAutotileResolver();
}

@riverpod
EditorMapSessionCoordinator editorMapSessionCoordinator(
    Ref ref) {
  return const EditorMapSessionCoordinator();
}

@riverpod
MapHistoryCoordinator mapHistoryCoordinator(Ref ref) {
  return const MapHistoryCoordinator(maxEntries: 100);
}

@riverpod
ElementCollisionProfileGenerator elementCollisionProfileGenerator(
    Ref ref) {
  return const ElementCollisionProfileGenerator();
}

@riverpod
PlacedElementInstanceIndexer placedElementInstanceIndexer(
    Ref ref) {
  return const PlacedElementInstanceIndexer();
}

@riverpod
EditorMapMutationCoordinator editorMapMutationCoordinator(
    Ref ref) {
  return EditorMapMutationCoordinator(
    historyCoordinator: ref.watch(mapHistoryCoordinatorProvider),
    sessionCoordinator: ref.watch(editorMapSessionCoordinatorProvider),
  );
}

@riverpod
WarpEditingCoordinator warpEditingCoordinator(Ref ref) {
  return const WarpEditingCoordinator();
}

@riverpod
EntityEditingCoordinator entityEditingCoordinator(
    Ref ref) {
  return const EntityEditingCoordinator();
}

@riverpod
TriggerEditingCoordinator triggerEditingCoordinator(
    Ref ref) {
  return const TriggerEditingCoordinator();
}

@riverpod
WarpEditingService warpEditingService(Ref ref) {
  return WarpEditingService(
    addWarpToMapUseCase: ref.watch(addWarpToMapUseCaseProvider),
    updateWarpOnMapUseCase: ref.watch(updateWarpOnMapUseCaseProvider),
    deleteWarpFromMapUseCase: ref.watch(deleteWarpFromMapUseCaseProvider),
    validateWarpTargetMapUseCase:
        ref.watch(validateWarpTargetMapUseCaseProvider),
    createReciprocalWarpUseCase: ref.watch(createReciprocalWarpUseCaseProvider),
    warpEditingCoordinator: ref.watch(warpEditingCoordinatorProvider),
  );
}

@riverpod
TriggerEditingService triggerEditingService(Ref ref) {
  return TriggerEditingService(
    addTriggerToMapUseCase: ref.watch(addTriggerToMapUseCaseProvider),
    updateTriggerOnMapUseCase: ref.watch(updateTriggerOnMapUseCaseProvider),
    deleteTriggerFromMapUseCase: ref.watch(deleteTriggerFromMapUseCaseProvider),
    triggerEditingCoordinator: ref.watch(triggerEditingCoordinatorProvider),
  );
}

@riverpod
EntityEditingService entityEditingService(Ref ref) {
  return EntityEditingService(
    addEntityToMapUseCase: ref.watch(addEntityToMapUseCaseProvider),
    updateEntityOnMapUseCase: ref.watch(updateEntityOnMapUseCaseProvider),
    deleteEntityFromMapUseCase: ref.watch(deleteEntityFromMapUseCaseProvider),
    entityEditingCoordinator: ref.watch(entityEditingCoordinatorProvider),
  );
}

@riverpod
MapConnectionEditingService mapConnectionEditingService(
    Ref ref) {
  return MapConnectionEditingService(
    upsertMapConnectionUseCase: ref.watch(upsertMapConnectionUseCaseProvider),
    deleteMapConnectionUseCase: ref.watch(deleteMapConnectionUseCaseProvider),
    resolveMapConnectionTargetUseCase:
        ref.watch(resolveMapConnectionTargetUseCaseProvider),
  );
}

@riverpod
TerrainPaintingCoordinator terrainPaintingCoordinator(
    Ref ref) {
  return TerrainPaintingCoordinator(
    paintTerrainOnMapUseCase: ref.watch(paintTerrainOnMapUseCaseProvider),
    paintTerrainPatternOnMapUseCase:
        ref.watch(paintTerrainPatternOnMapUseCaseProvider),
    eraseTerrainOnMapUseCase: ref.watch(eraseTerrainOnMapUseCaseProvider),
    eraseTerrainPatternOnMapUseCase:
        ref.watch(eraseTerrainPatternOnMapUseCaseProvider),
  );
}

@riverpod
PathLayerEditingCoordinator pathLayerEditingCoordinator(
    Ref ref) {
  return PathLayerEditingCoordinator(
    paintPathOnMapUseCase: ref.watch(paintPathOnMapUseCaseProvider),
    paintPathPatternOnMapUseCase:
        ref.watch(paintPathPatternOnMapUseCaseProvider),
    erasePathOnMapUseCase: ref.watch(erasePathOnMapUseCaseProvider),
    erasePathPatternOnMapUseCase:
        ref.watch(erasePathPatternOnMapUseCaseProvider),
    assignPathPresetToLayerUseCase:
        ref.watch(assignPathPresetToLayerUseCaseProvider),
  );
}

@riverpod
GameplayZoneEditingCoordinator gameplayZoneEditingCoordinator(
    Ref ref) {
  return const GameplayZoneEditingCoordinator();
}

@riverpod
GameplayZoneEditingService gameplayZoneEditingService(
    Ref ref) {
  return GameplayZoneEditingService(
    addGameplayZoneToMapUseCase: ref.watch(addGameplayZoneToMapUseCaseProvider),
    updateGameplayZoneOnMapUseCase:
        ref.watch(updateGameplayZoneOnMapUseCaseProvider),
    deleteGameplayZoneFromMapUseCase:
        ref.watch(deleteGameplayZoneFromMapUseCaseProvider),
    coordinator: ref.watch(gameplayZoneEditingCoordinatorProvider),
  );
}
