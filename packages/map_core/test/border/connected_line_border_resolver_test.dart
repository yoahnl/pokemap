import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveConnectedLineBorder', () {
    test('classifies an open horizontal stroke as cap straight cap', () {
      final result = resolveConnectedLineBorder(_Fixture().request);

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      final placements = result.materialization!.placements;
      expect(_primitiveIds(placements), <String>[
        'cap',
        'straight',
        'straight',
        'straight',
        'cap',
      ]);
      expect(
        placements.map((placement) => placement.anchorCell),
        const <GridPos>[
          GridPos(x: 1, y: 3),
          GridPos(x: 2, y: 3),
          GridPos(x: 3, y: 3),
          GridPos(x: 4, y: 3),
          GridPos(x: 5, y: 3),
        ],
      );
      expect(
        placements.map((placement) => placement.transform.quarterTurns),
        <int>[0, 0, 0, 0, 2],
      );
      expect(
        placements.map((placement) => placement.transform.flipX),
        everyElement(isFalse),
      );
    });

    test('orients a vertical stroke and supports a two-cell stroke', () {
      final vertical = resolveConnectedLineBorder(
        _Fixture(
          strokes: <BorderStroke>[
            _stroke(const <GridPos>[
              GridPos(x: 2, y: 1),
              GridPos(x: 2, y: 2),
              GridPos(x: 2, y: 3),
            ]),
          ],
        ).request,
      );
      final twoCells = resolveConnectedLineBorder(
        _Fixture(
          strokes: <BorderStroke>[
            _stroke(const <GridPos>[
              GridPos(x: 1, y: 1),
              GridPos(x: 2, y: 1)]),
          ],
        ).request,
      );

      expect(vertical.canApply, isTrue, reason: _diagnostics(vertical));
      expect(
        vertical.materialization!.placements
            .map((placement) => placement.transform.quarterTurns,
        ),
        <int>[1, 1, 3],
      );
      expect(twoCells.canApply, isTrue, reason: _diagnostics(twoCells));
      expect(
        _primitiveIds(twoCells.materialization!.placements),
        <String>['cap', 'cap',
      ]);
    });

    test('can preserve authored sprite orientation without quarter turns', () {
      final result = resolveConnectedLineBorder(
        _Fixture(
          strokes: <BorderStroke>[
            _stroke(const <GridPos>[
              GridPos(x: 2, y: 1),
              GridPos(x: 2, y: 2),
              GridPos(x: 3, y: 2),
            ]),
          ],
          lineSide: BorderLineSide.inverted,
          parameters: _parameters(allowAutoRotation: false),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .map((placement) => placement.transform.quarterTurns,
        ),
        everyElement(0),
      );
      expect(
        result.materialization!.placements
            .map((placement) => placement.transform.flipX,
        ),
        everyElement(isTrue),
      );
    });

    test('moves an asymmetric straight body across the line when inverted', () {
      final primitives = <BorderPublishedPrimitive>[
        _primitive('cap', BorderPrimitiveRole.lineCap, marker: 'a'),
        _primitive(
          'straight',
          BorderPrimitiveRole.lineStraight,
          marker: 'b',
          pixelSize: const GridSize(width: 16, height: 32),
          anchorPx: const BorderPixelPos(x: 8, y: 4),
        ),
        _primitive('corner', BorderPrimitiveRole.lineCorner, marker: 'c'),
      ];
      final primary = resolveConnectedLineBorder(
        _Fixture(primitives: primitives).request,
      );
      final inverted = resolveConnectedLineBorder(
        _Fixture(
          primitives: primitives,
          lineSide: BorderLineSide.inverted,
        ).request,
      );

      expect(primary.canApply, isTrue, reason: _diagnostics(primary));
      expect(inverted.canApply, isTrue, reason: _diagnostics(inverted));
      final primaryStraight = primary.materialization!.placements.firstWhere(
        (placement) => placement.primitiveId == 'straight',
      );
      final invertedStraight = inverted.materialization!.placements.firstWhere(
        (placement) => placement.primitiveId == 'straight',
      );

      expect(primaryStraight.transform.quarterTurns, 0);
      expect(invertedStraight.transform.quarterTurns, 2);
      expect(invertedStraight.transform.flipX, isTrue);
      expect(
        invertedStraight.opaqueWorldBoundsPx.y,
        lessThan(primaryStraight.opaqueWorldBoundsPx.y),
      );
    });

    test('orients all four canonical corner connection sets', () {
      final cases = <(List<GridPos>, GridPos, int)>[
        (
          const <GridPos>[
            GridPos(x: 1, y: 1),
            GridPos(x: 2, y: 1),
            GridPos(x: 2, y: 2),
          ],
          const GridPos(x: 2, y: 1),
          0,
        ),
        (
          const <GridPos>[
            GridPos(x: 2, y: 1),
            GridPos(x: 1, y: 1),
            GridPos(x: 1, y: 2),
          ],
          const GridPos(x: 1, y: 1),
          3,
        ),
        (
          const <GridPos>[
            GridPos(x: 2, y: 1),
            GridPos(x: 2, y: 2),
            GridPos(x: 1, y: 2),
          ],
          const GridPos(x: 2, y: 2),
          1,
        ),
        (
          const <GridPos>[
            GridPos(x: 1, y: 1),
            GridPos(x: 1, y: 2),
            GridPos(x: 2, y: 2),
          ],
          const GridPos(x: 1, y: 2),
          2,
        ),
      ];

      for (final (points, cornerCell, expectedQuarterTurns) in cases) {
        final result = resolveConnectedLineBorder(
          _Fixture(strokes: <BorderStroke>[_stroke(points)]).request,
        );
        expect(result.canApply, isTrue, reason: _diagnostics(result));
        final corner = result.materialization!.placements.singleWhere(
          (placement) => placement.primitiveId == 'corner',
        );
        expect(corner.anchorCell, cornerCell);
        expect(corner.transform.quarterTurns, expectedQuarterTurns);
      }
    });

    test('keeps every repeated stair node on its logical cell', () {
      final points = const <GridPos>[
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
        GridPos(x: 3, y: 2),
        GridPos(x: 3, y: 3),
        GridPos(x: 3, y: 4),
        GridPos(x: 4, y: 4),
        GridPos(x: 5, y: 4),
        GridPos(x: 5, y: 5),
        GridPos(x: 5, y: 6),
        GridPos(x: 6, y: 6),
        GridPos(x: 7, y: 6),
      ];
      final result = resolveConnectedLineBorder(
        _Fixture(strokes: <BorderStroke>[_stroke(points)]).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements.map((item) => item.anchorCell),
        orderedEquals(points),
      );
      expect(
        result.materialization!.placements.where(
          (item) => item.primitiveId == 'corner',
        ),
        hasLength(4),
      );
      expect(
        result.materialization!.placements
            .where((item) => item.primitiveId == 'straight')
            .map((item) => item.transform.quarterTurns)
            .toSet(),
        containsAll(<int>{0, 1}),
      );
    });

    test('resolves a closed rectangle without caps', () {
      final result = resolveConnectedLineBorder(
        _Fixture(
          strokes: <BorderStroke>[
            _stroke(
              const <GridPos>[
                GridPos(x: 1, y: 1),
                GridPos(x: 2, y: 1),
                GridPos(x: 3, y: 1),
                GridPos(x: 3, y: 2),
                GridPos(x: 3, y: 3),
                GridPos(x: 2, y: 3),
                GridPos(x: 1, y: 3),
                GridPos(x: 1, y: 2),
              ],
              closed: true),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(result.materialization!.placements, hasLength(8));
      expect(_primitiveIds(result.materialization!.placements),
          isNot(contains('cap')),
      );
      expect(
        _primitiveIds(result.materialization!.placements,
        )
            .where((id) => id == 'corner'),
        hasLength(4),
      );
    });

    test('canonical reversed gestures produce exactly equal output', () {
      const points = <GridPos>[
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
        GridPos(x: 2, y: 2),
        GridPos(x: 2, y: 3),
      ];
      final forward = resolveConnectedLineBorder(
        _Fixture(strokes: <BorderStroke>[_stroke(points)]).request,
      );
      final reverse = resolveConnectedLineBorder(
        _Fixture(strokes: <BorderStroke>[_stroke(points.reversed.toList())],
        )
            .request,
      );

      expect(forward, reverse);
    });

    test('side inversion preserves identity and only composes transforms', () {
      final primary = resolveConnectedLineBorder(
        _Fixture(lineSide: BorderLineSide.primary).request,
      );
      final inverted = resolveConnectedLineBorder(
        _Fixture(lineSide: BorderLineSide.inverted).request,
      );

      expect(primary.canApply, isTrue, reason: _diagnostics(primary));
      expect(inverted.canApply, isTrue, reason: _diagnostics(inverted));
      final first = primary.materialization!.placements;
      final second = inverted.materialization!.placements;
      expect(second.map((placement) => placement.slotKey),
          first.map((placement) => placement.slotKey),
      );
      expect(second.map((placement) => placement.primitiveId),
          first.map((placement) => placement.primitiveId),
      );
      expect(second.map((placement) => placement.anchorCell),
          first.map((placement) => placement.anchorCell),
      );
      expect(second.map((placement) => placement.stableOrderKey),
          first.map((placement) => placement.stableOrderKey),
      );
      expect(
        second.map((placement) => placement.transform.flipX),
        everyElement(isTrue),
      );
      for (var index = 0; index < first.length; index += 1) {
        expect(second[index].transform, isNot(first[index].transform));
      }
    });

    test('weighted choices are deterministic and independent from input order',
        () {
      final primitives = <BorderPublishedPrimitive>[
        _primitive('cap-z', BorderPrimitiveRole.lineCap, marker: '1'),
        _primitive('cap-a', BorderPrimitiveRole.lineCap, marker: '2'),
        _primitive('straight-z', BorderPrimitiveRole.lineStraight, marker: '3',
          ),
        _primitive('straight-a', BorderPrimitiveRole.lineStraight, marker: '4',
          ),
        _primitive('corner-z', BorderPrimitiveRole.lineCorner, marker: '5'),
        _primitive('corner-a', BorderPrimitiveRole.lineCorner, marker: '6'),
      ];
      final first = resolveConnectedLineBorder(
        _Fixture(primitives: primitives, featureSeed: 87).request,
      );
      final second = resolveConnectedLineBorder(
        _Fixture(
          primitives: primitives.reversed.toList(),
          featureSeed: 87,
        ).request,
      );

      expect(first, second);
      expect(first.canApply, isTrue, reason: _diagnostics(first));
      expect(
        _primitiveIds(first.materialization!.placements),
        <String>['cap-a', 'straight-z', 'straight-z', 'straight-z', 'cap-z',
        ]);
    },
    );

    test('zero variation always selects the first compatible variant', () {
      final primitives = <BorderPublishedPrimitive>[
        _primitive('cap-z', BorderPrimitiveRole.lineCap,
            marker: '1', weight: 1000,
        ),
        _primitive('cap-a', BorderPrimitiveRole.lineCap, marker: '2'),
        _primitive('straight-z', BorderPrimitiveRole.lineStraight,
            marker: '3', weight: 1000,
        ),
        _primitive('straight-a', BorderPrimitiveRole.lineStraight, marker: '4'),
        _primitive('corner-z', BorderPrimitiveRole.lineCorner,
            marker: '5', weight: 1000,
        ),
        _primitive('corner-a', BorderPrimitiveRole.lineCorner, marker: '6'),
      ];
      final result = resolveConnectedLineBorder(
        _Fixture(
          strokes: <BorderStroke>[
            _stroke(const <GridPos>[
              GridPos(x: 1, y: 1),
              GridPos(x: 2, y: 1),
              GridPos(x: 3, y: 1),
              GridPos(x: 3, y: 2),
              GridPos(x: 3, y: 3),
            ]),
          ],
          primitives: primitives,
          parameters: _parameters(variationPermille: 0),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        _primitiveIds(result.materialization!.placements),
        <String>[
          'cap-a',
          'straight-a',
          'corner-a',
          'straight-a',
          'cap-a',
        ]);
    });

    test('positive variation is deterministically gated and weighted', () {
      final primitives = <BorderPublishedPrimitive>[
        _primitive('cap-z', BorderPrimitiveRole.lineCap,
            marker: '1', weight: 1000,
        ),
        _primitive('cap-a', BorderPrimitiveRole.lineCap, marker: '2'),
        _primitive('straight-z', BorderPrimitiveRole.lineStraight,
            marker: '3', weight: 1000,
        ),
        _primitive('straight-a', BorderPrimitiveRole.lineStraight, marker: '4'),
        _primitive('corner-z', BorderPrimitiveRole.lineCorner,
            marker: '5', weight: 1000,
        ),
        _primitive('corner-a', BorderPrimitiveRole.lineCorner, marker: '6'),
      ];
      BorderResolutionResult resolveAt(int variationPermille) =>
          resolveConnectedLineBorder(
            _Fixture(
              primitives: primitives,
              parameters: _parameters(variationPermille: 0),
              paramsOverride: _parameters(
                variationPermille: variationPermille),
            ).request,
          );

      final low = resolveAt(1);
      final full = resolveAt(1000);

      expect(low.canApply, isTrue, reason: _diagnostics(low));
      expect(full.canApply, isTrue, reason: _diagnostics(full));
      expect(
        _primitiveIds(low.materialization!.placements),
        everyElement(anyOf('cap-a', 'straight-a')),
      );
      expect(
        _primitiveIds(full.materialization!.placements),
        contains(anyOf('cap-z', 'straight-z')),
      );
      expect(resolveAt(1), low);
      expect(resolveAt(1000), full);
    });

    test('applies suppress, replacement, and offset overrides', () {
      final source = _Fixture(
        primitives: <BorderPublishedPrimitive>[
          _primitive('cap', BorderPrimitiveRole.lineCap, marker: 'a'),
          _primitive('straight', BorderPrimitiveRole.lineStraight, marker: 'b'),
          _primitive(
            'straight-alt',
            BorderPrimitiveRole.lineStraight,
            marker: 'd',
          ),
          _primitive('corner', BorderPrimitiveRole.lineCorner, marker: 'c'),
        ],
      );
      final base = resolveConnectedLineBorder(source.request);
      final straight = base.materialization!.placements[2];
      final suppressed = base.materialization!.placements[1];
      final result = resolveConnectedLineBorder(
        _Fixture(
          primitives: source.primitives,
          overrides: <BorderSlotOverride>[
            BorderSlotOverride(
              slotKey: suppressed.slotKey,
              variationSalt: BorderSignedInt64.zero,
              suppressed: true,
              locked: false,
            ),
            BorderSlotOverride(
              slotKey: straight.slotKey,
              variationSalt: BorderSignedInt64.zero,
              suppressed: false,
              locked: false,
              replacementPrimitiveId: 'straight-alt',
              offsetDeltaPx: const BorderPixelOffset(x: 2, y: -1),
            ),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .map((placement) => placement.slotKey,
        ),
        isNot(contains(suppressed.slotKey)),
      );
      final replaced = result.materialization!.placements.singleWhere(
        (placement) => placement.slotKey == straight.slotKey,
      );
      expect(replaced.primitiveId, 'straight-alt');
      expect(replaced.topLeftWorldPx.x, straight.topLeftWorldPx.x + 2);
      expect(replaced.topLeftWorldPx.y, straight.topLeftWorldPx.y - 1);
    });

    test('reports missing roles, transforms, geometry and snapshots', () {
      final missingCap = resolveConnectedLineBorder(
        _Fixture(
          primitives: <BorderPublishedPrimitive>[
            _primitive('straight', BorderPrimitiveRole.lineStraight,
                marker: 'b',
            ),
            _primitive('corner', BorderPrimitiveRole.lineCorner, marker: 'c'),
          ],
        ).request,
      );
      final missingFlip = resolveConnectedLineBorder(
        _Fixture(
          lineSide: BorderLineSide.inverted,
          primitives: <BorderPublishedPrimitive>[
            _primitive('cap', BorderPrimitiveRole.lineCap,
                marker: 'a', allowFlipX: false,
            ),
            _primitive('straight', BorderPrimitiveRole.lineStraight,
                marker: 'b', allowFlipX: false,
            ),
            _primitive('corner', BorderPrimitiveRole.lineCorner,
                marker: 'c', allowFlipX: false,
            ),
          ],
        ).request,
      );
      final region = resolveConnectedLineBorder(
        _Fixture(
          geometry: BorderRegionGeometry(
            width: 10,
            height: 10,
            cells: List<bool>.filled(100, false),
          ),
        ).request,
      );
      final missingSnapshot = resolveConnectedLineBorder(
        _Fixture(visualSnapshots: const <BorderVisualSnapshot>[]).request,
      );

      expect(_codes(missingCap),
          contains('border.resolution.connected_line_cap_role_missing'),
      );
      expect(_codes(missingFlip),
          contains('border.resolution.connected_line_transform_unavailable'),
      );
      expect(_codes(region),
          contains('border.resolution.stroke_geometry_required'),
      );
      expect(_codes(missingSnapshot),
          contains('border.resolution.visual_snapshot_invalid'),
      );
      for (final result in <BorderResolutionResult>[
        missingCap,
        missingFlip,
        region,
        missingSnapshot,
      ]) {
        expect(result.materialization, isNull);
      }
    });

    test('reports an empty materialization when every node is suppressed', () {
      final base = resolveConnectedLineBorder(_Fixture().request);
      final result = resolveConnectedLineBorder(
        _Fixture(
          overrides: <BorderSlotOverride>[
            for (final placement in base.materialization!.placements)
              BorderSlotOverride(
                slotKey: placement.slotKey,
                variationSalt: BorderSignedInt64.zero,
                suppressed: true,
                locked: false,
              ),
          ],
        ).request,
      );

      expect(result.materialization, isNull);
      expect(
          _codes(result), contains('border.resolution.materialization_empty'),
      );
    });

    test('is active through the global resolver dispatcher', () {
      final request = _Fixture().request;
      expect(
          resolveBorderFeature(request), resolveConnectedLineBorder(request),
      );
    });
  });
}

final class _Fixture {
  _Fixture({
    List<BorderStroke>? strokes,
    List<BorderPublishedPrimitive>? primitives,
    List<BorderVisualSnapshot>? visualSnapshots,
    List<BorderSlotOverride> overrides = const <BorderSlotOverride>[],
    BorderFeatureGeometry? geometry,
    BorderLineSide lineSide = BorderLineSide.primary,
    int featureSeed = 53,
    BorderGenerationParams? parameters,
    BorderGenerationParams? paramsOverride,
  }) : primitives = primitives ??
            <BorderPublishedPrimitive>[
              _primitive('cap', BorderPrimitiveRole.lineCap, marker: 'a'),
              _primitive('straight', BorderPrimitiveRole.lineStraight,
                  marker: 'b',
             ),
              _primitive('corner', BorderPrimitiveRole.lineCorner, marker: 'c'),
            ] {
    final snapshots = visualSnapshots ??
        <BorderVisualSnapshot>[
          for (final primitive in this.primitives) _snapshot(primitive),
        ];
    final definition = BorderBlueprintPublishedDefinition(
      name: 'Ligne connectee',
      previewSeed: BorderSignedInt64.fromInt(23),
      template: BorderBlueprintTemplate.connectedLine,
      primitives: this.primitives,
      defaults: parameters ?? _parameters(),
      sortOrder: 0,
    );
    request = BorderResolutionRequest(
      mapSize: const GridSize(width: 10, height: 10),
      tileSizePx: const GridSize(width: 16, height: 16),
      blueprintId: 'connected-line-test',
      blueprintRevision: BorderBlueprintRevision(
        revision: 2,
        definition: definition,
      ),
      feature: BorderFeature(
        id: 'connected-feature',
        name: 'Falaise',
        blueprintId: 'connected-line-test',
        seed: BorderSignedInt64.fromInt(featureSeed),
        geometry: geometry ??
            BorderStrokeGeometry(
              strokes: strokes ??
                  <BorderStroke>[
                    _stroke(const <GridPos>[
                      GridPos(x: 1, y: 3),
                      GridPos(x: 2, y: 3),
                      GridPos(x: 3, y: 3),
                      GridPos(x: 4, y: 3),
                      GridPos(x: 5, y: 3),
                    ]),
                  ],
            ),
        lineSide: lineSide,
        paramsOverride: paramsOverride,
        overrides: overrides,
        keepOutRegions: const <BorderKeepOutRegion>[],
      ),
      visualSnapshots: snapshots,
      resolverVersion: borderResolverVersion,
    );
  }

  final List<BorderPublishedPrimitive> primitives;
  late final BorderResolutionRequest request;
}

BorderStroke _stroke(List<GridPos> points, {bool closed = false}) =>
    canonicalizeBorderStrokeV1(
      id: 'main',
      sampledPoints: points,
      closed: closed,
    );

BorderGenerationParams _parameters({
  int variationPermille = 1000,
  bool allowAutoRotation = true,
}) =>
    BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: variationPermille,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
      allowAutoRotation: allowAutoRotation,
    );

BorderPublishedPrimitive _primitive(
  String id,
  BorderPrimitiveRole role, {
  required String marker,
  bool allowFlipX = true,
  int weight = 1,
  GridSize pixelSize = const GridSize(width: 16, height: 16),
  BorderPixelPos anchorPx = const BorderPixelPos(x: 7, y: 7),
}) =>
    BorderPublishedPrimitive(
      id: id,
      sourceElementId: 'element-$id',
      visualSnapshotId: 'border-snapshot-sha256:${marker * 64}',
      role: role,
      weight: weight,
      anchorPx: anchorPx,
      transforms: BorderTransformPolicy(
        allowFlipX: allowFlipX,
        allowedQuarterTurns: const <int>[0, 1, 2, 3],
      ),
      publishedMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'asset-$id',
        pixelSize: pixelSize,
        opaqueBounds: BorderPixelRect(
          x: 0,
          y: 0,
          width: pixelSize.width,
          height: pixelSize.height,
        ),
        defaultAnchorPx: anchorPx,
        occupancyMaskRle: encodeBorderRleMask(
          List<bool>.filled(pixelSize.width * pixelSize.height, true),
        ),
      ),
    );

BorderVisualSnapshot _snapshot(BorderPublishedPrimitive primitive) {
  final fingerprint = primitive.visualSnapshotId.substring(
    'border-snapshot-sha256:'.length,
  );
  return BorderVisualSnapshot(
    id: primitive.visualSnapshotId,
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/$fingerprint.png',
        sourceRectPx: BorderPixelRect(
          x: 0,
          y: 0,
          width: primitive.publishedMetrics.pixelSize.width,
          height: primitive.publishedMetrics.pixelSize.height,
        ),
        durationMs: 100,
      ),
    ],
  );
}

List<String> _primitiveIds(List<BorderResolvedPlacement> placements) =>
    placements.map((placement) => placement.primitiveId).toList();

Iterable<String> _codes(BorderResolutionResult result) =>
    result.diagnostics.map((diagnostic) => diagnostic.code);

String _diagnostics(BorderResolutionResult result) => result.diagnostics
    .map((diagnostic) => '${diagnostic.severity.name}:${diagnostic.code}')
    .join(', ');
