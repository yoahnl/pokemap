import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_map_render_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renders revision-bound collision, zone, warp and entity overlays',
      () async {
    final fixture = _fixture();
    final result = await const RuntimeAuthoringMapRenderAdapter().render(
      MapRenderRequest(
        mapResource: AuthoringResourceRef(
          kind: 'map',
          id: fixture.map.id,
          revision: _revision('a'),
        ),
        manifest: fixture.manifest,
        map: fixture.map,
        layerIds: const ['base'],
        overlays: const {
          MapRenderOverlay.collision,
          MapRenderOverlay.zones,
          MapRenderOverlay.warps,
          MapRenderOverlay.entities,
        },
        cellPixelSize: 4,
      ),
    );

    expect(result.mimeType, 'image/png');
    expect(result.sourceRevision, _revision('a'));
    expect(result.width, 12);
    expect(result.height, 8);
    expect(result.bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(result.overlayCounts, {
      MapRenderOverlay.collision: 1,
      MapRenderOverlay.zones: 1,
      MapRenderOverlay.warps: 1,
      MapRenderOverlay.entities: 1,
    });

    final bitmap = img.decodePng(Uint8List.fromList(result.bytes))!;
    final collision = bitmap.getPixel(2, 2);
    final zone = bitmap.getPixel(6, 2);
    final warp = bitmap.getPixel(10, 2);
    final entity = bitmap.getPixel(2, 6);
    expect(_rgba(collision), isNot(_rgba(zone)));
    expect(_rgba(zone), isNot(_rgba(warp)));
    expect(_rgba(warp), isNot(_rgba(entity)));
  });

  test('renders only the requested region and counts visible overlays',
      () async {
    final fixture = _fixture();
    final result = await const RuntimeAuthoringMapRenderAdapter().render(
      MapRenderRequest(
        mapResource: AuthoringResourceRef(
          kind: 'map',
          id: fixture.map.id,
          revision: _revision('b'),
        ),
        manifest: fixture.manifest,
        map: fixture.map,
        region: const MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 2, height: 1),
        ),
        overlays: const {
          MapRenderOverlay.collision,
          MapRenderOverlay.zones,
          MapRenderOverlay.warps,
          MapRenderOverlay.entities,
        },
        cellPixelSize: 4,
      ),
    );

    expect(result.width, 8);
    expect(result.height, 4);
    expect(result.region.pos, const GridPos(x: 1, y: 0));
    expect(result.overlayCounts, {
      MapRenderOverlay.collision: 0,
      MapRenderOverlay.zones: 1,
      MapRenderOverlay.warps: 1,
      MapRenderOverlay.entities: 0,
    });
  });
}

({ProjectManifest manifest, MapData map}) _fixture() {
  const map = MapData(
    id: 'preview',
    name: 'Preview',
    size: GridSize(width: 3, height: 2),
    layers: [
      TileLayer(
        id: 'base',
        name: 'Base',
        palette: [
          TileLayerPaletteEntry(tilesetId: 'base', localTileId: 0),
          TileLayerPaletteEntry(tilesetId: 'base', localTileId: 1),
          TileLayerPaletteEntry(tilesetId: 'base', localTileId: 2),
          TileLayerPaletteEntry(tilesetId: 'base', localTileId: 3),
          TileLayerPaletteEntry(tilesetId: 'base', localTileId: 4),
          TileLayerPaletteEntry(tilesetId: 'base', localTileId: 5),
        ],
        cells: [1, 2, 3, 4, 5, 6],
      ),
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
        targetMapId: 'preview',
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
  const manifest = ProjectManifest(
    name: 'Runtime preview',
    maps: [
      ProjectMapEntry(
        id: 'preview',
        name: 'Preview',
        relativePath: 'maps/preview.json',
      ),
    ],
    tilesets: [],
  );
  return (manifest: manifest, map: map);
}

String _revision(String digit) => 'sha256:${List.filled(64, digit).join()}';

List<num> _rgba(img.Pixel pixel) => [pixel.r, pixel.g, pixel.b, pixel.a];
