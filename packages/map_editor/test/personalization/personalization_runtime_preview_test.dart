import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('PST-040 projects the current title screen contract',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(
              accentColor: '#224466',
              layoutVariant: 'cinematic',
            ),
            typography: ProjectTypographyProfile(
              display: ProjectTypographyRoleProfile(
                family: 'Aurore Display',
              ),
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('personalization-runtime-preview'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('personalization-preview-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('branding-title-preview-layout-cinematic'),
      ),
      findsOneWidget,
    );
    expect(find.text('Pokémon Aurore'), findsOneWidget);
    expect(find.text('Aurore Display'), findsOneWidget);
  });
}

Widget _app(Widget child) => MaterialApp(
      theme: PokeMapTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
