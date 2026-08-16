import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/session/application/services/hub_installed_presentation_runtime.dart';
import 'package:pokemap_hub/features/session/domain/repositories/package_asset_port.dart';

void main() {
  test(
    'loads the installed media catalog through package-safe resolution',
    () async {
      final root = await Directory.systemTemp.createTemp('cin042-media-');
      addTearDown(() => root.delete(recursive: true));
      final media = ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          ProjectMediaAsset(
            id: 'opening.poster',
            label: 'Opening',
            kind: ProjectMediaKind.poster,
            sourceAssetId: 'asset.opening.poster',
          ),
        ],
      );
      final blobBytes = <int>[1, 2, 3];
      final blobDigest =
          computeNarrativeProjectFingerprint(<NarrativeProjectFingerprintEntry>[
            NarrativeProjectFingerprintEntry(
              relativePath: 'artifact-content',
              bytes: blobBytes,
            ),
          ]);
      final blobHexDigest = blobDigest.substring('sha256:'.length);
      await _write(
        root,
        'project/assets/.pokemap-media.json',
        utf8.encode(jsonEncode(media.toJson())),
      );
      await _write(
        root,
        'project/assets/.pokemap-assets.json',
        utf8.encode(
          jsonEncode(<String, Object?>{
            'schemaVersion': 1,
            'records': <Object?>[
              <String, Object?>{
                'id': 'asset.opening.poster',
                'logicalPath': 'presentation/opening.png',
                'artifact': <String, Object?>{
                  'handle': 'installed',
                  'mediaType': 'image/png',
                  'byteLength': 3,
                  'digest': blobDigest,
                },
                'usages': <Object?>[],
                'tags': <Object?>['presentation'],
              },
            ],
          }),
        ),
      );
      final blob = await _write(
        root,
        'project/assets/.pokemap-store/$blobHexDigest.blob',
        blobBytes,
      );

      final loaded = await const HubInstalledPresentationMediaLoader().load(
        _DirectoryPackageAssets(root),
      );

      expect(loaded.catalog.toJson(), media.toJson());
      expect(loaded.mediaUris['opening.poster'], blob.uri);
    },
  );

  test(
    'rejects a catalog asset that is not in the installed inventory',
    () async {
      final root = await Directory.systemTemp.createTemp('cin042-missing-');
      addTearDown(() => root.delete(recursive: true));
      await _write(
        root,
        'project/assets/.pokemap-media.json',
        utf8.encode(
          jsonEncode(
            ProjectMediaCatalog(
              entries: <ProjectMediaAsset>[
                ProjectMediaAsset(
                  id: 'opening.poster',
                  label: 'Opening',
                  kind: ProjectMediaKind.poster,
                  sourceAssetId: 'asset.missing',
                ),
              ],
            ).toJson(),
          ),
        ),
      );
      await _write(
        root,
        'project/assets/.pokemap-assets.json',
        utf8.encode(
          jsonEncode(<String, Object?>{
            'schemaVersion': 1,
            'records': <Object?>[],
          }),
        ),
      );

      expect(
        () => const HubInstalledPresentationMediaLoader().load(
          _DirectoryPackageAssets(root),
        ),
        throwsA(
          isA<HubInstalledPresentationMediaException>()
              .having(
                (error) => error.code,
                'code',
                HubInstalledPresentationMediaErrorCode.mediaAssetMissing,
              )
              .having((error) => error.mediaId, 'mediaId', 'opening.poster'),
        ),
      );
    },
  );

  test(
    'reports a stable error when an inventoried media blob is corrupt',
    () async {
      final root = await Directory.systemTemp.createTemp('cin042-blob-');
      addTearDown(() => root.delete(recursive: true));
      await _write(
        root,
        'project/assets/.pokemap-media.json',
        utf8.encode(
          jsonEncode(
            ProjectMediaCatalog(
              entries: <ProjectMediaAsset>[
                ProjectMediaAsset(
                  id: 'opening.poster',
                  label: 'Opening',
                  kind: ProjectMediaKind.poster,
                  sourceAssetId: 'asset.opening.poster',
                ),
              ],
            ).toJson(),
          ),
        ),
      );
      await _write(
        root,
        'project/assets/.pokemap-assets.json',
        utf8.encode(
          jsonEncode(<String, Object?>{
            'schemaVersion': 1,
            'records': <Object?>[
              <String, Object?>{
                'id': 'asset.opening.poster',
                'artifact': <String, Object?>{
                  'digest':
                      'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
                },
              },
            ],
          }),
        ),
      );
      await _write(
        root,
        'project/assets/.pokemap-store/'
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.blob',
        <int>[1, 2, 3],
      );

      expect(
        () => const HubInstalledPresentationMediaLoader().load(
          _DirectoryPackageAssets(root),
        ),
        throwsA(
          isA<HubInstalledPresentationMediaException>().having(
            (error) => error.code,
            'code',
            HubInstalledPresentationMediaErrorCode.mediaBlobInvalid,
          ),
        ),
      );
    },
  );
}

Future<File> _write(
  Directory root,
  String relativePath,
  List<int> bytes,
) async {
  final file = File(p.joinAll(<String>[root.path, ...relativePath.split('/')]));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

final class _DirectoryPackageAssets implements PackageAssetPort {
  const _DirectoryPackageAssets(this.root);

  final Directory root;

  @override
  PackageAssetReferencePort reference(String packagePath) =>
      _TestAssetReference(packagePath);

  @override
  Future<File> resolveFile(String packagePath) async {
    final file = File(
      p.joinAll(<String>[root.path, ...packagePath.split('/')]),
    );
    if (!await file.exists()) throw StateError('not inventoried');
    return file;
  }

  @override
  Future<File> resolveReference(PackageAssetReferencePort reference) =>
      resolveFile(reference.packagePath);
}

final class _TestAssetReference implements PackageAssetReferencePort {
  const _TestAssetReference(this.packagePath);

  @override
  final String packagePath;
}
