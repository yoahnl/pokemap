import 'package:avelune_studio/features/dialogues/application/dialogue_view_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';

void main() {
  DialogueEditorDocument document(List<String> titles) {
    final source = [
      for (final title in titles) 'title: $title\n---\nBonjour\n===\n',
    ].join('\n');
    final parsed = parseYarnToDocument(source, entryNodeTitle: titles.first);
    return DialogueEditorDocument(
      nodes: parsed.nodes,
      entryNodeId: parsed.entryNodeId,
    );
  }

  test('selecting a suite keeps the given step and response and drops the wire', () {
    final state = DialogueViewState()..wireId = 'wire';
    state.select('n1', step: 's1', branch: 'b1');
    expect([state.nodeId, state.stepId, state.branchId, state.wireId], [
      'n1',
      's1',
      'b1',
      null,
    ]);
    state.select('n2');
    expect([state.nodeId, state.stepId, state.branchId, state.wireId], [
      'n2',
      null,
      null,
      null,
    ]);
  });

  test('a still existing suite keeps the whole selection', () {
    final doc = document(['Accueil', 'Depart']);
    final state = DialogueViewState()
      ..select(doc.nodes.last.id, step: 's', branch: 'b')
      ..wireId = 'w';
    state.reconcile(doc);
    expect([state.nodeId, state.stepId, state.branchId, state.wireId], [
      doc.nodes.last.id,
      's',
      'b',
      'w',
    ]);
  });

  test('a vanished suite falls back to the first one and clears the rest', () {
    final doc = document(['Accueil', 'Depart']);
    final state = DialogueViewState()
      ..select('gone', step: 's', branch: 'b')
      ..wireId = 'w';
    state.reconcile(doc);
    expect([state.nodeId, state.stepId, state.branchId, state.wireId], [
      doc.nodes.first.id,
      null,
      null,
      null,
    ]);
  });

  test('an unselected view picks the first suite and a document without suite picks nothing', () {
    final doc = document(['Accueil']);
    final state = DialogueViewState()..reconcile(doc);
    expect(state.nodeId, doc.nodes.first.id);
    final empty = DialogueViewState()
      ..reconcile(DialogueEditorDocument(nodes: [], entryNodeId: ''));
    expect(empty.nodeId, isNull);
  });

  test('deleting clears the deepest selection first: wire, then response, then step', () {
    final state = DialogueViewState()
      ..select('n', step: 's', branch: 'b')
      ..wireId = 'w';
    state.clearDeepestSelection();
    expect([state.wireId, state.branchId, state.stepId], [null, 'b', 's']);
    state.clearDeepestSelection();
    expect([state.wireId, state.branchId, state.stepId], [null, null, 's']);
    state.clearDeepestSelection();
    expect([state.wireId, state.branchId, state.stepId, state.nodeId], [
      null,
      null,
      null,
      'n',
    ]);
    state.clearDeepestSelection();
    expect(state.nodeId, 'n');
  });

  test('a new view opens on the properties tab with the preview open', () {
    final state = DialogueViewState();
    expect(state.tab, 'properties');
    expect(state.previewOpen, isTrue);
  });
}
