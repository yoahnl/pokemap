part of 'map_workspace_controller.dart';

extension MapWorkspaceModelVisibility on MapWorkspaceController {
  Future<bool> configureModelVisibility(
    EditableMapDocument document,
    String instanceId,
    NarrativeEventConditionExpression? value,
  ) async {
    final source = port;
    final manifest = project;
    if (_disposed ||
        source is! SpatialModelVisibilityPort ||
        manifest == null ||
        document.saving ||
        catalogLocks(document.base.mapId)) {
      return false;
    }
    if (document.isElementUnavailable('model', instanceId)) return false;
    final before = document.current;
    final rollback = document.preserveDraft();
    try {
      final persisted = _previewModelVisibility(
        document.saved,
        instanceId,
        value,
      );
      final next = _previewModelVisibility(before, instanceId, value);
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
          'Enregistrez les modifications de ce décor avant de changer sa visibilité. Les autres brouillons sont conservés.',
        );
      }
      if (next == before) return true;
      document.commitInstanceVisibility(next);
      final token = document.undoToken!;
      document.saving = document.modelVisibilitySaving = true;
      notify();
      final receipt = await (source as SpatialModelVisibilityPort)
          .configureSpatialModelVisibility(
            session,
            document.base,
            instanceId,
            value,
          );
      if (_disposed) return false;
      if (receipt.document.map != persisted) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'La visibilité enregistrée ne correspond pas à l’aperçu. Rouvrez la carte avant de poursuivre.',
        );
      }
      document.acceptSave(persisted, receipt.document.revision);
      final receipts = _modelVisibilityReceipts.putIfAbsent(
        document.base.mapId,
        () => {},
      );
      final retained = document.historyTokens;
      receipts.removeWhere((key, _) => !retained.contains(key));
      receipts[token] = receipt;

      return true;
    } on Object catch (failure) {
      rollback();
      document.error = _message(failure);
      return false;
    } finally {
      document.saving = document.modelVisibilitySaving = false;
      notify();
    }
  }

  MapData _previewModelVisibility(
    MapData map,
    String instanceId,
    NarrativeEventConditionExpression? condition,
  ) {
    var result = map;
    for (final layer in map.layers.whereType<EnvironmentLayer>()) {
      for (final area in layer.content.areas) {
        if (area.generatedPlacementIds.contains(instanceId) &&
            !area.manualPlacementIds.contains(instanceId)) {
          result = const EnvironmentEditing().promoteSpatialPlacement(
            result,
            layerId: layer.id,
            areaId: area.id,
            placementId: instanceId,
          );
        }
      }
    }
    return result.copyWith(
      spatialScene: map.spatialScene!.copyWith(
        instances: [
          for (final instance in map.spatialScene!.instances)
            if (instance.id == instanceId)
              instance.copyWith(
                visibilityCondition: condition,
                clearVisibilityCondition: condition == null,
              )
            else
              instance,
        ],
      ),
    );
  }

  Future<void> _restoreModelVisibility(
    EditableMapDocument document,
    SpatialModelVisibilityReceipt receipt, {
    required bool redo,
  }) async {
    final source = port;
    if (source is! SpatialModelVisibilityPort || document.saving) return;
    final token = redo ? document.redoToken : document.undoToken;
    final rollback = document.preserveDraft();
    try {
      document.restoreInstanceVisibility(redo: redo);
      document.saving = document.modelVisibilitySaving = true;
      notify();
      final restored = await (source as SpatialModelVisibilityPort)
          .undoSpatialModelVisibility(
            session,
            document.base,
            receipt,
            redo: redo,
          );
      if (_disposed) return;
      document.acceptSave(restored.document.map, restored.document.revision);
      final receipts = _modelVisibilityReceipts[document.base.mapId]!;
      receipts.remove(token);
      receipts[(redo ? document.undoToken : document.redoToken)!] = restored;
    } on Object catch (failure) {
      rollback();
      document.error = _message(failure);
    } finally {
      document.saving = document.modelVisibilitySaving = false;
      notify();
    }
  }
}
