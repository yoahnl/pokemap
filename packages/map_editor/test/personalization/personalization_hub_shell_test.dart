import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  const responsiveSizes = <Size>[
    Size(759, 900),
    Size(760, 900),
    Size(761, 900),
    Size(1024, 720),
    Size(1280, 800),
    Size(1600, 1000),
  ];

  for (final size in responsiveSizes) {
    for (final textScale in <double>[1, 2]) {
      testWidgets(
        'remains usable at ${size.width}x${size.height} and ${textScale}x text',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              theme: PokeMapTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(textScale),
                ),
                child: Scaffold(
                  body: PersonalizationHubShell(
                    profile: _responsiveProfile,
                    baselineProfile: const ProjectPresentationProfile(),
                    selectedCategory: ProjectPresentationCategory.branding,
                    onCategorySelected: (_) {},
                    onProfileChanged: (_) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.byKey(
              const ValueKey<String>('personalization-runtime-preview'),
            ),
            findsOneWidget,
          );
          expect(
            find.byKey(
              const ValueKey<String>('personalization-category-branding'),
            ),
            findsOneWidget,
          );
        },
      );
    }
  }

  testWidgets('shows every semantic category and shared diagnostics', (
    tester,
  ) async {
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
    expect(find.text('Identité & écran titre'), findsWidgets);
    expect(find.text('Intro du jeu'), findsOneWidget);
    expect(find.text('Typographie'), findsOneWidget);
    expect(find.text('Menus & interface'), findsOneWidget);
    expect(find.text('1 erreur'), findsOneWidget);
    expect(
      find.text('Use a hexadecimal color such as #6750A4.'),
      findsOneWidget,
    );

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

  testWidgets('uses accessible navigation and opens the contextual preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PersonalizationHubShell(
            profile: const ProjectPresentationProfile(
              theme: safeProjectSemanticTheme,
            ),
            selectedCategory: ProjectPresentationCategory.theme,
            onCategorySelected: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('personalization-preview-battle')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-global-style-composition'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('personalization-category-search')),
      findsNothing,
    );
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('personalization-category-theme')),
      ),
      matchesSemantics(
        hasTapAction: true,
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
  });

  testWidgets('applies presets, compares and resets the active section', (
    tester,
  ) async {
    ProjectPresentationProfile? changed;
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(layoutVariant: 'centered'),
      theme: safeProjectSemanticTheme,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PersonalizationHubShell(
            profile: profile,
            baselineProfile: const ProjectPresentationProfile(),
            selectedCategory: ProjectPresentationCategory.branding,
            onCategorySelected: (_) {},
            onProfileChanged: (profile) => changed = profile,
          ),
        ),
      ),
    );

    expect(find.textContaining('changements'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preset-cinematic')),
    );
    expect(changed?.branding.layoutVariant, 'cinematic');

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-reset-branding')),
    );
    expect(changed?.branding, const ProjectBrandingProfile());
    expect(changed?.theme, safeProjectSemanticTheme);

    expect(
      find.byKey(const ValueKey<String>('personalization-preview-compare')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('personalization-preview-compare')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-compare')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-preview-before')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('personalization-preview-after')),
      findsOneWidget,
    );
  });

  testWidgets('applies the safe theme from an actionable contrast diagnostic', (
    tester,
  ) async {
    ProjectPresentationProfile? changed;
    final unsafeTheme = safeProjectSemanticTheme.copyWith(
      textPrimary: safeProjectSemanticTheme.background,
    );
    final profile = ProjectPresentationProfile(theme: unsafeTheme);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PersonalizationHubShell(
            profile: profile,
            selectedCategory: ProjectPresentationCategory.theme,
            onCategorySelected: (_) {},
            onProfileChanged: (profile) => changed = profile,
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(
        const ValueKey<String>('personalization-readiness-correction-0'),
      ),
      400,
      scrollable: find
          .descendant(
            of: find.byKey(
              const ValueKey<String>('personalization-category-detail-theme'),
            ),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-readiness-correction-0'),
      ),
    );

    expect(changed?.theme, safeProjectSemanticTheme);
  });
}

const _responsiveProfile = ProjectPresentationProfile(
  branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
  titleMotion: ProjectTitleMotionProfile(
    promptLoop: ProjectResponsiveVideoProfile(
      landscape: ProjectVideoVariantProfile(
        videoPath: 'assets/presentation/title/prompt.mp4',
        posterPath: 'assets/presentation/title/prompt.png',
        durationMilliseconds: 4000,
        width: 1280,
        height: 720,
        bitrateKbps: 1200,
        sizeBytes: 4000,
        videoCodec: 'h264',
      ),
    ),
  ),
  theme: safeProjectSemanticTheme,
  menuLabels: ProjectMenuLabelsProfile(pokedex: 'Carnet'),
);
