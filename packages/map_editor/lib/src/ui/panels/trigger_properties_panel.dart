import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';

class TriggerPropertiesPanel extends ConsumerStatefulWidget {
  const TriggerPropertiesPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<TriggerPropertiesPanel> createState() =>
      _TriggerPropertiesPanelState();
}

class _TriggerPropertiesPanelState
    extends ConsumerState<TriggerPropertiesPanel> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _propertyRows = <_TriggerPropertyDraft>[];

  String? _boundFingerprint;
  TriggerType _selectedType = TriggerType.event;

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
    final selectedTrigger = notifier.getSelectedTrigger();
    _syncControllers(selectedTrigger);

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
              if (map.triggers.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No triggers on this map.\nSelect the Trigger tool and click on the map to add one.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                )
              else
                ...map.triggers.map(
                  (trigger) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    color: trigger.id == state.selectedTriggerId
                        ? Colors.orange.withValues(alpha: 0.14)
                        : Theme.of(context).scaffoldBackgroundColor,
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        _iconForTriggerType(trigger.type),
                        size: 16,
                        color: trigger.id == state.selectedTriggerId
                            ? Colors.orangeAccent
                            : Colors.white60,
                      ),
                      title: Text(
                        trigger.name.trim().isNotEmpty ? trigger.name : trigger.id,
                        style: TextStyle(
                          fontSize: 12,
                          color: trigger.id == state.selectedTriggerId
                              ? Colors.orangeAccent
                              : Colors.white,
                          fontWeight: trigger.id == state.selectedTriggerId
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${_triggerTypeLabel(trigger.type)} | ${trigger.id} | (${trigger.area.pos.x}, ${trigger.area.pos.y}) ${trigger.area.size.width}x${trigger.area.size.height}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                      onTap: () => notifier.selectTrigger(trigger.id),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (selectedTrigger == null)
                const Text(
                  'Select a trigger to edit its properties.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                )
              else
                _buildSelectedTriggerEditor(
                  context: context,
                  notifier: notifier,
                  selectedTrigger: selectedTrigger,
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
                    'TRIGGERS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Text(
                  map == null ? '0' : '${map.triggers.length}',
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

  Widget _buildSelectedTriggerEditor({
    required BuildContext context,
    required EditorNotifier notifier,
    required MapTrigger selectedTrigger,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Trigger',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Area: (${selectedTrigger.area.pos.x}, ${selectedTrigger.area.pos.y}) ${selectedTrigger.area.size.width}x${selectedTrigger.area.size.height}',
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
        DropdownButtonFormField<TriggerType>(
          key: ValueKey(
              'trigger_type_${selectedTrigger.id}_${_selectedType.name}'),
          initialValue: _selectedType,
          isDense: true,
          decoration: const InputDecoration(
            labelText: 'Type',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: TriggerType.values
              .map(
                (type) => DropdownMenuItem<TriggerType>(
                  value: type,
                  child: Text(_triggerTypeLabel(type)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedType = value;
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
                  _propertyRows.add(_TriggerPropertyDraft.empty());
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
                onPressed: () => _saveSelectedTrigger(context, notifier),
                child: const Text('Save Trigger'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: notifier.deleteSelectedTrigger,
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _syncControllers(MapTrigger? trigger) {
    final fingerprint = trigger == null
        ? 'none'
        : '${trigger.id}|${trigger.name}|${trigger.type.name}|${trigger.area.pos.x}|${trigger.area.pos.y}|${trigger.area.size.width}|${trigger.area.size.height}|${trigger.properties.entries.map((entry) => '${entry.key}:${entry.value}').join('|')}';
    if (_boundFingerprint == fingerprint) {
      return;
    }
    _boundFingerprint = fingerprint;

    _idController.text = trigger?.id ?? '';
    _nameController.text = trigger?.name ?? '';
    _xController.text = trigger?.area.pos.x.toString() ?? '';
    _yController.text = trigger?.area.pos.y.toString() ?? '';
    _widthController.text = trigger?.area.size.width.toString() ?? '';
    _heightController.text = trigger?.area.size.height.toString() ?? '';
    _selectedType = trigger?.type ?? TriggerType.event;

    for (final row in _propertyRows) {
      row.dispose();
    }
    _propertyRows
      ..clear()
      ..addAll(
        trigger?.properties.entries
                .map(
                  (entry) => _TriggerPropertyDraft(
                    keyController: TextEditingController(text: entry.key),
                    valueController: TextEditingController(text: entry.value),
                  ),
                )
                .toList(growable: false) ??
            const [],
      );
  }

  void _saveSelectedTrigger(
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
          content: Text('Trigger coordinates and size must be valid integers'),
        ),
      );
      return;
    }
    if (width <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trigger width and height must be greater than zero'),
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
            content: Text('Trigger property keys cannot be empty'),
          ),
        );
        return;
      }
      if (properties.containsKey(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicate trigger property key: $key'),
          ),
        );
        return;
      }
      properties[key] = value;
    }

    notifier.updateSelectedTrigger(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      type: _selectedType,
      x: x,
      y: y,
      width: width,
      height: height,
      properties: properties,
    );
  }

  static IconData _iconForTriggerType(TriggerType type) {
    return switch (type) {
      TriggerType.warp => Icons.alt_route_outlined,
      TriggerType.message => Icons.chat_bubble_outline,
      TriggerType.interaction => Icons.touch_app_outlined,
      TriggerType.event => Icons.bolt_outlined,
      TriggerType.spawn => Icons.flag_outlined,
      TriggerType.camera => Icons.videocam_outlined,
      TriggerType.custom => Icons.extension_outlined,
    };
  }

  static String _triggerTypeLabel(TriggerType type) {
    return switch (type) {
      TriggerType.warp => 'Warp',
      TriggerType.message => 'Message',
      TriggerType.interaction => 'Interaction',
      TriggerType.event => 'Event',
      TriggerType.spawn => 'Spawn',
      TriggerType.camera => 'Camera',
      TriggerType.custom => 'Custom',
    };
  }
}

class _TriggerPropertyDraft {
  _TriggerPropertyDraft({
    required this.keyController,
    required this.valueController,
  });

  factory _TriggerPropertyDraft.empty() {
    return _TriggerPropertyDraft(
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
