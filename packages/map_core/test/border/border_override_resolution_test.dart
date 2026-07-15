import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/masonry_line_fixture.dart';

void main() {
  group('resolveBorderOverrides', () {
    test('preserves an override-free base resolution exactly', () {
      final request = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(request).materialization!;

      final resolved = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.ground, base.ground);
      expect(resolved.placements, base.placements);
      expect(resolved.diagnosticReport.hasDiagnostics, isFalse);
      expect(resolved.orphanedSlotKeys, isEmpty);
      expect(resolved.intentionalGapSlotKeys, isEmpty);
    });

    test('suppresses one stable slot without changing any other slot', () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements[base.placements.length ~/ 2];
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(slotKey: target.slotKey, suppressed: true),
        ],
      );

      final resolved = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(
        resolved.placements,
        base.placements
            .where((placement) => placement.slotKey != target.slotKey),
      );
      expect(resolved.intentionalGapSlotKeys, <String>{target.slotKey});
      expect(resolved.diagnosticReport.hasDiagnostics, isFalse);
    });

    test('replaces, moves, and transforms one slot while preserving its key',
        () {
      final primitives = <BorderPublishedPrimitive>[
        masonryPrimitive(
          id: 'a-base',
          fingerprintCharacter: '1',
          allowFlipX: true,
        ),
        masonryPrimitive(
          id: 'z-replacement',
          fingerprintCharacter: '2',
          allowFlipX: true,
        ),
      ];
      final baseRequest = MasonryLineFixture(
        primitives: primitives,
        parameters: masonryParameters(variationPermille: 0),
      ).request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(
            slotKey: target.slotKey,
            replacementPrimitiveId: 'z-replacement',
            offsetDeltaPx: const BorderPixelOffset(x: 2, y: -1),
            transformOverride: BorderSpriteTransform(
              quarterTurns: target.transform.quarterTurns,
              flipX: true,
            ),
          ),
        ],
      );

      final resolved = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.diagnosticReport.hasDiagnostics, isFalse);
      final changed = resolved.placements.singleWhere(
        (placement) => placement.slotKey == target.slotKey,
      );
      expect(changed.id, target.id);
      expect(changed.slotKey, target.slotKey);
      expect(changed.stableOrderKey, target.stableOrderKey);
      expect(changed.anchorCell, target.anchorCell);
      expect(changed.primitiveId, 'z-replacement');
      expect(changed.visualSnapshotId, primitives.last.visualSnapshotId);
      expect(changed.transform.flipX, isTrue);
      final oldTarget = _targetAnchorWorldPx(target, primitives.first);
      final newTarget = _targetAnchorWorldPx(changed, primitives.last);
      expect(newTarget.x, oldTarget.x + 2);
      expect(newTarget.y, oldTarget.y - 1);
      expect(
        resolved.placements
            .where((placement) => placement.slotKey != target.slotKey),
        base.placements
            .where((placement) => placement.slotKey != target.slotKey),
      );
    });

    test('uses variationSalt deterministically and only for its local slot',
        () {
      final primitives = <BorderPublishedPrimitive>[
        masonryPrimitive(
          id: 'a-base',
          fingerprintCharacter: '3',
          weight: 1,
        ),
        masonryPrimitive(
          id: 'z-local-variant',
          fingerprintCharacter: '4',
          weight: 1000,
        ),
      ];
      final baseRequest = MasonryLineFixture(
        primitives: primitives,
        parameters: masonryParameters(variationPermille: 0),
      ).request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(
            slotKey: target.slotKey,
            variationSalt: BorderSignedInt64.fromInt(9),
          ),
        ],
      );

      BorderOverrideResolution resolve() => resolveBorderOverrides(
            request: request,
            baseGround: base.ground,
            basePlacements: base.placements,
          );

      final first = resolve();
      final second = resolve();
      expect(first, second);
      expect(
        first.placements
            .singleWhere(
              (placement) => placement.slotKey == target.slotKey,
            )
            .primitiveId,
        'z-local-variant',
      );
      expect(
        first.placements
            .where((placement) => placement.slotKey != target.slotKey),
        base.placements
            .where((placement) => placement.slotKey != target.slotKey),
      );
    });

    test('honors a locked placement byte-for-byte including exact order', () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final locked = _movePlacement(target, x: 1, y: 0);
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(
            slotKey: target.slotKey,
            locked: true,
            lockedPlacement: locked,
            replacementPrimitiveId: locked.primitiveId,
            offsetDeltaPx: const BorderPixelOffset(x: 1, y: 0),
            transformOverride: locked.transform,
          ),
        ],
      );

      final resolved = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.diagnosticReport.hasDiagnostics, isFalse);
      expect(
        resolved.placements.singleWhere(
          (placement) => placement.slotKey == target.slotKey,
        ),
        locked,
      );
    });

    test('keeps orphan overrides attached and diagnoses them deterministically',
        () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(slotKey: 'orphan-z', suppressed: true),
          _override(slotKey: 'orphan-a', suppressed: true),
        ],
      );

      final first = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );
      final second = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(first, second);
      expect(first.placements, base.placements);
      expect(first.orphanedSlotKeys, <String>{'orphan-a', 'orphan-z'});
      expect(first.orphanedSlotKeys.toList(), <String>['orphan-a', 'orphan-z']);
      expect(
        first.diagnostics.map((diagnostic) => diagnostic.code),
        everyElement('border.resolution.override_orphaned'),
      );
      expect(
        first.diagnostics.map((diagnostic) => diagnostic.slotKey),
        <String>['orphan-a', 'orphan-z'],
      );
      expect(first.diagnosticReport.hasErrors, isFalse);
      expect(first.diagnosticReport.hasWarnings, isTrue);
    });

    test('validates published references before diagnosing an orphan', () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final resolved = resolveBorderOverrides(
        request: _copyRequest(
          baseRequest,
          overrides: <BorderSlotOverride>[
            _override(
              slotKey: 'orphan-with-missing-primitive',
              replacementPrimitiveId: 'missing-primitive',
            ),
          ],
        ),
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.placements, base.placements);
      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'border.resolution.override_primitive_missing',
          'border.resolution.override_orphaned',
        ]),
      );
      expect(resolved.diagnosticReport.hasErrors, isTrue);
    });

    test('validates primitive, transform, snapshot, corridor, and canvas', () {
      final baseRequest = MasonryLineFixture(
        parameters: masonryParameters(variationPermille: 0),
      ).request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final cases = <BorderSlotOverride>[
        _override(
          slotKey: target.slotKey,
          replacementPrimitiveId: 'missing-primitive',
        ),
        _override(
          slotKey: target.slotKey,
          transformOverride: BorderSpriteTransform(
            quarterTurns: target.transform.quarterTurns,
            flipX: true,
          ),
        ),
        _override(
          slotKey: target.slotKey,
          offsetDeltaPx: const BorderPixelOffset(x: 10000, y: 0),
        ),
        _override(
          slotKey: target.slotKey,
          locked: true,
          lockedPlacement: _copyPlacement(
            target,
            visualSnapshotId: _snapshotId('f'),
          ),
        ),
      ];
      final expectedCodes = <String>[
        'border.resolution.override_primitive_missing',
        'border.resolution.override_transform_not_allowed',
        'border.resolution.override_outside_corridor',
        'border.resolution.override_snapshot_invalid',
      ];

      for (var index = 0; index < cases.length; index += 1) {
        final resolved = resolveBorderOverrides(
          request: _copyRequest(
            baseRequest,
            overrides: <BorderSlotOverride>[cases[index]],
          ),
          baseGround: base.ground,
          basePlacements: base.placements,
        );

        expect(
          resolved.diagnostics.map((diagnostic) => diagnostic.code),
          contains(expectedCodes[index]),
          reason: 'case $index: ${resolved.diagnostics}',
        );
        expect(resolved.diagnosticReport.hasErrors, isTrue);
      }
    });

    test('rejects a moved placement whose opaque pixels leave the canvas', () {
      final primitive = masonryPrimitive(
        id: 'canvas-check',
        fingerprintCharacter: '6',
      );
      final baseRequest = MasonryLineFixture(
        primitives: <BorderPublishedPrimitive>[primitive],
      ).request;
      final basePlacement = _placementForPrimitive(
        primitive,
        topLeft: const BorderPixelPos(x: 5, y: 5),
      );
      final resolved = resolveBorderOverrides(
        request: _copyRequest(
          baseRequest,
          overrides: <BorderSlotOverride>[
            _override(
              slotKey: basePlacement.slotKey,
              offsetDeltaPx: const BorderPixelOffset(x: -17, y: 0),
            ),
          ],
        ),
        baseGround: const <BorderResolvedGroundCell>[],
        basePlacements: <BorderResolvedPlacement>[basePlacement],
      );

      expect(resolved.placements, <BorderResolvedPlacement>[basePlacement]);
      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.override_outside_canvas'),
      );
    });

    test('accepts the exact movement-corridor bound and rejects one pixel past',
        () {
      final primitive = masonryPrimitive(
        id: 'corridor-check',
        fingerprintCharacter: '9',
      );
      final baseRequest = MasonryLineFixture(
        primitives: <BorderPublishedPrimitive>[primitive],
      ).request;
      final basePlacement = _placementForPrimitive(
        primitive,
        topLeft: const BorderPixelPos(x: 40, y: 40),
      );
      final radius = _corridorRadius(baseRequest);

      BorderOverrideResolution resolve(int deltaX) => resolveBorderOverrides(
            request: _copyRequest(
              baseRequest,
              overrides: <BorderSlotOverride>[
                _override(
                  slotKey: basePlacement.slotKey,
                  offsetDeltaPx: BorderPixelOffset(x: deltaX, y: 0),
                ),
              ],
            ),
            baseGround: const <BorderResolvedGroundCell>[],
            basePlacements: <BorderResolvedPlacement>[basePlacement],
          );

      final atBoundary = resolve(radius);
      final outside = resolve(radius + 1);

      expect(atBoundary.diagnosticReport.hasDiagnostics, isFalse);
      expect(
        _targetAnchorWorldPx(atBoundary.placements.single, primitive).x,
        _targetAnchorWorldPx(basePlacement, primitive).x + radius,
      );
      expect(outside.placements, <BorderResolvedPlacement>[basePlacement]);
      expect(
        outside.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.override_outside_corridor'),
      );
    });

    test('rejects a locked primitive whose role changes the stable slot', () {
      final structure = masonryPrimitive(
        id: 'structure',
        fingerprintCharacter: '7',
      );
      final surfacePatch = masonryPrimitive(
        id: 'surface-patch',
        fingerprintCharacter: '8',
        role: BorderPrimitiveRole.surfacePatch,
      );
      final baseRequest = MasonryLineFixture(
        primitives: <BorderPublishedPrimitive>[structure, surfacePatch],
        parameters: masonryParameters(
          detailDensityPermille: 0,
          variationPermille: 0,
        ),
      ).request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final locked = _copyPlacement(
        target,
        primitiveId: surfacePatch.id,
        visualSnapshotId: surfacePatch.visualSnapshotId,
      );
      final resolved = resolveBorderOverrides(
        request: _copyRequest(
          baseRequest,
          overrides: <BorderSlotOverride>[
            _override(
              slotKey: target.slotKey,
              locked: true,
              lockedPlacement: locked,
            ),
          ],
        ),
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.override_primitive_role_mismatch'),
      );
      expect(resolved.diagnosticReport.hasErrors, isTrue);
      expect(
        resolved.placements.singleWhere(
          (placement) => placement.slotKey == target.slotKey,
        ),
        target,
      );
    });

    test('uses transformed real opaque pixels for keep-out filtering', () {
      final transparentAtKeepOut = List<bool>.filled(16, false)..[3] = true;
      final opaqueAtKeepOut = List<bool>.filled(16, false)..[5] = true;
      final transform = BorderSpriteTransform(quarterTurns: 1, flipX: true);

      BorderOverrideResolution resolve(List<bool> occupancy) {
        final primitive = masonryPrimitive(
          id: 'sparse',
          fingerprintCharacter: '5',
          width: 4,
          height: 4,
          allowFlipX: true,
          anchorPx: const BorderPixelPos(x: 0, y: 0),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 4, height: 4),
          occupancy: occupancy,
        );
        final source = MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[primitive],
          keepOutRegions: <BorderKeepOutRegion>[_keepOutCell(1, 1)],
        ).request;
        final placement = _placementForPrimitive(
          primitive,
          topLeft: const BorderPixelPos(x: 15, y: 15),
          transform: transform,
        );
        return resolveBorderOverrides(
          request: source,
          baseGround: const <BorderResolvedGroundCell>[],
          basePlacements: <BorderResolvedPlacement>[placement],
        );
      }

      final transparent = resolve(transparentAtKeepOut);
      final opaque = resolve(opaqueAtKeepOut);

      expect(transparent.diagnosticReport.hasDiagnostics, isFalse);
      expect(transparent.placements, hasLength(1));
      expect(opaque.diagnosticReport.hasDiagnostics, isFalse);
      expect(opaque.placements, isEmpty);
      expect(opaque.intentionalGapSlotKeys, <String>{'slot-sparse'});
    });

    test('rejects a keep-out whose stable mask does not match the canvas', () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final badKeepOut = BorderKeepOutRegion(
        id: 'bad-size',
        region: BorderRegionGeometry(
          width: 1,
          height: 1,
          cells: const <bool>[true],
        ),
      );

      final resolved = resolveBorderOverrides(
        request: _copyRequest(
          baseRequest,
          keepOutRegions: <BorderKeepOutRegion>[badKeepOut],
        ),
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.diagnosticReport.hasErrors, isTrue);
      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.keep_out_size_mismatch'),
      );
      expect(resolved.placements, base.placements);
    });
  });
}

