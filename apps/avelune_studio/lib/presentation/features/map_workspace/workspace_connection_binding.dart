part of 'map_workspace_screen.dart';

extension _WorkspaceConnectionBinding on _MapWorkspaceScreenState {
  Future<void> _linkMaps(
    MapConnectionDirection direction,
    String targetMapId,
    int offset,
  ) => _connections.link(direction, targetMapId, offset);

  Future<void> _unlinkMaps(MapConnectionDirection direction) =>
      _connections.unlink(direction);
}
