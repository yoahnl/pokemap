import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../use_cases/gameplay_zone_use_cases.dart';
import 'gameplay_zone_editing_coordinator.dart';

class GameplayZoneCreationResult {
  const GameplayZoneCreationResult({
    required this.updatedMap,
    required this.createdZone,
  });

  final MapData updatedMap;
  final MapGameplayZone createdZone;
}

class GameplayZoneUpdateResult {
  const GameplayZoneUpdateResult({
    required this.updatedMap,
    required this.selectedZoneId,
  });

  final MapData updatedMap;
  final String selectedZoneId;
}

class GameplayZoneEditingService {
  const GameplayZoneEditingService({
    required AddGameplayZoneToMapUseCase addGameplayZoneToMapUseCase,
    required UpdateGameplayZoneOnMapUseCase updateGameplayZoneOnMapUseCase,
    required DeleteGameplayZoneFromMapUseCase deleteGameplayZoneFromMapUseCase,
    required GameplayZoneEditingCoordinator coordinator,
  })  : _addUseCase = addGameplayZoneToMapUseCase,
        _updateUseCase = updateGameplayZoneOnMapUseCase,
        _deleteUseCase = deleteGameplayZoneFromMapUseCase,
        _coordinator = coordinator;

  final AddGameplayZoneToMapUseCase _addUseCase;
  final UpdateGameplayZoneOnMapUseCase _updateUseCase;
  final DeleteGameplayZoneFromMapUseCase _deleteUseCase;
  final GameplayZoneEditingCoordinator _coordinator;

  MapGameplayZone? findSelectedZone(
    MapData? map,
    String? selectedZoneId,
  ) {
    if (map == null || selectedZoneId == null) return null;
    return _coordinator.findZoneById(map, selectedZoneId);
  }

  MapGameplayZone? findZoneAtPos(MapData map, GridPos pos) {
    return _coordinator.findZoneAtPos(map, pos);
  }

  MapGameplayZone requireSelectedZone(MapData map, String? selectedZoneId) {
    if (selectedZoneId == null || selectedZoneId.trim().isEmpty) {
      throw const EditorInvalidOperationException('No gameplay zone selected');
    }
    final zone = _coordinator.findZoneById(map, selectedZoneId);
    if (zone == null) {
      throw EditorNotFoundException(
        'Selected gameplay zone not found: $selectedZoneId',
      );
    }
    return zone;
  }

  GameplayZoneCreationResult addZoneAt(MapData map, GridPos pos) {
    final zone = _coordinator.createDefaultZone(map, pos);
    final updated = _addUseCase.execute(map, zone: zone);
    return GameplayZoneCreationResult(updatedMap: updated, createdZone: zone);
  }

  GameplayZoneUpdateResult updateZone(
    MapData map, {
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    Object? encounterTableId,
    Object? movementMode,
    int? priority,
    Map<String, String>? properties,
  }) {
    final updated = _updateUseCase.execute(
      map,
      zoneId: zoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      encounterTableId: encounterTableId,
      movementMode: movementMode,
      priority: priority,
      properties: properties,
    );
    final nextId =
        id?.trim().isNotEmpty == true ? id!.trim() : zoneId;
    return GameplayZoneUpdateResult(updatedMap: updated, selectedZoneId: nextId);
  }

  MapData deleteZone(MapData map, {required String zoneId}) {
    return _deleteUseCase.execute(map, zoneId: zoneId);
  }
}
