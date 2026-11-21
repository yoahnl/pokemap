import 'dart:io';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/di/studio_settings_providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/settings/studio_appearance_preferences.dart';
import 'package:avelune_studio/platform/files/local_appearance_preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/studio_workspace_test_overrides.dart';

void main() {
  testWidgets('Studio applies the saved appearance and changes it in Display', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(1100, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = ProjectSessionController(ControlledProjectSessionPort());
    addTearDown(session.dispose);
    final store = MemoryStudioAppearanceStore(StudioAppearance.light);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionControllerProvider.overrideWithValue(session),
          studioAppearanceStoreProvider.overrideWithValue(store),
          ...studioWorkspaceTestOverrides(),
        ],
        child: const StudioApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = find.byType(MaterialApp);
    expect(tester.widget<MaterialApp>(app).themeMode, ThemeMode.light);
    await tester.tap(find.byKey(const ValueKey('studio-rail-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('studio-settings-display-nav')));
    await tester.pumpAndSettle();
    final setting = find.byKey(const ValueKey('studio-settings-appearance'));
    expect(Theme.of(tester.element(setting)).brightness, Brightness.light);
    await tester.tap(setting);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sombre').last);
    await tester.pumpAndSettle();

    expect(tester.widget<MaterialApp>(app).themeMode, ThemeMode.dark);
    expect(Theme.of(tester.element(setting)).brightness, Brightness.dark);
    expect(await store.load(), StudioAppearance.dark);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'the local store preserves a choice and rejects invalid files',
    () async {
      final directory = await Directory.systemTemp.createTemp('appearance_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/appearance-preferences.json');
      expect(await LocalStudioAppearanceStore(file.path).load(), isNull);

      await LocalStudioAppearanceStore(file.path).save(StudioAppearance.light);
      expect(
        await LocalStudioAppearanceStore(file.path).load(),
        StudioAppearance.light,
      );
      const invalid = '{"schemaVersion":1,"appearance":"system"}';
      await file.writeAsString(invalid);
      await expectLater(
        LocalStudioAppearanceStore(file.path).load(),
        throwsFormatException,
      );
      expect(await file.readAsString(), invalid);
    },
  );

  test('a failed write restores the saved appearance', () async {
    final preferences = StudioAppearancePreferences(_ReadOnlyAppearanceStore());
    addTearDown(preferences.dispose);
    await preferences.load();
    await preferences.select(StudioAppearance.dark);
    expect(preferences.appearance, StudioAppearance.light);
    expect(preferences.error, StudioAppearanceFailure.save);
    expect(preferences.saving, isFalse);
  });
}

class _ReadOnlyAppearanceStore implements StudioAppearanceStore {
  @override
  Future<StudioAppearance?> load() async => StudioAppearance.light;

  @override
  Future<void> save(StudioAppearance appearance) async {
    throw const FileSystemException('Read-only appearance fixture');
  }
}
