import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_asset_map_capture_service.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/border/border_runtime_asset_collection.dart';
import 'package:map_runtime/src/border/border_runtime_preparation.dart';

import '../../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('captures real placed-element pixels from the runtime renderer',
      () async {
    final result = await const RuntimeAuthoringAssetMapCaptureService().capture(
      bundle: surfaceTestBundle(
        map: const MapData(
          id: 'asset-capture',
          name: 'Asset capture',
          size: GridSize(width: 2, height: 1),
          layers: [
            MapLayer.tile(
              id: 'decor',
              name: 'Decor',
              cells: [0, 0],
            ),
          ],
          placedElements: [
            MapPlacedElement(
              id: 'tree-1',
              layerId: 'decor',
              elementId: 'tree',
              pos: GridPos(x: 0, y: 0),
            ),
          ],
        ),
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'entity',
            categoryId: 'nature',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      ),
      tileImagesByTilesetId: {
        'entity': await runtimeTilesetImage(const [Color(0xFF29B34A)]),
      },
      region: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 2, height: 1),
      ),
      layerIds: const [],
      overlays: const [],
      cellPixelSize: 32,
    );

    final bitmap = img.decodePng(result.bytes);

    expect(bitmap, isNotNull);
    expect(result.width, 64);
    expect(result.height, 32);
    final center = bitmap!.getPixel(16, 16);
    expect(
      [center.r.toInt(), center.g.toInt(), center.b.toInt(), center.a.toInt()],
      [41, 179, 74, 255],
    );
    expect(bitmap.getPixel(48, 16).a.toInt(), 0);
  });

  test('preserves canonical collision, zone, warp and entity overlays',
      () async {
    const map = MapData(
      id: 'overlay-capture',
      name: 'Overlay capture',
      size: GridSize(width: 3, height: 2),
      layers: [
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: [true, false, false, false, false, false],
        ),
      ],
      entities: [
        MapEntity(
          id: 'npc',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 0, y: 1),
          blocksMovement: false,
        ),
      ],
      warps: [
        MapWarp(
          id: 'door',
          pos: GridPos(x: 2, y: 0),
          targetMapId: 'overlay-capture',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
      gameplayZones: [
        MapGameplayZone(
          id: 'zone',
          kind: GameplayZoneKind.custom,
          area: MapRect(
            pos: GridPos(x: 1, y: 0),
            size: GridSize(width: 1, height: 1),
          ),
          special: SpecialZonePayload(),
        ),
      ],
    );
    final result = await const RuntimeAuthoringAssetMapCaptureService().capture(
      bundle: surfaceTestBundle(map: map),
      tileImagesByTilesetId: const {},
      region: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 3, height: 2),
      ),
      layerIds: const [],
      overlays: MapRenderOverlay.values,
      cellPixelSize: 4,
    );

    expect(result.overlayCounts, {
      MapRenderOverlay.collision: 1,
      MapRenderOverlay.zones: 1,
      MapRenderOverlay.warps: 1,
      MapRenderOverlay.entities: 1,
    });
  });

  test('loads prepared Border assets before capturing visible layers',
      () async {
    final root =
        await Directory.systemTemp.createTemp('pokemap-border-capture-');
    addTearDown(() => root.delete(recursive: true));
    const digest =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const snapshotId = 'border-snapshot-sha256:$digest';
    const relativePath = 'assets/borders/snapshots/$digest/frame_0000.png';
    final file = File('${root.path}/$relativePath');
    await file.parent.create(recursive: true);
    final frame = img.Image(width: 32, height: 32);
    img.fill(frame, color: img.ColorRgba8(255, 255, 0, 255));
    await file.writeAsBytes(img.encodePng(frame));

    final bundle = RuntimeMapBundle(
      manifest: ProjectManifest(
        name: 'Border capture',
        maps: const [],
        tilesets: const [],
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
          displayScale: 1,
        ),
      ),
      map: MapData(
        id: 'border-capture',
        name: 'Border capture',
        size: const GridSize(width: 1, height: 1),
        layers: [_borderLayer(snapshotId)],
      ),
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      borderRuntimePreparation: BorderRuntimePreparation(
        assetCollection: BorderRuntimeAssetCollection(
          snapshots: [
            BorderRuntimeSnapshotRequest(
              snapshotId: snapshotId,
              frames: [
                BorderRuntimeFrameRequest(
                  snapshotId: snapshotId,
                  frameIndex: 0,
                  relativeAssetPath: relativePath,
                  sourceRectPx: BorderPixelRect(
                    x: 0,
                    y: 0,
                    width: 32,
                    height: 32,
                  ),
                  durationMs: 100,
                  transparentColorArgb: null,
                ),
              ],
            ),
          ],
        ),
        snapshotIntegrity: const {},
        featureFreshness: const [],
      ),
    );

    final result = await const RuntimeAuthoringAssetMapCaptureService().capture(
      bundle: bundle,
      tileImagesByTilesetId: const {},
      region: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 1, height: 1),
      ),
      layerIds: const [],
      overlays: const [],
      cellPixelSize: 32,
    );

    final bitmap = img.decodePng(result.bytes)!;
    final center = bitmap.getPixel(16, 16);
    expect(
      [center.r.toInt(), center.g.toInt(), center.b.toInt(), center.a.toInt()],
      [255, 255, 0, 255],
    );
  });
}

BorderLayer _borderLayer(String snapshotId) {
  const receiptHash =
      'sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
  return BorderLayer(
    id: 'border',
    name: 'Border',
    content: BorderLayerContent(
      features: [
        BorderFeature(
          id: 'border-feature',
          name: 'Border feature',
          blueprintId: 'border-blueprint',
          seed: BorderSignedInt64.zero,
          geometry: BorderRegionGeometry(
            width: 1,
            height: 1,
            cells: const [true],
          ),
          overrides: const [],
          keepOutRegions: const [],
          materialization: BorderMaterialization(
            receipt: BorderResolutionReceipt(
              resolverVersion: 1,
              blueprintRevision: 1,
              components: BorderInputFingerprints(
                blueprint: receiptHash,
                geometryAndSeed: receiptHash,
                parameters: receiptHash,
                overrides: receiptHash,
                keepOutRegions: receiptHash,
                mapContext: receiptHash,
                visualSnapshots: receiptHash,
              ),
              inputFingerprint: receiptHash,
              outputFingerprint: receiptHash,
            ),
            ground: [
              BorderResolvedGroundCell(
                x: 0,
                y: 0,
                visualSnapshotId: snapshotId,
                resolvedRole: BorderGroundVariantRole.isolated,
              ),
            ],
            placements: const [],
          ),
        ),
      ],
    ),
  );
}
