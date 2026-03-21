import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../features/editor/state/editor_notifier.dart';

class ProjectExplorerPanel extends ConsumerWidget {
  const ProjectExplorerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          _buildHeader(context, state, notifier),
          const Divider(height: 1),
          Expanded(
            child: project == null
                ? const Center(
                    child: Text('No project loaded',
                        style: TextStyle(color: Colors.white24)))
                : _buildTree(context, project, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, dynamic state, EditorNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Icon(Icons.account_tree_outlined, size: 18, color: Colors.blue),
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
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            onPressed: state.project != null
                ? () => _showImportTilesetDialog(context, state, notifier)
                : null,
            tooltip: 'Import Tileset',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            onPressed: state.project != null
                ? () => _showCreateGroupDialog(context, notifier)
                : null,
            tooltip: 'New Root Group',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildTree(BuildContext context, ProjectManifest project,
      dynamic state, EditorNotifier notifier) {
    final rootMaps = project.maps.where((m) => m.groupId == null).toList();
    final rootGroups =
        project.groups.where((g) => g.parentGroupId == null).toList();
    final hasTilesets = project.tilesets.isNotEmpty;

    if (rootMaps.isEmpty && rootGroups.isEmpty && !hasTilesets) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('World is empty',
                style: TextStyle(color: Colors.white24)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context, notifier),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add City or Route'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildTilesetsSection(context, project, state, notifier),
        const Divider(height: 20),
        ...rootGroups.map((g) => _GroupNode(
            group: g,
            project: project,
            state: state,
            notifier: notifier,
            depth: 0)),
        if (rootMaps.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('UNGROUPED MAPS',
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.white38,
                    fontWeight: FontWeight.bold)),
          ),
          ...rootMaps.map((m) =>
              _MapNode(map: m, state: state, notifier: notifier, depth: 0)),
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
        state.selectedTilesetEditorId ?? state.activeMap?.tilesetId;
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

    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: EdgeInsets.zero,
      leading: const Icon(Icons.grid_view, size: 18, color: Colors.amber),
      title: const Text(
        'TILESETS',
        style: TextStyle(
          fontSize: 11,
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      children: [
        if (project.tilesets.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Text('No tilesets imported',
                style: TextStyle(color: Colors.white38)),
          ),
        if (globalTilesets.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'GLOBAL',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ...globalTilesets.map((tileset) => _TilesetNode(
                tileset: tileset,
                project: project,
                notifier: notifier,
                selected: selectedTilesetId == tileset.id,
              )),
        ],
        for (final group in sortedGroups)
          if (tilesetsByGroup[group.id]?.isNotEmpty ?? false) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  group.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ...tilesetsByGroup[group.id]!.map((tileset) => _TilesetNode(
                  tileset: tileset,
                  project: project,
                  notifier: notifier,
                  selected: selectedTilesetId == tileset.id,
                )),
          ],
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

    final formKey = GlobalKey<FormState>();
    final defaultName = p.basenameWithoutExtension(sourcePath);
    final nameController = TextEditingController(text: defaultName);
    var scope = TilesetScope.global;
    String? selectedGroupId =
        project.groups.isNotEmpty ? project.groups.first.id : null;
    var isWorld = project.tilesets.every((t) => !t.isWorldTileset);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Import Tileset'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    p.basename(sourcePath),
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tileset Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TilesetScope>(
                  value: scope,
                  decoration: const InputDecoration(labelText: 'Scope'),
                  items: const [
                    DropdownMenuItem(
                      value: TilesetScope.global,
                      child: Text('Global'),
                    ),
                    DropdownMenuItem(
                      value: TilesetScope.group,
                      child: Text('Group'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => scope = value);
                    }
                  },
                ),
                if (scope == TilesetScope.group) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGroupId,
                    decoration: const InputDecoration(labelText: 'Group'),
                    items: project.groups
                        .map((group) => DropdownMenuItem(
                              value: group.id,
                              child: Text(group.name),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedGroupId = value),
                  ),
                ],
                if (scope == TilesetScope.global) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isWorld,
                    title: const Text('Mark as world tileset'),
                    onChanged: (value) =>
                        setState(() => isWorld = value ?? false),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                if (scope == TilesetScope.group && selectedGroupId == null)
                  return;
                Navigator.pop(context);
                await notifier.importProjectTileset(
                  sourcePath: sourcePath,
                  name: nameController.text.trim(),
                  scope: scope,
                  groupId: scope == TilesetScope.group ? selectedGroupId : null,
                  isWorldTileset:
                      scope == TilesetScope.global ? isWorld : false,
                );
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, EditorNotifier notifier,
      {String? parentId}) {
    final nameController = TextEditingController();
    MapGroupType selectedType = MapGroupType.city;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(parentId == null ? 'New Root Group' : 'New Sub-Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MapGroupType>(
                value: selectedType,
                items: MapGroupType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v!),
                decoration: const InputDecoration(labelText: 'Group Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  notifier.createGroup(nameController.text, selectedType,
                      parentId: parentId);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
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

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(_getGroupIcon(group.type),
            size: 18, color: _getGroupColor(group.type)),
        title: Text(group.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(group.type.name.toUpperCase(),
            style: const TextStyle(fontSize: 9, color: Colors.white38)),
        tilePadding: EdgeInsets.only(left: 16.0 * depth + 8.0, right: 8.0),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        controlAffinity: ListTileControlAffinity.trailing,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, size: 16),
          onPressed: () => _showGroupContextMenu(context, group, notifier),
        ),
        children: [
          ...childrenGroups.map((g) => _GroupNode(
              group: g,
              project: project,
              state: state,
              notifier: notifier,
              depth: depth + 1)),
          ...childrenMaps.map((m) => _MapNode(
              map: m, state: state, notifier: notifier, depth: depth + 1)),
        ],
      ),
    );
  }

  IconData _getGroupIcon(MapGroupType type) {
    switch (type) {
      case MapGroupType.city:
        return Icons.location_city;
      case MapGroupType.village:
        return Icons.holiday_village;
      case MapGroupType.route:
        return Icons.map;
      case MapGroupType.dungeon:
        return Icons.castle;
      case MapGroupType.cave:
        return Icons.landscape;
      case MapGroupType.forest:
        return Icons.park;
      case MapGroupType.tower:
        return Icons.fort;
      case MapGroupType.facility:
        return Icons.business;
      case MapGroupType.special:
        return Icons.star;
    }
  }

  Color _getGroupColor(MapGroupType type) {
    switch (type) {
      case MapGroupType.city:
        return Colors.orangeAccent;
      case MapGroupType.route:
        return Colors.greenAccent;
      case MapGroupType.dungeon:
        return Colors.redAccent;
      case MapGroupType.cave:
        return Colors.brown;
      case MapGroupType.forest:
        return Colors.green;
      default:
        return Colors.blueAccent;
    }
  }

  void _showGroupContextMenu(
      BuildContext context, ProjectMapGroup group, EditorNotifier notifier) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position =
        (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx + 250, position.dy, 40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          onTap: () => Future.delayed(Duration.zero,
              () => _showCreateMapDialog(context, group.id, notifier)),
          child: const _ContextMenuItem(
              icon: Icons.add_location_alt_outlined, label: 'Add Map'),
        ),
        PopupMenuItem(
          onTap: () => Future.delayed(Duration.zero,
              () => _showCreateSubGroupDialog(context, group.id, notifier)),
          child: const _ContextMenuItem(
              icon: Icons.create_new_folder_outlined, label: 'Add Sub-Group'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () => Future.delayed(Duration.zero,
              () => _showRenameGroupDialog(context, group, notifier)),
          child: const _ContextMenuItem(
              icon: Icons.edit_outlined, label: 'Rename Group'),
        ),
        PopupMenuItem(
          onTap: () => notifier.deleteGroup(group.id),
          child: const _ContextMenuItem(
              icon: Icons.delete_outline,
              label: 'Delete Group',
              color: Colors.redAccent),
        ),
      ],
    );
  }

  void _showCreateMapDialog(
      BuildContext context, String groupId, EditorNotifier notifier) {
    final controller = TextEditingController();
    MapRole selectedRole = MapRole.exterior;
    final settings = state.project?.settings ?? const ProjectSettings();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Map in Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Map ID'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MapRole>(
                value: selectedRole,
                items: MapRole.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedRole = v!),
                decoration: const InputDecoration(labelText: 'Map Role'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  notifier.createMap(
                    controller.text,
                    settings.defaultMapWidth,
                    settings.defaultMapHeight,
                    groupId: groupId,
                    role: selectedRole,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSubGroupDialog(
      BuildContext context, String parentId, EditorNotifier notifier) {
    final nameController = TextEditingController();
    MapGroupType selectedType = MapGroupType.facility;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Sub-Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MapGroupType>(
                value: selectedType,
                items: MapGroupType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v!),
                decoration: const InputDecoration(labelText: 'Group Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  notifier.createGroup(nameController.text, selectedType,
                      parentId: parentId);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameGroupDialog(
      BuildContext context, ProjectMapGroup group, EditorNotifier notifier) {
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                notifier.renameGroup(group.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
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

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showMapContextMenu(context, details.globalPosition, map, notifier),
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 32.0 + (16.0 * depth), right: 16),
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(_getRoleIcon(map.role),
            size: 16, color: isSelected ? Colors.blue : Colors.white54),
        title: Text(
          map.name,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.blue : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => notifier.loadMap(map.relativePath),
        trailing: isSelected
            ? const Icon(Icons.edit, size: 12, color: Colors.blue)
            : null,
      ),
    );
  }

  IconData _getRoleIcon(MapRole role) {
    switch (role) {
      case MapRole.exterior:
        return Icons.wb_sunny_outlined;
      case MapRole.interior:
        return Icons.home_outlined;
      case MapRole.gate:
        return Icons.door_front_door_outlined;
      case MapRole.section:
        return Icons.segment;
      case MapRole.room:
        return Icons.meeting_room_outlined;
      case MapRole.sub_area:
        return Icons.layers_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  void _showMapContextMenu(BuildContext context, Offset position,
      ProjectMapEntry mapEntry, EditorNotifier notifier) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          onTap: () => Future.delayed(Duration.zero,
              () => _showRenameMapDialog(context, mapEntry, notifier)),
          child: const _ContextMenuItem(
              icon: Icons.edit_outlined, label: 'Rename Map'),
        ),
        PopupMenuItem(
          onTap: () => notifier.duplicateMap(mapEntry.id),
          child: const _ContextMenuItem(
              icon: Icons.copy_outlined, label: 'Duplicate Map'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () => notifier.deleteMap(mapEntry.id),
          child: const _ContextMenuItem(
              icon: Icons.delete_outline,
              label: 'Delete Map',
              color: Colors.redAccent),
        ),
      ],
    );
  }

  void _showRenameMapDialog(
      BuildContext context, ProjectMapEntry mapEntry, EditorNotifier notifier) {
    final controller = TextEditingController(text: mapEntry.id);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Map'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New ID'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                notifier.renameMap(mapEntry.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
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
    return Material(
      color:
          selected ? Colors.blue.withValues(alpha: 0.14) : Colors.transparent,
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.only(left: 24, right: 8),
        selected: selected,
        onTap: () => notifier.selectTilesetWorkspace(tileset.id),
        leading: Icon(
          tileset.isWorldTileset
              ? Icons.public
              : (tileset.scope == TilesetScope.global
                  ? Icons.language
                  : Icons.category_outlined),
          size: 16,
          color: selected
              ? Colors.blue.shade200
              : (tileset.isWorldTileset ? Colors.amber : Colors.white60),
        ),
        title: Text(
          tileset.name,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.blue.shade100 : Colors.white70,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${tileset.id} | sort ${tileset.sortOrder}',
          style: const TextStyle(fontSize: 10, color: Colors.white38),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _showRenameTilesetDialog(context);
                break;
              case 'make_global':
                notifier.updateProjectTileset(
                  tilesetId: tileset.id,
                  scope: TilesetScope.global,
                  groupId: null,
                );
                break;
              case 'assign_group':
                _showAssignGroupDialog(context);
                break;
              case 'toggle_world':
                notifier.updateProjectTileset(
                  tilesetId: tileset.id,
                  isWorldTileset: !tileset.isWorldTileset,
                );
                break;
              case 'move_up':
                notifier.reorderProjectTileset(tileset.id, -1);
                break;
              case 'move_down':
                notifier.reorderProjectTileset(tileset.id, 1);
                break;
              case 'delete':
                notifier.deleteProjectTileset(tileset.id);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child:
                  _ContextMenuItem(icon: Icons.edit_outlined, label: 'Rename'),
            ),
            const PopupMenuItem(
              value: 'move_up',
              child: _ContextMenuItem(
                  icon: Icons.keyboard_arrow_up, label: 'Move Up'),
            ),
            const PopupMenuItem(
              value: 'move_down',
              child: _ContextMenuItem(
                  icon: Icons.keyboard_arrow_down, label: 'Move Down'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'make_global',
              child: _ContextMenuItem(
                  icon: Icons.language, label: 'Set as Global'),
            ),
            const PopupMenuItem(
              value: 'assign_group',
              child: _ContextMenuItem(
                  icon: Icons.category_outlined, label: 'Attach to Group'),
            ),
            if (tileset.scope == TilesetScope.global)
              PopupMenuItem(
                value: 'toggle_world',
                child: _ContextMenuItem(
                  icon:
                      tileset.isWorldTileset ? Icons.public_off : Icons.public,
                  label: tileset.isWorldTileset
                      ? 'Unset World Tileset'
                      : 'Set as World Tileset',
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: _ContextMenuItem(
                icon: Icons.delete_outline,
                label: 'Delete Tileset',
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameTilesetDialog(BuildContext context) {
    final controller = TextEditingController(text: tileset.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Tileset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              notifier.updateProjectTileset(
                tilesetId: tileset.id,
                name: value,
              );
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
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

    String selectedGroupId = tileset.groupId ?? groups.first.id;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Attach Tileset to Group'),
          content: DropdownButtonFormField<String>(
            value: selectedGroupId,
            items: groups
                .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedGroupId = value);
              }
            },
            decoration: const InputDecoration(labelText: 'Group'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                notifier.updateProjectTileset(
                  tilesetId: tileset.id,
                  scope: TilesetScope.group,
                  groupId: selectedGroupId,
                );
                Navigator.pop(context);
              },
              child: const Text('Attach'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ContextMenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
