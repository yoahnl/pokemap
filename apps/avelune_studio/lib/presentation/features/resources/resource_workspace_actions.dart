part of 'resource_workspace_pane.dart';

extension ResourceWorkspaceActions on ResourceWorkspacePane {
  Future<void> exportPack(
    BuildContext context, {
    List<ResourceItem> selection = const [],
  }) async {
    final transfer = navigation.packTransfer;
    if (transfer == null || navigation.busy || !transfer.exportAvailable) {
      return;
    }
    await showResourcePackExport(
      context,
      transfer,
      projectName: navigation.workspace.project!.name,
      selection: [
        for (final item in selection) (kind: item.canonicalKind, id: item.id),
      ],
    );
  }

  Future<void> importPack(BuildContext context) async {
    final transfer = navigation.packTransfer;
    if (transfer == null || navigation.busy) return;
    await showResourcePackImport(
      context,
      transfer,
      onShowImported: () {
        final imported = transfer.firstImported;
        if (imported == null || navigation.isDisposed) return;
        if (imported.kind == 'character') {
          navigation.openCharacters(imported.id);
          return;
        }
        final item = resourceCatalog(navigation.workspace.project!)
            .where(
              (item) =>
                  item.canonicalKind == imported.kind && item.id == imported.id,
            )
            .firstOrNull;
        navigation.library.atelierVisible = false;
        navigation.showLibrary(item);
      },
    );
  }

  Future<void> removeEnvironment(
    BuildContext context,
    EnvironmentPreset preset,
  ) async {
    final n = navigation;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet environnement ?'),
        content: Text(
          'Retirer « ${preset.name} » de la bibliothèque. Les décors restent conservés. Une carte qui utilise cet environnement empêchera son retrait.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            label: 'Supprimer',
            variant: StudioButtonVariant.destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted || n.isDisposed) return;
    try {
      await n.removeEnvironment(preset);
    } on Object catch (failure) {
      n.setImportError('$failure');
    }
  }

  Future<void> import(
    BuildContext context, {
    ResourceImportIntent intent = ResourceImportIntent.source,
  }) async {
    try {
      final image = await picker();
      if (image == null || !context.mounted) return;
      final project = navigation.workspace.project!;
      final settings = project.settings;
      final request = await confirmImageImport(
        context,
        image,
        settings.tileWidth,
        settings.tileHeight,
        existingNames: {for (final tileset in project.tilesets) tileset.name},
        intent: intent,
      );
      if (request != null) await navigation.import(request, intent: intent);
    } catch (e) {
      navigation.error = e.toString();
      navigation.showLibrary();
    }
  }
}
