import 'package:map_core/map_core_domain.dart';

import '../application/map_workspace_controller.dart';
import 'map_editing_viewport_session.dart';

class WorkspaceMapCatalogBindings {
  WorkspaceMapCatalogBindings({
    required this.controller,
    required this.views,
    required this.activeView,
    required this.preparedMap,
    required this.reconcileBrushes,
    required this.isBusy,
    required this.hasDependencyDraft,
    required this.boundsChanged,
  });

  final MapWorkspaceController controller;
  final Map<String, MapEditingViewportSession> Function() views;
  final MapEditingViewportSession? Function() activeView;
  final MapData? Function() preparedMap;
  final void Function() reconcileBrushes;
  final bool Function() isBusy;
  final bool Function() hasDependencyDraft;
  final void Function() boundsChanged;
  late final String? Function(String, String) _guard = _dependencyFailure;

  String? _dependencyFailure(String action, String target) =>
      isBusy() || hasDependencyDraft()
      ? 'Un éditeur de ressources, d’histoire ou de monde a un travail en cours. '
            'Résolvez-le dans son propriétaire avant cette opération ; aucun brouillon n’a été enregistré.'
      : null;

  void bind() => controller.catalogDependencyFailure = _guard;

  void reconcile() {
    reconcileBrushes();
    final project = controller.project;
    if (project == null) return;
    final sessions = views();
    final ids = project.maps.map((map) => map.id).toSet();
    for (final id in sessions.keys.where((id) => !ids.contains(id)).toList()) {
      sessions.remove(id)?.dispose();
    }
    for (final entry in sessions.entries) {
      if (!controller.hasCompleteProject &&
          entry.key != controller.active?.base.mapId) {
        continue;
      }
      entry.value.reconcileResources(project, mapId: entry.key);
    }
    final current = controller.active?.current;
    final prepared = preparedMap();
    if (current != null &&
        prepared?.id == current.id &&
        prepared?.size != current.size) {
      final view = activeView();
      if (view != null) {
        view.positioned = false;
        view.borderDraft = null;
        view.pendingMove = null;
      }
      boundsChanged();
    }
  }

  void dispose() {
    if (identical(controller.catalogDependencyFailure, _guard)) {
      controller.catalogDependencyFailure = null;
    }
  }
}
