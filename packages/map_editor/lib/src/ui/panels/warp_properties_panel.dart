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
  final _targetXController = TextEditingController();
  final _targetYController = TextEditingController();
  String? _boundWarpId;
  String? _selectedTargetMapId;

  @override
  void dispose() {
    _idController.dispose();
    _targetXController.dispose();
    _targetYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final project = state.project;
    final projectMaps = project == null
        ? <ProjectMapEntry>[]
        : List<ProjectMapEntry>.from(project.maps);
    projectMaps.sort((a, b) {
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    final projectMapById = <String, ProjectMapEntry>{
      for (final mapEntry in projectMaps) mapEntry.id: mapEntry,
    };
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
                            '(${warp.pos.x}, ${warp.pos.y}) -> ${_buildTargetMapLabel(warp.targetMapId, projectMapById)} (${warp.targetPos.x}, ${warp.targetPos.y})',
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
                      projectMaps: projectMaps,
                      projectMapById: projectMapById,
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
    required List<ProjectMapEntry> projectMaps,
    required Map<String, ProjectMapEntry> projectMapById,
  }) {
    final currentTargetMapEntry = projectMapById[selectedWarp.targetMapId];
    final currentTargetMapLabel = currentTargetMapEntry == null
        ? 'Missing map: ${selectedWarp.targetMapId}'
        : '${currentTargetMapEntry.name} (${currentTargetMapEntry.id})';
    final canCreateReturnWarp = currentTargetMapEntry != null;
    final pickedTargetMapId = _selectedTargetMapId;
    final pickedTargetMapExists = pickedTargetMapId != null &&
        projectMapById.containsKey(pickedTargetMapId);

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
        const SizedBox(height: 4),
        Text(
          'Destination: $currentTargetMapLabel at (${selectedWarp.targetPos.x}, ${selectedWarp.targetPos.y})',
          style: TextStyle(
            fontSize: 11,
            color:
                currentTargetMapEntry == null ? Colors.amber : Colors.white54,
          ),
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
        DropdownButtonFormField<String>(
          key: ValueKey('warp_target_map_${_boundWarpId ?? 'none'}'),
          initialValue: pickedTargetMapExists ? pickedTargetMapId : null,
          isDense: true,
          decoration: const InputDecoration(
            labelText: 'Target Map',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          hint: Text(
            pickedTargetMapId == null
                ? 'Select target map'
                : 'Missing: $pickedTargetMapId',
            overflow: TextOverflow.ellipsis,
          ),
          items: projectMaps
              .map(
                (mapEntry) => DropdownMenuItem<String>(
                  value: mapEntry.id,
                  child: Text(
                    '${mapEntry.name} (${mapEntry.id})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            setState(() {
              _selectedTargetMapId = value;
            });
          },
        ),
        if (pickedTargetMapId != null && !pickedTargetMapExists) ...[
          const SizedBox(height: 6),
          Text(
            'Current target map is missing from project: $pickedTargetMapId',
            style: const TextStyle(fontSize: 11, color: Colors.amber),
          ),
        ],
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
                  final targetMapId = _selectedTargetMapId?.trim();
                  if (targetMapId == null || targetMapId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Select a target map'),
                      ),
                    );
                    return;
                  }
                  notifier.updateSelectedWarp(
                    id: _idController.text.trim(),
                    targetMapId: targetMapId,
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: canCreateReturnWarp
                ? notifier.createReciprocalWarpForSelectedWarp
                : null,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Create Return Warp'),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Creates a reciprocal warp in the target map at the destination cell.',
          style: TextStyle(fontSize: 11, color: Colors.white54),
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
      _targetXController.text = '';
      _targetYController.text = '';
      _selectedTargetMapId = null;
      return;
    }
    _idController.text = selectedWarp.id;
    _selectedTargetMapId = selectedWarp.targetMapId;
    _targetXController.text = selectedWarp.targetPos.x.toString();
    _targetYController.text = selectedWarp.targetPos.y.toString();
  }

  String _buildTargetMapLabel(
    String targetMapId,
    Map<String, ProjectMapEntry> projectMapById,
  ) {
    final targetMapEntry = projectMapById[targetMapId];
    if (targetMapEntry == null) {
      return '$targetMapId (missing)';
    }
    return '${targetMapEntry.name} (${targetMapEntry.id})';
  }
}
