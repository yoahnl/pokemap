import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../narrative/application/narrative_workspace_controller.dart';
import '../domain/cinematic_port.dart';
import 'cinematic_edit_session.dart';
import 'cinematic_map_model.dart';
import 'cinematic_preview_transport.dart';

export 'cinematic_edit_session.dart';
export 'cinematic_preview_transport.dart';
part 'cinematic_workspace_publication.dart';
part 'cinematic_workspace_actions.dart';
part 'cinematic_workspace_animation.dart';
part 'cinematic_workspace_spatial.dart';
part 'cinematic_workspace_timeline.dart';

class CinematicWorkspaceController {
  CinematicWorkspaceController(
    this.narrative,
    this.port, {
    required this.changed,
    this.sceneDrafts,
  }) {
    narrative.cinematicAccessProblem = accessProblem;
    narrative.cinematicsPublished = invalidateSources;
    narrative.workspace.addListener(reconcileCatalog);
  }
  final NarrativeWorkspaceController narrative;
  final CinematicPort port;
  final void Function() changed;
  final List<SceneAsset> Function()? sceneDrafts;
  final transport = CinematicPreviewTransport();
  final _sessions = <String, CinematicWorkingSession>{};
  final _publishing = <String>{}, _deleting = <String>{};
  int _generation = 0, sourceReads = 0, planBuilds = 0;
  bool _disposed = false, _loading = false;
  String? activeId, error;
  void Function(String id)? onPublished;
  bool Function()? flushEdits;
  bool get _closed => _disposed || narrative.workspace.isDisposed;
  bool get busy => _loading || _publishing.isNotEmpty;
  ProjectManifest get project => narrative.project;
  List<CinematicAsset> get entries => <String, CinematicAsset>{
    for (final c in project.cinematics) c.id: c,
    for (final s in _sessions.values) s.asset.id: s.asset,
  }.values.toList();
  CinematicWorkingSession? get _active => _sessions[activeId];
  CinematicEditSession? get active => _active?.snapshot;
  CinematicEditSession? session(String id) => _sessions[id]?.snapshot;
  bool get dirty => _sessions.values.any((s) => s.dirty);
  bool get canUndo => _active?.undo.isNotEmpty ?? false;
  bool get canRedo => _active?.redo.isNotEmpty ?? false;
  String? accessProblem(String id) =>
      _sessions[id]?.dirty == true || _publishing.contains(id)
      ? 'Cette cinématique possède un brouillon complet. Enregistrez-le ou rechargez-le explicitement.'
      : null;
  bool _fail(Object failure) {
    error = failure.toString();
    changed();
    return false;
  }

  ProjectManifest _with(CinematicAsset asset) => project.copyWith(
    cinematics: [
      for (final c in project.cinematics)
        if (c.id != asset.id) c,
      asset,
    ],
  );
  Future<bool> open(String id) async {
    if (_closed) return false;
    final ticket = ++_generation;
    final sameDocument = activeId == id && _sessions.containsKey(id);
    activeId = id;
    _loading = false;
    if (sameDocument) {
      transport.pause();
    } else {
      transport.clear();
    }
    error = null;
    final problem = narrative.cinematicInteractionAccessProblem(id);
    if (problem != null) return _fail(problem);
    if (_sessions.containsKey(id)) {
      changed();
      return true;
    }
    _loading = true;
    changed();
    try {
      sourceReads++;
      final value = await port.load(id);
      if (_closed || ticket != _generation) return false;
      _sessions[id] = CinematicWorkingSession(value.asset, value);
      return true;
    } catch (failure) {
      if (!_closed && ticket == _generation) error = failure.toString();
      return false;
    } finally {
      if (!_closed && ticket == _generation) {
        _loading = false;
        changed();
      }
    }
  }

  bool edit(CinematicAsset Function(CinematicAsset) transform) {
    final s = _active;
    if (_closed || s == null) return false;
    final problem =
        s.readOnlyReason ??
        (_deleting.contains(s.asset.id) ? 'Suppression en cours.' : null) ??
        narrative.cinematicInteractionAccessProblem(s.asset.id);
    if (problem != null) return _fail(problem);
    try {
      final next = transform(s.asset);
      if (next.id != s.asset.id) {
        return _fail('L’identité du document ne peut pas changer.');
      }
      if (next != s.asset) {
        s.change(next);
        transport.clear();
      }
      error = null;
      changed();
      return true;
    } catch (failure) {
      return _fail(failure);
    }
  }

  void undo() => _restore(false);
  void redo() => _restore(true);
  void _restore(bool forward) {
    final s = _active;
    if (_closed || s == null || _deleting.contains(s.asset.id)) return;
    final problem = narrative.cinematicInteractionAccessProblem(s.asset.id);
    if (problem != null) {
      _fail(problem);
      return;
    }
    s.restore(forward);
    transport.clear();
    error = null;
    changed();
  }

