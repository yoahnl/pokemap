import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/border/border_runtime_draw_instruction.dart';

const _digestA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _digestB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _digestC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _digestD =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  test(
    'flattens every feature ground before placements without re-sorting '
    'persisted placement order',
    () {
      final layer = MapLayer.border(
        id: 'border',
        name: 'Border',
        isVisible: false,
        opacity: 0.6,
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              id: 'feature-a',
              groundSnapshotId: 'border-snapshot-sha256:$_digestA',
              placement: _placement(
                id: 'placement-a',
                snapshotId: 'border-snapshot-sha256:$_digestC',
                ordinal: 20,
                drawBand: BorderDrawBand.accent,
              ),
            ),
            _feature(
              id: 'feature-b',
              groundSnapshotId: 'border-snapshot-sha256:$_digestB',
              placement: _placement(
                id: 'placement-b',
                snapshotId: 'border-snapshot-sha256:$_digestD',
                ordinal: 1,
                drawBand: BorderDrawBand.outerAccent,
              ),
            ),
          ],
        ),
      );

      final collection = buildBorderRuntimeDrawInstructions(
        layer: layer as BorderLayer,
        tileWidthPx: 16,
        tileHeightPx: 24,
      );

      expect(collection.layerId, 'border');
      expect(collection.isVisible, isFalse);
      expect(collection.opacity, 0.6);
      expect(
        collection.instructions.map((instruction) => instruction.snapshotId),
        <String>[
          'border-snapshot-sha256:$_digestA',
          'border-snapshot-sha256:$_digestB',
          'border-snapshot-sha256:$_digestC',
          'border-snapshot-sha256:$_digestD',
        ],
      );
      expect(collection.instructions[0], isA<BorderRuntimeGroundInstruction>());
      expect(collection.instructions[1], isA<BorderRuntimeGroundInstruction>());
      expect(
        collection.instructions[2],
        isA<BorderRuntimePlacementInstruction>().having(
          (instruction) => instruction.placementId,
          'placementId',
          'placement-a',
        ),
      );
      expect(
        collection.instructions[3],
        isA<BorderRuntimePlacementInstruction>().having(
          (instruction) => instruction.placementId,
          'placementId',
          'placement-b',
        ),
      );
      expect(
        (collection.instructions.first as BorderRuntimeGroundInstruction)
            .worldBoundsPx,
        BorderPixelRect(x: 16, y: 24, width: 16, height: 24),
      );
    },
  );
}

BorderFeature _feature({
  required String id,
  required String groundSnapshotId,
  required BorderResolvedPlacement placement,
}) {
  return BorderFeature(
    id: id,
    name: id,
    blueprintId: 'blueprint',
    seed: BorderSignedInt64.zero,
    geometry: BorderRegionGeometry(
      width: 2,
      height: 2,
      cells: const <bool>[true, true, true, true],
    ),
    overrides: const <BorderSlotOverride>[],
    keepOutRegions: const <BorderKeepOutRegion>[],
    materialization: BorderMaterialization(
      receipt: _receipt(),
      ground: <BorderResolvedGroundCell>[
        BorderResolvedGroundCell(
          x: 1,
          y: 1,
          visualSnapshotId: groundSnapshotId,
          resolvedRole: SurfaceVariantRole.isolated,
        ),
      ],
      placements: <BorderResolvedPlacement>[placement],
    ),
  );
}

BorderResolvedPlacement _placement({
  required String id,
  required String snapshotId,
  required int ordinal,
  required BorderDrawBand drawBand,
}) {
  final slot = 'slot-$id';
  return BorderResolvedPlacement(
    id: id,
    slotKey: slot,
    primitiveId: 'primitive-$id',
    visualSnapshotId: snapshotId,
    anchorCell: const GridPos(x: 0, y: 0),
    topLeftWorldPx: BorderPixelPos(x: ordinal, y: ordinal + 1),
    opaqueWorldBoundsPx:
        BorderPixelRect(x: ordinal, y: ordinal + 1, width: 2, height: 3),
    transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
    drawBand: drawBand,
    stableOrderKey: BorderStableOrderKey(
      drawBandIndex: drawBand.stableV1Index,
      anchorRowMajor: 0,
      passIndex: 0,
      rank: 0,
      ordinalLocal: ordinal,
      slotKey: slot,
    ),
  );
}

BorderResolutionReceipt _receipt() {
  const hash =
      'sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
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
