part of 'map_workspace_editing_state.dart';

mixin _MapWorkspaceSelectionState {
  set pendingMove(MapSelectionTarget? target);

  ({String mapId, GridPos cell})? pointer;
  MapSelectionTarget? _target;
  MapSelectionTarget? get target => _target;
  final _extras = <MapSelectionTarget>[];

  List<MapSelectionTarget> selectionIn(String mapId) => [
    if (_target case final target? when target.mapId == mapId) target,
    for (final extra in _extras)
      if (extra.mapId == mapId) extra,
  ];

  bool isSelected(String mapId, MapSelectionFamily family, String id) =>
      selectionIn(mapId)
          .any((target) => target.family == family && target.id == id);

  String? selectedFor(String mapId, MapSelectionFamily family) {
    final target = _target;
    return target != null && target.mapId == mapId && target.family == family
        ? target.id
        : null;
  }

  bool hasSelectionIn(String mapId) => _target?.mapId == mapId;

  Set<String> selectedDecorIds(String mapId) => {
    for (final target in selectionIn(mapId))
      if (target.family == MapSelectionFamily.decor) target.id,
  };

  bool isUnavailable(
    EditableMapDocument document,
    MapSelectionFamily family,
    String id,
  ) {
    final kind = switch (family) {
      MapSelectionFamily.decor =>
        document.current.spatialScene?.instances.any(
                  (entry) => entry.id == id,
                ) ==
                true
            ? 'model'
            : 'decor',
      MapSelectionFamily.character || MapSelectionFamily.marker => 'entity',
      MapSelectionFamily.warp => 'warp',
      MapSelectionFamily.zone => 'zone',
      MapSelectionFamily.trigger => 'trigger',
    };
    return document.isElementUnavailable(kind, id);
  }

  void _pruneUnavailable(EditableMapDocument document) => pruneSelection(
    document,
    (family, id) => isUnavailable(document, family, id),
  );

  void pruneSelection(
    EditableMapDocument document,
    bool Function(MapSelectionFamily family, String id) stale,
  ) {
    final mapId = document.current.id;
    _extras.removeWhere(
      (extra) => extra.mapId == mapId && stale(extra.family, extra.id),
    );
    final target = _target;
    if (target != null &&
        target.mapId == mapId &&
        stale(target.family, target.id)) {
      if (_extras.any((extra) => extra.mapId == mapId)) {
        _promote(
          document,
          _extras.removeAt(_extras.indexWhere((extra) => extra.mapId == mapId)),
        );
      } else {
        clearSelection(document);
      }
    }
  }

  void toggleInSelection(
    EditableMapDocument document,
    MapSelectionFamily family,
    String id,
  ) {
    final mapId = document.current.id;
    final target = _target;
    if (target == null || target.mapId != mapId) {
      select(document, family, id);
      return;
    }
    if (isUnavailable(document, family, id)) return;
    _extras.removeWhere((extra) => extra.mapId != mapId);
    if (target.family == family && target.id == id) {
      if (_extras.isEmpty) {
        clearSelection(document);
      } else {
        _promote(document, _extras.removeAt(0));
      }
      return;
    }
    final index = _extras.indexWhere(
      (extra) => extra.family == family && extra.id == id,
    );
    if (index >= 0) {
      _extras.removeAt(index);
    } else {
      _extras.add(MapSelectionTarget(mapId: mapId, family: family, id: id));
    }
  }

  void toggleDecorInSelection(EditableMapDocument document, String id) =>
      toggleInSelection(document, MapSelectionFamily.decor, id);

  void selectAll(
    EditableMapDocument document,
    List<MapSelectionTarget> targets,
  ) {
    final available = [
      for (final target in targets)
        if (target.mapId == document.current.id &&
            !isUnavailable(document, target.family, target.id))
          target,
    ];
    if (available.isEmpty) {
      clearSelection(document);
      return;
    }
    select(document, available.first.family, available.first.id);
    _extras.addAll(available.skip(1));
  }

  void select(
    EditableMapDocument document,
    MapSelectionFamily family,
    String id,
  ) {
    if (isUnavailable(document, family, id)) return;
    _extras.clear();
    _promote(
      document,
      MapSelectionTarget(mapId: document.current.id, family: family, id: id),
    );
  }

  void _promote(EditableMapDocument document, MapSelectionTarget target) {
    _target = target;
    document.selectedId = target.family == MapSelectionFamily.decor
        ? target.id
        : null;
  }

  void clearSelection(EditableMapDocument document) {
    _target = null;
    _extras.clear();
    pendingMove = null;
    document.selectedId = null;
  }
}
