import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../../../features/editor/state/editor_notifier.dart';
import '../../../shared/cupertino_editor_widgets.dart';

/// Données minimales transportées pendant le drag-and-drop de la bibliothèque
/// de tilesets.
///
/// On sort ce type du gros panneau pour éviter que toute la logique de dépôt
/// soit noyée dans `project_explorer_panel.dart`.
class TilesetLibraryDragData {
  const TilesetLibraryDragData.tileset(this.id) : isFolder = false;
  const TilesetLibraryDragData.folder(this.id) : isFolder = true;

  final String id;
  final bool isFolder;
}

ProjectTilesetEntry? _tilesetById(ProjectManifest project, String tilesetId) {
  for (final tileset in project.tilesets) {
    if (tileset.id == tilesetId) return tileset;
  }
  return null;
}

bool tilesetLibraryCanDropOnFolder(
  ProjectManifest project,
  ProjectTilesetFolder target,
  TilesetLibraryDragData data,
) {
  if (data.isFolder) {
    if (data.id == target.id) return false;
    if (tilesetFolderSubtreeIds(project, data.id).contains(target.id)) {
      return false;
    }
    for (final folder in project.tilesetFolders) {
      if (folder.id != data.id) continue;
      final parentId = folder.parentFolderId?.trim() ?? '';
      if (parentId == target.id) return false;
      break;
    }
    return true;
  }
  final tileset = _tilesetById(project, data.id);
  if (tileset == null) return false;
  final currentFolderId = tileset.folderId?.trim() ?? '';
  return currentFolderId != target.id;
}

bool tilesetLibraryCanDropOnRoot(
  ProjectManifest project,
  TilesetLibraryDragData data,
) {
  if (data.isFolder) {
    ProjectTilesetFolder? folder;
    for (final candidate in project.tilesetFolders) {
      if (candidate.id == data.id) {
        folder = candidate;
        break;
      }
    }
    if (folder == null) return false;
    final parentId = folder.parentFolderId?.trim() ?? '';
    return parentId.isNotEmpty;
  }
  final tileset = _tilesetById(project, data.id);
  if (tileset == null) return false;
  final currentFolderId = tileset.folderId?.trim() ?? '';
  return currentFolderId.isNotEmpty;
}

void tilesetLibraryApplyDropOnFolder(
  EditorNotifier notifier,
  ProjectTilesetFolder target,
  TilesetLibraryDragData data,
) {
  if (data.isFolder) {
    notifier.moveTilesetLibraryFolder(
      folderId: data.id,
      newParentFolderId: target.id,
    );
  } else {
    notifier.assignTilesetToLibraryFolder(
      tilesetId: data.id,
      folderId: target.id,
    );
  }
}

void tilesetLibraryApplyDropOnRoot(
  EditorNotifier notifier,
  TilesetLibraryDragData data,
) {
  if (data.isFolder) {
    notifier.moveTilesetLibraryFolder(
      folderId: data.id,
      newParentFolderId: null,
    );
  } else {
    notifier.moveTilesetToLibraryRoot(data.id);
  }
}

Widget buildTilesetLibraryTilesetDragFeedback(
  BuildContext context,
  ProjectTilesetEntry tileset,
) {
  return Material(
    elevation: 6,
    borderRadius: BorderRadius.circular(8),
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MacosIcon(
            CupertinoIcons.square_stack_3d_up,
            size: 16,
            color: EditorChrome.accentWarm,
          ),
          const SizedBox(width: 8),
          Text(
            tileset.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: EditorChrome.primaryLabel(context),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildTilesetLibraryFolderDragFeedback(
  BuildContext context,
  ProjectTilesetFolder folder,
) {
  return Material(
    elevation: 6,
    borderRadius: BorderRadius.circular(8),
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.accentCyan.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MacosIcon(
            CupertinoIcons.folder_fill,
            size: 16,
            color: EditorChrome.accentCyan,
          ),
          const SizedBox(width: 8),
          Text(
            folder.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: EditorChrome.primaryLabel(context),
            ),
          ),
        ],
      ),
    ),
  );
}
