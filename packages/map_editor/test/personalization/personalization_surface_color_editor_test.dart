import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('shows inherited colors and creates one contextual override', (
    tester,
  ) async {
    ProjectSurfacePaletteProfile? changed;
    await tester.pumpWidget(
      _app(
        PersonalizationSurfaceColorEditor(
          role: ProjectPresentationSurfaceRole.dialogue,
          palette: null,
          inheritedTheme: safeProjectSemanticTheme,
          onChanged: (palette) => changed = palette,
        ),
      ),
    );

    expect(find.text('Hérité'), findsNWidgets(6));
    await tester.tap(
      find.byKey(const ValueKey<String>('surface-color-edit-dialogue-surface')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('personalization-theme-token-input')),
      '#102030',
    );
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    expect(changed?.surface, '#102030');
    expect(changed?.text, isNull);
  });

  testWidgets('restores one token or the complete scene inheritance', (
    tester,
  ) async {
    ProjectSurfacePaletteProfile? changed;
    await tester.pumpWidget(
      _app(
        PersonalizationSurfaceColorEditor(
          role: ProjectPresentationSurfaceRole.battleHud,
          palette: const ProjectSurfacePaletteProfile(
            surface: '#102030',
            border: '#63E6FF',
          ),
          inheritedTheme: safeProjectSemanticTheme,
          onChanged: (palette) => changed = palette,
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('surface-color-inherit-battleHud-surface'),
      ),
    );
    expect(changed?.surface, isNull);
    expect(changed?.border, '#63E6FF');

    await tester.tap(
      find.byKey(const ValueKey<String>('surface-colors-reset-battleHud')),
    );
    expect(changed, isNull);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
