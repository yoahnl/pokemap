import 'package:map_core/map_core_domain.dart';

import '../domain/pokemon_workspace_models.dart';
import '../domain/pokemon_workspace_port.dart';
import '../domain/pokemon_import_models.dart';
import '../domain/pokemon_moves_sync_models.dart';
import '../domain/pokemon_external_import_models.dart';
import 'pokemon_commerce_controller.dart';
import 'pokemon_combat_controller.dart';

part 'pokemon_learnset_commands.dart';
part 'pokemon_moves_sync_commands.dart';
part 'pokemon_import_commands.dart';
part 'pokemon_external_commands.dart';
part 'pokemon_workspace_owner_commands.dart';

final class PokemonWorkspaceController {
  PokemonWorkspaceController(
    this.port, {
    required this.changed,
    this.commerce,
    this.combat,
  });

  final PokemonWorkspacePort port;
  final void Function() changed;
  final PokemonCommerceController? commerce;
  final PokemonCombatController? combat;
  final _drafts = <String, PokemonSpeciesDraft>{};
  PokemonWorkspaceIndex? index;
  PokemonWorkspaceView view = PokemonWorkspaceView.pokedex;
  PokemonDetailSection section = PokemonDetailSection.overview;
  String search = '';
  String moveSearch = '';
  String? editingLanguage;
  String? typeFilter;
  int? generationFilter;
  bool? enabledFilter;
  String? selectedId;
  String? selectedMoveId;
  String? lastSavedSpeciesId;
  String? moveInsertGroup;
  int? moveReplaceIndex;
  String? error;
  String? notice;
  bool loading = false;
  bool saving = false;
  bool importing = false;
  bool syncing = false;
  PokemonMovesSyncPreview? movesPreview;
  PokemonExternalSearch? externalSearch;
  PokemonExternalImportPreview? externalPreview;
  PokemonExternalImportResult? externalResult;
  bool externalBusy = false;
  bool committing = false;
  PokemonLocalImportPreview? importPreview;
  int _request = 0;
  bool _disposed = false;

  bool get operationActive =>
      saving ||
      importing ||
      syncing ||
      externalBusy ||
      commerce?.saving == true ||
      commerce?.importing == true ||
      combat?.operationActive == true;
  bool get mutationActive =>
      saving ||
      committing ||
      commerce?.saving == true ||
      commerce?.importing == true ||
      combat?.saving == true;
  bool get hasPendingChanges =>
      _drafts.values.any((draft) => draft.dirty) ||
      commerce?.dirty == true ||
      combat?.dirty == true;
  PokemonSpeciesDraft? get selectedDraft => _drafts[selectedId];

  List<PokemonSpeciesSummary> get visibleSpecies {
    final needle = search.trim().toLowerCase();
    return [
      for (final entry in index?.entries ?? const <PokemonSpeciesSummary>[])
        if ((needle.isEmpty ||
                entry.name.toLowerCase().contains(needle) ||
                entry.id.toLowerCase().contains(needle)) &&
            (typeFilter == null || entry.types.contains(typeFilter)) &&
            (generationFilter == null ||
                entry.generation == generationFilter) &&
            (enabledFilter == null || entry.enabled == enabledFilter))
          entry,
    ];
  }

  List<PokemonMoveSummary> get visibleMoves {
    final needle = moveSearch.trim().toLowerCase();
    return [
      for (final entry in index?.moves.entries ?? const <PokemonMoveSummary>[])
        if (needle.isEmpty ||
            entry.id.toLowerCase().contains(needle) ||
            entry.name.toLowerCase().contains(needle))
          entry,
    ];
  }

  Future<void> load({bool refresh = false}) async {
    if (index != null && !refresh) return;
    final request = ++_request;
    loading = true;
    error = null;
    _notify();
    try {
      final loaded = await port.loadIndex();
      if (!_current(request)) return;
      index = loaded;
    } on Object catch (failure) {
      if (_current(request)) error = 'Lecture du Pokédex impossible : $failure';
    } finally {
      if (_current(request)) {
        loading = false;
        _notify();
      }
    }
  }

