part of 'map_workspace_screen.dart';

extension _WorkspaceScopedCatalog on _MapWorkspaceScreenState {
  Future<int?> _prepareWorkshopRoute(MapWorkspaceWorkshop workshop) =>
      _workshops.prepare(workshop);

  Future<void> _refreshScopedVisuals(ProjectManifest definitions) =>
      _visualProjection.refresh(definitions);

  Future<void> _openWorkshop(
    WorkspaceSpace destination,
    MapWorkspaceWorkshop workshop, {
    VoidCallback? prepare,
    Future<void> Function()? loadDependencies,
  }) => _workshops.open(
    workshop,
    prepare: prepare,
    loadDependencies: loadDependencies,
    opened: () => _show(destination, libraryGuarded: true),
  );
}
