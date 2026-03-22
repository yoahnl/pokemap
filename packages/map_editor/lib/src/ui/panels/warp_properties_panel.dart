import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';

class WarpPropertiesPanel extends ConsumerStatefulWidget {
  const WarpPropertiesPanel({super.key});

  @override
  ConsumerState<WarpPropertiesPanel> createState() =>
      _WarpPropertiesPanelState();
}

class _WarpPropertiesPanelState extends ConsumerState<WarpPropertiesPanel> {
  final _idController = TextEditingController();
  final _targetMapIdController = TextEditingController();
  final _targetXController = TextEditingController();
  final _targetYController = TextEditingController();
  String? _boundWarpId;

  @override
  void dispose() {
    _idController.dispose();
    _targetMapIdController.dispose();
    _targetXController.dispose();
    _targetYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final selectedWarp = notifier.getSelectedWarp();
    _syncControllers(selectedWarp);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'WARPS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Text(
                  map == null ? '0' : '${map.warps.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                children: [
                  if (map.warps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'No warps on this map.\nSelect the Warp tool and click on the map to add one.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  else
                    ...map.warps.map(
                      (warp) => Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        color: warp.id == state.selectedWarpId
                            ? Colors.cyan.withValues(alpha: 0.12)
                            : Theme.of(context).scaffoldBackgroundColor,
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.alt_route_outlined,
                            size: 16,
                            color: warp.id == state.selectedWarpId
                                ? Colors.cyanAccent
                                : Colors.white60,
                          ),
                          title: Text(
                            warp.id,
                            style: TextStyle(
                              fontSize: 12,
                              color: warp.id == state.selectedWarpId
                                  ? Colors.cyanAccent
                                  : Colors.white,
                              fontWeight: warp.id == state.selectedWarpId
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '(${warp.pos.x}, ${warp.pos.y}) -> ${warp.targetMapId} (${warp.targetPos.x}, ${warp.targetPos.y})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                          onTap: () => notifier.selectWarp(warp.id),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  if (selectedWarp == null)
                    const Text(
                      'Select a warp to edit its properties.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    )
                  else
                    _buildSelectedWarpEditor(
                      context: context,
                      notifier: notifier,
                      selectedWarp: selectedWarp,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedWarpEditor({
    required BuildContext context,
    required EditorNotifier notifier,
    required MapWarp selectedWarp,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Warp',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Map position: (${selectedWarp.pos.x}, ${selectedWarp.pos.y})',
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _idController,
          decoration: const InputDecoration(
            labelText: 'ID',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _targetMapIdController,
          decoration: const InputDecoration(
            labelText: 'Target Map ID',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _targetXController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target X',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _targetYController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Y',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final x = int.tryParse(_targetXController.text.trim());
                  final y = int.tryParse(_targetYController.text.trim());
                  if (x == null || y == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Target position must be valid integers'),
                      ),
                    );
                    return;
                  }
                  notifier.updateSelectedWarp(
                    id: _idController.text.trim(),
                    targetMapId: _targetMapIdController.text.trim(),
                    targetPosX: x,
                    targetPosY: y,
                  );
                },
                child: const Text('Save Warp'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: notifier.deleteSelectedWarp,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete selected warp',
            ),
          ],
        ),
      ],
    );
  }

  void _syncControllers(MapWarp? selectedWarp) {
    final currentId = selectedWarp?.id;
    if (currentId == _boundWarpId) return;
    _boundWarpId = currentId;
    if (selectedWarp == null) {
      _idController.text = '';
      _targetMapIdController.text = '';
      _targetXController.text = '';
      _targetYController.text = '';
      return;
    }
    _idController.text = selectedWarp.id;
    _targetMapIdController.text = selectedWarp.targetMapId;
    _targetXController.text = selectedWarp.targetPos.x.toString();
    _targetYController.text = selectedWarp.targetPos.y.toString();
  }
}
