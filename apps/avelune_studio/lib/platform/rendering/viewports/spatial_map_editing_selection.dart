part of 'spatial_map_editing_viewport.dart';

extension _SpatialSelectionOutlines on _SpatialMapEditingViewportState {
  List<SpatialSceneContentHit> get additionalSelection {
    final map = editingDocument.current;
    final instances = {
      for (final instance in map.spatialScene!.instances) instance.id: instance,
    };
    final entities = {for (final entity in map.entities) entity.id: entity};
    SpatialSceneContentHit? hitFor(MapSelectionTarget target) => switch ((
      target.family,
      instances[target.id],
      entities[target.id],
    )) {
      (MapSelectionFamily.decor, final instance?, _) => SpatialSceneContentHit(
        kind: SpatialSceneContentKind.model,
        id: instance.id,
        cell: (instance.position.x.floor(), instance.position.z.floor()),
      ),
      (MapSelectionFamily.character, _, final entity?) =>
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.actor,
          id: 'npc:${entity.id}',
          cell: (entity.pos.x, entity.pos.y),
        ),
      _ => null,
    };
    return [
      for (final target in widget.view.selectionIn(map.id).skip(1))
        ?hitFor(target),
    ];
  }
}
