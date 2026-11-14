part of 'map_workspace_controller.dart';

extension _MapWorkspaceExternalStates on MapWorkspaceController {
  void _closeExternallyRemovedDocument(
    String id,
    EditableMapDocument document,
  ) {
    documents.remove(id);
    _forgetVisualScope(id);
    final selection = _selections.remove(id);
    _unindexExternalProjection(
      id,
      selection?.definitions,
      _selectionMapsByModel,
    );
    _externalConflicts.remove(id);
    _mapVisualProfiles.remove(id);
    _elementOrderReceipts.remove(id);
    _fieldObstacleReceipts.remove(id);
    _modelVisibilityReceipts.remove(id);
    _fieldTraversalReceipts.remove(id);
    document.weatherVisuals?.dispose();
    document.atmosphere?.dispose();
    document.exteriorDecoration?.dispose();
    document.editor?.dispose();
    if (active == document) active = null;
  }

  Future<void> _refreshExternalVisualStates(
    Set<({String kind, String id})> resources,
  ) async {
    final source = port;
    if (source is! ProjectVisualsPort) return;
    for (final resource in resources.where(
      (resource) => resource.kind == 'visualSettings',
    )) {
      if (_disposed) return;
      if (resource.id == SpatialVisualDocument.projectRelativePath) {
        final state = await (source as ProjectVisualsPort).loadVisuals(session);
        if (_disposed) return;
        final owner = settingsVisualsOwner;
        if (owner != null && owner.scope == null) {
          owner.acceptExternalState(state);
        }
        _projectVisualProfile = state.profile;
        for (final document in documents.values) {
          document.visualProfile = state.profile.overriddenBy(
            document.weatherVisuals?.preview.value ??
                _mapVisualProfiles[document.base.mapId] ??
                SpatialVisualPatch(),
          );
        }
        continue;
      }
      final settingsScope = settingsVisualsOwner?.scope;
      final id =
          settingsScope != null &&
              resource.id ==
                  SpatialVisualDocument.relativePathForMap(settingsScope.id)
          ? settingsScope.id
          : _visualScopeMapIds[resource.id];
      if (id != null) {
        final maps = project!.maps;
        final entry = maps is ProjectMapEntries
            ? maps.lookup(id)
            : maps.where((entry) => entry.id == id).firstOrNull;
        if (entry == null) continue;
        final state = await (source as ProjectVisualsPort).loadVisuals(
          session,
          map: entry,
        );
        if (_disposed) return;
        _mapVisualProfiles[id] = state.profile;
        final document = documents[id];
        final owners = <ProjectVisualsController>{
          ?document?.weatherVisuals,
          if (settingsVisualsOwner?.scope?.id == id) settingsVisualsOwner!,
        };
        for (final owner in owners) {
          owner.acceptExternalState(state);
        }
        if (document != null) {
          document.visualProfile = inheritedVisualProfile.overriddenBy(
            document.weatherVisuals?.preview.value ?? state.profile,
          );
        }
      }
    }
  }

