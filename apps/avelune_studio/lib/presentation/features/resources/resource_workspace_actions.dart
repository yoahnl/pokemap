part of 'resource_workspace_pane.dart';

extension ResourceWorkspaceActions on ResourceWorkspacePane {
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

  Future<void> import(BuildContext context) async {
    try {
      final image = await picker();
      if (image == null || !context.mounted) return;
      final settings = navigation.workspace.project!.settings;
      final request = await confirmImageImport(
        context,
        image,
        settings.tileWidth,
        settings.tileHeight,
      );
      if (request != null) await navigation.import(request);
    } catch (e) {
      navigation.error = e.toString();
      navigation.showLibrary();
    }
  }

  Future<void> importCharacterSheet(BuildContext context) async {
    final image = await picker();
    if (image == null || !context.mounted) return;
    final n = navigation;
    if (image.width % 3 != 0 || image.height % 4 != 0) {
      n.setImportError(
        'La planche doit contenir 3 colonnes et 4 rangées de même taille.',
      );
      return;
    }
    final settings = n.workspace.project!.settings;
    final poseWidth = image.width ~/ 3;
    final poseHeight = image.height ~/ 4;
    if (poseWidth % settings.tileWidth != 0 ||
        poseHeight % settings.tileHeight != 0 ||
        poseWidth < settings.tileWidth * 2 ||
        poseHeight < settings.tileHeight * 2) {
      n.setImportError(
        'Chaque pose doit occuper au moins deux cases par axe et un nombre entier de cases '
        '(${settings.tileWidth} × ${settings.tileHeight} px).',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer une planche de personnage'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: Image.memory(
                  image.bytes,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${image.width} × ${image.height} px · '
                '3 poses × 4 directions · '
                '${image.width ~/ 3} × ${image.height ~/ 4} px par pose',
              ),
              const SizedBox(height: 8),
              const Text(
                'Un nouveau personnage sera créé. '
                'Les personnages et brouillons existants restent intacts.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    n.error = null;
    n.setImportBusy(true);
    try {
      final receipt = await n.port.importImage(
        ResourceImageImport(
          sourcePath: image.path,
          name: image.name,
          tileWidth: image.width ~/ 3,
          tileHeight: image.height ~/ 4,
        ),
      );
      await n.accept(receipt);
      final tilesetId = receipt.createdTilesetId!;
      if (!await n.characters.create(
        image.name,
        tilesetId,
        frameWidth: poseWidth ~/ settings.tileWidth,
        frameHeight: poseHeight ~/ settings.tileHeight,
      )) {
        n.error =
            'La planche est dans Images, mais le personnage n’a pas été '
            'créé : ${n.characters.error}';
      } else {
        final source = n.workspace.project!.tilesets
            .firstWhere((entry) => entry.id == tilesetId)
            .source;
        if (source is ProjectRegularAtlasTilesetSource) {
          n.characters.assignClassicSheet(source);
        }
        n.openCharacters();
      }
    } catch (failure) {
      n.error = '$failure';
    } finally {
      n.setImportBusy(false);
    }
  }
}
