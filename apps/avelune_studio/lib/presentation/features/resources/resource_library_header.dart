part of 'resource_library_screen.dart';

extension _ResourceLibraryHeader on _ResourceLibraryScreenState {
  Widget libraryHeader(BuildContext context, BoxConstraints bounds) {
    final compact = bounds.maxHeight < 650;
    return StudioPageHeader(
      title: state.family.label,
      alignActionsToEnd: true,
      description: compact
          ? null
          : switch (state.family) {
              ResourceLibraryFamily.decors =>
                'Préparez les objets à placer, leur apparence et leurs collisions.',
              ResourceLibraryFamily.terrains =>
                'Définissez les raccords qui assemblent automatiquement le sol.',
              ResourceLibraryFamily.borders =>
                'Préparez les contours, puis tracez-les sur la carte.',
              ResourceLibraryFamily.environments =>
                'Composez une palette de décors à répartir dans une zone.',
              ResourceLibraryFamily.images =>
                'Importez et organisez les planches sources de vos ressources.',
              ResourceLibraryFamily.models3d =>
                'Importez vos modèles, vérifiez leur taille et explorez leurs animations.',
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
                      children: libraryActions(context, close: close),
                    ),
                  ),
                ),
              ),
            ]
          : libraryActions(context),
    );
  }

  List<Widget> libraryActions(BuildContext context, {VoidCallback? close}) {
    void run(VoidCallback action) {
      close?.call();
      action();
    }

    return [
      if (widget.onManageContainers != null &&
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
      StudioButton(
        label: widget.targetMapName == null
            ? 'Retour à la carte'
            : 'Carte : ${widget.targetMapName}',
        icon: Icons.arrow_back,
        secondary: true,
        onPressed: () => run(widget.onBack),
      ),
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
              onImport: widget.onImport,
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
