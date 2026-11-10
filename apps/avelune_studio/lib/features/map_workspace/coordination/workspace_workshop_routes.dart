import '../application/map_workspace_controller.dart';
import '../domain/map_workspace_workshop.dart';

class WorkspaceWorkshopRoutes {
  WorkspaceWorkshopRoutes({
    required this.controller,
    required this.isActive,
    required this.failed,
    required this.changed,
  });

  final MapWorkspaceController controller;
  final bool Function() isActive;
  final void Function(Object?) failed;
  final void Function() changed;
  bool loading = false;
  int request = 0;

  Future<int?> prepare(MapWorkspaceWorkshop workshop) async {
    final ticket = ++request;
    loading = true;
    failed(null);
    changed();
    try {
      await controller.ensureWorkshop(workshop);
      return isActive() && ticket == request ? ticket : null;
    } catch (failure) {
      if (isActive() && ticket == request) {
        failed(failure);
      }
      return null;
    } finally {
      if (isActive() && ticket == request) {
        loading = false;
        changed();
      }
    }
  }

  Future<void> open(
    MapWorkspaceWorkshop workshop, {
    required void Function() opened,
    void Function()? prepare,
    Future<void> Function()? loadDependencies,
  }) async {
    final ticket = ++request;
    loading = true;
    failed(null);
    changed();
    try {
      await controller.ensureWorkshop(workshop);
      if (!isActive() || ticket != request) return;
      await loadDependencies?.call();
      if (!isActive() || ticket != request) return;
      prepare?.call();
      loading = false;
      opened();
    } catch (failure) {
      if (isActive() && ticket == request) {
        failed(failure);
      }
    } finally {
      if (isActive() && ticket == request) {
        loading = false;
        changed();
      }
    }
  }
}
