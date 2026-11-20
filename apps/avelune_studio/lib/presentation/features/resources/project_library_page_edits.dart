part of 'project_library_page.dart';

extension _ProjectLibraryPageEdits on _ProjectLibraryPageState {
  Future<void> _importFile(
    BuildContext context,
    _ProjectLibraryRead read,
    ProjectLibraryManagement management,
  ) async {
    if (_pickingFile) return;
    final reading = _reading;
    final revision = read.revision!;
    _setPickingFile(true);
    PickedProjectLibraryFile? picked;
    try {
      picked = await management.pickFile();
    } on Object catch (error) {
      if (mounted) {
        _notice(
          error is ResourceFailure ? error.message : 'Impossible d’ouvrir ce fichier. Choisissez un fichier PNG ou GLB accessible.',
        );
      }
    } finally {
      if (mounted) _setPickingFile(false);
    }
    final file = picked;
    if (!mounted ||
        !context.mounted ||
        !widget.active ||
        file == null ||
        _reading != reading) {
      return;
    }
    final settings = widget.maps.project?.settings;
    await _showEdit(
      context,
      read,
      ProjectLibraryEditDialog.importFile(
        file: file,
        defaultTileSize: settings == null
            ? null
            : (width: settings.tileWidth, height: settings.tileHeight),
        saveName: (name, size) => management.editor.importResource(
          file,
          name: name,
          tileSize: size,
          expectedRevision: revision,
        ),
      ),
      imported: true,
    );
  }

  Future<ResourceLibraryItemView?> _rename(
    BuildContext context,
    _ProjectLibraryRead read,
    ProjectLibraryEditor editor,
    String id,
  ) {
    final item = read.catalog.entries[id]!;
    final revision = read.revision!;
    return _showEdit(
      context,
      read,
      ProjectLibraryEditDialog.rename(
        item: item,
        saveName: (name, _) =>
            editor.renameResource(item, name: name, expectedRevision: revision),
      ),
    );
  }

  Future<ResourceLibraryItemView?> _classify(
    BuildContext context,
    _ProjectLibraryRead read,
    ProjectLibraryEditor editor,
    String id,
  ) {
    final item = read.catalog.entries[id]!;
    final revision = read.revision!;
    return _showEdit(
      context,
      read,
      ProjectLibraryEditDialog.classify(
        item: item,
        families: read.catalog.familyLabels,
        saveClassification: (family, role) => editor.classifyResource(
          item,
          familyId: family,
          role: role,
          expectedRevision: revision,
        ),
      ),
    );
  }

  Future<ResourceLibraryItemView?> _showEdit(
    BuildContext context,
    _ProjectLibraryRead read,
    ProjectLibraryEditDialog dialog, {
    bool imported = false,
  }) async {
    final reading = _reading;
    final result = await showDialog<ProjectLibraryEditDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );
    if (!mounted || _reading != reading || result == null) return null;
    final publication = result.edit?.receipt ?? result.partialReceipt;
    if (widget.visuals case final ScopedResourcePreviewVisuals previews
        when imported && publication != null) {
      previews.invalidateResourcePreviews(publication.changedPaths.toSet());
    }
    if (result.edit case final edit?) {
      if (!_acceptLibraryReceipt(edit.receipt)) {
        _notice(
          'La modification est enregistrée. La bibliothèque est en cours de relecture.',
        );
        _refresh();
        return null;
      }
      return _publish(read, edit, imported: imported);
    }
    if (result.partialReceipt != null) _refresh();
    return null;
  }

  bool _acceptLibraryReceipt(ResourceMutationReceipt receipt) {
    final maps = widget.maps;
    try {
      if (maps.project == receipt.before &&
          (receipt.manifest != receipt.before ||
              receipt.removedLibraryResource != null)) {
        maps.acceptResources(
          receipt.before,
          receipt.manifest,
          removedLibraryResource: receipt.removedLibraryResource,
        );
      } else if (maps.project != receipt.manifest &&
          receipt.manifest != receipt.before) {
        return false;
      }
      return true;
    } on Object {
      return false;
    }
  }

  void _notice(String message) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
}
