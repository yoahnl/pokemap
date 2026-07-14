import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_transaction.dart';
import 'package:map_editor/src/features/border_studio/application/ports/border_asset_snapshot_store.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_asset_snapshot_store.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_publication_manifest_port.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Border publication filesystem integration', () {
    late Directory root;
    late File manifestFile;
    late ProjectManifest previous;

    setUp(() async {
      root = await Directory.systemTemp.createTemp(
        'pokemap_border_publication_integration_',
      );
      manifestFile = File(p.join(root.path, 'project.json'));
      previous = const ProjectManifest(
        name: 'Before publication',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );
      await manifestFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(previous.toJson()),
        flush: true,
      );
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('recovers after a partial snapshot move without exposing manifest',
        () async {
      final preparation = _animatedPreparation();
      var stageIndex = 0;
      var moveCount = 0;
      var injected = false;
      final store = FileBorderAssetSnapshotStore(
        projectRootPath: root.path,
        stageIdFactory: () => 'stage_${stageIndex++}',
        beforeOperation: (operation, relativePath) {
          if (!injected &&
              operation == BorderSnapshotStoreOperation.finalizeMove &&
              ++moveCount == 2) {
            injected = true;
            throw StateError('simulated crash during second move');
          }
        },
      );
      ProjectManifest? applied;
      final transaction = BorderPublicationTransaction(
        snapshotStore: store,
        manifestPort: FileBorderPublicationManifestPort(
          manifestPath: manifestFile.path,
          applyInMemoryManifest: (manifest) => applied = manifest,
          stageIdFactory: () => 'manifest_stage',
        ),
        candidateValidator: const _AcceptingValidator(),
      );
      final request = _request(previous, preparation);
      final oldBytes = await manifestFile.readAsBytes();

      await expectLater(transaction.publish(request), throwsStateError);

      expect(await manifestFile.readAsBytes(), oldBytes);
      expect(applied, isNull);
      expect(
        File(p.join(root.path, preparation.files.first.relativePath))
            .existsSync(),
        isTrue,
      );
      expect(
        File(p.join(root.path, preparation.files.last.relativePath))
            .existsSync(),
        isFalse,
      );

      final result = await transaction.publish(request);

      expect(result.manifest, request.nextManifest);
      expect(applied, request.nextManifest);
      for (final payload in preparation.files) {
        expect(
          await File(p.join(root.path, payload.relativePath)).readAsBytes(),
          payload.bytes,
        );
      }
      expect(await _readManifest(manifestFile), request.nextManifest);
    });

    test('a corrupt shared snapshot blocks manifest replacement', () async {
      final preparation = _animatedPreparation();
      final firstFile = File(
        p.join(root.path, preparation.files.first.relativePath),
      );
      await firstFile.parent.create(recursive: true);
      final corruptBytes = Uint8List.fromList(<int>[9, 9, 9]);
      await firstFile.writeAsBytes(corruptBytes, flush: true);
      final oldBytes = await manifestFile.readAsBytes();
      final transaction = BorderPublicationTransaction(
        snapshotStore: FileBorderAssetSnapshotStore(
          projectRootPath: root.path,
          stageIdFactory: () => 'stage_corrupt',
        ),
        manifestPort: FileBorderPublicationManifestPort(
          manifestPath: manifestFile.path,
          applyInMemoryManifest: (_) {},
          stageIdFactory: () => 'manifest_corrupt',
        ),
        candidateValidator: const _AcceptingValidator(),
      );

      await expectLater(
        transaction.publish(_request(previous, preparation)),
        throwsA(
          isA<BorderAssetSnapshotStoreException>().having(
            (error) => error.code,
            'code',
            BorderAssetSnapshotStoreErrorCode.corruptedExistingSnapshot,
          ),
        ),
      );

      expect(await manifestFile.readAsBytes(), oldBytes);
      expect(await firstFile.readAsBytes(), corruptBytes);
    });
  });
}

BorderAssetSnapshotPreparation _animatedPreparation() {
  const service = BorderAssetSnapshotService();
  return service.prepare(
    BorderAssetSnapshotRequest(
      frames: <BorderAssetSnapshotSourceFrame>[
        BorderAssetSnapshotSourceFrame(
          sourceProjectRelativePath: 'assets/source/frame-a.png',
          encodedImageBytes: _png(20, 80, 140),
          durationMs: 100,
        ),
        BorderAssetSnapshotSourceFrame(
          sourceProjectRelativePath: 'assets/source/frame-b.png',
          encodedImageBytes: _png(60, 120, 180),
          durationMs: 125,
        ),
      ],
    ),
  );
}

BorderPublicationRequest _request(
  ProjectManifest previous,
  BorderAssetSnapshotPreparation preparation,
) {
  final next = replaceProjectBorderCatalog(
    previous,
    ProjectBorderCatalog(
      visualSnapshots: <BorderVisualSnapshot>[preparation.snapshot],
    ),
  );
  return BorderPublicationRequest(
    previousManifest: previous,
    nextManifest: next,
    blueprintId: 'integration-coast',
    resolverVersion: 1,
    snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
      preparation.snapshot.id: BorderVisualSnapshotIntegrity(
        snapshotId: preparation.snapshot.id,
        metadataValid: true,
        filesPresent: true,
        contentFingerprintMatches: true,
      ),
    },
    canonicalGalleryReport: BorderPublicationGalleryReport(
      resolverVersion: 1,
      canonicalGalleryVersion: borderCanonicalGalleryVersion,
      candidateFingerprint: 'sha256:${List<String>.filled(64, '0').join()}',
      samples: const <BorderPublicationGallerySample>[],
    ),
    files: preparation.files,
  );
}

Future<ProjectManifest> _readManifest(File file) async {
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return ProjectManifest.fromJson(migrateProjectManifestJson(json));
}

Uint8List _png(int red, int green, int blue) {
  final image = img.Image(width: 2, height: 2, numChannels: 4);
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      image.setPixelRgba(x, y, red, green, blue, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

final class _AcceptingValidator implements BorderPublicationCandidateValidator {
  const _AcceptingValidator();

  @override
  BorderDiagnosticsReport validate(BorderPublicationRequest request) {
    return const BorderDiagnosticsReport.empty();
  }
}
