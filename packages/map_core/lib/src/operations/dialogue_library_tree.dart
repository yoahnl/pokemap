import '../models/project_manifest.dart';

/// Branche de la bibliothèque de scripts (dossier + sous-dossiers + fichiers `.yarn`).
class DialogueLibraryBranch {
  const DialogueLibraryBranch({
    required this.folder,
    required this.childFolders,
    required this.dialogues,
  });

  final ProjectDialogueFolder folder;
  final List<DialogueLibraryBranch> childFolders;
  final List<ProjectDialogueEntry> dialogues;
}

class DialogueLibraryTreeSnapshot {
  const DialogueLibraryTreeSnapshot({
    required this.rootFolders,
    required this.rootDialogues,
  });

  final List<DialogueLibraryBranch> rootFolders;
  final List<ProjectDialogueEntry> rootDialogues;
}

int _compareDialogueFolders(ProjectDialogueFolder a, ProjectDialogueFolder b) {
  final o = a.sortOrder.compareTo(b.sortOrder);
  if (o != 0) return o;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

int _compareDialoguesInLibrary(ProjectDialogueEntry a, ProjectDialogueEntry b) {
  final o = a.sortOrder.compareTo(b.sortOrder);
  if (o != 0) return o;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

DialogueLibraryBranch _buildDialogueBranch({
  required ProjectDialogueFolder folder,
  required List<ProjectDialogueFolder> allFolders,
  required List<ProjectDialogueEntry> allDialogues,
}) {
  final children = allFolders
      .where((f) => f.parentFolderId == folder.id)
      .toList()
    ..sort(_compareDialogueFolders);
  final direct = allDialogues
      .where((d) => d.folderId?.trim() == folder.id)
      .toList()
    ..sort(_compareDialoguesInLibrary);

  return DialogueLibraryBranch(
    folder: folder,
    childFolders: children
        .map(
          (f) => _buildDialogueBranch(
            folder: f,
            allFolders: allFolders,
            allDialogues: allDialogues,
          ),
        )
        .toList(growable: false),
    dialogues: direct,
  );
}

/// Arbre des scripts projet (dossiers + entrées sans dossier).
DialogueLibraryTreeSnapshot buildDialogueLibraryTree(ProjectManifest manifest) {
  final folders = manifest.dialogueFolders.toList()..sort(_compareDialogueFolders);
  final roots = folders.where((f) => f.parentFolderId == null).toList();
  final rootBranches = roots
      .map(
        (f) => _buildDialogueBranch(
          folder: f,
          allFolders: folders,
          allDialogues: manifest.dialogues,
        ),
      )
      .toList(growable: false);

  final rootDialogues = manifest.dialogues
      .where((d) {
        final fid = d.folderId?.trim() ?? '';
        return fid.isEmpty;
      })
      .toList()
    ..sort(_compareDialoguesInLibrary);

  return DialogueLibraryTreeSnapshot(
    rootFolders: rootBranches,
    rootDialogues: rootDialogues,
  );
}

class DialogueLibraryFolderPickerRow {
  const DialogueLibraryFolderPickerRow({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

List<DialogueLibraryFolderPickerRow> flattenDialogueFoldersForPicker(
  ProjectManifest manifest,
) {
  final folders = manifest.dialogueFolders.toList()..sort(_compareDialogueFolders);
  final out = <DialogueLibraryFolderPickerRow>[];

  void walk(String? parentId, String prefix) {
    final children = folders.where((f) => f.parentFolderId == parentId).toList()
      ..sort(_compareDialogueFolders);
    for (final f in children) {
      final label = prefix.isEmpty ? f.name : '$prefix / ${f.name}';
      out.add(DialogueLibraryFolderPickerRow(id: f.id, label: label));
      walk(f.id, label);
    }
  }

  walk(null, '');
  return out;
}

/// Identifiants du dossier [rootId] et de tous ses sous-dossiers (incl. [rootId]).
Set<String> dialogueFolderSubtreeIds(ProjectManifest manifest, String rootId) {
  final byParent = <String?, List<ProjectDialogueFolder>>{};
  for (final f in manifest.dialogueFolders) {
    byParent.putIfAbsent(f.parentFolderId, () => []).add(f);
  }
  final out = <String>{};
  void walk(String id) {
    out.add(id);
    for (final c in byParent[id] ?? const <ProjectDialogueFolder>[]) {
      walk(c.id);
    }
  }

  walk(rootId);
  return out;
}
