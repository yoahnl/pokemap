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
          _buildHeader(context, state, notifier),
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

  Widget _buildHeader(
    BuildContext context,
    dynamic state,
    EditorNotifier notifier,
  ) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const explorerAccent = EditorChrome.accentCyan;
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
                  explorerAccent.withValues(alpha: 0.22),
                  EditorChrome.accentPrune.withValues(alpha: 0.14),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.square_stack_3d_up,
              size: 18,
              color: explorerAccent,
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
          _SidebarHeaderAction(
            enabled: state.project != null,
            icon: CupertinoIcons.photo_on_rectangle,
            tooltip: 'Import Tileset',
            onPressed: () => _showImportTilesetDialog(context, state, notifier),
          ),
          const SizedBox(width: 6),
          _SidebarHeaderAction(
            enabled: state.project != null,
            icon: CupertinoIcons.folder_badge_plus,
            tooltip: 'New Root Group',
            onPressed: () => _showCreateGroupDialog(context, notifier),
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
            child: _buildWorldIsland(context, worldChildren),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: _buildTilesetsSection(context, project, state, notifier),
      ),
    );
  }

  Widget _buildWorldIsland(
    BuildContext context,
    List<Widget> worldChildren,
  ) {
    const worldAccent = EditorChrome.accentCyan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(
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
    final globalTilesets =
        project.tilesets.where((t) => t.scope == TilesetScope.global).toList()
          ..sort((a, b) {
            if (a.isWorldTileset != b.isWorldTileset) {
              return a.isWorldTileset ? -1 : 1;
            }
            final sortCompare = a.sortOrder.compareTo(b.sortOrder);
            if (sortCompare != 0) return sortCompare;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

    final groupedTilesets = project.tilesets
        .where((t) => t.scope == TilesetScope.group && t.groupId != null)
        .toList()
      ..sort((a, b) {
        final groupCompare = (a.groupId ?? '').compareTo(b.groupId ?? '');
        if (groupCompare != 0) return groupCompare;
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final tilesetsByGroup = <String, List<ProjectTilesetEntry>>{};
    for (final tileset in groupedTilesets) {
      final key = tileset.groupId!;
      tilesetsByGroup.putIfAbsent(key, () => []).add(tileset);
    }

    final sortedGroups = project.groups.toList()
      ..sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final children = <Widget>[
      if (project.tilesets.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Text(
            'No tilesets imported',
            style: TextStyle(
              color: CupertinoColors.placeholderText.resolveFrom(context),
            ),
          ),
        ),
      if (globalTilesets.isNotEmpty) ...[
        const EditorSidebarSectionTitle('GLOBAL', leftInset: 14),
        ...globalTilesets.map(
          (tileset) => _TilesetNode(
            tileset: tileset,
            project: project,
            notifier: notifier,
            selected: selectedTilesetId == tileset.id,
          ),
        ),
      ],
      for (final group in sortedGroups)
        if (tilesetsByGroup[group.id]?.isNotEmpty ?? false) ...[
          EditorSidebarSectionTitle(group.name.toUpperCase(), leftInset: 14),
          ...tilesetsByGroup[group.id]!.map(
            (tileset) => _TilesetNode(
              tileset: tileset,
              project: project,
              notifier: notifier,
              selected: selectedTilesetId == tileset.id,
            ),
          ),
        ],
    ];

    final theme = MacosTheme.of(context);
    final tilesetsTitleBase = theme.typography.body;
    final tilesetsTitleDark = theme.brightness == Brightness.dark;

    return CupertinoDisclosureTile(
      useEditorMacosSidebarDisclosureStyle: true,
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      childrenPadding: EdgeInsets.zero,
      leading: const MacosIcon(CupertinoIcons.square_grid_2x2, size: 16),
      title: Text(
        'TILESETS',
        style: tilesetsTitleBase.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: (tilesetsTitleBase.fontSize ?? 14) * 0.85,
          color: tilesetsTitleDark
              ? MacosColors.white.withValues(alpha: 0.3)
              : MacosColors.black.withValues(alpha: 0.3),
        ),
      ),
      children: children,
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

    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 480,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
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
        ),
      ),
    );

    if (!shouldImport) return;
    await notifier.importProjectTileset(
      sourcePath: sourcePath,
      name: nameController.text.trim(),
      scope: scope,
      groupId: scope == TilesetScope.group ? selectedGroupId : null,
      isWorldTileset: scope == TilesetScope.global ? isWorld : false,
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
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () async {
                  final t = await showCupertinoListPicker<MapGroupType>(
                    context: ctx,
                    title: 'Group Type',
                    items: MapGroupType.values,
                    labelOf: (x) => x.name.toUpperCase(),
                  );
                  if (t != null) setState(() => selectedType = t);
                },
                child: Text('Type: ${selectedType.name.toUpperCase()}'),
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
                    if (nameController.text.isEmpty) return;
                    notifier.createGroup(
                      nameController.text,
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
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () async {
                  final t = await showCupertinoListPicker<MapGroupType>(
                    context: ctx,
                    title: 'Group Type',
                    items: MapGroupType.values,
                    labelOf: (x) => x.name.toUpperCase(),
                  );
                  if (t != null) setState(() => selectedType = t);
                },
                child: Text('Type: ${selectedType.name.toUpperCase()}'),
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
                    if (nameController.text.isEmpty) return;
                    notifier.createGroup(
                      nameController.text,
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

class _TilesetNode extends StatelessWidget {
  final ProjectTilesetEntry tileset;
  final ProjectManifest project;
  final EditorNotifier notifier;
  final bool selected;

  const _TilesetNode({
    required this.tileset,
    required this.project,
    required this.notifier,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return EditorSidebarListRow(
      selected: selected,
      onTap: () => notifier.selectTilesetWorkspace(tileset.id),
      onSecondaryTapDown: (d) =>
          _showTilesetMenu(context, anchorGlobal: d.globalPosition),
      leftIndent: 6,
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
      subtitle: Text('${tileset.id} | sort ${tileset.sortOrder}'),
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
