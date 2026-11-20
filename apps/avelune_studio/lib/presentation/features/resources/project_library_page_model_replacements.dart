part of 'project_library_page.dart';

extension _ProjectLibraryPageModelReplacements on _ProjectLibraryPageState {
  ModelReplacementPanelBuilder? _modelReplacementBuilder(
    _ProjectLibraryRead read,
    ProjectLibraryItem selected,
    ProjectLibraryManagement? management,
    MapWorkspaceVisuals? visuals,
  ) {
    final editor = management?.editor;
    if (management == null || editor is! ProjectModelReplacementProvider) {
      return null;
    }
    final replacement =
        (editor as ProjectModelReplacementProvider).modelReplacement;
    return ({
      required revision,
      required enabled,
      required onBusyChanged,
      required onRevision,
      required onPublished,
    }) => ProjectModelReplacementPanel(
      item: selected,
      models: read.catalog.entries.values.where(
        (item) => item.kind == 'model3d' && item.id != selected.id,
      ),
      familyLabels: read.catalog.familyLabels,
      port: replacement,
      revision: revision,
      available: enabled,
      showPreview: visuals is SpatialWorkspaceVisuals,
      pickFile: management.pickFile,
      prepareCatalog: () => _prepareReplacementCatalog(read, management.editor),
      checkDrafts: (resources, models) => _replacementDraftProblem(
        read.catalog,
        management.editor,
        resources,
        models,
      ),
      synchronize: (commit) =>
          _publishWorkshopReplacement(read, replacement, commit),
      onRevision: onRevision,
      onPublished: onPublished,
      initialStatus:
          _modelReplacementStatus?.commit.sourceModelId == selected.id
          ? _modelReplacementStatus
          : null,
      onStatusChanged: (status) => _modelReplacementStatus = status,
      onBusyChanged: (busy) {
        onBusyChanged(busy);
        _updateView(() => _workshopBusy = busy);
      },
    );
  }

  Future<String> _prepareReplacementCatalog(
    _ProjectLibraryRead read,
    ProjectLibraryEditor editor,
  ) async {
    final maps = widget.maps;
    final reading = _reading;
    await _prepareResources(read, editor);
    final revision = read.revision!;
    if (maps.port case final ProjectResourceLibraryMapUsagesPort reader
        when mounted && reading == _reading && read.enriched == null) {
      final loading = _withUsages(
        reader,
        maps.session,
        ProjectResourceLibrary(
          read.catalog.metadata,
          read.catalog.entries.values.toList(growable: false),
        ),
        revision,
        read,
      );
      read.withUsages = loading;
      await loading;
    }
    return revision;
  }

  String? _replacementDraftProblem(
    ProjectLibraryCatalogView catalog,
    ProjectLibraryEditor editor,
    Set<ModelReplacementResource> resources,
    Set<String> models,
  ) {
    if (widget.maps.hasOpenMapWork([
      for (final resource in resources)
        if (resource.kind == 'map') resource.id,
    ])) {
      return 'Enregistrez ou fermez les cartes concernées avant ce remplacement.';
    }
    final identities = {
      for (final id in models) 'model3d:$id',
      for (final resource in resources)
        if (resource.kind == 'borderBlueprint')
          'borderBlueprint:${resource.id}',
    };
    final drafts = _draftDocuments().toList(growable: false);
    for (final identity in identities) {
      final item = catalog.entries[identity];
      if (item != null && editor.libraryDraftUses(item, drafts)) {
        return 'Une ressource concernée est utilisée dans un brouillon ouvert.';
      }
    }
    return null;
  }

  Future<void> _publishWorkshopReplacement(
    _ProjectLibraryRead read,
    ProjectModelReplacementPort replacement,
    ProjectModelReplacementCommit commit,
  ) async {
    final maps = widget.maps;
    final reading = _reading;
    final receipt = commit.receipt;
    await replacement.reconcile(commit);
    if (!mounted || !identical(maps, widget.maps)) return;
    if (receipt.changedModels.isNotEmpty) {
      final publish = widget.onModelWorkshopPublished;
      if (publish != null) {
        await publish(receipt);
      } else {
        maps.acceptResources(
          receipt.before,
          receipt.manifest,
          changedModels: receipt.changedModels,
        );
      }
    } else {
      await maps.acceptExternalMutation(commit.resources, reportFailure: true);
    }
    if (!mounted || reading != _reading) return;
    _updateView(() {
      read.revision = receipt.revision;
      _updateReplacementMapUsages(read, commit);
      read.previews.invalidate([
        for (final id in receipt.changedModels.keys) 'model3d:$id',
        for (final resource in commit.resources)
          if (resource.kind == 'borderBlueprint')
            'borderBlueprint:${resource.id}',
      ]);
    });
  }

  void _updateReplacementMapUsages(
    _ProjectLibraryRead read,
    ProjectModelReplacementCommit commit,
  ) {
    final target = commit.targetModelId;
    if (target == null) return;
    final projection = read.enriched;
    if (projection == null) {
      final reading = _reading;
      if (read.withUsages case final loading?) {
        unawaited(
          loading.then((_) {
            if (mounted && reading == _reading && read.enriched != null) {
              _updateView(() => _updateReplacementMapUsages(read, commit));
            }
          }),
        );
      }
      return;
    }
    final previous = _replacementUsageProjection;
    if (commit.restored) {
      if (previous?.entryId == commit.entryId) {
        projection.updateMapUsages(previous!.usages);
        _replacementUsageProjection = null;
      }
      return;
    }
    if (previous?.entryId == commit.entryId) return;
    final from = 'model3d:${commit.sourceModelId}';
    final to = 'model3d:$target';
    final sourceMaps = projection.item(from)?.usedOn ?? const <String>{};
    final targetMaps = projection.item(to)?.usedOn ?? const <String>{};
    _replacementUsageProjection = (
      entryId: commit.entryId,
      usages: {from: sourceMaps, to: targetMaps},
    );
    projection.updateMapUsages({
      from: sourceMaps.difference(commit.affectedMapIds),
      to: targetMaps.union(sourceMaps.intersection(commit.affectedMapIds)),
    });
  }
}
