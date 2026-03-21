import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

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
          const Text('WORLD EXPLORER',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.1)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            onPressed: state.project != null
                ? () => _showCreateGroupDialog(context, notifier)
                : null,
            tooltip: 'New Root Group',
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

    if (rootMaps.isEmpty && rootGroups.isEmpty) {
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
                  notifier.createMap(controller.text, 20, 15,
                      groupId: groupId, role: selectedRole);
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
