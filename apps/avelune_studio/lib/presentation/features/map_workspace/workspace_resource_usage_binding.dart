part of 'map_workspace_screen.dart';

extension _WorkspaceResourceUsageBinding on _MapWorkspaceScreenState {
  List<String> _resourceUsageDraftOwners() => [
    if (_narrative?.dirty == true) 'Narration',
    if (_scenes?.dirty == true) 'Scènes',
    if (_events?.dirty == true) 'Événements',
    if (_dialogues?.dirty == true) 'Dialogues',
    if (_cinematics?.dirty == true) 'Cinématiques',
    if (_presentations?.dirty == true) 'Présentations',
    if (_pokemon?.hasPendingChanges == true) 'Pokémon',
  ];

  bool _canOpenResourceUsage(ResourceUsageEntry entry) {
    final project = _controller.project;
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

  Future<bool> _openResourceUsage(ResourceUsageEntry entry) async {
    if (!mounted || !_canOpenResourceUsage(entry)) return false;
    if (_actions.busy ||
        _resources?.busy == true ||
        _resources?.pendingReceipt != null ||
        _resources?.managementDialogActive == true) {
      return false;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    if (entry.mapId != null) {
      final target = _controller.project!.maps.firstWhere(
        (map) => map.id == entry.mapId,
      );
      final request = ++_navigationRequest;
      bool current() => mounted && request == _navigationRequest;
      await _controller.activate(target, isCurrent: current);
      if (!current() || _controller.active?.base.mapId != target.id) {
        return false;
      }
      final document = _controller.active!;
      final instanceId = entry.entityId;
      if (instanceId != null) {
        final family =
            document.current.placedElements.any((item) => item.id == instanceId)
            ? MapSelectionFamily.decor
            : document.current.entities.any((item) => item.id == instanceId)
            ? MapSelectionFamily.character
            : null;
        if (family != null) _view?.select(document, family, instanceId);
      }
      _show(WorkspaceSpace.map);
      _toolChanged();
      return true;
    }
    if (entry.resourceId != null) {
      final item = resourceCatalog(_controller.project!).firstWhere(
        (item) =>
            item.kind.name == entry.resourceFamily &&
            item.id == entry.resourceId,
      );
      _resources?.showLibrary(item);
      _show(WorkspaceSpace.resources);
      return true;
    }
    _resources?.openCharacters(entry.ownerId);
    _show(WorkspaceSpace.resources);
    return true;
  }
}
