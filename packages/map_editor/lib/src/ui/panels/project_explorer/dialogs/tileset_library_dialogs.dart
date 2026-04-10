import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../features/editor/state/editor_notifier.dart';
import '../../../shared/cupertino_editor_widgets.dart';

/// Valeur affichable dans les pickers de destination de bibliothèque tilesets.
class ImportLibraryDestination {
  const ImportLibraryDestination(this.label, this.folderId);

  final String label;
  final String? folderId;
}

/// Valeur affichable dans le picker de déplacement de dossier.
class TilesetFolderMoveOption {
  const TilesetFolderMoveOption(this.label, this.newParentId);

  final String label;
  final String? newParentId;
}

Future<void> promptNewTilesetLibraryFolder(
  BuildContext context,
  EditorNotifier notifier, {
  String? parentFolderId,
}) async {
  final controller = TextEditingController();
  final ok = await showMacosEditorPromptSheet(
    context,
    title: parentFolderId == null ? 'New folder' : 'New subfolder',
    controller: controller,
    placeholder: 'Name',
    confirmLabel: 'Create',
    compact: true,
  );
  if (!ok || !context.mounted) return;
  final name = controller.text.trim();
  if (name.isEmpty) return;
  await notifier.createTilesetLibraryFolder(
    name: name,
    parentFolderId: parentFolderId,
  );
}

Future<void> promptRenameTilesetLibraryFolder(
  BuildContext context,
  EditorNotifier notifier,
  ProjectTilesetFolder folder,
) async {
  final controller = TextEditingController(text: folder.name);
  final ok = await showMacosEditorPromptSheet(
    context,
    title: 'Rename folder',
    controller: controller,
    placeholder: 'Name',
    confirmLabel: 'Rename',
    compact: true,
  );
  if (!ok || !context.mounted) return;
  final name = controller.text.trim();
  if (name.isEmpty) return;
  await notifier.renameTilesetLibraryFolder(
    folderId: folder.id,
    name: name,
  );
}

Future<void> openTilesetLibraryFolderContextMenu(
  BuildContext context, {
  required ProjectTilesetFolder folder,
  required ProjectManifest project,
  required EditorNotifier notifier,
  required Offset anchorGlobal,
}) async {
  final action = await showMacosEditorContextMenu<String>(
    context: context,
    globalPosition: anchorGlobal,
    actions: const [
      MacosEditorSheetAction(label: 'Rename', value: 'rename'),
      MacosEditorSheetAction(label: 'New subfolder', value: 'sub'),
      MacosEditorSheetAction(label: 'Move to…', value: 'move'),
      MacosEditorSheetAction(
        label: 'Delete folder',
        value: 'delete',
        isDestructive: true,
      ),
    ],
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case 'rename':
      await promptRenameTilesetLibraryFolder(context, notifier, folder);
    case 'sub':
      await promptNewTilesetLibraryFolder(
        context,
        notifier,
        parentFolderId: folder.id,
      );
    case 'move':
      await pickMoveTilesetLibraryFolderTarget(
        context,
        project,
        notifier,
        folder.id,
      );
    case 'delete':
      await notifier.deleteTilesetLibraryFolder(folder.id);
  }
}

Future<void> pickMoveTilesetLibraryFolderTarget(
  BuildContext context,
  ProjectManifest project,
  EditorNotifier notifier,
  String folderId,
) async {
  final blocked = tilesetFolderSubtreeIds(project, folderId);
  final options = <TilesetFolderMoveOption>[
    const TilesetFolderMoveOption('Library root', null),
  ];
  for (final row in flattenTilesetFoldersForPicker(project)) {
    if (row.id == folderId) continue;
    if (blocked.contains(row.id)) continue;
    options.add(TilesetFolderMoveOption(row.label, row.id));
  }
  final picked = await showCupertinoListPicker<TilesetFolderMoveOption>(
    context: context,
    title: 'Move folder into',
    items: options,
    labelOf: (option) => option.label,
  );
  if (picked == null || !context.mounted) return;
  await notifier.moveTilesetLibraryFolder(
    folderId: folderId,
    newParentFolderId: picked.newParentId,
  );
}

Future<void> openAssignTilesetLibraryFolderSheet(
  BuildContext context, {
  required ProjectManifest project,
  required EditorNotifier notifier,
  required ProjectTilesetEntry tileset,
}) async {
  final options = <ImportLibraryDestination>[
    const ImportLibraryDestination('Library root', null),
    ...flattenTilesetFoldersForPicker(project)
        .map((row) => ImportLibraryDestination(row.label, row.id)),
  ];
  final picked = await showCupertinoListPicker<ImportLibraryDestination>(
    context: context,
    title: 'Move tileset to folder',
    items: options,
    labelOf: (option) => option.label,
  );
  if (picked == null || !context.mounted) return;
  if (picked.folderId == null) {
    await notifier.moveTilesetToLibraryRoot(tileset.id);
  } else {
    await notifier.assignTilesetToLibraryFolder(
      tilesetId: tileset.id,
      folderId: picked.folderId!,
    );
  }
}
