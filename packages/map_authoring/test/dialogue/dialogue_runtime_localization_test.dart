import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final line in [
    'Maman:   Bonjour',
    '(La nuit tombe)',
    YarnDialogueLineLiteral(text: '  Deux: mots\n exacts  ').toSource(),
    r'\"Bonjour"',
    '__AVELUNE_TEXT_0_0__',
    '<<portrait mother happy>>\nMaman: Bonjour',
    '-> Choisir\n  <<speaker mother>>\n  Bonjour',
  ]) {
    test('preserves protected literal and directive forms: $line', () {
      final source = 'title: Start\r\ncustom: gardé\r\n---\r\n'
          '${line.replaceAll('\n', '\r\n')}\r\n===\r\n';
      final opened = readLocalizedDialogue(source: source, sourceLocale: 'fr');
      var localization = opened.localization;
      for (final unit in localization.units) {
        localization = localization.translate(unit.id, 'en', 'Traduit');
      }
      final document = const YarnDialogueCompiler().compile(source);
      final compiled = compileRuntimeDialogueLocalization(
          source: source, document: document, localization: localization);
      validateRuntimeDialogueLocalization(document, compiled);
      expect(compiled.units.map((unit) => unit.id).toSet(),
          localization.units.map((unit) => unit.id).toSet());
      expect(opened.source, source);
    });
  }

  test('reprojection keeps stale translations and their revision status', () {
    const oldSource = 'title: Start\n---\nMaman: Bonjour\n===\n';
    final opened = readLocalizedDialogue(source: oldSource, sourceLocale: 'fr');
    final original = opened.localization;
    final translated =
        original.translate(original.units.single.id, 'en', 'Hello');
    final line =
        opened.document.nodes.single.steps.whereType<DeLineStep>().single;
    line.body = 'Bienvenue';
    final changed =
        writeLocalizedDialogue(opened.document, previous: translated);
    final document = const YarnDialogueCompiler().compile(changed.source);
    final compiled = compileRuntimeDialogueLocalization(
        source: changed.source,
        document: document,
        localization: changed.localization);
    final resolved = compiled.resolve(compiled.units.single.id,
        preferredLocale: 'en',
        supportedLocales: ['fr', 'en'],
        fallbackLocale: 'fr');
    expect(resolved.text, 'Maman: Hello');
    expect(resolved.status, DialogueTranslationStatus.needsReview);
    expect(compiled.units.single.source, 'Maman: Bienvenue');
    expect(compiled.units.single.translations['en']!.source, 'Maman: Bonjour');
  });

  test(
      'projects exact identities past ignored commands, speakers and narration',
      () {
    const source = 'title: Start\n---\n<<set something>>\n'
        'Maman: Bonjour\n(La nuit tombe)\nBonjour\n'
        '-> Partir\n  <<outcome leave>>\n  Au revoir\n'
        '-> Rester\n  <<outcome stay>>\n===\n';
    final opened = readLocalizedDialogue(source: source, sourceLocale: 'fr');
    var localization = opened.localization;
    for (final (index, unit) in localization.units.indexed) {
      localization = localization.translate(unit.id, 'en', 'English $index');
    }
    final document = const YarnDialogueCompiler().compile(source);
    final compiled = compileRuntimeDialogueLocalization(
        source: source, document: document, localization: localization);
    expect(compiled.units.map((unit) => unit.id),
        localization.units.map((unit) => unit.id));
    expect(compiled.units.first.binding, '/Start/0');
    expect(compiled.units.first.source, 'Maman: Bonjour');
    expect(compiled.units[1].source, '(La nuit tombe)');
    expect(compiled.units.first.translations['en']!.text, 'Maman: English 0');
    expect(compiled.units[1].translations['en']!.text, '(English 1)');
    final english = resolveRuntimeDialogueLocalization(document, compiled,
        preferredLocale: 'en',
        locales: ProjectLocalePolicy(
            supportedLocales: ['fr', 'en'], fallbackLocale: 'fr'));
    expect(
        runtimeDialogueTextShape(english), runtimeDialogueTextShape(document));
    expect(runtimeDialogueTextScopes(english).map((scope) => scope.text), [
      'Maman: English 0',
      '(English 1)',
      'English 2',
      'English 3',
      'English 4',
      'English 5',
    ]);
    expect(opened.source, source);
    expect(opened.localization.units.first.source, 'Bonjour');
  });

  test(
      'translation syntax remains literal data and cannot add a jump or choice',
      () {
    const source = 'title: Start\n---\nBonjour\n===\n';
    final opened = readLocalizedDialogue(source: source, sourceLocale: 'fr');
    const literal = '-> Quitter\n<<jump Missing>>\n  espaces  ';
    final localization = opened.localization
        .translate(opened.localization.units.single.id, 'en', literal);
    final document = const YarnDialogueCompiler().compile(source);
    final compiled = compileRuntimeDialogueLocalization(
        source: source, document: document, localization: localization);
    final english = resolveRuntimeDialogueLocalization(document, compiled,
        preferredLocale: 'en',
        locales: ProjectLocalePolicy(
            supportedLocales: ['fr', 'en'], fallbackLocale: 'fr'));
    expect((english.nodes.single.steps.single as RuntimeDialogueLine).text,
        literal);
    expect(
        runtimeDialogueTextShape(english), runtimeDialogueTextShape(document));
  });

  test('stale metadata and different compiled structures are refused', () {
    const source = 'title: Start\n---\nBonjour\n===\n';
    final localization =
        readLocalizedDialogue(source: source, sourceLocale: 'fr').localization;
    expect(
        () => compileRuntimeDialogueLocalization(
            source: source.replaceFirst('Bonjour', 'Salut'),
            document: const YarnDialogueCompiler().compile(source),
            localization: localization),
        throwsFormatException);
    expect(
        () => compileRuntimeDialogueLocalization(
            source: source,
            document: const YarnDialogueCompiler()
                .compile('title: Other\n---\nBonjour\n===\n'),
            localization: localization),
        throwsFormatException);
  });
}
