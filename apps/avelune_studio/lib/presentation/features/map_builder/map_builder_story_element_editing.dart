part of 'map_builder_story_binding.dart';

extension MapStoryElementEditing on MapBuilderStoryBinding {
  MapEntity? entityOf(MapStoryElement element) =>
      element.target == MapStoryElementTarget.entity
      ? map?.entities.where((item) => item.id == element.id).firstOrNull
      : null;

  bool rename(MapStoryElement element, String name) => _edit((
    document,
    project,
  ) {
    final entity = entityOf(element);
    switch (element.target) {
      case MapStoryElementTarget.trigger:
        TriggerEditingCommands(document, project).rename(element.id, name);
      case MapStoryElementTarget.entity when entity?.npc != null:
        CharacterEditingCommands(
          document,
          project,
        ).update(element.id, name: name);
      case MapStoryElementTarget.entity when entity?.sign != null:
        MapEntityEditingCommands(
          document,
          project,
        ).updateSign(element.id, title: name);
      case MapStoryElementTarget.entity:
        MapEntityEditingCommands(document, project).rename(element.id, name);
      case MapStoryElementTarget.model || MapStoryElementTarget.map:
        return false;
    }
    return true;
  });

  bool moveTo(MapStoryElement element, GridPos position) => _edit((
    document,
    project,
  ) {
    final size = element.area?.size ?? const GridSize(width: 1, height: 1);
    if (!_fits(document.current, position, size)) return false;
    switch (element.target) {
      case MapStoryElementTarget.trigger:
        TriggerEditingCommands(document, project).move(element.id, position);
      case MapStoryElementTarget.entity when entityOf(element)?.npc != null:
        CharacterEditingCommands(document, project).move(element.id, position);
      case MapStoryElementTarget.entity:
        MapEntityEditingCommands(document, project).move(element.id, position);
      case MapStoryElementTarget.model || MapStoryElementTarget.map:
        return false;
    }
    return true;
  });

  bool resize(MapStoryElement element, GridSize size) =>
      _edit((document, project) {
        final area = element.area;
        if (element.target != MapStoryElementTarget.trigger ||
            area == null ||
            size.width < 1 ||
            size.height < 1 ||
            !_fits(document.current, area.pos, size)) {
          return false;
        }
        TriggerEditingCommands(document, project).resize(element.id, size);
        return true;
      });

  bool setFacing(MapStoryElement element, EntityFacing facing) =>
      _edit((document, project) {
        CharacterEditingCommands(
          document,
          project,
        ).update(element.id, facing: facing);
        return true;
      });

  bool setBlocks(MapStoryElement element, bool blocks) =>
      _edit((document, project) {
        CharacterEditingCommands(
          document,
          project,
        ).update(element.id, blocks: blocks);
        return true;
      });

  bool setMovement(MapStoryElement element, MapEntityNpcMovementMode mode) =>
      _edit((document, project) {
        final npc = entityOf(element)?.npc;
        if (npc == null) return false;
        CharacterEditingCommands(document, project).setMovementConfiguration(
          element.id,
          npc.movement.copyWith(mode: mode),
        );
        return true;
      });

  bool setTrainer(MapStoryElement element, String? trainerId) =>
      _edit((document, project) {
        CharacterEditingCommands(
          document,
          project,
        ).assignTrainer(element.id, trainerId);
        return true;
      });

  bool setSignText(MapStoryElement element, String text) =>
      _edit((document, project) {
        MapEntityEditingCommands(
          document,
          project,
        ).updateSign(element.id, plainText: text);
        return true;
      });

  bool setCharacter(MapStoryElement element, ProjectCharacterEntry character) =>
      _edit((document, project) {
        CharacterEditingCommands(
          document,
          project,
        ).setCharacter(element.id, character);
        return true;
      });

  bool _edit(
    bool Function(EditableMapDocument document, ProjectManifest project) change,
  ) {
    final document = maps.active;
    final project = maps.project;
    if (document == null || project == null || document.saving) return false;
    attempts++;
    final before = document.current;
    bool applied;
    try {
      applied = change(document, project);
      error = applied ? null : MapBuilderStoryBinding.outOfMap;
    } on Object catch (failure) {
      applied = false;
      error = failure is StateError ? failure.message : '$failure';
    }
    if (!identical(document.current, before)) {
      _record(_StorySide.map, document.undoToken);
      maps.notify();
    }
    changed();
    return applied;
  }

  bool _fits(MapData map, GridPos position, GridSize size) =>
      position.x >= 0 &&
      position.y >= 0 &&
      position.x + size.width <= map.size.width &&
      position.y + size.height <= map.size.height;
}
