import 'package:map_core/map_core.dart' as core;

class TriggerEditingCoordinator {
  const TriggerEditingCoordinator();

  core.MapTrigger? findTriggerAtPos(
    core.MapData map,
    core.GridPos pos,
  ) {
    return core.findTriggerAtPos(map, pos);
  }

  core.MapTrigger? findTriggerById(
    core.MapData map,
    String triggerId,
  ) {
    return core.findTriggerById(map, triggerId);
  }

  String generateUniqueTriggerId(core.MapData map) {
    final ids = map.triggers.map((trigger) => trigger.id).toSet();
    if (!ids.contains('trigger')) {
      return 'trigger';
    }
    var index = 1;
    while (ids.contains('trigger_$index')) {
      index++;
    }
    return 'trigger_$index';
  }

  core.MapTrigger createDefaultTrigger(
    core.MapData map,
    core.GridPos pos,
  ) {
    final id = generateUniqueTriggerId(map);
    return core.MapTrigger(
      id: id,
      name: id,
      type: core.TriggerType.event,
      area: core.MapRect(
        pos: pos,
        size: const core.GridSize(width: 1, height: 1),
      ),
      properties: const {},
    );
  }
}
