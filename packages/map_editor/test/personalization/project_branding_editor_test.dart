import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('offers guided image controls for icon, cover, and hero',
      (tester) async {
    final imported = <ProjectBrandingImageRole>[];
    final removed = <ProjectBrandingImageRole>[];
    const profile = ProjectBrandingProfile(
      iconPath: 'assets/presentation/branding/icon.png',
      coverPath: 'assets/presentation/branding/cover.png',
      heroPath: 'assets/presentation/branding/hero.png',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectBrandingEditor(
              profile: profile,
              onImportImage: imported.add,
              onRemoveImage: removed.add,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Icône du jeu'), findsOneWidget);
    expect(find.text('Cover de bibliothèque'), findsOneWidget);
    expect(find.text('Logo / hero du titre'), findsOneWidget);
    for (final role in ProjectBrandingImageRole.values) {
      await tester.tap(
        find.byKey(ValueKey<String>('branding-import-${role.name}')),
      );
      await tester.tap(
        find.byKey(ValueKey<String>('branding-remove-${role.name}')),
      );
    }

    expect(imported, ProjectBrandingImageRole.values);
    expect(removed, ProjectBrandingImageRole.values);
  });
}
