import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../features/editor/state/editor_notifier.dart';
import 'battle_background_path_utils.dart';
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
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _priorityController = TextEditingController();

  // ── Per-kind payload fields ──────────────────────────────────────────────────
  String? _boundFingerprint;
  GameplayZoneKind _selectedKind = GameplayZoneKind.encounter;

  // encounter
  String? _encounterTableId;
  EncounterKind _encounterKind = EncounterKind.walk;
  String? _encounterBattleBackgroundRelativePath;
  String? _encounterBattleBackgroundMessage;

  // movement
  MovementMode _movementMode = MovementMode.walk;

  // movement effect
  MovementEffectZoneKind _movementEffectKind = MovementEffectZoneKind.slide;
  int _movementEffectCost = 1;

  // hazard
  HazardKind _hazardKind = HazardKind.other;
  int _hazardDamagePerStep = 0;

  // special / custom
  String _scriptKey = '';

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
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
                    'No gameplay zones on this map.\nSelect the Zone tool and draw a rectangle to add one.',
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
                    color: CupertinoColors.placeholderText.resolveFrom(context),
                    fontSize: 12,
                  ),
                )
              else
                _buildEditor(
                  context: context,
                  notifier: notifier,
                  zone: selectedZone,
                  encounterTableOptions: encounterTableOptions,
                  projectRootPath: state.projectRootPath?.trim(),
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
    required String? projectRootPath,
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
        // Kind
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

        // ── Payload fields per kind ────────────────────────────────────────────
        if (_selectedKind == GameplayZoneKind.encounter) ...[
          const _SectionDivider('Encounter'),
          const SizedBox(height: 8),
          if (encounterTableOptions.isNotEmpty)
            _buildEncounterTableDropdown(
              context,
              coral,
              encounterTableOptions,
            ),
          const SizedBox(height: 8),
          _buildEncounterKindDropdown(context, coral),
          const SizedBox(height: 8),
          _buildEncounterBattleBackgroundPicker(
            context: context,
            projectRootPath: projectRootPath,
          ),
          const SizedBox(height: 8),
        ],

        if (_selectedKind == GameplayZoneKind.movement) ...[
          const _SectionDivider('Movement'),
          const SizedBox(height: 8),
          _buildMovementModeDropdown(context, coral),
          const SizedBox(height: 8),
        ],

        if (_selectedKind == GameplayZoneKind.movementEffect) ...[
          const _SectionDivider('Movement Effect'),
          const SizedBox(height: 8),
          _buildMovementEffectKindDropdown(context, coral),
          const SizedBox(height: 8),
          _labeledField(
            context,
            label: 'Movement Cost',
            controller:
                TextEditingController(text: _movementEffectCost.toString())
                  ..selection = TextSelection.collapsed(
                    offset: _movementEffectCost.toString().length,
                  ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) setState(() => _movementEffectCost = parsed);
            },
          ),
          const SizedBox(height: 8),
        ],

        if (_selectedKind == GameplayZoneKind.hazard) ...[
          const _SectionDivider('Hazard'),
          const SizedBox(height: 8),
          _buildHazardKindDropdown(context, coral),
          const SizedBox(height: 8),
          _labeledField(
            context,
            label: 'Damage / step',
            controller:
                TextEditingController(text: _hazardDamagePerStep.toString())
                  ..selection = TextSelection.collapsed(
                      offset: _hazardDamagePerStep.toString().length),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) setState(() => _hazardDamagePerStep = parsed);
            },
          ),
          const SizedBox(height: 8),
        ],

        if (_selectedKind == GameplayZoneKind.special ||
            _selectedKind == GameplayZoneKind.custom) ...[
          const _SectionDivider('Special'),
          const SizedBox(height: 8),
          _labeledField(
            context,
            label: 'Script Key',
            controller: TextEditingController(text: _scriptKey)
              ..selection = TextSelection.collapsed(offset: _scriptKey.length),
            onChanged: (v) => setState(() => _scriptKey = v),
          ),
          const SizedBox(height: 8),
        ],

        // ── Priority ──────────────────────────────────────────────────────────
        _labeledField(
          context,
          label: 'Priority',
          controller: _priorityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),

        // ── Actions ───────────────────────────────────────────────────────────
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

  // ── Payload dropdowns ──────────────────────────────────────────────────────

  Widget _buildEncounterTableDropdown(
    BuildContext context,
    Color accent,
    List<ProjectEncounterTable> options,
  ) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Encounter Table',
        valueLabel: _encounterTableId == null
            ? '—'
            : (options
                .firstWhere(
                  (t) => t.id == _encounterTableId,
                  orElse: () => options.first,
                )
                .name),
        orderedIds: ['', ...options.map((t) => t.id)],
        selectedMenuValue: _encounterTableId ?? '',
        selectedIdForCheck: _encounterTableId ?? '',
        idToLabel: (id) => id.isEmpty
            ? '— None —'
            : (options
                .firstWhere((t) => t.id == id, orElse: () => options.first)
                .name),
        onSelected: (id) => setState(
          () => _encounterTableId = id.isEmpty ? null : id,
        ),
        tooltip: 'Encounter table',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<ProjectEncounterTable?>(
          context: context,
          title: 'Encounter Table',
          items: [null, ...options],
          labelOf: (t) => t == null ? '— None —' : t.name,
        );
        if (picked != null || _encounterTableId != null) {
          setState(() => _encounterTableId = picked?.id);
        }
      },
      child: Text(
        'Encounter Table: ${_encounterTableId == null ? '—' : options.firstWhere((t) => t.id == _encounterTableId!, orElse: () => options.first).name}',
      ),
    );
  }

  Widget _buildEncounterKindDropdown(BuildContext context, Color accent) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Encounter Kind',
        valueLabel: _encounterKindLabel(_encounterKind),
        orderedIds: EncounterKind.values.map((k) => k.name).toList(),
        selectedMenuValue: _encounterKind.name,
        selectedIdForCheck: _encounterKind.name,
        idToLabel: (id) => _encounterKindLabel(
          EncounterKind.values.firstWhere((k) => k.name == id),
        ),
        onSelected: (id) => setState(() {
          _encounterKind = EncounterKind.values.firstWhere((k) => k.name == id);
        }),
        tooltip: 'Encounter trigger kind',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<EncounterKind>(
          context: context,
          title: 'Encounter Kind',
          items: EncounterKind.values,
          labelOf: _encounterKindLabel,
        );
        if (picked != null) setState(() => _encounterKind = picked);
      },
      child: Text('Encounter Kind: ${_encounterKindLabel(_encounterKind)}'),
    );
  }

  Widget _buildEncounterBattleBackgroundPicker({
    required BuildContext context,
    required String? projectRootPath,
  }) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final relativePath = _encounterBattleBackgroundRelativePath?.trim();
    final hasExplicitPath = relativePath != null && relativePath.isNotEmpty;
    final absolutePath = !hasExplicitPath || projectRootPath == null
        ? null
        : p.normalize(p.join(projectRootPath, relativePath));
    final exists = absolutePath != null && File(absolutePath).existsSync();
    final statusLabel = !hasExplicitPath
        ? 'none'
        : exists
            ? 'linked'
            : 'missing';
    final statusColor = switch (statusLabel) {
      'linked' => EditorChrome.accentJade,
      'missing' => EditorChrome.inspectorJoyCoral,
      _ => subtle,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Battle background',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: subtle,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: EditorChrome.editorIslandRim(context),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasExplicitPath
                      ? relativePath
                      : 'No battle background linked.',
                  style: TextStyle(
                    color: hasExplicitPath ? labelColor : subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: $statusLabel',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_encounterBattleBackgroundMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _encounterBattleBackgroundMessage!,
                    style: const TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    CupertinoButton(
                      key: const Key(
                        'gameplay-zone-encounter-background-pick-button',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(1, 30),
                      onPressed: () => _pickEncounterBattleBackground(
                        projectRootPath: projectRootPath,
                      ),
                      child: const Text(
                        'Choose battle background',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      key: const Key(
                        'gameplay-zone-encounter-background-clear-button',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(1, 30),
                      onPressed: hasExplicitPath
                          ? () {
                              setState(() {
                                _encounterBattleBackgroundRelativePath = null;
                                _encounterBattleBackgroundMessage = null;
                              });
                            }
                          : null,
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovementModeDropdown(BuildContext context, Color accent) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Required Mode',
        valueLabel: _movementModeLabel(_movementMode),
        orderedIds: MovementMode.values.map((m) => m.name).toList(),
        selectedMenuValue: _movementMode.name,
        selectedIdForCheck: _movementMode.name,
        idToLabel: (id) => _movementModeLabel(
          MovementMode.values.firstWhere((m) => m.name == id),
        ),
        onSelected: (id) => setState(() {
          _movementMode = MovementMode.values.firstWhere((m) => m.name == id);
        }),
        tooltip: 'Required movement mode',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<MovementMode>(
          context: context,
          title: 'Required Mode',
          items: MovementMode.values,
          labelOf: _movementModeLabel,
        );
        if (picked != null) setState(() => _movementMode = picked);
      },
      child: Text('Required Mode: ${_movementModeLabel(_movementMode)}'),
    );
  }

  Widget _buildMovementEffectKindDropdown(BuildContext context, Color accent) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Effect Kind',
        valueLabel: _movementEffectKindLabel(_movementEffectKind),
        orderedIds: MovementEffectZoneKind.values.map((k) => k.name).toList(),
        selectedMenuValue: _movementEffectKind.name,
        selectedIdForCheck: _movementEffectKind.name,
        idToLabel: (id) => _movementEffectKindLabel(
          MovementEffectZoneKind.values.firstWhere((k) => k.name == id),
        ),
        onSelected: (id) => setState(() {
          _movementEffectKind =
              MovementEffectZoneKind.values.firstWhere((k) => k.name == id);
        }),
        tooltip: 'Movement effect kind',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<MovementEffectZoneKind>(
          context: context,
          title: 'Movement Effect',
          items: MovementEffectZoneKind.values,
          labelOf: _movementEffectKindLabel,
        );
        if (picked != null) setState(() => _movementEffectKind = picked);
      },
      child: Text(
        'Effect: ${_movementEffectKindLabel(_movementEffectKind)}',
      ),
    );
  }

  Widget _buildHazardKindDropdown(BuildContext context, Color accent) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Hazard Kind',
        valueLabel: _hazardKindLabel(_hazardKind),
        orderedIds: HazardKind.values.map((k) => k.name).toList(),
        selectedMenuValue: _hazardKind.name,
        selectedIdForCheck: _hazardKind.name,
        idToLabel: (id) => _hazardKindLabel(
          HazardKind.values.firstWhere((k) => k.name == id),
        ),
        onSelected: (id) => setState(() {
          _hazardKind = HazardKind.values.firstWhere((k) => k.name == id);
        }),
        tooltip: 'Type of environmental hazard',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<HazardKind>(
          context: context,
          title: 'Hazard Kind',
          items: HazardKind.values,
          labelOf: _hazardKindLabel,
        );
        if (picked != null) setState(() => _hazardKind = picked);
      },
      child: Text('Hazard: ${_hazardKindLabel(_hazardKind)}'),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
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
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _syncControllers(MapGameplayZone? zone) {
    final fingerprint = zone == null
        ? 'none'
        : '${zone.id}|${zone.name}|${zone.kind.name}'
            '|${zone.area.pos.x}|${zone.area.pos.y}'
            '|${zone.area.size.width}|${zone.area.size.height}'
            '|${zone.priority}'
            '|${zone.encounter?.encounterTableId}|${zone.encounter?.encounterKind.name}|${zone.encounter?.battleBackgroundRelativePath}'
            '|${zone.movement?.requiredMode.name}'
            '|${zone.movementEffect?.effectKind.name}|${zone.movementEffect?.movementCost}'
            '|${zone.hazard?.hazardKind.name}|${zone.hazard?.damagePerStep}'
            '|${zone.special?.scriptKey}';
    if (_boundFingerprint == fingerprint) return;
    _boundFingerprint = fingerprint;

    _idController.text = zone?.id ?? '';
    _nameController.text = zone?.name ?? '';
    _priorityController.text = zone?.priority.toString() ?? '0';
    _selectedKind = zone?.kind ?? GameplayZoneKind.encounter;

    // encounter
    _encounterTableId = zone?.encounter?.encounterTableId;
    _encounterKind = zone?.encounter?.encounterKind ?? EncounterKind.walk;
    _encounterBattleBackgroundRelativePath =
        zone?.encounter?.battleBackgroundRelativePath;
    _encounterBattleBackgroundMessage = null;

    // movement
    _movementMode = zone?.movement?.requiredMode ?? MovementMode.walk;

    // movement effect
    _movementEffectKind =
        zone?.movementEffect?.effectKind ?? MovementEffectZoneKind.slide;
    _movementEffectCost = zone?.movementEffect?.movementCost ?? 1;

    // hazard
    _hazardKind = zone?.hazard?.hazardKind ?? HazardKind.other;
    _hazardDamagePerStep = zone?.hazard?.damagePerStep ?? 0;

    // special
    _scriptKey = zone?.special?.scriptKey ?? '';
  }

  Future<void> _save(BuildContext context, EditorNotifier notifier) async {
    final priority = int.tryParse(_priorityController.text.trim()) ?? 0;

    EncounterZonePayload? encounter;
    MovementZonePayload? movement;
    MovementEffectZonePayload? movementEffect;
    HazardZonePayload? hazard;
    SpecialZonePayload? special;

    switch (_selectedKind) {
      case GameplayZoneKind.encounter:
        encounter = EncounterZonePayload(
          encounterTableId: _encounterTableId,
          encounterKind: _encounterKind,
          battleBackgroundRelativePath: _normalizeOptionalProjectRelativePath(
            _encounterBattleBackgroundRelativePath,
          ),
        );
      case GameplayZoneKind.movement:
        movement = MovementZonePayload(requiredMode: _movementMode);
      case GameplayZoneKind.movementEffect:
        movementEffect = MovementEffectZonePayload(
          effectKind: _movementEffectKind,
          movementCost: _movementEffectCost,
        );
      case GameplayZoneKind.hazard:
        hazard = HazardZonePayload(
          hazardKind: _hazardKind,
          damagePerStep: _hazardDamagePerStep,
        );
      case GameplayZoneKind.special:
      case GameplayZoneKind.custom:
        special = SpecialZonePayload(
          scriptKey: _scriptKey.trim().isEmpty ? null : _scriptKey.trim(),
        );
    }

    notifier.updateSelectedGameplayZone(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      kind: _selectedKind,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
  }

  Future<void> _pickEncounterBattleBackground({
    required String? projectRootPath,
  }) async {
    final normalizedProjectRoot = projectRootPath?.trim();
    if (normalizedProjectRoot == null || normalizedProjectRoot.isEmpty) {
      setState(() {
        _encounterBattleBackgroundMessage =
            'A valid project workspace is required before linking a battle background.';
      });
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>[
        'png',
        'jpg',
        'jpeg',
        'webp',
        'bmp',
        'gif',
      ],
      withData: false,
    );
    final pickedAbsolutePath = result?.files.single.path?.trim();
    if (pickedAbsolutePath == null || pickedAbsolutePath.isEmpty) {
      return;
    }

    final relativePath = _normalizePickedBattleBackgroundPath(
      projectRootPath: normalizedProjectRoot,
      pickedAbsolutePath: pickedAbsolutePath,
    );
    if (relativePath == null) {
      return;
    }

    setState(() {
      _encounterBattleBackgroundRelativePath = relativePath;
      _encounterBattleBackgroundMessage = null;
    });
  }

  String? _normalizePickedBattleBackgroundPath({
    required String projectRootPath,
    required String pickedAbsolutePath,
  }) {
    final relativePath = normalizeProjectLocalBattleBackgroundPath(
      projectRootPath: projectRootPath,
      pickedAbsolutePath: pickedAbsolutePath,
    );

    if (relativePath == null) {
      setState(() {
        _encounterBattleBackgroundMessage =
            'Only project-local images can be linked to a battle zone.';
      });
      return null;
    }

    return relativePath;
  }

  String? _normalizeOptionalProjectRelativePath(String? rawValue) {
    return normalizeOptionalBattleBackgroundRelativePath(rawValue);
  }

  static IconData _iconForKind(GameplayZoneKind kind) {
    return switch (kind) {
      GameplayZoneKind.encounter => CupertinoIcons.leaf_arrow_circlepath,
      GameplayZoneKind.movement => CupertinoIcons.arrow_right_arrow_left,
      GameplayZoneKind.movementEffect => CupertinoIcons.arrow_2_circlepath,
      GameplayZoneKind.hazard => CupertinoIcons.exclamationmark_triangle,
      GameplayZoneKind.special => CupertinoIcons.star,
      GameplayZoneKind.custom => CupertinoIcons.square_stack_3d_up,
    };
  }

  static String _kindLabel(GameplayZoneKind kind) {
    return switch (kind) {
      GameplayZoneKind.encounter => 'Encounter',
      GameplayZoneKind.movement => 'Movement',
      GameplayZoneKind.movementEffect => 'Movement Effect',
      GameplayZoneKind.hazard => 'Hazard',
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

  static String _movementEffectKindLabel(MovementEffectZoneKind kind) {
    return switch (kind) {
      MovementEffectZoneKind.slide => 'Slide',
      MovementEffectZoneKind.movementCost => 'Movement Cost',
    };
  }

  static String _encounterKindLabel(EncounterKind kind) {
    return switch (kind) {
      EncounterKind.walk => 'Walk (tall grass)',
      EncounterKind.surf => 'Surf',
      EncounterKind.headbutt => 'Headbutt',
      EncounterKind.oldRod => 'Old Rod',
      EncounterKind.goodRod => 'Good Rod',
      EncounterKind.superRod => 'Super Rod',
      EncounterKind.gift => 'Gift',
      EncounterKind.special => 'Special',
    };
  }

  static String _hazardKindLabel(HazardKind kind) {
    return switch (kind) {
      HazardKind.lava => 'Lava',
      HazardKind.poison => 'Poison',
      HazardKind.swamp => 'Swamp',
      HazardKind.pitfall => 'Pitfall',
      HazardKind.other => 'Other',
    };
  }
}

/// Petit séparateur de section avec label.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = CupertinoColors.tertiaryLabel.resolveFrom(context);
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Container(height: 1, color: color.withValues(alpha: 0.3))),
      ],
    );
  }
}
