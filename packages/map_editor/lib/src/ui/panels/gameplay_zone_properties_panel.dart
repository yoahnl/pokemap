import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';
import '../shared/inspector_embedded_widgets.dart';

class GameplayZonePropertiesPanel extends ConsumerStatefulWidget {
  const GameplayZonePropertiesPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<GameplayZonePropertiesPanel> createState() =>
      _GameplayZonePropertiesPanelState();
}

class _GameplayZonePropertiesPanelState
    extends ConsumerState<GameplayZonePropertiesPanel> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _priorityController = TextEditingController();

  String? _boundFingerprint;
  GameplayZoneKind _selectedKind = GameplayZoneKind.encounter;
  String? _selectedEncounterTableId;
  MovementMode? _selectedMovementMode;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _xController.dispose();
    _yController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final project = state.project;
    final selectedZone = notifier.getSelectedGameplayZone();
    _syncControllers(selectedZone);

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.inspectorJoyMint;
    final listAccent = widget.embedded ? accent : EditorPaintColors.greenAccent;
    final labelColor = CupertinoColors.label.resolveFrom(context);

    final encounterTableOptions = project?.encounterTables ?? const [];

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
            padding: widget.embedded
                ? kInspectorTileBodyPadding
                : const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              if (map.gameplayZones.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No gameplay zones on this map.\nSelect the Zone tool and click on the map to add one.',
                    style: TextStyle(
                      color:
                          CupertinoColors.placeholderText.resolveFrom(context),
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...map.gameplayZones.map(
                  (zone) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: zone.id == state.selectedGameplayZoneId
                            ? Color.lerp(
                                EditorChrome.islandFillElevated(context),
                                listAccent,
                                0.3,
                              )!
                            : EditorChrome.islandFillElevated(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: zone.id == state.selectedGameplayZoneId
                              ? listAccent.withValues(alpha: 0.78)
                              : EditorChrome.editorIslandRim(context),
                          width: 1,
                        ),
                        boxShadow:
                            EditorChrome.inspectorTileHardShadows(context),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                        alignment: Alignment.centerLeft,
                        onPressed: () => notifier.selectGameplayZone(zone.id),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _iconForKind(zone.kind),
                              size: 16,
                              color: zone.id == state.selectedGameplayZoneId
                                  ? listAccent
                                  : subtle,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    zone.name.trim().isNotEmpty
                                        ? zone.name
                                        : zone.id,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: labelColor,
                                      fontWeight: zone.id ==
                                              state.selectedGameplayZoneId
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_kindLabel(zone.kind)} | ${zone.id} | (${zone.area.pos.x},${zone.area.pos.y}) ${zone.area.size.width}×${zone.area.size.height}',
                                    style:
                                        TextStyle(fontSize: 11, color: subtle),
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
              if (selectedZone == null)
                Text(
                  'Select a zone to edit its properties.',
                  style: TextStyle(
                    color:
                        CupertinoColors.placeholderText.resolveFrom(context),
                    fontSize: 12,
                  ),
                )
              else
                _buildEditor(
                  context: context,
                  notifier: notifier,
                  zone: selectedZone,
                  encounterTableOptions: encounterTableOptions,
                ),
            ],
          );

    if (widget.embedded) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(color: EditorChrome.islandFill(context)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'GAMEPLAY ZONES',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
                Text(
                  map == null ? '0' : '${map.gameplayZones.length}',
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

  Widget _buildEditor({
    required BuildContext context,
    required EditorNotifier notifier,
    required MapGameplayZone zone,
    required List<ProjectEncounterTable> encounterTableOptions,
  }) {
    const coral = EditorChrome.inspectorJoyCoral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded)
          const InspectorEmbeddedSectionLabel('Zone sélectionnée')
        else
          Text(
            'Selected Zone',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 8),
        _labeledField(context, label: 'ID', controller: _idController),
        const SizedBox(height: 8),
        _labeledField(context, label: 'Name', controller: _nameController),
        const SizedBox(height: 8),
        if (widget.embedded)
          InspectorEmbeddedDropdown(
            accent: coral,
            fieldLabel: 'Kind',
            valueLabel: _kindLabel(_selectedKind),
            orderedIds: GameplayZoneKind.values.map((k) => k.name).toList(),
            selectedMenuValue: _selectedKind.name,
            selectedIdForCheck: _selectedKind.name,
            idToLabel: (id) => _kindLabel(
              GameplayZoneKind.values.firstWhere((k) => k.name == id),
            ),
            onSelected: (id) {
              setState(() {
                _selectedKind =
                    GameplayZoneKind.values.firstWhere((k) => k.name == id);
              });
            },
            tooltip: 'Zone kind',
          )
        else
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked = await showCupertinoListPicker<GameplayZoneKind>(
                context: context,
                title: 'Kind',
                items: GameplayZoneKind.values,
                labelOf: _kindLabel,
              );
              if (picked != null) setState(() => _selectedKind = picked);
            },
            child: Text('Kind: ${_kindLabel(_selectedKind)}'),
          ),
        const SizedBox(height: 8),
        if (encounterTableOptions.isNotEmpty) ...[
          if (widget.embedded)
            InspectorEmbeddedDropdown(
              accent: coral,
              fieldLabel: 'Encounter Table',
              valueLabel: _selectedEncounterTableId == null
                  ? '—'
                  : (encounterTableOptions
                          .firstWhere(
                            (t) => t.id == _selectedEncounterTableId,
                            orElse: () => encounterTableOptions.first,
                          )
                          .name),
              orderedIds: [
                '',
                ...encounterTableOptions.map((t) => t.id),
              ],
              selectedMenuValue: _selectedEncounterTableId ?? '',
              selectedIdForCheck: _selectedEncounterTableId ?? '',
              idToLabel: (id) => id.isEmpty
                  ? '— None —'
                  : (encounterTableOptions
                      .firstWhere((t) => t.id == id,
                          orElse: () => encounterTableOptions.first)
                      .name),
              onSelected: (id) {
                setState(() {
                  _selectedEncounterTableId = id.isEmpty ? null : id;
                });
              },
              tooltip: 'Encounter table',
            )
          else
            CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () async {
                final options = [null, ...encounterTableOptions];
                final picked =
                    await showCupertinoListPicker<ProjectEncounterTable?>(
                  context: context,
                  title: 'Encounter Table',
                  items: options,
                  labelOf: (t) => t == null ? '— None —' : t.name,
                );
                if (picked != null || _selectedEncounterTableId != null) {
                  setState(() {
                    _selectedEncounterTableId = picked?.id;
                  });
                }
              },
              child: Text(
                  'Encounter Table: ${_selectedEncounterTableId == null ? '—' : encounterTableOptions.firstWhere((t) => t.id == _selectedEncounterTableId!, orElse: () => encounterTableOptions.first).name}'),
            ),
          const SizedBox(height: 8),
        ],
        if (widget.embedded)
          InspectorEmbeddedDropdown(
            accent: coral,
            fieldLabel: 'Movement Mode',
            valueLabel: _selectedMovementMode == null
                ? '— None —'
                : _movementModeLabel(_selectedMovementMode!),
            orderedIds: [
              '',
              ...MovementMode.values.map((m) => m.name),
            ],
            selectedMenuValue: _selectedMovementMode?.name ?? '',
            selectedIdForCheck: _selectedMovementMode?.name ?? '',
            idToLabel: (id) => id.isEmpty
                ? '— None —'
                : _movementModeLabel(
                    MovementMode.values.firstWhere((m) => m.name == id),
                  ),
            onSelected: (id) {
              setState(() {
                _selectedMovementMode = id.isEmpty
                    ? null
                    : MovementMode.values.firstWhere((m) => m.name == id);
              });
            },
            tooltip: 'Movement mode',
          )
        else
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked = await showCupertinoListPicker<MovementMode?>(
                context: context,
                title: 'Movement Mode',
                items: [null, ...MovementMode.values],
                labelOf: (m) =>
                    m == null ? '— None —' : _movementModeLabel(m),
              );
              if (picked != null || _selectedMovementMode != null) {
                setState(() => _selectedMovementMode = picked);
              }
            },
            child: Text(
                'Movement: ${_selectedMovementMode == null ? '—' : _movementModeLabel(_selectedMovementMode!)}'),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: 'X',
                controller: _xController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
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
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
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
            const SizedBox(width: 8),
            Expanded(
              child: _labeledField(
                context,
                label: 'Priority',
                controller: _priorityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.embedded)
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: coral,
                  icon: CupertinoIcons.checkmark_circle_fill,
                  label: 'Enregistrer',
                  prominent: true,
                  onPressed: () => _save(context, notifier),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: coral,
                  icon: CupertinoIcons.trash,
                  label: 'Supprimer',
                  enabled: true,
                  onPressed: notifier.deleteSelectedGameplayZone,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: () => _save(context, notifier),
                  child: const Text('Save Zone'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  onPressed: notifier.deleteSelectedGameplayZone,
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
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

  void _syncControllers(MapGameplayZone? zone) {
    final fingerprint = zone == null
        ? 'none'
        : '${zone.id}|${zone.name}|${zone.kind.name}|${zone.area.pos.x}|${zone.area.pos.y}|${zone.area.size.width}|${zone.area.size.height}|${zone.priority}|${zone.encounterTableId}|${zone.movementMode?.name}';
    if (_boundFingerprint == fingerprint) return;
    _boundFingerprint = fingerprint;

    _idController.text = zone?.id ?? '';
    _nameController.text = zone?.name ?? '';
    _xController.text = zone?.area.pos.x.toString() ?? '';
    _yController.text = zone?.area.pos.y.toString() ?? '';
    _widthController.text = zone?.area.size.width.toString() ?? '';
    _heightController.text = zone?.area.size.height.toString() ?? '';
    _priorityController.text = zone?.priority.toString() ?? '0';
    _selectedKind = zone?.kind ?? GameplayZoneKind.encounter;
    _selectedEncounterTableId = zone?.encounterTableId;
    _selectedMovementMode = zone?.movementMode;
  }

  Future<void> _save(BuildContext context, EditorNotifier notifier) async {
    final x = int.tryParse(_xController.text.trim());
    final y = int.tryParse(_yController.text.trim());
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    final priority = int.tryParse(_priorityController.text.trim()) ?? 0;

    if (x == null || y == null || width == null || height == null) {
      await showCupertinoEditorAlert(
        context,
        message: 'Zone coordinates and size must be valid integers',
      );
      return;
    }
    if (width <= 0 || height <= 0) {
      await showCupertinoEditorAlert(
        context,
        message: 'Zone width and height must be greater than zero',
      );
      return;
    }

    notifier.updateSelectedGameplayZone(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      kind: _selectedKind,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      encounterTableId:
          _selectedEncounterTableId, // null = clear, value = set
      movementMode: _selectedMovementMode,
      priority: priority,
    );
  }

  static IconData _iconForKind(GameplayZoneKind kind) {
    return switch (kind) {
      GameplayZoneKind.encounter => CupertinoIcons.leaf_arrow_circlepath,
      GameplayZoneKind.movement => CupertinoIcons.arrow_right_arrow_left,
      GameplayZoneKind.hazard => CupertinoIcons.exclamationmark_triangle,
      GameplayZoneKind.transition => CupertinoIcons.arrow_uturn_right,
      GameplayZoneKind.special => CupertinoIcons.star,
      GameplayZoneKind.custom => CupertinoIcons.square_stack_3d_up,
    };
  }

  static String _kindLabel(GameplayZoneKind kind) {
    return switch (kind) {
      GameplayZoneKind.encounter => 'Encounter',
      GameplayZoneKind.movement => 'Movement',
      GameplayZoneKind.hazard => 'Hazard',
      GameplayZoneKind.transition => 'Transition',
      GameplayZoneKind.special => 'Special',
      GameplayZoneKind.custom => 'Custom',
    };
  }

  static String _movementModeLabel(MovementMode mode) {
    return switch (mode) {
      MovementMode.walk => 'Walk',
      MovementMode.surf => 'Surf',
      MovementMode.fly => 'Fly',
      MovementMode.cut => 'Cut',
      MovementMode.strength => 'Strength',
      MovementMode.rockSmash => 'Rock Smash',
    };
  }
}
