part of 'map_selection_commands.dart';

extension _MapSelectionInsertion on MapSelectionCommands {
  void _moveCells(
    EditableMapDocument scratch,
    MapSelectionTarget target,
    GridPos delta,
  ) {
    final map = scratch.current;
    GridPos shift(GridPos pos) =>
        GridPos(x: pos.x + delta.x, y: pos.y + delta.y);
    switch (target.family) {
      case MapSelectionFamily.decor:
        final element = map.placedElements
            .where((item) => item.id == target.id)
            .firstOrNull;
        if (element != null) {
          MapEditingCommands(
            scratch,
            project,
          ).move(target.id, shift(element.pos));
        }
      case MapSelectionFamily.character:
        final entity = CharacterEditingCommands(
          scratch,
          project,
        ).selected(target.id);
        if (entity != null) {
          CharacterEditingCommands(
            scratch,
            project,
          ).move(target.id, shift(entity.pos));
        }
      case MapSelectionFamily.marker:
        final commands = MapEntityEditingCommands(scratch, project);
        final entity = commands.selected(target.id);
        if (entity != null) commands.move(target.id, shift(entity.pos));
      case MapSelectionFamily.warp:
        final commands = WarpEditingCommands(scratch, project);
        final warp = commands.selected(target.id);
        if (warp != null) commands.move(target.id, shift(warp.pos));
      case MapSelectionFamily.zone:
        final commands = GameplayZoneEditingCommands(scratch, project);
        final zone = commands.selected(target.id);
        if (zone != null) commands.move(target.id, shift(zone.area.pos));
      case MapSelectionFamily.trigger:
        final commands = TriggerEditingCommands(scratch, project);
        final trigger = commands.selected(target.id);
        if (trigger != null) commands.move(target.id, shift(trigger.area.pos));
    }
  }

  MapSelectionTarget _insert(
    EditableMapDocument scratch,
    MapElementCopy item,
    int dx,
    int dy,
  ) {
    final map = scratch.current;
    GridPos shift(GridPos pos) => GridPos(x: pos.x + dx, y: pos.y + dy);
    MapRect area(MapRect rect) => rect.copyWith(pos: shift(rect.pos));
    MapSelectionTarget target(MapSelectionFamily family, String id) =>
        MapSelectionTarget(mapId: map.id, family: family, id: id);
    switch (item) {
      case SpatialModelCopyItem(:final instance, :final elevation):
        final copy = SpatialModelEditingCommands(scratch, project).insertCopy(
          instance,
          x: instance.position.x + dx,
          z: instance.position.z + dy,
          elevation: elevation,
        );
        return target(MapSelectionFamily.decor, copy.id);
      case PlacedDecorCopyItem(:final element):
        final id = MapEditingCommands(
          scratch,
          project,
        ).insertCopy(element, shift(element.pos));
        return target(MapSelectionFamily.decor, id);
      case EntityCopyItem(:final entity, :final family):
        final id = _uniqueId(
          map.entities.map((entry) => entry.id),
          family == MapSelectionFamily.character
              ? 'character'
              : entity.kind.name,
        );
        scratch.commit(
          addEntityToMap(
            map,
            entity: entity.copyWith(
              id: id,
              name: copiedName(entity.name),
              pos: shift(entity.pos),
            ),
          ),
        );
        return target(family, id);
      case WarpCopyItem(:final warp):
        final id = _uniqueId(map.warps.map((entry) => entry.id), 'warp');
        scratch.commit(
          addWarpToMap(
            map,
            warp: warp.copyWith(id: id, pos: shift(warp.pos)),
          ),
        );
        return target(MapSelectionFamily.warp, id);
      case ZoneCopyItem(:final zone):
        final id = _uniqueId(
          map.gameplayZones.map((entry) => entry.id),
          'zone',
        );
        scratch.commit(
          addGameplayZoneToMap(
            map,
            zone: zone.copyWith(
              id: id,
              name: copiedName(zone.name),
              area: area(zone.area),
              cellMask: zone.cellMask?.map(shift).toList(),
            ),
          ),
        );
        return target(MapSelectionFamily.zone, id);
      case TriggerCopyItem(:final trigger):
        final id = _uniqueId(map.triggers.map((entry) => entry.id), 'trigger');
        scratch.commit(
          addTriggerToMap(
            map,
            trigger: trigger.copyWith(
              id: id,
              name: copiedName(trigger.name),
              area: area(trigger.area),
            ),
          ),
        );
        return target(MapSelectionFamily.trigger, id);
    }
  }

  String _uniqueId(Iterable<String> existing, String prefix) {
    final taken = existing.toSet();
    String id;
    do {
      id =
          '$prefix-${DateTime.now().microsecondsSinceEpoch}-${MapSelectionCommands._sequence++}';
    } while (taken.contains(id));
    return id;
  }
}
