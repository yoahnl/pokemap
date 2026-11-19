import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  for (final (locale, counts) in [
    ('fr', ['0 caractère', '1 caractère', '2 caractères']),
    ('en', ['0 characters', '1 character', '2 characters']),
  ]) {
    testWidgets('text input pluralizes character count in $locale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: PlayerSceneInteractionSurface(
            request: SceneInteractionRequest.text(
              requestId: 'name',
              revision: 1,
              prompt: SceneInteractionPrompt(
                localizationKey: 'game.name',
                fallbackText: 'Céleste',
              ),
            ),
            onResult: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Céleste'), findsOneWidget);
      expect(find.text(counts[0]), findsOneWidget);

      final field = find.byKey(const ValueKey('scene-interaction-text-field'));
      await tester.enterText(field, 'e\u0301');
      await tester.pump();
      expect(find.text(counts[1]), findsOneWidget);

      await tester.enterText(field, 'e\u0301a');
      await tester.pump();
      expect(find.text(counts[2]), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
