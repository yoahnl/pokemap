import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';

enum MapStoryTab { behaviour, properties }

class MapBuilderStoryBinding {
  MapBuilderStoryBinding({
    required this.maps,
    required this.changed,
    required this.view,
  });

  final MapWorkspaceController maps;
  final void Function() changed;
  final MapEditingViewportSession? Function() view;
  String query = '';
  MapStoryElementKind? filter;
  MapStoryTab tab = MapStoryTab.behaviour;
  int behaviour = 0;
  String? error;
  String? _mapSelection;
  MapStoryElements? _elements;
  MapData? _source;
  ProjectManifest? _project;

  MapData? get map => maps.active?.current;

  MapStoryElements? get elements {
    final map = this.map;
    if (map == null) return null;
    final project = maps.project;
    if (!identical(map, _source) || !identical(project, _project)) {
      _source = map;
      _project = project;
      _elements = MapStoryElements(map, project);
    }
    return _elements;
  }

  List<MapStoryElement> get visible {
    final needle = query.trim().toLowerCase();
    return [
      for (final element in elements?.elements ?? const <MapStoryElement>[])
        if ((filter == null || element.kind == filter) &&
            (needle.isEmpty || element.name.toLowerCase().contains(needle)))
          element,
    ];
  }

  MapStoryElement? get selected {
    final map = this.map;
    final session = view();
    if (map == null || session == null) return null;
    final elements = this.elements!;
    for (final (family, target) in const [
      (MapSelectionFamily.character, MapStoryElementTarget.entity),
      (MapSelectionFamily.marker, MapStoryElementTarget.entity),
      (MapSelectionFamily.trigger, MapStoryElementTarget.trigger),
      (MapSelectionFamily.decor, MapStoryElementTarget.model),
    ]) {
      final id = session.selectedFor(map.id, family);
      if (id != null) return elements.byKey('${target.name}:$id');
    }
    if (session.hasSelectionIn(map.id)) return null;
    return elements.byKey(_mapSelection);
  }

  NarrativeEventRecord? get selectedBehaviour {
    final behaviours = selected?.behaviours ?? const [];
    return behaviours.isEmpty
        ? null
        : behaviours[behaviour.clamp(0, behaviours.length - 1)];
  }

  void select(MapStoryElement element) {
    final document = maps.active;
    final session = view();
    if (document == null || session == null) return;
    behaviour = 0;
    _mapSelection = null;
    switch (element.target) {
      case MapStoryElementTarget.map:
        session.clearSelection(document);
        _mapSelection = element.key;
      case MapStoryElementTarget.entity:
        final entity = document.current.entities
            .where((item) => item.id == element.id)
            .firstOrNull;
        session.select(
          document,
          entity?.kind == MapEntityKind.npc
              ? MapSelectionFamily.character
              : MapSelectionFamily.marker,
          element.id,
        );
      case MapStoryElementTarget.trigger:
        session.select(document, MapSelectionFamily.trigger, element.id);
      case MapStoryElementTarget.model:
        session.select(document, MapSelectionFamily.decor, element.id);
    }
    changed();
  }

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

  bool _edit(
    bool Function(EditableMapDocument document, ProjectManifest project) change,
  ) {
    final document = maps.active;
    final project = maps.project;
    if (document == null || project == null || document.saving) return false;
    final before = document.current;
    bool applied;
    try {
      applied = change(document, project);
      error = applied ? null : outOfMap;
    } on Object catch (failure) {
      applied = false;
      error = failure is StateError ? failure.message : '$failure';
    }
    if (!identical(document.current, before)) maps.notify();
    changed();
    return applied;
  }

  static const outOfMap = 'out-of-map';

  bool _fits(MapData map, GridPos position, GridSize size) =>
      position.x >= 0 &&
      position.y >= 0 &&
      position.x + size.width <= map.size.width &&
      position.y + size.height <= map.size.height;

  void search(String value) {
    query = value;
    changed();
  }

  void showKind(MapStoryElementKind? value) {
    filter = value;
    changed();
  }

  void openTab(MapStoryTab value) {
    tab = value;
    changed();
  }

  void openBehaviour(int index) {
    behaviour = index;
    changed();
  }
}
