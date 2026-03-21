import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/editor/state/editor_notifier.dart';

class ProjectExplorerPanel extends ConsumerWidget {
  const ProjectExplorerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    return Container(
      color: Theme.of(context).cardColor.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              project?.name ?? 'No Project',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: project == null
                ? const Center(child: Text('Create or Load Project'))
                : ListView(
                    children: [
                      ExpansionTile(
                        leading: const Icon(Icons.map, size: 18),
                        title: const Text('Maps', style: TextStyle(fontSize: 14)),
                        initiallyExpanded: true,
                        children: project.maps.map((map) => ListTile(
                          dense: true,
                          selected: state.activeMap?.id == map.id,
                          title: Text(map.name),
                          onTap: () => notifier.loadMap(map.relativePath),
                        )).toList(),
                      ),
                      ExpansionTile(
                        leading: const Icon(Icons.grid_view, size: 18),
                        title: const Text('Tilesets', style: TextStyle(fontSize: 14)),
                        children: project.tilesets.map((ts) => ListTile(
                          dense: true,
                          title: Text(ts.name),
                          onTap: () {},
                        )).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
