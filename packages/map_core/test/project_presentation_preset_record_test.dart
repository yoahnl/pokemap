import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('roundtrips project-owned presentation preset records', () {
    final manifest = ProjectManifest(
      name: 'Preset library',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationPresets: const <ProjectPresentationPresetRecord>[
        ProjectPresentationPresetRecord(
          id: 'night-train',
          label: 'Train de nuit',
          description: 'Présentation sombre et cinématique.',
          profile: ProjectPresentationProfile(
            branding: ProjectBrandingProfile(layoutVariant: 'cinematic'),
          ),
          assets: <ProjectPresentationPresetAssetReference>[
            ProjectPresentationPresetAssetReference(
              projectPath: 'assets/presentation/icon.png',
              mediaType: 'image/png',
              sizeBytes: 4,
              sha256:
                  '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
              licenseProjectPath: 'assets/presentation/icon-license.txt',
            ),
          ],
        ),
      ],
    );

    final decoded = ProjectManifest.fromJsonPokeMapBetaV1ForTest(
      manifest.toJson(),
    );

    expect(decoded.presentationPresets, manifest.presentationPresets);
    expect(
      decoded.presentationPresets.single.configuredCategories,
      <ProjectPresentationCategory>[ProjectPresentationCategory.branding],
    );
  });

  test('rejects duplicate project preset identities on decode', () {
    final manifest = ProjectManifest(
      name: 'Duplicates',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
    ).toJson();
    const preset = ProjectPresentationPresetRecord(
      id: 'classic',
      label: 'Classique',
      description: 'Profil classique.',
      profile: ProjectPresentationProfile(),
    );
    manifest['presentationPresets'] = <Object?>[
      preset.toJson(),
      preset.toJson(),
    ];

    expect(
      () => ProjectManifest.fromJsonPokeMapBetaV1ForTest(manifest),
      throwsA(isA<FormatException>()),
    );
  });

  test('migrates old complete records and roundtrips scoped records', () {
    const legacy = ProjectPresentationPresetRecord(
      id: 'legacy-v5',
      label: 'Ancien V5',
      description: 'Profil complet historique.',
      profile: ProjectPresentationProfile(),
    );
    final legacyJson = legacy.toJson();

    expect(
      ProjectPresentationPresetRecord.fromJson(legacyJson).scope,
      ProjectPresentationPresetScope.complete,
    );

    const scoped = ProjectPresentationPresetRecord(
      id: 'dialogue-wide',
      label: 'Dialogue large',
      description: 'Remplace uniquement le dialogue.',
      profile: ProjectPresentationProfile(
        dialogue: ProjectDialoguePresentationProfile(maxWidthFactor: .94),
      ),
      scope: ProjectPresentationPresetScope.dialogue,
      replacedSections: <String>['dialogue', 'layouts.dialogue'],
    );
    final decoded = ProjectPresentationPresetRecord.fromJson(scoped.toJson());

    expect(decoded, scoped);
    expect(decoded.replacedSections, <String>['dialogue', 'layouts.dialogue']);
  });

  test('applies a scoped record without replacing unrelated assets', () {
    const current = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(
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
    const preset = ProjectPresentationPresetRecord(
      id: 'dialogue-top',
      label: 'Dialogue haut',
      description: 'Dialogue uniquement.',
      profile: ProjectPresentationProfile(
        dialogue: ProjectDialoguePresentationProfile(
          placement: ProjectDialoguePlacement.top,
        ),
      ),
      scope: ProjectPresentationPresetScope.dialogue,
      replacedSections: <String>['dialogue'],
    );

    final applied = preset.applyTo(current);

    expect(applied.dialogue?.placement, ProjectDialoguePlacement.top);
    expect(applied.branding, current.branding);
    expect(applied.intro, current.intro);
  });

  test('projects a scoped profile without carrying unrelated assets', () {
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(
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
      dialogue: ProjectDialoguePresentationProfile(
        placement: ProjectDialoguePlacement.top,
      ),
    );

    final projected = projectPresentationPresetProfileForScope(
      profile: profile,
      scope: ProjectPresentationPresetScope.dialogue,
    );

    expect(projected.dialogue, profile.dialogue);
    expect(projected.branding, const ProjectBrandingProfile());
    expect(projected.intro, isNull);
    expect(projected.titleMotion, isNull);
  });

  test('rejects section names outside the announced scope', () {
    final json = const ProjectPresentationPresetRecord(
      id: 'dialogue-smuggling-title',
      label: 'Dialogue trompeur',
      description: 'Ne doit pas annoncer une section de titre.',
      profile: ProjectPresentationProfile(
        dialogue: ProjectDialoguePresentationProfile(),
      ),
      scope: ProjectPresentationPresetScope.dialogue,
      replacedSections: <String>['dialogue', 'branding'],
    ).toJson();

    expect(
      () => ProjectPresentationPresetRecord.fromJson(json),
      throwsFormatException,
    );
  });

  test(
    'rejects a scoped record that contains none of its announced content',
    () {
      final json = const ProjectPresentationPresetRecord(
        id: 'empty-dialogue',
        label: 'Dialogue vide',
        description: 'Ne doit pas être accepté.',
        profile: ProjectPresentationProfile(),
        scope: ProjectPresentationPresetScope.dialogue,
        replacedSections: <String>['dialogue'],
      ).toJson();

      expect(
        () => ProjectPresentationPresetRecord.fromJson(json),
        throwsFormatException,
      );
    },
  );
}
