import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  const codec = PresentationPresetPackCodec();

  test('roundtrips a deterministic licensed preset pack', () {
    final image = Uint8List.fromList(<int>[0x89, 0x50, 0x4e, 0x47]);
    final font = Uint8List.fromList(<int>[0x00, 0x01, 0x00, 0x00]);
    final license = Uint8List.fromList(utf8.encode('CC-BY-4.0\n'));
    final pack = ProjectPresentationPresetPack(
      manifest: PresentationPresetPackManifest(
        id: 'night-train',
        label: 'Train de nuit',
        description: 'Une présentation nocturne réutilisable.',
        compatibility: const PresentationPresetCompatibility(
          minimumProfileSchemaVersion: 5,
          maximumProfileSchemaVersion: 5,
        ),
        assets: <PresentationPresetAsset>[
          PresentationPresetAsset(
            projectPath: 'assets/presentation/branding/icon.png',
            archivePath: 'assets/icon.png',
            mediaType: 'image/png',
            sizeBytes: image.length,
            sha256: sha256.convert(image).toString(),
            licenseProjectPath: 'assets/presentation/licenses/icon-license.txt',
            licenseArchivePath: 'licenses/icon.txt',
            licenseSizeBytes: license.length,
            licenseSha256: sha256.convert(license).toString(),
          ),
          PresentationPresetAsset(
            projectPath: 'assets/presentation/fonts/battle.ttf',
            archivePath: 'assets/battle.ttf',
            mediaType: 'font/ttf',
            sizeBytes: font.length,
            sha256: sha256.convert(font).toString(),
            licenseProjectPath: 'assets/presentation/licenses/font-license.txt',
            licenseArchivePath: 'licenses/font.txt',
            licenseSizeBytes: license.length,
            licenseSha256: sha256.convert(license).toString(),
          ),
        ],
      ),
      profile: const ProjectPresentationProfile(
        branding: ProjectBrandingProfile(
          iconPath: 'assets/presentation/branding/icon.png',
        ),
        typography: ProjectTypographyProfile(
          combat: ProjectTypographyRoleProfile(
            fontPath: 'assets/presentation/fonts/battle.ttf',
            family: 'Battle Mono',
            licensePath: 'assets/presentation/licenses/font-license.txt',
            redistributable: true,
            glyphCoverage: <String>[
              'latin',
              'latinExtended',
              'digits',
              'punctuation',
            ],
          ),
        ),
      ),
      files: <String, Uint8List>{
        'assets/icon.png': image,
        'assets/battle.ttf': font,
        'licenses/icon.txt': license,
        'licenses/font.txt': license,
      },
    );

    final first = codec.encode(pack);
    final second = codec.encode(pack);
    final decoded = codec.decode(first);

    expect(second, first);
    expect(decoded.manifest.toJson(), pack.manifest.toJson());
    expect(decoded.profile, pack.profile);
    expect(decoded.files['assets/icon.png'], image);
    expect(decoded.files['assets/battle.ttf'], font);
    expect(decoded.files['licenses/icon.txt'], license);
  });

  test('rejects traversal before exposing any file', () {
    final archive = Archive()
      ..addFile(ArchiveFile('../escape.txt', 1, <int>[0]))
      ..addFile(ArchiveFile('manifest.json', 2, utf8.encode('{}')));
    final bytes = ZipEncoder().encodeBytes(archive);

    expect(
      () => codec.decode(bytes),
      throwsA(
        isA<PresentationPresetPackException>().having(
          (error) => error.code,
          'code',
          'presetPackInvalidPath',
        ),
      ),
    );
  });

  test('requires combat font assets and licenses in the preset pack', () {
    expect(
      () => ProjectPresentationPresetPack(
        manifest: PresentationPresetPackManifest(
          id: 'missing-combat-font',
          label: 'Police combat manquante',
          description: 'Le profil ne doit pas perdre sa police de combat.',
          compatibility: const PresentationPresetCompatibility(
            minimumProfileSchemaVersion: 5,
            maximumProfileSchemaVersion: 5,
          ),
          assets: <PresentationPresetAsset>[],
        ),
        profile: const ProjectPresentationProfile(
          typography: ProjectTypographyProfile(
            combat: ProjectTypographyRoleProfile(
              fontPath: 'assets/presentation/fonts/battle.ttf',
              family: 'Battle Mono',
              licensePath: 'assets/presentation/licenses/font-license.txt',
              redistributable: true,
              glyphCoverage: <String>[
                'latin',
                'latinExtended',
                'digits',
                'punctuation',
              ],
            ),
          ),
        ),
      ),
      throwsA(
        isA<PresentationPresetPackException>().having(
          (error) => error.code,
          'code',
          'presetPackProfileAssetMissing',
        ),
      ),
    );
  });

  test('requires a license for every redistributed asset', () {
    final image = Uint8List.fromList(<int>[0x89, 0x50, 0x4e, 0x47]);
    expect(
      () => ProjectPresentationPresetPack(
        manifest: PresentationPresetPackManifest(
          id: 'unlicensed',
          label: 'Sans licence',
          description: 'Doit être refusé.',
          compatibility: const PresentationPresetCompatibility(
            minimumProfileSchemaVersion: 5,
            maximumProfileSchemaVersion: 5,
          ),
          assets: <PresentationPresetAsset>[
            PresentationPresetAsset(
              projectPath: 'assets/presentation/branding/icon.png',
              archivePath: 'assets/icon.png',
              mediaType: 'image/png',
              sizeBytes: image.length,
              sha256: sha256.convert(image).toString(),
            ),
          ],
        ),
        profile: const ProjectPresentationProfile(),
        files: <String, Uint8List>{'assets/icon.png': image},
      ),
      throwsA(
        isA<PresentationPresetPackException>().having(
          (error) => error.code,
          'code',
          'presetPackLicenseRequired',
        ),
      ),
    );
  });

  test('rejects incompatible profile schemas and tampered assets', () {
    final bytes = Uint8List.fromList(<int>[1, 2, 3]);
    final asset = PresentationPresetAsset(
      projectPath: 'assets/presentation/branding/icon.png',
      archivePath: 'assets/icon.png',
      mediaType: 'image/png',
      sizeBytes: bytes.length,
      sha256: sha256.convert(<int>[9]).toString(),
      licenseProjectPath: 'assets/presentation/licenses/icon-license.txt',
      licenseArchivePath: 'licenses/icon.txt',
      licenseSizeBytes: 3,
      licenseSha256: sha256.convert(utf8.encode('MIT')).toString(),
    );
    expect(
      () => ProjectPresentationPresetPack(
        manifest: PresentationPresetPackManifest(
          id: 'tampered',
          label: 'Altéré',
          description: 'Doit être refusé.',
          compatibility: const PresentationPresetCompatibility(
            minimumProfileSchemaVersion: 5,
            maximumProfileSchemaVersion: 5,
          ),
          assets: <PresentationPresetAsset>[asset],
        ),
        profile: const ProjectPresentationProfile(),
        files: <String, Uint8List>{
          'assets/icon.png': bytes,
          'licenses/icon.txt': Uint8List.fromList(utf8.encode('MIT')),
        },
      ),
      throwsA(
        isA<PresentationPresetPackException>().having(
          (error) => error.code,
          'code',
          'presetPackChecksumMismatch',
        ),
      ),
    );
  });
}
