part of 'resource_navigation.dart';

extension ResourceNavigationEnvironment on ResourceNavigation {
  void openEnvironment([EnvironmentPreset? preset]) {
    if (_disposed || workspace.isDisposed || busy) return;
    final draft = preset == null
        ? EnvironmentDraft()
        : environments.putIfAbsent(
            preset.id,
            () => EnvironmentDraft(original: preset),
          );
    environments[draft.id] = draft;
    environment = draft;
    page = ResourcePage.environment;
    changed();
  }

  void duplicateEnvironment(EnvironmentPreset preset) {
    if (_disposed || workspace.isDisposed || busy) return;
    final draft = EnvironmentDraft.copy(preset);
    environments[draft.id] = draft;
    environment = draft;
    page = ResourcePage.environment;
    changed();
  }

  Future<void> saveEnvironment() async {
    final draft = environment;
    if (draft == null || busy || _disposed || workspace.isDisposed) return;
    busy = true;
    changed();
    try {
      await _saveEnvironment(draft);
      if (identical(environment, draft) && !draft.dirty) {
        environment = null;
        library.selectFamily(ResourceLibraryFamily.environments);
        showLibrary();
      }
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
      rethrow;
    } finally {
      busy = false;
      changed();
    }
  }

  Future<void> _saveEnvironment(EnvironmentDraft draft) async {
    final current = workspace.project?.environmentPresets
        .where((preset) => preset.id == draft.id)
        .firstOrNull;
    if (current != draft.original) {
      throw const ResourceFailure(
        'Cet environnement a changé. Votre préparation est conservée.',
      );
    }
    final saved = draft.build();
    final revision = await captureResourceRevision();
    final preparation = await prepareOperation('environment.preset.upsert', {
      'preset': encodeEnvironmentPreset(saved),
    }, expectedSnapshotRevision: revision);
    try {
      final receipt = await _preparationPort.applyPrepared(
        preparation,
        validateBeforeApply: () => _disposed || workspace.isDisposed
            ? 'Le projet a été fermé.'
            : workspace.project?.environmentPresets
                      .where((preset) => preset.id == draft.id)
                      .firstOrNull !=
                  draft.original
            ? 'L’environnement a changé.'
            : null,
      );
      await accept(receipt);
    } on ResourceFailure catch (failure) {
      final receipt = failure.partialReceipt;
      if (receipt != null) {
        pendingReceipt = receipt;
        final published = receipt.manifest.environmentPresets
            .where((preset) => preset.id == saved.id)
            .firstOrNull;
        if (published != null) draft.rebase(published);
      }
      rethrow;
    }
    draft.rebase(saved);
    if (!draft.dirty) environments.remove(draft.id);
    error = null;
  }

  Future<void> removeEnvironment(EnvironmentPreset preset) async {
    if (environments[preset.id]?.dirty == true) {
      throw const ResourceFailure(
        'Enregistrez ou annulez la préparation de cet environnement.',
      );
    }
    final owners = workspace.documents.values
        .where(
          (document) =>
              document.dirty &&
              document.current.layers.whereType<EnvironmentLayer>().any(
                (layer) => layer.content.areas.any(
                  (area) => area.presetId == preset.id,
                ),
              ),
        )
        .toList();
    if (owners.isNotEmpty) {
      throw ResourceFailure(
        'Cet environnement est utilisé par une carte non enregistrée : ${owners.map((document) => document.current.name).join(', ')}.',
      );
    }
    final preparation = await prepareOperation('environment.preset.delete', {
      'presetId': preset.id,
    });
    await applyPrepared(preparation, confirmDestructive: true);
    environments.remove(preset.id);
    if (environment?.id == preset.id) environment = null;
  }

  void discardEnvironment() {
    final draft = environment;
    if (draft == null) return;
    environments.remove(draft.id);
    environment = null;
    library.selectFamily(ResourceLibraryFamily.environments);
    showLibrary();
  }
}
