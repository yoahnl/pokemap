import 'dart:io';

import 'package:avelune_studio/app/di/language_providers.dart';
import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/language/coordination/studio_language_preferences.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/platform/files/local_language_preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/studio_workspace_test_overrides.dart';

void main() {
  testWidgets('the Studio follows the system language until one is chosen', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final session = ProjectSessionController(ControlledProjectSessionPort());
    addTearDown(session.dispose);
    final store = MemoryStudioLanguageStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionControllerProvider.overrideWith((ref) => session),
          studioLanguagePreferencesProvider.overrideWith((ref) {
            final preferences = StudioLanguagePreferences(store);
            ref.onDispose(preferences.dispose);
            return preferences;
          }),
          ...studioWorkspaceTestOverrides(),
        ],
        child: const StudioApp(),
      ),
    );
    await tester.pumpAndSettle();

    final home = find.byKey(const ValueKey('studio-home'));
    expect(Localizations.localeOf(tester.element(home)).languageCode, 'en');
    expect(find.byKey(const ValueKey('studio-language')), findsNothing);
    expect(find.byKey(const ValueKey('home-export-game')), findsNothing);
    final rail = find.byKey(const ValueKey('studio-rail'));
    final homeRail = tester.element(rail);
    final homeRoute = ModalRoute.of(homeRail);
    await tester.tap(find.byKey(const ValueKey('studio-rail-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Studio settings'), findsWidgets);
    expect(ModalRoute.of(tester.element(rail)), same(homeRoute));
    expect(tester.element(rail), same(homeRail));

    Future<void> choose(String code) async {
      await tester.tap(find.byKey(const ValueKey('studio-settings-language')));
      await tester.pumpAndSettle();
      final label = switch (code) {
        'fr' => 'Français',
        'en' => 'English',
        _ => 'System language',
      };
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await choose('fr');
    expect(find.text('Réglages du Studio'), findsWidgets);
    expect(store.languageCode, 'fr');

    await choose('en');
    expect(find.text('Studio settings'), findsWidgets);
    expect(store.languageCode, 'en');

    await choose('system');
    await tester.tap(find.byKey(const ValueKey('studio-rail-home')));
    await tester.pumpAndSettle();
    expect(Localizations.localeOf(tester.element(home)).languageCode, 'en');
    expect(store.languageCode, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('the language preference survives a restart and refuses junk', () async {
    final directory = await Directory.systemTemp.createTemp('avelune_lang_');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/language-preferences.json';
    await LocalStudioLanguageStore(path).save('en');
    expect(await LocalStudioLanguageStore(path).load(), 'en');
    await LocalStudioLanguageStore(path).save(null);
    expect(await LocalStudioLanguageStore(path).load(), isNull);
    await File(path).writeAsString('{"schemaVersion":1,"languageCode":"../x"}');
    await expectLater(
      LocalStudioLanguageStore(path).load(),
      throwsA(isA<FormatException>()),
    );
  });

  test('a failed language write restores the last saved preference', () async {
    final preferences = StudioLanguagePreferences(_ReadOnlyLanguageStore());
    addTearDown(preferences.dispose);
    await preferences.load();
    await preferences.select('fr');

    expect(preferences.languageCode, 'en');
    expect(preferences.error, StudioLanguageFailure.save);
    expect(preferences.saving, isFalse);
  });
}

class _ReadOnlyLanguageStore implements StudioLanguageStore {
  @override
  Future<String?> load() async => 'en';

  @override
  Future<void> save(String? languageCode) async {
    throw const FileSystemException('Read-only preferences fixture');
  }
}
