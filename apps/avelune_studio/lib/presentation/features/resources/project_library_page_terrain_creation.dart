part of 'project_library_page.dart';

extension _ProjectLibraryPageTerrainCreation on _ProjectLibraryPageState {
  ResourceLibraryWorkshopAction? _terrainCreationAction(
    _ProjectLibraryRead read,
    ProjectLibraryManagement? management,
  ) {
    final revision = read.revision;
    final editor = management?.editor;
    if (revision == null || editor is! ProjectTerrainWorkshopPort) return null;
    final port = editor as ProjectTerrainWorkshopPort;
    if (!port.terrainConnectionEditingAvailable) return null;
    return (
      label: 'Nouveau terrain',
      icon: Icons.add,
      open: () => _createTerrain(read, port, management!, revision),
    );
  }

  Future<void> _createTerrain(
    _ProjectLibraryRead read,
    ProjectTerrainWorkshopPort port,
    ProjectLibraryManagement management,
    String revision,
  ) async {
    final reading = _reading;
    final maps = widget.maps;
    final dimension = maps.project?.settings.dimension;
    final templates =
        read.catalog.entries.values
            .where(
              (item) =>
                  item.kind == 'smartTilePreset' &&
                  item.mapId == null &&
                  (dimension == null ||
                      item.compatibleDimensions.isEmpty ||
                      item.compatibleDimensions.contains(dimension)),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    var importImage = false;
    var result = await showDialog<ProjectLibraryEditDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => ProjectTerrainCreationDialog(
        templates: templates,
        previews: read.previews,
        visuals: widget.visuals,
        publish: (draft) => _withWorkshopBusy(
          () => port.createTerrain(draft, expectedRevision: revision),
        ),
        reconcile: (receipt) =>
            _withWorkshopBusy(() => port.reconcileTerrainCreation(receipt)),
        importImage: port is ProjectTerrainImageWorkshopPort
            ? () {
                importImage = true;
                Navigator.of(dialog).pop();
              }
            : null,
      ),
    );
    if (importImage &&
        mounted &&
        _reading == reading &&
        port is ProjectTerrainImageWorkshopPort) {
      result = await _terrainFromImage(
        port as ProjectTerrainImageWorkshopPort,
        management,
        revision,
      );
    }
    if (!mounted || _reading != reading || result == null) return;
    if (result.edit case final edit?) {
      if (!_acceptLibraryReceipt(edit.receipt)) {
        _notice(
          'Le terrain est publié. La bibliothèque est en cours de relecture.',
        );
        _refresh();
        return;
      }
      _publish(read, edit, imported: true);
      if (widget.visuals case final ScopedResourcePreviewVisuals previews) {
        previews.invalidateResourcePreviews(edit.receipt.changedPaths.toSet());
      }
      _selectWorkshop(_ProjectWorkshopKind.terrains, edit.item.identity);
      _notice('Terrain publié.');
      if (maps.hasResourceKind(edit.item.kind, placeableOnly: true)) {
        try {
          await maps.ensureResourceClosure(
            edit.item.kind,
            edit.item.id,
            newlyPublished: true,
          );
        } on Object {
          if (mounted && identical(widget.maps, maps)) {
            _notice(
              'Le terrain est publié. Changez de catégorie, puis revenez à Terrains pour actualiser la palette.',
            );
          }
        }
      }
    } else if (result.partialReceipt != null) {
      _refresh();
    }
  }

  Future<ProjectLibraryEditDialogResult?> _terrainFromImage(
    ProjectTerrainImageWorkshopPort port,
    ProjectLibraryManagement management,
    String revision,
  ) async {
    final reading = _reading;
    final file = await _pickLibraryFile(management);
    if (!mounted || !widget.active || _reading != reading || file == null) {
      return null;
    }
    final size = file.imageSize;
    if (size == null) {
      _notice('Choisissez une planche PNG.');
      return null;
    }
    final settings = widget.maps.project?.settings;
    final tileSize =
        settings == null ||
            size.width % settings.tileWidth != 0 ||
            size.height % settings.tileHeight != 0
        ? size
        : (width: settings.tileWidth, height: settings.tileHeight);
    return showDialog<ProjectLibraryEditDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectLibraryEditDialog.importTerrain(
        file: file,
        defaultTileSize: tileSize,
        saveTerrain: (name, size, cell) => _withWorkshopBusy(
          () => port.createTerrainFromImage(
            file,
            name: name,
            tileSize: size,
            cell: cell,
            expectedRevision: revision,
          ),
        ),
      ),
    );
  }
}
