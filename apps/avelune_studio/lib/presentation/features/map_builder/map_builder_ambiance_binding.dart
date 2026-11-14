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

part 'map_builder_ambiance_history.dart';

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
}
