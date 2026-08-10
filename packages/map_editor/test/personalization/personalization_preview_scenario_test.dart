import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test('comparison follows the current baseline and draft profiles', () {
    const baseline = ProjectPresentationProfile();
    const changed = ProjectPresentationProfile(
      menuLabels: ProjectMenuLabelsProfile(pokedex: 'Carnet'),
    );

    const unchangedScenario = PersonalizationPreviewScenario(
      draftProfile: baseline,
      baselineProfile: baseline,
      surface: PersonalizationPreviewSurface.menu,
    );
    const changedScenario = PersonalizationPreviewScenario(
      draftProfile: changed,
      baselineProfile: baseline,
      surface: PersonalizationPreviewSurface.menu,
      comparisonEnabled: true,
    );

    expect(unchangedScenario.canCompare, isFalse);
    expect(unchangedScenario.showComparison, isFalse);
    expect(changedScenario.canCompare, isTrue);
    expect(changedScenario.showComparison, isTrue);
  });

  test('simulation changes preserve the authored profiles', () {
    const draft = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
    );
    const scenario = PersonalizationPreviewScenario(
      draftProfile: draft,
      surface: PersonalizationPreviewSurface.title,
    );

    final changed = scenario.copyWith(
      viewport: PersonalizationPreviewViewport.portrait,
      textScale: 2,
      reducedMotion: true,
      comparisonEnabled: true,
    );

    expect(changed.draftProfile, same(draft));
    expect(changed.surface, PersonalizationPreviewSurface.title);
    expect(changed.viewport, PersonalizationPreviewViewport.portrait);
    expect(changed.textScale, 2);
    expect(changed.reducedMotion, isTrue);
  });

  test(
    'viewport scenarios carry deterministic logical sizes and safe areas',
    () {
      const profile = ProjectPresentationProfile();
      const portrait = PersonalizationPreviewScenario(
        draftProfile: profile,
        surface: PersonalizationPreviewSurface.title,
        viewport: PersonalizationPreviewViewport.portrait,
      );
      const landscape = PersonalizationPreviewScenario(
        draftProfile: profile,
        surface: PersonalizationPreviewSurface.menu,
        viewport: PersonalizationPreviewViewport.phoneLandscape,
      );

      expect(portrait.metrics.logicalWidth, 390);
      expect(portrait.metrics.logicalHeight, 844);
      expect(portrait.metrics.safeTop, 44);
      expect(portrait.metrics.safeBottom, 34);
      expect(landscape.metrics.logicalWidth, 844);
      expect(landscape.metrics.logicalHeight, 390);
      expect(landscape.metrics.safeLeft, 44);
      expect(landscape.metrics.safeBottom, 21);
    },
  );
}
