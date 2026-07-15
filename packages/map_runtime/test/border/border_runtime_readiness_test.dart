import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/border/border_runtime_readiness.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/presentation/flame/runtime_map_game.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prepareBorderRuntimeBundle', () {
    test('accepts fresh materialization and ignores an unused corrupt snapshot',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final unused = _snapshot(
        digest: 'f' * 64,
        relativePath: 'assets/borders/snapshots/unused/corrupt.png',
      );
      await File(
              p.join(fixture.root.path, unused.frames.single.relativeAssetPath))
          .parent
          .create(recursive: true);
      await File(
              p.join(fixture.root.path, unused.frames.single.relativeAssetPath))
          .writeAsBytes(<int>[1, 2, 3]);

      final prepared = await prepareBorderRuntimeBundle(
        fixture.bundle(extraSnapshots: <BorderVisualSnapshot>[unused]),
      );

      expect(prepared.borderRuntimePreparation, isNotNull);
      expect(
        prepared.borderRuntimePreparation!.assetCollection.snapshots
            .map((request) => request.snapshotId),
        <String>[fixture.snapshot.id],
      );
      expect(
        prepared.borderRuntimePreparation!
            .snapshotIntegrity[fixture.snapshot.id]?.isValid,
        isTrue,
      );
      expect(
        prepared.borderRuntimePreparation!.featureFreshness.single.state,
        BorderMaterializationState.fresh,
      );
    });

    test('permits a missing blueprint when persisted output stays renderable',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);

      final prepared = await prepareBorderRuntimeBundle(
        fixture.bundle(includeBlueprint: false),
      );

      final freshness =
          prepared.borderRuntimePreparation!.featureFreshness.single;
      expect(freshness.state, BorderMaterializationState.stale);
      expect(
        freshness.reasons,
        contains(BorderStalenessReason.blueprintMissing),
      );
      expect(freshness.isRenderable, isTrue);
    });

    test('permits a newer blueprint with a corrupt generation-only snapshot',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final corruptGenerationSnapshot = _snapshot(
        digest: 'e' * 64,
        relativePath: 'assets/borders/snapshots/generation-only/corrupt.png',
      );
      final priorPrimitive = fixture.revision.definition.primitives.single;
      final newerPrimitive = BorderPublishedPrimitive(
        id: priorPrimitive.id,
        sourceElementId: priorPrimitive.sourceElementId,
        visualSnapshotId: corruptGenerationSnapshot.id,
        role: priorPrimitive.role,
        weight: priorPrimitive.weight,
        anchorPx: priorPrimitive.anchorPx,
        transforms: priorPrimitive.transforms,
        publishedMetrics: priorPrimitive.publishedMetrics,
      );
      final newerRevision = BorderBlueprintRevision(
        revision: fixture.revision.revision + 1,
        definition: BorderBlueprintPublishedDefinition(
          name: fixture.revision.definition.name,
          previewSeed: fixture.revision.definition.previewSeed,
          template: fixture.revision.definition.template,
          primitives: <BorderPublishedPrimitive>[newerPrimitive],
          defaults: fixture.revision.definition.defaults,
          ground: fixture.revision.definition.ground,
          categoryId: fixture.revision.definition.categoryId,
          sortOrder: fixture.revision.definition.sortOrder,
        ),
      );
      final source = fixture.bundle();
      final prepared = await prepareBorderRuntimeBundle(
        source.copyWith(
          manifest: source.manifest.copyWith(
            borderCatalog: ProjectBorderCatalog(
              records: <BorderBlueprintRecord>[_record(newerRevision)],
              visualSnapshots: <BorderVisualSnapshot>[
                fixture.snapshot,
                corruptGenerationSnapshot,
              ],
            ),
          ),
        ),
      );

      final freshness =
          prepared.borderRuntimePreparation!.featureFreshness.single;
      expect(freshness.state, BorderMaterializationState.stale);
      expect(freshness.isRenderable, isTrue);
      expect(
        freshness.reasons,
        contains(BorderStalenessReason.blueprintNewer),
      );
      expect(
        prepared.borderRuntimePreparation!.snapshotIntegrity,
        isNot(contains(corruptGenerationSnapshot.id)),
      );
    });

    test('validates hidden Border features and blocks unmaterialized content',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);

      await expectLater(
        prepareBorderRuntimeBundle(
          fixture.bundle(
            isVisible: false,
            unmaterialized: true,
          ),
        ),
        throwsA(
          isA<BorderRuntimeReadinessException>()
              .having((error) => error.layerId, 'layer', 'border')
              .having((error) => error.featureId, 'feature', 'coast')
              .having(
                (error) => error.state,
                'state',
                BorderMaterializationState.unmaterialized,
              ),
        ),
      );
    });

    test('blocks an altered persisted output fingerprint', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final original = fixture.materialization;
      final altered = BorderMaterialization(
        receipt: original.receipt,
        ground: <BorderResolvedGroundCell>[
          BorderResolvedGroundCell(
            x: 1,
            y: 0,
            visualSnapshotId: fixture.snapshot.id,
            resolvedRole: SurfaceVariantRole.isolated,
          ),
        ],
        placements: original.placements,
      );

      await expectLater(
        prepareBorderRuntimeBundle(fixture.bundle(materialization: altered)),
        throwsA(
          isA<BorderRuntimeReadinessException>()
              .having(
                (error) => error.state,
                'state',
                BorderMaterializationState.invalid,
              )
              .having(
                (error) => error.reasons,
                'reasons',
                contains(BorderStalenessReason.outputAltered),
              ),
        ),
      );
    });

    test('blocks a tampered persisted receipt fingerprint', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final original = fixture.materialization;
      final receipt = original.receipt;
      final tampered = BorderMaterialization(
        receipt: BorderResolutionReceipt(
          resolverVersion: receipt.resolverVersion,
          blueprintRevision: receipt.blueprintRevision,
          components: receipt.components,
          inputFingerprint: 'sha256:${'0' * 64}',
          outputFingerprint: receipt.outputFingerprint,
        ),
        ground: original.ground,
        placements: original.placements,
      );

      await expectLater(
        prepareBorderRuntimeBundle(fixture.bundle(materialization: tampered)),
        throwsA(
          isA<BorderRuntimeReadinessException>().having(
            (error) => error.state,
            'state',
            BorderMaterializationState.invalid,
          ),
        ),
      );
    });

    test('blocks missing and corrupt used snapshot files', () async {
      for (final mutation in <Future<void> Function(_Fixture)>[
        (fixture) => fixture.snapshotFile.delete(),
        (fixture) => fixture.snapshotFile.writeAsBytes(<int>[1, 2, 3]),
        (fixture) async {
          final changed = img.Image(width: 1, height: 1, numChannels: 4)
            ..setPixelRgba(0, 0, 13, 34, 56, 255);
          await fixture.snapshotFile.writeAsBytes(img.encodePng(changed));
        },
      ]) {
        final fixture = await _Fixture.create();
        addTearDown(fixture.dispose);
        await mutation(fixture);

        await expectLater(
          prepareBorderRuntimeBundle(fixture.bundle()),
          throwsA(
            isA<BorderRuntimeReadinessException>().having(
              (error) => error.reasons,
              'reasons',
              contains(BorderStalenessReason.visualSnapshotMissingOrCorrupt),
            ),
          ),
        );
      }
    });

    test('copyWith preserves preparation only when no source input changes',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final prepared = await prepareBorderRuntimeBundle(fixture.bundle());

      final unrelatedMapEdit = prepared.copyWith(
        map: prepared.map.copyWith(name: 'Renamed only'),
      );
      final borderEdit = prepared.copyWith(
        map: fixture.bundle(unmaterialized: true).map,
        borderRuntimePreparation: prepared.borderRuntimePreparation,
      );
      final catalogEdit = prepared.copyWith(
        manifest: prepared.manifest.copyWith(
          borderCatalog: const ProjectBorderCatalog.empty(),
        ),
      );
      final rootEdit = prepared.copyWith(
        projectRootDirectory: p.join(fixture.root.path, 'moved'),
      );

      expect(prepared.copyWith().borderRuntimePreparation,
          same(prepared.borderRuntimePreparation));
      expect(unrelatedMapEdit.borderRuntimePreparation, isNull);
      expect(borderEdit.borderRuntimePreparation, isNull);
      expect(catalogEdit.borderRuntimePreparation, isNull);
      expect(rootEdit.borderRuntimePreparation, isNull);
    });

    test('Border materialization does not change gameplay collision results',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final bundle = fixture.bundle();
      final baselineMap = bundle.map.copyWith(layers: const <MapLayer>[]);
      final baseline = GameplayWorldState.initial(
        map: baselineMap,
        playerPos: const GridPos(x: 0, y: 0),
        project: bundle.manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final withBorder = GameplayWorldState.initial(
        map: bundle.map,
        playerPos: const GridPos(x: 0, y: 0),
        project: bundle.manifest,
        tileWidth: 16,
        tileHeight: 16,
      );

      for (var x = 0; x < bundle.map.size.width; x += 1) {
        expect(
          withBorder.movementBlockReasonAt(
            x: x,
            y: 0,
            movementMode: MovementMode.walk,
          ),
          baseline.movementBlockReasonAt(
            x: x,
            y: 0,
            movementMode: MovementMode.walk,
          ),
        );
      }
    });
  });

  test('loadRuntimeMapBundle returns a Border-ready bundle', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final projectFilePath = await fixture.writeProject();

    final loaded = await loadRuntimeMapBundle(
      projectFilePath: projectFilePath,
      mapId: 'map',
    );

    expect(loaded.borderRuntimePreparation, isNotNull);
    expect(
      loaded.borderRuntimePreparation!.assetCollection.snapshots.single
          .snapshotId,
      fixture.snapshot.id,
    );
  });

  group('Border runtime host gate', () {
    test('RuntimeMapGame prepares and renders a real snapshot before mount',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final game = RuntimeMapGame(bundle: fixture.bundle());

      game.onGameResize(Vector2(32, 16));
      await game.onLoad();

      final layer = game.world.children.whereType<MapLayersComponent>().single;
      expect(layer.borderAssets, isNotNull);
      final rendered = await _render(layer, width: 32, height: 16);
      expect(await _rgbaAt(rendered, 8, 8), <int>[12, 34, 56, 255]);
    });

    test('PlayableMapGame prepares and renders a real snapshot before mount',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final game = PlayableMapGame(
        bundle: fixture.bundle(),
        projectFilePath: p.join(fixture.root.path, 'project.json'),
      );

      game.onGameResize(Vector2(32, 16));
      await game.onLoad();

      final layer =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (component) =>
                    component.renderPass == MapLayerRenderPass.background,
              );
      expect(layer.borderAssets, isNotNull);
      final rendered = await _render(layer, width: 32, height: 16);
      expect(await _rgbaAt(rendered, 8, 8), <int>[12, 34, 56, 255]);
    });

    test('PlayableMapGame revalidates an invalid bundleTransformer result',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final game = PlayableMapGame(
        bundle: fixture.bundle(),
        projectFilePath: p.join(fixture.root.path, 'project.json'),
        bundleTransformer: (_) => fixture.bundle(unmaterialized: true),
      );

      game.onGameResize(Vector2(32, 16));
      await expectLater(
        game.onLoad(),
        throwsA(isA<BorderRuntimeReadinessException>()),
      );
      expect(game.world.children.whereType<MapLayersComponent>(), isEmpty);
    });

    test('PlayableMapGame revalidates a prewarmed cached bundle before reuse',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final projectFilePath = await fixture.writeProject();
      final game = PlayableMapGame(
        bundle: fixture.bundle(),
        projectFilePath: projectFilePath,
      );

      game.onGameResize(Vector2(32, 16));
      await game.onLoad();
      await game.debugLoadRuntimeMapBundleCachedForTest('map');
      expect(game.debugIsMapLoaded('map'), isTrue);
      final mountedLayerCount =
          game.world.children.whereType<MapLayersComponent>().length;
      await fixture.snapshotFile.writeAsBytes(<int>[1, 2, 3]);

      await expectLater(
        game.debugLoadRuntimeMapBundleCachedForTest('map'),
        throwsA(isA<BorderRuntimeReadinessException>()),
      );
      expect(game.debugIsMapLoaded('map'), isTrue);
      expect(
        game.world.children.whereType<MapLayersComponent>().length,
        mountedLayerCount,
      );
    });
  });
}

