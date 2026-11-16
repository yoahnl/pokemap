import 'package:avelune_studio/features/dialogues/application/dialogue_localization_editing.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

const source =
    'title: Start\r\ntags: shared\r\n---\r\n'
    '<<portrait hero happy>>\r\nLuth: Bonjour {{ fact.name }}\r\n'
    '(Le vent souffle.)\r\n-> Oui\r\n    <<outcome yes>>\r\n'
    '    <<jump End>>\r\n===\r\ntitle: End\r\n---\r\nAu revoir.\r\n===\r\n';

StoryDialogueSource original({bool localized = true}) {
  final opened = readLocalizedDialogue(source: source, sourceLocale: 'fr');
  final localization = opened.localization.translate(
    opened.localization.units.first.id,
    'en',
    'Hello {{ fact.name }}',
  );
  return StoryDialogueSource(
    entry: ProjectDialogueEntry(
      id: 'shared',
      name: 'Rencontre',
      relativePath: 'dialogues/shared.yarn',
      localization: localized ? localization : null,
      declaredOutcomes: const [
        DialogueDeclaredOutcome(id: 'yes', label: 'Oui'),
      ],
    ),
    source: source,
    revision: 'saved-revision',
  );
}

void main() {
  test('copying edited text preserves variants and the saved original', () {
    final saved = original();
    final form = DialogueLocalizationEditing(saved);
    final id = form.localization.units.last.id;
    form.writeSource(id, 'Copie indépendante - à bientôt !');
    final copied = form.duplicate(id: 'copy', name: 'Copie');
    expect(
      copied.source,
      source.replaceFirst('Au revoir.', 'Copie indépendante - à bientôt !'),
    );
    expect(
      copied.entry.localization!.units.first.translations,
      saved.entry.localization!.units.first.translations,
    );
    expect(
      copied.entry.localization!.units
          .map((unit) => unit.id)
          .toSet()
          .intersection(
            saved.entry.localization!.units.map((unit) => unit.id).toSet(),
          ),
      isEmpty,
    );
    expect(saved.source, source);
  });

  test(
    'text that would change its speaker is refused with the input intact',
    () {
      final saved = original();
      final form = DialogueLocalizationEditing(saved);
      final id = form.localization.units.last.id;
      form.writeSource(id, 'Changement de locuteur : texte');
      expect(form.build, throwsA(isA<DialogueTextUnrepresentable>()));
      expect(form.sourceText(id), 'Changement de locuteur : texte');
      expect(saved.source, source);
    },
  );
  test('source changes preserve translations and durable identities', () {
    final saved = original();
    final editing = DialogueLocalizationEditing(saved);
    final id = editing.localization.units.first.id;
    editing.writeSource(id, 'Salut {{ fact.name }}');
    final changed = editing.build();
    expect(changed.source, source.replaceFirst('Bonjour', 'Salut'));
    expect(
      changed.entry.localization!.units.map((u) => u.id),
      saved.entry.localization!.units.map((u) => u.id),
    );
    expect(editing.resolve(id, 'en').needsReview, isTrue);
    expect(changed.revision, saved.revision);
    expect(changed.entry.declaredOutcomes, saved.entry.declaredOutcomes);
  });

  test('translations and review confirmation leave source bytes unchanged', () {
    final saved = original();
    final editing = DialogueLocalizationEditing(saved);
    final id = editing.localization.units.first.id;
    editing.writeTranslation(id, 'es', 'Hola {{ fact.name }}');
    final changed = editing.build();
    expect(changed.source, source);
    expect(
      changed.entry.localization!.unit(id).translations['en'],
      saved.entry.localization!.unit(id).translations['en'],
    );
    expect(
      editing.resolve(id, 'es').status,
      DialogueTranslationStatus.translated,
    );
    editing.writeSource(id, 'Salut {{ fact.name }}');
    expect(editing.resolve(id, 'es').needsReview, isTrue);
    editing.writeTranslation(id, 'es', 'Hola {{ fact.name }}');
    expect(editing.resolve(id, 'es').needsReview, isFalse);
  });

  test('narration and choices keep their results and syntax', () {
    final editing = DialogueLocalizationEditing(original());
    final narration = editing.localization.units.firstWhere(
      (u) => u.kind == DialogueTextKind.narration,
    );
    final choice = editing.localization.units.firstWhere(
      (u) => u.kind == DialogueTextKind.choice,
    );
    editing.writeSource(narration.id, 'Le soleil brille.');
    editing.writeSource(choice.id, 'Avec plaisir');
    final changed = editing.build();
    expect(
      changed.source,
      source
          .replaceFirst('Le vent souffle.', 'Le soleil brille.')
          .replaceFirst('-> Oui', '-> Avec plaisir'),
    );
    expect(changed.entry.declaredOutcomes.single.id, 'yes');
  });

  test('legacy source editing does not silently enable localization', () {
    final editing = DialogueLocalizationEditing(original(localized: false));
    expect(editing.sourceLocale, isNull);
    editing.writeSource(
      editing.localization.units.first.id,
      'Salut {{ fact.name }}',
    );
    expect(editing.build().entry.localization, isNull);
    editing.declareSourceLocale('fr');
    expect(editing.build().entry.localization!.sourceLocale, 'fr');
  });

  test('empty translation removes only that variant and exposes fallback', () {
    final editing = DialogueLocalizationEditing(original());
    final id = editing.localization.units.first.id;
    editing.writeTranslation(id, 'en', '');
    expect(editing.resolve(id, 'en').status, DialogueTranslationStatus.missing);
    expect(editing.resolve(id, 'en').text, 'Bonjour {{ fact.name }}');
    expect(editing.build().source, source);
  });
}
