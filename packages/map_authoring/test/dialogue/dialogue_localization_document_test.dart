import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:test/test.dart';

const _source =
    'title: Start\ncustom: untouched\n---\nBonjour\n(La nuit tombe)\n'
    '-> Partir\n  <<outcome leave>>\n-> Rester\n  <<outcome stay>>\n===\n';
const _entry = ProjectDialogueEntry(
    id: 'talk',
    name: 'Accueil',
    relativePath: 'dialogues/talk.yarn',
    declaredOutcomes: [
      DialogueDeclaredOutcome(id: 'leave', label: 'Partir'),
      DialogueDeclaredOutcome(id: 'stay', label: 'Rester'),
    ]);

void main() {
  test(
      'an explicit entry node is preserved without rewriting the legacy source',
      () {
    const source =
        'title: First\n---\nBonjour\n===\ntitle: Entry\n---\nBienvenue\n===\n';
    final opened = readLocalizedDialogue(
        source: source, sourceLocale: 'fr', entryNodeTitle: 'Entry');
    expect(
        opened.document.nodeById(opened.document.effectiveEntryNodeId!)!.title,
        'Entry');
    expect(opened.source, source);
    final copied = duplicateLocalizedDialogue(opened);
    expect(
        copied.document.nodeById(copied.document.effectiveEntryNodeId!)!.title,
        'Entry');
  });

  test('renaming and moving a node retain the text identities after reopening',
      () {
    const source =
        'title: Start\n---\nBonjour\n===\ntitle: Other\n---\nEncore\n===\n';
    final opened = readLocalizedDialogue(source: source, sourceLocale: 'fr');
    final ids = opened.localization.units.map((unit) => unit.id).toSet();
    opened.document.nodes.first.title = 'Renamed';
    final moved = opened.document
        .copyWith(nodes: opened.document.nodes.reversed.toList());
    final written =
        writeLocalizedDialogue(moved, previous: opened.localization);
    final reopened = readLocalizedDialogue(
        source: written.source,
        sourceLocale: 'fr',
        localization: written.localization);
    expect(reopened.localization.units.map((unit) => unit.id).toSet(), ids);
    expect(
        reopened.document.nodes.map((node) => node.title), contains('Renamed'));
  });

  test(
      'legacy conversion is deterministic and preserves the original source verbatim',
      () {
    const source =
        '// En-tête conservé\r\ntitle: Start\r\n---\r\nBonjour\r\n===\r\n';
    final first = readLocalizedDialogue(source: source, sourceLocale: 'fr');
    final second = readLocalizedDialogue(source: source, sourceLocale: 'fr');
    expect(first.source, source);
    expect(first.localization.toJson(), second.localization.toJson());
    final reopened = readLocalizedDialogue(
        source: first.source,
        sourceLocale: 'fr',
        localization: first.localization);
    expect(reopened.source, source);
    expect(reopened.localization.toJson(), first.localization.toJson());
  });

  test(
      'editing and reordering lines and choices keep their own persisted identities',
      () {
    final opened = readLocalizedDialogue(source: _source, sourceLocale: 'fr');
    final greeting = opened.localization.units.first;
    final translated =
        opened.localization.translate(greeting.id, 'en', 'Hello');
    final node = opened.document.nodes.single;
    final line = node.steps.whereType<DeLineStep>().single;
    line.body = 'Bienvenue';
    node.steps.remove(line);
    node.steps.add(line);
    final choices = node.steps.whereType<DeChoiceStep>().single;
    final first = choices.branches.removeAt(0);
    choices.branches.add(first);
    final written =
        writeLocalizedDialogue(opened.document, previous: translated);
    final reopened = readLocalizedDialogue(
        source: written.source,
        sourceLocale: 'fr',
        localization: written.localization);
    final current = reopened.localization.unit(greeting.id);
    expect(current.source, 'Bienvenue');
    expect(current.binding, isNot(greeting.binding));
    expect(current.translations['en']!.text, 'Hello');
    expect(
        reopened.document.nodes.single.steps.whereType<DeLineStep>().single.id,
        greeting.id);
    expect(
        reopened.document.nodes.single.steps
            .whereType<DeChoiceStep>()
            .single
            .branches
            .last
            .id,
        first.id);
    expect(reopened.document.documentOutcomes().map((outcome) => outcome.id),
        ['stay', 'leave']);
  });

  test('an independent copy receives new identities and retains variants', () {
    final opened = readLocalizedDialogue(source: _source, sourceLocale: 'fr');
    final translated = opened.localization
        .translate(opened.localization.units.first.id, 'en', 'Hello');
    final original =
        writeLocalizedDialogue(opened.document, previous: translated);
    final copy = duplicateLocalizedDialogue(original);
    final ids = original.localization.units.map((unit) => unit.id).toSet();
    expect(
        copy.localization.units.any((unit) => ids.contains(unit.id)), isFalse);
    expect(copy.localization.units.first.translations['en']!.text, 'Hello');
    copy.document.nodes.single.steps.whereType<DeLineStep>().single.body =
        'Copie';
    expect(
        original.document.nodes.single.steps
            .whereType<DeLineStep>()
            .single
            .body,
        'Bonjour');
    expect(copy.document.documentOutcomes().map((outcome) => outcome.id),
        ['leave', 'stay']);
  });

  test(
      'translation changes displayed choices without changing outcomes or branches',
      () {
    final opened = readLocalizedDialogue(source: _source, sourceLocale: 'fr');
    var catalog = opened.localization;
    for (final unit in catalog.units) {
      catalog = catalog.translate(unit.id, 'en', 'English ${unit.kind.name}');
    }
    final english = resolveLocalizedDialogue(
        writeLocalizedDialogue(opened.document, previous: catalog),
        preferredLocale: 'en-GB',
        supportedLocales: ['fr', 'en'],
        fallbackLocale: 'fr');
    final compiler = const DialogueAuthoringCompiler();
    final original = compiler.compile(entry: _entry, source: opened.source);
    final localized = compiler.compile(entry: _entry, source: english.source);
    expect(original.canPublish, isTrue);
    expect(localized.canPublish, isTrue);
    final simulation = const DialogueSimulationService();
    for (final choice in [0, 1]) {
      final first = simulation.simulate(original, choices: {'Start': choice});
      final second = simulation.simulate(localized, choices: {'Start': choice});
      expect(second.outcomes, first.outcomes);
      expect(second.visitedNodes, first.visitedNodes);
      expect(second.selectedChoices.single, 'English choice');
    }
    expect(opened.source, _source);
  });

  test(
      'stale or incomplete bindings are rejected instead of guessing an identity',
      () {
    final opened = readLocalizedDialogue(source: _source, sourceLocale: 'fr');
    expect(
        () => readLocalizedDialogue(
            source: _source.replaceFirst('Bonjour', 'Salut'),
            sourceLocale: 'fr',
            localization: opened.localization),
        throwsFormatException);
    expect(
        () => readLocalizedDialogue(
            source: _source,
            sourceLocale: 'fr',
            localization: opened.localization
                .withUnits(opened.localization.units.skip(1).toList())),
        throwsFormatException);
    expect(opened.source, _source);
  });
}
