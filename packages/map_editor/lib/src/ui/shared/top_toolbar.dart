import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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
            onPressed: () async {
              debugPrint('TopToolbar: New Project clicked');
              String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
              
              if (selectedDirectory != null) {
                debugPrint('TopToolbar: Selected directory: $selectedDirectory');
                await notifier.createProject('New Project', selectedDirectory);
              } else {
                debugPrint('TopToolbar: Project creation cancelled by user');
              }
            },
            icon: const Icon(Icons.create_new_folder, size: 20),
            tooltip: 'New Project',
          ),
          IconButton(
            onPressed: state.project != null && state.fileSystem != null
              ? () {
                  final id = 'map_${DateTime.now().millisecondsSinceEpoch}';
                  debugPrint('TopToolbar: Requesting new map creation: $id');
                  notifier.createMap(id, 20, 15);
                }
              : null,
            icon: const Icon(Icons.add_location_alt, size: 20),
            tooltip: 'New Map',
          ),
          const Spacer(),
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
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
