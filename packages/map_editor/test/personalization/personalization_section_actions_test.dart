import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_section_actions.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('describes modified sections without exposing JSON paths', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: const Scaffold(
          body: PersonalizationSectionActions(
            profile: ProjectPresentationProfile(
              typography: ProjectTypographyProfile(),
              windows: legacyProjectPresentationWindows,
            ),
            category: ProjectPresentationCategory.theme,
            baselineProfile: ProjectPresentationProfile(),
            onProfileChanged: null,
          ),
        ),
      ),
    );

    expect(find.text('2 sections modifiées'), findsOneWidget);
    expect(find.text('Typographie  •  Forme des fenêtres'), findsOneWidget);
    expect(find.textContaining(r'$.'), findsNothing);
  });
}
