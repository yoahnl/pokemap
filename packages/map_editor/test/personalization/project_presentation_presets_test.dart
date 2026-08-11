import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

const _titleMotion = ProjectTitleMotionProfile(
  promptLoop: ProjectResponsiveVideoProfile(
    landscape: ProjectVideoVariantProfile(
      videoPath: 'assets/presentation/title/prompt.mp4',
      posterPath: 'assets/presentation/title/prompt.webp',
      durationMilliseconds: 4000,
      width: 1280,
      height: 720,
      bitrateKbps: 2400,
      sizeBytes: 4096,
      videoCodec: 'h264',
    ),
  ),
);

const _pause = ProjectPausePresentationProfile(
  title: 'Escale',
  actions: <ProjectPauseActionProfile>[
    ProjectPauseActionProfile(
      id: ProjectPauseActionId.resume,
      label: 'Repartir',
      icon: ProjectPauseActionIcon.play,
    ),
  ],
);

void main() {
  test('applies one preset section without replacing unrelated authoring', () {
    final intro = ProjectIntroVideoProfile.fromLandscape(
      videoPath: 'presentation/intro.mp4',
      durationMilliseconds: 1000,
      width: 1280,
      height: 720,
      bitrateKbps: 1000,
      sizeBytes: 1000,
      videoCodec: 'h264',
    );
    final current = ProjectPresentationProfile(intro: intro);

    final updated = cinematicPresentationPreset.apply(
      current,
      ProjectPresentationCategory.branding,
    );

    expect(updated.branding.layoutVariant, 'cinematic');
    expect(updated.intro, intro);
  });

  test('resets only the selected section', () {
    const current = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(layoutVariant: 'centered'),
      title: ProjectTitlePresentationProfile(title: 'Titre personnalisé'),
      theme: safeProjectSemanticTheme,
    );

    final updated = resetProjectPresentationCategory(
      current,
      ProjectPresentationCategory.branding,
    );

    expect(updated.branding, const ProjectBrandingProfile());
    expect(updated.title, isNull);
    expect(updated.theme, safeProjectSemanticTheme);
  });

  test(
    'preview and comparison project the canonical presentation contract',
    () {
      const baseline = ProjectPresentationProfile();
      const current = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
        theme: safeProjectSemanticTheme,
      );
      final preview = PersonalizationPreviewProjection(current);
      final comparison = compareProjectPresentation(baseline, current);

      expect(
        preview.surface(PersonalizationStudioScene.battle).backgroundHex,
        safeProjectSemanticTheme.battleHudSurface,
      );
      expect(preview.titleLayoutVariant, 'cinematic');
      expect(comparison.changedPaths, contains(r'$.branding.layoutVariant'));
      expect(comparison.changedPaths, contains(r'$.theme'));
    },
  );

  test('comparison detects pause action changes', () {
    const baseline = ProjectPresentationProfile();
    const current = ProjectPresentationProfile(pause: _pause);

    final comparison = compareProjectPresentation(baseline, current);

    expect(comparison.changedPaths, contains(r'$.pause'));
  });

  test('comparison detects title motion changes', () {
    const baseline = ProjectPresentationProfile();
    const current = ProjectPresentationProfile(titleMotion: _titleMotion);

    final comparison = compareProjectPresentation(baseline, current);

    expect(comparison.changedPaths, contains(r'$.titleMotion'));
  });

  test('comparison detects title copy changes', () {
    const baseline = ProjectPresentationProfile();
    const current = ProjectPresentationProfile(
      title: ProjectTitlePresentationProfile(title: 'Titre personnalisé'),
    );

    final comparison = compareProjectPresentation(baseline, current);

    expect(comparison.changedPaths, contains(r'$.title'));
  });

  test('comparison detects authored window changes', () {
    const baseline = ProjectPresentationProfile();
    const current = ProjectPresentationProfile(
      windows: legacyProjectPresentationWindows,
    );

    final comparison = compareProjectPresentation(baseline, current);

    expect(comparison.changedPaths, contains(r'$.windows'));
  });

  test('comparison detects menu label and surface palette changes', () {
    const baseline = ProjectPresentationProfile();
    const current = ProjectPresentationProfile(
      menuLabels: ProjectMenuLabelsProfile(pokedex: 'Carnet'),
      surfacePalettes: ProjectPresentationSurfacePalettesProfile(
        dialogue: ProjectSurfacePaletteProfile(surface: '#FFFFFF'),
      ),
    );

    final comparison = compareProjectPresentation(baseline, current);

    expect(comparison.changedPaths, contains(r'$.menuLabels'));
    expect(comparison.changedPaths, contains(r'$.surfacePalettes'));
  });

  test('branding preset replaces branding and title motion together', () {
    const preset = ProjectPresentationPreset(
      id: 'animated-branding',
      label: 'Titre animé',
      description: 'Identité et mouvement du titre.',
      profile: ProjectPresentationProfile(
        branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
        titleMotion: _titleMotion,
      ),
      categories: <ProjectPresentationCategory>{
        ProjectPresentationCategory.branding,
      },
    );
    final intro = ProjectIntroVideoProfile.fromLandscape(
      videoPath: 'assets/presentation/intro.mp4',
      durationMilliseconds: 1000,
      width: 1280,
      height: 720,
      bitrateKbps: 1000,
      sizeBytes: 1000,
      videoCodec: 'h264',
    );
    final current = ProjectPresentationProfile(intro: intro);

    final updated = preset.apply(current, ProjectPresentationCategory.branding);

    expect(
      updated.branding,
      const ProjectBrandingProfile(layoutVariant: 'cinematic'),
    );
    expect(updated.titleMotion, _titleMotion);
    expect(updated.intro, intro);
  });

  test('branding reset clears branding and title motion together', () {
    const current = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
      titleMotion: _titleMotion,
      theme: safeProjectSemanticTheme,
      pause: _pause,
    );

    final updated = resetProjectPresentationCategory(
      current,
      ProjectPresentationCategory.branding,
    );

    expect(updated.branding, const ProjectBrandingProfile());
    expect(updated.titleMotion, isNull);
    expect(updated.theme, safeProjectSemanticTheme);
    expect(updated.pause, _pause);
  });

  test('interface preset replaces theme and pause actions together', () {
    const preset = ProjectPresentationPreset(
      id: 'interface-copy',
      label: 'Interface ferroviaire',
      description: 'Palette et libellés du menu.',
      profile: ProjectPresentationProfile(
        theme: safeProjectSemanticTheme,
        pause: _pause,
        windows: legacyProjectPresentationWindows,
      ),
      categories: <ProjectPresentationCategory>{
        ProjectPresentationCategory.theme,
      },
    );
    const current = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
      titleMotion: _titleMotion,
    );

    final updated = preset.apply(current, ProjectPresentationCategory.theme);

    expect(updated.theme, safeProjectSemanticTheme);
    expect(updated.pause, _pause);
    expect(updated.windows, legacyProjectPresentationWindows);
    expect(
      updated.branding,
      const ProjectBrandingProfile(layoutVariant: 'cinematic'),
    );
    expect(updated.titleMotion, _titleMotion);
  });

  test('interface reset clears theme and pause actions together', () {
    const current = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
      titleMotion: _titleMotion,
      theme: safeProjectSemanticTheme,
      pause: _pause,
      windows: legacyProjectPresentationWindows,
    );

    final updated = resetProjectPresentationCategory(
      current,
      ProjectPresentationCategory.theme,
    );

    expect(updated.theme, isNull);
    expect(updated.pause, isNull);
    expect(updated.windows, isNull);
    expect(
      updated.branding,
      const ProjectBrandingProfile(layoutVariant: 'cinematic'),
    );
    expect(updated.titleMotion, _titleMotion);
  });
}