BorderSlotOverride _override({
  required String slotKey,
  BorderSignedInt64? variationSalt,
  bool suppressed = false,
  bool locked = false,
  BorderResolvedPlacement? lockedPlacement,
  String? replacementPrimitiveId,
  BorderPixelOffset? offsetDeltaPx,
  BorderSpriteTransform? transformOverride,
}) =>
    BorderSlotOverride(
      slotKey: slotKey,
      variationSalt: variationSalt ?? BorderSignedInt64.zero,
      suppressed: suppressed,
      locked: locked,
      lockedPlacement: lockedPlacement,
      replacementPrimitiveId: replacementPrimitiveId,
      offsetDeltaPx: offsetDeltaPx,
      transformOverride: transformOverride,
    );

BorderResolutionRequest _copyRequest(
  BorderResolutionRequest source, {
  List<BorderSlotOverride>? overrides,
  List<BorderKeepOutRegion>? keepOutRegions,
}) =>
    BorderResolutionRequest(
      mapSize: source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: source.feature.seed,
        geometry: source.feature.geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: overrides ?? source.feature.overrides,
        keepOutRegions: keepOutRegions ?? source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

BorderResolvedPlacement _movePlacement(
  BorderResolvedPlacement source, {
  required int x,
  required int y,
}) =>
    _copyPlacement(
      source,
      topLeftWorldPx: BorderPixelPos(
        x: source.topLeftWorldPx.x + x,
        y: source.topLeftWorldPx.y + y,
      ),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: source.opaqueWorldBoundsPx.x + x,
        y: source.opaqueWorldBoundsPx.y + y,
        width: source.opaqueWorldBoundsPx.width,
        height: source.opaqueWorldBoundsPx.height,
      ),
    );

