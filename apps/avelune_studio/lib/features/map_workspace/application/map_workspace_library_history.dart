part of 'map_workspace_controller.dart';

extension MapWorkspaceLibraryHistory on MapWorkspaceController {
  bool libraryStepLeads({required bool redo}) {
    final document = active;
    return libraryHistory.leads(
      redo: redo,
      mapId: document?.base.mapId,
      depth: document?.undoCount ?? 0,
      token: document?.undoToken,
      mapCanStep: (redo ? document?.canRedo : document?.canUndo) ?? false,
    );
  }

  bool canStepHistory({required bool redo}) =>
      !catalogBusy &&
      pendingCatalogReceipt == null &&
      (libraryStepLeads(redo: redo) ||
          ((redo ? active?.canRedo : active?.canUndo) ?? false));

  Future<void> stepHistory({required bool redo}) async {
    if (catalogBusy || pendingCatalogReceipt != null) return;
    if (libraryStepLeads(redo: redo)) {
      await stepLibrary(redo: redo);
    } else {
      restore(redo: redo);
    }
  }

  Future<MapCatalogResult> stepLibrary({required bool redo}) async {
    final step = libraryHistory.next(redo: redo);
    final mutations = catalogPort;
    final manifest = project;
    if (step == null ||
        mutations == null ||
        manifest == null ||
        _disposed ||
        catalogBusy ||
        pendingCatalogReceipt != null) {
      return const MapCatalogResult(
        error:
            'Le catalogue est indisponible ou une opération est encore active.',
      );
    }
    final problem = _libraryStepProblem(step, redo: redo);
    if (problem != null) return _refuseLibraryStep(problem);
    final returnMapId = active?.base.mapId;
    catalogBusy = true;
    notify();
    MapCatalogReceipt? receipt;
    try {
      if (_startedSaves.isNotEmpty) await savesSettled;
      if (_disposed) return const MapCatalogResult(error: 'Session fermée.');
      receipt = await mutations.restoreHistory(
        session,
        step.receipt,
        redo: redo,
        expectedManifest: manifest,
      );
      if (_disposed) return MapCatalogResult(published: true, receipt: receipt);
      pendingCatalogReceipt = receipt;
      final result = await _integrateCatalog(
        mutations,
        receipt,
        reopenMapId: redo ? null : step.returnMapId,
      );
      if (!result.integrated) {
        libraryHistory.discard(redo: redo);
        return result;
      }
      libraryHistory.land(
        _libraryStep(
          redo ? receipt : step.receipt,
          returnMapId: redo ? returnMapId : step.returnMapId,
          revisions: receipt,
        ),
        redo: redo,
      );
      final created = project!.maps
          .where((entry) => entry.id == receipt!.createdMapId)
          .firstOrNull;
      if (created != null) await activate(created);
      return result;
    } on Object catch (failure) {
      libraryHistory.discard(redo: redo);
      final message = failure is MapWorkspaceFailure
          ? failure.message
          : failure.toString();
      if (!_disposed) _showLibraryProblem(message);
      return MapCatalogResult(
        published: receipt != null,
        receipt: receipt,
        error: message,
      );
    } finally {
      catalogBusy = false;
      notify();
    }
  }

  void recordHistoryStep(MapCatalogReceipt receipt) =>
      _recordLibraryStep(receipt, active?.base.mapId);

  void _recordLibraryStep(MapCatalogReceipt receipt, String? returnMapId) {
    if (receipt.historyEntryId == null || receipt.changedPaths.isEmpty) return;
    libraryHistory.record(
      _libraryStep(receipt, returnMapId: returnMapId, revisions: receipt),
    );
  }

  MapLibraryStep _libraryStep(
    MapCatalogReceipt receipt, {
    required String? returnMapId,
    required MapCatalogReceipt revisions,
  }) => MapLibraryStep(
    receipt: receipt,
    returnMapId: returnMapId,
    positions: {
      for (final document in documents.values)
        document.base.mapId: (
          depth: document.undoCount,
          token: document.undoToken,
        ),
    },
    revisions: {
      for (final entry in revisions.documents.entries)
        entry.key: entry.value.revision,
    },
  );

  String? _libraryStepProblem(MapLibraryStep step, {required bool redo}) {
    for (final entry in step.revisions.entries) {
      final document = documents[entry.key];
      if (document == null) continue;
      final name = document.current.name;
      if (document.base.revision != entry.value) {
        libraryHistory.discard(redo: redo);
        return 'La carte « $name » a été enregistrée depuis cette action de la bibliothèque : elle ne peut plus être ${redo ? 'rétablie' : 'annulée'}. Rien n’a été modifié.';
      }
      if (document.dirty || document.saving) {
        return 'Enregistrez ou annulez les modifications de la carte « $name » avant de ${redo ? 'rétablir' : 'annuler'} cette action de la bibliothèque.';
      }
    }
    return null;
  }

  MapCatalogResult _refuseLibraryStep(String message) {
    _showLibraryProblem(message);
    notify();
    return MapCatalogResult(error: message);
  }

  void _showLibraryProblem(String message) {
    final document = active;
    if (document == null) {
      error = message;
    } else {
      document.error = message;
    }
  }
}
