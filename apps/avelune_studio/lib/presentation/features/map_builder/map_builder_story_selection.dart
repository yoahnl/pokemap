part of 'map_builder_story_binding.dart';

extension MapStorySelection on MapBuilderStoryBinding {
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
    if (!carrierEditable) {
      final record = behaviours
          .registry(project!)
          ?.records
          .where((record) => record.id == _behaviourSelection)
          .firstOrNull;
      final at = record == null ? null : mapStoryLocation(record);
      return this.elements?.byKey(
        at == null ? _mapSelection : '${at.$2.name}:${at.$3}',
      );
    }
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
    if (!carrierEditable && _behaviourSelection != null) {
      return behaviours
          .where((record) => record.id == _behaviourSelection)
          .firstOrNull;
    }
    return behaviours.isEmpty
        ? null
        : behaviours[behaviour.clamp(0, behaviours.length - 1)];
  }

  void select(MapStoryElement element) {
    pendingAfter = null;
    if (!carrierEditable) {
      behaviour = 0;
      _mapSelection = element.key;
      _behaviourSelection = element.behaviours.firstOrNull?.id;
      changed();
      return;
    }
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
    pendingAfter = null;
    if (!carrierEditable) {
      final records = selected?.behaviours ?? const [];
      _behaviourSelection = index >= 0 && index < records.length
          ? records[index].id
          : null;
    }
    behaviour = index;
    changed();
  }
}
