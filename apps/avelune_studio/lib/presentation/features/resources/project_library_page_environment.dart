part of 'project_library_page.dart';

extension _ProjectLibraryPageEnvironment on _ProjectLibraryPageState {
  ProjectEnvironmentWorkshopPort? _environmentEditor(
    _ProjectLibraryRead read,
    ProjectLibraryManagement? management,
  ) {
    final editor = management?.editor;
    if (read.revision == null || editor is! ProjectEnvironmentWorkshopPort) {
      return null;
    }
    final port = editor as ProjectEnvironmentWorkshopPort;
    return port.environmentEditingAvailable ? port : null;
  }

  ResourceLibraryWorkshopAction? _environmentCreationAction(
    _ProjectLibraryRead read,
    ProjectLibraryManagement? management,
  ) {
    final editor = _environmentEditor(read, management);
    if (editor == null) return null;
    return (
      label: 'Nouvel environnement',
      icon: Icons.add,
      open: () => _showEnvironmentEditor(read, editor),
    );
  }

  Widget _environmentWorkshop(
    _ProjectLibraryRead read,
    ProjectLibraryItem selected,
    MapWorkspaceVisuals? visuals,
    ProjectLibraryManagement? management,
    VoidCallback leave,
    Future<bool> Function(String)? openMap, {
    required bool loadingMapUsages,
  }) {
    final editor = _environmentEditor(read, management);
    final document = widget.maps.active;
    final mapId = document?.base.mapId;
    final dimension = document?.current.spatialScene == null
        ? ProjectDimension.twoD
        : ProjectDimension.threeD;
    final tryOnMap = widget.onUseEnvironment;
    final trial =
        mapId != null &&
        tryOnMap != null &&
        (selected.mapId == null || selected.mapId == mapId) &&
        selected.compatibleDimensions.contains(dimension) &&
        selected.role != ResourceLibraryRole.component;
    return ProjectEnvironmentWorkshop(
      key: ValueKey(selected.identity),
      id: selected.id,
      name: selected.name,
      load: () => _loadWorkshopProject(selected),
      onBack: leave,
      usages: _workshopMapUsages(read, selected.identity),
      loadingMapUsages: loadingMapUsages,
      paletteName: (entry) => _environmentPaletteName(read, entry),
      visuals: visuals,
      onOpenMap: openMap,
      onEdit: editor == null
          ? null
          : (preset) => _showEnvironmentEditor(read, editor, original: preset),
      trialMap: !trial ? null : document?.current.name,
      tryOnMap: !trial ? null : () => tryOnMap(mapId, selected.id),
    );
  }

  String _environmentPaletteName(
    _ProjectLibraryRead read,
    EnvironmentPaletteItem entry,
  ) =>
      read
          .catalog
          .entries['${entry.isSpatial ? 'model3d' : 'element'}:${entry.resourceId}']
          ?.name ??
      'Décor introuvable';

  Future<bool> _showEnvironmentEditor(
    _ProjectLibraryRead read,
    ProjectEnvironmentWorkshopPort editor, {
    EnvironmentPreset? original,
  }) async {
    final reading = _reading;
    final maps = widget.maps;
    final revision = read.revision!;
    final spatial =
        original?.isSpatial ??
        maps.project?.settings.dimension == ProjectDimension.threeD;
    final kind = spatial ? 'model3d' : 'element';
    final scope = original == null
        ? null
        : read.catalog.entries['environmentPreset:${original.id}']?.mapId;
    bool current() =>
        mounted && identical(_reading, reading) && identical(widget.maps, maps);
    final result = await showDialog<ProjectLibraryEditDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ProjectEnvironmentEditorDialog(
        original: original,
        spatial: spatial,
        paletteName: (entry) => _environmentPaletteName(read, entry),
        pick: (selected) => showDialog<ProjectLibraryItem>(
          context: dialogContext,
          builder: (_) => ProjectModelTargetDialog(
            models: read.catalog.entries.values.where(
              (item) =>
                  item.kind == kind &&
                  item.role != ResourceLibraryRole.component &&
                  (item.mapId == null || item.mapId == scope) &&
                  !selected.contains(item.id),
            ),
            familyLabels: read.catalog.familyLabels,
            title: 'Choisir un décor à répartir',
            confirmLabel: 'Ajouter au mélange',
            searchLabel: spatial
                ? 'Chercher un modèle 3D'
                : 'Chercher un décor 2D',
            emptyLabel: 'Aucun décor compatible trouvé',
            itemIcon: spatial
                ? Icons.view_in_ar_outlined
                : Icons.image_outlined,
          ),
        ),
        publish: (preset) => _withWorkshopBusy(
          () => editor.publishEnvironment(preset, expectedRevision: revision),
        ),
        reconcile: (preset, receipt) => _withWorkshopBusy(
          () => editor.reconcileEnvironment(preset, receipt),
        ),
      ),
    );
    if (!current() || result == null) return false;
    if (result.edit case final edit?) {
      final receipt = edit.receipt;
      if (!receipt.noChange && maps.project == receipt.before) {
        maps.acceptResources(
          receipt.before,
          receipt.manifest,
          changedEnvironment: findProjectEnvironmentPresetById(
            receipt.manifest,
            edit.item.id,
          ),
        );
      } else if (maps.project != receipt.manifest) {
        _notice(
          'L’environnement est enregistré. La bibliothèque doit être relue.',
        );
        _refresh();
        return false;
      }
      read.previews.invalidate([edit.item.identity]);
      _publish(read, edit, imported: original == null);
      _selectWorkshop(_ProjectWorkshopKind.environments, edit.item.identity);
      return true;
    }
    if (result.partialReceipt != null) _refresh();
    return false;
  }
}
