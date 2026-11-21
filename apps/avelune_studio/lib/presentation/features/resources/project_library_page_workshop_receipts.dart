part of 'project_library_page.dart';

extension _ProjectLibraryPageWorkshopReceipts on _ProjectLibraryPageState {
  ProjectTerrainWorkshopEditor? _terrainWorkshopEditor(
    _ProjectLibraryRead read,
    ProjectLibraryItem item,
    ProjectLibraryEditor? editor,
  ) {
    final revision = read.revision;
    if (revision == null || editor is! ProjectTerrainWorkshopPort) return null;
    final port = editor as ProjectTerrainWorkshopPort;
    if (!port.terrainConnectionEditingAvailable) return null;
    final maps = widget.maps;
    Future<ResourceMutationReceipt> accept(
      Future<ResourceMutationReceipt> Function() write,
    ) => _withWorkshopBusy(() async {
      final receipt = await write();
      final terrain = receipt.changedTerrain;
      if (terrain == null || receipt.noChange) return receipt;
      try {
        if (!mounted || !identical(maps, widget.maps)) {
          throw const ResourceFailure('Le projet a été fermé.');
        }
        if (maps.project == receipt.before) {
          maps.acceptResources(
            receipt.before,
            receipt.manifest,
            changedTerrain: terrain,
          );
        } else if (maps.project != receipt.manifest) {
          throw const ResourceFailure('La bibliothèque a changé.');
        }
        _updateView(() {
          if (read.revision == receipt.beforeRevision) {
            read.revision = receipt.revision;
          }
        });
      } on Object {
        throw ResourceFailure(
          'Les raccords sont enregistrés. Relisez la publication pour les afficher.',
          partialReceipt: receipt,
        );
      }
      return receipt;
    });

    return (
      revision: revision,
      pendingReceipt: _workshopReceipts[item.identity],
      onPendingReceiptChanged: (receipt) =>
          _retainWorkshopReceipt(maps, item.identity, receipt),
      publish: (preset, expectedRevision) => accept(
        () => port.publishTerrainConnections(
          preset,
          expectedRevision: expectedRevision,
        ),
      ),
      reconcile: (receipt) async {
        await accept(() async {
          await port.reconcileTerrainConnections(receipt);
          return receipt;
        });
      },
    );
  }

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
      resolveSpatialModel: (context, modelId) =>
          _resolveCharacterSpatialModel(context, read, modelId),
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

  Future<ProjectModel3dEntry?> _resolveCharacterSpatialModel(
    BuildContext context,
    _ProjectLibraryRead read,
    String? modelId,
  ) async {
    final reading = _reading;
    final selected = modelId != null
        ? read.catalog.entries['model3d:$modelId']
        : await showDialog<ProjectLibraryItem>(
            context: context,
            builder: (context) => ProjectModelTargetDialog(
              models: read.catalog.entries.values.where(
                (item) => item.kind == 'model3d',
              ),
              familyLabels: read.catalog.familyLabels,
              title: 'Choisir le modèle du personnage',
              confirmLabel: 'Choisir ce modèle',
              emptyLabel: 'Aucun modèle 3D trouvé',
            ),
          );
    if (!mounted || !identical(reading, _reading)) return null;
    if (selected == null) {
      if (modelId == null) return null;
      throw const ResourceFailure('Le modèle associé est introuvable.');
    }
    final lease = read.previews.acquire(selected);
    try {
      final preview = await lease.result;
      if (!mounted || !identical(reading, _reading)) return null;
      final model = preview?.item.model3d;
      if (model == null) {
        throw const ResourceFailure('Le modèle est introuvable.');
      }
      if (!model.inspection.skinned || model.inspection.animations.isEmpty) {
        throw ResourceFailure(
          '« ${model.name} » doit contenir un squelette et au moins un clip.',
        );
      }
      return model;
    } finally {
      lease.release();
    }
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