  CinematicMapModel? previewModel;
  MapData? _previewMap;
  String? previewMapId, previewMapProblem;
  int _mapGeneration = 0;
  Object? _mediaIdentity;

  void prepareMapPreview({
    required Future<MapData> Function(String mapId) load,
    CinematicMediaPlaybackPort Function(ProjectManifest)? media,
  }) {
    final asset = _active?.asset;
    if (_closed || asset == null) return;
    if (previewMapId != asset.mapId) {
      previewMapId = asset.mapId;
      _previewMap = null;
      previewModel = null;
      previewMapProblem = null;
      final generation = ++_mapGeneration, id = asset.mapId;
      if (id != null) {
        unawaited(
          load(id)
              .then((map) {
                if (_closed ||
                    generation != _mapGeneration ||
                    previewMapId != id) {
                  return;
                }
                _previewMap = map;
                changed();
              })
              .catchError((Object failure) {
                if (_closed || generation != _mapGeneration) return;
                previewMapProblem = failure.toString();
                changed();
              }),
        );
      }
    }
    final open = narrative.workspace.documents[asset.mapId]?.current;
    if (open != null) _previewMap = open;
    final map = _previewMap;
    if (map != null &&
        (previewModel?.asset != asset ||
            previewModel?.project != project ||
            previewModel?.map != map)) {
      previewModel = CinematicMapModel(asset, project, map);
    }
    prepareMapPlan(media: media);
  }

  void prepareMapPlan({
    CinematicMediaPlaybackPort Function(ProjectManifest)? media,
  }) {
    if (_closed) return;
    final identity = (activeId, project);
    if (media != null && _mediaIdentity != identity) {
      _mediaIdentity = identity;
      transport.configureMedia(media(project));
    }
    final current = previewModel;
    preparePreview(
      actorDisplay: current?.actors,
      resolvedTargets: current?.targets ?? const {},
      stageBounds: current?.bounds,
    );
  }

  void retryMapPreview() {
    previewMapId = null;
    _mapGeneration++;
  }

  void suspendMapPreview() {
    _mapGeneration++;
    previewMapId = null;
    _previewMap = null;
    previewModel = null;
    previewMapProblem = null;
    _mediaIdentity = null;
    transport.pause();
  }

  void preparePreview({
    CinematicActorDisplayPreviewModel? actorDisplay,
    Map<String, CinematicPreviewPlaybackPoint> resolvedTargets = const {},
    CinematicPreviewPlaybackStageBounds? stageBounds,
  }) {
    final asset = _active?.asset;
    if (asset == null || _closed) return;
    final dependencies = (asset, actorDisplay, stageBounds, project);
    if (_previewDependencies == dependencies &&
        (_previewTargets.length == resolvedTargets.length &&
            _previewTargets.entries.every(
              (e) => resolvedTargets[e.key] == e.value,
            )) &&
        transport.plan != null) {
      return;
    }
    _previewTargets = Map.of(resolvedTargets);
    _previewDependencies = dependencies;
    planBuilds++;
    final timeMs = transport.timeMs;
    transport.install(
      buildCinematicPreviewPlaybackPlan(
        cinematic: asset,
        actorDisplayPreviewModel: actorDisplay,
        resolvedMovementTargets: resolvedTargets,
        stageBounds: stageBounds,
        dialogues: project.dialogues,
        mediaAssets: project.cinematicMediaAssets,
        availableMapIds: project.maps.map((m) => m.id),
      ),
    );
    if (timeMs > 0) transport.seek(timeMs);
  }

  Object? _previewDependencies;
  Map<String, CinematicPreviewPlaybackPoint> _previewTargets = {};
  CinematicTimelineClipboard? _clipboard;
  CinematicAsset? _clipboardSource;
  void invalidateSources(Set<String> ids) {
    for (final id in ids) {
      if (_sessions[id]?.dirty == false && !_publishing.contains(id)) {
        _sessions.remove(id);
      }
    }
    if (ids.contains(activeId)) transport.clear();
    changed();
  }

  void reconcileCatalog() {
    if (_closed) return;
    final removed = _sessions.entries
        .where(
          (e) =>
              !e.value.dirty &&
              !_publishing.contains(e.key) &&
              e.value.base?.asset !=
                  project.cinematics.where((a) => a.id == e.key).firstOrNull,
        )
        .map((e) => e.key)
        .toSet();
    if (removed.isNotEmpty) invalidateSources(removed);
  }

  void dispose() {
    _disposed = true;
    _mapGeneration++;
    _generation++;
    narrative.workspace.removeListener(reconcileCatalog);
    narrative.cinematicAccessProblem = null;
    narrative.cinematicsPublished = null;
    transport.dispose();
  }
}
