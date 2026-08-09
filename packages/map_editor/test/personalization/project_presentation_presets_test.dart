import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

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
      theme: safeProjectSemanticTheme,
    );

    final updated = resetProjectPresentationCategory(
      current,
      ProjectPresentationCategory.branding,
    );

    expect(updated.branding, const ProjectBrandingProfile());
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
        preview.surface(PersonalizationPreviewSurface.battleHud).backgroundHex,
        safeProjectSemanticTheme.battleHudSurface,
      );
      expect(preview.titleLayoutVariant, 'cinematic');
      expect(comparison.changedPaths, contains(r'$.branding.layoutVariant'));
      expect(comparison.changedPaths, contains(r'$.theme'));
    },
  );
}
