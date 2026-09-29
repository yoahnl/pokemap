part of 'map_workspace_screen.dart';

extension _WorkspaceConnectionBinding on _MapWorkspaceScreenState {
  Future<void> _linkMaps(
    MapConnectionDirection direction,
    String targetMapId,
    int offset,
  ) => _mutateConnection(
    direction: direction,
    targetMapId: targetMapId,
    offset: offset,
    remove: false,
  );

  Future<void> _unlinkMaps(MapConnectionDirection direction) {
    final connection = _controller.active?.current.connections
        .where((value) => value.direction == direction)
        .firstOrNull;
    if (connection == null) return Future.value();
    return _mutateConnection(
      direction: direction,
      targetMapId: connection.targetMapId,
      offset: connection.offset,
      remove: true,
    );
  }

  Future<void> _mutateConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    required bool remove,
  }) async {
    final port = widget.mapConnectionPort;
    final document = _controller.active;
    final targetDocument = _controller.documents[targetMapId];
    if (port == null || document == null || _connectionBusy) return;
    if (document.dirty || targetDocument?.dirty == true) {
      _connectionError =
          'Enregistrez les brouillons des deux cartes avant de modifier leur liaison.';
      _changed();
      return;
    }
    final controller = _controller;
    final source = document.current;
    _connectionBusy = true;
    _connectionError = null;
    _changed();
    try {
      if (remove) {
        await port.unlink(
          session: controller.session,
          source: source,
          direction: direction,
          expectedTarget: targetDocument?.current,
        );
      } else {
        await port.link(
          session: controller.session,
          source: source,
          direction: direction,
          targetMapId: targetMapId,
          offset: offset,
          expectedTarget: targetDocument?.current,
        );
      }
      if (!mounted || controller.isDisposed) return;
      await controller.refreshSavedMaps({source.id, targetMapId});
    } on Object catch (failure) {
      if (mounted && !controller.isDisposed) {
        _connectionError = failure.toString();
      }
    } finally {
      if (mounted && !controller.isDisposed) {
        _connectionBusy = false;
        _changed();
      }
    }
  }
}
