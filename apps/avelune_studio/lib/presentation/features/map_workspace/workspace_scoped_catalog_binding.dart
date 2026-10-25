part of 'map_workspace_screen.dart';

extension _WorkspaceScopedCatalog on _MapWorkspaceScreenState {
  Future<int?> _prepareWorkshopRoute(MapWorkspaceWorkshop workshop) async {
    final request = ++_navigationRequest;
    _openingWorkshop = true;
    _resourceError = null;
    _changed();
    try {
      await _controller.ensureWorkshop(workshop);
      return mounted && request == _navigationRequest ? request : null;
    } catch (failure) {
      if (mounted && request == _navigationRequest) {
        _resourceError = 'Cet atelier ne peut pas être chargé : $failure';
      }
      return null;
    } finally {
      if (mounted && request == _navigationRequest) {
        _openingWorkshop = false;
        _changed();
      }
    }
  }

  Future<void> _refreshScopedVisuals(ProjectManifest definitions) async {
    final visuals = _visuals;
    if (visuals == null || visuals is! ResourceWorkspaceVisuals) return;
    final generation = ++_projectionVisualGeneration;
    _projectionVisualsLoading = true;
    try {
      final queued = _projectionVisualQueue.then((_) async {
        if (!mounted ||
            generation != _projectionVisualGeneration ||
            !identical(visuals, _visuals)) {
          return;
        }
        await (visuals as ResourceWorkspaceVisuals).updateCatalog(definitions);
      });
      _projectionVisualQueue = queued.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      );
      await queued;
      if (!mounted ||
          generation != _projectionVisualGeneration ||
          !identical(visuals, _visuals)) {
        return;
      }
      _preparedMap = _controller.active?.current;
      if (_preparedMap != null) visuals.setActiveMap(_preparedMap!);
    } catch (failure) {
      if (mounted && generation == _projectionVisualGeneration) {
        _resourceError =
            'Les ressources de cette carte ne peuvent pas être chargées : $failure';
      }
    } finally {
      if (mounted && generation == _projectionVisualGeneration) {
        _projectionVisualsLoading = false;
        _changed();
      }
    }
  }

  Future<void> _openWorkshop(
    WorkspaceSpace destination,
    MapWorkspaceWorkshop workshop, {
    VoidCallback? prepare,
    Future<void> Function()? loadDependencies,
  }) async {
    final request = ++_navigationRequest;
    _openingWorkshop = true;
    _resourceError = null;
    _changed();
    try {
      await _controller.ensureWorkshop(workshop);
      if (!mounted || request != _navigationRequest) return;
      await loadDependencies?.call();
      if (!mounted || request != _navigationRequest) return;
      prepare?.call();
      _openingWorkshop = false;
      _show(destination, libraryGuarded: true);
    } catch (failure) {
      if (mounted && request == _navigationRequest) {
        _resourceError = 'Cet atelier ne peut pas être chargé : $failure';
      }
    } finally {
      if (mounted && request == _navigationRequest) {
        _openingWorkshop = false;
        _changed();
      }
    }
  }
}
