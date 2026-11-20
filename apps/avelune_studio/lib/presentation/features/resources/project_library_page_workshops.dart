part of 'project_library_page.dart';

extension _ProjectLibraryPageWorkshops on _ProjectLibraryPageState {
  VoidCallback? _modelWorkshopAction(
    _ProjectLibraryRead read,
    String identity,
  ) {
    if (read.catalog.entries[identity]?.kind != 'model3d') return null;
    return () => _showModelWorkshop(identity);
  }

  void _showModelWorkshop(String? identity) =>
      _updateView(() => _workshopModel = identity);

  Widget _workshops(
    _ProjectLibraryRead read,
    MapWorkspaceVisuals? visuals,
    ProjectLibraryManagement? management,
    VoidCallback back,
  ) {
    final selected = read.catalog.entries[_workshopModel];
    if (selected == null) {
      return _ModelWorkshopPicker(
        catalog: read.catalog,
        onSelected: _showModelWorkshop,
      );
    }
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
          : (enabled, revision) => _publishWorkshopShadow(
              read,
              selected.id,
              () => workshop.saveModelShadow(
                selected.id,
                castsShadows: enabled,
                expectedRevision: revision,
              ),
            ),
      reconcileShadow: workshop == null
          ? null
          : (receipt) => _publishWorkshopShadow(read, selected.id, () async {
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
      onBack: () {
        _showModelWorkshop(null);
        back();
      },
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

  Future<ResourceMutationReceipt> _publishWorkshopShadow(
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

class _ModelWorkshopPicker extends StatefulWidget {
  const _ModelWorkshopPicker({required this.catalog, required this.onSelected});

  final ProjectLibraryCatalogView catalog;
  final ValueChanged<String> onSelected;

  @override
  State<_ModelWorkshopPicker> createState() => _ModelWorkshopPickerState();
}

class _ModelWorkshopPickerState extends State<_ModelWorkshopPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = studioSearchText(_search.text).trim();
    final models = [
      for (final item in widget.catalog.entries.values)
        if (item.kind == 'model3d' && item.searchText.contains(query)) item,
    ];
    return Padding(
      padding: const EdgeInsets.all(StudioSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ateliers', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: StudioSpacing.xl),
          Text('Modèles 3D', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: StudioSpacing.l),
          StudioSearchField(
            key: const ValueKey('library-workshop-model-search'),
            label: 'Chercher un modèle 3D',
            controller: _search,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: StudioSpacing.l),
          Expanded(
            child: models.isEmpty
                ? StudioEmptyState(
                    title: query.isEmpty
                        ? 'Aucun modèle 3D'
                        : 'Aucun modèle trouvé',
                    description: query.isEmpty
                        ? 'Importez un modèle GLB dans la bibliothèque.'
                        : 'Essayez un autre nom de modèle.',
                  )
                : ListView.builder(
                    itemCount: models.length,
                    itemBuilder: (context, index) {
                      final model = models[index];
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: StudioButton(
                          key: ValueKey('library-workshop-${model.identity}'),
                          label: model.name,
                          icon: Icons.view_in_ar_outlined,
                          variant: StudioButtonVariant.quiet,
                          onPressed: () => widget.onSelected(model.identity),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
