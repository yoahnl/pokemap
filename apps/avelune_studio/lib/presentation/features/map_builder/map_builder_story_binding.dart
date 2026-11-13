import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
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
