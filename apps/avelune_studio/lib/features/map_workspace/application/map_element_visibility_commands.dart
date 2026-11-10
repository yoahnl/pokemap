import 'editable_map_document.dart';
import 'map_element_catalog.dart';
import 'map_workspace_editing_state.dart';

class MapElementVisibilityCommands {
  MapElementVisibilityCommands(
    this.document,
    this.view, {
    required this.catalog,
    this.changed,
  });

  final EditableMapDocument document;
  final MapWorkspaceEditingState view;
  final MapElementCatalog Function() catalog;
  final void Function()? changed;

  void reconcileSelection() {
    final target = view.target;
    if (target == null) return;
    final entry = catalog().entries
        .where(
          (entry) =>
              entry.id == target.id &&
              switch (entry.kind) {
                'decor' || 'model' => target.family == MapSelectionFamily.decor,
                'entity' =>
                  target.family ==
                      (entry.isCharacter
                          ? MapSelectionFamily.character
                          : MapSelectionFamily.marker),
                'warp' => target.family == MapSelectionFamily.warp,
                'zone' => target.family == MapSelectionFamily.zone,
                'trigger' => target.family == MapSelectionFamily.trigger,
                _ => false,
              },
        )
        .firstOrNull;
    if (entry != null &&
        (document.isElementLocked(entry.kind, entry.id) ||
            document.isElementHidden(entry.kind, entry.id))) {
      view.clearSelection(document);
    }
  }

  void _changed() {
    reconcileSelection();
    changed?.call();
  }

  Future<void> setLocked(
    Iterable<MapElementListEntry> entries,
    bool locked,
  ) async {
    try {
      final editor = document.editor;
      if (editor == null || !editor.canWrite) return;
      if (!locked &&
          entries.any(
            (entry) =>
                document.isElementLocked(entry.kind, entry.id) &&
                !editor.current.isLocked(entry.kind, entry.id),
          )) {
        document.error = 'Des éléments sont verrouillés par leur calque. Déverrouillez ce calque dans Calques.';
        _changed();
        return;
      }
      final save = editor.setGroupLocked(
        entries.map((entry) => (entry.kind, entry.id)),
        locked,
      );
      _changed();
      await save;
    } on Object catch (error) {
      document.error = '$error';
      _changed();
    }
  }

  Future<void> setHidden(
    Iterable<MapElementListEntry> entries,
    bool hidden,
  ) async {
    try {
      final editor = document.editor;
      if (editor == null || !editor.canWrite) return;
      if (!hidden &&
          entries.any(
            (entry) => document.isElementHiddenInherited(entry.kind, entry.id),
          )) {
        document.error = 'Des éléments sont masqués par leur calque ou leur famille. Réaffichez le calque ou utilisez Tout afficher.';
        _changed();
        return;
      }
      final save = editor.setGroupHidden(
        entries.map((entry) => (entry.kind, entry.id)),
        hidden,
      );
      _changed();
      await save;
    } on Object catch (error) {
      document.error = '$error';
      _changed();
    }
  }
}
