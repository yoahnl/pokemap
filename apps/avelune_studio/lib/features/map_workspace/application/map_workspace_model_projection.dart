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

  ProjectManifest _prepareModelProjection(
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
    return identical(models, value.models3d) && identical(maps, value.maps)
        ? value
        : value.copyWith(models3d: models, maps: maps);
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

  void _indexModelProjection(
    String mapId,
    ProjectManifest? previous,
    ProjectManifest next,
    Map<String, Set<String>> index,
  ) {
    if (previous != null) {
      for (final model in previous.models3d) {
        final maps = index[model.id];
        maps?.remove(mapId);
        if (maps?.isEmpty == true) index.remove(model.id);
      }
    }
    for (final model in next.models3d) {
      (index[model.id] ??= {}).add(mapId);
    }
  }

  void _cacheSelection(
    String mapId,
    MapWorkspaceSelection selection,
    int sourceEpoch,
  ) {
    _indexVisualScope(mapId);
    final definitions = _prepareModelProjection(
      selection.definitions,
      sourceEpoch: sourceEpoch,
    );
    _indexModelProjection(
      mapId,
      _selections[mapId]?.definitions,
      definitions,
      _selectionMapsByModel,
    );
    _selections[mapId] = _selectionWithDefinitions(selection, definitions);
  }

  void _cachePreviewDefinitions(
    String mapId,
    ProjectManifest value,
    int sourceEpoch,
  ) {
    _indexVisualScope(mapId);
    final definitions = _prepareModelProjection(
      value,
      sourceEpoch: sourceEpoch,
    );
    _indexModelProjection(
      mapId,
      _previewDefinitions[mapId],
      definitions,
      _previewMapsByModel,
    );
    _previewDefinitions[mapId] = definitions;
  }

  void _clearSelections() {
    _selections.clear();
    _selectionMapsByModel.clear();
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

  void _unindexExternalProjection(
    String id,
    ProjectManifest? definitions,
    Map<String, Set<String>> index,
  ) {
    for (final model
        in definitions?.models3d ?? const <ProjectModel3dEntry>[]) {
      final ids = index[model.id];
      ids?.remove(id);
      if (ids?.isEmpty == true) index.remove(model.id);
    }
  }
}
