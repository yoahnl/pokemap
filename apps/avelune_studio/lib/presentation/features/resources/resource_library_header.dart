part of 'resource_library_screen.dart';

extension _ResourceLibraryHeader on _ResourceLibraryScreenState {
  Widget libraryHeader(BuildContext context, BoxConstraints bounds) {
    final compact = bounds.maxHeight < 650;
    return StudioPageHeader(
      title: 'Ressources',
      alignActionsToEnd: true,
      description: compact
          ? null
          : 'Vos décors, terrains et images, prêts à donner vie à la carte.',
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
      if (widget.onManageContainers != null)
        StudioButton(
          key: const ValueKey('resource-manage-containers'),
          label: state.kind == ResourceKind.images
              ? 'Gérer les dossiers'
              : 'Gérer les catégories',
          icon: Icons.folder_outlined,
          secondary: true,
          onPressed: () => run(() => widget.onManageContainers!(state.kind)),
        ),
      ...resourceCreationButtons(
        context: context,
        project: widget.project,
        visuals: widget.visuals,
        onCreateBorder: () => run(widget.onCreateBorder),
        onCreatePath: (item) => run(() => widget.onTerrain(item)),
        onImport: () => run(widget.onImport),
        onCharacters: widget.onCharacters == null
            ? null
            : () => run(widget.onCharacters!),
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
        label: 'Importer une image',
        icon: Icons.add_photo_alternate_outlined,
        onPressed: () => run(widget.onImport),
      ),
    ];
  }
}
