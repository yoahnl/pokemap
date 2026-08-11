import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('shows all semantic roles and dispatches guided font import', (
    tester,
  ) async {
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
    expect(find.text('Combats'), findsOneWidget);
    expect(find.text('Nombres'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('typography-import-display')),
    );
    expect(selected, ProjectTypographyRole.display);
  });

  testWidgets('uses the loaded preview family and exposes license evidence', (
    tester,
  ) async {
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
      find.byKey(const ValueKey<String>('typography-preview-display')),
    );
    expect(preview.style?.fontFamily, 'PokeMapPreview-display');
    expect(preview.style?.fontFamilyFallback, <String>['sans-serif']);
  });

  testWidgets('edits bounded V6 metrics and updates the live sample', (
    tester,
  ) async {
    ProjectTypographyMetricsProfile? changed;
    await tester.pumpWidget(
      _app(
        ProjectTypographyEditor(
          profile: const ProjectTypographyProfile(
            display: ProjectTypographyRoleProfile(
              metrics: ProjectTypographyMetricsProfile(
                sizeScale: 1.25,
                weight: 700,
                lineHeight: 1.1,
                letterSpacing: .5,
              ),
            ),
          ),
          fixedRole: ProjectTypographyRole.display,
          onImportRole: (_) {},
          onUseSystemFont: (_) {},
          onMetricsChanged: (_, metrics) => changed = metrics,
        ),
      ),
    );

    final preview = tester.widget<Text>(
      find.byKey(const ValueKey<String>('typography-preview-display')),
    );
    expect(preview.style?.fontSize, 35);
    expect(preview.style?.fontWeight, FontWeight.w700);
    expect(preview.style?.height, 1.1);
    expect(preview.style?.letterSpacing, .5);

    await tester.tap(
      find.byKey(const ValueKey<String>('typography-weight-display')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('600').last);
    await tester.pumpAndSettle();

    expect(changed?.weight, 600);
  });

  testWidgets('keeps contextual role metrics independent', (tester) async {
    ProjectTypographyRole? changedRole;
    ProjectTypographyMetricsProfile? changedMetrics;
    await tester.pumpWidget(
      _app(
        ProjectTypographyEditor(
          profile: const ProjectTypographyProfile(),
          roles: const <ProjectTypographyRole>[
            ProjectTypographyRole.combat,
            ProjectTypographyRole.numbers,
          ],
          onImportRole: (_) {},
          onUseSystemFont: (_) {},
          onMetricsChanged: (role, metrics) {
            changedRole = role;
            changedMetrics = metrics;
          },
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('typography-size-combat')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('typography-size-numbers')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('typography-size-dialogue')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('typography-size-numbers')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('125 %').last);
    await tester.pumpAndSettle();

    expect(changedRole, ProjectTypographyRole.numbers);
    expect(changedMetrics?.sizeScale, 1.25);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
