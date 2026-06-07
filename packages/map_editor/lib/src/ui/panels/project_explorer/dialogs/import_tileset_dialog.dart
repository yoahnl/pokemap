import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../features/editor/state/editor_notifier.dart';
import '../../../../features/editor/state/editor_selectors.dart';
import '../../../shared/cupertino_editor_widgets.dart';
import 'tileset_library_dialogs.dart';

Future<void> showImportTilesetDialog(
  BuildContext context,
  EditorProjectExplorerSnapshot snapshot,
  EditorNotifier notifier,
) async {
  final project = snapshot.project;
  if (project == null) return;

  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
    withData: false,
  );
  final sourcePath = picked?.files.single.path;
  if (sourcePath == null) return;
  if (!context.mounted) return;

  final defaultName = p.basenameWithoutExtension(sourcePath);
  final nameController = TextEditingController(text: defaultName);
  var scope = TilesetScope.global;
  String? selectedGroupId =
      project.groups.isNotEmpty ? project.groups.first.id : null;
  var isWorld = project.tilesets.every((tileset) => !tileset.isWorldTileset);
  var shouldImport = false;
  String? importLibraryFolderId;

  await showMacosEditorModalSheet<void>(
    context: context,
    maxWidth: 480,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        String libraryFolderButtonLabel() {
          if (importLibraryFolderId == null) return 'Racine de la bibliothèque';
          for (final row in flattenTilesetFoldersForPicker(project)) {
            if (row.id == importLibraryFolderId) return row.label;
          }
          return 'Racine de la bibliothèque';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Importer un jeu de tuiles',
              style: editorMacosSheetTitleStyle(ctx),
            ),
            const SizedBox(height: 12),
            Text(
              p.basename(sourcePath),
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text('Nom du jeu de tuiles', style: editorMacosFormLabelStyle(ctx)),
            const SizedBox(height: 6),
            MacosTextField(controller: nameController),
            const SizedBox(height: 10),
            Text('Dossier de destination', style: editorMacosFormLabelStyle(ctx)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () async {
                  final options = <ImportLibraryDestination>[
                    const ImportLibraryDestination('Racine de la bibliothèque', null),
                    ...flattenTilesetFoldersForPicker(project).map(
                      (row) => ImportLibraryDestination(row.label, row.id),
                    ),
                  ];
                  final pickedDestination =
                      await showCupertinoListPicker<ImportLibraryDestination>(
                    context: ctx,
                    title: 'Dossier de destination',
                    items: options,
                    labelOf: (option) => option.label,
                  );
                  if (pickedDestination != null) {
                    setState(
                      () => importLibraryFolderId = pickedDestination.folderId,
                    );
                  }
                },
                child: Text(libraryFolderButtonLabel()),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () async {
                  final pickedScope =
                      await showCupertinoListPicker<TilesetScope>(
                    context: ctx,
                    title: 'Portée',
                    items: TilesetScope.values,
                    labelOf: (value) =>
                        value == TilesetScope.global ? 'Global' : 'Groupe',
                  );
                  if (pickedScope != null) setState(() => scope = pickedScope);
                },
                child: Text(
                  'Portée : ${scope == TilesetScope.global ? 'Global' : 'Groupe'}',
                ),
              ),
            ),
            if (scope == TilesetScope.group) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: PushButton(
                  controlSize: ControlSize.regular,
                  secondary: true,
                  onPressed: () async {
                    final pickedGroup =
                        await showCupertinoListPicker<ProjectMapGroup>(
                      context: ctx,
                      title: 'Groupe',
                      items: project.groups,
                      labelOf: (group) => group.name,
                    );
                    if (pickedGroup != null) {
                      setState(() => selectedGroupId = pickedGroup.id);
                    }
                  },
                  child: Text(
                    'Groupe : ${project.groups.firstWhere((group) => group.id == selectedGroupId, orElse: () => project.groups.first).name}',
                  ),
                ),
              ),
            ],
            if (scope == TilesetScope.global) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  MacosSwitch(
                    value: isWorld,
                    onChanged: (value) => setState(() => isWorld = value),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Définir comme tileset mondial'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 10),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    if (scope == TilesetScope.group &&
                        selectedGroupId == null) {
                      return;
                    }
                    shouldImport = true;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Importer'),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  if (!shouldImport) return;
  await notifier.importProjectTileset(
    sourcePath: sourcePath,
    name: nameController.text.trim(),
    scope: scope,
    groupId: scope == TilesetScope.group ? selectedGroupId : null,
    isWorldTileset: scope == TilesetScope.global ? isWorld : false,
    libraryFolderId: importLibraryFolderId,
  );
}
