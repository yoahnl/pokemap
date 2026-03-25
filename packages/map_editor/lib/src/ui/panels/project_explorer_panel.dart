import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../features/editor/state/editor_notifier.dart';
import 'terrain_editor_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';

String _mapGroupTypeDisplayLabel(MapGroupType t) {
  final n = t.name;
  if (n.isEmpty) return '';
  return '${n[0].toUpperCase()}${n.substring(1)}';
}

class _ImportLibraryDest {
  const _ImportLibraryDest(this.label, this.folderId);
  final String label;
  final String? folderId;
}

class _TilesetFolderMoveOption {
  const _TilesetFolderMoveOption(this.label, this.newParentId);
  final String label;
  final String? newParentId;
}

Future<void> _promptNewTilesetLibraryFolder(
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

Future<void> _promptRenameTilesetLibraryFolder(
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

Future<void> _openTilesetLibraryFolderContextMenu(
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
      await _promptRenameTilesetLibraryFolder(context, notifier, folder);
    case 'sub':
      await _promptNewTilesetLibraryFolder(
        context,
        notifier,
        parentFolderId: folder.id,
      );
    case 'move':
      await _pickMoveTilesetLibraryFolderTarget(
        context,
        project,
        notifier,
        folder.id,
      );
    case 'delete':
      await notifier.deleteTilesetLibraryFolder(folder.id);
  }
}

Future<void> _pickMoveTilesetLibraryFolderTarget(
  BuildContext context,
  ProjectManifest project,
  EditorNotifier notifier,
  String folderId,
) async {
  final blocked = tilesetFolderSubtreeIds(project, folderId);
  final options = <_TilesetFolderMoveOption>[
    const _TilesetFolderMoveOption('Library root', null),
  ];
  for (final row in flattenTilesetFoldersForPicker(project)) {
    if (row.id == folderId) continue;
    if (blocked.contains(row.id)) continue;
    options.add(_TilesetFolderMoveOption(row.label, row.id));
  }
  final picked = await showCupertinoListPicker<_TilesetFolderMoveOption>(
    context: context,
    title: 'Move folder into',
    items: options,
    labelOf: (o) => o.label,
  );
  if (picked == null || !context.mounted) return;
  await notifier.moveTilesetLibraryFolder(
    folderId: folderId,
    newParentFolderId: picked.newParentId,
  );
}

Future<void> _openAssignTilesetLibraryFolderSheet(
  BuildContext context, {
  required ProjectManifest project,
  required EditorNotifier notifier,
  required ProjectTilesetEntry tileset,
}) async {
  final options = <_ImportLibraryDest>[
    const _ImportLibraryDest('Library root', null),
    ...flattenTilesetFoldersForPicker(project)
        .map((r) => _ImportLibraryDest(r.label, r.id)),
  ];
  final picked = await showCupertinoListPicker<_ImportLibraryDest>(
    context: context,
    title: 'Move tileset to folder',
    items: options,
    labelOf: (o) => o.label,
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

class ProjectExplorerPanel extends ConsumerWidget {
  const ProjectExplorerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 2),
          Expanded(
            child: project == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Open a project to browse your world, maps and tilesets.',
                        style: TextStyle(
                          color: CupertinoColors.placeholderText
                              .resolveFrom(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _buildTree(context, project, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const explorerAccent = EditorChrome.inspectorJoyCyan;
    const explorerDeep = EditorChrome.inspectorJoyPlum;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, explorerAccent, 0.78)!,
                  Color.lerp(explorerDeep, const Color(0xFF140818), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: explorerAccent.withValues(alpha: 0.88),
                width: 1.15,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.square_stack_3d_up,
              size: 18,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'World Explorer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Maps, regions, tilesets and project structure',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTree(
    BuildContext context,
    ProjectManifest project,
    dynamic state,
    EditorNotifier notifier,
  ) {
    final rootMaps = project.maps.where((m) => m.groupId == null).toList();
    final rootGroups =
        project.groups.where((g) => g.parentGroupId == null).toList();

    final worldChildren = <Widget>[
      ...rootGroups.map(
        (g) => _GroupNode(
          group: g,
          project: project,
          state: state,
          notifier: notifier,
          depth: 0,
        ),
      ),
      if (rootMaps.isNotEmpty) ...[
        const EditorSidebarSectionTitle('UNGROUPED MAPS', leftInset: 6),
        ...rootMaps.map(
          (m) => _MapNode(
            map: m,
            state: state,
            notifier: notifier,
            depth: 0,
          ),
        ),
      ],
      if (rootGroups.isEmpty && rootMaps.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'World is empty',
                style: TextStyle(
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: () => _showCreateGroupDialog(context, notifier),
                child: const Text('Add City or Route'),
              ),
            ],
          ),
        ),
    ];

    return Column(
      children: [
        Expanded(
          child: _ExplorerIslandSurface(
            tint: EditorChrome.islandCoolTint,
            child: _buildTilesetsIsland(context, project, state, notifier),
          ),
        ),
        const SizedBox(height: 14),
        ResizablePane.noScrollBar(
          key: const ValueKey('project_explorer_world_pane'),
          resizableSide: ResizableSide.top,
          minSize: 180,
          maxSize: 420,
          startSize: 280,
          decoration: const BoxDecoration(
            color: MacosColors.transparent,
            border: Border(
              top: BorderSide(color: MacosColors.transparent),
            ),
          ),
          child: _ExplorerIslandSurface(
            tint: EditorChrome.islandNeutralTint,
            child: _buildWorldIsland(context, worldChildren, notifier),
          ),
        ),
        const SizedBox(height: 14),
        ResizablePane.noScrollBar(
          key: const ValueKey('project_explorer_surface_pane'),
          resizableSide: ResizableSide.top,
          minSize: 180,
          maxSize: 480,
          startSize: 280,
          decoration: const BoxDecoration(
            color: MacosColors.transparent,
            border: Border(
              top: BorderSide(color: MacosColors.transparent),
            ),
          ),
          child: _ExplorerIslandSurface(
            tint: EditorChrome.islandWarmTint,
            child: const TerrainEditorPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildTilesetsIsland(
    BuildContext context,
    ProjectManifest project,
    dynamic state,
    EditorNotifier notifier,
  ) {
    const tilesetAccent = EditorChrome.accentWarm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tilesetAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  CupertinoIcons.square_grid_2x2,
                  size: 15,
                  color: tilesetAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tileset Library',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Folders, imports, and map painting',
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.photo_on_rectangle,
                tooltip: 'Import tileset',
                onPressed: () =>
                    _showImportTilesetDialog(context, state, notifier),
              ),
              const SizedBox(width: 6),
              _SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.plus_circle_fill,
                tooltip: 'New folder',
                onPressed: () =>
                    _promptNewTilesetLibraryFolder(context, notifier),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTilesetsSection(context, project, state, notifier),
          ),
        ),
      ],
    );
  }

  Widget _buildWorldIsland(
    BuildContext context,
    List<Widget> worldChildren,
    EditorNotifier notifier,
  ) {
    const worldAccent = EditorChrome.accentCyan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: worldAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  CupertinoIcons.map_fill,
                  size: 15,
                  color: worldAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'World Maps',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Regions, groups and playable maps',
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.folder_badge_plus,
                tooltip: 'New root group',
                onPressed: () => _showCreateGroupDialog(context, notifier),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: worldChildren,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTilesetsSection(
    BuildContext context,
    ProjectManifest project,
    dynamic state,
    EditorNotifier notifier,
  ) {
    final selectedTilesetId =
        state.selectedTilesetEditorId ?? notifier.getSelectedTilesetEntry()?.id;
    final tree = buildTilesetLibraryTree(project);

    String scopeLabel(ProjectTilesetEntry t) {
      if (t.scope == TilesetScope.global) return 'Global';
      final gid = t.groupId;
      if (gid == null) return 'Group';
      for (final g in project.groups) {
        if (g.id == gid) return g.name;
      }
      return 'Group';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (project.tilesets.isEmpty && project.tilesetFolders.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Text(
              'No tilesets yet. Import an image or create folders to organize your library.',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 12,
              ),
            ),
          ),
        ...tree.rootFolders.map(
          (branch) => _TilesetLibraryFolderNode(
            branch: branch,
            depth: 0,
            project: project,
            notifier: notifier,
            selectedTilesetId: selectedTilesetId,
            scopeLabel: scopeLabel,
          ),
        ),
        ...tree.rootTilesets.map(
          (tileset) => _TilesetNode(
            tileset: tileset,
            project: project,
            notifier: notifier,
            selected: selectedTilesetId == tileset.id,
            leftIndent: 14,
            scopeLabel: scopeLabel(tileset),
          ),
        ),
      ],
    );
  }

  Future<void> _showImportTilesetDialog(
    BuildContext context,
    dynamic state,
    EditorNotifier notifier,
  ) async {
    final project = state.project as ProjectManifest?;
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
    var isWorld = project.tilesets.every((t) => !t.isWorldTileset);
    var shouldImport = false;
    String? importLibraryFolderId;

    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 480,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          String libraryFolderButtonLabel() {
            if (importLibraryFolderId == null) return 'Library root';
            for (final r in flattenTilesetFoldersForPicker(project)) {
              if (r.id == importLibraryFolderId) return r.label;
            }
            return 'Library root';
          }

          return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Import Tileset',
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
            Text('Tileset Name', style: editorMacosFormLabelStyle(ctx)),
            const SizedBox(height: 6),
            MacosTextField(controller: nameController),
            const SizedBox(height: 10),
            Text('Library folder', style: editorMacosFormLabelStyle(ctx)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () async {
                  final options = <_ImportLibraryDest>[
                    const _ImportLibraryDest('Library root', null),
                    ...flattenTilesetFoldersForPicker(project)
                        .map((r) => _ImportLibraryDest(r.label, r.id)),
                  ];
                  final p = await showCupertinoListPicker<_ImportLibraryDest>(
                    context: ctx,
                    title: 'Library folder',
                    items: options,
                    labelOf: (o) => o.label,
                  );
                  if (p != null) {
                    setState(() => importLibraryFolderId = p.folderId);
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
                  final s = await showCupertinoListPicker<TilesetScope>(
                    context: ctx,
                    title: 'Scope',
                    items: TilesetScope.values,
                    labelOf: (v) =>
                        v == TilesetScope.global ? 'Global' : 'Group',
                  );
                  if (s != null) setState(() => scope = s);
                },
                child: Text(
                  'Scope: ${scope == TilesetScope.global ? 'Global' : 'Group'}',
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
                    final g = await showCupertinoListPicker<ProjectMapGroup>(
                      context: ctx,
                      title: 'Group',
                      items: project.groups,
                      labelOf: (x) => x.name,
                    );
                    if (g != null) {
                      setState(() => selectedGroupId = g.id);
                    }
                  },
                  child: Text(
                    'Group: ${project.groups.firstWhere((g) => g.id == selectedGroupId, orElse: () => project.groups.first).name}',
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
                    onChanged: (v) => setState(() => isWorld = v),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Mark as world tileset'),
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
                  child: const Text('Cancel'),
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
                  child: const Text('Import'),
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

  void _showCreateGroupDialog(
    BuildContext context,
    EditorNotifier notifier, {
    String? parentId,
  }) {
    final nameController = TextEditingController();
    var selectedType = MapGroupType.city;

    showMacosEditorModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              parentId == null ? 'New Root Group' : 'New Sub-Group',
              style: editorMacosSheetTitleStyle(ctx),
            ),
            const SizedBox(height: 12),
            MacosTextField(
              controller: nameController,
              autofocus: true,
              placeholder: 'Group Name',
            ),
            const SizedBox(height: 12),
            Text('Group type', style: editorMacosFormLabelStyle(ctx)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: MacosPopupButton<MapGroupType>(
                value: selectedType,
                onChanged: (MapGroupType? v) {
                  if (v != null) setState(() => selectedType = v);
                },
                items: [
                  for (final t in MapGroupType.values)
                    MacosPopupMenuItem<MapGroupType>(
                      value: t,
                      child: Text(_mapGroupTypeDisplayLabel(t)),
                    ),
                ],
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
                    if (nameController.text.trim().isEmpty) return;
                    notifier.createGroup(
                      nameController.text.trim(),
                      selectedType,
                      parentId: parentId,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerIslandSurface extends StatelessWidget {
  const _ExplorerIslandSurface({
    required this.child,
    required this.tint,
  });

  final Widget child;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return EditorIsland(
      radius: 24,
      tint: tint,
      child: child,
    );
  }
}

class _SidebarHeaderAction extends StatefulWidget {
  const _SidebarHeaderAction({
    required this.enabled,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final bool enabled;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_SidebarHeaderAction> createState() => _SidebarHeaderActionState();
}

class _SidebarHeaderActionState extends State<_SidebarHeaderAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return MacosTooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        child: GestureDetector(
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered && enabled
                  ? CupertinoColors.systemFill.resolveFrom(context)
                  : CupertinoColors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: MacosIcon(
              widget.icon,
              size: 16,
              color: enabled
                  ? EditorChrome.primaryLabel(context)
                  : CupertinoColors.inactiveGray.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupNode extends StatelessWidget {
  final ProjectMapGroup group;
  final ProjectManifest project;
  final dynamic state;
  final EditorNotifier notifier;
  final int depth;

  const _GroupNode({
    required this.group,
    required this.project,
    required this.state,
    required this.notifier,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final childrenGroups =
        project.groups.where((g) => g.parentGroupId == group.id).toList();
    final childrenMaps =
        project.maps.where((m) => m.groupId == group.id).toList();
    return CupertinoDisclosureTile(
      useEditorMacosSidebarDisclosureStyle: true,
      tilePadding:
          EdgeInsets.only(left: 8 + 16.0 * depth, right: 8, top: 4, bottom: 4),
      childrenPadding: EdgeInsets.zero,
      leading: MacosIcon(_getGroupIcon(group.type), size: 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            group.type.name.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
      trailing: Builder(
        builder: (btnContext) => EditorToolbarIconButton(
          icon: CupertinoIcons.ellipsis_vertical,
          tooltip: 'Group actions',
          iconSize: 16,
          onPressed: () => _showGroupContextMenu(
            context,
            group,
            notifier,
            anchorGlobal: editorMenuAnchorBelowWidget(btnContext),
          ),
        ),
      ),
      onSecondaryTapDown: (d) => _showGroupContextMenu(context, group, notifier,
          anchorGlobal: d.globalPosition),
      children: [
        ...childrenGroups.map(
          (g) => _GroupNode(
            group: g,
            project: project,
            state: state,
            notifier: notifier,
            depth: depth + 1,
          ),
        ),
        ...childrenMaps.map(
          (m) => _MapNode(
            map: m,
            state: state,
            notifier: notifier,
            depth: depth + 1,
          ),
        ),
      ],
    );
  }

  IconData _getGroupIcon(MapGroupType type) {
    return switch (type) {
      MapGroupType.city => CupertinoIcons.building_2_fill,
      MapGroupType.village => CupertinoIcons.house_fill,
      MapGroupType.route => CupertinoIcons.map_fill,
      MapGroupType.dungeon => CupertinoIcons.lock_shield,
      MapGroupType.cave => CupertinoIcons.circle_grid_hex,
      MapGroupType.forest => CupertinoIcons.leaf_arrow_circlepath,
      MapGroupType.tower => CupertinoIcons.arrow_up_circle_fill,
      MapGroupType.facility => CupertinoIcons.briefcase_fill,
      MapGroupType.special => CupertinoIcons.star_fill,
    };
  }

  Future<void> _showGroupContextMenu(
    BuildContext context,
    ProjectMapGroup group,
    EditorNotifier notifier, {
    required Offset anchorGlobal,
  }) async {
    final action = await showMacosEditorContextMenu<String>(
      context: context,
      globalPosition: anchorGlobal,
      actions: const [
        MacosEditorSheetAction(label: 'Add Map', value: 'add_map'),
        MacosEditorSheetAction(label: 'Add Sub-Group', value: 'add_subgroup'),
        MacosEditorSheetAction(label: 'Rename Group', value: 'rename'),
        MacosEditorSheetAction(
          label: 'Delete Group',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'add_map':
        _showCreateMapDialog(context, group.id, notifier);
      case 'add_subgroup':
        _showCreateSubGroupDialog(context, group.id, notifier);
      case 'rename':
        _showRenameGroupDialog(context, group, notifier);
      case 'delete':
        notifier.deleteGroup(group.id);
    }
  }

  void _showCreateMapDialog(
    BuildContext context,
    String groupId,
    EditorNotifier notifier,
  ) {
    final controller = TextEditingController();
    var selectedRole = MapRole.exterior;
    final settings = state.project?.settings ?? const ProjectSettings();

    showMacosEditorModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New Map in Group',
              style: editorMacosSheetTitleStyle(ctx),
            ),
            const SizedBox(height: 12),
            MacosTextField(
              controller: controller,
              autofocus: true,
              placeholder: 'Map ID',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () async {
                  final r = await showCupertinoListPicker<MapRole>(
                    context: ctx,
                    title: 'Map Role',
                    items: MapRole.values,
                    labelOf: (x) => x.name.toUpperCase(),
                  );
                  if (r != null) setState(() => selectedRole = r);
                },
                child: Text('Role: ${selectedRole.name.toUpperCase()}'),
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
                    if (controller.text.isEmpty) return;
                    notifier.createMap(
                      controller.text,
                      settings.defaultMapWidth,
                      settings.defaultMapHeight,
                      groupId: groupId,
                      role: selectedRole,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSubGroupDialog(
    BuildContext context,
    String parentId,
    EditorNotifier notifier,
  ) {
    final nameController = TextEditingController();
    var selectedType = MapGroupType.facility;

    showMacosEditorModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New Sub-Group',
              style: editorMacosSheetTitleStyle(ctx),
            ),
            const SizedBox(height: 12),
            MacosTextField(
              controller: nameController,
              autofocus: true,
              placeholder: 'Group Name',
            ),
            const SizedBox(height: 12),
            Text('Group type', style: editorMacosFormLabelStyle(ctx)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: MacosPopupButton<MapGroupType>(
                value: selectedType,
                onChanged: (MapGroupType? v) {
                  if (v != null) setState(() => selectedType = v);
                },
                items: [
                  for (final t in MapGroupType.values)
                    MacosPopupMenuItem<MapGroupType>(
                      value: t,
                      child: Text(_mapGroupTypeDisplayLabel(t)),
                    ),
                ],
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
                    if (nameController.text.trim().isEmpty) return;
                    notifier.createGroup(
                      nameController.text.trim(),
                      selectedType,
                      parentId: parentId,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameGroupDialog(
    BuildContext context,
    ProjectMapGroup group,
    EditorNotifier notifier,
  ) async {
    final controller = TextEditingController(text: group.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Rename Group',
      controller: controller,
      confirmLabel: 'Rename',
    );
    if (!ok || !context.mounted) return;
    notifier.renameGroup(group.id, controller.text.trim());
  }
}

class _MapNode extends StatelessWidget {
  final ProjectMapEntry map;
  final dynamic state;
  final EditorNotifier notifier;
  final int depth;

  const _MapNode({
    required this.map,
    required this.state,
    required this.notifier,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = state.activeMap?.id == map.id;

    return EditorSidebarListRow(
      selected: isSelected,
      onTap: () => notifier.loadMap(map.relativePath),
      onSecondaryTapDown: (details) => _showMapContextMenu(
        context,
        details.globalPosition,
        map,
        notifier,
      ),
      leftIndent: 14 + 16.0 * depth,
      leading: MacosIcon(_getRoleIcon(map.role), size: 16),
      title: Text(map.name),
      trailing: isSelected
          ? const MacosIcon(
              CupertinoIcons.pencil,
              size: 14,
              color: MacosColors.white,
            )
          : null,
    );
  }

  IconData _getRoleIcon(MapRole role) {
    return switch (role) {
      MapRole.exterior => CupertinoIcons.sun_max,
      MapRole.interior => CupertinoIcons.house,
      MapRole.basement => CupertinoIcons.arrow_down_circle,
      MapRole.upper_floor => CupertinoIcons.arrow_up_circle,
      MapRole.connector => CupertinoIcons.link,
      MapRole.gate => CupertinoIcons.square_arrow_right,
      MapRole.section => CupertinoIcons.square_split_2x1,
      MapRole.room => CupertinoIcons.square_grid_2x2,
      MapRole.sub_area => CupertinoIcons.layers_alt,
    };
  }

  Future<void> _showMapContextMenu(
    BuildContext context,
    Offset position,
    ProjectMapEntry mapEntry,
    EditorNotifier notifier,
  ) async {
    final action = await showMacosEditorContextMenu<String>(
      context: context,
      globalPosition: position,
      actions: const [
        MacosEditorSheetAction(label: 'Rename Map', value: 'rename'),
        MacosEditorSheetAction(label: 'Duplicate Map', value: 'duplicate'),
        MacosEditorSheetAction(
          label: 'Delete Map',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'rename':
        _showRenameMapDialog(context, mapEntry, notifier);
      case 'duplicate':
        notifier.duplicateMap(mapEntry.id);
      case 'delete':
        notifier.deleteMap(mapEntry.id);
    }
  }

  Future<void> _showRenameMapDialog(
    BuildContext context,
    ProjectMapEntry mapEntry,
    EditorNotifier notifier,
  ) async {
    final controller = TextEditingController(text: mapEntry.id);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Rename Map',
      controller: controller,
      confirmLabel: 'Rename',
    );
    if (!ok || !context.mounted) return;
    notifier.renameMap(mapEntry.id, controller.text.trim());
  }
}

class _TilesetLibraryFolderNode extends StatelessWidget {
  const _TilesetLibraryFolderNode({
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
      onSecondaryTapDown: (d) => _openTilesetLibraryFolderContextMenu(
        context,
        folder: folder,
        project: project,
        notifier: notifier,
        anchorGlobal: d.globalPosition,
      ),
      trailing: Builder(
        builder: (btnContext) => EditorToolbarIconButton(
          icon: CupertinoIcons.ellipsis_vertical,
          tooltip: 'Folder actions',
          iconSize: 16,
          onPressed: () => _openTilesetLibraryFolderContextMenu(
            context,
            folder: folder,
            project: project,
            notifier: notifier,
            anchorGlobal: editorMenuAnchorBelowWidget(btnContext),
          ),
        ),
      ),
      children: [
        ...branch.childFolders.map(
          (b) => _TilesetLibraryFolderNode(
            branch: b,
            depth: depth + 1,
            project: project,
            notifier: notifier,
            selectedTilesetId: selectedTilesetId,
            scopeLabel: scopeLabel,
          ),
        ),
        ...branch.tilesets.map(
          (t) => _TilesetNode(
            tileset: t,
            project: project,
            notifier: notifier,
            selected: selectedTilesetId == t.id,
            leftIndent: indent + 14,
            scopeLabel: scopeLabel(t),
          ),
        ),
      ],
    );
  }
}

class _TilesetNode extends StatelessWidget {
  final ProjectTilesetEntry tileset;
  final ProjectManifest project;
  final EditorNotifier notifier;
  final bool selected;
  final double leftIndent;
  final String scopeLabel;

  const _TilesetNode({
    required this.tileset,
    required this.project,
    required this.notifier,
    required this.selected,
    this.leftIndent = 6,
    required this.scopeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return EditorSidebarListRow(
      selected: selected,
      onTap: () => notifier.selectTilesetWorkspace(tileset.id),
      onSecondaryTapDown: (d) =>
          _showTilesetMenu(context, anchorGlobal: d.globalPosition),
      leftIndent: leftIndent,
      leadingIconUnselectedColor:
          tileset.isWorldTileset ? EditorPaintColors.amberAccent : null,
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
        builder: (btnContext) => EditorToolbarIconButton(
          icon: CupertinoIcons.ellipsis_vertical,
          tooltip: 'Tileset actions',
          iconSize: 16,
          color: selected ? MacosColors.white : null,
          onPressed: () => _showTilesetMenu(
            context,
            anchorGlobal: editorMenuAnchorBelowWidget(btnContext),
          ),
        ),
      ),
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
        const MacosEditorSheetAction(label: 'Rename', value: 'rename'),
        const MacosEditorSheetAction(label: 'Move Up', value: 'move_up'),
        const MacosEditorSheetAction(label: 'Move Down', value: 'move_down'),
        const MacosEditorSheetAction(
            label: 'Set as Global', value: 'make_global'),
        const MacosEditorSheetAction(
          label: 'Attach to Group',
          value: 'assign_group',
        ),
        const MacosEditorSheetAction(
          label: 'Move to folder…',
          value: 'library_folder',
        ),
        if (tileset.folderId != null && tileset.folderId!.trim().isNotEmpty)
          const MacosEditorSheetAction(
            label: 'Move to library root',
            value: 'library_root',
          ),
        if (tileset.scope == TilesetScope.global)
          MacosEditorSheetAction(
            label: tileset.isWorldTileset
                ? 'Unset World Tileset'
                : 'Set as World Tileset',
            value: 'toggle_world',
          ),
        const MacosEditorSheetAction(
          label: 'Delete Tileset',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'rename':
        _showRenameTilesetDialog(context);
      case 'make_global':
        notifier.updateProjectTileset(
          tilesetId: tileset.id,
          scope: TilesetScope.global,
          groupId: null,
        );
      case 'assign_group':
        _showAssignGroupDialog(context);
      case 'library_folder':
        await _openAssignTilesetLibraryFolderSheet(
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
                  final g = await showCupertinoListPicker<ProjectMapGroup>(
                    context: ctx,
                    title: 'Group',
                    items: groups,
                    labelOf: (x) => x.name,
                  );
                  if (g != null) {
                    setState(() => selectedGroupId = g.id);
                  }
                },
                child: Text(
                  groups.firstWhere((g) => g.id == selectedGroupId).name,
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
