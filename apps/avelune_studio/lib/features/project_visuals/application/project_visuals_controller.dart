import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/project_visuals_port.dart';

typedef SpatialVisualScope = bool Function(SpatialVisualParameter parameter);

bool _everyVisualParameter(SpatialVisualParameter _) => true;

bool _sameVisualValue(Object? a, Object? b) =>
    a is List && b is List ? listEquals(a, b) : a == b;

Set<SpatialVisualParameter> _changedVisualParameters(
  SpatialVisualPatch before,
  SpatialVisualPatch after,
) => {
  for (final parameter in SpatialVisualParameter.values)
    if (!_sameVisualValue(before.value(parameter), after.value(parameter)))
      parameter,
};

SpatialVisualPatch _takeVisualParameters(
  SpatialVisualPatch target,
  SpatialVisualPatch source,
  Iterable<SpatialVisualParameter> parameters,
) {
  final values = {...target.values};
  for (final parameter in parameters) {
    final value = source.value(parameter);
    if (value == null) {
      values.remove(parameter);
    } else {
      values[parameter] = value;
    }
  }
  return SpatialVisualPatch(values);
}

final class _VisualStep {
  _VisualStep(this.before, this.after)
    : changed = _changedVisualParameters(before, after);
  final SpatialVisualPatch before, after;
  final Set<SpatialVisualParameter> changed;
  bool within(SpatialVisualScope scope) => changed.every(scope);
  bool touches(SpatialVisualScope scope) => changed.any(scope);
}

final class ProjectVisualsController extends ChangeNotifier {
  ProjectVisualsController({required this.session, required this.port});
  final ProjectSession session;
  final ProjectVisualsPort port;
  final preview = ValueNotifier(SpatialVisualPatch());
  ProjectVisualsState? saved;
  ProjectMapEntry? scope;
  bool loading = false, saving = false;
  String? error;
  int? lastSaveMicroseconds;
  final invalidInputs = <SpatialVisualParameter, String>{};
  final _undo = <_VisualStep>[];
  final _redo = <_VisualStep>[];
  int _generation = 0;
  bool _disposed = false;
  bool _externalConflict = false;
  SpatialVisualPatch? _gestureStart;
  void beginGesture() {
    _gestureStart ??= preview.value;
  }

  void endGesture() {
    final start = _gestureStart;
    _gestureStart = null;
    if (start != null && start != preview.value) {
      _record(_VisualStep(start, preview.value));
      notifyListeners();
    }
  }

  void _record(_VisualStep step) {
    _undo.add(step);
    if (_undo.length > 100) _undo.removeAt(0);
  }

  bool get dirty => saved != null && saved!.profile != preview.value;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool dirtyWhere(SpatialVisualScope scope) {
    final base = saved?.profile;
    return base != null &&
        _changedVisualParameters(base, preview.value).any(scope);
  }

  bool invalidWhere(SpatialVisualScope scope) =>
      invalidInputs.keys.any(scope);

  void reportInvalid(SpatialVisualParameter parameter, String text) {
    if (_disposed || invalidInputs[parameter] == text) return;
    invalidInputs[parameter] = text;
    notifyListeners();
  }

  void clearInvalid(SpatialVisualParameter parameter) {
    if (_disposed || invalidInputs.remove(parameter) == null) return;
    notifyListeners();
  }

  bool canUndoWhere(SpatialVisualScope scope) =>
      _undo.any((step) => step.within(scope));
  bool canRedoWhere(SpatialVisualScope scope) =>
      _redo.any((step) => step.within(scope));

  void rejectExternalChange() {
    if (_disposed) return;
    _externalConflict = true;
    error = 'Une modification externe concerne ces réglages visuels. Votre brouillon et son historique sont conservés. Rechargez ces réglages avant de publier.';
    notifyListeners();
  }

  bool acceptExternalState(ProjectVisualsState state) {
    if (_disposed || loading || saved == null) return false;
    if (state.revision == saved!.revision) return true;
    if (dirty || saving || canUndo || canRedo || _gestureStart != null) {
      rejectExternalChange();
      return false;
    }
    saved = state;
    preview.value = state.profile;
    _externalConflict = false;
    error = null;
    notifyListeners();
    return true;
  }

  Future<void> open({ProjectMapEntry? map}) async {
    final generation = ++_generation;
    _gestureStart = null;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final value = await port.loadVisuals(session, map: map);
      if (_disposed || generation != _generation) return;
      scope = map;
      saved = value;
      _externalConflict = false;
      preview.value = value.profile;
      _undo.clear();
      _redo.clear();
    } on Object catch (failure) {
      if (!_disposed && generation == _generation) error = '$failure';
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void edit(SpatialVisualPatch profile) {
    if (loading || saving || saved == null || profile == preview.value) return;
    if (_gestureStart == null) _record(_VisualStep(preview.value, profile));
    _redo.clear();
    preview.value = profile;
    error = null;
    notifyListeners();
  }

  void undo() => undoWhere(_everyVisualParameter);

  void redo() => redoWhere(_everyVisualParameter);

  void undoWhere(SpatialVisualScope scope) {
    if (saving) return;
    final index = _undo.lastIndexWhere((step) => step.within(scope));
    if (index < 0) return;
    final step = _undo.removeAt(index);
    _redo.add(step);
    preview.value = _takeVisualParameters(
      preview.value,
      step.before,
      step.changed,
    );
    notifyListeners();
  }

  void redoWhere(SpatialVisualScope scope) {
    if (saving) return;
    final index = _redo.lastIndexWhere((step) => step.within(scope));
    if (index < 0) return;
    final step = _redo.removeAt(index);
    _record(step);
    preview.value = _takeVisualParameters(
      preview.value,
      step.after,
      step.changed,
    );
    notifyListeners();
  }

  void discard() => discardWhere(_everyVisualParameter);

  void discardWhere(SpatialVisualScope scope) {
    if (saved == null || saving) return;
    preview.value = _takeVisualParameters(
      preview.value,
      saved!.profile,
      SpatialVisualParameter.values.where(scope),
    );
    _undo.removeWhere((step) => step.touches(scope));
    _redo.removeWhere((step) => step.touches(scope));
    invalidInputs.removeWhere((parameter, _) => scope(parameter));
    error = null;
    notifyListeners();
  }

  Future<bool> save() => saveWhere(_everyVisualParameter);

  Future<bool> saveWhere(SpatialVisualScope owned) async {
    if (saved == null || saving || loading) return false;
    if (invalidWhere(owned)) {
      error = 'Corrigez les valeurs invalides avant d’enregistrer : '
          'rien n’a été publié.';
      notifyListeners();
      return false;
    }
    if (!dirtyWhere(owned)) return true;
    if (_externalConflict) {
      rejectExternalChange();
      return false;
    }
    saving = true;
    error = null;
    notifyListeners();
    final watch = Stopwatch()..start();
    try {
      final draft = preview.value;
      final ownedParameters = SpatialVisualParameter.values.where(owned);
      final target = _takeVisualParameters(
        saved!.profile,
        draft,
        ownedParameters,
      );
      final value = await port.saveVisuals(
        session,
        target,
        saved!.revision,
        map: scope,
      );
      if (_disposed) return false;
      saved = value;
      preview.value = _takeVisualParameters(
        value.profile,
        draft,
        SpatialVisualParameter.values.where((parameter) => !owned(parameter)),
      );
      lastSaveMicroseconds = watch.elapsedMicroseconds;
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
    _generation++;
    preview.dispose();
    super.dispose();
  }
}
