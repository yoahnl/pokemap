import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../domain/dialogue_port.dart';
import 'dialogue_edit_session.dart';
import 'dialogue_preview_state.dart';

export 'dialogue_edit_session.dart';
export 'dialogue_preview_state.dart';
part 'dialogue_workspace_commands.dart';
part 'dialogue_workspace_links.dart';
part 'dialogue_workspace_publication.dart';
part 'dialogue_workspace_validation.dart';
part 'dialogue_workspace_structure.dart';

class DialogueWorkspaceController {
  DialogueWorkspaceController(
    this.narrative,
    this.port, {
    required this.changed,
    this.sceneDrafts,
  }) {
    narrative.dialogueAccessProblem = accessProblem;
    narrative.dialoguesPublished = _invalidateSources;
    narrative.workspace.addListener(_reconcileCatalog);
  }
  final NarrativeWorkspaceController narrative;
  final DialoguePort port;
  final void Function() changed;
  final List<SceneAsset> Function()? sceneDrafts;
  void Function(String id, String revision)? onPublished;
  final _sessions = <String, DialogueWorkingSession>{};
  final _identities = <String, DialogueEditorDocument>{};
  int _generation = 0, sourceReads = 0, compilationCount = 0;
  bool _disposed = false;
  bool _loading = false;
  final _publishing = <String>{};
  final _deleting = <String>{};
  bool get busy => _loading || _publishing.isNotEmpty;
  String? activeId, error;
  DialoguePreviewState? preview;
  bool get _closed => _disposed || narrative.workspace.isDisposed;
  ProjectManifest get project => narrative.project;
  List<ProjectDialogueEntry> get entries => <String, ProjectDialogueEntry>{
    for (final e in project.dialogues) e.id: e,
    for (final s in _sessions.values) s.current.entry.id: s.current.entry,
  }.values.toList();
  DialogueWorkingSession? get _active => _sessions[activeId];
  DialogueEditSession? get active => _active?.snapshot;
  DialogueEditSession? session(String id) => _sessions[id]?.snapshot;
  bool get dirty => _sessions.values.any((s) => s.dirty);
  bool get canUndo => _active?.undo.isNotEmpty ?? false;
  bool get canRedo => _active?.redo.isNotEmpty ?? false;
  String? sourceForDialogue(String id) => _sessions[id]?.current.source;
  String? accessProblem(String id) =>
      _sessions[id]?.dirty == true || _publishing.contains(id)
      ? 'Ce dialogue possède un brouillon dans l’éditeur de dialogue. Enregistrez-le ou rechargez-le explicitement.'
      : null;
  bool _fail(String message) {
    error = message;
    changed();
    return false;
  }

  Future<bool> open(String id, {String? startNode}) async {
    if (_closed) return false;
    final ticket = ++_generation;
    activeId = id;
    _loading = false;
    preview = null;
    error = null;
    final problem = narrative.dialogueInteractionAccessProblem(id);
    if (problem != null) return _fail(problem);
    if (_sessions.containsKey(id)) {
      _sessions[id]!
        ..startNode = startNode
        ..invalidate();
      changed();
      return true;
    }
    _loading = true;
    changed();
    try {
      sourceReads++;
      final value = await port.load(id);
      if (_closed || ticket != _generation) return false;
      final doc = reconcileDialogueDocumentIds(
        parseYarnToDocument(
          value.source,
          entryNodeTitle: value.entry.defaultStartNode,
        ),
        previous: _identities[id],
      );
      final compiled = _compile(value.entry, value.source);
      final canonical = emitDocumentToYarn(
        DialogueEditorDocument(nodes: doc.nodes, entryNodeId: doc.entryNodeId),
      );
      final roundtrip = _compile(value.entry, canonical);
      final reason = !compiled.canPublish
          ? compiled.diagnostics.map((d) => d.message).join('\n')
          : compiled.document != roundtrip.document
          ? 'Cette source ne peut pas être représentée fidèlement. Consultation Yarn conservée.'
          : _opaqueSourceProblem(value.source);
      _sessions[id] = DialogueWorkingSession(
        DialogueWorkingState(value.entry, doc),
        value,
        readOnlyReason: reason,
      )..startNode = startNode;
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

  DialogueAuthoringCompileResult _compile(
    ProjectDialogueEntry entry,
    String source,
  ) {
    compilationCount++;
    return const DialogueAuthoringCompiler().compile(
      entry: entry,
      source: source,
    );
  }

  bool _edit(
    void Function(DialogueWorkingState value) change, {
    ProjectDialogueEntry Function(ProjectDialogueEntry)? metadata,
  }) {
    final s = _active;
    if (_closed || s == null) return false;
    final problem =
        (_deleting.contains(s.current.entry.id)
            ? 'Suppression en cours : ce dialogue est protégé.'
            : null) ??
        s.readOnlyReason ??
        narrative.dialogueInteractionAccessProblem(s.current.entry.id);
    if (problem != null) return _fail(problem);
    try {
      var next = s.current.clone();
      change(next);
      if (metadata != null) {
        next = DialogueWorkingState(metadata(next.entry), next.document);
      }
      s.change(next);
      preview = null;
      error = null;
      changed();
      return true;
    } catch (failure) {
      return _fail(failure.toString());
    }
  }

  bool _replaceDocument(
    DialogueEditorDocument Function(DialogueEditorDocument) transform, {
    ProjectDialogueEntry Function(ProjectDialogueEntry)? metadata,
  }) {
    final s = _active;
    if (_closed || s == null) return false;
    final problem =
        (_deleting.contains(s.current.entry.id)
            ? 'Suppression en cours : ce dialogue est protégé.'
            : null) ??
        s.readOnlyReason ??
        narrative.dialogueInteractionAccessProblem(s.current.entry.id);
    if (problem != null) return _fail(problem);
    try {
      s.change(
        DialogueWorkingState(
          metadata?.call(s.current.entry) ?? s.current.entry,
          transform(s.current.document),
        ),
      );
      preview = null;
      error = null;
      changed();
      return true;
    } catch (failure) {
      return _fail(failure.toString());
    }
  }

  void undo() => _restore(false);
  void redo() => _restore(true);
  void _restore(bool forward) {
    final s = _active;
    if (_closed ||
        s == null ||
        s.readOnlyReason != null ||
        _deleting.contains(s.current.entry.id)) {
      return;
    }
    final problem = narrative.dialogueInteractionAccessProblem(
      s.current.entry.id,
    );
    if (problem != null) {
      _fail(problem);
      return;
    }
    s.restore(forward);
    preview = null;
    error = null;
    changed();
  }

  bool startPreview({String? nodeTitle}) {
    final s = _active;
    if (s == null) return false;
    final start = nodeTitle ?? s.startNode ?? s.current.entry.defaultStartNode;
    final compiled = _compileDocument(s.current, startNode: start);
    preview = DialoguePreviewState(compiled);
    changed();
    return compiled.canPublish;
  }

  void advancePreview() {
    preview?.advance();
    changed();
  }

  void choosePreview(int index) {
    preview?.choose(index);
    changed();
  }

  void _invalidateSources(Set<String> ids) {
    for (final id in ids) {
      final s = _sessions[id];
      if (s != null && !s.dirty && !_publishing.contains(id)) {
        _identities[id] = s.current.document;
        _sessions.remove(id);
      }
    }
    if (ids.contains(activeId)) preview = null;
    changed();
  }

  void dispose() {
    _disposed = true;
    _generation++;
    narrative.dialogueAccessProblem = null;
    narrative.dialoguesPublished = null;
    narrative.workspace.removeListener(_reconcileCatalog);
  }
}
