part of 'map_workspace_screen.dart';

extension _WorkspaceWorldBinding on _MapWorkspaceScreenState {
  void _initializeWorld() {
    final narrative = _narrative, port = widget.worldPort;
    if (narrative == null || port == null) return;
    // The maps stay unread until the author actually opens the page: a
    // workspace that never visits it must not pay for them.
    _world = WorldWorkspaceController(narrative, port, changed: _changed);
  }

  void _openWorld() {
    _worldOrigin = WorkspaceReturn.story;
    final owner = _world;
    if (owner != null && !owner.initialized && !owner.loading) {
      unawaited(owner.initialize());
    }
    _show(WorkspaceSpace.world);
  }

  Future<void> _returnFromWorld() async {
    final origin = _worldOrigin;
    final sceneId = origin.documentId;
    if (origin.space == WorkspaceSpace.scene && sceneId != null) {
      if (_scenes?.open(sceneId) != true) {
        _worldOrigin = WorkspaceReturn.story;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cette scène n’est plus disponible.')),
        );
        _show(WorkspaceSpace.story);
        return;
      }
    }
    _show(
      origin.space == WorkspaceSpace.world
          ? WorkspaceSpace.story
          : origin.space,
    );
  }

  Widget _worldPage() {
    final owner = _world;
    if (owner == null) {
      return const Center(
        child: Text('Les états et règles sont indisponibles sur cet hôte.'),
      );
    }
    return WorldWorkspacePage(
      controller: owner,
      view: _worldView,
      onBack: () => unawaited(_returnFromWorld()),
      backLabel: _worldOrigin.space == WorkspaceSpace.scene
          ? 'la scène'
          : 'Histoire',
      onOpenScene: (sceneId) async {
        if (_scenes?.open(sceneId) != true) return;
        _sceneOrigin = WorkspaceReturn(WorkspaceSpace.world);
        _show(WorkspaceSpace.scene);
      },
    );
  }
}
