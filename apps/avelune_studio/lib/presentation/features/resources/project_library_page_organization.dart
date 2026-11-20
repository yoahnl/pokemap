part of 'project_library_page.dart';

extension _ProjectLibraryPageOrganization on _ProjectLibraryPageState {
  Future<void> _manageFamilies(
    BuildContext context,
    _ProjectLibraryRead read,
    ProjectLibraryOrganization organization,
  ) async {
    final reading = _reading;
    final editor = widget.management!.editor;
    final result =
        await showDialog<
          ProjectLibraryOrganizationDialogResult<ProjectLibraryFamilyEdit>
        >(
          context: context,
          barrierDismissible: false,
          builder: (_) => ProjectLibraryFamiliesDialog(
            families: read.catalog.metadata.families,
            familyLabels: read.catalog.familyLabels,
            saveFamily: (existing, name, parentId) =>
                organization.saveLibraryFamily(
                  existing: existing,
                  name: name,
                  parentId: parentId,
                  expectedRevision: read.revision!,
                ),
            deleteFamily: (family) => organization.deleteLibraryFamily(
              family,
              expectedRevision: read.revision!,
            ),
            prepareCatalog: () => _prepareResources(read, editor),
          ),
        );
    if (!mounted || _reading != reading || result == null) return;
    final edit = result.edit;
    if (edit == null) {
      if (result.partialReceipt != null) _refresh();
      return;
    }
    if (!_acceptOrganizationReceipt(read, edit.receipt)) return;
    _updateView(() {
      read.catalog.updateFamily(edit.id, edit.family);
      read.enriched?.updateFamily(edit.id, edit.family);
    });
    _notice(
      edit.family == null ? 'Famille supprimée.' : 'Famille enregistrée.',
    );
  }

  Future<void> _classifySelection(
    BuildContext context,
    _ProjectLibraryRead read,
    ProjectLibraryOrganization organization,
    Set<String> identities,
  ) async {
    final items = [for (final id in identities) ?read.catalog.entries[id]];
    if (items.isEmpty || items.length != identities.length) {
      _notice('La sélection a changé. Vérifiez les ressources sélectionnées.');
      return;
    }
    final reading = _reading;
    final editor = widget.management!.editor;
    final result =
        await showDialog<
          ProjectLibraryOrganizationDialogResult<ProjectLibraryBatchEdit>
        >(
          context: context,
          barrierDismissible: false,
          builder: (_) => ProjectLibraryBatchClassifyDialog(
            selectionCount: items.length,
            familyLabels: read.catalog.familyLabels,
            save: (family, role) => organization.classifyLibraryResources(
              items,
              family: family,
              role: role,
              expectedRevision: read.revision!,
            ),
            prepareCatalog: () => _prepareResources(read, editor),
          ),
        );
    if (!mounted || _reading != reading || result == null) return;
    final edit = result.edit;
    if (edit == null) {
      if (result.partialReceipt != null) _refresh();
      return;
    }
    if (!_acceptOrganizationReceipt(read, edit.receipt)) return;
    _updateView(() {
      for (final item in edit.items) {
        read.catalog.upsert(item);
        read.enriched?.upsert(item);
      }
    });
    _notice('Classement enregistré.');
  }

  bool _acceptOrganizationReceipt(
    _ProjectLibraryRead read,
    ResourceMutationReceipt receipt,
  ) {
    if (!_acceptLibraryReceipt(receipt)) {
      _notice('La modification est enregistrée. Relecture du catalogue…');
      _refresh();
      return false;
    }
    read.revision = receipt.revision;
    return true;
  }
}
