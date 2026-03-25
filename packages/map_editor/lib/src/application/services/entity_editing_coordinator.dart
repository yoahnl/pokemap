import 'package:map_core/map_core.dart' as core;

class EntityEditingCoordinator {
  const EntityEditingCoordinator();

  core.MapEntity? findEntityAtPos(
    core.MapData map,
    core.GridPos pos,
  ) {
    return core.findEntityAtPos(map, pos);
  }

  core.MapEntity? findEntityById(
    core.MapData map,
    String entityId,
  ) {
    return core.findEntityById(map, entityId);
  }

  String generateUniqueEntityId(
    core.MapData map,
    core.MapEntityKind kind,
  ) {
    final ids = map.entities.map((entity) => entity.id).toSet();
    final base = _baseIdForKind(kind);
    if (!ids.contains(base)) {
      return base;
    }
    var index = 1;
    while (ids.contains('${base}_$index')) {
      index++;
    }
    return '${base}_$index';
  }

  core.MapEntity createDefaultEntity(
    core.MapData map,
    core.GridPos pos, {
    required core.MapEntityKind kind,
  }) {
    final id = generateUniqueEntityId(map, kind);
    return core.MapEntity(
      id: id,
      name: id,
      kind: kind,
      pos: pos,
      size: const core.GridSize(width: 1, height: 1),
      npc: switch (kind) {
        core.MapEntityKind.npc => const core.MapEntityNpcData(),
        _ => null,
      },
      sign: switch (kind) {
        core.MapEntityKind.sign => const core.MapEntitySignData(),
        _ => null,
      },
      item: switch (kind) {
        core.MapEntityKind.item => const core.MapEntityItemData(),
        _ => null,
      },
      spawn: switch (kind) {
        core.MapEntityKind.spawn => const core.MapEntitySpawnData(),
        _ => null,
      },
      properties: const {},
    );
  }

  String _baseIdForKind(core.MapEntityKind kind) {
    return switch (kind) {
      core.MapEntityKind.npc => 'npc',
      core.MapEntityKind.sign => 'sign',
      core.MapEntityKind.item => 'item',
      core.MapEntityKind.spawn => 'spawn',
      core.MapEntityKind.custom => 'entity',
    };
  }
}
