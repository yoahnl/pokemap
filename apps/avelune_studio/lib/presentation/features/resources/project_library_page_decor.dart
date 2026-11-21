part of 'project_library_page.dart';

extension _ProjectLibraryPageDecor on _ProjectLibraryPageState {
  ProjectDecorWorkshopPort? _decorPort(ProjectLibraryManagement? management) {
    final editor = management?.editor;
    return editor is ProjectDecorWorkshopPort
        ? editor as ProjectDecorWorkshopPort
        : null;
  }

  ResourceLibraryWorkshopAction? _decorCreationAction(
    _ProjectLibraryRead read,
    ProjectLibraryManagement? management,
  ) {
    final port = _decorPort(management);
    if (port?.decorEditingAvailable != true || read.revision == null) {
      return null;
    }
    return (
      label: 'Nouveau décor 2D',
      icon: Icons.add,
      open: () => _chooseDecorSource(read, port!),
    );
  }

  Future<void> _chooseDecorSource(
    _ProjectLibraryRead read,
    ProjectDecorWorkshopPort port,
  ) async {
    final reading = _reading;
    final maps = widget.maps;
    bool current() =>
        mounted && identical(_reading, reading) && identical(maps, widget.maps);
    final source = await showDialog<ProjectLibraryItem>(
      context: context,
      builder: (_) => ProjectModelTargetDialog(
        models: read.catalog.entries.values.where(
          (item) => item.kind == 'tileset',
        ),
        familyLabels: read.catalog.familyLabels,
        title: 'Choisir la planche du décor',
        confirmLabel: 'Utiliser cette planche',
        searchLabel: 'Chercher une planche',
        emptyLabel: 'Importez une planche depuis la bibliothèque.',
        itemIcon: Icons.image_outlined,
      ),
    );
    if (!current() || source == null) return;
    final ProjectDecorWorkshopRead loading;
    try {
      loading = await _withWorkshopBusy(
        () => port.readWorkshopDecor(source.kind, source.id),
      );
    } on Object {
      if (current()) _notice('La planche du décor est indisponible.');
      return;
    }
    if (!current()) return;
    await _showDecorEditor(read, port, loading, source.id);
  }

  Widget _decorWorkshop(
    _ProjectLibraryRead read,
    ProjectLibraryItem item,
    ProjectLibraryManagement? management,
    MapWorkspaceVisuals? visuals,
    VoidCallback leave,
  ) {
    final port = _decorPort(management);
    return ProjectDecorWorkshop(
      key: ValueKey(item.identity),
      id: item.id,
      load: () async => port != null
          ? await port.readWorkshopDecor(item.kind, item.id)
          : (
              project: await _loadWorkshopProject(item),
              revision: read.revision ?? '',
            ),
      visuals: visuals,
      onBack: leave,
      edit: port?.decorEditingAvailable != true
          ? null
          : (loaded) {
              final original = loaded.project.elements.singleWhere(
                (element) => element.id == item.id,
              );
              return _showDecorEditor(
                read,
                port!,
                loaded,
                original.tilesetId,
                original: original,
              );
            },
    );
  }

  Future<bool> _showDecorEditor(
    _ProjectLibraryRead read,
    ProjectDecorWorkshopPort port,
    ProjectDecorWorkshopRead loaded,
    String tilesetId, {
    ProjectElementEntry? original,
  }) async {
    final project = loaded.project;
    final tileset = project.tilesets
        .where((value) => value.id == tilesetId)
        .firstOrNull;
    final problem = decorWorkshopProblem(project, tileset, original);
    if (problem != null || tileset == null) {
      _notice(problem ?? 'La planche est indisponible.');
      return false;
    }
    if (original == null && project.elementCategories.isEmpty) {
      _notice(
        'Ce projet doit avoir une catégorie de décors pour publier un décor.',
      );
      return false;
    }
    final reading = _reading;
    final maps = widget.maps;
    bool current() =>
        mounted && identical(_reading, reading) && identical(maps, widget.maps);
    final result = await showDialog<ProjectLibraryEditDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectDecorEditorDialog(
        project: project,
        tileset: tileset,
        original: original,
        visuals: widget.visuals,
        publish: (decor) => _withWorkshopBusy(
          () => port.publishDecor(decor, expectedRevision: loaded.revision),
        ),
        reconcile: (receipt) =>
            _withWorkshopBusy(() => port.reconcileDecor(receipt)),
      ),
    );
    if (!current() || result == null) return false;
    if (result.edit case final edit?) {
      if (!_acceptLibraryReceipt(edit.receipt)) {
        _notice('Le décor est enregistré. La bibliothèque doit être relue.');
        _refresh();
        return false;
      }
      _publish(read, edit, imported: original == null);
      _selectWorkshop(_ProjectWorkshopKind.decors, edit.item.identity);
      if (original == null &&
          maps.hasResourceKind(edit.item.kind, placeableOnly: true)) {
        try {
          await maps.ensureResourceClosure(
            edit.item.kind,
            edit.item.id,
            newlyPublished: true,
          );
        } on Object {
          if (current()) {
            _notice('Le décor est publié. Relisez la palette de la carte.');
          }
        }
      }
      return true;
    }
    if (result.partialReceipt != null) _refresh();
    return false;
  }
}
