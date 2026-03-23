import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';

class MapConnectionsPanel extends ConsumerStatefulWidget {
  const MapConnectionsPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<MapConnectionsPanel> createState() =>
      _MapConnectionsPanelState();
}

class _MapConnectionsPanelState extends ConsumerState<MapConnectionsPanel> {
  late final Map<MapConnectionDirection, TextEditingController>
      _offsetControllers;
  final _selectedTargetMapIds = <MapConnectionDirection, String?>{};
  String? _boundConnectionsKey;

  @override
  void initState() {
    super.initState();
    _offsetControllers = {
      for (final direction in MapConnectionDirection.values)
        direction: TextEditingController(text: '0'),
    };
  }

  @override
  void dispose() {
    for (final controller in _offsetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final project = state.project;
    final projectMaps = project == null || map == null
        ? <ProjectMapEntry>[]
        : project.maps
            .where((entry) => entry.id != map.id)
            .toList(growable: false);
    final sortedProjectMaps = List<ProjectMapEntry>.from(projectMaps)
      ..sort((left, right) {
        final sortCompare = left.sortOrder.compareTo(right.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
    final projectMapById = <String, ProjectMapEntry>{
      for (final mapEntry in sortedProjectMaps) mapEntry.id: mapEntry,
    };
    _syncEditors(map);

    final content = map == null
        ? const Center(
            child: Text(
              'No map loaded',
              style: TextStyle(color: Colors.white38),
            ),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Connect map edges to build a continuous world. Each side can point to one other map.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              if (sortedProjectMaps.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Create another map before adding world connections.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              for (final direction in MapConnectionDirection.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DirectionConnectionCard(
                    direction: direction,
                    existingConnection: notifier.getMapConnection(direction),
                    projectMaps: sortedProjectMaps,
                    projectMapById: projectMapById,
                    selectedTargetMapId: _selectedTargetMapIds[direction],
                    offsetController: _offsetControllers[direction]!,
                    onTargetChanged: (value) {
                      setState(() {
                        _selectedTargetMapIds[direction] = value;
                      });
                    },
                    onSave: () => _saveDirection(context, notifier, direction),
                    onOpen: () => notifier.openConnectedMap(direction),
                    onClear: () => _clearDirection(notifier, direction),
                  ),
                ),
            ],
          );

    if (widget.embedded) {
      return content;
    }

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
                    'CONNECTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Text(
                  map == null ? '0' : '${map.connections.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: content),
        ],
      ),
    );
  }

  void _syncEditors(MapData? map) {
    final nextKey = map == null
        ? 'none'
        : '${map.id}|${map.connections.map((connection) => '${connection.direction.name}:${connection.targetMapId}:${connection.offset}').join('|')}';
    if (_boundConnectionsKey == nextKey) {
      return;
    }
    _boundConnectionsKey = nextKey;
    final connectionsByDirection = <MapConnectionDirection, MapConnection>{};
    if (map != null) {
      for (final connection in map.connections) {
        connectionsByDirection[connection.direction] = connection;
      }
    }
    for (final direction in MapConnectionDirection.values) {
      final connection = connectionsByDirection[direction];
      _selectedTargetMapIds[direction] = connection?.targetMapId;
      _offsetControllers[direction]!.text =
          connection?.offset.toString() ?? '0';
    }
  }

  void _saveDirection(
    BuildContext context,
    EditorNotifier notifier,
    MapConnectionDirection direction,
  ) {
    final targetMapId = _selectedTargetMapIds[direction]?.trim() ?? '';
    final offset = int.tryParse(_offsetControllers[direction]!.text.trim());
    if (offset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection offset must be a valid integer'),
        ),
      );
      return;
    }
    notifier.saveMapConnection(
      direction: direction,
      targetMapId: targetMapId,
      offset: offset,
    );
  }

  void _clearDirection(
    EditorNotifier notifier,
    MapConnectionDirection direction,
  ) {
    final existingConnection = notifier.getMapConnection(direction);
    setState(() {
      _selectedTargetMapIds[direction] = null;
      _offsetControllers[direction]!.text = '0';
    });
    if (existingConnection == null) {
      return;
    }
    notifier.deleteMapConnection(direction);
  }
}

