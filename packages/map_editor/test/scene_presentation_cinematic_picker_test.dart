import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_presentation_cinematic_picker.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('Create and link is an enabled explicit picker choice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: const Scaffold(
          body: ScenePresentationCinematicPicker(cinematics: []),
        ),
      ),
    );

    final finder = find.byKey(
      const ValueKey('scene-presentation-picker-create-and-link'),
    );
    expect(finder, findsOneWidget);
    expect(tester.widget<PokeMapButton>(finder).onPressed, isNotNull);
    expect(find.text('Créer et lier'), findsOneWidget);
  });

  testWidgets(
    'English picker remains usable at 200 percent and preserves grapheme search',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: PokeMapTheme.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: ScenePresentationCinematicPicker(
              cinematics: [
                PresentationCinematicAsset(
                  id: 'opening',
                  title: 'Étoile 👩🏽‍🚀',
                  durationUs: 1000000,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create and link'), findsOneWidget);
      expect(find.text('Use an existing cinematic'), findsOneWidget);
      expect(find.text('Landscape · fallback'), findsOneWidget);
      expect(find.text('Portrait · fallback'), findsOneWidget);
      expect(tester.takeException(), isNull);

      const query = '👩🏽‍🚀 e\u0301toile';
      await tester.enterText(
        find.byKey(const ValueKey('scene-presentation-picker-search')),
        query,
      );
      expect(find.text(query), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
