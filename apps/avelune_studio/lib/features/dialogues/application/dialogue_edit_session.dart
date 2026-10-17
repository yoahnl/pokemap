import 'dart:convert';

import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import '../domain/dialogue_port.dart';

class DialogueEditSession {
  DialogueEditSession({
    required this.entry,
    required DialogueEditorDocument document,
    required this.source,
    required this.revision,
    required this.dirty,
    required this.canUndo,
    required this.canRedo,
    this.readOnlyReason,
    this.error,
    this.sourceRevision,
    this.startNode,
  }) : document = snapshotDialogueDocument(document);
  final ProjectDialogueEntry entry;
  final DialogueEditorDocument document;
  final String source;
  final int revision;
  final bool dirty, canUndo, canRedo;
  final String? readOnlyReason, error, sourceRevision, startNode;
}

class DialogueWorkingState {
  DialogueWorkingState(this.entry, this.document);
  final ProjectDialogueEntry entry;
  final DialogueEditorDocument document;
  String get source => emitDocumentToYarn(document);
  DialogueWorkingState clone() =>
      DialogueWorkingState(entry, cloneDialogueDocument(document));
}

class DialogueWorkingSession {
  DialogueWorkingSession(this.current, this.base, {this.readOnlyReason})
    : saved = current;
  DialogueWorkingState current, saved;
  DialogueSourceSnapshot? base;
  String? readOnlyReason, startNode, error;
  int revision = 0;
  final undo = <DialogueWorkingState>[];
  final redo = <DialogueWorkingState>[];
  DialogueEditSession? _snapshot;
  List<DialogueLineTextEdit>? get lineTextEdits {
    if (base == null ||
        _textEditShape(saved.document) != _textEditShape(current.document) ||
        saved.entry.defaultStartNode != current.entry.defaultStartNode ||
        jsonEncode(
              saved.entry.declaredOutcomes.map((o) => o.toJson()).toList(),
            ) !=
            jsonEncode(
              current.entry.declaredOutcomes.map((o) => o.toJson()).toList(),
            )) {
      return null;
    }
    const compiler = DialogueAuthoringCompiler();
    final before = compiler.compile(entry: saved.entry, source: saved.source);
    final after = compiler.compile(
      entry: current.entry,
      source: current.source,
    );
    if (!before.canPublish || !after.canPublish) return null;
    final oldLines = sceneDialogueLineScopes(before.document!);
    final newLines = sceneDialogueLineScopes(after.document!);
    if (oldLines.length != newLines.length) return null;
    final edits = <DialogueLineTextEdit>[];
    for (var i = 0; i < oldLines.length; i++) {
      final old = oldLines[i], updated = newLines[i];
      if (old.nodeName != updated.nodeName ||
          old.lineIndex != updated.lineIndex) {
        return null;
      }
      if (old.text != updated.text) {
        edits.add(
          DialogueLineTextEdit(
            nodeName: old.nodeName,
            lineIndex: old.lineIndex,
            beforeText: old.text,
            afterText: updated.text,
          ),
        );
      }
    }
    return edits.isEmpty ? null : List.unmodifiable(edits);
  }

  bool get dirty =>
      base == null ||
      current.entry != saved.entry ||
      current.source != saved.source ||
      _shape(current.document) != _shape(saved.document);
  DialogueEditSession get snapshot => _snapshot ??= DialogueEditSession(
    entry: current.entry,
    document: current.document,
    source: current.source,
    revision: revision,
    dirty: dirty,
    canUndo: undo.isNotEmpty,
    canRedo: redo.isNotEmpty,
    readOnlyReason: readOnlyReason,
    error: error,
    sourceRevision: base?.revision,
    startNode: startNode,
  );
  void invalidate() {
    _snapshot = null;
  }

  void change(DialogueWorkingState next) {
    if (next.entry == current.entry &&
        next.source == current.source &&
        _shape(next.document) == _shape(current.document)) {
      return;
    }
    undo.add(current.clone());
    redo.clear();
    current = next.clone();
    revision++;
    invalidate();
  }

  void restore(bool forward) {
    final list = forward ? redo : undo;
    if (list.isEmpty) return;
    (forward ? undo : redo).add(current.clone());
    current = list.removeLast().clone();
    revision++;
    invalidate();
  }
}

String _textEditShape(DialogueEditorDocument document) {
  Object shape(DialogueEditorStep step) => [
    step.id,
    switch (step) {
      DeStartStep() => ['start'],
      DeEndStep() => ['end'],
      DeLineStep() => [
        'line',
        step.speaker,
        step.characterId,
        step.portraitStateId,
      ],
      DeNarrationStep() => ['narration'],
      DeJumpStep() => ['jump', step.targetTitle],
      DeCommandStep() => ['command', step.raw],
      DeConditionStep() => ['condition', step.raw],
      DeChoiceStep() => [
        'choice',
        [
          for (final branch in step.branches)
            [
              branch.id,
              branch.label,
              branch.outcomeId,
              branch.steps.map(shape).toList(),
            ],
        ],
      ],
    },
  ];
  return jsonEncode([
    document.entryNodeId,
    for (final node in document.nodes)
      [
        node.id,
        node.title,
        [
          for (final header in node.headers) [header.name, header.value],
        ],
        node.steps.map(shape).toList(),
      ],
  ]);
}

String _shape(DialogueEditorDocument doc) {
  String steps(Iterable<DialogueEditorStep> list) => list
      .map(
        (s) =>
            '${s.id}:${s.runtimeType}:${s is DeChoiceStep ? s.branches.map((b) => '${b.id}:${steps(b.steps)}').join(';') : ''}',
      )
      .join('|');
  return '${doc.entryNodeId}:${doc.nodes.map((n) => '${n.id}:${steps(n.steps)}').join('/')}';
}
