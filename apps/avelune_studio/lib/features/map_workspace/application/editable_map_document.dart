import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

class EditableMapDocument {
  EditableMapDocument(this.base) : current = base.map, saved = base.map;

  MapWorkspaceDocument base;
  MapData current;
  MapData saved;
  String? selectedId;
  GridPos? stackPosition;
  bool saving = false;
  String? error;
  final _history = const MapHistoryCoordinator();
  List<MapHistoryEntry> _undo = [];
  List<MapHistoryEntry> _redo = [];

  bool get dirty => current != saved;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get undoCount => _undo.length;
  MapPlacedElement? get selected => current.placedElements
      .where((element) => element.id == selectedId)
      .firstOrNull;

  void commit(MapData next) {
    if (next == current) return;
    final result = _history.recordMutation(
      before: current,
      after: next,
      selectionBefore: const MapHistorySelection(),
      undoStack: _undo,
      redoStack: _redo,
    );
    _undo = result.undoStack;
    _redo = result.redoStack;
    current = next;
    error = null;
    _repairSelection();
  }

  void restore({required bool redo}) {
    final result = redo
        ? _history.redo(currentMap: current, undoStack: _undo, redoStack: _redo)
        : _history.undo(
            currentMap: current,
            undoStack: _undo,
            redoStack: _redo,
          );
    if (result == null) return;
    current = result.restoredSnapshot.map;
    _undo = result.undoStack;
    _redo = result.redoStack;
    error = null;
    _repairSelection();
  }

  void acceptSave(MapData snapshot, String revision) {
    saved = snapshot;
    base = MapWorkspaceDocument(
      map: snapshot,
      revision: revision,
      mapId: base.mapId,
    );
  }

  void _repairSelection() {
    if (selected == null) selectedId = null;
  }
}
