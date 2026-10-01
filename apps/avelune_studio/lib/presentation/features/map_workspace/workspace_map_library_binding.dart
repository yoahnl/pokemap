part of 'map_workspace_screen.dart';

extension _WorkspaceMapLibrary on _MapWorkspaceScreenState {
  MapWorkspaceViewState? get _view {
    final id = _controller.active?.base.mapId;
    return id == null
        ? null
        : _views.putIfAbsent(id, MapWorkspaceViewState.new);
  }

  void _configureCatalogueGuard() {
    _controller.catalogDependencyFailure = (_, _) =>
        _actions.busy || _actions.hasCatalogDependencyDraft
        ? 'Un éditeur de ressources, d’histoire ou de monde a un travail en cours. '
              'Résolvez-le dans son propriétaire avant cette opération ; aucun brouillon n’a été enregistré.'
        : null;
  }

  void _reconcileCatalogueView() {
    final ids = _controller.project?.maps.map((map) => map.id).toSet();
    if (ids == null) return;
    for (final id in _views.keys.where((id) => !ids.contains(id)).toList()) {
      _views.remove(id)?.dispose();
    }
    final current = _controller.active?.current;
    if (current != null &&
        _preparedMap?.id == current.id &&
        _preparedMap?.size != current.size) {
      _view?.positioned = false;
      _view?.borderDraft = null;
      _view?.pendingMove = null;
      _gestureGeneration++;
    }
  }

  Future<String?> _organizeMaps({
    List<ProjectMapGroup>? groups,
    required List<Map<String, Object?>> assignments,
  }) async {
    final result = await _controller.mutateCatalog('map.library.reorganize', {
      if (groups != null)
        'groups': groups.map((group) => group.toJson()).toList(),
      'assignments': assignments,
    });
    if (mounted) _changed();
    return result.integrated
        ? null
        : result.published
        ? 'L’organisation est enregistrée sur disque. ${result.error ?? ''} Relisez le catalogue avant une autre opération.'
        : result.error ?? 'Organisation impossible.';
  }

  Future<void> _createMap([String? groupId]) =>
      createWorkspaceMap(context, _controller, groupId: groupId);
}
