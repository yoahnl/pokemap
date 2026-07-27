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

  testWidgets('PST-041 composes dialogue and menu runtime surfaces',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            typography: ProjectTypographyProfile(
              body: ProjectTypographyRoleProfile(family: 'Aurore Body'),
              dialogue: ProjectTypographyRoleProfile(
                family: 'Aurore Dialogue',
              ),
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
    expect(find.text('ÉQUIPE'), findsOneWidget);
    expect(find.text('SAC'), findsOneWidget);
    final menuText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('personalization-menu-sample-text')),
    );
    expect(menuText.style?.fontFamily, 'Aurore Body');
  });

  testWidgets('PST-042 composes overworld and battle HUD surfaces',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            typography: ProjectTypographyProfile(
              body: ProjectTypographyRoleProfile(family: 'Aurore Body'),
              numbers: ProjectTypographyRoleProfile(
                family: 'Aurore Numbers',
              ),
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
      find.byKey(
        const ValueKey<String>('personalization-preview-battleHud'),
      ),
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

  testWidgets('PST-043 previews portrait intro poster and reduced motion',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            intro: ProjectIntroVideoProfile(
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
      find.byKey(
        const ValueKey<String>('personalization-intro-composition'),
      ),
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

  testWidgets('PST-044 simulates viewport text scale and reduced motion',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationRuntimePreview(
          projectName: 'Pokémon Aurore',
          projectRootPath: '',
          profile: ProjectPresentationProfile(
            intro: ProjectIntroVideoProfile(
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
        const ValueKey<String>(
          'personalization-preview-viewport-portrait',
        ),
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
}

Widget _app(Widget child) => MaterialApp(
      theme: PokeMapTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
