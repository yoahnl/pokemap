import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('shows all semantic roles and dispatches guided font import',
      (tester) async {
    ProjectTypographyRole? selected;

    await tester.pumpWidget(
      _app(
        ProjectTypographyEditor(
          profile: const ProjectTypographyProfile(),
          onImportRole: (role) => selected = role,
          onUseSystemFont: (_) {},
        ),
      ),
    );

    expect(find.text('Titres & affichage'), findsOneWidget);
    expect(find.text('Texte courant'), findsOneWidget);
    expect(find.text('Dialogues'), findsOneWidget);
    expect(find.text('Nombres'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('typography-import-display'),
      ),
    );
    expect(selected, ProjectTypographyRole.display);
  });

  testWidgets('uses the loaded preview family and exposes license evidence',
      (tester) async {
    const role = ProjectTypographyRoleProfile(
      fontPath: 'assets/presentation/fonts/display.ttf',
      family: 'Aube Display',
      licensePath: 'assets/presentation/fonts/display-license.txt',
      redistributable: true,
      fallbackFamilies: <String>['sans-serif'],
      glyphCoverage: <String>[
        'latin',
        'latinExtended',
        'digits',
        'punctuation',
      ],
    );

    await tester.pumpWidget(
      _app(
        ProjectTypographyEditor(
          profile: const ProjectTypographyProfile(display: role),
          previewFamilies: const <ProjectTypographyRole, String>{
            ProjectTypographyRole.display: 'PokeMapPreview-display',
          },
          onImportRole: (_) {},
          onUseSystemFont: (_) {},
        ),
      ),
    );

    expect(find.text('Licence jointe'), findsOneWidget);
    expect(find.text('Glyphes vérifiés'), findsOneWidget);
    final preview = tester.widget<Text>(
      find.byKey(
        const ValueKey<String>('typography-preview-display'),
      ),
    );
    expect(preview.style?.fontFamily, 'PokeMapPreview-display');
    expect(preview.style?.fontFamilyFallback, <String>['sans-serif']);
  });
}

Widget _app(Widget child) => MaterialApp(
      theme: PokeMapTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
