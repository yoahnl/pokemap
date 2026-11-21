part of 'project_library_page.dart';

extension _ProjectLibraryPageModelWorkshop on _ProjectLibraryPageState {
  Widget _modelWorkshop(
    _ProjectLibraryRead read,
    ProjectLibraryItem selected,
    MapWorkspaceVisuals? visuals,
    ProjectLibraryManagement? management,
    VoidCallback back,
  ) {
    final editor = management?.editor;
    final workshop = editor is ProjectModelWorkshopPort
        ? editor as ProjectModelWorkshopPort
        : null;
    return ProjectModelWorkshop(
      key: ValueKey(selected.identity),
      item: selected,
      visuals: visuals,
      loadModel: () => workshop == null
          ? _readWorkshopModel(selected.id)
          : workshop.readWorkshopModel(selected.id),
      saveShadow: workshop == null
          ? null
          : (enabled, revision) => _publishModelWorkshop(
              read,
              selected.id,
              () => workshop.saveModelShadow(
                selected.id,
                castsShadows: enabled,
                expectedRevision: revision,
              ),
            ),
      saveSettings:
          workshop == null ||
              widget.maps.session.storage !=
                  ProjectSessionStorage.workingCatalog
          ? null
          : (settings, revision) => _publishModelWorkshop(
              read,
              selected.id,
              () => workshop.saveModelSettings(
                selected.id,
                settings: settings,
                expectedRevision: revision,
              ),
            ),
      reconcileShadow: workshop == null
          ? null
          : (receipt) => _publishModelWorkshop(read, selected.id, () async {
              await workshop.reconcileModelShadow(receipt);
              return receipt;
            }),
      pendingReceipt: _workshopReceipts[selected.id],
      buildReplacement: _modelReplacementBuilder(
        read,
        selected,
        management,
        visuals,
      ),
      onBack: back,
      onDraftChanged: (value) => _updateView(() => _workshopHasDraft = value),
    );
  }

  Future<ProjectModelWorkshopRead> _readWorkshopModel(String id) async {
    final maps = widget.maps;
    final port = maps.port;
    final project =
        !maps.hasCompleteProject && port is ProjectResourcePreviewPort
        ? await (port as ProjectResourcePreviewPort).readResourcePreview(
            maps.session,
            'model3d',
            id,
          )
        : maps.project;
    return (
      model: switch (project?.models3d) {
        final ProjectModel3dEntries entries => entries.lookup(id),
        final entries? => entries.where((model) => model.id == id).firstOrNull,
        null => null,
      },
      revision: null,
    );
  }

  Future<ResourceMutationReceipt> _publishModelWorkshop(
    _ProjectLibraryRead read,
    String modelId,
    Future<ResourceMutationReceipt> Function() write,
  ) async {
    final reading = _reading;
    final maps = widget.maps;
    bool current() => mounted && identical(maps, widget.maps);
    _updateView(() => _workshopBusy = true);
    try {
      final receipt = await write();
      if (!current()) return receipt;
      if (!receipt.noChange) {
        try {
          final publish = widget.onModelWorkshopPublished;
          if (publish != null) {
            await publish(receipt);
          } else {
            maps.acceptResources(
              receipt.before,
              receipt.manifest,
              changedModels: receipt.changedModels,
            );
          }
        } on Object {
          throw ResourceFailure(
            'La bibliothèque n’a pas pu relire l’enregistrement.',
            partialReceipt: receipt,
          );
        }
      }
      if (current()) {
        _workshopReceipts.remove(modelId);
        if (_reading == reading && read.revision == receipt.beforeRevision) {
          read.revision = receipt.revision;
        }
      }
      return receipt;
    } on ResourceFailure catch (failure) {
      if (failure.partialReceipt case final pending? when current()) {
        _workshopReceipts[modelId] = pending;
      }
      rethrow;
    } finally {
      if (current()) _updateView(() => _workshopBusy = false);
    }
  }
}
