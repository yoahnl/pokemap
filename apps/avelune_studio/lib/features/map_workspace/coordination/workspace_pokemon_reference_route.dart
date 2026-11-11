import '../application/editable_map_document.dart';
import '../application/map_workspace_controller.dart';

class WorkspacePokemonReferenceRoute {
  WorkspacePokemonReferenceRoute({
    required this.controller,
    required this.isActive,
    required this.leavePokemon,
    required this.sceneUnavailable,
    required this.showMap,
    required this.selectEntity,
    required this.opened,
  });

  final MapWorkspaceController controller;
  final bool Function() isActive;
  final Future<bool> Function() leavePokemon;
  final void Function() sceneUnavailable, showMap, opened;
  final void Function(EditableMapDocument, String) selectEntity;
  bool Function()? _unchanged;

  Future<void> open(String kind, String id, [String? detailId]) async {
    if (kind == 'scene') {
      sceneUnavailable();
      return;
    }
    if (!await leavePokemon() || !isActive()) return;
    if (kind != 'map') return;
    final entry = controller.project?.maps
        .where((value) => value.id == id)
        .firstOrNull;
    if (entry == null) return;
    showMap();
    await controller.activate(entry);
    final document = controller.active;
    if (!isActive() || document == null || document.current.id != id) return;
    if (detailId != null) selectEntity(document, detailId);
    final current = document.current;
    _unchanged = () =>
        identical(controller.active, document) &&
        !document.dirty &&
        identical(document.current, current);
    opened();
  }

  bool takeUnchanged() {
    final unchanged = _unchanged?.call() ?? false;
    _unchanged = null;
    return unchanged;
  }
}
