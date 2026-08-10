import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../app/providers/core/repository_providers.dart';
import '../../app/providers/pokedex/pokedex_providers.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_species_lookup_service.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'encounter_probability_projection.dart';

// Keep the encounters panel in one Dart library so the corrective pass can
// split the noise into neighboring `part` files without changing visibility,
// notifier contracts, or the existing encounter authoring pipeline.
part 'encounter_tables_panel_support.dart';
part 'encounter_tables_panel_workspace.dart';

const PokemonSpeciesLookupService _encounterSpeciesLookupService =
    PokemonSpeciesLookupService();

const encounterWorkspaceLibraryKey = ValueKey<String>(
  'encounter-workspace-library',
);
const encounterWorkspaceTableKey = ValueKey<String>(
  'encounter-workspace-table',
);
const encounterWorkspaceInspectorKey = ValueKey<String>(
  'encounter-workspace-inspector',
);

class EncounterTablesPanel extends ConsumerStatefulWidget {
  const EncounterTablesPanel({super.key, this.selectedTableId});

  final String? selectedTableId;

  @override
  ConsumerState<EncounterTablesPanel> createState() =>
      _EncounterTablesPanelState();
}

class _EncounterTablesPanelState extends ConsumerState<EncounterTablesPanel> {
  // -------------------------------------------------------------------------
  // Create table draft
  // -------------------------------------------------------------------------

  final _newTableNameController = TextEditingController();
  final _newTableChancePercentController = TextEditingController(text: '12');
  final _newTableRequiredFlagsController = TextEditingController();
  final _newTableTagsController = TextEditingController();
  EncounterKind _newTableKind = EncounterKind.walk;
  bool _showCreateForm = false;
  String? _createTableValidationMessage;
  final _tableSearchController = TextEditingController();
  String _tableSearchQuery = '';
  _EncounterWorkspacePane _compactWorkspacePane = _EncounterWorkspacePane.table;

  // -------------------------------------------------------------------------
  // Edit table draft
  // -------------------------------------------------------------------------

  String? _editingTableId;
  String? _pendingSelectedTableId;
  final _editTableNameController = TextEditingController();
  final _editTableChancePercentController = TextEditingController();
  final _editTableRequiredFlagsController = TextEditingController();
  final _editTableTagsController = TextEditingController();
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
  bool _entryDeleteFailed = false;

  // -------------------------------------------------------------------------
  // Local Pokédex references used only for encounter authoring assistance
  // -------------------------------------------------------------------------

  String? _referenceProjectRootPath;
  Future<_EncounterReferenceData>? _referenceDataFuture;

  @override
  void initState() {
    super.initState();
    _pendingSelectedTableId = widget.selectedTableId;
  }

