part of 'map_workspace_controller.dart';

extension MapWorkspaceCatalogCommands on MapWorkspaceController {
  bool catalogLocks(String mapId) =>
      (catalogBusy && _catalogTargetId == mapId) ||
      pendingCatalogReceipt?.documents.containsKey(mapId) == true;

  Future<MapCatalogResult> mutateCatalog(
    String actionId,
    Map<String, Object?> parameters, {
    bool confirmDestructive = false,
  }) async {
    final mutations = catalogPort;
    final targetId = _catalogMapId(actionId, parameters);
    final problem = _catalogProblem(actionId, targetId);
    if (problem != null || mutations == null) {
      return MapCatalogResult(error: problem);
    }
    catalogBusy = true;
    _catalogTargetId = targetId;
    notify();
    MapCatalogReceipt? receipt;
    try {
      receipt = await mutations.mutate(
        session,
        actionId,
        parameters,
        expectedMapRevisions: _catalogRevisions(targetId),
        confirmDestructive: confirmDestructive,
        expectedManifest: project,
      );
      if (_disposed) return MapCatalogResult(published: true, receipt: receipt);
      pendingCatalogReceipt = receipt;
      return await _integrateCatalog(mutations, receipt);
    } on Object catch (failure) {
      final message = failure is MapWorkspaceFailure
          ? failure.message
          : failure.toString();
      if (!_disposed) error = message;
      return MapCatalogResult(
        published: receipt != null,
        receipt: receipt,
        error: message,
      );
    } finally {
      _catalogTargetId = null;
      catalogBusy = false;
      notify();
    }
  }

  Future<MapCatalogResult> retryCatalogRefresh() async {
    final receipt = pendingCatalogReceipt;
    final mutations = catalogPort;
    if (_disposed || catalogBusy || receipt == null || mutations == null) {
      return const MapCatalogResult(error: 'Aucune relecture disponible.');
    }
    catalogBusy = true;
    notify();
    try {
      return await _integrateCatalog(mutations, receipt);
    } finally {
      catalogBusy = false;
      notify();
    }
  }

  Future<MapCatalogResult> _integrateCatalog(
    MapCatalogPort mutations,
    MapCatalogReceipt receipt,
  ) async {
    try {
      await mutations.reconcile(session, receipt);
      if (_disposed) return MapCatalogResult(published: true, receipt: receipt);
      if (project != receipt.before) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue ouvert a changé pendant la publication.',
        );
      }
      for (final entry in receipt.documents.entries) {
        final existing = documents[entry.key];
        if (existing == null) continue;
        if (existing.saved.size != entry.value.map.size) {
          existing.acceptCatalogContent(entry.value);
        } else {
          existing.acceptCatalogMetadata(entry.value);
        }
      }
      final activeId = active?.base.mapId;
      final retained = receipt.manifest.maps.map((entry) => entry.id).toSet();
      for (final id
          in documents.keys.where((id) => !retained.contains(id)).toList()) {
        final removed = documents.remove(id)!;
        if (removed.dirty) retiredDocuments[id] = removed;
        if (identical(active, removed)) active = null;
      }
      final changed = receipt.documents.keys.toSet();
      for (final id in {
        ...changed,
        if (activeId != null && !retained.contains(activeId)) activeId,
      }) {
        _mapEpochs[id] = (_mapEpochs[id] ?? 0) + 1;
      }
      _previews.removeWhere(
        (id, _) => !retained.contains(id) || changed.contains(id),
      );
      _loading.removeWhere(
        (id, _) => !retained.contains(id) || changed.contains(id),
      );
      project = receipt.manifest;
      _catalogEpoch++;
      pendingCatalogReceipt = null;
      error = null;
      if (activeId != null &&
          !retained.contains(activeId) &&
          receipt.manifest.maps.isNotEmpty) {
        await activate(receipt.manifest.maps.first);
      }
      notify();
      return MapCatalogResult(
        published: receipt.changedPaths.isNotEmpty,
        integrated: true,
        receipt: receipt,
      );
    } on Object catch (failure) {
      final message =
          'Publication effectuée ; relecture à reprendre : $failure';
      if (!_disposed) error = message;
      return MapCatalogResult(
        published: true,
        receipt: receipt,
        error: message,
      );
    }
  }
}
