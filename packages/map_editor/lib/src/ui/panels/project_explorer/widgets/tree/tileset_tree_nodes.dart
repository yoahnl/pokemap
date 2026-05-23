import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../../../../features/editor/state/editor_notifier.dart';
import '../../../../shared/cupertino_editor_widgets.dart';
import '../../../../../theme/theme.dart';
import '../../dialogs/tileset_library_dialogs.dart';
import '../../dnd/tileset_library_drag_drop.dart';

class TilesetLibraryRootDropStrip extends StatelessWidget {
  const TilesetLibraryRootDropStrip({
    super.key,
    required this.project,
    required this.notifier,
  });

  final ProjectManifest project;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final subtle = colors.textMuted;
    return DragTarget<TilesetLibraryDragData>(
      onWillAcceptWithDetails: (details) =>
          tilesetLibraryCanDropOnRoot(project, details.data),
      onAcceptWithDetails: (details) {
        tilesetLibraryApplyDropOnRoot(notifier, details.data);
      },
      builder: (context, candidateData, rejected) {
        final hovering = candidateData.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: hovering
                  ? colors.warning.withValues(alpha: 0.12)
                  : colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hovering
                    ? colors.warning.withValues(alpha: 0.75)
                    : colors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                MacosIcon(
                  CupertinoIcons.square_stack_3d_up,
                  size: 14,
                  color: hovering ? colors.warning : subtle,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hovering
                        ? 'Relâcher pour déplacer à la racine'
                        : 'Déposer ici pour sortir du dossier',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hovering
                          ? colors.textPrimary
                          : subtle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TilesetLibraryFolderNode extends StatelessWidget {
  const TilesetLibraryFolderNode({
    super.key,
    required this.branch,
    required this.depth,
    required this.project,
    required this.notifier,
    required this.selectedTilesetId,
    required this.scopeLabel,
  });

  final TilesetLibraryBranch branch;
  final int depth;
  final ProjectManifest project;
  final EditorNotifier notifier;
  final String? selectedTilesetId;
  final String Function(ProjectTilesetEntry) scopeLabel;

  @override
  Widget build(BuildContext context) {
    final folder = branch.folder;
    final indent = 6.0 + depth * 10.0;

    return CupertinoDisclosureTile(
      useEditorMacosSidebarDisclosureStyle: true,
      initiallyExpanded: true,
      tilePadding: EdgeInsets.only(left: indent, right: 8, top: 4, bottom: 4),
      childrenPadding: EdgeInsets.zero,
      leading: const MacosIcon(CupertinoIcons.folder_fill, size: 16),
      title: Text(
        folder.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onSecondaryTapDown: (details) => openTilesetLibraryFolderContextMenu(
        context,
        folder: folder,
        project: project,
        notifier: notifier,
        anchorGlobal: details.globalPosition,
      ),
      trailing: Builder(
        builder: (buttonContext) => EditorToolbarIconButton(
          icon: CupertinoIcons.ellipsis_vertical,
          tooltip: 'Actions du dossier',
          iconSize: 16,
          onPressed: () => openTilesetLibraryFolderContextMenu(
            context,
            folder: folder,
            project: project,
            notifier: notifier,
            anchorGlobal: editorMenuAnchorBelowWidget(buttonContext),
          ),
        ),
      ),
      wrapHeader: (header) => _TilesetFolderHeaderDnD(
        header: header,
        folder: folder,
        project: project,
        notifier: notifier,
      ),
      children: [
        ...branch.childFolders.map(
          (childBranch) => TilesetLibraryFolderNode(
            branch: childBranch,
            depth: depth + 1,
            project: project,
            notifier: notifier,
            selectedTilesetId: selectedTilesetId,
            scopeLabel: scopeLabel,
          ),
        ),
        ...branch.tilesets.map(
          (tileset) => TilesetNode(
            tileset: tileset,
            project: project,
            notifier: notifier,
            selected: selectedTilesetId == tileset.id,
            leftIndent: indent + 14,
            scopeLabel: scopeLabel(tileset),
          ),
        ),
      ],
    );
  }
}

class TilesetNode extends StatelessWidget {
  const TilesetNode({
    super.key,
    required this.tileset,
    required this.project,
    required this.notifier,
    required this.selected,
    required this.scopeLabel,
    this.leftIndent = 6,
  });

  final ProjectTilesetEntry tileset;
  final ProjectManifest project;
  final EditorNotifier notifier;
  final bool selected;
  final double leftIndent;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final row = EditorSidebarListRow(
      selected: selected,
      onTap: () => notifier.selectTilesetWorkspace(tileset.id),
      onSecondaryTapDown: (details) =>
          _showTilesetMenu(context, anchorGlobal: details.globalPosition),
      leftIndent: leftIndent,
      leadingIconUnselectedColor:
          tileset.isWorldTileset ? colors.warning : null,
      leading: MacosIcon(
        tileset.isWorldTileset
            ? CupertinoIcons.globe
            : (tileset.scope == TilesetScope.global
                ? CupertinoIcons.circle_grid_hex
                : CupertinoIcons.tag),
        size: 16,
      ),
      title: Text(tileset.name),
      subtitle: Text('$scopeLabel · ${tileset.id}'),
      trailing: Builder(
        builder: (buttonContext) => EditorToolbarIconButton(
          icon: CupertinoIcons.ellipsis_vertical,
          tooltip: 'Actions du tileset',
          iconSize: 16,
          color: selected ? MacosColors.white : null,
          onPressed: () => _showTilesetMenu(
            context,
            anchorGlobal: editorMenuAnchorBelowWidget(buttonContext),
          ),
        ),
      ),
    );
    return Draggable<TilesetLibraryDragData>(
      data: TilesetLibraryDragData.tileset(tileset.id),
      affinity: Axis.vertical,
      feedback: buildTilesetLibraryTilesetDragFeedback(context, tileset),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: row,
      ),
      child: row,
    );
  }

  Future<void> _showTilesetMenu(
    BuildContext context, {
    required Offset anchorGlobal,
  }) async {
    final action = await showMacosEditorContextMenu<String>(
      context: context,
      globalPosition: anchorGlobal,
      actions: [
        const MacosEditorSheetAction(label: 'Renommer', value: 'rename'),
        const MacosEditorSheetAction(label: 'Déplacer vers le haut', value: 'move_up'),
        const MacosEditorSheetAction(label: 'Déplacer vers le bas', value: 'move_down'),
        const MacosEditorSheetAction(
          label: 'Définir comme global',
          value: 'make_global',
        ),
        const MacosEditorSheetAction(
          label: 'Lier à un groupe',
          value: 'assign_group',
        ),
        const MacosEditorSheetAction(
          label: 'Déplacer dans un dossier…',
          value: 'library_folder',
        ),
        if (tileset.folderId != null && tileset.folderId!.trim().isNotEmpty)
          const MacosEditorSheetAction(
            label: 'Déplacer à la racine',
            value: 'library_root',
          ),
        if (tileset.scope == TilesetScope.global)
          MacosEditorSheetAction(
            label: tileset.isWorldTileset
                ? 'Retirer comme tileset mondial'
                : 'Définir comme tileset mondial',
            value: 'toggle_world',
          ),
        const MacosEditorSheetAction(
          label: 'Supprimer le tileset',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'rename':
        await _showRenameTilesetDialog(context);
      case 'make_global':
        notifier.updateProjectTileset(
          tilesetId: tileset.id,
          scope: TilesetScope.global,
          groupId: null,
        );
      case 'assign_group':
        _showAssignGroupDialog(context);
      case 'library_folder':
        await openAssignTilesetLibraryFolderSheet(
          context,
          project: project,
          notifier: notifier,
          tileset: tileset,
        );
      case 'library_root':
        await notifier.moveTilesetToLibraryRoot(tileset.id);
      case 'toggle_world':
        notifier.updateProjectTileset(
          tilesetId: tileset.id,
          isWorldTileset: !tileset.isWorldTileset,
        );
      case 'move_up':
        notifier.reorderProjectTileset(tileset.id, -1);
      case 'move_down':
        notifier.reorderProjectTileset(tileset.id, 1);
      case 'delete':
        notifier.deleteProjectTileset(tileset.id);
    }
  }

  Future<void> _showRenameTilesetDialog(BuildContext context) async {
    final controller = TextEditingController(text: tileset.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Rename Tileset',
      controller: controller,
      confirmLabel: 'Rename',
    );
    if (!ok || !context.mounted) return;
    final value = controller.text.trim();
    notifier.updateProjectTileset(
      tilesetId: tileset.id,
      name: value,
    );
  }

  void _showAssignGroupDialog(BuildContext context) {
    final groups = project.groups.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (groups.isEmpty) {
      notifier.updateProjectTileset(
        tilesetId: tileset.id,
        scope: TilesetScope.global,
      );
      return;
    }

    var selectedGroupId = tileset.groupId ?? groups.first.id;
    showMacosEditorModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attach Tileset to Group',
              style: editorMacosSheetTitleStyle(ctx),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () async {
                  final group = await showCupertinoListPicker<ProjectMapGroup>(
                    context: ctx,
                    title: 'Group',
                    items: groups,
                    labelOf: (value) => value.name,
                  );
                  if (group != null) {
                    setState(() => selectedGroupId = group.id);
                  }
                },
                child: Text(
                  groups
                      .firstWhere((group) => group.id == selectedGroupId)
                      .name,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () {
                    notifier.updateProjectTileset(
                      tilesetId: tileset.id,
                      scope: TilesetScope.group,
                      groupId: selectedGroupId,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Attach'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TilesetFolderHeaderDnD extends StatelessWidget {
  const _TilesetFolderHeaderDnD({
    required this.header,
    required this.folder,
    required this.project,
    required this.notifier,
  });

  final Widget header;
  final ProjectTilesetFolder folder;
  final ProjectManifest project;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TilesetLibraryDragData>(
      onWillAcceptWithDetails: (details) =>
          tilesetLibraryCanDropOnFolder(project, folder, details.data),
      onAcceptWithDetails: (details) {
        tilesetLibraryApplyDropOnFolder(notifier, folder, details.data);
      },
      builder: (context, candidateData, rejected) {
        final hovering = candidateData.isNotEmpty;
        return Draggable<TilesetLibraryDragData>(
          data: TilesetLibraryDragData.folder(folder.id),
          affinity: Axis.vertical,
          feedback: buildTilesetLibraryFolderDragFeedback(context, folder),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: header,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            decoration: hovering
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: context.pokeMapColors.brandPrimaryBorder.withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                    color: context.pokeMapColors.brandPrimarySoft.withValues(alpha: 0.08),
                  )
                : null,
            child: header,
          ),
        );
      },
    );
  }
}
