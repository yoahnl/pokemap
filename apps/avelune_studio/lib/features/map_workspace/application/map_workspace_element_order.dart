part of 'map_workspace_controller.dart';

extension MapWorkspaceElementOrder on MapWorkspaceController {
  bool get canReorderElements =>
      port is MapElementOrderPort &&
      session.storage != ProjectSessionStorage.portableCatalog;

  Future<bool> reorderElements(
    String kind,
    List<String> frontFirstIds,
    String? layerId,
  ) async {
    final document = active;
    final source = port;
    if (!canReorderElements ||
        document == null ||
        source is! MapElementOrderPort ||
        document.saving ||
        catalogLocks(document.base.mapId)) {
      return false;
    }
    if (document.dirty) {
      document.error = 'Enregistrez les modifications de la carte avant de changer sa superposition.';
      notify();
      return false;
    }
    final before = document.current;
    final rollback = document.preserveDraft();
    try {
      final next = _elementOrderPreview(before, kind, frontFirstIds, layerId);
      if (next == before) return true;
      document.commit(next);
      final token = document.undoToken!;
      document.saving = document.elementOrderSaving = true;
      notify();
      final receipt = await (source as MapElementOrderPort).reorderMapElements(
        session,
        document.base,
        kind,
        frontFirstIds,
        layerId,
      );
      if (_disposed) return false;
      if (receipt.document.map != next) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'L’ordre enregistré ne correspond pas à l’aperçu. Rouvrez la carte avant de poursuivre.',
        );
      }
      document.acceptSave(next, receipt.document.revision);
      final receipts = _elementOrderReceipts.putIfAbsent(
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
      document.saving = document.elementOrderSaving = false;
      notify();
    }
  }

  Future<void> _restoreElementOrder(
    EditableMapDocument document,
    MapElementOrderWorkspaceReceipt receipt, {
    required bool redo,
  }) async {
    final source = port;
    if (!canReorderElements ||
        source is! MapElementOrderPort ||
        document.saving) {
      return;
    }
    final token = redo ? document.redoToken : document.undoToken;
    final rollback = document.preserveDraft();
    try {
      document.restore(redo: redo);
      final next = document.current;
      document.saving = document.elementOrderSaving = true;
      notify();
      final restored = await (source as MapElementOrderPort)
          .undoMapElementOrder(session, document.base, receipt);
      if (_disposed) return;
      if (restored.document.map != next) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Cette annulation ne correspond plus à la carte. Rouvrez-la avant de poursuivre.',
        );
      }
      document.acceptSave(next, restored.document.revision);
      final receipts = _elementOrderReceipts[document.base.mapId]!;
      receipts.remove(token);
      receipts[(redo ? document.undoToken : document.redoToken)!] = restored;
      _previews.remove(document.base.mapId);
    } on Object catch (failure) {
      rollback();
      document.error = _message(failure);
    } finally {
      document.saving = document.elementOrderSaving = false;
      notify();
    }
  }
}

MapData _elementOrderPreview(
  MapData map,
  String kind,
  List<String> frontFirstIds,
  String? layerId,
) {
  if (kind == 'layers') {
    final byId = {for (final layer in map.layers) layer.id: layer};
    if (layerId != null ||
        frontFirstIds.length != byId.length ||
        frontFirstIds.toSet().length != byId.length ||
        !frontFirstIds.every(byId.containsKey)) {
      throw const FormatException('La liste des calques a changé.');
    }
    final ids = mapPaintsFirstLayerInFront(map)
        ? frontFirstIds
        : frontFirstIds.reversed;
    return map.copyWith(layers: [for (final id in ids) byId[id]!]);
  }
  if (kind != 'decor' ||
      !map.layers.any((layer) => layer.id == layerId && layer is TileLayer)) {
    throw const FormatException(
      'Ces éléments ne partagent pas un calque réordonnable.',
    );
  }
  final items = map.placedElements
      .where((item) => item.layerId == layerId)
      .map((item) => item.id)
      .toSet();
  if (frontFirstIds.length != items.length ||
      frontFirstIds.toSet().length != items.length ||
      !frontFirstIds.every(items.contains)) {
    throw const FormatException('La liste des décors a changé.');
  }
  final ranks = {
    for (final (index, id) in frontFirstIds.indexed)
      id: frontFirstIds.length - index - 1,
  };
  return map.copyWith(
    placedElements: [
      for (final item in map.placedElements)
        if (item.layerId == layerId)
          item.copyWith(visualOrder: ranks[item.id]!)
        else
          item,
    ],
  );
}
