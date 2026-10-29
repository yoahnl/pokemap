part of 'map_workspace_controller.dart';

extension MapWorkspaceFieldTraversals on MapWorkspaceController {
  Future<bool> configureFieldTraversal(
    EditableMapDocument document,
    MapData next,
  ) async {
    final source = port;
    if (_disposed ||
        source is! FieldTraversalZonePort ||
        document.saving ||
        catalogLocks(document.base.mapId)) {
      return false;
    }
    final before = document.current;
    if (next.copyWith(gameplayZones: before.gameplayZones) != before) {
      return false;
    }
    final changed = <String>{
      for (final zone in [...before.gameplayZones, ...next.gameplayZones])
        if (findGameplayZoneById(before, zone.id) !=
            findGameplayZoneById(next, zone.id))
          zone.id,
    };
    if (changed.length != 1) return false;
    final zoneId = changed.single;
    if (document.isElementUnavailable('zone', zoneId)) return false;
    final previousZone = findGameplayZoneById(before, zoneId);
    final nextZone = findGameplayZoneById(next, zoneId);
    final action = previousZone == null
        ? 'gameplay_zone.create'
        : nextZone == null
        ? 'gameplay_zone.delete'
        : 'gameplay_zone.update';
    final parameters = <String, Object?>{
      'mapId': before.id,
      if (previousZone != null) 'zoneId': zoneId,
      if (nextZone != null) 'zone': nextZone.toJson(),
    };
    if (!TriggerZoneActions.isFieldTraversalMutation(
      before,
      action,
      parameters,
    )) {
      return false;
    }
    final rollback = document.preserveDraft();
    try {
      if (findGameplayZoneById(document.saved, zoneId) != previousZone) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Enregistrez les modifications de ce passage avant de changer son parcours. Les autres brouillons restent conservés.',
        );
      }
      final persisted = document.saved.copyWith(
        gameplayZones: [
          for (final zone in document.saved.gameplayZones)
            if (zone.id != zoneId) zone else ?nextZone,
          if (previousZone == null && nextZone != null) nextZone,
        ],
      );
      document.commit(next);
      final token = document.undoToken!;
      document.saving = document.fieldTraversalSaving = true;
      notify();
      final receipt = await (source as FieldTraversalZonePort)
          .publishFieldTraversalZone(
            session,
            document.base,
            action,
            parameters,
          );
      if (_disposed) return false;
      if (receipt.document.map != persisted) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le passage enregistré ne correspond pas à l’aperçu. Rouvrez la carte avant de poursuivre.',
        );
      }
      document.acceptSave(persisted, receipt.document.revision);
      final receipts = _fieldTraversalReceipts.putIfAbsent(
        document.base.mapId,
        () => {},
      );
      receipts.removeWhere(
        (token, _) => !document.historyTokens.contains(token),
      );
      receipts[token] = receipt;
      _previews.remove(document.base.mapId);
      return true;
    } on Object catch (failure) {
      rollback();
      document.error = _message(failure);
      return false;
    } finally {
      document.saving = document.fieldTraversalSaving = false;
      notify();
    }
  }

  Future<void> _restoreFieldTraversal(
    EditableMapDocument document,
    FieldTraversalZoneReceipt receipt, {
    required bool redo,
  }) async {
    final source = port;
    if (source is! FieldTraversalZonePort || document.saving) return;
    final token = redo ? document.redoToken : document.undoToken;
    final rollback = document.preserveDraft();
    try {
      document.restore(redo: redo);
      document.saving = document.fieldTraversalSaving = true;
      notify();
      final restored = await (source as FieldTraversalZonePort)
          .restoreFieldTraversalZone(
            session,
            document.base,
            receipt,
            redo: redo,
          );
      if (_disposed) return;
      document.acceptSave(restored.document.map, restored.document.revision);
      final receipts = _fieldTraversalReceipts[document.base.mapId]!;
      receipts.remove(token);
      receipts[(redo ? document.undoToken : document.redoToken)!] = restored;
      _previews.remove(document.base.mapId);
    } on Object catch (failure) {
      rollback();
      document.error = _message(failure);
    } finally {
      document.saving = document.fieldTraversalSaving = false;
      notify();
    }
  }
}
