import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test('offers three complete presets for every editable scene', () {
    for (final scene in PersonalizationStudioScene.values) {
      final presets = personalizationScenePresetsFor(scene);
      expect(presets, hasLength(3), reason: scene.name);
      expect(
        presets.every((preset) => preset.replacedSections.isNotEmpty),
        isTrue,
      );
    }
  });

  test(
    'applies one scene preset transactionally and preserves other assets',
    () {
      const current = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(
          iconPath: 'assets/presentation/icon.png',
          heroPath: 'assets/presentation/hero.png',
        ),
        intro: ProjectIntroVideoProfile(
          media: ProjectResponsiveVideoProfile(
            landscape: ProjectVideoVariantProfile(
              videoPath: 'assets/presentation/intro.mp4',
              posterPath: 'assets/presentation/poster.png',
              durationMilliseconds: 1000,
              width: 1280,
              height: 720,
              bitrateKbps: 100,
              sizeBytes: 100,
              videoCodec: 'h264',
            ),
          ),
        ),
      );
      final preset = personalizationScenePresetsFor(
        PersonalizationStudioScene.dialogue,
      ).first;

      final transaction = preset.preview(current);

      expect(transaction.requiresConfirmation, isTrue);
      expect(transaction.profile.branding.iconPath, current.branding.iconPath);
      expect(transaction.profile.intro, current.intro);
      expect(transaction.removedAssetPaths, isEmpty);
      expect(transaction.replacedSections, preset.replacedSections);
    },
  );

  test('inherits global style without replacing scene-specific content', () {
    const current = ProjectPresentationProfile(
      typography: ProjectTypographyProfile(
        body: ProjectTypographyRoleProfile(family: 'Lisible'),
        dialogue: ProjectTypographyRoleProfile(family: 'Bulle'),
      ),
      dialogue: ProjectDialoguePresentationProfile(
        placement: ProjectDialoguePlacement.top,
      ),
      windows: legacyProjectPresentationWindows,
      surfacePalettes: ProjectPresentationSurfacePalettesProfile(
        dialogue: ProjectSurfacePaletteProfile(surface: '#112233'),
      ),
    );

    final next = copyGlobalStyleToScene(
      scene: PersonalizationStudioScene.dialogue,
      current: current,
    );

    expect(next.dialogue, current.dialogue);
    expect(next.surfacePalettes?.dialogue, isNull);
    expect(next.typography?.dialogue, current.typography?.body);
    expect(
      next.windows?.dialogueStyleId,
      legacyProjectPresentationWindows.defaultStyleId,
    );
  });

  test('reset local keeps shared assets and unrelated scene settings', () {
    final layouts = suggestedProjectPresentationLayouts('standard');
    final current = ProjectPresentationProfile(
      branding: const ProjectBrandingProfile(
        heroPath: 'assets/presentation/hero.png',
      ),
      dialogue: const ProjectDialoguePresentationProfile(
        placement: ProjectDialoguePlacement.top,
      ),
      layouts: layouts,
    );

    final next = resetPersonalizationScene(
      current,
      PersonalizationStudioScene.dialogue,
    );

    expect(next.dialogue, isNull);
    expect(next.branding.heroPath, current.branding.heroPath);
    expect(next.layouts?.title, layouts.title);
    expect(next.layouts?.pauseMenu, layouts.pauseMenu);
  });

  test('three presets of one scene produce three distinct profiles', () {
    for (final scene in PersonalizationStudioScene.values) {
      final source = scene == PersonalizationStudioScene.intro
          ? const ProjectPresentationProfile(
              intro: ProjectIntroVideoProfile(
                media: ProjectResponsiveVideoProfile(
                  landscape: ProjectVideoVariantProfile(
                    videoPath: 'assets/presentation/intro.mp4',
                    posterPath: 'assets/presentation/poster.png',
                    durationMilliseconds: 1000,
                    width: 1280,
                    height: 720,
                    bitrateKbps: 100,
                    sizeBytes: 100,
                    videoCodec: 'h264',
                  ),
                ),
              ),
            )
          : const ProjectPresentationProfile();
      final profiles = personalizationScenePresetsFor(
        scene,
      ).map((preset) => preset.apply(source).toJson()).toList();

      expect(
        profiles.map((profile) => profile.toString()).toSet(),
        hasLength(3),
        reason: scene.name,
      );
    }
  });
}
