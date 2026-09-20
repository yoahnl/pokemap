import 'package:map_core/map_core_domain.dart';
import '../../map_workspace/application/map_workspace_controller.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../domain/event_port.dart';
import '../domain/event_record_view.dart';

part 'event_workspace_commands.dart';
part 'event_workspace_catalog.dart';
part 'event_workspace_publication.dart';
part 'event_publication_order.dart';

class EventWorkspaceController {
  EventWorkspaceController(
    this.narrative,
    this.port, {
    required this.changed,
    this.sceneDrafts,
  }) {
    narrative.eventAccessProblem = accessProblem;
    workspace.addListener(reconcile);
  }
  final NarrativeWorkspaceController narrative;
  final EventPort port;
  final void Function() changed;
  final List<SceneAsset> Function()? sceneDrafts;
  Future<void> Function()? flushEdits;
  final _pending = <String, NarrativeEventRecord?>{};
  final _bases = <String, NarrativeEventRecord?>{};
  final _undo =
      <
        ({String id, NarrativeEventRecord? before, NarrativeEventRecord? after})
      >[];
  final _redo =
      <
        ({String id, NarrativeEventRecord? before, NarrativeEventRecord? after})
      >[];
  final _maps = <String, MapData>{};
  final _publishing = <String>{};
  Future<bool>? _preparing;
  ProjectManifest? _preparedManifest;
  List<Object?> _catalogSignature = [];
  NarrativeEventAuthoringContext? _cachedContext;
  bool _disposed = false;
  bool busy = false;
  String? error;
  String? activeId;
  MapWorkspaceController get workspace => narrative.workspace;
  bool get _closed => _disposed || workspace.isDisposed;
  bool get dirty => _pending.isNotEmpty;
  bool isDirty(String id) => _pending.containsKey(id);
  Set<String> get dirtyIds => _pending.keys.toSet();
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  NarrativeEventRecord? record(String id) =>
      _pending.containsKey(id) ? _pending[id] : _stored(id);
  NarrativeEventRecord? get active =>
      activeId == null ? null : record(activeId!);
  NarrativeEventRecord? _stored(String id) => narrative
      .project
      .eventRegistry
      ?.records
      .where((r) => r.id == id)
      .firstOrNull;
  List<NarrativeEventRecord> get records => <String, NarrativeEventRecord?>{
    for (final r
        in narrative.project.eventRegistry?.records ?? <NarrativeEventRecord>[])
      r.id: r,
    ..._pending,
  }.values.whereType<NarrativeEventRecord>().toList();
  ProjectManifest get project {
    final base = narrative.project;
    final registry = base.eventRegistry;
    return base.copyWith(
      facts: narrative.facts,
      storylines: narrative.stories,
      scenes: sceneDrafts?.call() ?? base.scenes,
      eventRegistry: registry == null && _pending.isEmpty
          ? null
          : NarrativeEventRegistry(
              schemaVersion: registry?.schemaVersion ?? 1,
              mode: registry?.mode ?? EventSystemMode.legacyOnly,
              records: records,
              legacyClaims: registry?.legacyClaims ?? const [],
            ),
    );
  }

  String? accessProblem(String id) => _publishing.contains(id) || isDirty(id)
      ? 'Cet événement possède un brouillon dans Événements. Enregistrez-le ou abandonnez ses modifications avant de l’éditer ici.'
      : null;

  bool open(String id) {
    if (_closed) return false;
    reconcile();
    if (record(id) == null) {
      return _fail('Cet événement ne figure plus dans le projet.');
    }
    activeId = id;
    _bases.putIfAbsent(id, () => _stored(id));
    changed();
    return true;
  }

  bool _fail(String message) {
    error = message;
    changed();
    return false;
  }

  bool _apply(
    NarrativeEventAuthoringResult result, {
    NarrativeEventRecord? original,
  }) {
    if (result.status == NarrativeEventAuthoringStatus.noOp) return true;
    if (result.status != NarrativeEventAuthoringStatus.applied) {
      return _fail(result.humanReason ?? 'Cette modification est refusée.');
    }
    final id = result.eventId!;
    final candidate = original ?? result.previousRecord;
    final before = candidate?.id == id ? candidate : null;
    if (record(id) != before) {
      return _fail('Le brouillon a changé pendant cette modification.');
    }
    _bases.putIfAbsent(id, () => _stored(id));
    _undo.add((id: id, before: before, after: result.nextRecord));
    if (_undo.length > 80) _undo.removeAt(0);
    _redo.clear();
    _write(id, result.nextRecord);
    return true;
  }

  void _write(String id, NarrativeEventRecord? value) {
    if (value == _stored(id)) {
      _pending.remove(id);
    } else {
      _pending[id] = value;
    }
    error = null;
    changed();
  }

  void restore({required bool redo}) {
    if (_closed || busy) return;
    reconcile();
    final from = redo ? _redo : _undo;
    if (from.isEmpty) return;
    final delta = from.last;
    final problem = narrative.interactionAccessProblem(delta.id);
    if (problem != null) {
      _fail(problem);
      return;
    }
    from.removeLast();
    (redo ? _undo : _redo).add(delta);
    _write(delta.id, redo ? delta.after : delta.before);
  }

  void reconcile() {
    if (_closed || busy) return;
    for (final entry in _bases.entries.toList()) {
      final latest = _stored(entry.key);
      if (latest == entry.value) continue;
      if (isDirty(entry.key)) {
        error ??=
            'Un événement ouvert a changé. Son brouillon est conservé ; rechargez-le pour résoudre le conflit.';
      } else {
        _bases[entry.key] = latest;
        _invalidate(entry.key);
        if (activeId == entry.key && latest == null) activeId = null;
      }
    }
  }

  void _invalidate(String id) {
    _undo.removeWhere((d) => d.id == id);
    _redo.removeWhere((d) => d.id == id);
  }

  bool discard(String id) {
    if (_closed || busy) return false;
    _pending.remove(id);
    _bases[id] = _stored(id);
    _invalidate(id);
    error = null;
    changed();
    return true;
  }

  Future<bool> save() => saveAll();
  Future<bool> saveAll() => _flushAndPublish();
  Future<bool> reload(String id) => _reload(id);
  void dispose() {
    _disposed = true;
    workspace.removeListener(reconcile);
    if (narrative.eventAccessProblem == accessProblem) {
      narrative.eventAccessProblem = null;
    }
  }
}
