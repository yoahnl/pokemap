import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';

class LayersPanel extends ConsumerWidget {
  const LayersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'LAYERS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Add Layer',
                  onPressed: map == null
                      ? null
                      : () => _showAddLayerDialog(context, notifier),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  tooltip: 'Remove All Layers',
                  onPressed: map == null
                      ? null
                      : () => _showDeleteAllLayersDialog(context, notifier),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (map == null)
            const Expanded(
              child: Center(
                child: Text(
                  'No map loaded',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            Expanded(
              child: _LayerList(
                map: map,
                activeLayerId: state.activeLayerId,
                notifier: notifier,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddLayerDialog(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    var selectedType = MapLayerKind.tile;
    var shouldSave = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Layer'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<MapLayerKind>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: MapLayerKind.tile,
                      child: Text('Tile Layer'),
                    ),
                    DropdownMenuItem(
                      value: MapLayerKind.collision,
                      child: Text('Collision Layer'),
                    ),
                    DropdownMenuItem(
                      value: MapLayerKind.terrain,
                      child: Text('Terrain Layer'),
                    ),
                    DropdownMenuItem(
                      value: MapLayerKind.object,
                      child: Text('Object Layer'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                shouldSave = true;
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (!shouldSave) return;
    notifier.addMapLayer(
      kind: selectedType,
      name: nameController.text.trim(),
    );
  }

  Future<void> _showDeleteAllLayersDialog(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    var shouldDelete = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove All Layers'),
        content: const Text(
          'All current layers will be removed. The map can stay with zero layers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              shouldDelete = true;
              Navigator.pop(context);
            },
            child: const Text('Remove All'),
          ),
        ],
      ),
    );
    if (!shouldDelete) return;
    notifier.deleteAllMapLayers();
  }
}

class _LayerList extends StatelessWidget {
  final MapData map;
  final String? activeLayerId;
  final EditorNotifier notifier;

  const _LayerList({
    required this.map,
    required this.activeLayerId,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    if (map.layers.isEmpty) {
      return const Center(
        child: Text(
          'No layers in this map',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      itemCount: map.layers.length,
      itemBuilder: (context, index) {
        final layer = map.layers[index];
        final isActive = layer.id == activeLayerId;
        final canMoveUp = index > 0;
        final canMoveDown = index < map.layers.length - 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isActive
              ? Colors.blue.withValues(alpha: 0.12)
              : Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              children: [
                InkWell(
                  onTap: () => notifier.setActiveLayer(layer.id),
                  child: Row(
                    children: [
                      Icon(
                        _iconForLayer(layer),
                        size: 16,
                        color: isActive ? Colors.blue : Colors.white60,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              layer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isActive ? Colors.blue : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_labelForLayer(layer)} • ${layer.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => notifier.setMapLayerVisibility(
                          layer.id,
                          !layer.isVisible,
                        ),
                        icon: Icon(
                          layer.isVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        tooltip: layer.isVisible ? 'Hide layer' : 'Show layer',
                      ),
                      IconButton(
                        onPressed: canMoveUp
                            ? () => notifier.moveMapLayerUp(layer.id)
                            : null,
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        tooltip: 'Move up',
                      ),
                      IconButton(
                        onPressed: canMoveDown
                            ? () => notifier.moveMapLayerDown(layer.id)
                            : null,
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        tooltip: 'Move down',
                      ),
                      IconButton(
                        onPressed: () => _showRenameLayerDialog(
                          context,
                          notifier,
                          layer,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Rename layer',
                      ),
                      IconButton(
                        onPressed: () => _showDeleteLayerDialog(
                          context,
                          notifier,
                          layer,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: 'Delete layer',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'Opacity',
                      style: TextStyle(fontSize: 10, color: Colors.white60),
                    ),
                    Expanded(
                      child: Slider(
                        value: layer.opacity.clamp(0.0, 1.0),
                        min: 0,
                        max: 1,
                        divisions: 20,
                        label: '${(layer.opacity * 100).round()}%',
                        onChanged: (value) {
                          notifier.setMapLayerOpacity(layer.id, value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${(layer.opacity * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white60),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => Icons.grid_on_outlined,
      collision: (_) => Icons.shield_outlined,
      terrain: (_) => Icons.terrain_outlined,
      object: (_) => Icons.category_outlined,
    );
  }

  String _labelForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => 'tile',
      collision: (_) => 'collision',
      terrain: (_) => 'terrain',
      object: (_) => 'object',
    );
  }

  Future<void> _showRenameLayerDialog(
    BuildContext context,
    EditorNotifier notifier,
    MapLayer layer,
  ) async {
    final controller = TextEditingController(text: layer.name);
    var shouldSave = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Layer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              shouldSave = true;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!shouldSave) return;
    notifier.renameMapLayer(layer.id, controller.text.trim());
  }

  Future<void> _showDeleteLayerDialog(
    BuildContext context,
    EditorNotifier notifier,
    MapLayer layer,
  ) async {
    var shouldDelete = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layer'),
        content: Text('Delete "${layer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              shouldDelete = true;
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!shouldDelete) return;
    notifier.deleteMapLayer(layer.id);
  }
}
