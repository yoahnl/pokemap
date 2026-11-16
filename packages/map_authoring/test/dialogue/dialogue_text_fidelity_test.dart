import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const source = '// A preserved author note\r\n'
    'title: Start\r\n'
    'tags: greeting   shared\r\n'
    '---\r\n'
    '<<portrait hero happy>>\r\n'
    'Luth: Bonjour {{ fact.name }}  \r\n'
    '(Le vent souffle.)\r\n'
    '-> Oui\r\n'
    '    <<outcome yes>>\r\n'
    '    <<jump End>>\r\n'
    '-> Non\r\n'
    '    <<outcome no>>\r\n'
    '    <<jump End>>\r\n'
    '===\r\n'
    'title: End\r\n'
    '---\r\n'
    'Bonjour {{ fact.name }}\r\n'
    '===\r\n';

void main() {
  for (final body in [
    'Locuteur : texte',
    '(Ceci reste une réplique.)',
    'Étiquette: {{ fact.name }}\n<<jump End>>',
  ]) {
    test('ambiguous line text preserves its kind and source bytes: $body', () {
      final opened = readLocalizedDialogue(source: source, sourceLocale: 'fr');
      final line =
          opened.document.nodes.last.steps.whereType<DeLineStep>().single;
      final previous = opened.localization.translate(line.id, 'en', 'Goodbye.');
      line.body = body;
      final changed =
          writeLocalizedDialogue(opened.document, previous: previous);
      final reopened = readLocalizedDialogue(
        source: changed.source,
        sourceLocale: 'fr',
        localization: changed.localization,
      );
      final read =
          reopened.document.nodes.last.steps.whereType<DeLineStep>().single;
      expect(read.body, body);
      expect(read.speaker, isNull);
      expect(read.id, line.id);
      final compiled = const YarnDialogueCompiler().compile(changed.source);
      expect(
          (compiled.nodes.last.steps.single as RuntimeDialogueLine).text, body);
      expect(reopened.localization.unit(line.id).translations,
          previous.unit(line.id).translations);
      expect(changed.source.split('title: End').first,
          source.split('title: End').first);
      read.body = 'Au revoir.';
      final second = writeLocalizedDialogue(reopened.document,
          previous: reopened.localization);
      expect(
          readLocalizedDialogue(
                  source: second.source,
                  sourceLocale: 'fr',
                  localization: second.localization)
              .localization
              .unit(line.id)
              .source,
          'Au revoir.');
    });
  }

  test('ordinary edits retain the exact historical speaker prefix', () {
    const original = 'title: Start\r\n---\r\nLuth :   Bonjour !  \r\n===\r\n';
    final opened = readLocalizedDialogue(source: original, sourceLocale: 'fr');
    opened.document.nodes.single.steps.whereType<DeLineStep>().single.body =
        '  Bonsoir !';
    final changed =
        writeLocalizedDialogue(opened.document, previous: opened.localization);
    expect(changed.source, original.replaceFirst('Bonjour', 'Bonsoir'));
    final reopened = readLocalizedDialogue(
        source: changed.source,
        sourceLocale: 'fr',
        localization: changed.localization);
    expect(
        reopened.document.nodes.single.steps
            .whereType<DeLineStep>()
            .single
            .speaker,
        'Luth');
  });

  test('an explicit line inside a choice retains portrait and outcome', () {
    const original = 'title: Start\n---\n-> Oui\n  <<outcome yes>>\n'
        '  <<portrait hero happy>>\n  Bonjour\n===\n';
    final opened = readLocalizedDialogue(source: original, sourceLocale: 'fr');
    final branch = opened.document.nodes.single.steps
        .whereType<DeChoiceStep>()
        .single
        .branches
        .single;
    final line = branch.steps.single as DeLineStep;
    line.body = '(Une réplique : sans narrateur.)';
    final changed =
        writeLocalizedDialogue(opened.document, previous: opened.localization);
    final reopened = readLocalizedDialogue(
        source: changed.source,
        sourceLocale: 'fr',
        localization: changed.localization);
    final next = reopened.document.nodes.single.steps
        .whereType<DeChoiceStep>()
        .single
        .branches
        .single;
    expect(next.outcomeId, 'yes');
    final read = next.steps.single as DeLineStep;
    expect(read.body, line.body);
    expect(read.characterId, 'hero');
    expect(read.portraitStateId, 'happy');
    expect(read.speaker, isNull);
  });

  test('structural changes still use the canonical writer', () {
    final document = parseYarnToDocument(source);
    document.nodes.last.steps
        .add(DeLineStep(id: 'new-line', body: 'Une suite.'));
    final emitted = emitDocumentToYarn(document);
    final reopened = parseYarnToDocument(emitted);
    expect(
        reopened.nodes.last.steps
            .whereType<DeLineStep>()
            .map((step) => step.body),
        ['Bonjour {{ fact.name }}', 'Une suite.']);
  });

  test('a localized copy remains editable with new ids and preserved Yarn', () {
    final original = readLocalizedDialogue(source: source, sourceLocale: 'fr');
    final copied = duplicateLocalizedDialogue(original);
    final line =
        copied.document.nodes.last.steps.whereType<DeLineStep>().single;
    line.body = 'Salut {{ fact.name }}';
    final updated =
        writeLocalizedDialogue(copied.document, previous: copied.localization);
    expect(
        updated.source,
        source.replaceFirst('\r\nBonjour {{ fact.name }}\r\n',
            '\r\nSalut {{ fact.name }}\r\n'));
    expect(
        updated.localization.units.map((unit) => unit.id).toSet().intersection(
            original.localization.units.map((unit) => unit.id).toSet()),
        isEmpty);
    readLocalizedDialogue(
        source: updated.source,
        sourceLocale: 'fr',
        localization: updated.localization);
  });

  test('literal narration and choice labels preserve literal encoding', () {
    const original =
        'title: Start\r\n---\r\n\\"(Une\\nnuit)"\r\n-> \\"Oui\\nmerci"\r\n    <<jump Start>>\r\n===\r\n';
    final opened = readLocalizedDialogue(source: original, sourceLocale: 'fr');
    final steps = opened.document.nodes.single.steps;
    steps.whereType<DeNarrationStep>().single.text = 'Deux\nnuits';
    steps.whereType<DeChoiceStep>().single.branches.single.label = 'Non\nmerci';
    final updated =
        writeLocalizedDialogue(opened.document, previous: opened.localization);
    expect(
        updated.source,
        original
            .replaceFirst('Une\\nnuit', 'Deux\\nnuits')
            .replaceFirst('Oui', 'Non'));
    readLocalizedDialogue(
        source: updated.source,
        sourceLocale: 'fr',
        localization: updated.localization);
  });

  test('changing a line preserves every unrelated source byte and text id', () {
    final opened = readLocalizedDialogue(source: source, sourceLocale: 'fr');
    final line =
        opened.document.nodes.last.steps.whereType<DeLineStep>().single;
    final previous = opened.localization.translate(line.id, 'en', 'Hello.');
    line.body = 'Salut {{ fact.name }}';
    final changed = writeLocalizedDialogue(opened.document, previous: previous);
    expect(
        changed.source,
        source.replaceFirst('\r\nBonjour {{ fact.name }}\r\n',
            '\r\nSalut {{ fact.name }}\r\n'));
    expect(changed.localization.units.map((u) => u.id),
        previous.units.map((u) => u.id));
    expect(changed.localization.unit(line.id).translations,
        previous.unit(line.id).translations);
    readLocalizedDialogue(
        source: changed.source,
        sourceLocale: 'fr',
        localization: changed.localization);
  });

  test('choice and narration edits preserve commands and outcome identities',
      () {
    final opened = readLocalizedDialogue(source: source, sourceLocale: 'fr');
    final node = opened.document.nodes.first;
    node.steps.whereType<DeNarrationStep>().single.text = 'Le soleil brille.';
    node.steps.whereType<DeChoiceStep>().single.branches.first.label =
        'Avec plaisir';
    final changed =
        writeLocalizedDialogue(opened.document, previous: opened.localization);
    expect(
        changed.source,
        source
            .replaceFirst('(Le vent souffle.)', '(Le soleil brille.)')
            .replaceFirst('-> Oui', '-> Avec plaisir'));
    expect(changed.document.documentOutcomes().map((o) => o.id), ['yes', 'no']);
    readLocalizedDialogue(
        source: changed.source,
        sourceLocale: 'fr',
        localization: changed.localization);
  });

  test('literal multiline text stays literal without rewriting another node',
      () {
    const original = 'title: Start\r\n---\r\n\\"Hello\\nworld"\r\n===\r\n';
    final opened = readLocalizedDialogue(source: original, sourceLocale: 'en');
    opened.document.nodes.single.steps.whereType<DeLineStep>().single.body =
        'Hi\nworld';
    final changed =
        writeLocalizedDialogue(opened.document, previous: opened.localization);
    expect(changed.source, original.replaceFirst('Hello', 'Hi'));
  });
}
