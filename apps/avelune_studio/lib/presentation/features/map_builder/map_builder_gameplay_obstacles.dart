part of 'map_builder_gameplay_binding.dart';

extension MapGameplayFieldObstacles on MapBuilderGameplayBinding {
  List<MapEntity> get obstacles => [
    for (final entity in map?.entities ?? const <MapEntity>[])
      if (entity.fieldObstacle != null &&
          studioSearchMatches(entity.name, query))
        entity,
  ];

  FieldObstacleKind? get draftingObstacle {
    final draft = _obstacleDraft;
    return draft != null && draft.mapId == map?.id ? draft.kind : null;
  }

  List<ProjectElementEntry> get obstacleVisuals =>
      maps.project?.elements ?? const [];

  ProjectElementEntry? get obstacleVisual => view()?.brush;

  MapEntity? get selectedObstacle {
    final map = this.map;
    if (map == null) return null;
    final id = view()?.selectedFor(map.id, MapSelectionFamily.marker);
    return map.entities
        .where((entity) => entity.id == id && entity.fieldObstacle != null)
        .firstOrNull;
  }

  SpatialModelInstance? get selectedInstance {
    final map = this.map;
    final scene = map?.spatialScene;
    if (map == null || scene == null) return null;
    final id = view()?.selectedFor(map.id, MapSelectionFamily.decor);
    return scene.instances.where((instance) => instance.id == id).firstOrNull;
  }

  MapEntity? boundEntity(SpatialModelInstance instance) => map?.entities
      .where((entity) => entity.id == instance.entityId)
      .firstOrNull;

  String? obstacleRefusal(SpatialModelInstance instance) =>
      spatialFieldObstacleRefusal(
        instance,
        maps.project?.models3d
            .where((model) => model.id == instance.modelId)
            .firstOrNull,
        boundEntity(instance),
      );

  void draftObstacle(FieldObstacleKind kind) {
    final state = view();
    final map = this.map;
    final document = maps.active;
    if (state == null || map == null || document == null) return;
    state.clearSelection(document);
    _clearDrafts();
    entityError = null;
    _obstacleDraft = (
      mapId: map.id,
      known: {for (final entity in map.entities) entity.id},
      kind: kind,
    );
    state
      ..selectFieldObstacleKind(kind)
      ..brush = null
      ..tool = StudioMapTool.select;
    changed();
  }

  void chooseObstacleVisual(ProjectElementEntry element) {
    final state = view();
    final kind = draftingObstacle;
    if (state == null || kind == null) return;
    state.brush = element;
    state.prepareFieldObstaclePlacement(kind);
    changed();
  }

  void selectObstacle(MapEntity entity) {
    final document = maps.active;
    if (document == null) return;
    _clearDrafts();
    entityError = null;
    release();
    final instance = map?.spatialScene?.instances
        .where((instance) => instance.entityId == entity.id)
        .firstOrNull;
    if (instance != null) {
      view()?.select(document, MapSelectionFamily.decor, instance.id);
    } else {
      view()?.select(document, MapSelectionFamily.marker, entity.id);
    }
    changed();
  }

  Future<void> configureInstanceObstacle(
    String instanceId,
    MapEntityFieldObstacleData? value,
  ) async {
    final document = maps.active;
    final project = maps.project;
    if (document == null || project == null) return;
    final configured = await SpatialModelEditingCommands(
      document,
      project,
    ).configureFieldObstacle(instanceId, value);
    entityError = configured ? null : document.error;
    maps.notify();
  }
}
