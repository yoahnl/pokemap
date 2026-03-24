import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../use_cases/entity_use_cases.dart';
import 'entity_editing_coordinator.dart';

class EntityCreationResult {
  const EntityCreationResult({
    required this.updatedMap,
    required this.createdEntity,
  });

  final MapData updatedMap;
  final MapEntity createdEntity;
}

class EntityUpdateResult {
  const EntityUpdateResult({
    required this.updatedMap,
    required this.selectedEntityId,
  });

  final MapData updatedMap;
  final String selectedEntityId;
}

class EntityEditingService {
  const EntityEditingService({
    required AddEntityToMapUseCase addEntityToMapUseCase,
    required UpdateEntityOnMapUseCase updateEntityOnMapUseCase,
    required DeleteEntityFromMapUseCase deleteEntityFromMapUseCase,
    required EntityEditingCoordinator entityEditingCoordinator,
  })  : _addEntityToMapUseCase = addEntityToMapUseCase,
        _updateEntityOnMapUseCase = updateEntityOnMapUseCase,
        _deleteEntityFromMapUseCase = deleteEntityFromMapUseCase,
        _entityEditingCoordinator = entityEditingCoordinator;

  final AddEntityToMapUseCase _addEntityToMapUseCase;
  final UpdateEntityOnMapUseCase _updateEntityOnMapUseCase;
  final DeleteEntityFromMapUseCase _deleteEntityFromMapUseCase;
  final EntityEditingCoordinator _entityEditingCoordinator;

  MapEntity? findSelectedEntity(
    MapData? map,
    String? selectedEntityId,
  ) {
    if (map == null || selectedEntityId == null) {
      return null;
    }
    return _entityEditingCoordinator.findEntityById(map, selectedEntityId);
  }

  MapEntity? findEntityAtPos(
    MapData map,
    GridPos pos,
  ) {
    return _entityEditingCoordinator.findEntityAtPos(map, pos);
  }

  MapEntity requireSelectedEntity(
    MapData map,
    String? selectedEntityId,
  ) {
    if (selectedEntityId == null || selectedEntityId.trim().isEmpty) {
      throw const EditorInvalidOperationException('No entity selected');
    }
    final entity = _entityEditingCoordinator.findEntityById(
      map,
      selectedEntityId,
    );
    if (entity == null) {
      throw EditorNotFoundException(
        'Selected entity not found: $selectedEntityId',
      );
    }
    return entity;
  }

  EntityCreationResult addEntityAt(
    MapData map,
    GridPos pos, {
    required MapEntityKind kind,
  }) {
    final entity = _entityEditingCoordinator.createDefaultEntity(
      map,
      pos,
      kind: kind,
    );
    final updated = _addEntityToMapUseCase.execute(
      map,
      entity: entity,
    );
    return EntityCreationResult(
      updatedMap: updated,
      createdEntity: entity,
    );
  }

  EntityUpdateResult updateEntity(
    MapData map, {
    required String entityId,
    String? id,
    String? name,
    MapEntityKind? kind,
    GridPos? pos,
    GridSize? size,
    Map<String, String>? properties,
  }) {
    final updated = _updateEntityOnMapUseCase.execute(
      map,
      entityId: entityId,
      id: id,
      name: name,
      kind: kind,
      pos: pos,
      size: size,
      properties: properties,
    );
    final nextSelectedEntityId =
        id?.trim().isNotEmpty == true ? id!.trim() : entityId;
    return EntityUpdateResult(
      updatedMap: updated,
      selectedEntityId: nextSelectedEntityId,
    );
  }

  MapData deleteEntity(
    MapData map, {
    required String entityId,
  }) {
    return _deleteEntityFromMapUseCase.execute(
      map,
      entityId: entityId,
    );
  }
}
