import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';

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

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final content = map == null
        ? Center(
            child: Text(
              'No map loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Connect map edges to build a continuous world. Each side can point to one other map.',
                  style: TextStyle(color: subtle, fontSize: 12),
                ),
              ),
              if (sortedProjectMaps.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Create another map before adding world connections.',
                    style: TextStyle(
                      color: CupertinoColors.placeholderText.resolveFrom(context),
                      fontSize: 12,
                    ),
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
        color: EditorChrome.islandFill(context),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'CONNECTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
                Text(
                  map == null ? '0' : '${map.connections.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: subtle,
                  ),
                ),
              ],
            ),
          ),
          const EditorHorizontalDivider(),
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

  Future<void> _saveDirection(
    BuildContext context,
    EditorNotifier notifier,
    MapConnectionDirection direction,
  ) async {
    final targetMapId = _selectedTargetMapIds[direction]?.trim() ?? '';
    final offset = int.tryParse(_offsetControllers[direction]!.text.trim());
    if (offset == null) {
      await showCupertinoEditorAlert(
        context,
        message: 'Connection offset must be a valid integer',
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

  Future<void> _pickMap(BuildContext context) async {
    final picked = await showMacosEditorActionsSheet<String>(
      context: context,
      title: const Text('Connected Map'),
      actions: [
        const MacosEditorSheetAction(label: 'Clear selection', value: ''),
        ...projectMaps.map(
          (mapEntry) => MacosEditorSheetAction<String>(
            label: '${mapEntry.name} (${mapEntry.id})',
            value: mapEntry.id,
          ),
        ),
      ],
    );
    if (picked == null || !context.mounted) return;
    onTargetChanged(picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final currentTargetEntry = existingConnection == null
        ? null
        : projectMapById[existingConnection!.targetMapId];
    final selectedTargetExists = selectedTargetMapId != null &&
        projectMapById.containsKey(selectedTargetMapId);
    final statusColor = existingConnection == null
        ? EditorPaintColors.white38
        : currentTargetEntry == null
            ? EditorPaintColors.amber
            : EditorPaintColors.lightBlueAccent;

    final displayName = selectedTargetMapId == null
        ? (projectMaps.isEmpty
            ? 'No other map available'
            : 'Select map')
        : (selectedTargetExists
            ? '${projectMapById[selectedTargetMapId]!.name} ($selectedTargetMapId)'
            : 'Missing: $selectedTargetMapId');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: EditorChrome.inspectorTileHardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _directionIcon(direction),
                size: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _directionLabel(direction),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    EditorChrome.islandFillElevated(context),
                    statusColor,
                    0.35,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.85),
                    width: 1,
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
                  ? EditorPaintColors.amber
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connected Map',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 6),
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed:
                projectMaps.isEmpty ? null : () => _pickMap(context),
            child: Text(
              displayName,
              style: TextStyle(
                color: projectMaps.isEmpty
                    ? CupertinoColors.placeholderText.resolveFrom(context)
                    : CupertinoColors.label.resolveFrom(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (selectedTargetMapId != null && !selectedTargetExists) ...[
            const SizedBox(height: 6),
            Text(
              'Selected target is missing from project: $selectedTargetMapId',
              style: const TextStyle(fontSize: 11, color: EditorPaintColors.amber),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Offset',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _offsetHelper(direction),
            style: TextStyle(
              fontSize: 10,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: offsetController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: projectMaps.isEmpty ? null : onSave,
                  child: Text(
                    existingConnection == null ? 'Set Connection' : 'Save',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: existingConnection == null ? null : onOpen,
                  child: const Text('Open'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
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
      MapConnectionDirection.north => CupertinoIcons.arrow_up,
      MapConnectionDirection.south => CupertinoIcons.arrow_down,
      MapConnectionDirection.east => CupertinoIcons.arrow_right,
      MapConnectionDirection.west => CupertinoIcons.arrow_left,
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
