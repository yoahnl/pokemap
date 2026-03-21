import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../features/editor/state/editor_notifier.dart';

class TopToolbar extends ConsumerWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('RPG Editor', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          IconButton(
            onPressed: () => _showNewProjectDialog(context, notifier),
            icon: const Icon(Icons.create_new_folder, size: 20),
            tooltip: 'New Project',
          ),
          IconButton(
            onPressed: () async {
              String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory != null) {
                final manifestPath = p.join(selectedDirectory, 'project.json');
                await notifier.loadProject(manifestPath);
              }
            },
            icon: const Icon(Icons.folder_open, size: 20),
            tooltip: 'Open Project',
          ),
          const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          IconButton(
            onPressed: state.project != null && state.fileSystem != null
              ? () => _showNewMapDialog(context, notifier)
              : null,
            icon: const Icon(Icons.add_location_alt, size: 20),
            tooltip: 'New Map (Root)',
          ),
          IconButton(
            onPressed: state.activeMap != null
              ? () => notifier.saveActiveMap()
              : null,
            icon: state.isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.save, size: 20, color: state.isDirty ? Colors.blue : null),
            tooltip: 'Save Map',
          ),
          const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          IconButton(
            onPressed: () => notifier.zoom(0.1),
            icon: const Icon(Icons.zoom_in, size: 20),
            tooltip: 'Zoom In',
          ),
          IconButton(
            onPressed: () => notifier.zoom(-0.1),
            icon: const Icon(Icons.zoom_out, size: 20),
            tooltip: 'Zoom Out',
          ),
          const Spacer(),
          if (state.statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(state.statusMessage!, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ),
        ],
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context, EditorNotifier notifier) {
    final controller = TextEditingController(text: 'My New Project');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Project Name', hintText: 'The name of your game'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                String? baseDir = await FilePicker.platform.getDirectoryPath();
                if (baseDir != null) {
                  // Créer un sous-dossier propre pour le projet
                  final projectDir = p.join(baseDir, name.replaceAll(' ', '_').toLowerCase());
                  await notifier.createProject(name, projectDir);
                }
              }
            },
            child: const Text('Create Project'),
          ),
        ],
      ),
    );
  }

  void _showNewMapDialog(BuildContext context, EditorNotifier notifier) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Root Map'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Map ID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                notifier.createMap(controller.text, 20, 15);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
