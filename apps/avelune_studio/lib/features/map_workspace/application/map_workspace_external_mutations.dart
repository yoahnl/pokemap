part of 'map_workspace_controller.dart';

extension MapWorkspaceExternalMutations on MapWorkspaceController {
  Future<void> acceptExternalMutation(
    Set<({String kind, String id})> resources,
  ) {
    final operation = _externalMutations.then(
      (_) => _acceptExternalMutation(resources),
    );
    _externalMutations = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _acceptExternalMutation(
    Set<({String kind, String id})> resources,
  ) async {
    if (_disposed || project == null || resources.isEmpty) return;
    try {
      final source = port;
      if (source is! MapWorkspaceExternalMutationPort) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'La modification externe exige de rouvrir ce projet. Vos brouillons restent conservés.',
        );
      }
      final catalog = await (source as MapWorkspaceExternalMutationPort)
          .refreshExternalBaseline(session, resources: resources);
      if (_disposed) return;
      if (session.storage == ProjectSessionStorage.workingCatalog &&
          source is MapWorkspaceScopedPort) {
        projectScope = MapWorkspaceProjectScope.mapSelection;
      }
      final changed = <String>{
        for (final resource in resources)
          if (resource.kind == 'map') resource.id,
      };
      final documentChanges = {...changed};
      final dependencies = resources
          .where(
            (resource) => !const {
              'map',
              'mapAtmosphere',
              'mapEditor',
              'mapExteriorDecoration',
              'project',
              'projectSettings',
              'mapMetadata',
              'visualSettings',
            }.contains(resource.kind),
          )
          .toList();
      if (dependencies.isNotEmpty) {
        for (final entry in _selections.entries) {
          if (dependencies.any(
            (resource) =>
                _usesExternalResource(entry.value.definitions, resource),
          )) {
            changed.add(entry.key);
          }
        }
        for (final entry in _previewDefinitions.entries) {
          if (dependencies.any(
            (resource) => _usesExternalResource(entry.value, resource),
          )) {
            changed.add(entry.key);
          }
        }
      }
      await _refreshExternalVisualStates(resources);
      if (_disposed) return;
      final exteriorDefinitionsChanged = await _refreshExternalSecondaryStates(
        resources,
      );
      changed.addAll(exteriorDefinitionsChanged);
      if (_disposed) return;
      final settingsFields = {
        for (final resource in resources)
          if (resource.kind == 'projectSettings') resource.id,
      };
      if (settingsFields.contains('surf')) {
        _surfConfigurationAccepted = true;
        _acceptedSurfConfiguration = catalog.metadata.settings.surf;
      }
      if (settingsFields.contains('fieldAbilities')) {
        _fieldAbilitiesAccepted = true;
        _acceptedFieldAbilities = catalog.metadata.settings.fieldAbilities;
      }
      if (settingsFields.contains('audio')) {
        _audioAccepted = true;
        _acceptedAudio = catalog.metadata.settings.audio;
      }
      if (settingsFields.isNotEmpty) {
        _surfProjections = Expando<ProjectManifest>();
      }
      if (resources.any((resource) => resource.kind == 'project')) {
        project = _withSurfConfiguration(catalog.metadata);
        if (_workshopDefinitions case final loaded?) {
          _workshopDefinitions = mergeProjectMetadataSections(
            loaded,
            catalog.metadata,
            {for (final workshop in _workshops) ...workshop.metadataFields},
          );
        }
      } else {
        if (resources.any(
          (resource) =>
              resource.kind == 'map' || resource.kind == 'mapMetadata',
        )) {
          project = project!.copyWith(maps: catalog.metadata.maps);
        }
        if (settingsFields.isNotEmpty) {
          project = _withSurfConfiguration(
            project!.copyWith(settings: catalog.metadata.settings),
          );
        }
      }
      final affectedFields = <String>{
        for (final resource in resources)
          ...switch (resource.kind) {
            'character' => {'characterStudioCatalog'},
            'fact' => {'facts'},
            'dialogue' => {'dialogues'},
            'script' => {'scripts'},
            'scene' => {'scenes'},
            'cinematic' => {'cinematics'},
            'trainer' => {'trainers'},
            'encounterTable' => {'encounterTables'},
            'shop' => {'shops'},
            'badge' => {'badges'},
            'storyline' => {'storylines'},
            'scenario' => {'scenarios'},
            'worldRule' => {'worldRules'},
            _ => const <String>{},
          },
      };
      if (affectedFields.isNotEmpty) {
        _workshops.removeWhere(
          (workshop) => workshop.metadataFields.any(affectedFields.contains),
        );
      }
      final family = _familyDefinitions;
      if (family != null &&
          resources.any(
            (resource) => _usesExternalResource(family, resource),
          )) {
        _resourceKind = null;
        _familyDefinitions = null;
      }
      final borders = _onDemandDefinitions;
      if (borders != null &&
          resources.any(
            (resource) => _usesExternalResource(borders, resource),
          )) {
        _resetOnDemandSelections();
      }
      _composeResourceVisuals();
      for (final id in changed) {
        final document = documents[id];
        if (document != null &&
            documentChanges.contains(id) &&
            _hasLocalWork(document)) {
          final revision = await (source as MapWorkspaceExternalMutationPort)
              .readExternalMapRevision(session, id);
          if (_disposed) return;
          if (documents[id] != document) continue;
          if (revision == document.base.revision) {
            documentChanges.remove(id);
            if (dependencies.isEmpty &&
                !exteriorDefinitionsChanged.contains(id)) {
              continue;
            }
          }
        }
        _mapEpochs[id] = (_mapEpochs[id] ?? 0) + 1;
        _previews.remove(id);
        final previewDefinitions = _previewDefinitions.remove(id);
        _unindexExternalProjection(id, previewDefinitions, _previewMapsByModel);
        _loading.remove(id);
        if (document != null &&
            documentChanges.contains(id) &&
            _hasLocalWork(document)) {
          _externalConflicts.add(id);
          document.error = 'Une modification externe concerne cette carte. Votre brouillon et son historique sont conservés. Rouvrez le projet avant de publier ou d’annuler.';
          error = document.error;
          continue;
        }
        final maps = catalog.metadata.maps;
        final entry = maps is ProjectMapEntries
            ? maps.lookup(id)
            : maps.where((entry) => entry.id == id).firstOrNull;
        if (document == null) continue;
        if (entry == null) {
          _closeExternallyRemovedDocument(id, document);
          continue;
        }
        final sourceEpoch = _modelSourceEpoch;
        final selection = source is MapWorkspaceScopedPort
            ? await source.loadMapSelection(session, entry)
            : null;
        if (_disposed || document != documents[id]) return;
        if (!documentChanges.contains(id)) {
          if (selection != null &&
              selection.document.revision == document.base.revision) {
            _cacheSelection(id, selection, sourceEpoch);
            if (active == document && !hasCompleteProject) {
              project = _withWorkshops(selection.definitions);
            }
            continue;
          }
          if (_hasLocalWork(document)) {
            _externalConflicts.add(id);
            document.error = 'Une modification externe concerne aussi le document de cette carte. Votre brouillon et son historique sont conservés.';
            error = document.error;
            continue;
          }
        }
        final updated = await _prepareAtmosphere(
          EditableMapDocument(
            selection?.document ?? await port.loadMap(session, entry),
          ),
          entry,
        );
        if (_disposed) return;
        if (document != documents[id] || _hasLocalWork(document)) {
          updated.weatherVisuals?.dispose();
          updated.atmosphere?.dispose();
          updated.exteriorDecoration?.dispose();
          updated.editor?.dispose();
          _externalConflicts.add(id);
          document.error = 'Une modification externe concerne cette carte. Votre brouillon et son historique sont conservés.';
          error = document.error;
          continue;
        }
        document.weatherVisuals?.dispose();
        document.atmosphere?.dispose();
        document.exteriorDecoration?.dispose();
        document.editor?.dispose();
        if (selection != null) _cacheSelection(id, selection, sourceEpoch);
        documents[id] = updated;
        _externalConflicts.remove(id);
        _elementOrderReceipts.remove(id);
        _fieldObstacleReceipts.remove(id);
        _modelVisibilityReceipts.remove(id);
        _fieldTraversalReceipts.remove(id);
        if (active == document) {
          active = updated;
          if (selection != null && !hasCompleteProject) {
            project = _withWorkshops(selection.definitions);
          }
        }
      }
      notify();
    } catch (failure) {
      if (!_disposed) {
        error = _message(failure);
        notify();
      }
    }
  }
}
