import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../narrative/application/narrative_workspace_controller.dart';
import '../domain/cinematic_port.dart';
import 'cinematic_edit_session.dart';
import 'cinematic_input_state.dart';
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
  String? activeId;
  String? _error;
  int _errorRevision = 0;
  CinematicInputState? _errorInputs;
  String? get error => _error;
  set error(String? value) {
    _error = value;
    _errorRevision++;
    final inputs = _inputs[activeId];
    _errorInputs = value != null && inputs?.validating == true ? inputs : null;
  }

  void Function(String id)? onPublished;
  final _inputs = <String, CinematicInputState>{};
  (String, int)? _inputDiscardFailure;
  Object? _inputHost;
  bool Function()? _flushFocus;
  bool Function()? get flushEdits => _flushInputs;
  set flushEdits(bool Function()? value) {
    _inputHost = null;
    _flushFocus = value;
  }

  CinematicInputState inputsFor(String id, {CinematicInputState? initial}) =>
      _inputs.putIfAbsent(id, () => initial ?? CinematicInputState());

  Iterable<CinematicInputDiscard> get pendingInputDiscards {
    if (_closed || busy) return const [];
    return List<CinematicInputDiscard>.unmodifiable([
      for (final id in _inputs.keys) ?prepareInputDiscard(id),
    ]);
  }

  CinematicInputDiscard? prepareInputDiscard(String cinematicId) {
    if (_closed || busy) return null;
    final session = _sessions[cinematicId];
    final inputs = _inputs[cinematicId];
    if (session == null || inputs == null || !inputs.dirty) return null;
    return CinematicInputDiscard._(
      owner: this,
      cinematicId: cinematicId,
      title: session.asset.title,
      session: session,
      asset: session.asset,
      sessionRevision: session.revision,
      inputs: inputs,
      inputRevision: inputs.revision,
    );
  }

  bool discardInputs(
    CinematicInputDiscard preparation, {
    required bool confirmed,
  }) {
    if (!confirmed || _closed || busy) return false;
    final session = _sessions[preparation.cinematicId];
    final inputs = _inputs[preparation.cinematicId];
    if (!identical(preparation._owner, this) ||
        !identical(session, preparation._session) ||
        !identical(session?.asset, preparation._asset) ||
        session?.revision != preparation._sessionRevision ||
        !identical(inputs, preparation._inputs) ||
        inputs?.revision != preparation._inputRevision ||
        inputs?.dirty != true) {
      const message =
          'Cette cinématique ou ses saisies ont changé. '
          'Vérifiez-les avant de confirmer leur abandon.';
      if (error != null &&
          _errorInputs == null &&
          _inputDiscardFailure?.$2 != _errorRevision) {
        changed();
        return false;
      }
      error = message;
      _inputDiscardFailure = (preparation.cinematicId, _errorRevision);
      changed();
      return false;
    }
    inputs!.discard(preserveDiagnostics: true);
    final discardFailure = _inputDiscardFailure;
    if (identical(_errorInputs, inputs) ||
        (discardFailure?.$1 == preparation.cinematicId &&
            _errorRevision == discardFailure?.$2)) {
      error = null;
    }
    if (discardFailure?.$1 == preparation.cinematicId) {
      _inputDiscardFailure = null;
    }
    changed();
    return true;
  }

  bool _flushInputs() =>
      _flushFocus?.call() != false &&
      _inputs.values.every((input) => input.valid);

  void attachInputHost(Object owner, bool Function() flushFocus) {
    if (_closed) return;
    if (_inputHost != null && !identical(_inputHost, owner)) {
      suspendMapPreview();
    }
    _inputHost = owner;
    _flushFocus = flushFocus;
  }

  void detachInputHost(Object owner) {
    if (!identical(_inputHost, owner)) return;
    _inputHost = null;
    _flushFocus = null;
    suspendMapPreview();
  }

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
  bool get dirty =>
      _sessions.values.any((s) => s.dirty) ||
      _inputs.values.any((input) => input.dirty);
  bool Function() captureDraftGuard() {
    final sessions = {
      for (final entry in _sessions.entries)
        entry.key: (entry.value, entry.value.revision),
    };
    final inputs = {
      for (final entry in _inputs.entries)
        entry.key: (entry.value, entry.value.revision),
    };
    return () {
      if (_closed ||
          busy ||
          sessions.length != _sessions.length ||
          inputs.length != _inputs.length) {
        return false;
      }
      for (final entry in sessions.entries) {
        final current = _sessions[entry.key];
        if (!identical(current, entry.value.$1) ||
            current?.revision != entry.value.$2) {
          return false;
        }
      }
      for (final entry in inputs.entries) {
        final current = _inputs[entry.key];
        if (!identical(current, entry.value.$1) ||
            current?.revision != entry.value.$2) {
          return false;
        }
      }
      return true;
    };
  }

  bool get canUndo => _active?.undo.isNotEmpty ?? false;
  bool get canRedo => _active?.redo.isNotEmpty ?? false;
  String? accessProblem(String id) =>
      _sessions[id]?.dirty == true ||
          _inputs[id]?.dirty == true ||
          _publishing.contains(id)
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
      if (_sessions[id]?.dirty == false &&
          _inputs[id]?.dirty != true &&
          !_publishing.contains(id)) {
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
              _inputs[e.key]?.dirty != true &&
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
    _inputHost = null;
    _flushFocus = null;
    _mapGeneration++;
    _generation++;
    narrative.workspace.removeListener(reconcileCatalog);
    narrative.cinematicAccessProblem = null;
    narrative.cinematicsPublished = null;
    transport.dispose();
  }
}

class CinematicInputDiscard {
  CinematicInputDiscard._({
    required this._owner,
    required this.cinematicId,
    required this.title,
    required this._session,
    required this._asset,
    required this._sessionRevision,
    required this._inputs,
    required this._inputRevision,
  });

  final String cinematicId, title;
  final CinematicWorkspaceController _owner;
  final CinematicWorkingSession _session;
  final CinematicAsset _asset;
  final int _sessionRevision, _inputRevision;
  final CinematicInputState _inputs;
}
