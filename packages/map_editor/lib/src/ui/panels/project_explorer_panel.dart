import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';

class ProjectExplorerPanel extends ConsumerWidget {
  const ProjectExplorerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EditorChrome.panelBackground(context),
      ),
      child: Column(
        children: [
          _buildHeader(context, state, notifier),
          const EditorHorizontalDivider(),
          Expanded(
            child: project == null
                ? Center(
                    child: Text(
                      'No project loaded',
                      style: TextStyle(
                        color: CupertinoColors.placeholderText
                            .resolveFrom(context),
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
    final accent = EditorChrome.activeAccent(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Icon(CupertinoIcons.tree, size: 18, color: accent),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'WORLD EXPLORER',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.9,
              ),
            ),
          ),
          EditorToolbarIconButton(
            onPressed: state.project != null
                ? () => _showImportTilesetDialog(context, state, notifier)
                : null,
            icon: CupertinoIcons.photo_on_rectangle,
            tooltip: 'Import Tileset',
            iconSize: 18,
          ),
          EditorToolbarIconButton(
            onPressed: state.project != null
                ? () => _showCreateGroupDialog(context, notifier)
                : null,
            icon: CupertinoIcons.folder_badge_plus,
            tooltip: 'New Root Group',
            iconSize: 18,
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
    final hasTilesets = project.tilesets.isNotEmpty;

    if (rootMaps.isEmpty && rootGroups.isEmpty && !hasTilesets) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'World is empty',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () => _showCreateGroupDialog(context, notifier),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 16),
                  SizedBox(width: 6),
                  Text('Add City or Route'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildTilesetsSection(context, project, state, notifier),
        const SizedBox(height: 20),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'UNGROUPED MAPS',
              style: TextStyle(
                fontSize: 9,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...rootMaps.map(
            (m) => _MapNode(
              map: m,
              state: state,
              notifier: notifier,
              depth: 0,
            ),
          ),
        ],
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'GLOBAL',
              style: TextStyle(
                fontSize: 9,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                group.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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

    return CupertinoDisclosureTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: EdgeInsets.zero,
      leading: const Icon(
        CupertinoIcons.square_grid_2x2,
        size: 18,
        color: EditorPaintColors.amberAccent,
      ),
      title: Text(
        'TILESETS',
        style: TextStyle(
          fontSize: 11,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
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
    final color = _getGroupColor(group.type);

    return CupertinoDisclosureTile(
      tilePadding: EdgeInsets.only(left: 16.0 * depth + 8.0, right: 4),
      childrenPadding: EdgeInsets.zero,
      leading: Icon(_getGroupIcon(group.type), size: 18, color: color),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
      onSecondaryTapDown: (d) =>
          _showGroupContextMenu(context, group, notifier,
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

  Color _getGroupColor(MapGroupType type) {
    return switch (type) {
      MapGroupType.city => EditorPaintColors.orangeAccent,
      MapGroupType.route => EditorPaintColors.greenAccent,
      MapGroupType.dungeon => EditorPaintColors.redAccent,
      MapGroupType.cave => EditorPaintColors.brown,
      MapGroupType.forest => EditorPaintColors.green,
      _ => EditorPaintColors.lightBlueAccent,
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
    final accent = EditorChrome.activeAccent(context);
    final secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showMapContextMenu(context, details.globalPosition, map, notifier),
      child: CupertinoButton(
        padding: EdgeInsets.only(
          left: 32.0 + (16.0 * depth),
          right: 16,
          top: 6,
          bottom: 6,
        ),
        alignment: Alignment.centerLeft,
        onPressed: () => notifier.loadMap(map.relativePath),
        child: Row(
          children: [
            Icon(
              _getRoleIcon(map.role),
              size: 16,
              color: isSelected ? accent : secondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                map.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? accent : CupertinoColors.label.resolveFrom(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(CupertinoIcons.pencil, size: 12, color: accent),
          ],
        ),
      ),
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
    final accent = EditorChrome.activeAccent(context);
    final secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);

    return GestureDetector(
      onSecondaryTapDown: (d) =>
          _showTilesetMenu(context, anchorGlobal: d.globalPosition),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : EditorPaintColors.transparent,
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.only(left: 24, right: 4, top: 4, bottom: 4),
          alignment: Alignment.centerLeft,
          onPressed: () => notifier.selectTilesetWorkspace(tileset.id),
          child: Row(
            children: [
              Icon(
                tileset.isWorldTileset
                    ? CupertinoIcons.globe
                    : (tileset.scope == TilesetScope.global
                        ? CupertinoIcons.circle_grid_hex
                        : CupertinoIcons.tag),
                size: 16,
                color: selected
                    ? EditorPaintColors.blue200
                    : (tileset.isWorldTileset
                        ? EditorPaintColors.amberAccent
                        : secondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tileset.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? EditorPaintColors.blue100
                            : CupertinoColors.label.resolveFrom(context),
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '${tileset.id} | sort ${tileset.sortOrder}',
                      style: TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (btnContext) => EditorToolbarIconButton(
                  icon: CupertinoIcons.ellipsis_vertical,
                  tooltip: 'Tileset actions',
                  iconSize: 16,
                  onPressed: () => _showTilesetMenu(
                    context,
                    anchorGlobal: editorMenuAnchorBelowWidget(btnContext),
                  ),
                ),
              ),
            ],
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
        const MacosEditorSheetAction(label: 'Set as Global', value: 'make_global'),
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
