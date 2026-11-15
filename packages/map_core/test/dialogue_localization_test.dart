import 'dart:convert';

import 'package:map_core/map_core_domain.dart';
import 'package:test/test.dart';

DialogueLocalization _catalog() => DialogueLocalization(
  sourceLocale: 'fr',
  units: [
    DialogueTextUnit(
      id: 'greeting',
      binding: '/Start/0',
      kind: DialogueTextKind.line,
      source: 'Bonjour',
    ),
    DialogueTextUnit(
      id: 'leave',
      binding: '/Start/1/0',
      kind: DialogueTextKind.choice,
      source: 'Partir',
    ),
  ],
);

void main() {
  test('legacy dialogue JSON remains unchanged without localization', () {
    const entry = ProjectDialogueEntry(
      id: 'talk',
      name: 'Accueil',
      relativePath: 'dialogues/talk.yarn',
    );
    final json = entry.toJson();
    expect(json.containsKey('localization'), isFalse);
    expect(ProjectDialogueEntry.fromJson(json).toJson(), json);
  });

  test(
    'localized metadata round-trips and keeps exact text and identities',
    () {
      final catalog = _catalog().translate('greeting', 'en', 'Hello\n"friend"');
      final entry = ProjectDialogueEntry(
        id: 'talk',
        name: 'Accueil',
        relativePath: 'dialogues/talk.yarn',
        localization: catalog,
      );
      final json =
          jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>;
      final reopened = ProjectDialogueEntry.fromJson(json).localization!;
      expect(ProjectDialogueEntry.fromJson(json), entry);
      expect(reopened.toJson(), catalog.toJson());
      expect(reopened.units.map((unit) => unit.id), ['greeting', 'leave']);
      expect(() => reopened.units.clear(), throwsUnsupportedError);
      expect(
        () => reopened.units.first.translations.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test('locale matching and missing translations use an explicit fallback', () {
    final catalog = _catalog().translate('greeting', 'en', 'Hello');
    DialogueTextResolution resolve(String id, String locale) => catalog.resolve(
      id,
      preferredLocale: locale,
      supportedLocales: ['fr', 'en', 'es'],
      fallbackLocale: 'fr',
    );
    final english = resolve('greeting', 'en-GB');
    expect(english.text, 'Hello');
    expect(english.status, DialogueTranslationStatus.translated);
    expect(english.textLocale, 'en');
    final missing = resolve('leave', 'en');
    expect(missing.text, 'Partir');
    expect(missing.status, DialogueTranslationStatus.missing);
    expect(missing.usedFallback, isTrue);
    expect(missing.effectiveLocale, 'en');
    expect(missing.textLocale, 'fr');
    expect(resolve('greeting', 'de').text, 'Bonjour');
    expect(resolve('greeting', 'fr-CA').text, 'Bonjour');
    final projectFallback = catalog.resolve(
      'greeting',
      preferredLocale: 'es',
      supportedLocales: ['fr', 'en', 'es'],
      fallbackLocale: 'en',
    );
    expect(projectFallback.text, 'Hello');
    expect(projectFallback.effectiveLocale, 'es');
    expect(projectFallback.textLocale, 'en');
    expect(projectFallback.status, DialogueTranslationStatus.missing);
  });

  test(
    'editing the source marks existing variants for review without erasing them',
    () {
      final catalog = _catalog().translate('greeting', 'en', 'Hello');
      final changed = catalog.withUnits([
        catalog.units.first.copyWith(source: 'Bienvenue'),
        catalog.units.last,
      ]);
      final resolved = changed.resolve(
        'greeting',
        preferredLocale: 'en',
        supportedLocales: ['fr', 'en'],
        fallbackLocale: 'fr',
      );
      expect(resolved.text, 'Hello');
      expect(resolved.status, DialogueTranslationStatus.needsReview);
      expect(catalog.units.first.source, 'Bonjour');
      expect(
        changed
            .translate('greeting', 'en', 'Welcome')
            .resolve(
              'greeting',
              preferredLocale: 'en',
              supportedLocales: ['fr', 'en'],
              fallbackLocale: 'fr',
            )
            .status,
        DialogueTranslationStatus.translated,
      );
    },
  );

  test(
    'unknown formats, fields, duplicate identities and empty variants are refused',
    () {
      final json = _catalog().toJson();
      for (final invalid in [
        {...json, 'format': 2},
        {...json, 'format': 1.0},
        {...json, 'unknown': true},
        {...json, 'sourceLocale': '!!!'},
        {
          ...json,
          'units': [json['units']![0], json['units']![0]],
        },
      ]) {
        expect(
          () => DialogueLocalization.fromJson(invalid),
          throwsFormatException,
        );
      }
      expect(
        () => _catalog().translate('greeting', 'en', ''),
        throwsArgumentError,
      );
      expect(
        () => _catalog().translate('unknown', 'en', 'Hello'),
        throwsArgumentError,
      );
      expect(
        () => _catalog().translate('greeting', 'fr', 'Salut'),
        throwsArgumentError,
      );
      expect(_catalog().toJson(), json);
    },
  );
}
