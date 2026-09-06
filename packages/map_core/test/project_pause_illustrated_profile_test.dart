import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const background = ProjectPauseBackgroundProfile(
    imagePath: 'assets/menu/night.png',
    focalX: .8,
    focalY: .2,
    sampling: ProjectMenuImageSampling.pixelArt,
  );
  test('illustrated preset preserves authored content and overrides', () {
    const source = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(heroPath: 'assets/title.png'),
      menuLabels: ProjectMenuLabelsProfile(bag: 'Inventaire'),
      pause: ProjectPausePresentationProfile(
        title: 'Voyage',
        hint: 'Continuer',
        background: background,
        composition: ProjectResponsivePauseCompositionProfile(),
        actions: [
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.resume,
            label: 'Poursuivre',
          ),
          ProjectPauseActionProfile(
            id: ProjectPauseActionId.bag,
            visible: false,
          ),
        ],
      ),
    );
    final result = applyNightIllustratedPresentationPreset(source);
    expect(
      result,
      source.copyWith(
        pause: source.pause!.copyWith(
          style: ProjectPauseMenuStyle.nightIllustrated,
        ),
      ),
    );
    expect(
      ProjectPresentationProfile.fromJson(result.toJson()),
      result.copyWith(menuLabels: null),
    );
    expect(validateProjectPresentationProfile(result), isEmpty);
  });
  test('no background is valid and generic preset imposes no branding', () {
    final result = applyNightIllustratedPresentationPreset(
      const ProjectPresentationProfile(),
    );
    expect(result.branding, const ProjectBrandingProfile());
    expect(result.pause!.background, isNull);
    for (final breakpoint in ProjectPresentationBreakpoint.values) {
      expect(
        result.pause!.composition!.resolve(breakpoint).showRootDetailPanel,
        isFalse,
      );
    }
    expect(validateProjectPresentationProfile(result), isEmpty);
  });
  test('unsafe images and nonfinite focal positions are rejected', () {
    for (final path in [
      '/Users/private/image.png',
      '../image.png',
      'https://example.com/image.png',
    ]) {
      final profile = ProjectPresentationProfile(
        pause: ProjectPausePresentationProfile(
          background: background.copyWith(imagePath: path),
        ),
      );
      expect(
        validateProjectPresentationProfile(profile).map((e) => e.code),
        contains('presentationAssetPathUnsafe'),
      );
    }
    for (final focal in [-.1, 1.1, double.nan, double.infinity]) {
      final profile = ProjectPresentationProfile(
        pause: ProjectPausePresentationProfile(
          background: background.copyWith(focalX: focal),
        ),
      );
      expect(
        validateProjectPresentationProfile(profile).map((e) => e.code),
        contains('pauseBackgroundFocalInvalid'),
      );
    }
  });
  test('unknown styles and sampling are rejected', () {
    expect(
      () => ProjectPausePresentationProfile.fromJson({'style': 'unknown'}),
      throwsArgumentError,
    );
    expect(
      () => ProjectPauseBackgroundProfile.fromJson({
        'imagePath': 'assets/image.png',
        'sampling': 'unknown',
      }),
      throwsArgumentError,
    );
  });
  test('optional illustrated fields round trip in the current schema', () {
    final json = const ProjectPresentationProfile(
      pause: ProjectPausePresentationProfile(background: background),
    ).toJson();
    json['schemaVersion'] = 10;
    expect(
      ProjectPresentationProfile.fromJson(json).pause!.background,
      background,
    );
    final legacy = ProjectPresentationProfile.fromJson({
      'schemaVersion': 10,
      'branding': <String, dynamic>{},
    });
    expect(legacy.pause, isNull);
    expect(validateProjectPresentationProfile(legacy), isEmpty);
  });
}
