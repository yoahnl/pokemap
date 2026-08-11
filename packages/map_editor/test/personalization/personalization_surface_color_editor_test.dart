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

    expect(find.text('Hérité de Style global'), findsNWidgets(6));
    expect(
      find.text(
        'Éléments affectés : la bulle, le nom, le texte et les choix de dialogue.',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('surface-color-edit-dialogue-surface')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Avant application, cette couleur affectera la bulle, le nom, le texte et les choix de dialogue.',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('personalization-theme-token-input')),
      '#F0F0F0',
    );
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    expect(changed?.surface, '#F0F0F0');
    expect(changed?.text, isNull);
  });

  testWidgets('refuses a contextual color that breaks contrast', (
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

    await tester.tap(
      find.byKey(const ValueKey<String>('surface-color-edit-dialogue-text')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('personalization-theme-token-input')),
      safeProjectSemanticTheme.dialogueSurface,
    );
    await tester.tap(find.text('Appliquer'));
    await tester.pump();

    expect(
      find.text(
        'Cette couleur ne garde pas assez de contraste dans cette scène.',
      ),
      findsOneWidget,
    );
    expect(changed, isNull);
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

    final reset = find.byKey(
      const ValueKey<String>('surface-colors-reset-battleHud'),
    );
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    expect(reset.hitTestable(), findsOneWidget);
    await tester.tap(reset);
    expect(changed, isNull);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