class _DirectionConnectionCard extends StatelessWidget {
  const _DirectionConnectionCard({
    required this.direction,
    required this.existingConnection,
    required this.projectMaps,
    required this.projectMapById,
    required this.selectedTargetMapId,
    required this.offsetController,
    required this.onTargetChanged,
    required this.onSave,
    required this.onOpen,
    required this.onClear,
  });

  final MapConnectionDirection direction;
  final MapConnection? existingConnection;
  final List<ProjectMapEntry> projectMaps;
  final Map<String, ProjectMapEntry> projectMapById;
  final String? selectedTargetMapId;
  final TextEditingController offsetController;
  final ValueChanged<String?> onTargetChanged;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final currentTargetEntry = existingConnection == null
        ? null
        : projectMapById[existingConnection!.targetMapId];
    final selectedTargetExists = selectedTargetMapId != null &&
        projectMapById.containsKey(selectedTargetMapId);
    final statusColor = existingConnection == null
        ? Colors.white24
        : currentTargetEntry == null
            ? Colors.amber
            : Colors.cyanAccent;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _directionIcon(direction),
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _directionLabel(direction),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  existingConnection == null ? 'Open' : 'Linked',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            existingConnection == null
                ? 'No map connected on this side.'
                : currentTargetEntry == null
                    ? 'Current target is missing: ${existingConnection!.targetMapId}'
                    : 'Current target: ${currentTargetEntry.name} (${currentTargetEntry.id}) | offset ${existingConnection!.offset}',
            style: TextStyle(
              fontSize: 11,
              color: currentTargetEntry == null && existingConnection != null
                  ? Colors.amber
                  : Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'map_connection_${direction.name}_${selectedTargetMapId ?? 'none'}',
            ),
            initialValue: selectedTargetExists ? selectedTargetMapId : null,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Connected Map',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            hint: Text(
              projectMaps.isEmpty
                  ? 'No other map available'
                  : selectedTargetMapId == null
                      ? 'Select map'
                      : 'Missing: $selectedTargetMapId',
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
            onChanged: projectMaps.isEmpty ? null : onTargetChanged,
          ),
          if (selectedTargetMapId != null && !selectedTargetExists) ...[
            const SizedBox(height: 6),
            Text(
              'Selected target is missing from project: $selectedTargetMapId',
              style: const TextStyle(fontSize: 11, color: Colors.amber),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: offsetController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: InputDecoration(
              labelText: 'Offset',
              helperText: _offsetHelper(direction),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: projectMaps.isEmpty ? null : onSave,
                  child: Text(
                    existingConnection == null ? 'Set Connection' : 'Save',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: existingConnection == null ? null : onOpen,
                  child: const Text('Open'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onClear,
              child: Text(
                existingConnection == null
                    ? 'Clear Draft'
                    : 'Remove Connection',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _directionIcon(MapConnectionDirection direction) {
    return switch (direction) {
      MapConnectionDirection.north => Icons.keyboard_arrow_up,
      MapConnectionDirection.south => Icons.keyboard_arrow_down,
      MapConnectionDirection.east => Icons.keyboard_arrow_right,
      MapConnectionDirection.west => Icons.keyboard_arrow_left,
    };
  }

  static String _directionLabel(MapConnectionDirection direction) {
    return switch (direction) {
      MapConnectionDirection.north => 'North Edge',
      MapConnectionDirection.south => 'South Edge',
      MapConnectionDirection.east => 'East Edge',
      MapConnectionDirection.west => 'West Edge',
    };
  }

  static String _offsetHelper(MapConnectionDirection direction) {
    return switch (direction) {
      MapConnectionDirection.north =>
        'Horizontal shift of the top map relative to this map',
      MapConnectionDirection.south =>
        'Horizontal shift of the bottom map relative to this map',
      MapConnectionDirection.east =>
        'Vertical shift of the right map relative to this map',
      MapConnectionDirection.west =>
        'Vertical shift of the left map relative to this map',
    };
  }
}
