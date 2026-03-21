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

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state),
          const Divider(height: 1),
          Expanded(
            child: state.project == null
                ? const Center(
                    child: Text(
                      'No project loaded',
                      style: TextStyle(color: Colors.white24),
                    ),
                  )
                : _buildExplorerList(context, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.folder, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.project?.name ?? 'PROJECT EXPLORER',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplorerList(BuildContext context, dynamic state, EditorNotifier notifier) {
    final project = state.project as ProjectManifest;
    
    return ListView(
      children: [
        _buildSectionHeader('MAPS'),
        ...project.maps.map((mapEntry) => _buildMapItem(context, mapEntry, state, notifier)),
        const SizedBox(height: 16),
        _buildSectionHeader('TILESETS'),
        ...project.tilesets.map((tileset) => _buildTilesetItem(context, tileset)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMapItem(BuildContext context, ProjectMapEntry mapEntry, dynamic state, EditorNotifier notifier) {
    final isSelected = state.activeMap?.id == mapEntry.id;

    return GestureDetector(
      onSecondaryTapDown: (details) => _showMapContextMenu(context, details.globalPosition, mapEntry, notifier),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(
          Icons.map_outlined,
          size: 16,
          color: isSelected ? Colors.blue : Colors.white54,
        ),
        title: Text(
          mapEntry.name,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.blue : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onTap: () => notifier.loadMap(mapEntry.relativePath),
      ),
    );
  }

  Widget _buildTilesetItem(BuildContext context, ProjectTilesetEntry tileset) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.grid_on, size: 16, color: Colors.white54),
      title: Text(
        tileset.name,
        style: const TextStyle(fontSize: 13, color: Colors.white70),
      ),
      onTap: () {
        // TODO: Select tileset
      },
    );
  }

  void _showMapContextMenu(BuildContext context, Offset position, ProjectMapEntry mapEntry, EditorNotifier notifier) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          onTap: () {
            Future.delayed(Duration.zero, () => _showRenameDialog(context, mapEntry, notifier));
          },
          child: const _ContextMenuItem(icon: Icons.edit_outlined, label: 'Rename'),
        ),
        PopupMenuItem<String>(
          value: 'duplicate',
          onTap: () => notifier.duplicateMap(mapEntry.id),
          child: const _ContextMenuItem(icon: Icons.copy_outlined, label: 'Duplicate'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          onTap: () {
            Future.delayed(Duration.zero, () => _showDeleteConfirmation(context, mapEntry, notifier));
          },
          child: const _ContextMenuItem(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context, ProjectMapEntry mapEntry, EditorNotifier notifier) {
    final controller = TextEditingController(text: mapEntry.id);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Map'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New ID',
            hintText: 'e.g. pallet_town',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newId = controller.text.trim();
              if (newId.isNotEmpty && newId != mapEntry.id) {
                notifier.renameMap(mapEntry.id, newId);
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProjectMapEntry mapEntry, EditorNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Map'),
        content: Text('Are you sure you want to delete "${mapEntry.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              notifier.deleteMap(mapEntry.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
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

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

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
