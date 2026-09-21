part of 'presentation_workspace_page.dart';

extension _PresentationLibraryActions on _PresentationWorkspacePageState {
  Future<String?> chooseTemplate() => showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choisir un modèle'),
      content: SizedBox(
        width: 450,
        height: 360,
        child: ListView(
          children: [
            for (final template
                in PresentationCinematicTemplateCatalog.canonical().templates)
              ListTile(
                title: Text(switch (template.id) {
                  'blank' => 'Composition vide',
                  'titleIdentity' => 'Titre et identité',
                  'immersiveOpening' => 'Ouverture immersive',
                  'stagedStory' => 'Histoire illustrée',
                  'interactivePath' => 'Parcours interactif',
                  'adaptiveVideo' => 'Vidéo adaptative',
                  _ => template.id,
                }),
                subtitle: Text(presentationTime(template.defaultDurationUs)),
                onTap: () => Navigator.pop(context, template.id),
              ),
          ],
        ),
      ),
      actions: [
        StudioButton(
          label: 'Annuler',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
  Future<void> documentMenu() async {
    if (!flush() || controller.active == null) return;
    final owner = controller.activeId!, revision = controller.active!.revision;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(controller.active!.asset.title),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in const {
                'settings': 'Durée et dossier',
                'duplicate': 'Dupliquer',
                'archive': 'Archiver',
                'reload': 'Abandonner le brouillon',
                'delete': 'Supprimer',
              }.entries)
                ListTile(
                  title: Text(entry.value),
                  onTap: () => Navigator.pop(context, entry.key),
                ),
            ],
          ),
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    if (!mounted ||
        choice == null ||
        controller.activeId != owner ||
        controller.active?.revision != revision) {
      return;
    }
    if (choice == 'settings') {
      await documentSettings(owner);
      return;
    }
    if (choice == 'duplicate') await controller.duplicate(owner);
    if (choice == 'archive') await controller.setArchived(owner, true);
    if (choice == 'reload') await controller.reload(owner);
    if (choice == 'delete' && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer cette présentation ?'),
          content: const Text(
            'Les présentations utilisées par une scène sont protégées.',
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
      if (mounted &&
          confirmed == true &&
          controller.activeId == owner &&
          controller.active?.revision == revision) {
        await controller.delete(owner);
      }
    }
    refresh();
  }
}
