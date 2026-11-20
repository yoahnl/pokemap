part of 'project_library_page.dart';

extension _ProjectLibraryPageWorkshops on _ProjectLibraryPageState {
  ResourceLibraryWorkshopAction? _workshopAction(
    _ProjectLibraryRead read,
    String identity,
  ) {
    final resourceKind = read.catalog.entries[identity]?.kind;
    final workshop = _ProjectWorkshopKind.values
        .where((option) => option.resourceKind == resourceKind)
        .firstOrNull;
    if (workshop == null) return null;
    return (
      label: workshop.actionLabel,
      icon: workshop.icon,
      open: () => _selectWorkshop(workshop, identity),
    );
  }

  void _selectWorkshop(_ProjectWorkshopKind kind, [String? identity]) =>
      _updateView(() {
        _workshopKind = kind;
        _workshopEntry = identity;
      });

  Widget _workshops(
    _ProjectLibraryRead read,
    MapWorkspaceVisuals? visuals,
    ProjectLibraryManagement? management,
    VoidCallback back,
    Future<bool> Function(String)? openMap, {
    required bool loadingMapUsages,
  }) {
    final selected = read.catalog.entries[_workshopEntry];
    if (selected == null) {
      return _ProjectWorkshopPicker(
        key: ValueKey(_workshopKind),
        catalog: read.catalog,
        workshop: _workshopKind,
        onWorkshop: _selectWorkshop,
        onSelected: (identity) => _selectWorkshop(_workshopKind, identity),
      );
    }
    void leave() {
      _selectWorkshop(_workshopKind);
      back();
    }

    final rename = management == null || read.revision == null
        ? null
        : () => _withWorkshopBusy(() async {
            await _rename(context, read, management.editor, selected.identity);
          });

    return switch (_workshopKind) {
      _ProjectWorkshopKind.models => _modelWorkshop(
        read,
        selected,
        visuals,
        management,
        leave,
      ),
      _ProjectWorkshopKind.tilesets => ProjectTilesetWorkshop(
        key: ValueKey(selected.identity),
        item: selected,
        previews: read.previews,
        visuals: visuals,
        usages: _workshopMapUsages(read, selected.identity),
        onOpenMap: openMap,
        onBack: leave,
        gridEditor: _tilesetGridEditor(read, selected, management?.editor),
      ),
      _ProjectWorkshopKind.borders => _borderWorkshop(
        read,
        selected,
        management?.editor,
        visuals,
        leave,
      ),
      _ProjectWorkshopKind.characters => ProjectCharacterWorkshop(
        key: ValueKey(selected.identity),
        item: selected,
        previews: read.previews,
        visuals: visuals,
        active: widget.active,
        onBack: leave,
        onRename: rename,
      ),
      _ProjectWorkshopKind.terrains => ProjectTerrainWorkshop(
        key: ValueKey(selected.identity),
        item: selected,
        previews: read.previews,
        visuals: visuals,
        usages: _workshopMapUsages(read, selected.identity),
        loadingMapUsages: loadingMapUsages,
        onOpenMap: openMap,
        onBack: leave,
        onRename: rename,
      ),
    };
  }

  Map<String, String>? _workshopMapUsages(
    _ProjectLibraryRead read,
    String identity,
  ) {
    final mapIds = read.enriched?.item(identity)?.usedOn;
    if (mapIds == null) return null;
    return {
      for (final map in widget.maps.project?.maps ?? const <ProjectMapEntry>[])
        if (mapIds.contains(map.id)) map.id: map.name,
    };
  }

  Future<ProjectManifest> _loadWorkshopProject(ProjectLibraryItem entry) async {
    final maps = widget.maps;
    final port = maps.port;
    if (maps.hasCompleteProject) return maps.project!;
    if (port case final ProjectResourcePreviewPort reader) {
      return reader.readResourcePreview(maps.session, entry.kind, entry.id);
    }
    throw StateError('Lecteur d’aperçu indisponible.');
  }

  ProjectTilesetGridEditor? _tilesetGridEditor(
    _ProjectLibraryRead read,
    ProjectLibraryItem selected,
    ProjectLibraryEditor? editor,
  ) {
    final revision = read.revision;
    if (revision == null || editor is! ProjectTilesetWorkshopPort) return null;
    final port = editor as ProjectTilesetWorkshopPort;
    if (!port.tilesetGridEditingAvailable) return null;
    final maps = widget.maps;
    return (
      revision: revision,
      pendingReceipt: _workshopReceipts[selected.identity],
      onPendingReceiptChanged: (receipt) =>
          _retainWorkshopReceipt(maps, selected.identity, receipt),
      prepareCatalog: () =>
          _withWorkshopBusy(() => _prepareReplacementCatalog(read, editor!)),
      save: (size, expected) => _publishWorkshopGrid(
        read,
        () => port.saveTilesetGrid(
          selected,
          tileSize: size,
          expectedRevision: expected,
          validateBeforeApply: () {
            if (!mounted || !identical(maps, widget.maps)) {
              return 'Le projet a été fermé.';
            }
            return editor!.libraryDraftUses(selected, _draftDocuments())
                ? 'Cette planche est utilisée dans un brouillon ouvert.'
                : null;
          },
        ),
      ),
      reconcile: (receipt) => _publishWorkshopGrid(read, () async {
        await port.reconcileTilesetGrid(receipt);
        return receipt;
      }),
    );
  }

