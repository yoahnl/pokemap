import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../use_cases/trigger_use_cases.dart';
import 'trigger_editing_coordinator.dart';

class TriggerCreationResult {
  const TriggerCreationResult({
    required this.updatedMap,
    required this.createdTrigger,
  });

  final MapData updatedMap;
  final MapTrigger createdTrigger;
}

class TriggerUpdateResult {
  const TriggerUpdateResult({
    required this.updatedMap,
    required this.selectedTriggerId,
  });

  final MapData updatedMap;
  final String selectedTriggerId;
}

class TriggerEditingService {
  const TriggerEditingService({
    required AddTriggerToMapUseCase addTriggerToMapUseCase,
    required UpdateTriggerOnMapUseCase updateTriggerOnMapUseCase,
    required DeleteTriggerFromMapUseCase deleteTriggerFromMapUseCase,
    required TriggerEditingCoordinator triggerEditingCoordinator,
  })  : _addTriggerToMapUseCase = addTriggerToMapUseCase,
        _updateTriggerOnMapUseCase = updateTriggerOnMapUseCase,
        _deleteTriggerFromMapUseCase = deleteTriggerFromMapUseCase,
        _triggerEditingCoordinator = triggerEditingCoordinator;

  final AddTriggerToMapUseCase _addTriggerToMapUseCase;
  final UpdateTriggerOnMapUseCase _updateTriggerOnMapUseCase;
  final DeleteTriggerFromMapUseCase _deleteTriggerFromMapUseCase;
  final TriggerEditingCoordinator _triggerEditingCoordinator;

  MapTrigger? findSelectedTrigger(
    MapData? map,
    String? selectedTriggerId,
  ) {
    if (map == null || selectedTriggerId == null) {
      return null;
    }
    return _triggerEditingCoordinator.findTriggerById(map, selectedTriggerId);
  }

  MapTrigger? findTriggerAtPos(
    MapData map,
    GridPos pos,
  ) {
    return _triggerEditingCoordinator.findTriggerAtPos(map, pos);
  }

  MapTrigger requireSelectedTrigger(
    MapData map,
    String? selectedTriggerId,
  ) {
    if (selectedTriggerId == null || selectedTriggerId.trim().isEmpty) {
      throw const EditorInvalidOperationException('No trigger selected');
    }
    final trigger = _triggerEditingCoordinator.findTriggerById(
      map,
      selectedTriggerId,
    );
    if (trigger == null) {
      throw EditorNotFoundException(
        'Selected trigger not found: $selectedTriggerId',
      );
    }
    return trigger;
  }

  TriggerCreationResult addTriggerAt(
    MapData map,
    GridPos pos,
  ) {
    final trigger = _triggerEditingCoordinator.createDefaultTrigger(map, pos);
    final updated = _addTriggerToMapUseCase.execute(map, trigger: trigger);
    return TriggerCreationResult(
      updatedMap: updated,
      createdTrigger: trigger,
    );
  }

  TriggerUpdateResult updateTrigger(
    MapData map, {
    required String triggerId,
    String? id,
    String? name,
    TriggerType? type,
    MapRect? area,
    Map<String, String>? properties,
  }) {
    final updated = _updateTriggerOnMapUseCase.execute(
      map,
      triggerId: triggerId,
      id: id,
      name: name,
      type: type,
      area: area,
      properties: properties,
    );
    final nextSelectedTriggerId =
        id?.trim().isNotEmpty == true ? id!.trim() : triggerId;
    return TriggerUpdateResult(
      updatedMap: updated,
      selectedTriggerId: nextSelectedTriggerId,
    );
  }

  MapData deleteTrigger(
    MapData map, {
    required String triggerId,
  }) {
    return _deleteTriggerFromMapUseCase.execute(
      map,
      triggerId: triggerId,
    );
  }
}
