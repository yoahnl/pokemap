part of 'map_workspace_controller.dart';

extension MapWorkspaceAcceptedResources on MapWorkspaceController {
  Future<void> acceptModelLight(
    ProjectModel3dEntry model,
    String beforeRevision,
    String afterRevision,
  ) async {
    if (_disposed) return;
    final source = port;
    if (source is MapWorkspaceModelLightPort) {
      await (source as MapWorkspaceModelLightPort).acceptModelLight(
        session,
        model,
        beforeRevision,
        afterRevision,
      );
    }
    if (_disposed) return;
    final current = project;
    if (current == null) return;
    final entries = current.models3d as ProjectModel3dEntries;
    final previous = entries.lookup(model.id);
    if (previous == null) return;
    final replacement = previous.copyWith(
      light: model.light,
      clearLight: model.light == null,
    );
    acceptResources(
      current,
      current.copyWith(models3d: entries.replaceSelected([replacement])),
      changedModels: {model.id: replacement},
    );
  }

  void _acceptResources(
    ProjectManifest before,
    ProjectManifest updated, {
    Map<String, ProjectModel3dEntry> changedModels = const {},
    BorderBlueprintRecord? changedBorder,
    ({String kind, String id})? removedLibraryResource,
    required bool notifyChange,
  }) {
    if (_disposed) return;
    if (changedModels.isEmpty) {
      if (project != before) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue a changé pendant cette opération.',
        );
      }
      project = _prepareModelProjection(updated);
      if (_workshopDefinitions != null) _workshopDefinitions = project;
    } else {
      final current = project;
      final currentModels = current?.models3d;
      final beforeModels = before.models3d;
      if (current == null ||
          currentModels is! ProjectModel3dEntries ||
          beforeModels is! ProjectModel3dEntries) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue a changé pendant cette opération.',
        );
      }
      for (final change in changedModels.entries) {
        final existing = currentModels.lookup(change.key);
        if (change.key != change.value.id ||
            (existing != null &&
                existing != beforeModels.lookup(change.key) &&
                existing != change.value)) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le catalogue a changé pendant cette opération.',
          );
        }
      }
      final sourceEpoch = ++_modelSourceEpoch;
      for (final entry in changedModels.entries) {
        _acceptedModelDefinitions[entry.key] = (
          epoch: sourceEpoch,
          definition: entry.value,
        );
      }
      for (final change in _dependentModelChanges(
        changedModels,
        _selectionMapsByModel,
      ).entries) {
        modelSourceSelectionsVisited++;
        final selection = _selections[change.key]!;
        _selections[change.key] = _selectionWithDefinitions(
          selection,
          _replaceModelProjection(selection.definitions, change.value),
        );
      }
      for (final change in _dependentModelChanges(
        changedModels,
        _previewMapsByModel,
      ).entries) {
        modelSourcePreviewsVisited++;
        _previewDefinitions[change.key] = _replaceModelProjection(
          _previewDefinitions[change.key]!,
          change.value,
        );
      }
      project = _replaceModelProjection(current, changedModels);
      if (_workshopDefinitions case final definitions?) {
        _workshopDefinitions = _replaceModelProjection(
          definitions,
          changedModels,
        );
      }
      if (_resourceVisualDefinitions case final definitions?) {
        final family = identical(definitions, _familyDefinitions);
        final borders = identical(definitions, _onDemandDefinitions);
        _resourceVisualDefinitions = _replaceModelProjection(
          definitions,
          changedModels,
        );
        if (family) _familyDefinitions = _resourceVisualDefinitions;
        if (borders) _onDemandDefinitions = _resourceVisualDefinitions;
      }
      if (_familyDefinitions case final definitions?
          when !identical(definitions, _resourceVisualDefinitions)) {
        _familyDefinitions = _replaceModelProjection(
          definitions,
          changedModels,
        );
      }
      if (_onDemandDefinitions case final definitions?
          when !identical(definitions, _resourceVisualDefinitions)) {
        _onDemandDefinitions = _replaceModelProjection(
          definitions,
          changedModels,
        );
      }
      if (_combinedVisuals case final definitions?) {
        _combinedVisuals = _replaceModelProjection(definitions, changedModels);
        _visualMapSource =
            _selections[active?.base.mapId]?.definitions ?? project;
        _visualFamilySource = _resourceVisualDefinitions;
      }
    }
    if (changedBorder case final border?) {
      _acceptBorderProjection(border);
    }
    if (removedLibraryResource case final removed?) {
      _resourceClosures.remove('${removed.kind}:${removed.id}');
      if (removed.kind == 'borderBlueprint') {
        _borderBlueprints.remove(removed.id);
      }
      if (removed.kind == 'model3d') {
        _acceptedModelDefinitions.remove(removed.id);
      }
      final family = _familyDefinitions;
      final onDemand = _onDemandDefinitions;
      if (family != null) {
        _familyDefinitions = withoutLibraryResource(family, removed);
      }
      if (onDemand != null) {
        _onDemandDefinitions = withoutLibraryResource(onDemand, removed);
      }
      if (!identical(family, _familyDefinitions) ||
          !identical(onDemand, _onDemandDefinitions)) {
        _composeResourceVisuals();
      }
    }
    if (notifyChange) notify();
  }

  void _acceptBorderProjection(BorderBlueprintRecord record) {
    for (final id in _selectionMapsByBorder[record.id] ?? const <String>{}) {
      borderWorkshopSelectionsVisited++;
      final selection = _selections[id]!;
      _selections[id] = _selectionWithDefinitions(
        selection,
        replaceLoadedBorderProjection(selection.definitions, record),
      );
    }
    for (final id in _previewMapsByBorder[record.id] ?? const <String>{}) {
      _previewDefinitions[id] = replaceLoadedBorderProjection(
        _previewDefinitions[id]!,
        record,
      );
    }
    ProjectManifest? replace(ProjectManifest? value) =>
        value == null ? null : replaceLoadedBorderProjection(value, record);
    _familyDefinitions = replace(_familyDefinitions);
    _onDemandDefinitions = replace(_onDemandDefinitions);
    _resourceVisualDefinitions = replace(_resourceVisualDefinitions);
    if (_combinedVisuals != null) {
      _combinedVisuals = replace(_combinedVisuals);
      _visualMapSource =
          _selections[active?.base.mapId]?.definitions ?? project;
      _visualFamilySource = _resourceVisualDefinitions;
    }
  }
}
