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
  PixelPosition? stackPixelPosition;
  bool saving = false;
  String? error;
  final _history = const MapHistoryCoordinator();
  List<MapHistoryEntry> _undo = [];
  List<MapHistoryEntry> _redo = [];
  String? _catalogName;

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

  void restore({required bool redo, bool Function(MapData)? canRestore}) {
    final result = redo
        ? _history.redo(currentMap: current, undoStack: _undo, redoStack: _redo)
        : _history.undo(
            currentMap: current,
            undoStack: _undo,
            redoStack: _redo,
          );
    if (result == null) return;
    final catalogName = _catalogName;
    final restored = catalogName == null
        ? result.restoredSnapshot.map
        : result.restoredSnapshot.map.copyWith(name: catalogName);
    if (canRestore != null && !canRestore(restored)) return;
    current = restored;
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

  void acceptCatalogMetadata(MapWorkspaceDocument updated) {
    if (updated.map.copyWith(name: saved.name) != saved) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La carte publiée contient d’autres modifications. Votre historique reste conservé.',
      );
    }
    _catalogName = updated.map.name;
    current = current.copyWith(name: updated.map.name);
    saved = updated.map;
    base = updated;
  }

  void acceptCatalogContent(MapWorkspaceDocument updated) {
    if (dirty || saving) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La carte publiée ne peut pas remplacer une saisie en cours. Votre brouillon reste conservé.',
      );
    }
    current = updated.map;
    saved = updated.map;
    base = updated;
    _catalogName = updated.map.name;
    _undo = [];
    _redo = [];
    stackPosition = null;
    stackPixelPosition = null;
    _repairSelection();
  }

  void acceptResourceContent(MapWorkspaceDocument updated) {
    if (dirty || saving) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Enregistrez ou annulez cette carte avant de modifier ses références.',
      );
    }
    if (updated.map.copyWith(entities: current.entities) != current) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La publication contient d’autres changements que les références de personnages.',
      );
    }
    current = current.copyWith(entities: updated.map.entities);
    saved = current;
    base = updated;
    _catalogName = updated.map.name;
    _repairSelection();
  }

  void _repairSelection() {
    if (selected == null &&
        !(current.spatialScene?.instances.any(
              (item) => item.id == selectedId,
            ) ??
            false)) {
      selectedId = null;
    }
  }
}
