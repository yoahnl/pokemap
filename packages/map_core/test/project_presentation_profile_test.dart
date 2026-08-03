import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPresentationProfile', () {
    test('round-trips the versioned branding contract', () {
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(
          iconPath: 'assets/presentation/icon.png',
          coverPath: 'assets/presentation/cover.png',
          heroPath: 'assets/presentation/hero.png',
          accentColor: '#6750A4',
          titleMusicPath: 'assets/audio/title.ogg',
          layoutVariant: 'cinematic',
        ),
      );

      expect(
        ProjectPresentationProfile.fromJson(profile.toJson()),
        profile,
      );
      expect(profile.configuredCategories, {
        ProjectPresentationCategory.branding,
      });
      expect(validateProjectPresentationProfile(profile), isEmpty);
    });

    test('reports shared diagnostics for unsafe or unsupported values', () {
      const profile = ProjectPresentationProfile(
        schemaVersion: 99,
        branding: ProjectBrandingProfile(
          iconPath: '../outside.png',
          accentColor: 'purple',
          layoutVariant: 'floating',
        ),
      );

      expect(
        validateProjectPresentationProfile(profile)
            .map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'presentationVersionUnsupported',
          'presentationAssetPathUnsafe',
          'presentationAccentColorInvalid',
          'presentationLayoutUnsupported',
        ]),
      );
    });

    test('legacy project JSON remains valid and receives safe defaults', () {
      final manifest = ProjectManifest.fromJson(<String, dynamic>{
        'name': 'Legacy game',
        'version': 'v6',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
      });

      expect(manifest.presentation, isNull);
      expect(
        manifest.effectivePresentation,
        const ProjectPresentationProfile(),
      );
      expect(manifest.toJson(), isNot(contains('presentation')));
    });

    test('project manifest owns and serializes authored presentation', () {
      const presentation = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(
          accentColor: '#123456',
          layoutVariant: 'centered',
        ),
      );
      final manifest = ProjectManifest(
        name: 'Personalized game',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        presentation: presentation,
      );

      final json = manifest.toJson();

      expect(
        ProjectManifest.fromJson(json).presentation,
        presentation,
      );
      expect(json['presentation'], presentation.toJson());
    });

    test('valid intro video metadata joins the semantic contract', () {
      const profile = ProjectPresentationProfile(
        intro: ProjectIntroVideoProfile(
          videoPath: 'assets/presentation/intro/intro.mp4',
          posterPath: 'assets/presentation/intro/poster.png',
          captionsPath: 'assets/presentation/intro/captions.vtt',
          durationMilliseconds: 32000,
          width: 1920,
          height: 1080,
          bitrateKbps: 8000,
          sizeBytes: 32000000,
          videoCodec: 'h264',
          audioCodec: 'aac',
        ),
      );

      expect(validateProjectPresentationProfile(profile), isEmpty);
      expect(
        profile.configuredCategories,
        contains(ProjectPresentationCategory.intro),
      );
      expect(
        ProjectPresentationProfile.fromJson(profile.toJson()),
        profile,
      );
    });

    test('accepts intro videos in landscape and portrait orientations', () {
      ProjectPresentationProfile profileFor({
        required int width,
        required int height,
      }) =>
          ProjectPresentationProfile(
            intro: ProjectIntroVideoProfile(
              videoPath: 'assets/presentation/intro/intro.mp4',
              posterPath: 'assets/presentation/intro/poster.png',
              durationMilliseconds: 12000,
              width: width,
              height: height,
              bitrateKbps: 2400,
              sizeBytes: 5000000,
              videoCodec: 'h264',
            ),
          );

      expect(
        validateProjectPresentationProfile(
          profileFor(width: 1920, height: 1080),
        ),
        isEmpty,
      );
      expect(
        validateProjectPresentationProfile(
          profileFor(width: 1080, height: 1920),
        ),
        isEmpty,
      );
    });

    test('intro video limits and fallback poster fail closed', () {
      const profile = ProjectPresentationProfile(
        intro: ProjectIntroVideoProfile(
          videoPath: 'assets/presentation/intro/intro.mov',
          durationMilliseconds: 130000,
          width: 3840,
          height: 2160,
          bitrateKbps: 24000,
          sizeBytes: 150000000,
          videoCodec: 'hevc',
          audioCodec: 'aac',
        ),
      );

      expect(
        validateProjectPresentationProfile(profile)
            .map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'introPosterRequired',
          'introContainerUnsupported',
          'introDurationExceeded',
          'introResolutionExceeded',
          'introBitrateExceeded',
          'introSizeExceeded',
          'introVideoCodecUnsupported',
        ]),
      );
    });

    test('round-trips explicit typography roles and redistribution evidence',
        () {
      const profile = ProjectPresentationProfile(
        typography: ProjectTypographyProfile(
          display: ProjectTypographyRoleProfile(
            fontPath: 'assets/presentation/fonts/display.ttf',
            family: 'Aube Display',
            licensePath: 'assets/presentation/fonts/display-license.txt',
            redistributable: true,
            fallbackFamilies: <String>['sans-serif'],
            glyphCoverage: <String>[
              'latin',
              'latinExtended',
              'digits',
              'punctuation',
            ],
          ),
        ),
      );

      expect(validateProjectPresentationProfile(profile), isEmpty);
      expect(
        profile.configuredCategories,
        contains(ProjectPresentationCategory.typography),
      );
      expect(ProjectPresentationProfile.fromJson(profile.toJson()), profile);
    });

    test('custom fonts require license, redistribution, fallback and glyphs',
        () {
      const profile = ProjectPresentationProfile(
        typography: ProjectTypographyProfile(
          display: ProjectTypographyRoleProfile(
            fontPath: '../display.woff',
            family: '',
            fallbackFamilies: <String>[],
            glyphCoverage: <String>['latin'],
          ),
        ),
      );

      expect(
        validateProjectPresentationProfile(profile)
            .map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'presentationAssetPathUnsafe',
          'typographyFormatUnsupported',
          'typographyFamilyRequired',
          'typographyLicenseRequired',
          'typographyRedistributionRequired',
          'typographyFallbackRequired',
          'typographyGlyphCoverageIncomplete',
        ]),
      );
    });

    test('round-trips a semantic theme for every player surface', () {
      const profile = ProjectPresentationProfile(
        theme: ProjectSemanticThemeProfile(
          primary: '#003A44',
          onPrimary: '#FFFFFF',
          background: '#F4F7FB',
          surface: '#FFFFFF',
          surfaceElevated: '#EAF0F8',
          textPrimary: '#101827',
          textSecondary: '#526176',
          outline: '#65758B',
          success: '#16794B',
          warning: '#8A5100',
          danger: '#B4233C',
          titleSurface: '#D9F4F6',
          dialogueSurface: '#FFFFFF',
          menuSurface: '#EAF0F8',
          overworldHudSurface: '#FFFFFF',
          battleHudSurface: '#FFFFFF',
        ),
      );

      expect(validateProjectPresentationProfile(profile), isEmpty);
      expect(
        profile.configuredCategories,
        contains(ProjectPresentationCategory.theme),
      );
      expect(ProjectPresentationProfile.fromJson(profile.toJson()), profile);
    });

    test('semantic theme rejects malformed colors and unreadable text', () {
      const profile = ProjectPresentationProfile(
        theme: ProjectSemanticThemeProfile(
          primary: '#EEEEEE',
          onPrimary: '#FFFFFF',
          background: '#FFFFFF',
          surface: '#FFFFFF',
          surfaceElevated: '#FFFFFF',
          textPrimary: '#F8F8F8',
          textSecondary: '#GGGGGG',
          outline: '#FFFFFF',
          success: '#FFFFFF',
          warning: '#FFFFFF',
          danger: '#FFFFFF',
          titleSurface: '#FFFFFF',
          dialogueSurface: '#FFFFFF',
          menuSurface: '#FFFFFF',
          overworldHudSurface: '#FFFFFF',
          battleHudSurface: '#FFFFFF',
        ),
      );

      expect(
        validateProjectPresentationProfile(profile)
            .map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'themeColorInvalid',
          'themeContrastInsufficient',
        ]),
      );
    });
  });
}
