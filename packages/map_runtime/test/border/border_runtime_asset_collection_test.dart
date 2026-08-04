import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/border/border_runtime_asset_collection.dart';

const _digestA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _digestB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _digestC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  test(
    'collects only materialized snapshots including hidden layers in stable '
    'first-reference order',
    () {
      final groundSnapshot = _snapshot(
        digest: _digestB,
        paths: const <String>['ground.png'],
      );
      final placementSnapshot = _snapshot(
        digest: _digestA,
        paths: const <String>['placement_0.png', 'placement_1.png'],
        durationsMs: const <int>[80, 120],
      );
      final unusedSnapshot = _snapshot(
        digest: _digestC,
        paths: const <String>['unused.png'],
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: const GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.border(
            id: 'hidden-border',
            name: 'Hidden Border',
            isVisible: false,
            content: BorderLayerContent(
              features: <BorderFeature>[
                _feature(
                  id: 'feature-1',
                  groundSnapshotId: groundSnapshot.id,
                  placementSnapshotIds: <String>[
                    placementSnapshot.id,
                    groundSnapshot.id,
                  ],
                ),
                _feature(id: 'unmaterialized'),
              ],
            ),
          ),
        ],
      );

      final collection = collectBorderRuntimeAssetRequests(
        map: map,
        catalog: ProjectBorderCatalog(
          visualSnapshots: <BorderVisualSnapshot>[
            placementSnapshot,
            unusedSnapshot,
            groundSnapshot,
          ],
        ),
      );

      expect(
        collection.snapshots.map((snapshot) => snapshot.snapshotId),
        <String>[groundSnapshot.id, placementSnapshot.id],
      );
      expect(
        collection.snapshots.last.frames
            .map((frame) => frame.relativeAssetPath),
        <String>[
          'assets/borders/snapshots/$_digestA/placement_0.png',
          'assets/borders/snapshots/$_digestA/placement_1.png',
        ],
      );
      expect(
        collection.snapshots.last.frames.map((frame) => frame.frameIndex),
        <int>[0, 1],
      );
      expect(
        collection.snapshots.last.frames.map((frame) => frame.durationMs),
        <int>[80, 120],
      );
    },
  );

  test('surfaces a missing snapshot reference instead of consulting sources',
      () {
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Border',
          content: BorderLayerContent(
            features: <BorderFeature>[
              _feature(
                id: 'feature',
                placementSnapshotIds: const <String>[
                  'border-snapshot-sha256:$_digestA',
                ],
              ),
            ],
          ),
        ),
      ],
    );

    expect(
      () => collectBorderRuntimeAssetRequests(
        map: map,
        catalog: const ProjectBorderCatalog.empty(),
      ),
      throwsA(
        isA<AssetNotFoundException>().having(
          (error) => error.toString(),
          'message',
          contains('border-snapshot-sha256:$_digestA'),
        ),
      ),
    );
  });
}

BorderVisualSnapshot _snapshot({
  required String digest,
  required List<String> paths,
  List<int>? durationsMs,
}) {
  return BorderVisualSnapshot(
    id: 'border-snapshot-sha256:$digest',
    contentFingerprint: digest,
    frames: <BorderVisualFrameSnapshot>[
      for (var index = 0; index < paths.length; index += 1)
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/$digest/${paths[index]}',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 3),
          durationMs: durationsMs?[index] ?? 100,
        ),
    ],
  );
}

BorderFeature _feature({
  required String id,
  String? groundSnapshotId,
  List<String> placementSnapshotIds = const <String>[],
}) {
  final hasMaterialization =
      groundSnapshotId != null || placementSnapshotIds.isNotEmpty;
  return BorderFeature(
    id: id,
    name: id,
    blueprintId: 'blueprint',
    seed: BorderSignedInt64.zero,
    geometry: BorderRegionGeometry(
      width: 1,
      height: 1,
      cells: const <bool>[true],
    ),
    overrides: const <BorderSlotOverride>[],
    keepOutRegions: const <BorderKeepOutRegion>[],
    materialization: hasMaterialization
        ? BorderMaterialization(
            receipt: _receipt(),
            ground: groundSnapshotId == null
                ? const <BorderResolvedGroundCell>[]
                : <BorderResolvedGroundCell>[
                    BorderResolvedGroundCell(
                      x: 0,
                      y: 0,
                      visualSnapshotId: groundSnapshotId,
                      resolvedRole: BorderGroundVariantRole.isolated,
                    ),
                  ],
            placements: <BorderResolvedPlacement>[
              for (var index = 0;
                  index < placementSnapshotIds.length;
                  index += 1)
                _placement(
                  index: index,
                  snapshotId: placementSnapshotIds[index],
                ),
            ],
          )
        : null,
  );
}

BorderResolvedPlacement _placement({
  required int index,
  required String snapshotId,
}) {
  final slot = 'slot-$index';
  return BorderResolvedPlacement(
    id: 'placement-$index',
    slotKey: slot,
    primitiveId: 'primitive-$index',
    visualSnapshotId: snapshotId,
    anchorCell: const GridPos(x: 0, y: 0),
    topLeftWorldPx: BorderPixelPos(x: index, y: 0),
    opaqueWorldBoundsPx: BorderPixelRect(x: index, y: 0, width: 1, height: 1),
    transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
    drawBand: BorderDrawBand.structure,
    stableOrderKey: BorderStableOrderKey(
      drawBandIndex: BorderDrawBand.structure.stableV1Index,
      anchorRowMajor: 0,
      passIndex: 0,
      rank: 0,
      ordinalLocal: index,
      slotKey: slot,
    ),
  );
}

BorderResolutionReceipt _receipt() {
  const hash =
      'sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
  return BorderResolutionReceipt(
    resolverVersion: 1,
    blueprintRevision: 1,
    components: BorderInputFingerprints(
      blueprint: hash,
      geometryAndSeed: hash,
      parameters: hash,
      overrides: hash,
      keepOutRegions: hash,
      mapContext: hash,
      visualSnapshots: hash,
    ),
    inputFingerprint: hash,
    outputFingerprint: hash,
  );
}