  Future<Set<String>> _refreshExternalSecondaryStates(
    Set<({String kind, String id})> resources,
  ) async {
    final definitionsChanged = <String>{};
    final source = port;
    for (final resource in resources) {
      if (_disposed) return definitionsChanged;
      final document = documents[resource.id];
      if (document == null) continue;
      switch (resource.kind) {
        case 'mapAtmosphere':
          if (source is! MapAtmospherePort) continue;
          final previous = document.atmosphere;
          final next = await MapAtmosphereController.open(
            session,
            resource.id,
            source as MapAtmospherePort,
          );
          if (_disposed ||
              document != documents[resource.id] ||
              document.atmosphere != previous) {
            next.dispose();
            continue;
          }
          if (previous != null && previous.revision == next.revision) {
            next.dispose();
            continue;
          }
          if (previous != null &&
              (previous.dirty ||
                  previous.saving ||
                  previous.canUndo ||
                  previous.canRedo)) {
            previous.rejectExternalChange();
            next.dispose();
            continue;
          }
          document.atmosphere = next;
          previous?.dispose();
        case 'mapEditor':
          if (source is! MapEditorPort) continue;
          final previous = document.editor;
          final next = await MapEditorController.open(
            session,
            resource.id,
            source as MapEditorPort,
          );
          if (_disposed ||
              document != documents[resource.id] ||
              document.editor != previous) {
            next.dispose();
            continue;
          }
          if (previous != null && previous.revision == next.revision) {
            next.dispose();
            continue;
          }
          if (previous != null &&
              (previous.dirty ||
                  previous.saving ||
                  previous.canUndo ||
                  previous.canRedo)) {
            previous.rejectExternalChange();
            next.dispose();
            continue;
          }
          document.editor = next;
          previous?.dispose();
        case 'mapExteriorDecoration':
          if (source is! MapExteriorDecorationPort) continue;
          final previous = document.exteriorDecoration;
          final next = await MapExteriorDecorationController.open(
            session,
            document.current,
            source as MapExteriorDecorationPort,
          );
          if (_disposed ||
              document != documents[resource.id] ||
              document.exteriorDecoration != previous) {
            next.dispose();
            continue;
          }
          if (previous != null && previous.revision == next.revision) {
            next.dispose();
            continue;
          }
          if (previous != null &&
              (previous.dirty ||
                  previous.saving ||
                  previous.canUndo ||
                  previous.canRedo)) {
            previous.rejectExternalChange();
            next.dispose();
            continue;
          }
          document.exteriorDecoration = next;
          previous?.dispose();
          definitionsChanged.add(resource.id);
      }
    }
    return definitionsChanged;
  }

  bool _hasLocalWork(EditableMapDocument document) =>
      document.dirty ||
      document.saving ||
      document.spatialFieldObstacleSaving ||
      document.fieldTraversalSaving ||
      document.elementOrderSaving ||
      document.canUndo ||
      document.canRedo ||
      document.atmosphere?.dirty == true ||
      document.atmosphere?.saving == true ||
      document.atmosphere?.canUndo == true ||
      document.atmosphere?.canRedo == true ||
      document.exteriorDecoration?.dirty == true ||
      document.exteriorDecoration?.saving == true ||
      document.exteriorDecoration?.canUndo == true ||
      document.exteriorDecoration?.canRedo == true ||
      document.weatherVisuals?.dirty == true ||
      document.weatherVisuals?.saving == true ||
      document.weatherVisuals?.canUndo == true ||
      document.weatherVisuals?.canRedo == true ||
      document.editor?.dirty == true ||
      document.editor?.saving == true ||
      document.editor?.canUndo == true ||
      document.editor?.canRedo == true;

  bool _usesExternalResource(
    ProjectManifest definitions,
    ({String kind, String id}) resource,
  ) {
    final id = resource.id;
    return switch (resource.kind) {
      'model3d' => definitions.models3d.any((entry) => entry.id == id),
      'tileset' => definitions.tilesets.any((entry) => entry.id == id),
      'element' => definitions.elements.any((entry) => entry.id == id),
      'character' => definitions.characters.any((entry) => entry.id == id),
      'environmentPreset' => definitions.environmentPresets.any(
        (entry) => entry.id == id,
      ),
      'smartTilePreset' => definitions.smartTileCatalog.presets.any(
        (entry) => entry.id == id,
      ),
      'smartTileMaterial' => definitions.smartTileCatalog.materials.any(
        (entry) => entry.id == id,
      ),
      'smartTilePattern' => definitions.smartTileCatalog.patterns.any(
        (entry) => entry.id == id,
      ),
      'smartTileAtlas' => definitions.smartTileCatalog.atlases.any(
        (entry) => entry.id == id,
      ),
      'smartTileAnimation' => definitions.smartTileCatalog.animations.any(
        (entry) => entry.id == id,
      ),
      'borderBlueprint' || 'borderRecord' =>
        definitions.borderCatalog.records.any((entry) => entry.id == id),
      'dialogue' => definitions.dialogues.any((entry) => entry.id == id),
      'fact' => definitions.facts.any((entry) => entry.id == id),
      _ => false,
    };
  }
}
