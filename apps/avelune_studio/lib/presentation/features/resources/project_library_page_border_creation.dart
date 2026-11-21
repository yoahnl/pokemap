part of 'project_library_page.dart';

extension _ProjectLibraryPageBorderCreation on _ProjectLibraryPageState {
  ResourceLibraryWorkshopAction? _borderCreationAction(
    _ProjectLibraryRead read,
    ProjectLibraryManagement? management,
  ) {
    final editor = management?.editor;
    final revision = read.revision;
    if (_workshopBusy ||
        revision == null ||
        widget.maps.project?.settings.dimension != ProjectDimension.threeD ||
        editor is! ProjectBorderWorkshopPort) {
      return null;
    }
    final port = editor as ProjectBorderWorkshopPort;
    if (!port.canEditBorderWorkshop) return null;
    return (
      label: 'Nouvelle bordure',
      icon: Icons.add,
      open: () => _createWorkshopBorder(read, port, revision),
    );
  }

  Future<void> _createWorkshopBorder(
    _ProjectLibraryRead read,
    ProjectBorderWorkshopPort port,
    String revision,
  ) async {
    final reading = _reading;
    final result = await showDialog<ProjectLibraryEditDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectBorderCreationDialog(
        models: [
          for (final item in read.catalog.entries.values)
            if (item.kind == 'model3d' &&
                item.mapId == null &&
                item.compatibleDimensions.contains(ProjectDimension.threeD))
              item,
        ],
        familyLabels: read.catalog.familyLabels,
        save: (request) => _withWorkshopBusy(
          () => port.createWorkshopBorder(request, expectedRevision: revision),
        ),
      ),
    );
    if (!mounted || _reading != reading || result == null) return;
    if (result.edit case final edit?) {
      if (!_acceptLibraryReceipt(edit.receipt)) {
        _refresh();
        return;
      }
      _publish(read, edit, imported: true);
      _selectWorkshop(_ProjectWorkshopKind.borders, edit.item.identity);
    } else if (result.partialReceipt != null) {
      _refresh();
    }
  }
}
