part of 'map_workspace_controller.dart';

extension MapWorkspaceCatalogPreparation on MapWorkspaceController {
  Future<MapCatalogPreparation> prepareCatalog(
    String actionId,
    Map<String, Object?> parameters,
  ) async {
    final mutations = catalogPort;
    final targetId = _catalogMapId(actionId, parameters);
    final problem = _catalogProblem(actionId, targetId);
    if (problem != null || mutations is! MapCatalogPreparationPort) {
      throw MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        problem ?? 'L’analyse du catalogue est indisponible.',
      );
    }
    catalogBusy = true;
    _catalogTargetId = targetId;
    notify();
    try {
      final preparation = await (mutations as MapCatalogPreparationPort)
          .prepare(
            session,
            actionId,
            parameters,
            expectedMapRevisions: _catalogRevisions(targetId),
            expectedManifest: project,
          );
      if (_disposed) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Cette session de projet est fermée.',
        );
      }
      return preparation;
    } finally {
      _catalogTargetId = null;
      catalogBusy = false;
      notify();
    }
  }

  Future<MapCatalogResult> applyPreparedCatalog(
    MapCatalogPreparation preparation, {
    bool confirmDestructive = false,
  }) async {
    final mutations = catalogPort;
    final targetId = preparation.targetMapId;
    final problem = _catalogProblem(preparation.actionId, targetId);
    if (problem != null ||
        mutations is! MapCatalogPreparationPort ||
        preparation.sessionId != session.sessionId ||
        preparation.sourceMap.id != targetId ||
        _catalogMapId(preparation.actionId, preparation.parameters) !=
            targetId ||
        (!preparation.canApply && !preparation.noChange)) {
      return MapCatalogResult(
        error: problem ?? 'Cette analyse ne permet pas la publication.',
      );
    }
    catalogBusy = true;
    _catalogTargetId = targetId;
    notify();
    MapCatalogReceipt? receipt;
    try {
      receipt = await (mutations as MapCatalogPreparationPort).applyPrepared(
        session,
        preparation,
        expectedMapRevisions: _catalogRevisions(targetId),
        confirmDestructive: confirmDestructive,
        expectedManifest: project,
        validateBeforeApply: () => _disposed
            ? 'Cette session de projet est fermée.'
            : _catalogDraftProblem(preparation.actionId, targetId),
      );
      if (_disposed) {
        return MapCatalogResult(
          published: receipt.changedPaths.isNotEmpty,
          receipt: receipt,
        );
      }
      pendingCatalogReceipt = receipt;
      return await _integrateCatalog(catalogPort!, receipt);
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

  String? _catalogProblem(String actionId, String? targetId) {
    if (_disposed ||
        catalogPort == null ||
        catalogBusy ||
        pendingCatalogReceipt != null ||
        project == null) {
      return 'Le catalogue est indisponible ou une opération est encore active.';
    }
    return _catalogDraftProblem(actionId, targetId);
  }

  String? _catalogDraftProblem(String actionId, String? targetId) {
    final target = documents[targetId];
    if (target?.dirty == true || target?.saving == true) {
      return 'Enregistrez cette carte avant de poursuivre cette opération.';
    }
    if (actionId == 'map.resize_apply' || actionId == 'map.delete_apply') {
      if (targetId != null) {
        final problem = catalogDependencyFailure?.call(actionId, targetId);
        if (problem != null) return problem;
      }
      for (final document in documents.values) {
        if (document.base.mapId == targetId ||
            (!document.dirty && !document.saving)) {
          continue;
        }
        final references =
            document.current.warps.any(
              (warp) => warp.targetMapId == targetId,
            ) ||
            document.current.connections.any(
              (connection) => connection.targetMapId == targetId,
            ) ||
            (targetId != null &&
                buildNarrativeDependencyIndex(
                      project: project!,
                      maps: [document.current],
                    )
                    .usagesFor(NarrativeDependencyKey.map(targetId))
                    .any(
                      (usage) =>
                          usage.owner.physicalMapId == document.base.mapId,
                    ));
        if (references) {
          return 'La carte « ${document.current.name} » contient des références non enregistrées. Enregistrez ou annulez son brouillon avant de poursuivre.';
        }
      }
    }
    return null;
  }

  Map<String, String> _catalogRevisions(String? targetId) => {
    if (documents[targetId] case final target?)
      target.base.mapId: target.base.revision,
  };

  String? _catalogMapId(String actionId, Map<String, Object?> parameters) {
    final value =
        parameters[actionId == 'map.duplicate' ? 'sourceMapId' : 'mapId'];
    return value is String ? value : null;
  }

  String _message(Object failure) => failure is MapWorkspaceFailure
      ? failure.message
      : 'Impossible de charger ou d’enregistrer cette carte.';
}
