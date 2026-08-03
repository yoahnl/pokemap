import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
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
      previous = _previousManifest(preparation, catalogKnowsSnapshot: false);
      await _writeManifest(manifestFile, previous);
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

    test('a corrupt catalog-known snapshot blocks manifest replacement',
        () async {
      final preparation = _animatedPreparation();
      previous = _previousManifest(preparation, catalogKnowsSnapshot: true);
      await _writeManifest(manifestFile, previous);
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

    test('restores missing files for a catalog-known referenced snapshot',
        () async {
      final preparation = _animatedPreparation();
      previous = _previousManifest(preparation, catalogKnowsSnapshot: true);
      await _writeManifest(manifestFile, previous);
      final request = _request(previous, preparation);
      expect(
        request.nextManifest.borderCatalog.visualSnapshots,
        previous.borderCatalog.visualSnapshots,
      );
      expect(request.files, preparation.files);
      ProjectManifest? applied;
      final transaction = BorderPublicationTransaction(
        snapshotStore: FileBorderAssetSnapshotStore(
          projectRootPath: root.path,
          stageIdFactory: () => 'stage_restore_known',
        ),
        manifestPort: FileBorderPublicationManifestPort(
          manifestPath: manifestFile.path,
          applyInMemoryManifest: (manifest) => applied = manifest,
          stageIdFactory: () => 'manifest_restore_known',
        ),
        candidateValidator: const _AcceptingValidator(),
      );

      final result = await transaction.publish(request);

      expect(result.snapshotFinalize.createdRelativePaths,
          preparation.files.map((file) => file.relativePath));
      expect(applied, request.nextManifest);
      for (final payload in preparation.files) {
        expect(
          await File(p.join(root.path, payload.relativePath)).readAsBytes(),
          payload.bytes,
        );
      }
      expect(await _readManifest(manifestFile), request.nextManifest);
    });

    test('preserves an external manifest changed after candidate creation',
        () async {
      final preparation = _animatedPreparation();
      previous = _previousManifest(preparation, catalogKnowsSnapshot: true);
      await _writeManifest(manifestFile, previous);
      final request = _request(previous, preparation);
      final external = previous.copyWith(name: 'Newer external project');
      ProjectManifest? applied;
      final transaction = BorderPublicationTransaction(
        snapshotStore: FileBorderAssetSnapshotStore(
          projectRootPath: root.path,
          stageIdFactory: () => 'stage_stale_manifest',
        ),
        manifestPort: FileBorderPublicationManifestPort(
          manifestPath: manifestFile.path,
          applyInMemoryManifest: (manifest) => applied = manifest,
          stageIdFactory: () => 'manifest_stale',
          beforeOperation: (operation, _) async {
            if (operation == BorderPublicationManifestOperation.atomicReplace) {
              await _writeManifest(manifestFile, external);
            }
          },
        ),
        candidateValidator: const _AcceptingValidator(),
      );

      await expectLater(
        transaction.publish(request),
        throwsA(
          isA<BorderPublicationManifestException>().having(
            (error) => error.code,
            'code',
            BorderPublicationManifestErrorCode.staleManifest,
          ),
        ),
      );

      expect(await _readManifest(manifestFile), external);
      expect(applied, isNull);
    });
  });
}

BorderAssetSnapshotPreparation _animatedPreparation() {
  const service = BorderAssetSnapshotService();
  return service.prepare(
    BorderAssetSnapshotRequest(
      sourceElementId: 'animated-element',
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
  final target = previous.borderCatalog.records.single;
  final candidate = const BorderPublicationCandidateBuilder().build(
    manifest: previous,
    draftRecord: target,
    primitiveSnapshotsByPrimitiveId: <String, BorderAssetSnapshotPreparation>{
      'animated-structure': preparation,
    },
  );
  return BorderPublicationRequest(
    previousManifest: previous,
    nextManifest: candidate.nextManifest,
    blueprintId: 'integration-coast',
    resolverVersion: 1,
    snapshotIntegrity: candidate.snapshotIntegrity,
    canonicalGalleryReport: BorderPublicationGalleryReport(
      resolverVersion: 1,
      canonicalGalleryVersion: borderCanonicalGalleryVersion,
      candidateFingerprint: 'sha256:${List<String>.filled(64, '0').join()}',
      samples: const <BorderPublicationGallerySample>[],
    ),
    files: candidate.files,
  );
}

ProjectManifest _previousManifest(
  BorderAssetSnapshotPreparation preparation, {
  required bool catalogKnowsSnapshot,
}) {
  final definition = BorderBlueprintDraftDefinition(
    name: 'Integration coast',
    previewSeed: BorderSignedInt64.zero,
    template: BorderBlueprintTemplate.organicEdge,
    primitives: <BorderPrimitiveDraft>[
      BorderPrimitiveDraft(
        id: 'animated-structure',
        sourceElementId: 'animated-element',
        role: BorderPrimitiveRole.structureLarge,
        weight: 1000,
        anchorPx: preparation.metrics.defaultAnchorPx,
        transforms: BorderTransformPolicy(
          allowFlipX: false,
          allowedQuarterTurns: const <int>[0, 1, 2, 3],
        ),
        currentMetrics: preparation.metrics,
      ),
    ],
    defaults: BorderGenerationParams(
      irregularityPermille: 500,
      detailDensityPermille: 500,
      variationPermille: 500,
      maxOverlapPx: 2,
      gapTolerancePx: 2,
      depthRows: 2,
    ),
    sortOrder: 0,
  );
  return ProjectManifest(
    name: 'Before publication',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'source-tileset',
        name: 'Source tileset',
        relativePath: 'assets/source/source.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'border', name: 'Border'),
    ],
    elements: const <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'animated-element',
        name: 'Animated element',
        tilesetId: 'source-tileset',
        categoryId: 'border',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    borderCatalog: ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[
        BorderBlueprintRecord(
          id: 'integration-coast',
          draft: BorderBlueprintDraft(
            baseRevision: 0,
            definition: definition,
          ),
        ),
      ],
      visualSnapshots: catalogKnowsSnapshot
          ? <BorderVisualSnapshot>[preparation.snapshot]
          : const <BorderVisualSnapshot>[],
    ),
  );
}

Future<void> _writeManifest(File file, ProjectManifest manifest) async {
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    flush: true,
  );
}

Future<ProjectManifest> _readManifest(File file) async {
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return ProjectManifest.fromJson(json);
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
