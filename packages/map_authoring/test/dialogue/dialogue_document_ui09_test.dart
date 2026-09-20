import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:test/test.dart';

void main() {
  const entry = ProjectDialogueEntry(
      id: 'conversation',
      name: 'Conversation',
      relativePath: 'dialogues/test.yarn',
      declaredOutcomes: [
        DialogueDeclaredOutcome(id: 'depart', label: 'Partir')
      ]);
  test(
      'strict compiler rejects outcome outside choice instead of claiming ignored success',
      () {
    const source = 'title: Start\n---\nBonjour\n<<outcome depart>>\n===\n';
    final result =
        const DialogueAuthoringCompiler().compile(entry: entry, source: source);
    expect(result.canPublish, false);
    expect(result.diagnostics.map((d) => d.code),
        contains('dialogue.outcome_outside_choice'));
    expect(emitDocumentToYarn(parseYarnToDocument(source)), source);
  });
  test(
      'same shared codec preserves headers source literals ordered answers and public IDs',
      () {
    const source =
        'title: Start\ntags: public accueil\n---\nBonjour\n-> Partir\n  <<outcome depart>>\n  <<jump Suite>>\n-> Attendre\n  <<jump Suite>>\n===\ntitle: Suite\n---\nÀ bientôt\n===\n';
    final doc = parseYarnToDocument(source);
    expect(emitDocumentToYarn(doc), source);
    final clone = cloneDialogueDocument(doc);
    final choices = clone.nodes.first.steps.whereType<DeChoiceStep>().single;
    final answer = choices.branches.removeAt(0);
    choices.branches.add(answer);
    answer.label = 'Oui';
    final emitted = emitDocumentToYarn(clone);
    expect(emitted, contains('tags: public accueil'));
    expect(
        doc.nodes.first.steps
            .whereType<DeChoiceStep>()
            .single
            .branches
            .first
            .label,
        'Partir');
    final result = const DialogueAuthoringCompiler()
        .compile(entry: entry, source: emitted);
    expect(result.canPublish, true);
    expect(result.emittedOutcomes, ['depart']);
  });
  test(
      'snapshot mutation rejected and reconciliation stable independently of parsing randomness',
      () {
    const source = 'title: Start\n---\nBonjour\n===\n';
    final a = reconcileDialogueDocumentIds(parseYarnToDocument(source));
    final b = reconcileDialogueDocumentIds(parseYarnToDocument(source));
    expect(a.nodes.single.id, b.nodes.single.id);
    expect(a.nodes.single.steps.last.id, b.nodes.single.steps.last.id);
    final frozen = snapshotDialogueDocument(a);
    expect(
        () => frozen.nodes.single.title = 'corruption', throwsUnsupportedError);
    expect(() => frozen.nodes.clear(), throwsUnsupportedError);
  });
}
