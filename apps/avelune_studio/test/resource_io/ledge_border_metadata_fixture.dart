import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

final class NativeLedgeResourceFixture {
  NativeLedgeResourceFixture(
    this.base,
    this.project,
    this.record,
    this.mapBefore,
    this.mediaBefore,
  );
  final ResourceFixture base;
  final ProjectManifest project;
  final BorderBlueprintRecord record;
  final List<int> mapBefore;
  final Map<String, List<int>> mediaBefore;
  Directory get root => base.root;
  File get mapFile => base.mapFile;
  LocalResourceAdapter get resources => base.resources;
  LocalMapWorkspaceAdapter get maps => base.maps;
  ProjectSession get session => base.session;

  static Future<NativeLedgeResourceFixture> create({
    bool jumpsEnabled = true,
    bool animatedFirst = false,
    bool isDeprecated = false,
  }) async {
    final base = await ResourceFixture.create();
    const path = 'assets/tilesets/native-ledges.png';
    final atlas = image.Image(width: 96, height: 32, numChannels: 4);
    for (var variant = 0; variant < 3; variant++) {
      for (var y = 16; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          atlas.setPixelRgba(
            variant * 32 + x,
            y,
            x * 7,
            y * 5,
            40 + variant * 60,
            255,
          );
        }
      }
    }
    final encoded = image.encodePng(atlas);
    final file = File('${base.root.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(encoded);
    final preparations = <CanonicalBorderSnapshotPreparation>[];
    final primitives = <BorderPrimitiveDraft>[];
    final published = <BorderPublishedPrimitive>[];
    final elements = <ProjectElementEntry>[];
    for (var i = 0; i < 3; i++) {
      final id = 'native-variant-$i';
      final sourceId = 'native-element-$i';
      const anchor = BorderPixelPos(x: 16, y: 31);
      final visualFrames = [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: i, y: 0),
          durationMs: 100,
        ),
        if (animatedFirst && i == 0)
          const TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: 0),
            durationMs: 180,
          ),
      ];
      final preparation = const CanonicalBorderSnapshotCompiler().prepare(
        sourceElementId: sourceId,
        anchorPx: anchor,
        frames: [
          for (final frame in visualFrames)
            CanonicalBorderSourceFrame(
              sourceProjectRelativePath: path,
              encodedImageBytes: encoded,
              sourceRectPx: BorderPixelRect(
                x: frame.source.x * 32,
                y: 0,
                width: 32,
                height: 32,
              ),
              durationMs: frame.durationMs,
            ),
        ],
      );
      preparations.add(preparation);
      final transform = BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: [0],
      );
      primitives.add(
        BorderPrimitiveDraft(
          id: id,
          sourceElementId: sourceId,
          role: BorderPrimitiveRole.structureLarge,
          authoredOrientation: BorderPrimitiveOrientation.south,
          weight: i + 1,
          anchorPx: anchor,
          transforms: transform,
          currentMetrics: preparation.metrics,
        ),
      );
      published.add(
        BorderPublishedPrimitive(
          id: id,
          sourceElementId: sourceId,
          visualSnapshotId: preparation.snapshot.id,
          role: BorderPrimitiveRole.structureLarge,
          authoredOrientation: BorderPrimitiveOrientation.south,
          weight: i + 1,
          anchorPx: anchor,
          transforms: transform,
          publishedMetrics: preparation.metrics,
        ),
      );
      elements.add(
        ProjectElementEntry(
          id: sourceId,
          name: 'Rebord $i',
          tilesetId: 'native-atlas',
          categoryId: 'native-ledges',
          frames: visualFrames,
          collisionProfile: const ElementCollisionProfile(
            cells: [GridPos(x: 0, y: 0)],
          ),
        ),
      );
      for (final asset in preparation.files) {
        final output = File('${base.root.path}/${asset.relativePath}');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(asset.bytes);
      }
    }
    final rules = BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
      allowAutoRotation: false,
    );
    final jump = jumpsEnabled
        ? BorderJumpBehavior(durationMs: 500, peakHeightPx: 24)
        : null;
    final record = BorderBlueprintRecord(
      id: 'native-ledges',
      isDeprecated: isDeprecated,
      draft: BorderBlueprintDraft(
        baseRevision: 1,
        definition: BorderBlueprintDraftDefinition(
          name: 'Rebords natifs',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.ledgeLine,
          primitives: primitives,
          defaults: rules,
          jumpBehavior: jump,
          sortOrder: 0,
        ),
      ),
      latestPublished: BorderBlueprintRevision(
        revision: 1,
        definition: BorderBlueprintPublishedDefinition(
          name: 'Rebords natifs',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.ledgeLine,
          primitives: published,
          defaults: rules,
          jumpBehavior: jump,
          sortOrder: 0,
        ),
      ),
    );
    final project = ProjectManifest(
      name: 'Rebords importés',
      version: ProjectVersion.v8,
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      maps: const [ResourceFixture.entry],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'native-atlas',
          name: 'Modules natifs',
          relativePath: path,
        ),
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'native-ledges', name: 'Rebords'),
      ],
      elements: elements,
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 7,
        records: [record],
        visualSnapshots: [for (final p in preparations) p.snapshot],
      ),
    );
    ProjectValidator.validate(project);
    expect(ProjectManifest.fromJson(project.toJson()), project);
    await base.manifestFile.writeAsString(jsonEncode(project.toJson()));
    await base.mapFile.writeAsBytes(
      encodeMapDocumentBytes(
        MapData(
          id: 'garden',
          name: 'Jardin',
          size: const GridSize(width: 4, height: 4),
          visualStack: MapVisualStackConfig.canonicalV1,
          layers: [
            TileLayer(id: 'ground', name: 'Sol', cells: List.filled(16, 0)),
          ],
        ),
      ),
    );
    final catalogFile = File('${base.root.path}/$assetCatalogStorageKey');
    final catalog = await catalogFile.exists()
        ? AssetCatalog.fromJson(
            jsonDecode(await catalogFile.readAsString())
                as Map<String, dynamic>,
          )
        : AssetCatalog();
    final records = {
      for (final record in catalog.records) record.logicalPath: record,
    };
    for (final preparation in preparations) {
      for (final asset in preparation.files) {
        final artifact = ContentArtifactRef.fromBytes(
          asset.bytes,
          mediaType: 'image/png',
        );
        final known = records[asset.relativePath];
        if (known != null && known.artifact != artifact) {
          throw StateError(
            'Fixture snapshot registry conflicts with certified pixels.',
          );
        }
        records.putIfAbsent(
          asset.relativePath,
          () => AssetRecord(
            id: 'native_snapshot_${sha256.convert(utf8.encode(asset.relativePath))}',
            logicalPath: asset.relativePath,
            artifact: artifact,
          ),
        );
        final blob = File('${base.root.path}/${assetBlobStorageKey(artifact)}');
        if (await blob.exists()) {
          if (ContentArtifactRef.fromBytes(
                await blob.readAsBytes(),
                mediaType: 'image/png',
              ) !=
              artifact) {
            throw StateError(
              'Fixture snapshot blob conflicts with certified pixels.',
            );
          }
        } else {
          await blob.parent.create(recursive: true);
          await blob.writeAsBytes(asset.bytes);
        }
      }
    }
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(
      jsonEncode(AssetCatalog(records: records.values).toJson()),
    );
    await base.maps.loadProject(base.session);
    final media = <String, List<int>>{path: await file.readAsBytes()};
    for (final p in preparations) {
      for (final asset in p.files) {
        media[asset.relativePath] = await File(
          '${base.root.path}/${asset.relativePath}',
        ).readAsBytes();
      }
    }
    return NativeLedgeResourceFixture(
      base,
      project,
      record,
      await base.mapFile.readAsBytes(),
      media,
    );
  }

  Future<void> dispose() => base.dispose();
}
