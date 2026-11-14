part of 'map_workspace_controller.dart';

extension MapWorkspaceSaving on MapWorkspaceController {
  void acceptSavedMaps(Iterable<MapWorkspaceDocument> saved) {
    if (_disposed || project == null) return;
    for (final value in saved) {
      _previews.remove(value.mapId);
      documents[value.mapId]?.acceptCatalogContent(value);
    }
    notify();
  }

  Future<void> refreshSavedMaps(Set<String> mapIds) async {
    if (_disposed || project == null) return;
    final activeId = active?.base.mapId;
    for (final id in mapIds) {
      _previews.remove(id);
      final document = documents[id];
      if (document?.dirty == true || document?.saving == true) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Un brouillon de carte est encore ouvert. Enregistrez-le avant de relier les cartes.',
        );
      }
      final entry = project!.maps.where((map) => map.id == id).firstOrNull;
      if (entry == null) continue;
      final updated = EditableMapDocument(await port.loadMap(session, entry));
      if (_disposed) return;
      updated.atmosphere = document?.atmosphere;
      updated.exteriorDecoration = document?.exteriorDecoration;
      updated.editor = document?.editor;
      documents[id] = updated;
      if (activeId == id) active = updated;
    }
    notify();
  }

  Future<bool> _save(EditableMapDocument document) async {
    if (_disposed || document.saving) return false;
    if (_externalConflicts.contains(document.base.mapId)) {
      document.error = 'Une modification externe concerne cette carte. Votre brouillon reste conservé ; rouvrez le projet avant de publier.';
      notify();
      return false;
    }
    if (catalogLocks(document.base.mapId)) {
      document.error = 'Une publication du catalogue concerne cette carte.';
      notify();
      return false;
    }
    if (!identical(documents[document.base.mapId], document) ||
        (project != null &&
            !project!.maps.any((entry) => entry.id == document.base.mapId))) {
      document.error = 'Cette carte ne figure plus dans le projet.';
      notify();
      return false;
    }
    document.saving = true;
    notify();
    try {
      if (!await (document.weatherVisuals?.save() ?? Future.value(true))) {
        return false;
      }
      if (!await (document.atmosphere?.save() ?? Future.value(true))) {
        return false;
      }
      if (!await (document.editor?.save() ?? Future.value(true))) return false;
      if (!await (document.exteriorDecoration?.save() ?? Future.value(true))) {
        return false;
      }
      if (!document.dirty) return true;
      document.error = null;
      final snapshot = document.current;
      final before = document.base.map;
      notify();
      try {
        final revision = await port.saveMap(session, document.base, snapshot);
        if (_disposed) return false;
        document.acceptSave(snapshot, revision);
        final source = port;
        if (!hasCompleteProject &&
            source is MapWorkspaceScopedPort &&
            (!_selections.containsKey(document.base.mapId) ||
                !ProjectCatalogSelection.sameMapDependencies(
                  before,
                  snapshot,
                ))) {
          final entry = project!.maps.singleWhere(
            (entry) => entry.id == document.base.mapId,
          );
          final sourceEpoch = _modelSourceEpoch;
          final selection = await source.loadMapSelection(session, entry);
          if (_disposed) return false;
          _cacheSelection(entry.id, selection, sourceEpoch);
          if (identical(active, document)) {
            project = _withWorkshops(_selections[entry.id]!.definitions);
          }
        }
        return true;
      } catch (failure) {
        if (!_disposed) document.error = _message(failure);
        return false;
      }
    } finally {
      document.saving = false;
      notify();
    }
  }

  void _restore({required bool redo}) {
    final document = active;
    final manifest = project;
    if (document != null && _externalConflicts.contains(document.base.mapId)) {
      document.error = 'Une modification externe concerne cette carte. Votre historique reste conservé ; rouvrez le projet avant de l’utiliser.';
      notify();
      return;
    }
    if (document == null ||
        manifest == null ||
        document.saving ||
        catalogLocks(document.base.mapId) ||
        !manifest.maps.any((entry) => entry.id == document.base.mapId)) {
      return;
    }
    final exterior = document.exteriorDecoration;
    if (exterior?.editingExterior == true) {
      if (redo) {
        exterior!.redo();
      } else {
        exterior!.undo();
      }
      notify();
      return;
    }
    final token = redo ? document.redoToken : document.undoToken;
    final route = _fieldTraversalReceipts[document.base.mapId]?[token];
    if (route != null && document.base.revision == route.document.revision) {
      unawaited(_restoreFieldTraversal(document, route, redo: redo));
      return;
    }
    final visibility = _modelVisibilityReceipts[document.base.mapId]?[token];
    if (visibility != null &&
        document.base.revision == visibility.document.revision) {
      unawaited(_restoreModelVisibility(document, visibility, redo: redo));
      return;
    }
    final obstacle = _fieldObstacleReceipts[document.base.mapId]?[token];
    if (obstacle != null &&
        document.base.revision == obstacle.document.revision) {
      unawaited(_restoreFieldObstacle(document, obstacle, redo: redo));
      return;
    }
    final order = _elementOrderReceipts[document.base.mapId]?[token];
    if (order != null &&
        !document.dirty &&
        document.base.revision == order.document.revision) {
      unawaited(_restoreElementOrder(document, order, redo: redo));
      return;
    }
    document.restore(
      redo: redo,
      canRestore: (next) {
        final before = document.current;
        final resourceProblem = _historyResourceProblem(before, next, manifest);
        if (resourceProblem != null) {
          document.error = resourceProblem;
          return false;
        }
        if (_historyHasMissingMapDestination(next, manifest)) {
          document.error =
              'Cette annulation restaurerait une destination supprimée.';
          return false;
        }
        final removed = <(String, String)>[
          for (final entity in before.entities)
            if (!next.entities.any((item) => item.id == entity.id))
              ('entity', entity.id),
          for (final trigger in before.triggers)
            if (!next.triggers.any((item) => item.id == trigger.id))
              ('trigger', trigger.id),
        ];
        final dependencies = buildNarrativeDependencyIndex(
          project: manifest,
          maps: [before],
        );
        final referenced = removed.any(
          (item) => dependencies
              .usagesFor(
                NarrativeDependencyKey.mapSource(
                  mapId: before.id,
                  sourceKind: item.$1,
                  sourceId: item.$2,
                ),
              )
              .isNotEmpty,
        );
        final problem = referenced
            ? 'Cette annulation retirerait un personnage ou une zone utilisé par l’histoire enregistrée.'
            : historyGuard?.call(before, next);
        if (problem != null) {
          document.error = problem;
          return false;
        }
        return true;
      },
    );
    notify();
  }
}