BorderResolvedPlacement _copyPlacement(
  BorderResolvedPlacement source, {
  String? primitiveId,
  String? visualSnapshotId,
  BorderPixelPos? topLeftWorldPx,
  BorderPixelRect? opaqueWorldBoundsPx,
}) =>
    BorderResolvedPlacement(
      id: source.id,
      slotKey: source.slotKey,
      primitiveId: primitiveId ?? source.primitiveId,
      visualSnapshotId: visualSnapshotId ?? source.visualSnapshotId,
      anchorCell: source.anchorCell,
      topLeftWorldPx: topLeftWorldPx ?? source.topLeftWorldPx,
      opaqueWorldBoundsPx: opaqueWorldBoundsPx ?? source.opaqueWorldBoundsPx,
      transform: source.transform,
      drawBand: source.drawBand,
      stableOrderKey: source.stableOrderKey,
    );

BorderResolvedPlacement _placementForPrimitive(
  BorderPublishedPrimitive primitive, {
  required BorderPixelPos topLeft,
  BorderSpriteTransform? transform,
}) =>
    BorderResolvedPlacement(
      id: 'placement-sparse',
      slotKey: 'slot-sparse',
      primitiveId: primitive.id,
      visualSnapshotId: primitive.visualSnapshotId,
      anchorCell: const GridPos(x: 1, y: 1),
      topLeftWorldPx: topLeft,
      opaqueWorldBoundsPx: BorderPixelRect(
        x: topLeft.x,
        y: topLeft.y,
        width: 4,
        height: 4,
      ),
      transform:
          transform ?? BorderSpriteTransform(quarterTurns: 0, flipX: false),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: borderDrawBandV1Index(BorderDrawBand.structure),
        anchorRowMajor: 9,
        passIndex: 0,
        rank: 0,
        ordinalLocal: 0,
        slotKey: 'slot-sparse',
      ),
    );

