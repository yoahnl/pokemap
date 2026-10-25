part of 'event_workspace_controller.dart';

extension EventWorkspaceTemplates on EventWorkspaceController {
  Future<bool> publishTemplate(StandardEventTemplateSpec spec) async {
    if (_closed || busy || narrative.busy) return false;
    final gateway = port;
    if (gateway is! EventTemplatePort) {
      return _fail('L’édition guidée des événements est indisponible.');
    }
    var ownsBusy = false;
    try {
      await flushEdits?.call();
      if (_closed || busy) return false;
      if (dirty || narrative.dirty) {
        return _fail(
          'Enregistrez les brouillons ouverts avant de publier cet événement guidé.',
        );
      }
      busy = true;
      ownsBusy = true;
      changed();
      final mapIds = {
        spec.mapId,
        if (spec.parameters['destinationMapId'] case final String id) id,
      };
      if (!await prepare(mapIds: mapIds) || _closed) {
        return false;
      }
      final existingSceneIds = <String>{};
      final original =
          workspace.documents[spec.mapId]?.current ?? _maps[spec.mapId];
      if (original != null) {
        final previous = readStandardEventTemplate(
          project: narrative.project,
          map: original,
          entityId: spec.entityId,
        );
        if (previous != null) {
          final entity = original.entities.singleWhere(
            (value) => value.id == spec.entityId,
          );
          existingSceneIds.addAll(
            standardEventTemplateSceneIds(
              previous,
              generation:
                  entity.properties['standardEventTemplate.sceneGeneration.v1'],
            ),
          );
        }
        final destination = previous?.parameters['destinationMapId'];
        if (destination is String) {
          mapIds.add(destination);
          await loadMap(destination);
        }
      }
      if (_closed) return false;
      final snapshot = narrative.project;
      final templateMaps = [
        for (final id in mapIds)
          if (workspace.documents[id]?.current ?? _maps[id]
              case final MapData map)
            map,
      ];
      final projection = compileStandardEventTemplate(
        project: snapshot,
        maps: templateMaps,
        spec: spec,
      );
      for (final sceneId in {
        ...existingSceneIds,
        ...projection.scenes.map((scene) => scene.id),
      }) {
        final problem = narrative.sceneAccessProblem?.call(sceneId);
        if (problem != null) return _fail(problem);
      }
      final document = workspace.documents[spec.mapId];
      if (document?.dirty == true || document?.saving == true) {
        return _fail(
          'Enregistrez ou annulez les modifications de cette carte avant de publier son événement.',
        );
      }
      final entry = snapshot.maps.singleWhere(
        (entry) => entry.id == spec.mapId,
      );
      final base =
          document?.base ??
          await workspace.port.loadMap(workspace.session, entry);
      if (_closed || narrative.project != snapshot) {
        return _fail('Le projet a changé pendant la préparation. Réessayez.');
      }
      final workingMap = templateMaps.singleWhere(
        (map) => map.id == spec.mapId,
      );
      if (base.map != workingMap ||
          document?.dirty == true ||
          document?.saving == true) {
        return _fail(
          'La carte a changé. Rechargez-la avant de publier cet événement.',
        );
      }
      if (document != null) document.saving = true;
      changed();
      try {
        final receipt = await (gateway as EventTemplatePort).publishTemplate(
          base: base,
          spec: spec,
          project: snapshot,
          maps: templateMaps,
        );
        if (_closed) return false;
        workspace.acceptResources(receipt.beforeManifest, receipt.manifest);
        if (document != null) {
          document.saving = false;
          document.acceptCatalogContent(
            MapWorkspaceDocument(
              map: receipt.savedMap,
              revision: receipt.revision,
              mapId: receipt.savedMap.id,
            ),
          );
        }
        _maps[spec.mapId] = receipt.savedMap;
        activeId = projection.events.first.id;
        error = null;
        await narrative.acceptVisuals(
          receipt.manifest,
          receipt.changedPaths.toSet(),
        );
        return true;
      } finally {
        if (document != null) document.saving = false;
      }
    } catch (failure) {
      if (!_closed) _fail(failure.toString());
      return false;
    } finally {
      if (ownsBusy) {
        busy = false;
        if (!_closed) {
          reconcile();
          changed();
        }
      }
    }
  }
}
