import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('shows every semantic category and shared diagnostics',
      (tester) async {
    ProjectPresentationCategory? selected;
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(accentColor: 'purple'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PersonalizationHubShell(
            profile: profile,
            selectedCategory: ProjectPresentationCategory.branding,
            onCategorySelected: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('Personalization Hub'), findsOneWidget);
    expect(find.text('Branding'), findsWidgets);
    expect(find.text('Intro vidéo'), findsOneWidget);
    expect(find.text('Typographie'), findsOneWidget);
    expect(find.text('Thème & HUD'), findsOneWidget);
    expect(find.text('1 erreur'), findsOneWidget);
    expect(
        find.text('Use a hexadecimal color such as #6750A4.'), findsOneWidget);

    await tester.tap(find.text('Typographie'));
    expect(selected, ProjectPresentationCategory.typography);
  });

  testWidgets('renders category-specific no-code content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PersonalizationHubShell(
            profile: const ProjectPresentationProfile(),
            selectedCategory: ProjectPresentationCategory.intro,
            onCategorySelected: (_) {},
            categoryBuilder: (context, category) =>
                Text('Editor for ${category.name}'),
          ),
        ),
      ),
    );

    expect(find.text('Editor for intro'), findsOneWidget);
    expect(find.text('Prêt à configurer'), findsOneWidget);
  });
}
