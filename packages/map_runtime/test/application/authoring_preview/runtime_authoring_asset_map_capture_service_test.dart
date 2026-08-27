import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_asset_map_capture_service.dart';

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
}
