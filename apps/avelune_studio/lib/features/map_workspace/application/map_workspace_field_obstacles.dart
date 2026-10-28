part of 'map_workspace_controller.dart';

extension MapWorkspaceFieldObstacles on MapWorkspaceController {
  Future<bool> configureFieldObstacle(
    EditableMapDocument document,
    String instanceId,
    MapEntityFieldObstacleData? value,
  ) async {
    final source = port;
    final manifest = project;
    if (_disposed ||
        source is! SpatialFieldObstaclePort ||
        manifest == null ||
        document.saving ||
        catalogLocks(document.base.mapId)) {
      return false;
    }
    if (document.isElementUnavailable('model', instanceId)) return false;
    final before = document.current;
    final rollback = document.preserveDraft();
    try {
      const actions = SpatialMapActions();
      final persisted = actions.configureFieldObstacle(
        document.saved,
        project: manifest,
        instanceId: instanceId,
        fieldObstacle: value,
      );
      final next = actions.configureFieldObstacle(
        before,
        project: manifest,
        instanceId: instanceId,
        fieldObstacle: value,
      );
      final savedInstance = document.saved.spatialScene!.instances
          .where((item) => item.id == instanceId)
          .firstOrNull;
      final currentInstance = before.spatialScene!.instances
          .where((item) => item.id == instanceId)
          .firstOrNull;
      final savedEntity = document.saved.entities
          .where((item) => item.id == savedInstance?.entityId)
          .firstOrNull;
      final currentEntity = before.entities
          .where((item) => item.id == currentInstance?.entityId)
          .firstOrNull;
      if (savedInstance != currentInstance ||
          savedEntity != currentEntity ||
          persisted.spatialScene!.instances
                  .singleWhere((item) => item.id == instanceId)
                  .entityId !=
              next.spatialScene!.instances
                  .singleWhere((item) => item.id == instanceId)
                  .entityId) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Enregistrez les modifications de ce décor avant de changer son obstacle. Les autres brouillons sont conservés.',
        );
      }
      if (next == before) return true;
      document.commit(next);
      final token = document.undoToken!;
      document.saving = document.spatialFieldObstacleSaving = true;
      notify();
      final receipt = await (source as SpatialFieldObstaclePort)
          .configureSpatialFieldObstacle(
            session,
            document.base,
            instanceId,
            value,
          );
      if (_disposed) return false;
      if (receipt.document.map != persisted) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'L’obstacle enregistré ne correspond pas à l’aperçu. Rouvrez la carte avant de poursuivre.',
        );
      }
      document.acceptSave(persisted, receipt.document.revision);
      final receipts = _fieldObstacleReceipts.putIfAbsent(
        document.base.mapId,
        () => {},
      );
      final retained = document.historyTokens;
      receipts.removeWhere((key, _) => !retained.contains(key));
      receipts[token] = receipt;
      _previews.remove(document.base.mapId);
      return true;
    } on Object catch (failure) {
      rollback();
      document.error = _message(failure);
      return false;
    } finally {
      document.saving = document.spatialFieldObstacleSaving = false;
      notify();
    }
  }

  Future<void> _restoreFieldObstacle(
    EditableMapDocument document,
    SpatialFieldObstacleReceipt receipt, {
    required bool redo,
  }) async {
    final source = port;
    if (source is! SpatialFieldObstaclePort || document.saving) return;
    final token = redo ? document.redoToken : document.undoToken;
    final rollback = document.preserveDraft();
    try {
      document.restore(redo: redo);
      document.saving = document.spatialFieldObstacleSaving = true;
      notify();
      final restored = await (source as SpatialFieldObstaclePort)
          .undoSpatialFieldObstacle(
            session,
            document.base,
            receipt,
            redo: redo,
          );
      if (_disposed) return;
      document.acceptSave(restored.document.map, restored.document.revision);
      final receipts = _fieldObstacleReceipts[document.base.mapId]!;
      receipts.remove(token);
      receipts[(redo ? document.undoToken : document.redoToken)!] = restored;
      _previews.remove(document.base.mapId);
    } on Object catch (failure) {
      rollback();
      document.error = _message(failure);
    } finally {
      document.saving = document.spatialFieldObstacleSaving = false;
      notify();
    }
  }
}
