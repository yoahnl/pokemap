import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/project_surf_port.dart';

final class ProjectSurfController extends ChangeNotifier {
  ProjectSurfController({
    required this.session,
    required this.port,
    required this.dimension,
    this.onSaved,
    this.onRevisionChanged,
  }) : preview = ValueNotifier(
         ProjectSurfSettings(enabled: dimension == ProjectDimension.twoD),
       );

  final ProjectSession session;
  final ProjectSurfPort port;
  final ProjectDimension dimension;
  final ValueChanged<ProjectSurfSettings?>? onSaved;
  final void Function(String before, String after)? onRevisionChanged;
  final ValueNotifier<ProjectSurfSettings> preview;
  ProjectSurfState? saved;
  ProjectSurfReferences? references;
  bool loading = false, saving = false, loadingReferences = false;
  String? error,
      referencesError,
      inputError,
      conditionInput,
      conditionSourceDraft;
  int draftRevision = 0;
  String? speedInput, speedInputError;
  int? lastSaveMicroseconds;
  final _undo = <ProjectSurfSettings>[];
  final _redo = <ProjectSurfSettings>[];
  bool _disposed = false;

  ProjectSurfSettings get _base =>
      saved?.configuration ??
      ProjectSurfSettings(enabled: dimension == ProjectDimension.twoD);
  bool get dirty =>
      saved != null &&
      (preview.value != _base || inputError != null || speedInputError != null);
  bool get canUndo =>
      _undo.isNotEmpty || inputError != null || speedInputError != null;
  bool get canRedo => _redo.isNotEmpty;

  Future<void> open() async {
    if (saved != null || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final state = await port.loadSurf(session);
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

  void editSpeed(String raw) {
    if (saved == null || loading || saving) return;
    speedInput = raw;
    final value = double.tryParse(raw.trim());
    if (value == null || !value.isFinite || value <= 0) {
      speedInputError = 'Saisissez une vitesse supérieure à zéro.';
      notifyListeners();
      return;
    }
    speedInputError = null;
    final before = preview.value;
    change(speedCellsPerSecond: value);
    if (before == preview.value) notifyListeners();
  }

  void selectConditionSource(String source) {
    conditionSourceDraft = source;
    rejectInput('Choisissez une référence pour cette condition.');
  }

  void rejectInput(String message, {String? value}) {
    draftRevision++;
    inputError = message;
    conditionInput = value;
    notifyListeners();
  }

  void acceptInput() {
    if (inputError == null && conditionSourceDraft == null) return;
    draftRevision++;
    conditionSourceDraft = null;
    inputError = null;
    conditionInput = null;
    notifyListeners();
  }

  void edit(ProjectSurfSettings configuration) {
    if (saved == null || loading || saving || configuration == preview.value) {
      return;
    }
    _undo.add(preview.value);
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
    draftRevision++;
    preview.value = configuration;
    error = null;
    notifyListeners();
  }

  void change({
    bool? enabled,
    bool? requiresKnownMove,
    ProjectSurfAccessMode? accessMode,
    ScriptCondition? condition,
    double? speedCellsPerSecond,
  }) {
    final clearInput =
        condition != null ||
        (accessMode != null && accessMode != ProjectSurfAccessMode.condition);
    final hadInput = inputError != null || conditionSourceDraft != null;
    if (clearInput) {
      draftRevision++;
      inputError = null;
      conditionInput = null;
      conditionSourceDraft = null;
    }
    final current = preview.value;
    edit(
      ProjectSurfSettings(
        enabled: enabled ?? current.enabled,
        requiresKnownMove: requiresKnownMove ?? current.requiresKnownMove,
        accessMode: accessMode ?? current.accessMode,
        condition: condition ?? current.condition,
        speedCellsPerSecond: speedCellsPerSecond ?? current.speedCellsPerSecond,
      ),
    );
    if (clearInput && hadInput && current == preview.value) notifyListeners();
  }

  void undo() {
    if (!canUndo || saving) return;
    if (speedInputError != null) {
      speedInput = null;
      speedInputError = null;
      notifyListeners();
      return;
    }
    speedInput = null;
    if (inputError != null) {
      acceptInput();
      return;
    }
    draftRevision++;
    inputError = null;
    conditionInput = null;
    _redo.add(preview.value);
    preview.value = _undo.removeLast();
    error = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo || saving) return;
    speedInput = null;
    speedInputError = null;
    draftRevision++;
    inputError = null;
    conditionInput = null;
    _undo.add(preview.value);
    preview.value = _redo.removeLast();
    error = null;
    notifyListeners();
  }

  void discard() {
    if (saving) return;
    speedInput = null;
    speedInputError = null;
    draftRevision++;
    conditionSourceDraft = null;
    preview.value = _base;
    inputError = null;
    conditionInput = null;
    _undo.clear();
    _redo.clear();
    error = null;
    notifyListeners();
  }

  Future<void> loadReferences() async {
    if (references != null || loadingReferences) return;
    loadingReferences = true;
    referencesError = null;
    notifyListeners();
    try {
      final value = await port.loadSurfReferences(session);
      if (!_disposed) references = value;
    } on Object catch (failure) {
      if (!_disposed) referencesError = '$failure';
    } finally {
      if (!_disposed) {
        loadingReferences = false;
        notifyListeners();
      }
    }
  }

  void adoptRevision(String before, String after) {
    final current = saved;
    if (current != null && current.revision == before) {
      saved = ProjectSurfState(configuration: current.configuration, revision: after);
    }
  }

  Future<bool> save() async {
    if (saving || loading || inputError != null || speedInputError != null) {
      return false;
    }
    if (!dirty) return true;
    saving = true;
    error = null;
    notifyListeners();
    final watch = Stopwatch()..start();
    try {
      final configuration = preview.value.validated();
      final before = saved!.revision;
      final value = await port.saveSurf(
        session,
        configuration,
        saved!.revision,
      );
      if (_disposed) return false;
      saved = value;
      speedInput = null;
      preview.value = _base;
      lastSaveMicroseconds = watch.elapsedMicroseconds;
      onRevisionChanged?.call(before, value.revision);
      onSaved?.call(value.configuration);
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
