import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_editing.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/project_audio/domain/project_audio_port.dart';
import 'package:avelune_studio/features/project_visuals/application/map_effect_editing.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';

const mapBuilderAmbianceRubrics = {'dayNight', 'weather', 'effects', 'music'};

const mapBuilderDefaultMusicVolume = .8;

enum MapMusicSlot { exploration, battle }

enum _AmbianceSide { visuals, atmosphere, map }

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
  MapMusicSlot musicSlot = MapMusicSlot.exploration;
  String audioQuery = '';
  List<ProjectAudioEntry> audio = const [];
  bool audioLoading = false, audioLoaded = false;
  String? audioError;
  String? _audioCursor;
  var _audioGeneration = 0;

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

  bool get canUndo =>
      _canUndo(_AmbianceSide.visuals) ||
      _canUndo(_AmbianceSide.atmosphere) ||
      (_trail?.done.any((step) => _matches(step, undo: true)) ?? false);

  bool get canRedo =>
      _trail?.undone.any((step) => _matches(step, undo: false)) ?? false;

  void undo() {
    final trail = _trail;
    while (trail != null && trail.done.isNotEmpty) {
      final step = trail.done.removeLast();
      if (!_matches(step, undo: true)) continue;
      _apply(step.side, undo: true);
      trail.undone.add(_reissue(step, undo: true));
      return;
    }
    for (final side in const [
      _AmbianceSide.visuals,
      _AmbianceSide.atmosphere,
    ].where(_canUndo)) {
      _apply(side, undo: true);
      trail?.undone.add(_AmbianceStep(side));
      return;
    }
  }

  void redo() {
    final trail = _trail;
    while (trail != null && trail.undone.isNotEmpty) {
      final step = trail.undone.removeLast();
      if (!_matches(step, undo: false)) continue;
      _apply(step.side, undo: false);
      trail.done.add(_reissue(step, undo: false));
      return;
    }
  }

  MapMetadata? get metadata => maps.active?.current.mapMetadata;

  void selectMusicSlot(MapMusicSlot slot) {
    musicSlot = slot;
    changed();
  }

  void chooseMusic(String? path) => _editMetadata(
    (metadata) => musicSlot == MapMusicSlot.battle
        ? metadata.copyWith(battleMusicPath: path)
        : metadata.copyWith(
            musicPath: path,
            musicVolume: path == null ? null : metadata.musicVolume,
          ),
  );

  void setMusicVolume(double value) => _editMetadata(
    (metadata) =>
        metadata.copyWith(musicVolume: (value.clamp(0, 1) * 100).round() / 100),
  );

  Future<void> searchAudio(String query) {
    audioQuery = query;
    return loadAudio();
  }

  bool get audioMore => _audioCursor != null;

  static bool _shipped(String? path) =>
      path != null && const {'assets', 'data'}.contains(path.split('/').first);

  Future<void> loadAudio({bool more = false}) async {
    final port = maps.port;
    if (port is! ProjectAudioPort) return;
    final generation = ++_audioGeneration;
    audioLoading = true;
    audioError = null;
    changed();
    try {
      final page = await (port as ProjectAudioPort).queryLegacyAudio(
        maps.session,
        query: audioQuery,
        cursor: more ? _audioCursor : null,
      );
      if (generation != _audioGeneration) return;
      audio = [
        if (more) ...audio,
        ...page.entries.where((entry) => _shipped(entry.path)),
      ];
      _audioCursor = page.nextCursor;
      audioLoaded = true;
    } on Object catch (failure) {
      if (generation != _audioGeneration) return;
      audioError = '$failure';
    } finally {
      if (generation == _audioGeneration) {
        audioLoading = false;
        changed();
      }
    }
  }

  void _editMetadata(MapMetadata Function(MapMetadata metadata) change) {
    final document = maps.active;
    if (document == null || document.saving) return;
    final before = document.current;
    final next = before.copyWith(mapMetadata: change(before.mapMetadata));
    if (next == before) return;
    document.commit(next);
    if (document.current == before) return;
    _record(_AmbianceSide.map, token: document.undoToken);
    maps.notify();
    changed();
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
    if (id == 'music' && !audioLoaded && !audioLoading) {
      unawaited(loadAudio());
    }
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
    final document = maps.active;
    return document == null ? null : _trails[document] ??= _AmbianceTrail();
  }

  void _record(_AmbianceSide side, {Object? token}) {
    final trail = _trail;
    if (trail == null) return;
    trail.done.add(_AmbianceStep(side, token));
    trail.undone.clear();
  }

  bool _canUndo(_AmbianceSide side) => switch (side) {
    _AmbianceSide.visuals => _visuals?.canUndo ?? false,
    _AmbianceSide.atmosphere => _atmosphere?.canUndo ?? false,
    _AmbianceSide.map => maps.active?.canUndo ?? false,
  };

  bool _canRedo(_AmbianceSide side) => switch (side) {
    _AmbianceSide.visuals => _visuals?.canRedo ?? false,
    _AmbianceSide.atmosphere => _atmosphere?.canRedo ?? false,
    _AmbianceSide.map => maps.active?.canRedo ?? false,
  };

  bool _matches(_AmbianceStep step, {required bool undo}) {
    if (!(undo ? _canUndo(step.side) : _canRedo(step.side))) return false;
    if (step.side != _AmbianceSide.map) return true;
    final document = maps.active!;
    return identical(
      undo ? document.undoToken : document.redoToken,
      step.token,
    );
  }

  _AmbianceStep _reissue(_AmbianceStep step, {required bool undo}) =>
      step.side == _AmbianceSide.map
      ? _AmbianceStep(
          step.side,
          undo ? maps.active?.redoToken : maps.active?.undoToken,
        )
      : step;

  void _apply(_AmbianceSide side, {required bool undo}) =>
      switch ((side, undo)) {
        (_AmbianceSide.visuals, true) => _visuals?.undo(),
        (_AmbianceSide.visuals, false) => _visuals?.redo(),
        (_AmbianceSide.atmosphere, true) => _atmosphere?.undo(),
        (_AmbianceSide.atmosphere, false) => _atmosphere?.redo(),
        (_AmbianceSide.map, final undo) => _restoreMap(undo: undo),
      };

  void _restoreMap({required bool undo}) {
    maps.restore(redo: !undo);
    changed();
  }
}

final class _AmbianceStep {
  const _AmbianceStep(this.side, [this.token]);
  final _AmbianceSide side;
  final Object? token;
}

final class _AmbianceTrail {
  final done = <_AmbianceStep>[];
  final undone = <_AmbianceStep>[];
}
