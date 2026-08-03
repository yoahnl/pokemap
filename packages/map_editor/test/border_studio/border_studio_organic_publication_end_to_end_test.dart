import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_transaction.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';
import 'package:map_editor/src/features/border_studio/application/border_smart_tile_ground_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_asset_snapshot_store.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_publication_manifest_port.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'publishes two organic revisions while preserving revision one snapshots',
    () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'pokemap_border_studio_bord03_e2e_',
      );
      addTearDown(() async {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });
      final sourceFile = File(
        p.join(projectRoot.path, 'assets', 'tilesets', 'coast-rock.png'),
      );
      final groundSourceFile = File(
        p.join(projectRoot.path, 'assets', 'tilesets', 'shore-ground.png'),
      );
      final manifestFile = File(p.join(projectRoot.path, 'project.json'));
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsBytes(
        _opaqueTile(red: 84, green: 98, blue: 107),
        flush: true,
      );
      await groundSourceFile.writeAsBytes(
        _opaqueTile(red: 195, green: 176, blue: 115),
        flush: true,
      );

      const assetService = BorderProjectElementAssetService();
      const groundSnapshotService = BorderSmartTileGroundSnapshotService();
      final sourceManifest = _sourceManifest();
      final authoredPrimitives = <BorderPrimitiveDraft>[];
      for (final primitiveId in const <String>[
        'rock-large-a',
        'rock-large-b',
        'rock-large-c',
      ]) {
        final prepared = await assetService.prepare(
          manifest: sourceManifest,
          projectRootPath: projectRoot.path,
          sourceElementId: 'coast-rock',
          primitiveId: primitiveId,
          role: BorderPrimitiveRole.structureLarge,
          weight: 1,
          transforms: BorderTransformPolicy(
            allowFlipX: true,
            allowedQuarterTurns: const <int>[0, 1, 2, 3],
          ),
          anchorPx: const BorderPixelPos(x: 8, y: 8),
        );
        authoredPrimitives.add(prepared.primitive);
      }
      final initialRecord = _record(
        baseRevision: 0,
        primitives: authoredPrimitives,
      );
      final initialManifest = replaceProjectBorderCatalog(
        sourceManifest,
        ProjectBorderCatalog(records: <BorderBlueprintRecord>[initialRecord]),
      );
      ProjectValidator.validate(initialManifest);
      await _writeManifest(manifestFile, initialManifest);

      ProjectManifest? appliedInMemory;
      var snapshotStageIndex = 0;
      var manifestStageIndex = 0;
      final transaction = BorderPublicationTransaction(
        snapshotStore: FileBorderAssetSnapshotStore(
          projectRootPath: projectRoot.path,
          stageIdFactory: () => 'snapshot_${snapshotStageIndex++}',
        ),
        manifestPort: FileBorderPublicationManifestPort(
          manifestPath: manifestFile.path,
          applyInMemoryManifest: (manifest) => appliedInMemory = manifest,
          stageIdFactory: () => 'manifest_${manifestStageIndex++}',
        ),
        candidateValidator: const CoreBorderPublicationCandidateValidator(),
      );
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: assetService.prepare,
        buildCandidate: const BorderPublicationCandidateBuilder().build,
        resolveCanonicalGallery: ({
          required blueprintId,
          required blueprintRevision,
          required visualSnapshots,
          required tileSizePx,
          required resolverVersion,
        }) =>
            BorderStudioCanonicalGalleryResolution.fromCore(
          resolveBorderCanonicalGallery(
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: visualSnapshots,
            tileSizePx: tileSizePx,
            resolverVersion: resolverVersion,
          ),
        ),
        publishRequest: transaction.publish,
      );

      final groundPreparationsV1 = await groundSnapshotService.prepareAllRoles(
        manifest: initialManifest,
        projectRootPath: projectRoot.path,
        sourceSmartTilePresetId: 'shore',
      );
      final previewV1 = await coordinator.prepare(
        manifest: initialManifest,
        projectRootPath: projectRoot.path,
        draftRecord: initialRecord,
        groundSnapshotsByRole: groundPreparationsV1,
      );
      _expectCompleteGallery(previewV1);
      final publishedV1 = await coordinator.publish(
        preview: previewV1,
        currentManifest: initialManifest,
        currentDraftRecord: initialRecord,
        acknowledgedWarningCodes: previewV1.warningCodes,
      );
      final diskV1 = await _readManifest(manifestFile);
      expect(diskV1, publishedV1.manifest);
      expect(appliedInMemory, diskV1);
      final recordV1 = diskV1.borderCatalog.recordById('coast-blueprint')!;
      expect(recordV1.latestPublished!.revision, 1);
      final snapshotIdsV1 = recordV1.latestPublished!.definition.primitives
          .map((primitive) => primitive.visualSnapshotId)
          .toSet();
      expect(snapshotIdsV1, hasLength(1));
      final snapshotV1 = diskV1.borderCatalog.visualSnapshots.singleWhere(
        (snapshot) => snapshot.id == snapshotIdsV1.single,
      );
      final snapshotFileV1 = File(
        p.join(projectRoot.path, snapshotV1.frames.single.relativeAssetPath),
      );
      final immutableBytesV1 = await snapshotFileV1.readAsBytes();
      final groundSnapshotIdsV1 = recordV1
          .latestPublished!.definition.ground!.visualSnapshotIdsByRole.values
          .toSet();
      expect(groundSnapshotIdsV1, hasLength(1));
      final groundSnapshotMetadataV1 = diskV1.borderCatalog.visualSnapshots
          .singleWhere((snapshot) => snapshot.id == groundSnapshotIdsV1.single);
      final groundSnapshotFilesV1 = <File>[
        for (final frame in groundSnapshotMetadataV1.frames)
          File(p.join(projectRoot.path, frame.relativeAssetPath)),
      ];
      final immutableGroundBytesV1 = <List<int>>[
        for (final file in groundSnapshotFilesV1) await file.readAsBytes(),
      ];

      await sourceFile.writeAsBytes(
        _opaqueTile(red: 122, green: 113, blue: 91),
        flush: true,
      );
      await groundSourceFile.writeAsBytes(
        _opaqueTile(red: 170, green: 154, blue: 102),
        flush: true,
      );
      final refreshedPrimitives = <BorderPrimitiveDraft>[];
      for (final primitive in recordV1.draft.definition.primitives) {
        final refreshed = await assetService.reanalyze(
          manifest: diskV1,
          projectRootPath: projectRoot.path,
          primitive: primitive,
        );
        expect(
          refreshed.primitive.currentMetrics.assetFingerprint,
          isNot(primitive.currentMetrics.assetFingerprint),
        );
        refreshedPrimitives.add(refreshed.primitive);
      }
      final refreshedRecord = _record(
        baseRevision: 1,
        primitives: refreshedPrimitives,
        latestPublished: recordV1.latestPublished,
      );
      final refreshedManifest = replaceProjectBorderCatalog(
        diskV1,
        ProjectBorderCatalog(
          formatVersion: diskV1.borderCatalog.formatVersion,
          records: <BorderBlueprintRecord>[refreshedRecord],
          visualSnapshots: diskV1.borderCatalog.visualSnapshots,
        ),
      );
      ProjectValidator.validate(refreshedManifest);
      await _writeManifest(manifestFile, refreshedManifest);
      expect(await _readManifest(manifestFile), refreshedManifest);

      final groundPreparationsV2 = await groundSnapshotService.prepareAllRoles(
        manifest: refreshedManifest,
        projectRootPath: projectRoot.path,
        sourceSmartTilePresetId: 'shore',
      );
      final previewV2 = await coordinator.prepare(
        manifest: refreshedManifest,
        projectRootPath: projectRoot.path,
        draftRecord: refreshedRecord,
        groundSnapshotsByRole: groundPreparationsV2,
      );
      _expectCompleteGallery(previewV2);
      final publishedV2 = await coordinator.publish(
        preview: previewV2,
        currentManifest: refreshedManifest,
        currentDraftRecord: refreshedRecord,
        acknowledgedWarningCodes: previewV2.warningCodes,
      );
      final diskV2 = await _readManifest(manifestFile);

      expect(diskV2, publishedV2.manifest);
      expect(appliedInMemory, diskV2);
      final recordV2 = diskV2.borderCatalog.recordById('coast-blueprint')!;
      expect(recordV2.latestPublished!.revision, 2);
      final snapshotIdsV2 = recordV2.latestPublished!.definition.primitives
          .map((primitive) => primitive.visualSnapshotId)
          .toSet();
      expect(snapshotIdsV2, hasLength(1));
      expect(snapshotIdsV2.single, isNot(snapshotIdsV1.single));
      expect(
        diskV2.borderCatalog.visualSnapshots.take(
          diskV1.borderCatalog.visualSnapshots.length,
        ),
        orderedEquals(diskV1.borderCatalog.visualSnapshots),
      );
      expect(await snapshotFileV1.readAsBytes(), immutableBytesV1);
      final snapshotV2 = diskV2.borderCatalog.visualSnapshots.singleWhere(
        (snapshot) => snapshot.id == snapshotIdsV2.single,
      );
      final snapshotBytesV2 = await File(
        p.join(projectRoot.path, snapshotV2.frames.single.relativeAssetPath),
      ).readAsBytes();
      expect(snapshotBytesV2, isNot(immutableBytesV1));
      expect(
        diskV2.borderCatalog.visualSnapshots.map((snapshot) => snapshot.id),
        containsAll(<String>[snapshotIdsV1.single, snapshotIdsV2.single]),
      );

      final groundSnapshotIdsV2 = recordV2
          .latestPublished!.definition.ground!.visualSnapshotIdsByRole.values
          .toSet();
      expect(groundSnapshotIdsV2, hasLength(1));
      expect(groundSnapshotIdsV2, isNot(equals(groundSnapshotIdsV1)));
      expect(
        diskV2.borderCatalog.visualSnapshots.singleWhere(
          (snapshot) => snapshot.id == groundSnapshotIdsV1.single,
        ),
        groundSnapshotMetadataV1,
      );
      for (var index = 0; index < groundSnapshotFilesV1.length; index += 1) {
        expect(
          await groundSnapshotFilesV1[index].readAsBytes(),
          orderedEquals(immutableGroundBytesV1[index]),
        );
      }
      final groundSnapshotMetadataV2 = diskV2.borderCatalog.visualSnapshots
          .singleWhere((snapshot) => snapshot.id == groundSnapshotIdsV2.single);
      final groundBytesV2 = await File(
        p.join(
          projectRoot.path,
          groundSnapshotMetadataV2.frames.single.relativeAssetPath,
        ),
      ).readAsBytes();
      expect(
          groundBytesV2, isNot(orderedEquals(immutableGroundBytesV1.single)));
    },
  );
}

