import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/project_cs_port.dart';

final class ProjectCsController extends ChangeNotifier {
  ProjectCsController({
    required this.session,
    required this.port,
    this.onSaved,
    this.onRevisionChanged,
  });
  final ProjectSession session;
  final ProjectCsPort port;
  final ValueChanged<ProjectFieldAbilitiesSettings?>? onSaved;
  final void Function(String before, String after)? onRevisionChanged;
  final preview = ValueNotifier(const ProjectFieldAbilitiesSettings.empty());
  ProjectCsState? saved;
  bool loading = false, saving = false;
  String? error;
  final _undo = <ProjectFieldAbilitiesSettings>[];
  final _redo = <ProjectFieldAbilitiesSettings>[];
  bool _disposed = false;
  ProjectFieldAbilitiesSettings get _base =>
      saved?.configuration ?? const ProjectFieldAbilitiesSettings.empty();
  bool get dirty => saved != null && preview.value != _base;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  Future<void> open() async {
    if (saved != null || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final state = await port.loadFieldAbilities(session);
      if (_disposed) return;
      saved = state;
      preview.value = _base;
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void setEnabled(FieldAbility ability, bool enabled) =>
      setEnabledId(ability.moveId, enabled);

  void setEnabledId(String abilityId, bool enabled) {
    if (abilityId == FieldAbility.surf.moveId ||
        saved == null ||
        loading ||
        saving) {
      return;
    }
    if (!ProjectFieldAbilityRegistry.entries.any(
      (entry) => entry.id == abilityId,
    )) {
      throw ArgumentError.value(
        abilityId,
        'abilityId',
        'Unknown project field ability',
      );
    }
    final disabled = {...preview.value.disabledAbilityIds};
    if (enabled) {
      disabled.remove(abilityId);
    } else {
      disabled.add(abilityId);
    }
    final configuration = ProjectFieldAbilitiesSettings.fromIds(disabled);
    if (configuration == preview.value) return;
    _undo.add(preview.value);
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
    preview.value = configuration;
    error = null;
    notifyListeners();
  }

  void undo() {
    if (!canUndo || saving) return;
    _redo.add(preview.value);
    preview.value = _undo.removeLast();
    error = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo || saving) return;
    _undo.add(preview.value);
    if (_undo.length > 100) _undo.removeAt(0);
    preview.value = _redo.removeLast();
    error = null;
    notifyListeners();
  }

  void discard() {
    if (saving) return;
    preview.value = _base;
    _undo.clear();
    _redo.clear();
    error = null;
    notifyListeners();
  }

  void adoptRevision(String before, String after) {
    final current = saved;
    if (current != null && current.revision == before) {
      saved = ProjectCsState(
        configuration: current.configuration,
        revision: after,
      );
    }
  }

  Future<bool> save() async {
    if (loading || saving) return false;
    if (!dirty) return true;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final draft = preview.value;
      for (final ability in ProjectFieldAbilityRegistry.entries.where(
        (entry) => entry.id != 'surf',
      )) {
        if (draft.disabledAbilityIds.contains(ability.id) ==
            _base.disabledAbilityIds.contains(ability.id)) {
          continue;
        }
        final before = saved!.revision;
        final state = await port.saveFieldAbilityId(
          session,
          ability.id,
          !draft.disabledAbilityIds.contains(ability.id),
          before,
        );
        if (_disposed) return false;
        saved = state;
        onRevisionChanged?.call(before, state.revision);
        onSaved?.call(state.configuration);
      }
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
      return false;
    } finally {
      if (!_disposed) {
        saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    preview.dispose();
    super.dispose();
  }
}
