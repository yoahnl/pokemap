import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';

class EntityPropertiesPanel extends ConsumerStatefulWidget {
  const EntityPropertiesPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<EntityPropertiesPanel> createState() =>
      _EntityPropertiesPanelState();
}

class _EntityPropertiesPanelState
    extends ConsumerState<EntityPropertiesPanel> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _propertyRows = <_EntityPropertyDraft>[];

  String? _boundFingerprint;
  MapEntityKind _selectedKind = MapEntityKind.npc;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _xController.dispose();
    _yController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    for (final row in _propertyRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final selectedEntity = notifier.getSelectedEntity();
    _syncControllers(selectedEntity);

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
              DropdownButtonFormField<MapEntityKind>(
                key: ValueKey(
                  'entity_placement_kind_${state.selectedEntityKind.name}',
                ),
                initialValue: state.selectedEntityKind,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Placement Kind',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: MapEntityKind.values
                    .map(
                      (kind) => DropdownMenuItem<MapEntityKind>(
                        value: kind,
                        child: Text(_entityKindLabel(kind)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  notifier.selectEntityKind(value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                state.activeTool == EditorToolType.entityPlacement
                    ? 'Entity tool active. Click on the map to place the selected kind.'
                    : 'Select the Entity tool to place visible world content on the map.',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(height: 12),
              if (map.entities.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No entities on this map yet.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                )
              else
                ...map.entities.map(
                  (entity) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    color: entity.id == state.selectedEntityId
                        ? _entityColor(entity.kind).withValues(alpha: 0.16)
                        : Theme.of(context).scaffoldBackgroundColor,
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        _iconForEntityKind(entity.kind),
                        size: 16,
                        color: entity.id == state.selectedEntityId
                            ? Colors.white
                            : _entityColor(entity.kind),
                      ),
                      title: Text(
                        entity.name.trim().isNotEmpty ? entity.name : entity.id,
                        style: TextStyle(
                          fontSize: 12,
                          color: entity.id == state.selectedEntityId
                              ? Colors.white
                              : Colors.white,
                          fontWeight: entity.id == state.selectedEntityId
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${_entityKindLabel(entity.kind)} | ${entity.id} | (${entity.pos.x}, ${entity.pos.y}) ${entity.size.width}x${entity.size.height}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                      onTap: () => notifier.selectEntity(entity.id),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (selectedEntity == null)
                const Text(
                  'Select an entity to edit its properties.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                )
              else
                _buildSelectedEntityEditor(
                  context: context,
                  notifier: notifier,
                  selectedEntity: selectedEntity,
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
                    'ENTITIES',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Text(
                  map == null ? '0' : '${map.entities.length}',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
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

  Widget _buildSelectedEntityEditor({
    required BuildContext context,
    required EditorNotifier notifier,
    required MapEntity selectedEntity,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Entity',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Position: (${selectedEntity.pos.x}, ${selectedEntity.pos.y}) | Size: ${selectedEntity.size.width}x${selectedEntity.size.height}',
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
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<MapEntityKind>(
          key: ValueKey(
            'entity_kind_${selectedEntity.id}_${_selectedKind.name}',
          ),
          initialValue: _selectedKind,
          isDense: true,
          decoration: const InputDecoration(
            labelText: 'Kind',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: MapEntityKind.values
              .map(
                (kind) => DropdownMenuItem<MapEntityKind>(
                  value: kind,
                  child: Text(_entityKindLabel(kind)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedKind = value;
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _xController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'X',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _yController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Y',
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
              child: TextField(
                controller: _widthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Width',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Properties',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _propertyRows.add(_EntityPropertyDraft.empty());
                });
              },
              icon: const Icon(Icons.add, size: 18),
              tooltip: 'Add Property',
            ),
          ],
        ),
        if (_propertyRows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'No properties yet.',
              style: TextStyle(fontSize: 11, color: Colors.white38),
            ),
          )
        else
          ...List.generate(_propertyRows.length, (index) {
            final row = _propertyRows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: row.keyController,
                      decoration: const InputDecoration(
                        labelText: 'Key',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: row.valueController,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        final removed = _propertyRows.removeAt(index);
                        removed.dispose();
                      });
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Remove Property',
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _saveSelectedEntity(context, notifier),
                child: const Text('Save Entity'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: notifier.deleteSelectedEntity,
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _syncControllers(MapEntity? entity) {
    final fingerprint = entity == null
        ? 'none'
        : '${entity.id}|${entity.name}|${entity.kind.name}|${entity.pos.x}|${entity.pos.y}|${entity.size.width}|${entity.size.height}|${entity.properties.entries.map((entry) => '${entry.key}:${entry.value}').join('|')}';
    if (_boundFingerprint == fingerprint) {
      return;
    }
    _boundFingerprint = fingerprint;

    _idController.text = entity?.id ?? '';
    _nameController.text = entity?.name ?? '';
    _xController.text = entity?.pos.x.toString() ?? '';
    _yController.text = entity?.pos.y.toString() ?? '';
    _widthController.text = entity?.size.width.toString() ?? '';
    _heightController.text = entity?.size.height.toString() ?? '';
    _selectedKind = entity?.kind ?? MapEntityKind.npc;

    for (final row in _propertyRows) {
      row.dispose();
    }
    _propertyRows
      ..clear()
      ..addAll(
        entity?.properties.entries
                .map(
                  (entry) => _EntityPropertyDraft(
                    keyController: TextEditingController(text: entry.key),
                    valueController: TextEditingController(text: entry.value),
                  ),
                )
                .toList(growable: false) ??
            const [],
      );
  }

  void _saveSelectedEntity(
    BuildContext context,
    EditorNotifier notifier,
  ) {
    final x = int.tryParse(_xController.text.trim());
    final y = int.tryParse(_yController.text.trim());
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    if (x == null || y == null || width == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entity coordinates and size must be valid integers'),
        ),
      );
      return;
    }
    if (width <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entity width and height must be greater than zero'),
        ),
      );
      return;
    }

    final properties = <String, String>{};
    for (final row in _propertyRows) {
      final key = row.keyController.text.trim();
      final value = row.valueController.text.trim();
      if (key.isEmpty && value.isEmpty) {
        continue;
      }
      if (key.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entity property keys cannot be empty'),
          ),
        );
        return;
      }
      if (properties.containsKey(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicate entity property key: $key'),
          ),
        );
        return;
      }
      properties[key] = value;
    }

    notifier.updateSelectedEntity(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      kind: _selectedKind,
      x: x,
      y: y,
      width: width,
      height: height,
      properties: properties,
    );
  }

  static IconData _iconForEntityKind(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => Icons.person_outline,
      MapEntityKind.sign => Icons.signpost_outlined,
      MapEntityKind.item => Icons.inventory_2_outlined,
      MapEntityKind.spawn => Icons.flag_outlined,
      MapEntityKind.custom => Icons.extension_outlined,
    };
  }

  static Color _entityColor(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => const Color(0xFF55D0FF),
      MapEntityKind.sign => const Color(0xFFFFC857),
      MapEntityKind.item => const Color(0xFF7CE38B),
      MapEntityKind.spawn => const Color(0xFFFF7B7B),
      MapEntityKind.custom => const Color(0xFFC18CFF),
    };
  }

  static String _entityKindLabel(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'NPC',
      MapEntityKind.sign => 'Sign',
      MapEntityKind.item => 'Item',
      MapEntityKind.spawn => 'Spawn',
      MapEntityKind.custom => 'Custom',
    };
  }
}

class _EntityPropertyDraft {
  _EntityPropertyDraft({
    required this.keyController,
    required this.valueController,
  });

  factory _EntityPropertyDraft.empty() {
    return _EntityPropertyDraft(
      keyController: TextEditingController(),
      valueController: TextEditingController(),
    );
  }

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