Future<ui.Image> _render(
  MapLayersComponent component, {
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  return recorder.endRecording().toImage(width, height);
}

Future<List<int>> _rgbaAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return data!.buffer.asUint8List(offset, 4).toList(growable: false);
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.snapshot,
    required this.snapshotFile,
    required this.revision,
    required this.feature,
    required this.materialization,
  });

  final Directory root;
  final BorderVisualSnapshot snapshot;
  final File snapshotFile;
  final BorderBlueprintRevision revision;
  final BorderFeature feature;
  final BorderMaterialization materialization;

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_border_runtime_readiness_',
    );
    final rgba = Uint8List.fromList(<int>[12, 34, 56, 255]);
    final digest = computeBorderSnapshotContentFingerprint(
      frames: <BorderSnapshotContentFrame>[
        BorderSnapshotContentFrame(
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          durationMs: 100,
          rgbaBytes: rgba,
        ),
      ],
    );
    final relativePath = 'assets/borders/snapshots/$digest/frame_0000.png';
    final snapshotFile = File(p.join(root.path, relativePath));
    await snapshotFile.parent.create(recursive: true);
    final image = img.Image(width: 1, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 12, 34, 56, 255);
    await snapshotFile.writeAsBytes(img.encodePng(image));
    final snapshot = _snapshot(
      digest: digest,
      relativePath: relativePath,
    );
    final metrics = BorderPrimitiveAssetMetrics(
      assetFingerprint: 'source-asset',
      pixelSize: const GridSize(width: 1, height: 1),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
      defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
      occupancyMaskRle: 'border-rle-v1:1:1:1',
    );
    final params = BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    );
    final primitive = BorderPublishedPrimitive(
      id: 'rock',
      sourceElementId: 'source-rock',
      visualSnapshotId: snapshot.id,
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 0, y: 0),
      transforms: BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: const <int>[0],
      ),
      publishedMetrics: metrics,
    );
    final revision = BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Coast',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.organicEdge,
        primitives: <BorderPublishedPrimitive>[primitive],
        defaults: params,
        sortOrder: 0,
      ),
    );
    final feature = BorderFeature(
      id: 'coast',
      name: 'Coast',
      blueprintId: 'coast-blueprint',
      seed: BorderSignedInt64.zero,
      geometry: BorderRegionGeometry(
        width: 2,
        height: 1,
        cells: const <bool>[true, false],
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );
    final request = BorderResolutionRequest(
      mapSize: const GridSize(width: 2, height: 1),
      tileSizePx: const GridSize(width: 16, height: 16),
      blueprintId: feature.blueprintId,
      blueprintRevision: revision,
      feature: feature,
      visualSnapshots: <BorderVisualSnapshot>[snapshot],
      resolverVersion: borderResolverVersion,
    );
    final ground = <BorderResolvedGroundCell>[
      BorderResolvedGroundCell(
        x: 0,
        y: 0,
        visualSnapshotId: snapshot.id,
        resolvedRole: SurfaceVariantRole.isolated,
      ),
    ];
    final components = computeBorderInputFingerprints(request);
    final materialization = BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: borderResolverVersion,
        blueprintRevision: revision.revision,
        components: components,
        inputFingerprint: computeBorderAggregateInputFingerprint(
          resolverVersion: borderResolverVersion,
          blueprintRevision: revision.revision,
          components: components,
        ),
        outputFingerprint: computeBorderOutputFingerprint(
          ground: ground,
          placements: const <BorderResolvedPlacement>[],
        ),
      ),
      ground: ground,
      placements: const <BorderResolvedPlacement>[],
    );
    return _Fixture(
      root: root,
      snapshot: snapshot,
      snapshotFile: snapshotFile,
      revision: revision,
      feature: feature,
      materialization: materialization,
    );
  }

  RuntimeMapBundle bundle({
    bool includeBlueprint = true,
    bool isVisible = true,
    bool unmaterialized = false,
    BorderMaterialization? materialization,
    List<BorderVisualSnapshot> extraSnapshots = const <BorderVisualSnapshot>[],
  }) {
    final effectiveMaterialization =
        unmaterialized ? null : materialization ?? this.materialization;
    final feature = BorderFeature(
      id: this.feature.id,
      name: this.feature.name,
      blueprintId: this.feature.blueprintId,
      seed: this.feature.seed,
      geometry: this.feature.geometry,
      paramsOverride: this.feature.paramsOverride,
      overrides: this.feature.overrides,
      keepOutRegions: this.feature.keepOutRegions,
      materialization: effectiveMaterialization,
    );
    return RuntimeMapBundle(
      manifest: ProjectManifest(
        name: 'Border runtime readiness',
        version: ProjectVersion.v2,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
        borderCatalog: ProjectBorderCatalog(
          records: <BorderBlueprintRecord>[
            if (includeBlueprint) _record(revision),
          ],
          visualSnapshots: <BorderVisualSnapshot>[
            snapshot,
            ...extraSnapshots,
          ],
        ),
      ),
      map: MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 2, height: 1),
        layers: <MapLayer>[
          BorderLayer(
            id: 'border',
            name: 'Border',
            isVisible: isVisible,
            content: BorderLayerContent(features: <BorderFeature>[feature]),
          ),
        ],
      ),
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const <String, String>{},
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }

  Future<String> writeProject() async {
    final source = bundle();
    final manifest = source.manifest.copyWith(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map',
          name: 'Map',
          relativePath: 'maps/map.json',
        ),
      ],
    );
    final projectFile = File(p.join(root.path, 'project.json'));
    final mapFile = File(p.join(root.path, 'maps', 'map.json'));
    await mapFile.parent.create(recursive: true);
    await projectFile.writeAsString(jsonEncode(manifest.toJson()));
    await mapFile.writeAsString(jsonEncode(source.map.toJson()));
    return projectFile.path;
  }
}

BorderVisualSnapshot _snapshot({
  required String digest,
  required String relativePath,
}) =>
    BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$digest',
      contentFingerprint: digest,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: relativePath,
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          durationMs: 100,
        ),
      ],
    );

BorderBlueprintRecord _record(BorderBlueprintRevision revision) =>
    BorderBlueprintRecord(
      id: 'coast-blueprint',
      draft: BorderBlueprintDraft(
        baseRevision: revision.revision,
        definition: BorderBlueprintDraftDefinition(
          name: 'Draft',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.organicEdge,
          primitives: const <BorderPrimitiveDraft>[],
          defaults: revision.definition.defaults,
          sortOrder: 0,
        ),
      ),
      latestPublished: revision,
    );
