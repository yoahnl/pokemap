import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';

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

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorPaintColors.orangeAccent;
    final labelColor = CupertinoColors.label.resolveFrom(context);

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
              if (map.triggers.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No triggers on this map.\nSelect the Trigger tool and click on the map to add one.',
                    style: TextStyle(
                      color: CupertinoColors.placeholderText.resolveFrom(context),
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...map.triggers.map(
                  (trigger) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: trigger.id == state.selectedTriggerId
                            ? EditorPaintColors.orange.withValues(alpha: 0.14)
                            : EditorChrome.scaffoldBackground(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: EditorChrome.separator(context),
                        ),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                        alignment: Alignment.centerLeft,
                        onPressed: () => notifier.selectTrigger(trigger.id),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _iconForTriggerType(trigger.type),
                              size: 16,
                              color: trigger.id == state.selectedTriggerId
                                  ? accent
                                  : subtle,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trigger.name.trim().isNotEmpty
                                        ? trigger.name
                                        : trigger.id,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: trigger.id ==
                                              state.selectedTriggerId
                                          ? accent
                                          : labelColor,
                                      fontWeight: trigger.id ==
                                              state.selectedTriggerId
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_triggerTypeLabel(trigger.type)} | ${trigger.id} | (${trigger.area.pos.x}, ${trigger.area.pos.y}) ${trigger.area.size.width}x${trigger.area.size.height}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const EditorHorizontalDivider(),
              const SizedBox(height: 8),
              if (selectedTrigger == null)
                Text(
                  'Select a trigger to edit its properties.',
                  style: TextStyle(
                    color: CupertinoColors.placeholderText.resolveFrom(context),
                    fontSize: 12,
                  ),
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
        color: EditorChrome.panelBackground(context),
        border: Border(
          bottom: BorderSide(color: EditorChrome.separator(context)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TRIGGERS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
                Text(
                  map == null ? '0' : '${map.triggers.length}',
                  style: TextStyle(fontSize: 11, color: subtle),
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

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondary,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
        ),
      ],
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
        Text(
          'Selected Trigger',
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Area: (${selectedTrigger.area.pos.x}, ${selectedTrigger.area.pos.y}) ${selectedTrigger.area.size.width}x${selectedTrigger.area.size.height}',
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        _labeledField(context, label: 'ID', controller: _idController),
        const SizedBox(height: 8),
        _labeledField(context, label: 'Name', controller: _nameController),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () async {
            final picked = await showCupertinoListPicker<TriggerType>(
              context: context,
              title: 'Type',
              items: TriggerType.values,
              labelOf: _triggerTypeLabel,
            );
            if (picked != null) {
              setState(() => _selectedType = picked);
            }
          },
          child: Text('Type: ${_triggerTypeLabel(_selectedType)}'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: 'X',
                controller: _xController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeledField(
                context,
                label: 'Y',
                controller: _yController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: 'Width',
                controller: _widthController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeledField(
                context,
                label: 'Height',
                controller: _heightController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Properties',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            EditorToolbarIconButton(
              onPressed: () {
                setState(() {
                  _propertyRows.add(_TriggerPropertyDraft.empty());
                });
              },
              icon: CupertinoIcons.add,
              tooltip: 'Add Property',
            ),
          ],
        ),
        if (_propertyRows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No properties yet.',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        else
          ...List.generate(_propertyRows.length, (index) {
            final row = _propertyRows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _labeledField(
                      context,
                      label: 'Key',
                      controller: row.keyController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _labeledField(
                      context,
                      label: 'Value',
                      controller: row.valueController,
                    ),
                  ),
                  EditorToolbarIconButton(
                    onPressed: () {
                      setState(() {
                        final removed = _propertyRows.removeAt(index);
                        removed.dispose();
                      });
                    },
                    icon: CupertinoIcons.trash,
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
              child: CupertinoButton.filled(
                onPressed: () => _saveSelectedTrigger(context, notifier),
                child: const Text('Save Trigger'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoButton(
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

  Future<void> _saveSelectedTrigger(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final x = int.tryParse(_xController.text.trim());
    final y = int.tryParse(_yController.text.trim());
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    if (x == null || y == null || width == null || height == null) {
      await showCupertinoEditorAlert(
        context,
        message: 'Trigger coordinates and size must be valid integers',
      );
      return;
    }
    if (width <= 0 || height <= 0) {
      await showCupertinoEditorAlert(
        context,
        message: 'Trigger width and height must be greater than zero',
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
        await showCupertinoEditorAlert(
          context,
          message: 'Trigger property keys cannot be empty',
        );
        return;
      }
      if (properties.containsKey(key)) {
        await showCupertinoEditorAlert(
          context,
          message: 'Duplicate trigger property key: $key',
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
      TriggerType.warp => CupertinoIcons.arrow_branch,
      TriggerType.message => CupertinoIcons.chat_bubble,
      TriggerType.interaction => CupertinoIcons.hand_point_left,
      TriggerType.event => CupertinoIcons.bolt,
      TriggerType.spawn => CupertinoIcons.flag,
      TriggerType.camera => CupertinoIcons.videocam,
      TriggerType.custom => CupertinoIcons.square_stack_3d_up,
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