  @override
  void didUpdateWidget(covariant EncounterTablesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTableId != oldWidget.selectedTableId) {
      _pendingSelectedTableId = widget.selectedTableId;
    }
  }

  @override
  void dispose() {
    _newTableNameController.dispose();
    _newTableChancePercentController.dispose();
    _newTableRequiredFlagsController.dispose();
    _newTableTagsController.dispose();
    _tableSearchController.dispose();
    _editTableNameController.dispose();
    _editTableChancePercentController.dispose();
    _editTableRequiredFlagsController.dispose();
    _editTableTagsController.dispose();
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

    final tables = project?.encounterTables ?? const <ProjectEncounterTable>[];

    return Material(
      type: MaterialType.transparency,
      child: project == null
          ? const PokeMapEmptyState(
              title: 'Aucun projet ouvert',
              description:
                  'Ouvrez un projet pour créer et configurer ses rencontres.',
              icon: Icon(Icons.folder_open_rounded),
            )
          : FutureBuilder<_EncounterReferenceData>(
              future: _referenceDataFuture,
              initialData: const _EncounterReferenceData.loading(),
              builder: (context, snapshot) {
                final references =
                    snapshot.data ?? const _EncounterReferenceData.loading();
                return _buildEncounterWorkspace(
                  context: context,
                  state: state,
                  notifier: notifier,
                  tables: tables,
                  references: references,
                );
              },
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
        _validateEncounterTableName(_newTableNameController.text) ??
        _validateEncounterChancePercent(_newTableChancePercentController.text);
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
      chancePerStep: _parseEncounterChancePercent(
        _newTableChancePercentController.text,
      ),
      conditions: _buildAuthoredEncounterConditions(
        existing: const <ScriptCondition>[],
        requiredFlagsText: _newTableRequiredFlagsController.text,
        encounterKind: _newTableKind,
      ),
      tags: _parseEncounterTags(_newTableTagsController.text),
    );
    if (!mounted) {
      return;
    }

    final afterState = ref.read(editorNotifierProvider);
    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: afterState,
    );
    if (success) {
      final previousIds =
          beforeState.project?.encounterTables
              .map((table) => table.id)
              .toSet() ??
          const <String>{};
      ProjectEncounterTable? createdTable;
      for (final table
          in afterState.project?.encounterTables ??
              const <ProjectEncounterTable>[]) {
        if (!previousIds.contains(table.id)) {
          createdTable = table;
          break;
        }
      }
      setState(() {
        _resetCreateTableDraft();
        if (createdTable != null) {
          _prepareTableDraft(createdTable);
        }
      });
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
    ProjectEncounterTable table,
  ) async {
    final inlineValidation =
        _validateEncounterTableName(_editTableNameController.text) ??
        _validateEncounterChancePercent(_editTableChancePercentController.text);
    setState(() {
      _editTableValidationMessage = inlineValidation;
    });
    if (inlineValidation != null) {
      return;
    }

    final beforeState = ref.read(editorNotifierProvider);
    await notifier.updateEncounterTable(
      tableId: table.id,
      name: _editTableNameController.text,
      encounterKind: _editTableKind,
      chancePerStep: _parseEncounterChancePercent(
        _editTableChancePercentController.text,
      ),
      conditions: _buildAuthoredEncounterConditions(
        existing: table.conditions,
        requiredFlagsText: _editTableRequiredFlagsController.text,
        encounterKind: _editTableKind,
      ),
      tags: _parseEncounterTags(_editTableTagsController.text),
    );
    if (!mounted) {
      return;
    }

    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (success) {
      final updatedTables =
          ref.read(editorNotifierProvider).project?.encounterTables ??
          const <ProjectEncounterTable>[];
      ProjectEncounterTable? updatedTable;
      for (final candidate in updatedTables) {
        if (candidate.id == table.id) {
          updatedTable = candidate;
          break;
        }
      }
      setState(() {
        if (updatedTable != null) {
          _prepareTableDraft(updatedTable);
        } else {
          _editingTableId = table.id;
          _editTableValidationMessage = null;
        }
      });
      return;
    }

    setState(() {
      _editTableValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
          'Failed to update encounter table.';
    });
  }

  Future<void> _deleteTable(EditorNotifier notifier, String tableId) async {
    final beforeState = ref.read(editorNotifierProvider);
    await notifier.deleteEncounterTable(tableId);
    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      setState(() {
        _editTableValidationMessage =
            ref.read(editorNotifierProvider).errorMessage ??
            'Failed to delete encounter table.';
      });
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
      _entryDeleteFailed = false;
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
      _entryValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
          'Failed to save encounter entry.';
    });
  }

  Future<void> _deleteEntry(
    EditorNotifier notifier,
    String tableId,
    int index,
  ) async {
    final beforeState = ref.read(editorNotifierProvider);
    await notifier.deleteEncounterEntry(tableId: tableId, entryIndex: index);
    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      setState(() {
        _entryValidationMessage =
            ref.read(editorNotifierProvider).errorMessage ??
            'Failed to delete encounter entry.';
        _entryDeleteFailed = true;
      });
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
    _newTableChancePercentController.text = '12';
    _newTableRequiredFlagsController.clear();
    _newTableTagsController.clear();
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
    _entryDeleteFailed = false;
    _entrySpeciesController.clear();
    _entryMinLevelController.text = '1';
    _entryMaxLevelController.text = '5';
    _entryWeightController.text = '1';
  }
}
