part of 'map_workspace_screen.dart';

extension _WorkspaceWorldBinding on _MapWorkspaceScreenState {
  void _openWorld() {
    _worldOrigin = WorkspaceReturn.story;
    final owner = _world;
    if (owner != null && !owner.initialized && !owner.loading) {
      unawaited(owner.initialize());
    }
    _show(WorkspaceSpace.world);
  }

  Widget _worldPage() {
    return const Center(
      child: Text('Interface Monde retirée — reconstruction en attente.'),
    );
  }
}
