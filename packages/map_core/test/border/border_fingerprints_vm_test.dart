@TestOn('vm')
library;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const String _snapshotId =
    'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('accepts max-safe but rejects positive and negative 2^53 inputs', () {
    final firstOutsidePortableRange = BigInt.one << 53;
    final maximumPortableInteger = firstOutsidePortableRange - BigInt.one;

    expect(
      computeBorderOutputFingerprint(
        ground: const <BorderResolvedGroundCell>[],
        placements: <BorderResolvedPlacement>[
          _placement(maximumPortableInteger.toInt()),
        ],
      ),
      matches(RegExp(r'^sha256:[0-9a-f]{64}$')),
    );
    expect(
      () => computeBorderOutputFingerprint(
        ground: const <BorderResolvedGroundCell>[],
        placements: <BorderResolvedPlacement>[
          _placement(firstOutsidePortableRange.toInt()),
        ],
      ),
      throwsA(
        isA<ValidationException>(),
      ),
    );
    expect(
      () => computeBorderOutputFingerprint(
        ground: const <BorderResolvedGroundCell>[],
        placements: <BorderResolvedPlacement>[
          _placement(-firstOutsidePortableRange.toInt()),
        ],
      ),
      throwsA(isA<ValidationException>()),
    );

    expect(
      computeBorderInputFingerprints(
        _requestWithMaxOverlap(maximumPortableInteger.toInt()),
      ).parameters,
      matches(RegExp(r'^sha256:[0-9a-f]{64}$')),
    );
    expect(
      () => computeBorderInputFingerprints(
        _requestWithMaxOverlap(firstOutsidePortableRange.toInt()),
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}

BorderResolvedPlacement _placement(int x) => BorderResolvedPlacement(
      id: 'placement-a',
      slotKey: 'slot-a',
      primitiveId: 'primitive-a',
      visualSnapshotId: _snapshotId,
      anchorCell: const GridPos(x: 0, y: 0),
      topLeftWorldPx: BorderPixelPos(x: x, y: 0),
      opaqueWorldBoundsPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
      transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: 1,
        anchorRowMajor: 0,
        passIndex: 0,
        rank: 0,
        ordinalLocal: 0,
        slotKey: 'slot-a',
      ),
    );

BorderResolutionRequest _requestWithMaxOverlap(int maxOverlapPx) {
  final defaults = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: maxOverlapPx,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  return BorderResolutionRequest(
    mapSize: const GridSize(width: 1, height: 1),
    tileSizePx: const GridSize(width: 16, height: 16),
    blueprintId: 'blueprint-a',
    blueprintRevision: BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Blueprint',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.organicEdge,
        primitives: const <BorderPublishedPrimitive>[],
        defaults: defaults,
        ground: null,
        categoryId: null,
        sortOrder: 0,
      ),
    ),
    feature: BorderFeature(
      id: 'feature-a',
      name: 'Feature',
      blueprintId: 'blueprint-a',
      seed: BorderSignedInt64.zero,
      geometry: BorderRegionGeometry(
        width: 1,
        height: 1,
        cells: const <bool>[true],
      ),
      paramsOverride: null,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
      materialization: null,
    ),
    visualSnapshots: const <BorderVisualSnapshot>[],
    resolverVersion: 1,
  );
}
