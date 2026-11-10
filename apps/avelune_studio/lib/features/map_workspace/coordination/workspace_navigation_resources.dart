part of 'workspace_navigation_session.dart';

extension WorkspaceResourceNavigation on WorkspaceNavigationSession {
  bool canOpenResourceUsage(ResourceUsageEntry entry) {
    final project = controller.project;
    if (project == null) return false;
    if (entry.mapId != null) {
      return project.maps.any((map) => map.id == entry.mapId);
    }
    if (entry.resourceId != null) {
      return resourceCatalog(project).any(
        (item) =>
            item.kind.name == entry.resourceFamily &&
            item.id == entry.resourceId,
      );
    }
    return entry.ownerKind == 'character' &&
        project.characters.any((character) => character.id == entry.ownerId);
  }

  Future<bool> openResourceUsage(ResourceUsageEntry entry) async {
    if (!isActive() || !canOpenResourceUsage(entry)) return false;
    final owner = resources?.call();
    if (resourceUsageBusy?.call() == true ||
        owner?.busy == true ||
        owner?.pendingReceipt != null ||
        owner?.managementDialogActive == true) {
      return false;
    }
    flushResourceFocus?.call();
    if (entry.mapId != null) {
      final target = controller.project!.maps.firstWhere(
        (map) => map.id == entry.mapId,
      );
      final ticket = nextNavigationRequest?.call() ?? ++_request;
      bool current() => isActive() && ticket == request;
      await controller.activate(target, isCurrent: current);
      if (!current() || controller.active?.base.mapId != target.id) {
        return false;
      }
      final document = controller.active!;
      final instanceId = entry.entityId;
      if (instanceId?.startsWith('exterior:') == true) {
        document.exteriorDecoration?.setEditingExterior(true);
      }
      if (instanceId != null) {
        final family =
            document.current.placedElements.any((item) => item.id == instanceId)
            ? MapSelectionFamily.decor
            : document.current.entities.any((item) => item.id == instanceId)
            ? MapSelectionFamily.character
            : null;
        if (family != null) mapView?.call()?.select(document, family, instanceId);
      }
      show(WorkspaceSpace.map);
      toolChanged?.call();
      return true;
    }
    if (entry.resourceId != null) {
      final item = resourceCatalog(controller.project!).firstWhere(
        (item) =>
            item.kind.name == entry.resourceFamily &&
            item.id == entry.resourceId,
      );
      resources?.call()?.showLibrary(item);
      show(WorkspaceSpace.resources);
      return true;
    }
    resources?.call()?.openCharacters(entry.ownerId);
    show(WorkspaceSpace.resources);
    return true;
  }

  Future<bool> openResourceDiagnosticOwner(
    String kind,
    String id, {
    required Future<void> Function(void Function()) openWorkshop,
  }) async {
    final project = controller.project;
    if (!isActive() || project == null) return false;
    if (kind == 'character') {
      if (!project.characters.any((character) => character.id == id)) {
        return false;
      }
      await openWorkshop(() => resources?.call()?.openCharacters(id));
      return true;
    }
    final item = resourceCatalog(project)
        .where((item) => item.canonicalKind == kind && item.id == id)
        .firstOrNull;
    if (item == null) return false;
    await openWorkshop(() => resources?.call()?.showLibrary(item));
    return true;
  }
}
