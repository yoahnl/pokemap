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

// Keep the encounters panel in one Dart library so the corrective pass can
// split the noise into neighboring `part` files without changing visibility,
// notifier contracts, or the existing encounter authoring pipeline.
part 'encounter_tables_panel_support.dart';
part 'encounter_tables_panel_table_widgets.dart';
part 'encounter_tables_panel_entry_widgets.dart';

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
  // Add and edit intentionally share the same local draft surface:
  // - the validation path stays identical for add vs edit;
  // - notifier/use cases stay focused on persistence, not draft state;
  // - the panel remains the single owner of this authoring UX state.

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
                                    'Nouvelle table',
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
                        'Aucune table de rencontres. Créez-en une ci-dessus.',
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
                    'TABLES DE RENCONTRES',
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

  Future<void> _createTable(EditorNotifier notifier) async {
    final inlineValidation =
        _validateEncounterTableName(_newTableNameController.text);
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
    final inlineValidation =
        _validateEncounterTableName(_editTableNameController.text);
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
      // Match the rest of the surface: a successful mutation closes the active
      // draft instead of leaving the user inside an editor that already saved.
      setState(_closeTableEditor);
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

  // Extracted widget builders live in `part` files, but we still want the
  // panel state itself to stay the single owner of draft mutations. This tiny
  // bridge lets those local builders trigger state updates without adding a
  // new controller layer or changing the encounter pipeline contract.
  void _runLocalStateMutation(VoidCallback mutation) {
    setState(mutation);
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
}
