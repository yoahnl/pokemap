import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../rendering/contracts/map_workspace_visuals.dart';
import '../../resources/domain/resource_port.dart';
import '../application/map_workspace_controller.dart';
import 'workspace_workshop_routes.dart';

class WorkspaceVisualProjectionQueue {
  WorkspaceVisualProjectionQueue({
    required this.currentVisuals,
    required this.activeMap,
    required this.isActive,
    required this.prepared,
    required this.failed,
    required this.changed,
  });

  final MapWorkspaceVisuals? Function() currentVisuals;
  final MapData? Function() activeMap;
  final bool Function() isActive;
  final void Function(MapData?) prepared;
  final void Function(Object) failed;
  final void Function() changed;
  bool loading = false;
  ProjectManifest? definitions;
  MapData? preparedMap;
  int generation = 0;
  Future<void> queue = Future.value();

  void acknowledgeDefinitions(ProjectManifest? value) {
    definitions = value;
  }

  Future<void> acceptModelWorkshopReceipt(
    MapWorkspaceController controller,
    ResourceMutationReceipt receipt,
  ) async {
    if (controller.isDisposed || receipt.noChange) return;
    final previous = controller.visualProject;
    controller.acceptResources(
      receipt.before,
      receipt.manifest,
      changedModels: receipt.changedModels,
      notifyChange: false,
    );
    final publication = _publishModels(
      previous,
      controller.visualProject,
      receipt,
    );
    controller.notify();
    await publication;
  }

  Future<void> _publishModels(
    ProjectManifest? previous,
    ProjectManifest? updated,
    ResourceMutationReceipt receipt,
  ) async {
    final visuals = currentVisuals();
    if (visuals is! SpatialModelSourceWorkspaceVisuals ||
        updated == null ||
        !identical(definitions, previous) ||
        receipt.changedModels.isEmpty) {
      return;
    }
    definitions = updated;
    final ticket = generation;
    final queued = queue.then((_) async {
      if (!isActive() ||
          ticket != generation ||
          !identical(visuals, currentVisuals())) {
        return;
      }
      await (visuals as SpatialModelSourceWorkspaceVisuals).updateModelSources(
        updated,
        receipt.changedModels,
        receipt.modelSourceRevisions,
      );
    });
    queue = queued.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    await queued;
  }

  void synchronize(ProjectManifest? project, {bool suspended = false}) {
    if (!isActive()) return;
    final visuals = currentVisuals();
    if (visuals == null) return;
    if (!suspended && project != null && !identical(project, definitions)) {
      definitions = project;
      unawaited(refresh(project));
    }
    final map = activeMap();
    if (!loading && map != null && !identical(map, preparedMap)) {
      preparedMap = map;
      prepared(map);
      visuals.setActiveMap(map);
    }
  }

  void follow(
    MapWorkspaceController controller,
    WorkspaceWorkshopRoutes workshops,
  ) => synchronize(controller.visualProject, suspended: workshops.loading);

  Future<void> refresh(ProjectManifest definitions) async {
    final visuals = currentVisuals();
    if (visuals == null || visuals is! ResourceWorkspaceVisuals) return;
    final ticket = ++generation;
    loading = true;
    try {
      final queued = queue.then((_) async {
        if (!isActive() ||
            ticket != generation ||
            !identical(visuals, currentVisuals())) {
          return;
        }
        await (visuals as ResourceWorkspaceVisuals).updateCatalog(definitions);
      });
      queue = queued.then<void>((_) {}, onError: (Object _, StackTrace _) {});
      await queued;
      if (!isActive() ||
          ticket != generation ||
          !identical(visuals, currentVisuals())) {
        return;
      }
      final map = activeMap();
      preparedMap = map;
      prepared(map);
      if (map != null) visuals.setActiveMap(map);
    } catch (failure) {
      if (isActive() && ticket == generation) {
        failed(failure);
      }
    } finally {
      if (isActive() && ticket == generation) {
        loading = false;
        changed();
      }
    }
  }
}
