import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPresentationProfile', () {
    test('round-trips combat typography and falls back to body', () {
      const body = ProjectTypographyRoleProfile(family: 'Body Family');
      const combat = ProjectTypographyRoleProfile(family: 'Combat Family');
      const explicit = ProjectPresentationProfile(
        typography: ProjectTypographyProfile(body: body, combat: combat),
      );
      const inherited = ProjectPresentationProfile(
        typography: ProjectTypographyProfile(body: body),
      );

      final decoded = ProjectPresentationProfile.fromJson(explicit.toJson());

      expect(decoded.schemaVersion, 6);
      expect(decoded.typography?.resolve(ProjectTypographyRole.combat), combat);
      expect(inherited.typography?.resolve(ProjectTypographyRole.combat), body);
    });

    test('does not smuggle V5 combat typography through schema V4', () {
      final source = const ProjectPresentationProfile(
        typography: ProjectTypographyProfile(
          combat: ProjectTypographyRoleProfile(family: 'Combat Family'),
        ),
      ).toJson()..['schemaVersion'] = 4;

      expect(
        () => ProjectPresentationProfile.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('migrates schema V4 without combat presentation fields', () {
      final profile = ProjectPresentationProfile.fromJson(<String, dynamic>{
        'schemaVersion': 4,
        'branding': <String, dynamic>{'layoutVariant': 'standard'},
        'typography': const ProjectTypographyProfile().toJson(),
      });

      expect(profile.schemaVersion, 6);
      expect(profile.typography?.combat, isNull);
      expect(profile.layouts, isNull);
      expect(profile.windows, isNull);
    });

    test('migrates V1 landscape intro before generated deserialization', () {
      final source = jsonDecode(
        File(
          'test/fixtures/project_presentation/v1_landscape.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;

      final profile = ProjectPresentationProfile.fromJson(source);

      expect(profile.schemaVersion, 6);
      expect(profile.intro!.media.landscape.videoPath,
          'assets/presentation/intro/landscape.mp4');
      expect(profile.intro!.media.landscape.focalX, 0.5);
      expect(profile.intro!.media.portrait, isNull);
      expect(profile.titleMotion, isNull);
      final encoded = profile.toJson();
      expect(encoded['schemaVersion'], 6);
      expect((encoded['intro']! as Map<String, dynamic>), contains('media'));
      expect((encoded['intro']! as Map<String, dynamic>),
          isNot(contains('videoPath')));
    });

    test('round-trips V2 landscape-only and responsive title motion fixtures',
        () {
      for (final fixture in <String>[
        'v2_landscape_only.json',
        'v2_landscape_portrait.json',
      ]) {
        final source = jsonDecode(
          File('test/fixtures/project_presentation/$fixture')
              .readAsStringSync(),
        ) as Map<String, dynamic>;
        final profile = ProjectPresentationProfile.fromJson(source);

        expect(ProjectPresentationProfile.fromJson(profile.toJson()), profile,
            reason: fixture);
        expect(validateProjectPresentationProfile(profile), isEmpty,
            reason: fixture);
      }
    });

    test('validates focal points, loop audio and combined responsive budgets',
        () {
      ProjectVideoVariantProfile variant({
        String video = 'assets/presentation/title/loop.mp4',
        String poster = 'assets/presentation/title/loop.png',
        int duration = 16000,
        int size = 60 * 1024 * 1024,
        String audio = 'aac',
        double focalX = 1.2,
      }) =>
          ProjectVideoVariantProfile(
            videoPath: video,
            posterPath: poster,
            durationMilliseconds: duration,
            width: 1920,
            height: 1080,
            bitrateKbps: 4000,
            sizeBytes: size,
            videoCodec: 'h264',
            audioCodec: audio,
            focalX: focalX,
          );
      final profile = ProjectPresentationProfile(
        titleMotion: ProjectTitleMotionProfile(
          promptLoop: ProjectResponsiveVideoProfile(
            landscape: variant(),
            portrait: variant(
              video: 'assets/presentation/title/portrait.mp4',
              poster: 'assets/presentation/title/portrait.png',
            ),
          ),
        ),
      );

      expect(
        validateProjectPresentationProfile(profile)
            .map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'presentationFocalPointInvalid',
          'titleLoopDurationExceeded',
          'titleLoopSizeExceeded',
          'titleLoopAudioForbidden',
          'titleMotionCombinedSizeExceeded',
        ]),
      );
    });

    test('ProjectValidator rejects blocking presentation diagnostics', () {
      final manifest = ProjectManifest(
        name: 'Invalid presentation',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        presentation: ProjectPresentationProfile(
          titleMotion: ProjectTitleMotionProfile(
            promptLoop: ProjectResponsiveVideoProfile(
              landscape: ProjectVideoVariantProfile(
                videoPath: '../outside.mp4',
                posterPath: 'assets/presentation/title/poster.png',
                durationMilliseconds: 5000,
                width: 1920,
                height: 1080,
                bitrateKbps: 2000,
                sizeBytes: 1000000,
                videoCodec: 'h264',
                audioCodec: 'none',
              ),
            ),
          ),
        ),
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'presentationAssetPathUnsafe',
          ),
        ),
      );
    });

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

    test('round-trips project-owned pause menu label overrides', () {
      const profile = ProjectPresentationProfile(
        menuLabels: ProjectMenuLabelsProfile(
          pauseTitle: 'Interruption',
          resume: 'Continuer',
          party: 'Compagnons',
          bag: 'Inventaire',
          pokedex: 'Carnet de voyage',
          map: 'Région',
          save: 'Mémoriser',
          options: 'Réglages',
          returnToTitle: 'Quitter la partie',
        ),
      );

      expect(ProjectPresentationProfile.fromJson(profile.toJson()), profile);
      expect(
        profile.configuredCategories,
        contains(ProjectPresentationCategory.theme),
      );
      expect(validateProjectPresentationProfile(profile), isEmpty);
    });

    test('rejects empty, oversized and control-character menu labels', () {
      final profile = ProjectPresentationProfile(
        menuLabels: ProjectMenuLabelsProfile(
          resume: List<String>.filled(33, 'a').join(),
          pokedex: '   ',
          options: 'Options\navancées',
        ),
      );

      expect(
        validateProjectPresentationProfile(profile)
            .map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'menuLabelTooLong',
          'menuLabelEmpty',
          'menuLabelContainsControlCharacters',
        ]),
      );
    });

    test('accepts canonical RGB and RGBA hexadecimal accent colors', () {
      for (final accentColor in <String>['#126E78', '#126E78CC']) {
        final profile = ProjectPresentationProfile(
          branding: ProjectBrandingProfile(accentColor: accentColor),
        );

        expect(
          validateProjectPresentationProfile(profile),
          isEmpty,
          reason: accentColor,
        );
      }
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
          media: ProjectResponsiveVideoProfile(
            landscape: ProjectVideoVariantProfile(
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
          ),
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

    test('accepts landscape and optional portrait intro variants', () {
      const profile = ProjectPresentationProfile(
        intro: ProjectIntroVideoProfile(
          media: ProjectResponsiveVideoProfile(
            landscape: ProjectVideoVariantProfile(
              videoPath: 'assets/presentation/intro/intro.mp4',
              posterPath: 'assets/presentation/intro/poster.png',
              durationMilliseconds: 12000,
              width: 1920,
              height: 1080,
              bitrateKbps: 2400,
              sizeBytes: 5000000,
              videoCodec: 'h264',
            ),
            portrait: ProjectVideoVariantProfile(
              videoPath: 'assets/presentation/intro/intro-portrait.mp4',
              posterPath: 'assets/presentation/intro/poster-portrait.png',
              durationMilliseconds: 12000,
              width: 1080,
              height: 1920,
              bitrateKbps: 2400,
              sizeBytes: 5000000,
              videoCodec: 'h264',
            ),
          ),
        ),
      );

      expect(validateProjectPresentationProfile(profile), isEmpty);
    });

    test('intro video limits and fallback poster fail closed', () {
      const profile = ProjectPresentationProfile(
        intro: ProjectIntroVideoProfile(
          media: ProjectResponsiveVideoProfile(
            landscape: ProjectVideoVariantProfile(
              videoPath: 'assets/presentation/intro/intro.mov',
              posterPath: '',
              durationMilliseconds: 130000,
              width: 3840,
              height: 2160,
              bitrateKbps: 24000,
              sizeBytes: 150000000,
              videoCodec: 'hevc',
              audioCodec: 'aac',
            ),
          ),
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