  Future<bool> selectSpecies(String id) async {
    if (selectedId == id && _drafts.containsKey(id)) return true;
    if (selectedDraft?.dirty == true || saving) return false;
    final entry = index?.entries.where((item) => item.id == id).firstOrNull;
    if (entry == null) return false;
    final previousId = selectedId;
    selectedId = id;
    lastSavedSpeciesId = null;
    section = PokemonDetailSection.overview;
    error = null;
    if (_drafts.containsKey(id)) {
      _releaseInactiveDrafts(previousId);
      _notify();
      return true;
    }
    final request = ++_request;
    loading = true;
    _notify();
    try {
      final bundle = await port.loadSpecies(entry);
      if (!_current(request) || selectedId != id) return false;
      _drafts[id] = PokemonSpeciesDraft(bundle);
      _releaseInactiveDrafts(previousId);
      return true;
    } on Object catch (failure) {
      if (_current(request)) error = 'Fiche $id indisponible : $failure';
      return false;
    } finally {
      if (_current(request)) {
        loading = false;
        _notify();
      }
    }
  }

  void _releaseInactiveDrafts(String? previousId) {
    _drafts.removeWhere((id, draft) {
      if (id == selectedId) return false;
      if (draft.dirty) {
        draft.clearHistory();
        return false;
      }
      return id != previousId;
    });
  }

  bool setView(PokemonWorkspaceView value) {
    if (mutationActive || (value != view && hasPendingChanges)) return false;
    if (value == PokemonWorkspaceView.pokedex) {
      moveInsertGroup = null;
      moveReplaceIndex = null;
    }
    view = value;
    _notify();
    if (value == PokemonWorkspaceView.items ||
        value == PokemonWorkspaceView.shops) {
      final owner = commerce;
      if (owner != null) owner.load();
    }
    if (value == PokemonWorkspaceView.combats) combat?.load();
    return true;
  }

  void setSection(PokemonDetailSection value) {
    section = value;
    _notify();
  }

  void setSearch(String value) {
    search = value;
    _notify();
  }

  void setMoveSearch(String value) {
    moveSearch = value;
    _notify();
  }

  void setEditingLanguage(String value) {
    editingLanguage = value;
    _notify();
  }

  void setFilters({String? type, int? generation, bool? enabled}) {
    typeFilter = type;
    generationFilter = generation;
    enabledFilter = enabled;
    _notify();
  }

  void selectMove(String id) {
    selectedMoveId = id;
    _notify();
  }

  void edit(
    PokemonDocumentFamily family,
    void Function(Map<String, dynamic>) change, {
    Map<String, dynamic>? initial,
  }) {
    final draft = selectedDraft;
    if (draft == null || mutationActive) return;
    lastSavedSpeciesId = null;
    draft.edit(family, change, initial: initial);
    _notify();
  }

  void undo() {
    if (mutationActive) return;
    lastSavedSpeciesId = null;
    selectedDraft?.undo();
    _notify();
  }

  void redo() {
    if (mutationActive) return;
    lastSavedSpeciesId = null;
    selectedDraft?.redo();
    _notify();
  }

  void discardSelectedSpecies() {
    final id = selectedId;
    if (mutationActive) return;
    lastSavedSpeciesId = null;
    final draft = id == null ? null : _drafts[id];
    if (draft != null && id != null) {
      _drafts[id] = PokemonSpeciesDraft(draft.base);
    }
    _notify();
  }

  bool _current(int request) => !_disposed && request == _request;

  void _notify() {
    if (!_disposed) changed();
  }

  void dispose() {
    _disposed = true;
    _request++;
    commerce?.dispose();
    combat?.dispose();
  }
}
