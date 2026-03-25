import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

class EncounterTablesPanel extends ConsumerStatefulWidget {
  const EncounterTablesPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<EncounterTablesPanel> createState() =>
      _EncounterTablesPanelState();
}

class _EncounterTablesPanelState extends ConsumerState<EncounterTablesPanel> {
  // Create table form state
  final _newTableNameController = TextEditingController();
  EncounterKind _newTableKind = EncounterKind.walk;
  bool _showCreateForm = false;

  // Selected table editing
  String? _editingTableId;
  final _editTableNameController = TextEditingController();
  EncounterKind _editTableKind = EncounterKind.walk;

  // Entry editing per table: tableId → entryIndex (null = new)
  String? _editingEntryTableId;
  int? _editingEntryIndex;
  final _entrySpeciesController = TextEditingController();
  final _entryMinLevelController = TextEditingController();
  final _entryMaxLevelController = TextEditingController();
  final _entryWeightController = TextEditingController();

  @override
  void dispose() {
    _newTableNameController.dispose();
    _editTableNameController.dispose();
    _entrySpeciesController.dispose();
    _entryMinLevelController.dispose();
    _entryMaxLevelController.dispose();
    _entryWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.inspectorJoyCyan;

    final tables = project?.encounterTables ?? const [];

    final content = project == null
        ? Center(
            child: Text(
              'No project loaded',
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
              // Create table button / form
              if (!_showCreateForm)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: widget.embedded
                      ? InspectorEmbeddedPrimaryCapsule(
                          accent: accent,
                          icon: CupertinoIcons.add_circled,
                          label: 'Nouvelle table',
                          prominent: false,
                          onPressed: () =>
                              setState(() => _showCreateForm = true),
                        )
                      : CupertinoButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: () =>
                              setState(() => _showCreateForm = true),
                          child: const Row(
                            children: [
                              Icon(CupertinoIcons.add_circled, size: 16),
                              SizedBox(width: 6),
                              Text('New Table',
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                )
              else
                _buildCreateTableForm(context, notifier, accent),

              if (tables.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No encounter tables. Create one above.',
                    style: TextStyle(
                      color:
                          CupertinoColors.placeholderText.resolveFrom(context),
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...tables.map(
                  (table) => _buildTableCard(
                    context: context,
                    notifier: notifier,
                    table: table,
                    accent: accent,
                    subtle: subtle,
                  ),
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
                    'ENCOUNTER TABLES',
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
                  '${tables.length}',
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

  Widget _buildCreateTableForm(
    BuildContext context,
    EditorNotifier notifier,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: EditorChrome.inspectorTileHardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.embedded)
                const InspectorEmbeddedSectionLabel('Nouvelle table')
              else
                Text(
                  'New Table',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),
              _labeledField(
                context,
                label: 'Name',
                controller: _newTableNameController,
              ),
              const SizedBox(height: 8),
              if (widget.embedded)
                InspectorEmbeddedDropdown(
                  accent: accent,
                  fieldLabel: 'Kind',
                  valueLabel: _kindLabel(_newTableKind),
                  orderedIds:
                      EncounterKind.values.map((k) => k.name).toList(),
                  selectedMenuValue: _newTableKind.name,
                  selectedIdForCheck: _newTableKind.name,
                  idToLabel: (id) => _kindLabel(
                    EncounterKind.values.firstWhere((k) => k.name == id),
                  ),
                  onSelected: (id) => setState(() {
                    _newTableKind =
                        EncounterKind.values.firstWhere((k) => k.name == id);
                  }),
                  tooltip: 'Encounter kind',
                )
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () async {
                    final picked =
                        await showCupertinoListPicker<EncounterKind>(
                      context: context,
                      title: 'Encounter Kind',
                      items: EncounterKind.values,
                      labelOf: _kindLabel,
                    );
                    if (picked != null) setState(() => _newTableKind = picked);
                  },
                  child: Text('Kind: ${_kindLabel(_newTableKind)}'),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      onPressed: () => _createTable(context, notifier),
                      child: const Text('Create'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () {
                      setState(() {
                        _showCreateForm = false;
                        _newTableNameController.clear();
                        _newTableKind = EncounterKind.walk;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard({
    required BuildContext context,
    required EditorNotifier notifier,
    required ProjectEncounterTable table,
    required Color accent,
    required Color subtle,
  }) {
    final isEditingThis = _editingTableId == table.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEditingThis
                ? accent.withValues(alpha: 0.7)
                : EditorChrome.editorIslandRim(context),
            width: 1,
          ),
          boxShadow: EditorChrome.inspectorTileHardShadows(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table header
            CupertinoButton(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              alignment: Alignment.centerLeft,
              onPressed: () {
                setState(() {
                  if (_editingTableId == table.id) {
                    _editingTableId = null;
                  } else {
                    _editingTableId = table.id;
                    _editTableNameController.text = table.name;
                    _editTableKind = table.encounterKind;
                    _editingEntryTableId = null;
                    _editingEntryIndex = null;
                  }
                });
              },
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.list_bullet,
                    size: 15,
                    color: isEditingThis ? accent : subtle,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.label.resolveFrom(context),
                            fontWeight: isEditingThis
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_kindLabel(table.encounterKind)} · ${table.entries.length} entr${table.entries.length == 1 ? 'y' : 'ies'} · ${table.id}',
                          style: TextStyle(fontSize: 11, color: subtle),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isEditingThis
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 14,
                    color: subtle,
                  ),
                ],
              ),
            ),
            if (isEditingThis) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: EditorHorizontalDivider(),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: _buildTableEditor(context, notifier, table, accent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableEditor(
    BuildContext context,
    EditorNotifier notifier,
    ProjectEncounterTable table,
    Color accent,
  ) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isEditingEntry = _editingEntryTableId == table.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table name/kind edit
        _labeledField(context, label: 'Name', controller: _editTableNameController),
        const SizedBox(height: 8),
        if (widget.embedded)
          InspectorEmbeddedDropdown(
            accent: accent,
            fieldLabel: 'Kind',
            valueLabel: _kindLabel(_editTableKind),
            orderedIds: EncounterKind.values.map((k) => k.name).toList(),
            selectedMenuValue: _editTableKind.name,
            selectedIdForCheck: _editTableKind.name,
            idToLabel: (id) => _kindLabel(
              EncounterKind.values.firstWhere((k) => k.name == id),
            ),
            onSelected: (id) => setState(() {
              _editTableKind =
                  EncounterKind.values.firstWhere((k) => k.name == id);
            }),
            tooltip: 'Encounter kind',
          )
        else
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked = await showCupertinoListPicker<EncounterKind>(
                context: context,
                title: 'Encounter Kind',
                items: EncounterKind.values,
                labelOf: _kindLabel,
              );
              if (picked != null) setState(() => _editTableKind = picked);
            },
            child: Text('Kind: ${_kindLabel(_editTableKind)}'),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 8),
                onPressed: () => _updateTable(context, notifier, table.id),
                child: const Text('Save Table'),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: () => _deleteTable(context, notifier, table.id),
              child: const Text('Delete Table'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const EditorHorizontalDivider(),
        const SizedBox(height: 8),
        // Entries section
        Row(
          children: [
            Expanded(
              child: Text(
                'Entries (${table.entries.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subtle,
                ),
              ),
            ),
            EditorToolbarIconButton(
              onPressed: () {
                setState(() {
                  _editingEntryTableId = table.id;
                  _editingEntryIndex = null;
                  _entrySpeciesController.clear();
                  _entryMinLevelController.text = '1';
                  _entryMaxLevelController.text = '5';
                  _entryWeightController.text = '1';
                });
              },
              icon: CupertinoIcons.add,
              tooltip: 'Add entry',
            ),
          ],
        ),
        // Entry list
        if (table.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No entries yet.',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        else
          ...List.generate(table.entries.length, (index) {
            final entry = table.entries[index];
            final isEditingThisEntry = isEditingEntry &&
                _editingEntryIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isEditingThisEntry
                      ? Color.lerp(
                          EditorChrome.islandFillElevated(context),
                          accent,
                          0.18,
                        )!
                      : EditorChrome.islandFill(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isEditingThisEntry
                        ? accent.withValues(alpha: 0.6)
                        : EditorChrome.editorIslandRim(context),
                  ),
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  alignment: Alignment.centerLeft,
                  onPressed: () {
                    setState(() {
                      if (isEditingThisEntry) {
                        _editingEntryTableId = null;
                        _editingEntryIndex = null;
                      } else {
                        _editingEntryTableId = table.id;
                        _editingEntryIndex = index;
                        _entrySpeciesController.text = entry.speciesId;
                        _entryMinLevelController.text =
                            entry.minLevel.toString();
                        _entryMaxLevelController.text =
                            entry.maxLevel.toString();
                        _entryWeightController.text =
                            entry.weight.toString();
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entry.speciesId}  Lv.${entry.minLevel}–${entry.maxLevel}  ×${entry.weight}',
                          style: TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                      EditorToolbarIconButton(
                        onPressed: () =>
                            _deleteEntry(notifier, table.id, index),
                        icon: CupertinoIcons.trash,
                        tooltip: 'Delete entry',
                        iconSize: 15,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        // Entry edit form
        if (isEditingEntry) ...[
          const SizedBox(height: 8),
          _buildEntryForm(context, notifier, table.id, accent),
        ],
      ],
    );
  }

  Widget _buildEntryForm(
    BuildContext context,
    EditorNotifier notifier,
    String tableId,
    Color accent,
  ) {
    final isNew = _editingEntryIndex == null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? 'New Entry' : 'Edit Entry',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Species ID',
              controller: _entrySpeciesController,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _labeledField(
                    context,
                    label: 'Min Lv',
                    controller: _entryMinLevelController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _labeledField(
                    context,
                    label: 'Max Lv',
                    controller: _entryMaxLevelController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _labeledField(
                    context,
                    label: 'Weight',
                    controller: _entryWeightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    onPressed: () => _saveEntry(context, notifier, tableId),
                    child: Text(isNew ? 'Add' : 'Save'),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  onPressed: () {
                    setState(() {
                      _editingEntryTableId = null;
                      _editingEntryIndex = null;
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
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
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }

  Future<void> _createTable(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final name = _newTableNameController.text.trim();
    if (name.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        message: 'Table name cannot be empty',
      );
      return;
    }
    await notifier.createEncounterTable(
      name: name,
      encounterKind: _newTableKind,
    );
    setState(() {
      _showCreateForm = false;
      _newTableNameController.clear();
      _newTableKind = EncounterKind.walk;
    });
  }

  Future<void> _updateTable(
    BuildContext context,
    EditorNotifier notifier,
    String tableId,
  ) async {
    final name = _editTableNameController.text.trim();
    if (name.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        message: 'Table name cannot be empty',
      );
      return;
    }
    await notifier.updateEncounterTable(
      tableId: tableId,
      name: name,
      encounterKind: _editTableKind,
    );
  }

  Future<void> _deleteTable(
    BuildContext context,
    EditorNotifier notifier,
    String tableId,
  ) async {
    await notifier.deleteEncounterTable(tableId);
    setState(() {
      if (_editingTableId == tableId) _editingTableId = null;
      if (_editingEntryTableId == tableId) {
        _editingEntryTableId = null;
        _editingEntryIndex = null;
      }
    });
  }

  Future<void> _saveEntry(
    BuildContext context,
    EditorNotifier notifier,
    String tableId,
  ) async {
    final species = _entrySpeciesController.text.trim();
    final minLevel = int.tryParse(_entryMinLevelController.text.trim());
    final maxLevel = int.tryParse(_entryMaxLevelController.text.trim());
    final weight = int.tryParse(_entryWeightController.text.trim()) ?? 1;

    if (species.isEmpty) {
      await showCupertinoEditorAlert(context, message: 'Species ID is required');
      return;
    }
    if (minLevel == null || maxLevel == null) {
      await showCupertinoEditorAlert(
          context, message: 'Levels must be valid integers');
      return;
    }

    final index = _editingEntryIndex;
    if (index == null) {
      await notifier.addEncounterEntry(
        tableId: tableId,
        speciesId: species,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
    } else {
      await notifier.updateEncounterEntry(
        tableId: tableId,
        entryIndex: index,
        speciesId: species,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
    }
    setState(() {
      _editingEntryTableId = null;
      _editingEntryIndex = null;
    });
  }

  void _deleteEntry(EditorNotifier notifier, String tableId, int index) {
    notifier.deleteEncounterEntry(tableId: tableId, entryIndex: index);
    if (_editingEntryTableId == tableId && _editingEntryIndex == index) {
      setState(() {
        _editingEntryTableId = null;
        _editingEntryIndex = null;
      });
    }
  }

  static String _kindLabel(EncounterKind kind) {
    return switch (kind) {
      EncounterKind.walk => 'Walk',
      EncounterKind.surf => 'Surf',
      EncounterKind.headbutt => 'Headbutt',
      EncounterKind.oldRod => 'Old Rod',
      EncounterKind.goodRod => 'Good Rod',
      EncounterKind.superRod => 'Super Rod',
      EncounterKind.gift => 'Gift',
      EncounterKind.special => 'Special',
    };
  }
}
