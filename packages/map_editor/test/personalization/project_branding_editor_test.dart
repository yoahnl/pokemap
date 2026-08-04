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
    expect(find.textContaining('carrée, de 64 × 64'), findsOneWidget);
    expect(find.textContaining('minimum 640 × 360'), findsOneWidget);
    expect(find.textContaining('minimum 256 × 128'), findsOneWidget);
    for (final role in ProjectBrandingImageRole.values) {
      await tester.ensureVisible(
        find.byKey(ValueKey<String>('branding-import-${role.name}')),
      );
      await tester.pumpAndSettle();
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

  testWidgets('edits accent and title layout through guided controls',
      (tester) async {
    var editAccentCount = 0;
    var resetAccentCount = 0;
    String? selectedLayout;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectBrandingEditor(
              profile: const ProjectBrandingProfile(
                accentColor: '#123456',
                layoutVariant: 'centered',
              ),
              onImportImage: (_) {},
              onRemoveImage: (_) {},
              onEditAccent: () => editAccentCount += 1,
              onResetAccent: () => resetAccentCount += 1,
              onLayoutVariantChanged: (value) => selectedLayout = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('#123456'), findsOneWidget);
    expect(find.text('Couleur de cartouche Avelune et accent'), findsOneWidget);
    expect(
      find.textContaining('teinte la coque de la cartouche'),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('branding-edit-accent')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('branding-edit-accent')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('branding-reset-accent')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('branding-layout')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('branding-layout')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cinématique').last);
    await tester.pumpAndSettle();

    expect(editAccentCount, 1);
    expect(resetAccentCount, 1);
    expect(selectedLayout, 'cinematic');
  });

  testWidgets('imports, previews, and removes title music', (tester) async {
    var importCount = 0;
    var previewCount = 0;
    var removeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectBrandingEditor(
              profile: const ProjectBrandingProfile(
                titleMusicPath: 'assets/presentation/branding/title-music.ogg',
              ),
              onImportImage: (_) {},
              onRemoveImage: (_) {},
              onImportTitleMusic: () => importCount += 1,
              onToggleTitleMusicPreview: () => previewCount += 1,
              onRemoveTitleMusic: () => removeCount += 1,
              isTitleMusicPreviewPlaying: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Musique du titre'), findsOneWidget);
    expect(find.text('Arrêter'), findsOneWidget);
    expect(find.textContaining('30 Mio maximum'), findsOneWidget);
    for (final key in <String>[
      'branding-import-title-music',
      'branding-preview-title-music',
      'branding-remove-title-music',
    ]) {
      final finder = find.byKey(ValueKey<String>(key));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
    }

    expect(importCount, 1);
    expect(previewCount, 1);
    expect(removeCount, 1);
  });
}
