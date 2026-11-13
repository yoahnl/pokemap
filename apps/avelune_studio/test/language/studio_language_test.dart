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

    expect(find.text('Import a project'), findsOneWidget);

    Future<void> choose(String code) async {
      await tester.tap(find.byKey(const ValueKey('studio-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('studio-language-$code')));
      await tester.pumpAndSettle();
    }

    await choose('fr');
    expect(find.text('Importer un projet'), findsOneWidget);
    expect(store.languageCode, 'fr');

    await choose('en');
    expect(find.text('Import a project'), findsOneWidget);
    expect(store.languageCode, 'en');

    await choose('system');
    expect(find.text('Import a project'), findsOneWidget);
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
}