BorderKeepOutRegion _keepOutCell(int x, int y) => BorderKeepOutRegion(
      id: 'keep-out-$x-$y',
      region: BorderRegionGeometry(
        width: 8,
        height: 8,
        cells: <bool>[
          for (var index = 0; index < 64; index += 1) index == y * 8 + x,
        ],
      ),
    );

String _snapshotId(String character) =>
    'border-snapshot-sha256:${character * 64}';

BorderPixelPos _targetAnchorWorldPx(
  BorderResolvedPlacement placement,
  BorderPublishedPrimitive primitive,
) {
  final origin = resolveBorderSpriteGeometry(
    metrics: primitive.publishedMetrics,
    sourceAnchorPx: primitive.anchorPx,
    transform: placement.transform,
    targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
  );
  return BorderPixelPos(
    x: placement.topLeftWorldPx.x - origin.topLeftWorldPx.x,
    y: placement.topLeftWorldPx.y - origin.topLeftWorldPx.y,
  );
}

int _corridorRadius(BorderResolutionRequest request) {
  final definition = request.blueprintRevision!.definition;
  final parameters = request.feature.paramsOverride ?? definition.defaults;
  final tileSize = request.tileSizePx.width > request.tileSizePx.height
      ? request.tileSizePx.width
      : request.tileSizePx.height;
  return computeBorderDirtyHaloRadiusPx(
    depthRows: parameters.depthRows,
    tileSizePx: tileSize,
    largestTransformedOpaqueExtentPx: maximumBorderTransformedOpaqueExtentPx(
      definition.primitives.map((primitive) => primitive.publishedMetrics),
    ),
    jitterMaxPx: computeBorderJitterMaxPx(
      irregularityPermille: parameters.irregularityPermille,
      tileSizePx: tileSize,
    ),
    maxOverlapPx: parameters.maxOverlapPx,
    gapTolerancePx: parameters.gapTolerancePx,
  );
}
