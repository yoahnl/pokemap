import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_preview_painter.dart';

void main() {
  group('buildEditorBorderPaintEntries', () {
    test('keeps authored layer/feature order with grounds before placements',
        () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 3, height: 2),
        layers: <MapLayer>[
          MapLayer.border(
            id: 'lower',
            name: 'Lower',
            opacity: 0.4,
            content: BorderLayerContent(
              features: <BorderFeature>[
                _feature('a', groundX: 0, placementX: 16),
                _feature('b', groundX: 1, placementX: 32),
              ],
            ),
          ),
          const MapLayer.tile(id: 'tile', name: 'Tile'),
          MapLayer.border(
            id: 'upper',
            name: 'Upper',
            content: BorderLayerContent(
              features: <BorderFeature>[
                _feature('c', groundX: 2, placementX: 48),
              ],
            ),
          ),
          MapLayer.border(
            id: 'hidden',
            name: 'Hidden',
            isVisible: false,
            content: BorderLayerContent(
              features: <BorderFeature>[
                _feature('hidden', groundX: 0, placementX: 0),
              ],
            ),
          ),
        ],
      );

      final entries = buildEditorBorderPaintEntries(map: map);

      expect(
        entries.map((entry) =>
            '${entry.layerId}/${entry.featureId}/${entry.kind.name}'),
        <String>[
          'lower/a/ground',
          'lower/b/ground',
          'lower/a/placement',
          'lower/b/placement',
          'upper/c/ground',
          'upper/c/placement',
        ],
      );
      expect(entries.first.layerOpacity, 0.4);
      expect(entries.where((entry) => entry.layerId == 'hidden'), isEmpty);
    });
  });
}

BorderFeature _feature(
  String id, {
  required int groundX,
  required int placementX,
}) {
  const fingerprint =
      'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  final ground = <BorderResolvedGroundCell>[
    BorderResolvedGroundCell(
      x: groundX,
      y: 0,
      visualSnapshotId: _snapshot,
      resolvedRole: SurfaceVariantRole.isolated,
    ),
  ];
  final placement = BorderResolvedPlacement(
    id: 'placement-$id',
    slotKey: 'slot-$id',
    primitiveId: 'primitive-$id',
    visualSnapshotId: _snapshot,
    anchorCell: GridPos(x: groundX, y: 0),
    topLeftWorldPx: BorderPixelPos(x: placementX, y: 0),
    opaqueWorldBoundsPx:
        BorderPixelRect(x: placementX, y: 0, width: 16, height: 16),
    transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
    drawBand: BorderDrawBand.structure,
    stableOrderKey: BorderStableOrderKey(
      drawBandIndex: 1,
      anchorRowMajor: groundX,
      passIndex: 0,
      rank: 0,
      ordinalLocal: 0,
      slotKey: 'slot-$id',
    ),
  );
  return BorderFeature(
    id: id,
    name: id,
    blueprintId: 'blueprint',
    seed: BorderSignedInt64.zero,
    geometry: BorderRegionGeometry(
      width: 3,
      height: 2,
      cells: const <bool>[true, false, false, false, false, false],
    ),
    overrides: const <BorderSlotOverride>[],
    keepOutRegions: const <BorderKeepOutRegion>[],
    materialization: BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: 1,
        blueprintRevision: 1,
        components: BorderInputFingerprints(
          blueprint: fingerprint,
          geometryAndSeed: fingerprint,
          parameters: fingerprint,
          overrides: fingerprint,
          keepOutRegions: fingerprint,
          mapContext: fingerprint,
          visualSnapshots: fingerprint,
        ),
        inputFingerprint: fingerprint,
        outputFingerprint: fingerprint,
      ),
      ground: ground,
      placements: <BorderResolvedPlacement>[placement],
    ),
  );
}

const _snapshot =
    'border-snapshot-sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
