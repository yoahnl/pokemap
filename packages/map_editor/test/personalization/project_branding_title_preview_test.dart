import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('renders project-owned branding assets and selected layout',
      (tester) async {
    final root = Directory.systemTemp.createTempSync('branding-title-preview-');
    addTearDown(() => root.deleteSync(recursive: true));
    final assets = Directory(
      '${root.path}/assets/presentation/branding',
    )..createSync(recursive: true);
    for (final name in <String>['icon', 'cover', 'hero']) {
      File('${assets.path}/$name.png').writeAsBytesSync(
        image.encodePng(image.Image(width: 16, height: 16)),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: ProjectBrandingTitlePreview(
            projectName: 'Pokémon Aurore',
            projectRootPath: root.path,
            branding: const ProjectBrandingProfile(
              iconPath: 'assets/presentation/branding/icon.png',
              coverPath: 'assets/presentation/branding/cover.png',
              heroPath: 'assets/presentation/branding/hero.png',
              accentColor: '#224466',
              layoutVariant: 'cinematic',
            ),
            theme: safeProjectSemanticTheme,
            typography: const ProjectTypographyProfile(
              display: ProjectTypographyRoleProfile(
                family: 'Aurore Display',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('branding-title-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('branding-title-preview-layout-cinematic'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('branding-title-preview-cover')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('branding-title-preview-hero')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('branding-title-preview-icon')),
      findsOneWidget,
    );
    expect(find.text('Pokémon Aurore'), findsOneWidget);
  });

  testWidgets('falls back safely and reacts to a new layout', (tester) async {
    final root =
        Directory.systemTemp.createTempSync('branding-title-fallback-');
    addTearDown(() => root.deleteSync(recursive: true));

    Future<void> pump(String layout) => tester.pumpWidget(
          MaterialApp(
            theme: PokeMapTheme.dark(),
            home: Scaffold(
              body: ProjectBrandingTitlePreview(
                projectName: 'Projet sans assets',
                projectRootPath: root.path,
                branding: ProjectBrandingProfile(
                  coverPath: '../outside.png',
                  heroPath: 'assets/missing.png',
                  accentColor: 'invalid',
                  layoutVariant: layout,
                ),
                theme: safeProjectSemanticTheme,
              ),
            ),
          ),
        );

    await pump('centered');
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey<String>('branding-title-preview-layout-centered'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('branding-title-preview-cover-fallback'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('branding-title-preview-hero-fallback'),
      ),
      findsOneWidget,
    );

    await pump('standard');
    await tester.pumpAndSettle();
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
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
