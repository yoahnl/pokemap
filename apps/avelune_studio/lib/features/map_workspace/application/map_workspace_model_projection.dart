part of 'map_workspace_controller.dart';

extension _MapWorkspaceModelProjection on MapWorkspaceController {
  void _indexVisualScope(String id) {
    try {
      _visualScopeMapIds[SpatialVisualDocument.relativePathForMap(id)] = id;
    } on FormatException {
      return;
    }
  }

  void _forgetVisualScope(String id) {
    try {
      _visualScopeMapIds.remove(SpatialVisualDocument.relativePathForMap(id));
    } on FormatException {
      return;
    }
  }

  ProjectManifest _prepareResourceProjection(
    ProjectManifest value, {
    int? sourceEpoch,
  }) {
    final entries = ProjectModel3dEntries.prepare(value.models3d);
    final maps = ProjectMapEntries.prepare(value.maps);
    final replacements = <ProjectModel3dEntry>[];
    if (sourceEpoch != null && _acceptedModelDefinitions.isNotEmpty) {
      for (final entry in entries) {
        final replacement = _acceptedModelDefinitions[entry.id];
        if (replacement != null &&
            replacement.epoch > sourceEpoch &&
            !identical(entry, replacement.definition)) {
          replacements.add(replacement.definition);
        }
      }
    }
    final models = replacements.isEmpty
        ? entries
        : entries.replaceSelected(replacements);
    var result =
        identical(models, value.models3d) && identical(maps, value.maps)
        ? value
        : value.copyWith(models3d: models, maps: maps);
    if (sourceEpoch != null && sourceEpoch < _resourceProjectionEpoch) {
      for (final element in value.elements) {
        final replacement = _acceptedElementDefinitions[element.id];
        if (replacement != null && replacement.epoch > sourceEpoch) {
          result = upsertDecorProjection(
            result,
            replacement.definition,
            loadedOnly: true,
          );
        }
      }
      for (final terrain in value.smartTileCatalog.presets) {
        final replacement = _acceptedTerrainDefinitions[terrain.id];
        if (replacement != null && replacement.epoch > sourceEpoch) {
          result = replaceLoadedTerrainProjection(
            result,
            replacement.definition,
          );
        }
      }
    }
    return result;
  }

  ProjectManifest _replaceModelProjection(
    ProjectManifest value,
    Map<String, ProjectModel3dEntry> changed,
  ) {
    final entries = value.models3d as ProjectModel3dEntries;
    final replacements = <ProjectModel3dEntry>[];
    for (final replacement in changed.values) {
      modelSourceProjectionLookups++;
      final previous = entries.lookup(replacement.id);
      if (previous != null && !identical(previous, replacement)) {
        replacements.add(replacement);
      }
    }
    return replacements.isEmpty
        ? value
        : value.copyWith(models3d: entries.replaceSelected(replacements));
  }

  MapWorkspaceSelection _selectionWithDefinitions(
    MapWorkspaceSelection selection,
    ProjectManifest definitions,
  ) => identical(selection.definitions, definitions)
      ? selection
      : MapWorkspaceSelection(
          document: selection.document,
          definitions: definitions,
          catalogRevision: selection.catalogRevision,
          snapshotRevision: selection.snapshotRevision,
        );

  MapWorkspaceSelection _cacheSelection(
    String mapId,
    MapWorkspaceSelection selection,
    int sourceEpoch,
  ) {
    _indexVisualScope(mapId);
    final definitions = _prepareResourceProjection(
      selection.definitions,
      sourceEpoch: sourceEpoch,
    );
    final previous = _selections[mapId]?.definitions;
    _indexResourceProjections(
      mapId,
      previous,
      definitions,
      _selectionMapsByModel,
      _selectionMapsByBorder,
      _selectionMapsByTerrain,
      _selectionMapsByElement,
    );
    final prepared = _selectionWithDefinitions(selection, definitions);
    _selections[mapId] = prepared;
    return prepared;
  }

  void _cachePreviewDefinitions(
    String mapId,
    ProjectManifest value,
    int sourceEpoch,
  ) {
    _indexVisualScope(mapId);
    final definitions = _prepareResourceProjection(
      value,
      sourceEpoch: sourceEpoch,
    );
    final previous = _previewDefinitions[mapId];
    _indexResourceProjections(
      mapId,
      previous,
      definitions,
      _previewMapsByModel,
      _previewMapsByBorder,
      _previewMapsByTerrain,
      _previewMapsByElement,
    );
    _previewDefinitions[mapId] = definitions;
  }

  void _clearSelections() {
    _selections.clear();
    _selectionMapsByModel.clear();
    _selectionMapsByBorder.clear();
    _selectionMapsByTerrain.clear();
    _selectionMapsByElement.clear();
  }

  void _indexResourceProjections(
    String mapId,
    ProjectManifest? previous,
    ProjectManifest? next,
    Map<String, Set<String>> models,
    Map<String, Set<String>> borders,
    Map<String, Set<String>> terrains,
    Map<String, Set<String>> elements,
  ) {
    _indexResourceIds(
      mapId,
      previous?.models3d.map((item) => item.id),
      next?.models3d.map((item) => item.id),
      models,
    );
    _indexResourceIds(
      mapId,
      previous?.borderCatalog.records.map((item) => item.id),
      next?.borderCatalog.records.map((item) => item.id),
      borders,
    );
    _indexResourceIds(
      mapId,
      previous?.smartTileCatalog.presets.map((item) => item.id),
      next?.smartTileCatalog.presets.map((item) => item.id),
      terrains,
    );
    _indexResourceIds(
      mapId,
      previous?.elements.map((item) => item.id),
      next?.elements.map((item) => item.id),
      elements,
    );
  }

  void _indexResourceIds(
    String mapId,
    Iterable<String>? previous,
    Iterable<String>? next,
    Map<String, Set<String>> index,
  ) {
    for (final id in previous ?? const <String>[]) {
      final maps = index[id];
      maps?.remove(mapId);
      if (maps?.isEmpty == true) index.remove(id);
    }
    for (final id in next ?? const <String>[]) {
      (index[id] ??= {}).add(mapId);
    }
  }

  Map<String, Map<String, ProjectModel3dEntry>> _dependentModelChanges(
    Map<String, ProjectModel3dEntry> changed,
    Map<String, Set<String>> index,
  ) {
    final result = <String, Map<String, ProjectModel3dEntry>>{};
    for (final model in changed.values) {
      for (final mapId in index[model.id] ?? const <String>{}) {
        (result[mapId] ??= {})[model.id] = model;
      }
    }
    return result;
  }
}
