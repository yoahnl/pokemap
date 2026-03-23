import 'package:map_core/map_core.dart';

class AddTriggerToMapUseCase {
  MapData execute(
    MapData map, {
    required MapTrigger trigger,
  }) {
    final updated = addTriggerToMap(
      map,
      trigger: trigger,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class UpdateTriggerOnMapUseCase {
  MapData execute(
    MapData map, {
    required String triggerId,
    String? id,
    String? name,
    TriggerType? type,
    MapRect? area,
    Map<String, String>? properties,
  }) {
    final updated = updateTriggerOnMap(
      map,
      triggerId: triggerId,
      id: id,
      name: name,
      type: type,
      area: area,
      properties: properties,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteTriggerFromMapUseCase {
  MapData execute(
    MapData map, {
    required String triggerId,
  }) {
    final updated = removeTriggerFromMap(
      map,
      triggerId: triggerId,
    );
    MapValidator.validate(updated);
    return updated;
  }
}
