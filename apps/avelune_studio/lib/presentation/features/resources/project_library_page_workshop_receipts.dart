part of 'project_library_page.dart';

extension _ProjectLibraryPageWorkshopReceipts on _ProjectLibraryPageState {
  ProjectCharacterEditor? _characterWorkshopEditor(
    _ProjectLibraryRead read,
    ProjectLibraryItem item,
    ProjectLibraryManagement? management,
  ) {
    final editor = management?.editor;
    final maps = widget.maps;
    if (editor is! ProjectCharacterWorkshopPort ||
        management == null ||
        maps.session.storage != ProjectSessionStorage.workingCatalog) {
      return null;
    }
    return (
      port: editor as ProjectCharacterWorkshopPort,
      pickImage: management.pickFile,
      pending: _workshopReceipts[item.identity],
      retain: (receipt) => _retainWorkshopReceipt(maps, item.identity, receipt),
      publish: (receipt) {
        if (!mounted || !identical(maps, widget.maps)) {
          throw const ResourceFailure('Le projet a été fermé.');
        }
        if (receipt.noChange) return;
        if (maps.project == receipt.before) {
          maps.acceptResources(receipt.before, receipt.manifest);
        } else if (maps.project != receipt.manifest) {
          throw const ResourceFailure(
            'La bibliothèque n’a pas pu relire le personnage.',
          );
        }
        if (widget.visuals case final ScopedResourcePreviewVisuals previews) {
          previews.invalidateResourcePreviews(receipt.changedPaths.toSet());
        }
        _updateView(() {
          if (read.revision == receipt.beforeRevision) {
            read.revision = receipt.revision;
          }
          read.previews.invalidate([item.identity]);
        });
      },
    );
  }

  void _retainWorkshopReceipt(
    MapWorkspaceController maps,
    String identity,
    ResourceMutationReceipt? receipt,
  ) {
    if (!mounted || !identical(maps, widget.maps)) return;
    if (receipt == null) {
      _workshopReceipts.remove(identity);
    } else {
      _workshopReceipts[identity] = receipt;
    }
  }

  Future<T> _withWorkshopBusy<T>(Future<T> Function() action) async {
    final maps = widget.maps;
    _updateView(() => _workshopBusy = true);
    try {
      return await action();
    } finally {
      if (mounted && identical(maps, widget.maps)) {
        _updateView(() => _workshopBusy = false);
      }
    }
  }

  Future<ResourceMutationReceipt> _publishWorkshopGrid(
    _ProjectLibraryRead read,
    Future<ResourceMutationReceipt> Function() write,
  ) => _withWorkshopBusy(() async {
    final reading = _reading;
    final receipt = await write();
    if (mounted && identical(reading, _reading) && !receipt.noChange) {
      _updateView(() {
        if (read.revision == receipt.beforeRevision) {
          read.revision = receipt.revision;
        }
      });
    }
    return receipt;
  });

  void _publishWorkshopBorder(
    _ProjectLibraryRead read,
    ProjectLibraryItem selected,
    ResourceMutationReceipt receipt,
  ) {
    if (receipt.noChange) return;
    final border = receipt.manifest.borderCatalog.recordById(selected.id)!;
    final maps = widget.maps;
    if (maps.project == receipt.before) {
      maps.acceptResources(
        receipt.before,
        receipt.manifest,
        changedBorder: receipt.actionId == 'border.blueprint.publish'
            ? border
            : null,
      );
    } else if (maps.project != receipt.manifest) {
      throw const ResourceFailure(
        'La bibliothèque n’a pas pu relire l’enregistrement.',
      );
    }
    _updateView(() {
      if (read.revision == receipt.beforeRevision) {
        read.revision = receipt.revision;
      }
      read.previews.invalidate([selected.identity]);
      final name = border.draft.definition.name;
      if (name == selected.name) return;
      final item = ProjectLibraryItem(
        kind: selected.kind,
        id: selected.id,
        name: name,
        familyId: selected.familyId,
        mapId: selected.mapId,
        description: selected.description,
        category: selected.category,
        placementContext: selected.placementContext,
        role: selected.role,
        compatibleDimensions: selected.compatibleDimensions,
      );
      read.catalog.upsert(item);
      read.enriched?.upsert(item);
    });
  }
}
