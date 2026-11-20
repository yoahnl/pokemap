part of 'project_library_page.dart';

extension _ProjectLibraryPageLifecycle on _ProjectLibraryPageState {
  Future<ResourceLibraryItemView?> _modify(
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
      ProjectLibraryEditDialog.details(
        item: item,
        saveDetails: (description, placement) => editor.modifyLibraryResource(
          item,
          description: description,
          placementContext: placement,
          expectedRevision: revision,
        ),
      ),
    );
  }

  Future<ResourceLibraryItemView?> _duplicate(
    BuildContext context,
    _ProjectLibraryRead read,
    ProjectLibraryEditor editor,
    String id,
  ) {
    final item = read.catalog.entries[id]!;
    return _showEdit(
      context,
      read,
      ProjectLibraryEditDialog.rename(
        item: item,
        duplicate: true,
        prepareCatalog: () => _prepareResources(read, editor),
        saveName: (name, _) => editor.duplicateLibraryResource(
          item,
          name: name,
          expectedRevision: read.revision!,
        ),
      ),
      imported: true,
    );
  }

  Future<bool> _delete(
    BuildContext context,
    _ProjectLibraryRead read,
    ProjectLibraryEditor editor,
    String id,
  ) async {
    final item = read.catalog.entries[id]!;
    final reading = _reading;
    String? draftProblem() => editor.libraryDraftUses(item, _draftDocuments())
        ? 'Cette ressource est utilisée dans un brouillon de carte ouvert.'
        : null;
    final result = await showDialog<ProjectLibraryDeleteResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectLibraryDeleteDialog(
        name: item.name,
        prepare: () async {
          if (draftProblem() case final problem?) {
            throw ResourceFailure(problem);
          }
          return editor.prepareLibraryDeletion(
            item,
            expectedRevision: read.revision!,
          );
        },
        prepareCatalog: () => _prepareResources(read, editor),
        remove: (plan) => editor.applyPrepared(
          plan,
          confirmDestructive: true,
          validateBeforeApply: draftProblem,
        ),
        release: editor.releasePreparation,
      ),
    );
    if (!mounted || _reading != reading || result == null) return false;
    if (result.reload || !_acceptLibraryReceipt(result.receipt)) {
      _refresh();
    } else {
      _removeEntry(read, id, result.receipt.revision);
    }
    _notice('La fiche « ${item.name} » a été supprimée.');
    return true;
  }

  Iterable<Map<String, Object?>> _draftDocuments() sync* {
    for (final document in widget.maps.documents.values) {
      if (document.dirty) yield document.current.toJson();
      if (document.exteriorDecoration case final decoration?
          when decoration.dirty) {
        if (decoration.current case final current?) yield current.toJson();
      }
    }
  }

  Future<void> _prepareResources(
    _ProjectLibraryRead read,
    ProjectLibraryEditor editor,
  ) async {
    final receipt = await editor.prepareResourceIndexes(
      expectedSnapshotRevision: read.revision!,
    );
    read.revision = receipt.revision;
  }
}
