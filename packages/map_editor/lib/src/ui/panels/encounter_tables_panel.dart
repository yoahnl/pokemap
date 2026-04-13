import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../app/providers/core/repository_providers.dart';
import '../../app/providers/pokedex/pokedex_providers.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_species_lookup_service.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

const PokemonSpeciesLookupService _encounterSpeciesLookupService =
    PokemonSpeciesLookupService();

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
  // -------------------------------------------------------------------------
  // Create table draft
  // -------------------------------------------------------------------------

  final _newTableNameController = TextEditingController();
  EncounterKind _newTableKind = EncounterKind.walk;
  bool _showCreateForm = false;
  String? _createTableValidationMessage;

  // -------------------------------------------------------------------------
  // Edit table draft
  // -------------------------------------------------------------------------

  String? _editingTableId;
  final _editTableNameController = TextEditingController();
  EncounterKind _editTableKind = EncounterKind.walk;
  String? _editTableValidationMessage;

  // -------------------------------------------------------------------------
  // Shared encounter entry draft
  // -------------------------------------------------------------------------
  //
  // We intentionally keep one draft and one editor surface:
  // - add and edit share the exact same validation path;
  // - the panel remains the only owner of this authoring UX state;
  // - notifier/use cases remain pure orchestration + persistence.

  String? _editingEntryTableId;
  int? _editingEntryIndex;
  final _entrySpeciesController = TextEditingController();
  final _entryMinLevelController = TextEditingController(text: '1');
  final _entryMaxLevelController = TextEditingController(text: '5');
  final _entryWeightController = TextEditingController(text: '1');
  String? _entryValidationMessage;

  // -------------------------------------------------------------------------
  // Local Pokédex references used only for encounter authoring assistance
  // -------------------------------------------------------------------------

  String? _referenceProjectRootPath;
  Future<_EncounterReferenceData>? _referenceDataFuture;

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

    _ensureReferenceDataForState(state);

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.inspectorJoyCyan;

    final tables = project?.encounterTables ?? const <ProjectEncounterTable>[];

    final content = project == null
        ? Center(
            child: Text(
              'No project loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : FutureBuilder<_EncounterReferenceData>(
            future: _referenceDataFuture,
            initialData: const _EncounterReferenceData.loading(),
            builder: (context, snapshot) {
              final references =
                  snapshot.data ?? const _EncounterReferenceData.loading();
              return ListView(
                padding: widget.embedded
                    ? kInspectorTileBodyPadding
                    : const EdgeInsets.fromLTRB(8, 8, 8, 8),
                children: [
                  _buildReferencesBanner(
                    context,
                    references,
                    accent: accent,
                    onRefresh: () => _refreshReferenceData(state),
                  ),
                  if ((state.errorMessage ?? '').trim().isNotEmpty ||
                      (state.statusMessage ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildOperationBanner(
                        context,
                        message:
                            (state.errorMessage?.trim().isNotEmpty ?? false)
                                ? state.errorMessage!.trim()
                                : state.statusMessage!.trim(),
                        isError:
                            (state.errorMessage?.trim().isNotEmpty ?? false),
                      ),
                    ),
                  if (!_showCreateForm)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: widget.embedded
                          ? InspectorEmbeddedPrimaryCapsule(
                              key: const Key(
                                'encounter-tables-new-table-button',
                              ),
                              accent: accent,
                              icon: CupertinoIcons.add_circled,
                              label: 'Nouvelle table',
                              prominent: false,
                              onPressed: () => setState(() {
                                _showCreateForm = true;
                                _editingTableId = null;
                                _closeEntryEditor();
                                _createTableValidationMessage = null;
                              }),
                            )
                          : CupertinoButton(
                              key: const Key(
                                'encounter-tables-new-table-button',
                              ),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                              onPressed: () => setState(() {
                                _showCreateForm = true;
                                _editingTableId = null;
                                _closeEntryEditor();
                                _createTableValidationMessage = null;
                              }),
                              child: const Row(
                                children: [
                                  Icon(CupertinoIcons.add_circled, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'New Table',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                    )
                  else
                    _buildCreateTableForm(
                      context,
                      notifier,
                      accent,
                    ),
                  if (tables.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'No encounter tables. Create one above.',
                        style: TextStyle(
                          color: CupertinoColors.placeholderText
                              .resolveFrom(context),
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
                        references: references,
                        accent: accent,
                        subtle: subtle,
                      ),
                    ),
                ],
              );
            },
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

  // -------------------------------------------------------------------------
  // Local reference loading
  // -------------------------------------------------------------------------

  void _ensureReferenceDataForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (_referenceProjectRootPath == projectRootPath &&
        _referenceDataFuture != null) {
      return;
    }

    _referenceProjectRootPath = projectRootPath;
    final workspace = _workspaceForState(state);
    _referenceDataFuture = workspace == null
        ? Future<_EncounterReferenceData>.value(
            const _EncounterReferenceData.unavailable(),
          )
        : _loadReferenceData(workspace);
  }

  Future<void> _refreshReferenceData(EditorState state) async {
    final workspace = _workspaceForState(state);
    if (workspace == null) {
      return;
    }

    setState(() {
      _referenceDataFuture = _loadReferenceData(workspace);
    });
  }

  ProjectWorkspace? _workspaceForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return null;
    }
    return ref.read(projectWorkspaceFactoryProvider).create(projectRootPath);
  }

  Future<_EncounterReferenceData> _loadReferenceData(
    ProjectWorkspace workspace,
  ) async {
    final speciesLoader = ref.read(pokedexEntryLoaderProvider);

    try {
      final speciesEntries = await speciesLoader(workspace);
      return speciesEntries.isEmpty
          ? const _EncounterReferenceData(
              speciesEntries: <PokemonDatabaseIndexEntry>[],
              isSpeciesAvailable: false,
              speciesMessage:
                  'No local species are indexed yet. Raw species IDs are still allowed.',
            )
          : _EncounterReferenceData(
              speciesEntries: speciesEntries,
              isSpeciesAvailable: true,
              speciesMessage:
                  'Local species assist active on ${speciesEntries.length} indexed species.',
            );
    } catch (error) {
      return _EncounterReferenceData(
        speciesEntries: const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable: false,
        speciesMessage:
            'Unable to load local species data. Raw species IDs are still allowed.\n$error',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Table CRUD
  // -------------------------------------------------------------------------

  Widget _buildCreateTableForm(
    BuildContext context,
    EditorNotifier notifier,
    Color accent,
  ) {
    final inlineValidation = _validateTableName(_newTableNameController.text);
    final message = _createTableValidationMessage ?? inlineValidation;

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
                fieldKey: const Key('encounter-tables-create-name-field'),
                label: 'Name',
                placeholder: 'Grass Patch',
                controller: _newTableNameController,
                onChanged: (_) => setState(() {
                  _createTableValidationMessage = null;
                }),
                validationMessage: inlineValidation,
              ),
              const SizedBox(height: 8),
              if (widget.embedded)
                InspectorEmbeddedDropdown(
                  accent: accent,
                  fieldLabel: 'Kind',
                  valueLabel: _kindLabel(_newTableKind),
                  orderedIds: EncounterKind.values.map((k) => k.name).toList(),
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
                    final picked = await showCupertinoListPicker<EncounterKind>(
                      context: context,
                      title: 'Encounter Kind',
                      items: EncounterKind.values,
                      labelOf: _kindLabel,
                    );
                    if (picked != null) {
                      setState(() => _newTableKind = picked);
                    }
                  },
                  child: Text('Kind: ${_kindLabel(_newTableKind)}'),
                ),
              if (message != null && inlineValidation == null) ...[
                const SizedBox(height: 8),
                _buildInlineMessage(
                  context,
                  message,
                  isError: true,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      key: const Key(
                        'encounter-tables-create-submit-button',
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      onPressed: inlineValidation == null
                          ? () => _createTable(notifier)
                          : null,
                      child: const Text('Create'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () => setState(_resetCreateTableDraft),
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
    required _EncounterReferenceData references,
    required Color accent,
    required Color subtle,
  }) {
    final isEditingThis = _editingTableId == table.id;
    final totalWeight = _tableTotalWeight(table);

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
            CupertinoButton(
              key: Key('encounter-tables-table-toggle-${table.id}'),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              alignment: Alignment.centerLeft,
              onPressed: () {
                setState(() {
                  if (_editingTableId == table.id) {
                    _closeTableEditor();
                  } else {
                    _editingTableId = table.id;
                    _editTableNameController.text = table.name;
                    _editTableKind = table.encounterKind;
                    _editTableValidationMessage = null;
                    _showCreateForm = false;
                    _closeEntryEditor();
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
                          '${_kindLabel(table.encounterKind)} · ${table.entries.length} entr${table.entries.length == 1 ? 'y' : 'ies'} · total weight $totalWeight · ${table.id}',
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
                child: _buildTableEditor(
                  context,
                  notifier,
                  table,
                  references,
                  accent,
                ),
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
    _EncounterReferenceData references,
    Color accent,
  ) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isEditingEntry = _editingEntryTableId == table.id;
    final inlineValidation = _validateTableName(_editTableNameController.text);
    final totalWeight = _tableTotalWeight(table);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labeledField(
          context,
          fieldKey: Key('encounter-tables-edit-name-field-${table.id}'),
          label: 'Name',
          placeholder: 'Grass Patch',
          controller: _editTableNameController,
          onChanged: (_) => setState(() {
            _editTableValidationMessage = null;
          }),
          validationMessage: inlineValidation,
        ),
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
              if (picked != null) {
                setState(() => _editTableKind = picked);
              }
            },
            child: Text('Kind: ${_kindLabel(_editTableKind)}'),
          ),
        if (_editTableValidationMessage != null &&
            inlineValidation == null) ...[
          const SizedBox(height: 8),
          _buildInlineMessage(
            context,
            _editTableValidationMessage!,
            isError: true,
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CupertinoButton.filled(
                key: Key('encounter-tables-save-table-button-${table.id}'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                onPressed: inlineValidation == null
                    ? () => _updateTable(notifier, table.id)
                    : null,
                child: const Text('Save Table'),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              key: Key('encounter-tables-delete-table-button-${table.id}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: () => _deleteTable(notifier, table.id),
              child: const Text('Delete Table'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const EditorHorizontalDivider(),
        const SizedBox(height: 8),
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
            Text(
              'Total weight: $totalWeight',
              style: TextStyle(fontSize: 11, color: subtle),
            ),
            const SizedBox(width: 8),
            EditorToolbarIconButton(
              key: Key('encounter-tables-add-entry-button-${table.id}'),
              onPressed: () {
                setState(() {
                  _editingEntryTableId = table.id;
                  _editingEntryIndex = null;
                  _entryValidationMessage = null;
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
        const SizedBox(height: 4),
        Text(
          'Higher weight means the entry appears more often. Percentages below are derived from the current table.',
          style: TextStyle(fontSize: 11, color: subtle, height: 1.35),
        ),
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
            final isEditingThisEntry =
                isEditingEntry && _editingEntryIndex == index;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildEntryRow(
                context: context,
                table: table,
                entry: entry,
                entryIndex: index,
                references: references,
                isEditingThisEntry: isEditingThisEntry,
                accent: accent,
                onToggleEdit: () {
                  setState(() {
                    if (isEditingThisEntry) {
                      _closeEntryEditor();
                    } else {
                      _editingEntryTableId = table.id;
                      _editingEntryIndex = index;
                      _entryValidationMessage = null;
                      _entrySpeciesController.text = entry.speciesId;
                      _entryMinLevelController.text = entry.minLevel.toString();
                      _entryMaxLevelController.text = entry.maxLevel.toString();
                      _entryWeightController.text = entry.weight.toString();
                    }
                  });
                },
                onDelete: () => _deleteEntry(notifier, table.id, index),
              ),
            );
          }),
        if (isEditingEntry) ...[
          const SizedBox(height: 8),
          _buildEntryForm(
            context,
            notifier,
            table,
            references,
            accent,
          ),
        ],
      ],
    );
  }

  Widget _buildEntryRow({
    required BuildContext context,
    required ProjectEncounterTable table,
    required ProjectEncounterEntry entry,
    required int entryIndex,
    required _EncounterReferenceData references,
    required bool isEditingThisEntry,
    required Color accent,
    required VoidCallback onToggleEdit,
    required VoidCallback onDelete,
  }) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedSpecies = _resolveSpecies(references, entry.speciesId);
    final chanceLabel = _formatEncounterShare(
      _entryChance(table: table, weight: entry.weight),
    );

    return DecoratedBox(
      key: Key('encounter-tables-entry-row-${table.id}-$entryIndex'),
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
        onPressed: onToggleEdit,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedSpecies == null
                        ? '${entry.speciesId} • Lv.${entry.minLevel}-${entry.maxLevel}'
                        : '${resolvedSpecies.primaryName} • ${entry.speciesId} • Lv.${entry.minLevel}-${entry.maxLevel}',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.label.resolveFrom(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Weight ${entry.weight}${chanceLabel == null ? '' : ' • $chanceLabel'}',
                    style: TextStyle(fontSize: 11, color: subtle),
                  ),
                  if (resolvedSpecies == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      references.isSpeciesAvailable
                          ? 'Species not present in the local Pokédex.'
                          : 'Local species verification unavailable. The raw species ID is preserved.',
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            EditorToolbarIconButton(
              onPressed: onDelete,
              icon: CupertinoIcons.trash,
              tooltip: 'Delete entry',
              iconSize: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm(
    BuildContext context,
    EditorNotifier notifier,
    ProjectEncounterTable table,
    _EncounterReferenceData references,
    Color accent,
  ) {
    final isNew = _editingEntryIndex == null;
    final validation = _validateEntryDraft(references: references);
    final speciesStatus = _resolveSpeciesStatus(
      references: references,
      rawSpeciesId: _entrySpeciesController.text,
    );
    final suggestions = _buildSpeciesSuggestions(
      references: references,
      rawQuery: _entrySpeciesController.text,
    );
    final previewShare = _draftEncounterChance(table: table);

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
              fieldKey: const Key('encounter-tables-entry-species-field'),
              label: 'Species ID',
              placeholder: 'bulbasaur',
              controller: _entrySpeciesController,
              onChanged: (_) => setState(() {
                _entryValidationMessage = null;
              }),
              validationMessage: validation.speciesMessage,
            ),
            const SizedBox(height: 4),
            _buildInlineMessage(
              context,
              speciesStatus.message,
              isError: speciesStatus.isError,
            ),
            if (_entrySpeciesController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              if (!references.isSpeciesAvailable)
                _buildInlineMessage(
                  context,
                  'Local species suggestions are unavailable right now.',
                  isError: true,
                  key: const Key(
                    'encounter-tables-entry-species-search-unavailable',
                  ),
                )
              else if (suggestions.isEmpty)
                _buildInlineMessage(
                  context,
                  'No local species suggestion matches this query.',
                  isError: true,
                  key: const Key(
                    'encounter-tables-entry-species-search-empty',
                  ),
                )
              else
                Container(
                  key: const Key(
                    'encounter-tables-entry-species-suggestions',
                  ),
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final entry = suggestions[index];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: EditorChrome.islandFill(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                            width: 1,
                          ),
                        ),
                        child: CupertinoButton(
                          key: Key(
                            'encounter-tables-entry-species-suggestion-${entry.id}',
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          onPressed: () => _selectSuggestedSpecies(entry.id),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.primaryName} • ${entry.id}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.types.join(' / ')}',
                                      style: TextStyle(
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Use',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _labeledField(
                    context,
                    fieldKey:
                        const Key('encounter-tables-entry-min-level-field'),
                    label: 'Min Lv',
                    placeholder: '1',
                    controller: _entryMinLevelController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {
                      _entryValidationMessage = null;
                    }),
                    validationMessage: validation.minLevelMessage,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _labeledField(
                    context,
                    fieldKey:
                        const Key('encounter-tables-entry-max-level-field'),
                    label: 'Max Lv',
                    placeholder: '5',
                    controller: _entryMaxLevelController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {
                      _entryValidationMessage = null;
                    }),
                    validationMessage: validation.maxLevelMessage,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _labeledField(
                    context,
                    fieldKey: const Key('encounter-tables-entry-weight-field'),
                    label: 'Weight',
                    placeholder: '1',
                    controller: _entryWeightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {
                      _entryValidationMessage = null;
                    }),
                    validationMessage: validation.weightMessage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildInlineMessage(
              context,
              previewShare == null
                  ? 'Higher weight means the entry appears more often.'
                  : 'With the current draft, this entry would represent $previewShare of the table.',
              isError: false,
            ),
            if (_entryValidationMessage != null &&
                validation.firstMessage == null) ...[
              const SizedBox(height: 8),
              _buildInlineMessage(
                context,
                _entryValidationMessage!,
                isError: true,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    key: const Key('encounter-tables-entry-save-button'),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    onPressed: validation.firstMessage == null
                        ? () => _saveEntry(notifier, table.id, references)
                        : null,
                    child: Text(isNew ? 'Add' : 'Save'),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  onPressed: () => setState(_closeEntryEditor),
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
    Key? fieldKey,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    String? validationMessage,
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
          key: fieldKey,
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
        ),
        if (validationMessage != null) ...[
          const SizedBox(height: 4),
          _buildInlineMessage(
            context,
            validationMessage,
            isError: true,
          ),
        ],
      ],
    );
  }

  Widget _buildReferencesBanner(
    BuildContext context,
    _EncounterReferenceData references, {
    required Color accent,
    required VoidCallback onRefresh,
  }) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isAvailable = references.isSpeciesAvailable;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAvailable
                ? accent.withValues(alpha: 0.25)
                : CupertinoColors.systemYellow.resolveFrom(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.search_circle,
                size: 16,
                color: isAvailable
                    ? accent
                    : CupertinoColors.systemYellow.resolveFrom(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Local species assist',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      references.speciesMessage,
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(1, 22),
                onPressed: onRefresh,
                child: const Icon(
                  CupertinoIcons.refresh,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationBanner(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
    final color = isError
        ? EditorChrome.inspectorJoyCoral
        : EditorChrome.inspectorJoyCyan;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          message,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineMessage(
    BuildContext context,
    String message, {
    required bool isError,
    Key? key,
  }) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Text(
      message,
      key: key,
      style: TextStyle(
        color: isError ? EditorChrome.inspectorJoyCoral : subtle,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
    );
  }

  Future<void> _createTable(EditorNotifier notifier) async {
    final inlineValidation = _validateTableName(_newTableNameController.text);
    setState(() {
      _createTableValidationMessage = inlineValidation;
    });
    if (inlineValidation != null) {
      return;
    }

    final beforeState = ref.read(editorNotifierProvider);
    await notifier.createEncounterTable(
      name: _newTableNameController.text,
      encounterKind: _newTableKind,
    );
    if (!mounted) {
      return;
    }

    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (success) {
      setState(_resetCreateTableDraft);
      return;
    }

    setState(() {
      _createTableValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to create encounter table.';
    });
  }

  Future<void> _updateTable(
    EditorNotifier notifier,
    String tableId,
  ) async {
    final inlineValidation = _validateTableName(_editTableNameController.text);
    setState(() {
      _editTableValidationMessage = inlineValidation;
    });
    if (inlineValidation != null) {
      return;
    }

    final beforeState = ref.read(editorNotifierProvider);
    await notifier.updateEncounterTable(
      tableId: tableId,
      name: _editTableNameController.text,
      encounterKind: _editTableKind,
    );
    if (!mounted) {
      return;
    }

    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (success) {
      setState(() {
        _editTableValidationMessage = null;
      });
      return;
    }

    setState(() {
      _editTableValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to update encounter table.';
    });
  }

  Future<void> _deleteTable(
    EditorNotifier notifier,
    String tableId,
  ) async {
    final beforeState = ref.read(editorNotifierProvider);
    await notifier.deleteEncounterTable(tableId);
    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (!mounted || !success) {
      return;
    }

    setState(() {
      if (_editingTableId == tableId) {
        _closeTableEditor();
      }
      if (_editingEntryTableId == tableId) {
        _closeEntryEditor();
      }
    });
  }

  Future<void> _saveEntry(
    EditorNotifier notifier,
    String tableId,
    _EncounterReferenceData references,
  ) async {
    final validation = _validateEntryDraft(references: references);
    setState(() {
      _entryValidationMessage = validation.firstMessage;
    });
    if (validation.firstMessage != null) {
      return;
    }

    final minLevel = int.parse(_entryMinLevelController.text.trim());
    final maxLevel = int.parse(_entryMaxLevelController.text.trim());
    final weight = int.parse(_entryWeightController.text.trim());

    final beforeState = ref.read(editorNotifierProvider);
    final index = _editingEntryIndex;
    if (index == null) {
      await notifier.addEncounterEntry(
        tableId: tableId,
        speciesId: _entrySpeciesController.text.trim(),
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
    } else {
      await notifier.updateEncounterEntry(
        tableId: tableId,
        entryIndex: index,
        speciesId: _entrySpeciesController.text.trim(),
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
    }
    if (!mounted) {
      return;
    }

    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (success) {
      setState(_closeEntryEditor);
      return;
    }

    setState(() {
      _entryValidationMessage = ref.read(editorNotifierProvider).errorMessage ??
          'Failed to save encounter entry.';
    });
  }

  Future<void> _deleteEntry(
    EditorNotifier notifier,
    String tableId,
    int index,
  ) async {
    final beforeState = ref.read(editorNotifierProvider);
    await notifier.deleteEncounterEntry(
      tableId: tableId,
      entryIndex: index,
    );
    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (!mounted || !success) {
      return;
    }

    setState(() {
      if (_editingEntryTableId != tableId) {
        return;
      }
      if (_editingEntryIndex == index) {
        _closeEntryEditor();
        return;
      }
      if (_editingEntryIndex != null && _editingEntryIndex! > index) {
        _editingEntryIndex = _editingEntryIndex! - 1;
      }
    });
  }

  // We deliberately keep this success heuristic local to the encounter panel.
  // Why here instead of changing the notifier contract:
  // - the encounter pipeline already exists and already reports failures by
  //   mutating `errorMessage`;
  // - the panel only needs one local answer: did the project snapshot change;
  // - widening the notifier API just for this surface would be needless scope.
  bool _didEncounterMutationSucceed({
    required EditorState beforeState,
    required EditorState afterState,
  }) {
    if ((afterState.errorMessage?.trim().isNotEmpty ?? false)) {
      return false;
    }
    return !identical(beforeState.project, afterState.project);
  }

  void _selectSuggestedSpecies(String speciesId) {
    _entrySpeciesController
      ..text = speciesId
      ..selection = TextSelection.collapsed(offset: speciesId.length);
    setState(() {
      _entryValidationMessage = null;
    });
  }

  String? _validateTableName(String rawName) {
    if (rawName.trim().isEmpty) {
      return 'Table name cannot be empty.';
    }
    return null;
  }

  _EncounterEntryDraftValidation _validateEntryDraft({
    required _EncounterReferenceData references,
  }) {
    final speciesId = _entrySpeciesController.text.trim();
    final minLevel = int.tryParse(_entryMinLevelController.text.trim());
    final maxLevel = int.tryParse(_entryMaxLevelController.text.trim());
    final weight = int.tryParse(_entryWeightController.text.trim());

    String? speciesMessage;
    if (speciesId.isEmpty) {
      speciesMessage = 'Species ID cannot be empty.';
    } else if (references.isSpeciesAvailable &&
        _resolveSpecies(references, speciesId) == null) {
      speciesMessage =
          'Species "$speciesId" is not present in the local Pokédex.';
    }

    String? minLevelMessage;
    if (minLevel == null || minLevel <= 0) {
      minLevelMessage = 'Min level must be a positive integer.';
    }

    String? maxLevelMessage;
    if (maxLevel == null || maxLevel <= 0) {
      maxLevelMessage = 'Max level must be a positive integer.';
    } else if (minLevel != null && minLevel > 0 && minLevel > maxLevel) {
      maxLevelMessage = 'Max level must be greater than or equal to min level.';
    }

    String? weightMessage;
    if (weight == null || weight <= 0) {
      weightMessage = 'Weight must be a positive integer.';
    }

    return _EncounterEntryDraftValidation(
      speciesMessage: speciesMessage,
      minLevelMessage: minLevelMessage,
      maxLevelMessage: maxLevelMessage,
      weightMessage: weightMessage,
    );
  }

  PokemonDatabaseIndexEntry? _resolveSpecies(
    _EncounterReferenceData references,
    String rawSpeciesId,
  ) {
    if (!references.isSpeciesAvailable) {
      return null;
    }
    return _encounterSpeciesLookupService.findById(
      references.speciesEntries,
      rawSpeciesId,
    );
  }

  _EncounterSpeciesStatus _resolveSpeciesStatus({
    required _EncounterReferenceData references,
    required String rawSpeciesId,
  }) {
    final speciesId = rawSpeciesId.trim();
    if (speciesId.isEmpty) {
      return const _EncounterSpeciesStatus(
        message:
            'Search by species id, local name or Pokédex number when local data is available.',
        isError: false,
      );
    }

    if (!references.isSpeciesAvailable) {
      return const _EncounterSpeciesStatus(
        message:
            'Unable to verify against local species data. Raw species IDs are still allowed.',
        isError: false,
      );
    }

    final resolved = _resolveSpecies(references, speciesId);
    if (resolved == null) {
      return const _EncounterSpeciesStatus(
        message: 'Species not present in the local Pokédex.',
        isError: true,
      );
    }

    final dexLabel = resolved.nationalDex > 0
        ? '#${resolved.nationalDex.toString().padLeft(4, '0')}'
        : 'No dex number';
    return _EncounterSpeciesStatus(
      message:
          'Local species match: ${resolved.primaryName} • $dexLabel • ${resolved.id}',
      isError: false,
    );
  }

  List<PokemonDatabaseIndexEntry> _buildSpeciesSuggestions({
    required _EncounterReferenceData references,
    required String rawQuery,
  }) {
    if (!references.isSpeciesAvailable) {
      return const <PokemonDatabaseIndexEntry>[];
    }
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return const <PokemonDatabaseIndexEntry>[];
    }
    return _encounterSpeciesLookupService.search(
      references.speciesEntries,
      query,
      limit: 8,
    );
  }

  int _tableTotalWeight(ProjectEncounterTable table) {
    return table.entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.weight > 0 ? entry.weight : 0),
    );
  }

  double? _entryChance({
    required ProjectEncounterTable table,
    required int weight,
  }) {
    final totalWeight = _tableTotalWeight(table);
    if (weight <= 0 || totalWeight <= 0) {
      return null;
    }
    return weight / totalWeight;
  }

  String? _draftEncounterChance({
    required ProjectEncounterTable table,
  }) {
    final draftWeight = int.tryParse(_entryWeightController.text.trim());
    if (draftWeight == null || draftWeight <= 0) {
      return null;
    }

    var totalWeight = _tableTotalWeight(table);
    if (_editingEntryTableId == table.id && _editingEntryIndex != null) {
      final current = table.entries[_editingEntryIndex!];
      totalWeight = totalWeight - current.weight + draftWeight;
    } else {
      totalWeight += draftWeight;
    }

    if (totalWeight <= 0) {
      return null;
    }
    return _formatEncounterShare(draftWeight / totalWeight);
  }

  String? _formatEncounterShare(double? share) {
    if (share == null) {
      return null;
    }
    return '${(share * 100).toStringAsFixed(1)}%';
  }

  void _resetCreateTableDraft() {
    _showCreateForm = false;
    _createTableValidationMessage = null;
    _newTableNameController.clear();
    _newTableKind = EncounterKind.walk;
  }

  void _closeTableEditor() {
    _editingTableId = null;
    _editTableValidationMessage = null;
  }

  void _closeEntryEditor() {
    _editingEntryTableId = null;
    _editingEntryIndex = null;
    _entryValidationMessage = null;
    _entrySpeciesController.clear();
    _entryMinLevelController.text = '1';
    _entryMaxLevelController.text = '5';
    _entryWeightController.text = '1';
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

class _EncounterReferenceData {
  const _EncounterReferenceData({
    required this.speciesEntries,
    required this.isSpeciesAvailable,
    required this.speciesMessage,
  });

  const _EncounterReferenceData.loading()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Loading local species data… Raw species IDs are still allowed during this load.';

  const _EncounterReferenceData.unavailable()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'No usable Pokémon workspace detected. Raw species IDs are still allowed, but without local assistance.';

  final List<PokemonDatabaseIndexEntry> speciesEntries;
  final bool isSpeciesAvailable;
  final String speciesMessage;
}

class _EncounterEntryDraftValidation {
  const _EncounterEntryDraftValidation({
    this.speciesMessage,
    this.minLevelMessage,
    this.maxLevelMessage,
    this.weightMessage,
  });

  final String? speciesMessage;
  final String? minLevelMessage;
  final String? maxLevelMessage;
  final String? weightMessage;

  String? get firstMessage =>
      speciesMessage ?? minLevelMessage ?? maxLevelMessage ?? weightMessage;
}

class _EncounterSpeciesStatus {
  const _EncounterSpeciesStatus({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;
}