  Widget _borderWorkshop(
    _ProjectLibraryRead read,
    ProjectLibraryItem selected,
    ProjectLibraryEditor? editor,
    MapWorkspaceVisuals? visuals,
    VoidCallback back,
  ) {
    final maps = widget.maps;
    bool current() => mounted && identical(maps, widget.maps);
    return ProjectBorderWorkshop(
      key: ValueKey(selected.identity),
      item: selected,
      loadProject: () => _loadWorkshopProject(selected),
      visuals: visuals,
      editor: editor is ProjectBorderWorkshopPort
          ? editor as ProjectBorderWorkshopPort
          : null,
      pendingReceipt: _workshopReceipts[selected.identity],
      onPendingReceiptChanged: (receipt) =>
          _retainWorkshopReceipt(maps, selected.identity, receipt),
      onBusyChanged: (busy) {
        if (current()) _updateView(() => _workshopBusy = busy);
      },
      onDraftChanged: (dirty) {
        if (current() && _workshopHasDraft != dirty) {
          _updateView(() => _workshopHasDraft = dirty);
        }
      },
      onUpdated: (receipt) async {
        if (current()) _publishWorkshopBorder(read, selected, receipt);
      },
      onBack: back,
    );
  }

  Widget _modelWorkshop(
    _ProjectLibraryRead read,
    ProjectLibraryItem selected,
    MapWorkspaceVisuals? visuals,
    ProjectLibraryManagement? management,
    VoidCallback back,
  ) {
    final editor = management?.editor;
    final workshop = editor is ProjectModelWorkshopPort
        ? editor as ProjectModelWorkshopPort
        : null;
    return ProjectModelWorkshop(
      key: ValueKey(selected.identity),
      item: selected,
      visuals: visuals,
      loadModel: () => workshop == null
          ? _readWorkshopModel(selected.id)
          : workshop.readWorkshopModel(selected.id),
      saveShadow: workshop == null
          ? null
          : (enabled, revision) => _publishWorkshopShadow(
              read,
              selected.id,
              () => workshop.saveModelShadow(
                selected.id,
                castsShadows: enabled,
                expectedRevision: revision,
              ),
            ),
      reconcileShadow: workshop == null
          ? null
          : (receipt) => _publishWorkshopShadow(read, selected.id, () async {
              await workshop.reconcileModelShadow(receipt);
              return receipt;
            }),
      pendingReceipt: _workshopReceipts[selected.id],
      buildReplacement: _modelReplacementBuilder(
        read,
        selected,
        management,
        visuals,
      ),
      onBack: back,
    );
  }

  Future<ProjectModelWorkshopRead> _readWorkshopModel(String id) async {
    final maps = widget.maps;
    final port = maps.port;
    final project =
        !maps.hasCompleteProject && port is ProjectResourcePreviewPort
        ? await (port as ProjectResourcePreviewPort).readResourcePreview(
            maps.session,
            'model3d',
            id,
          )
        : maps.project;
    return (
      model: switch (project?.models3d) {
        final ProjectModel3dEntries entries => entries.lookup(id),
        final entries? => entries.where((model) => model.id == id).firstOrNull,
        null => null,
      },
      revision: null,
    );
  }

  Future<ResourceMutationReceipt> _publishWorkshopShadow(
    _ProjectLibraryRead read,
    String modelId,
    Future<ResourceMutationReceipt> Function() write,
  ) async {
    final reading = _reading;
    final maps = widget.maps;
    bool current() => mounted && identical(maps, widget.maps);
    _updateView(() => _workshopBusy = true);
    try {
      final receipt = await write();
      if (!current()) return receipt;
      if (!receipt.noChange) {
        try {
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
        } on Object {
          throw ResourceFailure(
            'La bibliothèque n’a pas pu relire l’enregistrement.',
            partialReceipt: receipt,
          );
        }
      }
      if (current()) {
        _workshopReceipts.remove(modelId);
        if (_reading == reading && read.revision == receipt.beforeRevision) {
          read.revision = receipt.revision;
        }
      }
      return receipt;
    } on ResourceFailure catch (failure) {
      if (failure.partialReceipt case final pending? when current()) {
        _workshopReceipts[modelId] = pending;
      }
      rethrow;
    } finally {
      if (current()) _updateView(() => _workshopBusy = false);
    }
  }
}
