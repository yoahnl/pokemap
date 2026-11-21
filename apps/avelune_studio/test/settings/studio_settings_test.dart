import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:avelune_studio/app/di/rendering_providers.dart';
import 'package:avelune_studio/app/di/studio_settings_providers.dart';
import 'package:avelune_studio/features/rendering/coordination/studio_rendering_preferences.dart';
import 'package:avelune_studio/features/settings/studio_ai_preferences.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/settings/studio_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the display preference uses the renderer and persists', (
    tester,
  ) async {
    final initialLimit = AveluneFrameRate.limit;
    addTearDown(() => AveluneFrameRate.setLimit(initialLimit));
    final store = MemoryRenderingPreferencesStore();
    final preferences = StudioRenderingPreferences(store);
    addTearDown(preferences.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studioAiKeyStoreProvider.overrideWithValue(_Keys()),
          studioRenderingPreferencesProvider.overrideWithValue(preferences),
        ],
        child: _app(const StudioSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final display = find.byKey(const ValueKey('studio-settings-display-nav'));
    await tester.tap(display);
    await tester.pumpAndSettle();
    expect(find.text('Langue de l’interface'), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('studio-settings-frame-rate')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('90 images/s').last);
    await tester.pumpAndSettle();

    expect(AveluneFrameRate.limit, 90);
    expect(await store.load(), 90);
  });

  testWidgets('credentials are masked and reused on an explicit test only', (
    tester,
  ) async {
    final keys = _Keys();
    final connection = _Connection();
    await tester.viewWithSettings(keys, connection);

    await tester.tap(find.byKey(const ValueKey('studio-settings-ai-nav')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('studio-settings-add-provider')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer la clé'));
    await tester.pumpAndSettle();
    expect(find.text('Saisis une clé API valide.'), findsOneWidget);
    expect(keys.values, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('studio-settings-api-key')),
      '  fixture-key  ',
    );
    await tester.tap(find.text('Enregistrer la clé'));
    await tester.pumpAndSettle();
    expect(keys.values, {StudioAiProvider.openAi: 'fixture-key'});
    expect(connection.calls, isEmpty);
    expect(find.text('fixture-key'), findsNothing);
    await tester.tap(find.byTooltip('Afficher la clé'));
    await tester.pumpAndSettle();
    expect(find.text('fixture-key'), findsOneWidget);
    await tester.tap(find.byTooltip('Masquer la clé'));
    await tester.pumpAndSettle();
    expect(find.text('fixture-key'), findsNothing);

    await tester.tap(find.text('Tester la connexion'));
    await tester.pumpAndSettle();
    expect(connection.calls, [(StudioAiProvider.openAi, 'fixture-key')]);
    expect(find.text('Clé refusée ou accès insuffisant.'), findsOneWidget);

    await tester.tap(find.byTooltip('Remplacer la clé'));
    await tester.pumpAndSettle();
    expect(find.text('fixture-key'), findsNothing);
    await tester.tap(find.text('Supprimer la clé'));
    await tester.pumpAndSettle();
    final confirmation = find.widgetWithText(
      AlertDialog,
      'Supprimer la clé API de cet appareil ?',
    );
    await tester.tap(
      find.descendant(
        of: confirmation,
        matching: find.text('Supprimer la clé'),
      ),
    );
    await tester.pumpAndSettle();
    expect(keys.values, isEmpty);
    expect(find.text('Aucun fournisseur configuré.'), findsOneWidget);
  });
}

Widget _app(Widget home) => MaterialApp(
  theme: studioTheme(),
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

extension on WidgetTester {
  Future<void> viewWithSettings(_Keys keys, _Connection connection) async {
    view.physicalSize = const Size(1100, 780);
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
    await pumpWidget(
      ProviderScope(
        overrides: [
          studioAiKeyStoreProvider.overrideWithValue(keys),
          studioAiConnectionProvider.overrideWithValue(connection),
        ],
        child: _app(const StudioSettingsPage()),
      ),
    );
    await pumpAndSettle();
  }
}

class _Keys implements StudioAiKeyStore {
  final values = <StudioAiProvider, String>{};

  @override
  Future<bool> contains(StudioAiProvider provider) async =>
      values.containsKey(provider);

  @override
  Future<String?> read(StudioAiProvider provider) async => values[provider];

  @override
  Future<void> write(StudioAiProvider provider, String key) async =>
      values[provider] = key;

  @override
  Future<void> delete(StudioAiProvider provider) async =>
      values.remove(provider);
}

class _Connection implements StudioAiConnection {
  final calls = <(StudioAiProvider, String)>[];

  @override
  Future<StudioAiConnectionResult> test(
    StudioAiProvider provider,
    String key,
  ) async {
    calls.add((provider, key));
    return StudioAiConnectionResult.denied;
  }
}
