import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_editing.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/project_visuals/application/map_effect_editing.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';

const mapBuilderAmbianceRubrics = {'dayNight', 'weather', 'effects'};

enum _AmbianceSide { visuals, atmosphere }

class MapBuilderAmbianceBinding {
  MapBuilderAmbianceBinding({
    required this.maps,
    required this.changed,
    MapEditingViewportSession? Function()? view,
  }) : _view = view ?? (() => null);

  final MapWorkspaceController maps;
  final void Function() changed;
  final MapEditingViewportSession? Function() _view;
  bool shown = false;
  String rubric = 'dayNight';
  MapEffect effect = MapEffect.halos;
  ProjectVisualsController? _visuals;
  MapAtmosphereController? _atmosphere;
  final _trails = Expando<_AmbianceTrail>();

  bool get spatial => maps.active?.current.spatialScene != null;

  ProjectVisualsController? get visuals => _visuals;

  MapAtmosphereController? get atmosphere => _atmosphere;

  SpatialVisualPatch get inherited => maps.inheritedVisualProfile;

  SpatialVisualEditing? get editing {
    final owner = _visuals;
    if (owner == null || owner.saved == null) return null;
    return SpatialVisualEditing(
      patch: owner.preview.value,
      inherited: inherited,
      onChanged: (patch) {
        final before = owner.preview.value;
        owner.edit(patch);
        if (owner.preview.value != before && _gestureStart == null) {
          _record(_AmbianceSide.visuals);
        }
      },
    );
  }

  MapAtmosphereEditing? get sources {
    final owner = _atmosphere;
    final document = maps.active;
    if (owner == null || document == null) return null;
    return MapAtmosphereEditing(owner, document.current, maps.visualProject);
  }

  String? get selectedModel {
    final document = maps.active;
    final scene = document?.current.spatialScene;
    if (document == null || scene == null) return null;
    final id = _view()?.selectedFor(
      document.current.id,
      MapSelectionFamily.decor,
    );
    return scene.instances.any((instance) => instance.id == id) ? id : null;
  }

  void locate(String instanceId) {
    final document = maps.active;
    final view = _view();
    if (document == null || view == null) return;
    view.select(document, MapSelectionFamily.decor, instanceId);
    changed();
  }

  void editSources(void Function(MapAtmosphereEditing sources) change) {
    final editing = sources;
    if (editing == null) return;
    final before = editing.controller.current;
    change(editing);
    if (editing.controller.current != before) {
      _record(_AmbianceSide.atmosphere);
    }
  }

  bool get loading => _visuals != null && _visuals!.saved == null;

  String? get error => _visuals?.error;

  bool get canUndo => _AmbianceSide.values.any(_canUndo);

  bool get canRedo => _trail?.undone.any(_canRedo) ?? false;

  void undo() {
    final trail = _trail;
    while (trail != null && trail.done.isNotEmpty) {
      final side = trail.done.removeLast();
      if (!_canUndo(side)) continue;
      _apply(side, undo: true);
      trail.undone.add(side);
      return;
    }
    for (final side in _AmbianceSide.values.where(_canUndo)) {
      _apply(side, undo: true);
      trail?.undone.add(side);
      return;
    }
  }

  void redo() {
    final trail = _trail;
    while (trail != null && trail.undone.isNotEmpty) {
      final side = trail.undone.removeLast();
      if (!_canRedo(side)) continue;
      _apply(side, undo: false);
      trail.done.add(side);
      return;
    }
  }

  SpatialVisualPatch? _gestureStart;

  void beginGesture() {
    final owner = _visuals;
    if (owner == null) return;
    _gestureStart ??= owner.preview.value;
    owner.beginGesture();
  }

  void endGesture() {
    final owner = _visuals;
    final start = _gestureStart;
    _gestureStart = null;
    if (owner == null) return;
    owner.endGesture();
    if (start != null && start != owner.preview.value) {
      _record(_AmbianceSide.visuals);
    }
  }

  void openRubric(String id) {
    if (!mapBuilderAmbianceRubrics.contains(id)) return;
    rubric = id;
    changed();
  }

  void openEffect(MapEffect value) {
    effect = value;
    changed();
  }

  void reconcile() {
    final document = maps.active;
    final active = shown && document != null && spatial;
    final nextVisuals = active ? maps.weatherDraftFor(document) : null;
    if (!identical(nextVisuals, _visuals)) {
      _visuals?.removeListener(changed);
      _visuals = nextVisuals;
      _visuals?.addListener(changed);
    }
    final nextAtmosphere = active ? document.atmosphere : null;
    if (!identical(nextAtmosphere, _atmosphere)) {
      _atmosphere?.removeListener(changed);
      _atmosphere = nextAtmosphere;
      _atmosphere?.addListener(changed);
    }
  }

  void dispose() {
    _visuals?.removeListener(changed);
    _atmosphere?.removeListener(changed);
    _visuals = null;
    _atmosphere = null;
  }

  _AmbianceTrail? get _trail {
    final Object? owner = _visuals ?? _atmosphere;
    return owner == null ? null : _trails[owner] ??= _AmbianceTrail();
  }

  void _record(_AmbianceSide side) {
    final trail = _trail;
    if (trail == null) return;
    trail.done.add(side);
    trail.undone.clear();
  }

  bool _canUndo(_AmbianceSide side) => switch (side) {
    _AmbianceSide.visuals => _visuals?.canUndo ?? false,
    _AmbianceSide.atmosphere => _atmosphere?.canUndo ?? false,
  };

  bool _canRedo(_AmbianceSide side) => switch (side) {
    _AmbianceSide.visuals => _visuals?.canRedo ?? false,
    _AmbianceSide.atmosphere => _atmosphere?.canRedo ?? false,
  };

  void _apply(_AmbianceSide side, {required bool undo}) =>
      switch ((side, undo)) {
        (_AmbianceSide.visuals, true) => _visuals?.undo(),
        (_AmbianceSide.visuals, false) => _visuals?.redo(),
        (_AmbianceSide.atmosphere, true) => _atmosphere?.undo(),
        (_AmbianceSide.atmosphere, false) => _atmosphere?.redo(),
      };
}

final class _AmbianceTrail {
  final done = <_AmbianceSide>[];
  final undone = <_AmbianceSide>[];
}
