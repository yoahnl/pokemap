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
        createAction: switch (_workshopKind) {
          _ProjectWorkshopKind.borders => _borderCreationAction(read, management),
          _ProjectWorkshopKind.terrains => _terrainCreationAction(read, management),
          _ProjectWorkshopKind.environments => _environmentCreationAction(read, management),
          _ProjectWorkshopKind.decors => _decorCreationAction(read, management),
          _ => null,
        },
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
        editor: _characterWorkshopEditor(read, selected, management),
        onBusyChanged: (busy) => _updateView(() => _workshopBusy = busy),
        onDraftChanged: (dirty) => _updateView(() => _workshopHasDraft = dirty),
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
        editor: _terrainWorkshopEditor(read, selected, management?.editor),
      ),
      _ProjectWorkshopKind.environments => _environmentWorkshop(
        read,
        selected,
        visuals,
        management,
        leave,
        openMap,
        loadingMapUsages: loadingMapUsages,
      ),
      _ProjectWorkshopKind.decors => _decorWorkshop(
        read,
        selected,
        management,
        visuals,
        leave,
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

}
