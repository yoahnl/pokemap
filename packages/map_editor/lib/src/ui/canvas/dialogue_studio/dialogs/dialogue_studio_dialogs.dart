part of 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';

extension _DialogueStudioWorkspaceDialogs on _DialogueStudioWorkspaceState {
  // Dialogues / menus du studio dialogue :
  // on les sort du shell principal pour que le workspace garde surtout
  // l'assemblage des colonnes et la logique de document.

  Future<void> _openStudioDialogueFolderMenu(
    BuildContext hostContext,
    ProjectManifest project,
    EditorNotifier notifier,
    ProjectDialogueFolder folder, {
    required Offset anchorGlobal,
  }) async {
    final action = await showMacosEditorContextMenu<String>(
      context: hostContext,
      globalPosition: anchorGlobal,
      actions: const [
        MacosEditorSheetAction(label: 'Renommer le dossier', value: 'rename'),
        MacosEditorSheetAction(label: 'Nouveau sous-dossier', value: 'sub'),
        MacosEditorSheetAction(label: 'Déplacer le dossier…', value: 'move'),
        MacosEditorSheetAction(
          label: 'Supprimer le dossier',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );
    if (!hostContext.mounted || action == null) return;
    switch (action) {
      case 'rename':
        await _promptRenameDialogueFolder(hostContext, notifier, folder);
      case 'sub':
        await _promptNewFolder(hostContext, notifier,
            parentFolderId: folder.id);
      case 'move':
        await _pickMoveDialogueLibraryFolder(
          hostContext,
          project,
          notifier,
          folder.id,
        );
      case 'delete':
        final ok = await showMacosEditorTwoChoiceAlert(
          hostContext,
          title: 'Supprimer le dossier ?',
          message:
              'Les dialogues qu’il contient doivent être déplacés ailleurs avant suppression.',
          primaryLabel: 'Supprimer',
          primaryIsDestructive: true,
        );
        if (ok && hostContext.mounted) {
          await notifier.deleteDialogueLibraryFolder(folder.id);
        }
    }
  }

  Future<void> _openStudioDialogueEntryMenu(
    BuildContext hostContext,
    ProjectManifest project,
    EditorNotifier notifier,
    ProjectDialogueEntry entry,
    Offset anchor,
  ) async {
    final inFolder =
        entry.folderId != null && entry.folderId!.trim().isNotEmpty;
    final action = await showMacosEditorContextMenu<String>(
      context: hostContext,
      globalPosition: anchor,
      actions: [
        const MacosEditorSheetAction(label: 'Renommer', value: 'rename'),
        const MacosEditorSheetAction(
          label: 'Déplacer vers un dossier…',
          value: 'move',
        ),
        if (inFolder)
          const MacosEditorSheetAction(
            label: 'Mettre à la racine',
            value: 'root',
          ),
      ],
    );
    if (!hostContext.mounted || action == null) return;
    switch (action) {
      case 'rename':
        await _promptRename(hostContext, notifier, entry);
      case 'move':
        await _promptMoveDialogueToFolder(
            hostContext, notifier, project, entry);
      case 'root':
        await notifier.moveDialogueToLibraryRoot(entry.id);
    }
  }

  Future<void> _promptRenameDialogueFolder(
    BuildContext context,
    EditorNotifier notifier,
    ProjectDialogueFolder folder,
  ) async {
    final c = TextEditingController(text: folder.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Renommer le dossier',
      controller: c,
      confirmLabel: 'Enregistrer',
      placeholder: 'Nom',
      compact: true,
    );
    if (!ok || !context.mounted) return;
    final name = c.text.trim();
    if (name.isEmpty) return;
    await notifier.renameDialogueLibraryFolder(folderId: folder.id, name: name);
  }

  Future<void> _pickMoveDialogueLibraryFolder(
    BuildContext context,
    ProjectManifest project,
    EditorNotifier notifier,
    String folderId,
  ) async {
    final blocked = dialogueFolderSubtreeIds(project, folderId);
    final options = <_DialogueFolderMoveOption>[
      const _DialogueFolderMoveOption('Racine des dossiers', null),
    ];
    for (final row in flattenDialogueFoldersForPicker(project)) {
      if (row.id == folderId) continue;
      if (blocked.contains(row.id)) continue;
      options.add(_DialogueFolderMoveOption(row.label, row.id));
    }
    final picked = await showCupertinoListPicker<_DialogueFolderMoveOption>(
      context: context,
      title: 'Déplacer le dossier vers…',
      items: options,
      labelOf: (o) => o.label,
    );
    if (picked == null || !context.mounted) return;
    await notifier.moveDialogueLibraryFolder(
      folderId: folderId,
      newParentFolderId: picked.newParentId,
    );
  }

  Future<void> _promptMoveDialogueToFolder(
    BuildContext context,
    EditorNotifier notifier,
    ProjectManifest project,
    ProjectDialogueEntry entry,
  ) async {
    final options = <_AssignDialogueFolderDest>[
      const _AssignDialogueFolderDest('Racine (hors dossier)', null),
      ...flattenDialogueFoldersForPicker(project)
          .map((r) => _AssignDialogueFolderDest(r.label, r.id)),
    ];
    final picked = await showCupertinoListPicker<_AssignDialogueFolderDest>(
      context: context,
      title: 'Ranger le dialogue dans…',
      items: options,
      labelOf: (o) => o.label,
    );
    if (picked == null || !context.mounted) return;
    if (picked.folderId == null) {
      await notifier.moveDialogueToLibraryRoot(entry.id);
    } else {
      await notifier.assignDialogueToLibraryFolder(
        dialogueId: entry.id,
        folderId: picked.folderId!,
      );
    }
  }

  Future<void> _save(EditorNotifier notifier, String dialogueId) async {
    if (_doc == null) return;
    final yarn = emitDocumentToYarn(_doc!);
    await notifier.saveProjectDialogueYarnBody(
      dialogueId: dialogueId,
      yarnBody: yarn,
    );
  }

  Future<void> _promptNewDialogue(
      BuildContext context, EditorNotifier n) async {
    final c = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Nouveau dialogue',
      controller: c,
      confirmLabel: 'Créer',
      placeholder: 'Nom affiché',
    );
    if (!ok || !context.mounted) return;
    final name = c.text.trim();
    if (name.isEmpty) return;
    await n.createProjectDialogue(name: name, folderId: _sidebarTargetFolderId);
    n.selectDialogueWorkspace();
  }

  Future<void> _promptNewFolder(
    BuildContext context,
    EditorNotifier n, {
    String? parentFolderId,
  }) async {
    final c = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title:
          parentFolderId == null ? 'Nouveau dossier' : 'Nouveau sous-dossier',
      controller: c,
      confirmLabel: 'Créer',
      placeholder: 'Nom du dossier',
    );
    if (!ok || !context.mounted) return;
    final name = c.text.trim();
    if (name.isEmpty) return;
    await n.createDialogueLibraryFolder(
      name: name,
      parentFolderId: parentFolderId ?? _sidebarTargetFolderId,
    );
  }

  Future<void> _importProjectDialogue(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['yarn', 'txt'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (!context.mounted) return;
    final baseName =
        p.basenameWithoutExtension(path).replaceAll(RegExp(r'[^\w\-]+'), '_');
    final nameController = TextEditingController(text: baseName);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Importer un dialogue',
      controller: nameController,
      confirmLabel: 'Importer',
      placeholder: 'Nom dans le projet',
    );
    if (!ok || !context.mounted) return;
    final displayName = nameController.text.trim();
    if (displayName.isEmpty) return;
    await notifier.importProjectDialogue(
      absoluteSourcePath: path,
      displayName: displayName,
      folderId: _sidebarTargetFolderId,
    );
  }

  Future<void> _promptRename(
    BuildContext context,
    EditorNotifier n,
    ProjectDialogueEntry entry,
  ) async {
    final c = TextEditingController(text: entry.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Renommer le dialogue',
      controller: c,
      confirmLabel: 'Enregistrer',
      placeholder: 'Nom',
    );
    if (!ok || !context.mounted) return;
    final name = c.text.trim();
    if (name.isEmpty) return;
    await n.renameProjectDialogue(dialogueId: entry.id, newName: name);
  }
}
