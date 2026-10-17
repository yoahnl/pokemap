part of 'resource_library_screen.dart';

extension _ResourceLibraryHeader on _ResourceLibraryScreenState {
  Widget libraryHeader(BuildContext context, BoxConstraints bounds) {
    final compact = bounds.maxHeight < 650;
    return StudioPageHeader(
      title: state.atelierVisible ? state.family.label : 'Ressources',
      compact: compact,
      alignActionsToEnd: true,
      description: compact
          ? null
          : !state.atelierVisible
          ? 'Retrouvez vos ressources par famille et gérez leur disponibilité dans le projet.'
          : switch (state.family) {
              ResourceLibraryFamily.decors => 'Préparez les objets à placer, leur apparence et leurs collisions.',
              ResourceLibraryFamily.terrains => 'Définissez les raccords qui assemblent automatiquement le sol.',
              ResourceLibraryFamily.borders =>
                'Préparez les contours, puis tracez-les sur la carte.',
              ResourceLibraryFamily.environments =>
                'Composez une palette de décors à répartir dans une zone.',
              ResourceLibraryFamily.images =>
                'Importez et organisez les planches sources de vos ressources.',
              ResourceLibraryFamily.models3d => 'Importez vos modèles, vérifiez leur taille et explorez leurs animations.',
            },
      actions: compact
          ? [
              StudioButton(
                label: 'Actions',
                icon: Icons.more_horiz,
                secondary: true,
                onPressed: () => showWorkspaceCompactPanel(
                  context,
                  title: 'Actions des ressources',
                  closeLabel: 'Retour aux ressources',
                  builder: (context, refresh, close) => SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: libraryActions(
                        context,
                        close: close,
                        compact: true,
                      ),
                    ),
                  ),
                ),
              ),
            ]
          : libraryActions(context),
    );
  }

  List<Widget> libraryActions(
    BuildContext context, {
    VoidCallback? close,
    bool compact = false,
  }) {
    void run(VoidCallback action) {
      close?.call();
      action();
    }

    return [
      if (widget.onImportPack != null)
        StudioButton(key: const ValueKey('resource-import-pack'), label: 'Importer un pack…', icon: Icons.inventory_2_outlined, secondary: true, onPressed: () => run(widget.onImportPack!)),
      if (compact) ...[
        StudioButton(
          label: state.grid ? 'Mode liste' : 'Mode grille',
          icon: state.grid ? Icons.view_list_outlined : Icons.grid_view,
          secondary: true,
          onPressed: () => run(() => change(() => state.grid = !state.grid)),
        ),
        StudioButton(
          label: state.sort == ResourceSort.nameAscending
              ? 'Trier de Z à A'
              : 'Trier de A à Z',
          icon: Icons.sort_by_alpha,
          secondary: true,
          onPressed: () => run(
            () => change(
              () => state.sort = state.sort == ResourceSort.nameAscending
                  ? ResourceSort.nameDescending
                  : ResourceSort.nameAscending,
            ),
          ),
        ),
      ],
      if (widget.onManageFamilies != null)
        StudioButton(
          key: const ValueKey('resource-manage-families'),
          label: 'Gérer les familles',
          icon: Icons.create_new_folder_outlined,
          secondary: true,
          onPressed: () => run(widget.onManageFamilies!),
        ),
      StudioButton(
        key: const ValueKey('resource-family-chooser'),
        label: 'Ateliers',
        icon: Icons.handyman_outlined,
        secondary: true,
        onPressed: () => run(showAteliers),
      ),
      if (state.atelierVisible)
        StudioButton(
          key: const ValueKey('resource-all-resources'),
          label: 'Toutes les ressources',
          icon: Icons.apps,
          secondary: true,
          onPressed: () => run(() => changeNatureFamily('')),
        ),
      if (widget.onManageContainers != null &&
          state.atelierVisible &&
          state.family != ResourceLibraryFamily.borders &&
          state.family != ResourceLibraryFamily.models3d &&
          state.family != ResourceLibraryFamily.environments)
        StudioButton(
          key: const ValueKey('resource-manage-containers'),
          label: state.kind == ResourceKind.images
              ? 'Gérer les dossiers'
              : 'Gérer les catégories',
          icon: Icons.folder_outlined,
          secondary: true,
          onPressed: () => run(() => widget.onManageContainers!(state.kind)),
        ),
      if (!state.atelierVisible)
        StudioButton(
          key: const ValueKey('resource-import'),
          label: widget.project.settings.dimension == ProjectDimension.threeD
              ? 'Importer un modèle'
              : 'Importer une image',
          icon: Icons.file_upload_outlined,
          onPressed:
              widget.project.settings.dimension == ProjectDimension.threeD
              ? widget.onImportModel == null
                    ? null
                    : () => run(widget.onImportModel!)
              : () => run(widget.onImport),
        ),
      StudioButton(
        label: widget.targetMapName == null
            ? 'Retour à la carte'
            : 'Carte : ${widget.targetMapName}',
        icon: Icons.arrow_back,
        secondary: true,
        onPressed: () => run(widget.onBack),
      ),
      if (state.atelierVisible)
        StudioButton(
          key: const ValueKey('resource-create'),
          label: switch (state.family) {
            ResourceLibraryFamily.decors => 'Créer un décor',
            ResourceLibraryFamily.terrains => 'Créer un chemin',
            ResourceLibraryFamily.borders => 'Créer une bordure',
            ResourceLibraryFamily.environments => 'Créer un environnement',
            ResourceLibraryFamily.images => 'Importer une image',
            ResourceLibraryFamily.models3d => 'Importer un modèle GLB',
          },
          icon: Icons.add,
          onPressed: switch (state.family) {
            ResourceLibraryFamily.decors => () {
              close?.call();
              chooseResourceSource(
                context: context,
                project: widget.project,
                visuals: widget.visuals,
                onChosen: widget.onEdit,
                onImport: widget.onImport,
                decor: true,
              );
            },
            ResourceLibraryFamily.terrains => () {
              close?.call();
              chooseResourceSource(
                context: context,
                project: widget.project,
                visuals: widget.visuals,
                onChosen: widget.onTerrain,
                onImport:
                    widget.project.settings.dimension == ProjectDimension.threeD
                    ? widget.onImportModel
                    : widget.onImport,
              );
            },
            ResourceLibraryFamily.borders => () => run(widget.onCreateBorder),
            ResourceLibraryFamily.environments =>
              widget.onCreateEnvironment == null
                  ? null
                  : () => run(widget.onCreateEnvironment!),
            ResourceLibraryFamily.images => () => run(widget.onImport),
            ResourceLibraryFamily.models3d =>
              widget.onImportModel == null
                  ? null
                  : () => run(widget.onImportModel!),
          },
        ),
    ];
  }
}
