import 'dart:async';
import 'package:map_core/map_core_domain.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../domain/presentation_port.dart';
import 'presentation_edit_session.dart';

export '../domain/presentation_port.dart';
export 'presentation_edit_session.dart';
part 'presentation_workspace_editing.dart';
part 'presentation_workspace_publication.dart';
part 'presentation_workspace_library.dart';
part 'presentation_workspace_references.dart';

class PresentationWorkspaceController {
  PresentationWorkspaceController(
    this.narrative,
    this.port, {
    required this.changed,
    this.sceneDrafts,
  }) {
    narrative.workspace.addListener(reconcileCatalog);
  }
  final NarrativeWorkspaceController narrative;
  final PresentationPort port;
  final void Function() changed;
  final List<SceneAsset> Function()? sceneDrafts;
  final _sessions = <String, PresentationWorkingSession>{};
  final _publishing = <String>{}, _deleting = <String>{};
  bool _disposed = false, _loading = false;
  int _generation = 0, sourceReads = 0;
  String? activeId, error;
  bool Function()? flushEdits;
  void Function()? suspendPreview;
  void Function(String id)? onPublished;
  void Function(PresentationSceneLink link, SceneAsset published)?
  onScenePublished;
  bool get _closed => _disposed || narrative.workspace.isDisposed;
  bool get busy => _loading || saving;
  bool get saving => _publishing.isNotEmpty;
  bool get dirty => _sessions.values.any((s) => s.dirty);
  ProjectManifest get project => narrative.project;
  CinematicLibraryCatalog get catalog => project.cinematicLibraryCatalog;
  PresentationWorkingSession? get _active => _sessions[activeId];
  PresentationEditSession? get active => _active?.snapshot;
  Iterable<PresentationEditSession> get sessions =>
      _sessions.values.map((s) => s.snapshot);
  PresentationEditSession? session(String id) => _sessions[id]?.snapshot;
  List<PresentationCinematicAsset> get entries =>
      <String, PresentationCinematicAsset>{
        for (final a in project.presentationCinematics) a.id: a,
        for (final s in _sessions.values) s.asset.id: s.asset,
      }.values.toList();
  PresentationCinematicAsset? assetFor(String id) =>
      _sessions[id]?.asset ??
      project.presentationCinematics.where((a) => a.id == id).firstOrNull;
  bool get canUndo => _active?.undo.isNotEmpty ?? false;
  bool get canRedo => _active?.redo.isNotEmpty ?? false;
  String? accessProblem(String id) =>
      _sessions[id]?.dirty == true || _publishing.contains(id)
      ? 'Cette présentation possède un brouillon ouvert.'
      : null;
  bool _fail(Object failure) {
    if (!_closed) {
      error = failure.toString();
      changed();
    }
    return false;
  }

  bool _flush() {
    try {
      return flushEdits?.call() != false;
    } catch (failure) {
      return _fail(failure);
    }
  }

  Future<bool> open(String id) async {
    if (_closed || !_flush()) return false;
    if (activeId != id) suspendPreview?.call();
    final ticket = ++_generation;
    activeId = id;
    error = null;
    _loading = false;
    if (_sessions.containsKey(id)) {
      changed();
      return true;
    }
    _loading = true;
    changed();
    try {
      sourceReads++;
      final source = await port.load(id);
      if (_closed || ticket != _generation) return false;
      _sessions[id] = PresentationWorkingSession(
        source.asset,
        source.projection,
        source,
      );
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

  void reconcileCatalog() {
    if (_closed) return;
    final removed = _sessions.entries
        .where(
          (e) =>
              !e.value.dirty &&
              !_publishing.contains(e.key) &&
              (e.value.base?.asset !=
                      project.presentationCinematics
                          .where((a) => a.id == e.key)
                          .firstOrNull ||
                  e.value.base?.entry !=
                      catalog.entryFor(
                        CinematicLibraryFamily.presentation,
                        e.key,
                      )),
        )
        .map((e) => e.key)
        .toList();
    for (final id in removed) {
      _sessions.remove(id);
    }
    if (removed.isNotEmpty) changed();
  }

  void dispose() {
    suspendPreview?.call();
    suspendPreview = null;
    _disposed = true;
    _generation++;
    narrative.workspace.removeListener(reconcileCatalog);
    for (final s in _sessions.values) {
      for (final media in s.imports) {
        unawaited(port.releaseMedia(media));
      }
    }
  }
}
