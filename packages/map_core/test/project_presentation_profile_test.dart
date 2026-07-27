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
  });
}
