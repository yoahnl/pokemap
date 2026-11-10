part of 'map_workspace_screen.dart';

extension _WorkspaceMapLibrary on _MapWorkspaceScreenState {
  MapWorkspaceViewState? get _view {
    final id = _controller.active?.base.mapId;
    return id == null
        ? null
        : _views.putIfAbsent(id, () => MapWorkspaceViewState(layout: _layout));
  }

  void _configureCatalogueGuard() => _mapCatalogBindings.bind();

  void _reconcileCatalogueView() => _mapCatalogBindings.reconcile();

  Future<String?> _organizeMaps({
    List<ProjectMapGroup>? groups,
    required List<Map<String, Object?>> assignments,
  }) async {
    final problem = await organizeWorkspaceMaps(
      _controller,
      groups: groups,
      assignments: assignments,
    );
    if (mounted) _changed();
    return problem;
  }

  Future<void> _createMap([String? groupId]) =>
      createWorkspaceMap(context, _controller, groupId: groupId);
}
