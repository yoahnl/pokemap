part of 'resource_navigation.dart';

extension ResourceNavigationLifecycle on ResourceNavigation {
  Future<ResourceReplacementPreview> prepareReplacement(
    ResourceReplacementRequest request,
  ) async {
    final problem = _managementProblem('tileset.source.replace', {
      'tilesetId': request.tilesetId,
    });
    if (problem != null) throw ResourceFailure(problem);
    if (port case final ResourceLifecyclePreparationPort lifecycle) {
      return lifecycle.prepareReplacement(request);
    }
    throw const ResourceFailure('Le remplacement est indisponible.');
  }

  Future<void> releasePreparation(
    ResourceMutationPreparation preparation,
  ) async {
    if (port case final ResourceLifecyclePreparationPort lifecycle) {
      await lifecycle.releasePreparation(preparation);
    }
  }

  DecorDraft? decorDraftFor(String id) =>
      decors.values.where((draft) => draft.original?.id == id).firstOrNull;

  Future<bool> saveDecorOwner(String id) async {
    if (busy || _disposed) return false;
    final draft = decorDraftFor(id);
    if (draft == null) return true;
    busy = true;
    changed();
    try {
      final current = workspace.project!.elements
          .where((element) => element.id == id)
          .firstOrNull;
      if (current != draft.original) {
        throw const ResourceFailure(
          'Ce décor a changé depuis son ouverture. La préparation est conservée.',
        );
      }
      final snapshot = draft.build();
      final revision = await captureResourceRevision();
      final preparation = await _preparationPort.prepareOperation(
        'element.upsert',
        {'element': snapshot.toJson()},
        expectedSnapshotRevision: revision,
      );
      final receipt = await _preparationPort.applyPrepared(
        preparation,
        confirmDestructive: preparation.confirmationRequired,
        validateBeforeApply: () =>
            workspace.project?.elements
                    .where((element) => element.id == id)
                    .firstOrNull !=
                draft.original
            ? 'Ce décor a changé. La préparation est conservée.'
            : null,
      );
      await accept(receipt);
      draft.rebase(snapshot);
      if (draft.build() == snapshot) discardDecorOwner(id);
      error = null;
      return decorDraftFor(id) == null;
    } on Object catch (failure) {
      if (failure is ResourceFailure && failure.partialReceipt != null) {
        _retainDecorPublication(draft, id, failure);
      }
      error = '$failure';
      return false;
    } finally {
      busy = false;
      changed();
    }
  }

  void discardDecorOwner(String id) {
    final draft = decorDraftFor(id);
    if (draft == null) return;
    decors.removeWhere((_, value) => identical(value, draft));
    if (identical(decor, draft)) {
      decor = null;
      page = ResourcePage.library;
    }
    changed();
  }

  List<String> lifecycleDraftOwners(String action, ResourceItem item) =>
      _lifecycleDraftOwners(action, {
        if (item.kind == ResourceKind.images) 'tilesetId': item.id,
        if (item.kind == ResourceKind.decors) 'elementId': item.id,
      });

  List<String> _lifecycleDraftOwners(
    String action,
    Map<String, Object?> parameters,
  ) {
    final tilesetId = parameters['tilesetId'];
    final elementId = parameters['elementId'] ?? parameters['sourceElementId'];
    final source = workspace.project!.tilesets
        .where((t) => t.id == tilesetId)
        .firstOrNull
        ?.source;
    final assetId = source is ProjectRegularAtlasTilesetSource
        ? source.assetId
        : null;
    final elements = workspace.project!.elements
        .where(
          (e) =>
              e.id == elementId ||
              (tilesetId != null &&
                  (e.tilesetId == tilesetId ||
                      e.frames.any((f) => f.tilesetId == tilesetId))),
        )
        .map((e) => e.id)
        .toSet();
    return [
      for (final document in workspace.documents.values)
        if (document.dirty &&
            (document.current.placedElements.any(
                  (e) => elements.contains(e.elementId),
                ) ||
                (tilesetId != null &&
                    (document.current.tilesetId == tilesetId ||
                        document.current.layers.whereType<TileLayer>().any(
                          (l) => l.palette.any(
                            (tile) => tile.tilesetId == tilesetId,
                          ),
                        )))))
          'Carte · ${document.current.name}',
      for (final draft in decors.values)
        if (draft.original?.id == elementId ||
            (tilesetId != null &&
                (draft.tileset.id == tilesetId ||
                    draft
                        .build(validateName: false)
                        .frames
                        .any((frame) => frame.tilesetId == tilesetId))))
          'Décor · ${draft.name}',
      for (final draft in terrains.values)
        if (draft.dirty &&
            tilesetId != null &&
            draft.draft.atlases.any((atlas) => atlas.tilesetId == tilesetId))
          'Terrain · ${draft.draft.name}',
      for (final draft in environments.values)
        if (draft.dirty &&
            draft.palette.any((item) => elements.contains(item.elementId)))
          'Environnement · ${draft.name}',
      for (final character in characters.dirtyCharacters)
        if (tilesetId != null &&
            (character.tilesetId == tilesetId ||
                (assetId != null &&
                    (character.animations.any(
                          (clip) => clip.sourceAssetId == assetId,
                        ) ||
                        character.customAnimations.any(
                          (clip) => clip.sourceAssetId == assetId,
                        )))))
          'Personnage · ${character.name}',
      ...?additionalDraftOwners?.call(),
    ];
  }

  void _validateDecorOwner(DecorDraft? draft) {
    final original = draft?.original;
    if (original == null) return;
    final current = workspace.project?.elements
        .where((element) => element.id == original.id)
        .firstOrNull;
    if (current != original) {
      throw const ResourceFailure(
        'Ce décor a changé ou a été supprimé. Votre préparation est conservée.',
      );
    }
  }
}
