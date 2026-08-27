import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_asset_map_render_adapter.dart';

import '../../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns asset-accurate bytes bound to the requested map revision',
      () async {
    final map = _map('asset-map');
    final bundle = surfaceTestBundle(
      map: map,
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
    );
    final adapter = RuntimeAuthoringAssetMapRenderAdapter(
      bundleLoader: (_) async => bundle,
      tilesetImageLoader: (_) async => {
        'entity': await runtimeTilesetImage(const [Color(0xFF29B34A)]),
      },
    );

    final result = await adapter.render(
      MapRenderRequest(
        mapResource: AuthoringResourceRef(
          kind: 'map',
          id: map.id,
          revision: _revision('a'),
        ),
        manifest: bundle.manifest.copyWith(
          maps: [
            ProjectMapEntry(
              id: map.id,
              name: map.name,
              relativePath: 'maps/${map.id}.json',
            ),
          ],
        ),
        map: map,
        cellPixelSize: 32,
      ),
    );

    final bitmap = img.decodePng(Uint8List.fromList(result.bytes))!;
    final center = bitmap.getPixel(16, 16);
    expect(result.sourceRevision, _revision('a'));
    expect(
      [center.r.toInt(), center.g.toInt(), center.b.toInt(), center.a.toInt()],
      [41, 179, 74, 255],
    );
  });

  test('rejects a bundle loaded from a different map revision', () async {
    final requestedMap = _map('requested');
    final adapter = RuntimeAuthoringAssetMapRenderAdapter(
      bundleLoader: (_) async => surfaceTestBundle(map: _map('loaded')),
      tilesetImageLoader: (_) async => const {},
    );

    expect(
      () => adapter.render(
        MapRenderRequest(
          mapResource: AuthoringResourceRef(
            kind: 'map',
            id: requestedMap.id,
            revision: _revision('b'),
          ),
          manifest: ProjectManifest(
            name: 'Revision test',
            maps: [
              ProjectMapEntry(
                id: requestedMap.id,
                name: requestedMap.name,
                relativePath: 'maps/${requestedMap.id}.json',
              ),
            ],
            tilesets: const [],
          ),
          map: requestedMap,
        ),
      ),
      throwsA(
        isA<ProjectSnapshotException>().having(
          (error) => error.code,
          'code',
          'map.render_revision_mismatch',
        ),
      ),
    );
  });
}

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 1, height: 1),
      layers: const [
        MapLayer.tile(id: 'decor', name: 'Decor', cells: [0]),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'tree-1',
          layerId: 'decor',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );

String _revision(String digit) => 'sha256:${List.filled(64, digit).join()}';