void _expectCompleteGallery(BorderStudioPublicationPreview preview) {
  expect(preview.canonicalGalleryCases, hasLength(6));
  expect(preview.canonicalGalleryReport.samples, hasLength(6));
  expect(
    preview.canonicalGalleryCases.every(
      (galleryCase) => galleryCase.resolution.canApply,
    ),
    isTrue,
  );
  expect(preview.diagnostics.hasErrors, isFalse);
  expect(preview.canPublish, isTrue);
}

ProjectManifest _sourceManifest() => ProjectManifest(
      name: 'BORD-03 end-to-end project',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'coast-tileset',
          name: 'Coast tileset',
          relativePath: 'assets/tilesets/coast-rock.png',
        ),
        ProjectTilesetEntry(
          id: 'shore-tileset',
          name: 'Shore tileset',
          relativePath: 'assets/tilesets/shore-ground.png',
        ),
      ],
      elementCategories: const <ProjectElementCategory>[
        ProjectElementCategory(id: 'coast-elements', name: 'Coast elements'),
      ],
      elements: const <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'coast-rock',
          name: 'Coast rock',
          tilesetId: 'coast-tileset',
          categoryId: 'coast-elements',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0),
            ),
          ],
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'shore-atlas',
            name: 'Shore atlas',
            tilesetId: 'shore-tileset',
            cellWidth: 16,
            cellHeight: 16,
            columns: 1,
            rows: 1,
          ),
        ],
        animations: const <ProjectSmartTileAnimation>[
          ProjectSmartTileAnimation(
            id: 'shore-ground',
            name: 'Shore ground',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'shore-atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 80,
              ),
            ],
          ),
        ],
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'shore-ground',
            name: 'Shore ground',
            connectionGroupId: 'shore-ground',
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'shore',
            name: 'Shore',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            status: SmartTilePresetStatus.published,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'shore-ground',
            allowedMaterialIds: <String>['shore-ground'],
            rules: <SmartTileRule>[
              SmartTileRule(
                id: 'ground',
                centerMatch: SmartTileSlotMatch.material('shore-ground'),
                candidates: <SmartTileCandidate>[
                  SmartTileCandidate(
                    id: 'ground',
                    parts: <SmartTileVisualPart>[
                      SmartTileVisualPart(
                        source: SmartTileVisualSource.animation(
                          animationId: 'shore-ground',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    );

BorderBlueprintRecord _record({
  required int baseRevision,
  required List<BorderPrimitiveDraft> primitives,
  BorderBlueprintRevision? latestPublished,
}) =>
    BorderBlueprintRecord(
      id: 'coast-blueprint',
      draft: BorderBlueprintDraft(
        baseRevision: baseRevision,
        definition: BorderBlueprintDraftDefinition(
          name: 'Organic coast',
          previewSeed: BorderSignedInt64.fromInt(271828),
          template: BorderBlueprintTemplate.organicEdge,
          primitives: primitives,
          defaults: BorderGenerationParams(
            irregularityPermille: 350,
            detailDensityPermille: 0,
            variationPermille: 1000,
            maxOverlapPx: 0,
            gapTolerancePx: 0,
            depthRows: 1,
          ),
          ground: BorderGroundDraft(
            sourceSmartTilePresetId: 'shore',
            edgeBandCells: 2,
          ),
          sortOrder: 0,
        ),
      ),
      latestPublished: latestPublished,
    );

Uint8List _opaqueTile({
  required int red,
  required int green,
  required int blue,
}) {
  final image = img.Image(width: 16, height: 16, numChannels: 4);
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      image.setPixelRgba(x, y, red, green, blue, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Future<void> _writeManifest(File file, ProjectManifest manifest) async {
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    flush: true,
  );
}

Future<ProjectManifest> _readManifest(File file) async {
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final manifest = ProjectManifest.fromJson(json);
  ProjectValidator.validate(manifest);
  return manifest;
}
