import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('PST-040 projects the current title screen contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(
              accentColor: '#224466',
              layoutVariant: 'cinematic',
            ),
            typography: ProjectTypographyProfile(
              display: ProjectTypographyRoleProfile(family: 'Aurore Display'),
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('personalization-runtime-preview')),
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

  testWidgets('PST-041 composes dialogue and menu runtime surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            typography: ProjectTypographyProfile(
              body: ProjectTypographyRoleProfile(family: 'Aurore Body'),
              dialogue: ProjectTypographyRoleProfile(family: 'Aurore Dialogue'),
            ),
            menuLabels: ProjectMenuLabelsProfile(
              pauseTitle: 'Interlude',
              pokedex: 'Carnet',
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-dialogue')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-dialogue-composition'),
      ),
      findsOneWidget,
    );
    expect(find.text('Professeure Saule'), findsOneWidget);
    expect(find.textContaining('Le monde est peuplé'), findsOneWidget);
    final dialogueText = tester.widget<Text>(
      find.byKey(
        const ValueKey<String>('personalization-dialogue-sample-text'),
      ),
    );
    expect(dialogueText.style?.fontFamily, 'Aurore Dialogue');

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-menu')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-menu-composition')),
      findsOneWidget,
    );
    expect(find.text('Interlude'), findsNWidgets(2));
    expect(find.text('Équipe'), findsOneWidget);
    expect(find.text('Carnet'), findsOneWidget);
    expect(find.text('Pokédex'), findsNothing);
    final menuText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('personalization-menu-sample-text')),
    );
    expect(menuText.style?.fontFamily, 'Aurore Body');
  });

  testWidgets('PST-042 composes overworld and battle HUD surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            typography: ProjectTypographyProfile(
              body: ProjectTypographyRoleProfile(family: 'Aurore Body'),
              numbers: ProjectTypographyRoleProfile(family: 'Aurore Numbers'),
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-overworldHud'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-overworld-hud-composition'),
      ),
      findsOneWidget,
    );
    expect(find.text('Route des Brumes'), findsOneWidget);
    expect(find.textContaining('Rejoins le laboratoire'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-battleHud')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('personalization-battle-hud-composition'),
      ),
      findsOneWidget,
    );
    expect(find.text('BRINDIBOU'), findsOneWidget);
    expect(find.text('PV 42 / 55'), findsOneWidget);
    final battleNumbers = tester.widget<Text>(
      find.byKey(
        const ValueKey<String>('personalization-battle-numbers-sample'),
      ),
    );
    expect(battleNumbers.style?.fontFamily, 'Aurore Numbers');
  });

  testWidgets('PST-043 previews portrait intro poster and reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            intro: ProjectIntroVideoProfile.fromLandscape(
              videoPath: 'assets/presentation/intro/portrait.mp4',
              posterPath: 'assets/presentation/intro/portrait.png',
              durationMilliseconds: 12500,
              width: 1080,
              height: 1920,
              bitrateKbps: 2400,
              sizeBytes: 5000000,
              videoCodec: 'h264',
              reducedMotionBehavior: 'poster',
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-intro')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-intro-composition')),
      findsOneWidget,
    );
    expect(find.text('Portrait 9:16'), findsOneWidget);
    expect(find.text('Mouvement réduit : poster'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('personalization-intro-poster-fallback'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('PST-044 simulates viewport text scale and reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            intro: ProjectIntroVideoProfile.fromLandscape(
              videoPath: 'assets/presentation/intro/intro.mp4',
              posterPath: 'assets/presentation/intro/poster.png',
              durationMilliseconds: 12500,
              width: 1920,
              height: 1080,
              bitrateKbps: 2400,
              sizeBytes: 5000000,
              videoCodec: 'h264',
              reducedMotionBehavior: 'skip',
            ),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-viewport-portrait'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>(
          'personalization-preview-viewport-frame-portrait',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-150'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Texte 150 %'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-reduced-motion'),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('personalization-preview-intro')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mouvement réduit actif'), findsOneWidget);
    expect(
      find.text('Intro ignorée avec les animations réduites'),
      findsOneWidget,
    );
  });

  testWidgets('PST-045 compares baseline and draft with identical simulation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          baselineProfile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(layoutVariant: 'standard'),
            theme: safeProjectSemanticTheme,
          ),
          profile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(layoutVariant: 'centered'),
            theme: safeProjectSemanticTheme,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('personalization-preview-compare')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-viewport-portrait'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-text-scale-150'),
      ),
    );
    await tester.pump();
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
    expect(find.text('Avant'), findsOneWidget);
    expect(find.text('Maintenant'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('branding-title-preview-layout-standard'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('branding-title-preview-layout-centered'),
      ),
      findsOneWidget,
    );
    expect(find.text('Texte 150 %'), findsOneWidget);
  });

  testWidgets('PST-045 hides comparison when the draft is unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          baselineProfile: ProjectPresentationProfile(
            theme: safeProjectSemanticTheme,
          ),
          profile: ProjectPresentationProfile(theme: safeProjectSemanticTheme),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('personalization-preview-compare')),
      findsNothing,
    );
  });

  testWidgets('title motion follows the reduced-motion simulation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
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
          ),
        ),
      ),
    );

    expect(find.text('Animation du titre active'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preview-reduced-motion'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Titre statique — mouvement réduit'), findsOneWidget);
    expect(find.text('Animation du titre active'), findsNothing);
  });

  testWidgets('surface navigation is semantic and keyboard operable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(theme: safeProjectSemanticTheme),
        ),
      ),
    );

    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('personalization-preview-title')),
      ),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-intro-composition')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-title-composition')),
      findsOneWidget,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('personalization-intro-composition')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
