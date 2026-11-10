import 'package:map_core/map_core_domain.dart' show GridPos;

import 'editable_map_document.dart';
import 'map_element_catalog.dart';
import 'map_workspace_editing_state.dart';

class MapElementSelectionCommands {
  const MapElementSelectionCommands(this.document, this.view, {this.centerOn});
  final EditableMapDocument document;
  final MapWorkspaceEditingState view;
  final void Function(GridPos)? centerOn;

  bool select(MapElementListEntry entry, {bool additive = false}) {
    if (document.isElementLocked(entry.kind, entry.id) ||
        document.isElementHidden(entry.kind, entry.id)) {
      return false;
    }
    final family = mapElementSelectionFamily(entry);
    if (family == null) return false;
    view.tool = StudioMapTool.select;
    if (family == MapSelectionFamily.decor && additive) {
      view.toggleDecorInSelection(document, entry.id);
    } else {
      view.select(document, family, entry.id);
      final cell = mapElementCell(document.current, entry.kind, entry.id);
      if (cell != null) centerOn?.call(cell);
    }
    return true;
  }

  bool isSelected(MapElementListEntry entry) {
    if ((entry.kind == 'decor' || entry.kind == 'model') &&
        view.selectedDecorIds(document.current.id).contains(entry.id)) {
      return true;
    }
    final target = view.target;
    return target != null &&
        target.id == entry.id &&
        target.family == mapElementSelectionFamily(entry);
  }
}

typedef MapElementReorder = Future<bool> Function(
  String kind,
  List<String> frontFirstIds,
  String? layerId,
);

class MapElementReorderSession {
  bool busy = false;

  Future<bool> reorder({
    required EditableMapDocument document,
    required List<MapElementListEntry> entries,
    required int from,
    required int to,
    required MapElementReorder? apply,
    MapContentFilter filter = MapContentFilter.all,
    String query = '',
  }) async {
    if (apply == null ||
        document.editor?.canWrite != true ||
        busy ||
        filter != MapContentFilter.all ||
        query.isNotEmpty) {
      return false;
    }
    final source = entries[from];
    if (document.isElementLocked(source.kind, source.id) || to == from) {
      return false;
    }
    final reordered = entries.toList();
    reordered.insert(to, reordered.removeAt(from));
    busy = true;
    try {
      return await apply(
        source.kind == 'layer' ? 'layers' : 'decor',
        reordered.map((entry) => entry.id).toList(),
        source.layerId,
      );
    } finally {
      busy = false;
    }
  }
}

MapSelectionFamily? mapElementSelectionFamily(MapElementListEntry entry) =>
    switch (entry.kind) {
      'decor' || 'model' => MapSelectionFamily.decor,
      'entity' =>
        entry.isCharacter
            ? MapSelectionFamily.character
            : MapSelectionFamily.marker,
      'warp' => MapSelectionFamily.warp,
      'zone' => MapSelectionFamily.zone,
      'trigger' => MapSelectionFamily.trigger,
      _ => null,
    };
