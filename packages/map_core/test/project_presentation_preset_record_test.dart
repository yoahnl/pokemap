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

    final decoded = ProjectManifest.fromJson(manifest.toJson());

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
      () => ProjectManifest.fromJson(manifest),
      throwsA(isA<FormatException>()),
    );
  });
}
